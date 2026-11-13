-- Issue #42: user profile, photo upload and account deletion.
-- Spec: .kiro/specs/perfil-usuario/
--
-- Additive for current app builds: users.foto stays a text column, and
-- update_my_profile keeps its signature (it now validates the photo).

-- ── 1.1 Private bucket and Storage policies ──────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 524288,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Who may see a user's photo (requirement 4.1): the user, anyone sharing a
-- group with them, and coordinators of a group they asked to join (#41).
create or replace function public.pode_ver_foto(p_dono uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select auth.uid() is not null
    and p_dono is not null
    and (
      p_dono = auth.uid()
      or exists (
        select 1
        from public.membros_grupo as eu
        join public.membros_grupo as outro on outro.grupo_id = eu.grupo_id
        where eu.user_id = auth.uid() and outro.user_id = p_dono
      )
      or exists (
        select 1
        from public.solicitacoes_grupo as s
        join public.membros_grupo as coord
          on coord.grupo_id = s.grupo_id
         and coord.user_id = auth.uid()
         and coord.papel = 'coordenador'
        where s.user_id = p_dono and s.status = 'pendente'
      )
    );
$$;

-- Object names are "<user_id>/<file>". A malformed folder must not raise an
-- error inside the policy, so the cast is guarded.
create or replace function public._dono_do_avatar(p_nome_objeto text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_pasta text := split_part(p_nome_objeto, '/', 1);
begin
  if v_pasta ~ '^[0-9a-fA-F-]{36}$' then
    return v_pasta::uuid;
  end if;
  return null;
end;
$$;

drop policy if exists "Avatar: quem pode ver a foto" on storage.objects;
create policy "Avatar: quem pode ver a foto"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'avatars'
    and public.pode_ver_foto(public._dono_do_avatar(name))
  );

drop policy if exists "Avatar: dono envia" on storage.objects;
create policy "Avatar: dono envia"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and public._dono_do_avatar(name) = (select auth.uid())
  );

drop policy if exists "Avatar: dono substitui" on storage.objects;
create policy "Avatar: dono substitui"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and public._dono_do_avatar(name) = (select auth.uid())
  )
  with check (
    bucket_id = 'avatars'
    and public._dono_do_avatar(name) = (select auth.uid())
  );

drop policy if exists "Avatar: dono apaga" on storage.objects;
create policy "Avatar: dono apaga"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and public._dono_do_avatar(name) = (select auth.uid())
  );

-- ── 1.2 Photo value validation and RPCs ──────────────────────────────────────

-- Accepts only: null; a file in the caller's own avatars folder; or the
-- caller's own Google photo, read from auth.users on the server. Blocks
-- arbitrary third-party URLs (viewer IP tracking).
create or replace function public._foto_valida(p_foto text)
returns boolean
language plpgsql
security definer
stable
set search_path = ''
as $$
declare
  v_meta jsonb;
begin
  if p_foto is null then
    return true;
  end if;
  if auth.uid() is null then
    return false;
  end if;
  if p_foto ~ ('^avatars/' || auth.uid()::text || '/[A-Za-z0-9._-]{1,100}$') then
    return true;
  end if;

  select au.raw_user_meta_data into v_meta
  from auth.users as au
  where au.id = auth.uid();

  -- coalesce: a missing metadata key yields null, and "not null" would let
  -- any URL through the callers' "if not _foto_valida(...)" checks.
  return coalesce(
    p_foto like 'https://%'
      and (p_foto = v_meta ->> 'avatar_url' or p_foto = v_meta ->> 'picture'),
    false
  );
end;
$$;

-- Sets the caller's photo and returns the previous value, so the app can
-- delete the previous uploaded file (requirement 2.6).
create or replace function public.definir_minha_foto(p_foto text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_foto text := nullif(btrim(p_foto), '');
  v_anterior text;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not public._foto_valida(v_foto) then
    raise exception 'Foto inválida.';
  end if;

  select u.foto into v_anterior
  from public.users as u
  where u.id = auth.uid()
  for update;

  if not found then
    raise exception 'Perfil não encontrado.';
  end if;

  update public.users
  set foto = v_foto,
      updated_at = now()
  where id = auth.uid();

  return v_anterior;
end;
$$;

-- Kept for older app builds; now validates the photo too.
create or replace function public.update_my_profile(
  p_nome text,
  p_foto text,
  p_papel text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_foto text := nullif(btrim(p_foto), '');
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;
  if nullif(btrim(p_nome), '') is null then
    raise exception 'O nome é obrigatório';
  end if;
  if p_papel is null or p_papel not in ('coordenador', 'membro') then
    raise exception 'Papel inválido';
  end if;
  if not public._foto_valida(v_foto) then
    raise exception 'Foto inválida.';
  end if;

  update public.users
  set nome = btrim(p_nome),
      foto = v_foto,
      papel = p_papel,
      updated_at = now()
  where id = v_user_id;

  if not found then
    insert into public.users (id, nome, email, foto, papel)
    select v_user_id, btrim(p_nome), au.email, v_foto, p_papel
    from auth.users as au
    where au.id = v_user_id and au.email is not null;
    if not found then
      raise exception 'Não foi possível salvar o perfil';
    end if;
  end if;
end;
$$;

-- Colleagues' photos: the users RLS already limits visible rows to the user
-- and people sharing a group, so the column grant matches requirement 4.1.
-- email stays not readable (4.2).
grant select (foto) on table public.users to authenticated;

-- ── 1.3 Name ─────────────────────────────────────────────────────────────────

create or replace function public.atualizar_meu_nome(p_nome text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_nome text := btrim(coalesce(p_nome, ''));
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;
  if char_length(v_nome) < 2 or char_length(v_nome) > 80 then
    raise exception 'O nome deve ter entre 2 e 80 caracteres.';
  end if;

  update public.users
  set nome = v_nome,
      updated_at = now()
  where id = v_user_id;

  -- First access without a profile row (requirement 5.2).
  if not found then
    insert into public.users (id, nome, email)
    select v_user_id, v_nome, au.email
    from auth.users as au
    where au.id = v_user_id and au.email is not null;
    if not found then
      raise exception 'Não foi possível salvar o perfil';
    end if;
  end if;
end;
$$;

-- ── 1.4 Account deletion ─────────────────────────────────────────────────────

-- The author is immutable for clients (#23); excluir_minha_conta enables a
-- transaction-local flag to hand authorship to another coordinator.
-- Clients cannot set it: set_config is not exposed through the API.
create or replace function public.set_criado_por()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      new.criado_por := auth.uid();
    end if;
  elsif coalesce(current_setting('app.reatribuir_autor', true), '') <> 'on' then
    new.criado_por := old.criado_por;
  end if;
  return new;
end;
$$;

-- Groups where the caller is the only coordinator (requirement 6.3).
create or replace function public.grupos_impedindo_exclusao()
returns table (id uuid, nome text)
language plpgsql
security definer
stable
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  return query
  select g.id, g.nome
  from public.grupos as g
  join public.membros_grupo as eu
    on eu.grupo_id = g.id
   and eu.user_id = auth.uid()
   and eu.papel = 'coordenador'
  where not exists (
    select 1 from public.membros_grupo as outro
    where outro.grupo_id = g.id
      and outro.papel = 'coordenador'
      and outro.user_id <> auth.uid()
  )
  order by lower(g.nome);
end;
$$;

-- Hands authorship of the caller's groups, songs and celebrations to the
-- oldest other coordinator of each group, then deletes the auth user.
-- Cascades remove public.users, memberships and join requests.
-- The app deletes the uploaded photo through the Storage API beforehand.
create or replace function public.excluir_minha_conta()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_bloqueio text;
  v_sem_coordenador int;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  select string_agg(b.nome, ', ') into v_bloqueio
  from public.grupos_impedindo_exclusao() as b;
  if v_bloqueio is not null then
    raise exception 'Você é o único coordenador de: %. Promova outro coordenador ou exclua esses grupos antes.',
      v_bloqueio;
  end if;

  -- Every item authored by the user must have someone to receive it.
  select count(*) into v_sem_coordenador
  from (
    select grupo_id from public.musicas where criado_por = v_user_id
    union
    select grupo_id from public.celebracoes where criado_por = v_user_id
    union
    select id from public.grupos where criado_por = v_user_id
  ) as itens
  where not exists (
    select 1 from public.membros_grupo as m
    where m.grupo_id = itens.grupo_id
      and m.papel = 'coordenador'
      and m.user_id <> v_user_id
  );
  if v_sem_coordenador > 0 then
    raise exception 'Há grupos sem outro coordenador para receber o que você criou. Promova um coordenador antes de excluir a conta.';
  end if;

  perform set_config('app.reatribuir_autor', 'on', true);

  -- Oldest other coordinator of the item's group (decision 1 of the design).
  update public.grupos as g
  set criado_por = (
    select m.user_id from public.membros_grupo as m
    where m.grupo_id = g.id and m.papel = 'coordenador' and m.user_id <> v_user_id
    order by m.created_at, m.user_id
    limit 1
  )
  where g.criado_por = v_user_id;

  update public.musicas as mu
  set criado_por = (
    select m.user_id from public.membros_grupo as m
    where m.grupo_id = mu.grupo_id and m.papel = 'coordenador' and m.user_id <> v_user_id
    order by m.created_at, m.user_id
    limit 1
  )
  where mu.criado_por = v_user_id;

  update public.celebracoes as c
  set criado_por = (
    select m.user_id from public.membros_grupo as m
    where m.grupo_id = c.grupo_id and m.papel = 'coordenador' and m.user_id <> v_user_id
    order by m.created_at, m.user_id
    limit 1
  )
  where c.criado_por = v_user_id;

  perform set_config('app.reatribuir_autor', 'off', true);

  delete from auth.users where id = v_user_id;
end;
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────

revoke all on function public.pode_ver_foto(uuid) from public, anon;
revoke all on function public._dono_do_avatar(text) from public, anon;
revoke all on function public._foto_valida(text) from public, anon, authenticated;
revoke all on function public.definir_minha_foto(text) from public, anon;
revoke all on function public.update_my_profile(text, text, text) from public, anon;
revoke all on function public.atualizar_meu_nome(text) from public, anon;
revoke all on function public.grupos_impedindo_exclusao() from public, anon;
revoke all on function public.excluir_minha_conta() from public, anon;
revoke all on function public.set_criado_por() from public, anon, authenticated;

-- Storage policies run as the caller, so these helpers must be executable.
grant execute on function public.pode_ver_foto(uuid) to authenticated;
grant execute on function public._dono_do_avatar(text) to authenticated;
grant execute on function public.definir_minha_foto(text) to authenticated;
grant execute on function public.update_my_profile(text, text, text) to authenticated;
grant execute on function public.atualizar_meu_nome(text) to authenticated;
grant execute on function public.grupos_impedindo_exclusao() to authenticated;
grant execute on function public.excluir_minha_conta() to authenticated;

notify pgrst, 'reload schema';
