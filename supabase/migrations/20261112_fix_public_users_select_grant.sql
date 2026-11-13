-- Restore the minimum required read access for authenticated users to
-- load member profiles in the group directory and the current profile.

revoke all on table public.users from public, anon, authenticated;
revoke select (id, nome, email, foto, papel, created_at, updated_at)
  on table public.users from public, anon, authenticated;

grant select (id, nome, papel) on table public.users to authenticated;

-- If you prefer to allow the whole public profile to be readable by the app,
-- replace the statement above with:
-- grant select on table public.users to authenticated;
