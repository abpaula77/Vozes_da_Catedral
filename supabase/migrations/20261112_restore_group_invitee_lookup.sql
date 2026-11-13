-- Restore the coordinator-only lookup used by the add-member dialog.
-- This function is intentionally limited to users not already in the group.

create or replace function public.list_group_invitees(p_grupo_id uuid)
returns table (id uuid, nome text, email text)
language plpgsql
security definer
stable
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem consultar usuários para o grupo';
  end if;

  return query
  select u.id, u.nome, u.email
  from public.users as u
  where not exists (
    select 1
    from public.membros_grupo as mg
    where mg.grupo_id = p_grupo_id
      and mg.user_id = u.id
  )
  order by lower(u.nome), lower(u.email);
end;
$$;

revoke all on function public.list_group_invitees(uuid) from public;
grant execute on function public.list_group_invitees(uuid) to authenticated;

create or replace function public.find_group_invitee(
  p_grupo_id uuid,
  p_email text
)
returns uuid
language sql
security definer
stable
set search_path = ''
as $$
  select u.id
  from public.users u
  where lower(u.email) = lower(p_email)
    and public.is_group_coordinator(p_grupo_id)
  limit 1;
$$;

revoke all on function public.find_group_invitee(uuid, text) from public;
grant execute on function public.find_group_invitee(uuid, text) to authenticated;
