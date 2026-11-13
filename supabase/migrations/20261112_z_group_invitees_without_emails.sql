-- Limit the registered-user picker to public profile fields only.
drop function if exists public.list_group_invitees(uuid);

create function public.list_group_invitees(p_grupo_id uuid)
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
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem consultar usuários para o grupo';
  end if;

  return query
  select u.id, u.nome
  from public.users as u
  where not exists (
    select 1
    from public.membros_grupo as mg
    where mg.grupo_id = p_grupo_id
      and mg.user_id = u.id
  )
  order by lower(u.nome);
end;
$$;

revoke all on function public.list_group_invitees(uuid) from public;
grant execute on function public.list_group_invitees(uuid) to authenticated;

notify pgrst, 'reload schema';
