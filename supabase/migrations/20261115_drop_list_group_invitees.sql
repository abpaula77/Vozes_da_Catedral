-- Issue #24: any authenticated user can create a group (becoming coordinator)
-- and call list_group_invitees to enumerate every registered user's name.
-- Members are now invited by exact e-mail only (add_group_member_by_email),
-- and the join-request flow (#41) will show only users who asked to join.
--
-- Apply ONLY after the web and Android builds without the "Usuário cadastrado"
-- tab are published; older builds call this function from that tab.
drop function if exists public.list_group_invitees(uuid);

notify pgrst, 'reload schema';
