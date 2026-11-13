drop function if exists public.list_group_invitees(uuid);
drop function if exists public.find_group_invitee(uuid, text);

drop policy if exists "Users can update their own profile" on public.users;
drop policy if exists "Users can insert their own profile" on public.users;

revoke all on table public.users from public, anon, authenticated;
revoke select (id, nome, email, foto, papel, created_at, updated_at)
  on table public.users from public, anon, authenticated;
grant select (id, nome, papel) on table public.users to authenticated;

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

  update public.users
  set nome = btrim(p_nome),
      foto = p_foto,
      papel = p_papel,
      updated_at = now()
  where id = v_user_id;

  if not found then
    insert into public.users (id, nome, email, foto, papel)
    select v_user_id, btrim(p_nome), au.email, p_foto, p_papel
    from auth.users as au
    where au.id = v_user_id and au.email is not null;
    if not found then
      raise exception 'Não foi possível salvar o perfil';
    end if;
  end if;
end;
$$;

revoke all on function public.update_my_profile(text, text, text) from public;
grant execute on function public.update_my_profile(text, text, text)
  to authenticated;

create or replace function public.add_group_member_by_email(
  p_grupo_id uuid,
  p_email text,
  p_papel text default 'membro'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem adicionar membros';
  end if;
  if nullif(btrim(p_email), '') is null then
    raise exception 'O e-mail é obrigatório';
  end if;
  if p_papel is null or p_papel not in ('coordenador', 'membro') then
    raise exception 'Papel inválido';
  end if;

  select u.id into v_user_id
  from public.users as u
  where lower(btrim(u.email)) = lower(btrim(p_email))
  limit 1;

  if v_user_id is not null then
    insert into public.membros_grupo (grupo_id, user_id, papel)
    values (p_grupo_id, v_user_id, p_papel)
    on conflict (grupo_id, user_id) do nothing;
  end if;
end;
$$;

revoke all on function public.add_group_member_by_email(uuid, text, text)
  from public;
grant execute on function public.add_group_member_by_email(uuid, text, text)
  to authenticated;
