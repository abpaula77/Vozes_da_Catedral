alter table public.musicas
  add column if not exists copiada_de_id uuid
  references public.musicas(id) on delete set null;

create unique index if not exists musicas_grupo_origem_unique
  on public.musicas (grupo_id, copiada_de_id)
  where copiada_de_id is not null;

drop policy if exists "Group members can read songs" on public.musicas;
drop policy if exists "Authenticated users can browse song catalog"
  on public.musicas;
create policy "Authenticated users can browse song catalog"
  on public.musicas for select
  using ((select auth.uid()) is not null);

create or replace function public.copy_song_to_group(
  p_musica_id uuid,
  p_grupo_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_source public.musicas%rowtype;
  v_copy_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem adicionar músicas ao grupo';
  end if;

  select * into v_source
  from public.musicas
  where id = p_musica_id;

  if not found then
    raise exception 'Música não encontrada no catálogo';
  end if;
  if v_source.grupo_id = p_grupo_id then
    raise exception 'A música já pertence a este grupo';
  end if;

  insert into public.musicas (
    grupo_id,
    titulo,
    tom_original,
    bpm,
    categorias,
    conteudo_raw,
    conteudo_json,
    criado_por,
    copiada_de_id
  ) values (
    p_grupo_id,
    v_source.titulo,
    v_source.tom_original,
    v_source.bpm,
    v_source.categorias,
    v_source.conteudo_raw,
    v_source.conteudo_json,
    v_user_id,
    v_source.id
  )
  on conflict (grupo_id, copiada_de_id)
    where copiada_de_id is not null
    do nothing
  returning id into v_copy_id;

  if v_copy_id is null then
    select id into v_copy_id
    from public.musicas
    where grupo_id = p_grupo_id and copiada_de_id = v_source.id;
  end if;

  return v_copy_id;
end;
$$;

revoke all on function public.copy_song_to_group(uuid, uuid) from public;
grant execute on function public.copy_song_to_group(uuid, uuid) to authenticated;
