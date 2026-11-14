-- Issue #42 follow-up: also accept the photo of the caller's own linked
-- Google identity (auth.identities), not only auth.users metadata. Accounts
-- created by e-mail and linked to Google later may only have it there.
create or replace function public._foto_valida(p_foto text)
returns boolean
language plpgsql
security definer
stable
set search_path = ''
as $$
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
  if p_foto not like 'https://%' then
    return false;
  end if;

  -- exists() is never null, so callers' "if not _foto_valida(...)" is safe.
  return exists (
    select 1 from auth.users as au
    where au.id = auth.uid()
      and p_foto in (au.raw_user_meta_data ->> 'avatar_url',
                     au.raw_user_meta_data ->> 'picture')
  )
  or exists (
    select 1 from auth.identities as i
    where i.user_id = auth.uid()
      and i.provider = 'google'
      and p_foto in (i.identity_data ->> 'avatar_url',
                     i.identity_data ->> 'picture')
  );
end;
$$;

revoke all on function public._foto_valida(text) from public, anon, authenticated;
