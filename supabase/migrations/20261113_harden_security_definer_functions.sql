-- Issue #22: security definer helpers must not depend on the caller's search_path.
create or replace function public.is_group_member(p_grupo_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.membros_grupo
    where grupo_id = p_grupo_id and user_id = auth.uid()
  );
$$ language sql security definer stable set search_path = '';

create or replace function public.is_group_coordinator(p_grupo_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.membros_grupo
    where grupo_id = p_grupo_id and user_id = auth.uid() and papel = 'coordenador'
  );
$$ language sql security definer stable set search_path = '';

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, nome, email, foto)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = '';
