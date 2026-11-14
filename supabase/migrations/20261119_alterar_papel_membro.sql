-- Issue #52: promote a member to coordinator or demote a coordinator.
-- Only coordinators of the group may change roles. A coordinator may demote
-- another coordinator (or themselves) as long as the group keeps at least one
-- coordinator: the protect_last_coordinator trigger (#23) enforces that.
-- membros_grupo has no UPDATE policy, so this RPC is the only way to change
-- a role.
create or replace function public.alterar_papel_membro(
  p_grupo_id uuid,
  p_user_id uuid,
  p_papel text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if p_papel is null or p_papel not in ('coordenador', 'membro') then
    raise exception 'Papel inválido';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem alterar papéis.';
  end if;

  update public.membros_grupo
  set papel = p_papel
  where grupo_id = p_grupo_id
    and user_id = p_user_id;

  if not found then
    raise exception 'Membro não encontrado neste grupo.';
  end if;
end;
$$;

revoke all on function public.alterar_papel_membro(uuid, uuid, text) from public, anon;
grant execute on function public.alterar_papel_membro(uuid, uuid, text) to authenticated;

notify pgrst, 'reload schema';
