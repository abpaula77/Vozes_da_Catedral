create or replace function public.copy_celebration_to_group(
  p_celebracao_id uuid,
  p_grupo_destino_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_source public.celebracoes%rowtype;
  v_copied_id uuid;
  v_musica_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  select * into v_source
  from public.celebracoes
  where id = p_celebracao_id;

  if not found then
    raise exception 'Celebração não encontrada';
  end if;
  if not public.is_group_coordinator(v_source.grupo_id) then
    raise exception 'Somente coordenadores podem compartilhar celebrações';
  end if;
  if v_source.grupo_id = p_grupo_destino_id then
    raise exception 'A celebração já pertence ao grupo de destino';
  end if;
  if not public.is_group_coordinator(p_grupo_destino_id) then
    raise exception 'Somente coordenadores podem adicionar celebrações ao grupo';
  end if;

  for v_musica_id in
    select distinct itens.musica_id
    from public.itens_celebracao as itens
    where itens.celebracao_id = p_celebracao_id
      and itens.musica_id is not null
  loop
    perform public.copy_song_to_group(v_musica_id, p_grupo_destino_id);
  end loop;

  insert into public.celebracoes (
    grupo_id,
    titulo,
    data_hora,
    criado_por
  ) values (
    p_grupo_destino_id,
    v_source.titulo,
    v_source.data_hora,
    v_user_id
  )
  returning id into v_copied_id;

  insert into public.itens_celebracao (
    celebracao_id,
    musica_id,
    ordem,
    momento_liturgico,
    observacao
  )
  select
    v_copied_id,
    case
      when itens.musica_id is null then null
      else (
        select musica_destino.id
        from public.musicas as musica_destino
        where musica_destino.grupo_id = p_grupo_destino_id
          and musica_destino.copiada_de_id = itens.musica_id
      )
    end,
    itens.ordem,
    itens.momento_liturgico,
    itens.observacao
  from public.itens_celebracao as itens
  where itens.celebracao_id = p_celebracao_id;

  return v_copied_id;
end;
$$;

revoke all on function public.copy_celebration_to_group(uuid, uuid) from public;
grant execute on function public.copy_celebration_to_group(uuid, uuid)
  to authenticated;
