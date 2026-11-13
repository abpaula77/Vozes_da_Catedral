-- Issue #23: RLS hardening.

-- 1. Authorship: criado_por is set from the JWT on insert and immutable afterwards.
--    A trigger is used (instead of a WITH CHECK policy) because the app upserts
--    celebrations edited by another coordinator, sending the original author.
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
  else
    new.criado_por := old.criado_por;
  end if;
  return new;
end;
$$;

revoke all on function public.set_criado_por() from public, anon, authenticated;

drop trigger if exists musicas_set_criado_por on public.musicas;
create trigger musicas_set_criado_por
  before insert or update on public.musicas
  for each row execute function public.set_criado_por();

drop trigger if exists celebracoes_set_criado_por on public.celebracoes;
create trigger celebracoes_set_criado_por
  before insert or update on public.celebracoes
  for each row execute function public.set_criado_por();

-- 2. A group must always keep at least one coordinator.
--    Cascades from deleting the group or the user are still allowed.
create or replace function public.protect_last_coordinator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.papel = 'coordenador'
     and (tg_op = 'DELETE' or new.papel is distinct from 'coordenador')
     and exists (select 1 from public.grupos g where g.id = old.grupo_id)
     and exists (select 1 from public.users u where u.id = old.user_id)
     and not exists (
       select 1 from public.membros_grupo m
       where m.grupo_id = old.grupo_id
         and m.papel = 'coordenador'
         and m.user_id <> old.user_id
     )
  then
    raise exception 'O grupo precisa ter pelo menos um coordenador';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.protect_last_coordinator() from public, anon, authenticated;

drop trigger if exists membros_grupo_protect_last_coordinator on public.membros_grupo;
create trigger membros_grupo_protect_last_coordinator
  before update or delete on public.membros_grupo
  for each row execute function public.protect_last_coordinator();

-- 3. Celebration items may only reference songs of the celebration's own group.
drop policy if exists "Coordinators can manage celebration items" on public.itens_celebracao;
create policy "Coordinators can manage celebration items"
  on public.itens_celebracao for insert
  with check (
    exists (
      select 1 from public.celebracoes c
      where c.id = itens_celebracao.celebracao_id
        and public.is_group_coordinator(c.grupo_id)
    )
    and (
      itens_celebracao.musica_id is null
      or exists (
        select 1
        from public.celebracoes c
        join public.musicas m on m.grupo_id = c.grupo_id
        where c.id = itens_celebracao.celebracao_id
          and m.id = itens_celebracao.musica_id
      )
    )
  );

drop policy if exists "Coordinators can update celebration items" on public.itens_celebracao;
create policy "Coordinators can update celebration items"
  on public.itens_celebracao for update
  using (
    exists (
      select 1 from public.celebracoes c
      where c.id = itens_celebracao.celebracao_id
        and public.is_group_coordinator(c.grupo_id)
    )
  )
  with check (
    exists (
      select 1 from public.celebracoes c
      where c.id = itens_celebracao.celebracao_id
        and public.is_group_coordinator(c.grupo_id)
    )
    and (
      itens_celebracao.musica_id is null
      or exists (
        select 1
        from public.celebracoes c
        join public.musicas m on m.grupo_id = c.grupo_id
        where c.id = itens_celebracao.celebracao_id
          and m.id = itens_celebracao.musica_id
      )
    )
  );

-- 4. Signed-out (anon) clients must not execute any RPC / helper function.
revoke execute on function public.add_group_member_by_email(uuid, text, text) from public, anon;
revoke execute on function public.copy_celebration_to_group(uuid, uuid) from public, anon;
revoke execute on function public.copy_song_to_group(uuid, uuid) from public, anon;
revoke execute on function public.create_group(text, text) from public, anon;
revoke execute on function public.handle_new_user() from public, anon;
revoke execute on function public.is_group_coordinator(uuid) from public, anon;
revoke execute on function public.is_group_creator(uuid) from public, anon;
revoke execute on function public.is_group_member(uuid) from public, anon;
revoke execute on function public.list_group_invitees(uuid) from public, anon;
revoke execute on function public.update_my_profile(text, text, text) from public, anon;

notify pgrst, 'reload schema';
