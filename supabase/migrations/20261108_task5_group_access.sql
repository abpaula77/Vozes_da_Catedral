create or replace function public.is_group_creator(p_grupo_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.grupos
    where id = p_grupo_id and criado_por = auth.uid()
  );
$$;

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

drop policy if exists "Users can search others by email" on public.users;
drop policy if exists "Group members can read fellow member profiles" on public.users;
create policy "Group members can read fellow member profiles"
  on public.users for select using (
    id = auth.uid()
    or exists (
      select 1
      from public.membros_grupo mg
      where mg.user_id = users.id
        and public.is_group_member(mg.grupo_id)
    )
  );

drop policy if exists "Users can add themselves to a group" on public.membros_grupo;
create policy "Users can add themselves to a group"
  on public.membros_grupo for insert
  with check (
    user_id = auth.uid()
    and public.is_group_creator(grupo_id)
  );
