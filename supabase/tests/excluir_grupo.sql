-- Tests for issue #61 (delete group).
-- Spec: .kiro/specs/excluir-grupo/
--
-- Runs in a single DO block that ALWAYS ends with an exception, so every
-- change is rolled back. All accounts and groups are created here.
--
--   C = coordinator of G (not its creator) and of D
--   M = member of G and recorded as G's creator (demoted creator)
--   Y = outsider with a pending join request to G
--   H = another group (coordinated by C2) holding copies to/from G
--
-- Songs in G:  g1 original (exclusive)
--              g2 original copied to H        -> not exclusive
--              g3 identical copy of h1        -> not exclusive
--              g4 edited copy of h2           -> exclusive

do $$
declare
  v_c uuid := gen_random_uuid();
  v_m uuid := gen_random_uuid();
  v_y uuid := gen_random_uuid();
  v_c2 uuid := gen_random_uuid();
  v_g uuid; v_d uuid; v_h uuid;
  v_g1 uuid; v_g2 uuid; v_g3 uuid; v_g4 uuid;
  v_h1 uuid; v_h2 uuid; v_hc uuid;
  v_cel uuid;
  r record;
  v_n int; v_txt text;
  ok int := 0;
  falhas text := '';
  fn text;
begin
  perform set_config('request.jwt.claims', '', true);

  insert into auth.users (id, email, aud, role, raw_user_meta_data) values
    (v_c,  'teste-c-'  || v_c  || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"C"}'),
    (v_m,  'teste-m-'  || v_m  || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"M"}'),
    (v_y,  'teste-y-'  || v_y  || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"Y"}'),
    (v_c2, 'teste-c2-' || v_c2 || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"C2"}');

  insert into public.grupos (nome, criado_por) values ('Teste Excluir G', v_m) returning id into v_g;
  insert into public.grupos (nome, criado_por) values ('Teste Excluir D', v_c) returning id into v_d;
  insert into public.grupos (nome, criado_por) values ('Teste Excluir H', v_c2) returning id into v_h;

  insert into public.membros_grupo (grupo_id, user_id, papel) values
    (v_g, v_c, 'coordenador'), (v_g, v_m, 'membro'),
    (v_d, v_c, 'coordenador'),
    (v_h, v_c2, 'coordenador');

  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por)
    values (v_h, 'h1', 'h1', '{}', v_c2) returning id into v_h1;
  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por)
    values (v_h, 'h2', 'h2', '{}', v_c2) returning id into v_h2;

  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por)
    values (v_g, 'g1', 'g1', '{}', v_c) returning id into v_g1;
  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por)
    values (v_g, 'g2', 'g2', '{}', v_c) returning id into v_g2;
  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por, copiada_de_id)
    values (v_g, 'g3', 'h1', '{}', v_c, v_h1) returning id into v_g3;
  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por, copiada_de_id)
    values (v_g, 'g4', 'h2 editada', '{}', v_c, v_h2) returning id into v_g4;
  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por, copiada_de_id)
    values (v_h, 'hc', 'g2', '{}', v_c2, v_g2) returning id into v_hc;

  insert into public.celebracoes (grupo_id, titulo, data_hora, criado_por)
    values (v_g, 'Missa teste', now(), v_c) returning id into v_cel;
  insert into public.itens_celebracao (celebracao_id, musica_id, ordem, momento_liturgico) values
    (v_cel, v_g2, 1, 'entrada'), (v_cel, null, 2, 'final_');

  insert into public.solicitacoes_grupo (grupo_id, user_id) values (v_g, v_y);

  -- ── Privileges ─────────────────────────────────────────────────────────────
  for fn in
    select p.oid::regprocedure::text from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname in ('_musicas_exclusivas', 'resumo_exclusao_grupo',
                        'copiar_conteudo_exclusivo', 'excluir_grupo')
  loop
    if has_function_privilege('anon', fn, 'execute') then
      falhas := falhas || 'ANON executa ' || fn || '; ';
    else ok := ok + 1; end if;
  end loop;

  if has_function_privilege('authenticated', 'public._musicas_exclusivas(uuid)', 'execute') then
    falhas := falhas || 'P01 authenticated executa _musicas_exclusivas; ';
  else ok := ok + 1; end if;
  if has_table_privilege('authenticated', 'public.grupos_excluidos', 'select') then
    falhas := falhas || 'P02 authenticated le grupos_excluidos; ';
  else ok := ok + 1; end if;
  select count(*) into v_n from pg_policies
  where schemaname = 'public' and tablename = 'grupos' and cmd = 'DELETE';
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'P03 ainda ha policy de DELETE; '; end if;

  set local role authenticated;

  -- ── M (demoted creator, member) can do nothing ─────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_m, 'role', 'authenticated')::text, true);
  -- Without a DELETE policy, RLS filters every row (no error); a privilege
  -- error would also be acceptable. Either way nothing may be deleted.
  begin
    delete from public.grupos where id = v_g;
  exception when insufficient_privilege then null;
  end;
  reset role;
  select count(*) into v_n from public.grupos where id = v_g;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'M01 delete direto apagou o grupo; '; end if;
  set local role authenticated;

  begin
    perform public.resumo_exclusao_grupo(v_g);
    falhas := falhas || 'M02 membro obteve resumo; ';
  exception when others then
    if sqlerrm like 'Somente coordenadores%' then ok := ok + 1; else falhas := falhas || 'M02 ' || sqlerrm || '; '; end if;
  end;
  begin
    perform public.excluir_grupo(v_g, 'Teste Excluir G');
    falhas := falhas || 'M03 membro excluiu o grupo; ';
  exception when others then
    if sqlerrm like 'Somente coordenadores%' then ok := ok + 1; else falhas := falhas || 'M03 ' || sqlerrm || '; '; end if;
  end;

  -- ── C: summary ─────────────────────────────────────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_c, 'role', 'authenticated')::text, true);
  select * into r from public.resumo_exclusao_grupo(v_g);
  if r.membros = 2 and r.musicas = 4 and r.musicas_exclusivas = 2
     and r.celebracoes = 1 and r.solicitacoes_pendentes = 1 then ok := ok + 1;
  else falhas := falhas || format('R01 resumo %s/%s/%s/%s/%s; ', r.membros, r.musicas,
         r.musicas_exclusivas, r.celebracoes, r.solicitacoes_pendentes); end if;

  begin
    perform public.resumo_exclusao_grupo(gen_random_uuid());
    falhas := falhas || 'R02 resumo de grupo inexistente; ';
  exception when others then
    if sqlerrm = 'Grupo não encontrado.' then ok := ok + 1; else falhas := falhas || 'R02 ' || sqlerrm || '; '; end if;
  end;

  -- ── C: copy ────────────────────────────────────────────────────────────────
  begin
    perform public.copiar_conteudo_exclusivo(v_g, v_h);
    falhas := falhas || 'K01 copiou para grupo que nao coordena; ';
  exception when others then
    if sqlerrm like 'Você precisa ser coordenador%' then ok := ok + 1; else falhas := falhas || 'K01 ' || sqlerrm || '; '; end if;
  end;
  begin
    perform public.copiar_conteudo_exclusivo(v_g, v_g);
    falhas := falhas || 'K02 copiou para o proprio grupo; ';
  exception when others then ok := ok + 1; end;

  select * into r from public.copiar_conteudo_exclusivo(v_g, v_d);
  if r.musicas = 2 and r.celebracoes = 1 then ok := ok + 1;
  else falhas := falhas || format('K03 copia %s/%s; ', r.musicas, r.celebracoes); end if;

  reset role;
  -- D gets g1 and g4 (exclusive) plus g2 (used by the celebration).
  select count(*) into v_n from public.musicas where grupo_id = v_d;
  if v_n = 3 then ok := ok + 1; else falhas := falhas || 'K04 musicas em D = ' || v_n || '; '; end if;
  select count(*) into v_n
  from public.itens_celebracao i join public.celebracoes c on c.id = i.celebracao_id
  where c.grupo_id = v_d;
  if v_n = 2 then ok := ok + 1; else falhas := falhas || 'K05 itens em D = ' || v_n || '; '; end if;
  select count(*) into v_n
  from public.itens_celebracao i join public.celebracoes c on c.id = i.celebracao_id
  join public.musicas s on s.id = i.musica_id
  where c.grupo_id = v_d and s.grupo_id = v_d and s.copiada_de_id = v_g2;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'K06 item nao aponta para a copia em D; '; end if;
  set local role authenticated;

  -- Repeating the copy does not duplicate songs.
  perform public.copiar_conteudo_exclusivo(v_g, v_d);
  reset role;
  select count(*) into v_n from public.musicas where grupo_id = v_d;
  if v_n = 3 then ok := ok + 1; else falhas := falhas || 'K07 copia repetida duplicou musicas: ' || v_n || '; '; end if;
  set local role authenticated;

  -- ── C: delete ──────────────────────────────────────────────────────────────
  begin
    perform public.excluir_grupo(v_g, 'Outro nome');
    falhas := falhas || 'E01 aceitou nome errado; ';
  exception when others then
    if sqlerrm like 'O nome digitado não confere%' then ok := ok + 1; else falhas := falhas || 'E01 ' || sqlerrm || '; '; end if;
  end;

  -- Case and surrounding spaces are ignored. G has a single coordinator (C):
  -- the last-coordinator trigger must not block the cascade.
  perform public.excluir_grupo(v_g, '  teste EXCLUIR g  ');
  ok := ok + 1;

  reset role;
  select count(*) into v_n from public.grupos where id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E03 grupo ficou; '; end if;
  select count(*) into v_n from public.membros_grupo where grupo_id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E04 membros ficaram; '; end if;
  select count(*) into v_n from public.musicas where grupo_id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E05 musicas ficaram; '; end if;
  select count(*) into v_n from public.celebracoes where grupo_id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E06 celebracoes ficaram; '; end if;
  select count(*) into v_n from public.itens_celebracao where celebracao_id = v_cel;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E07 itens ficaram; '; end if;
  select count(*) into v_n from public.solicitacoes_grupo where grupo_id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E08 solicitacoes ficaram; '; end if;

  select count(*) into v_n from public.grupos_excluidos
  where grupo_id = v_g and nome = 'Teste Excluir G' and excluido_por = v_c
    and (totais ->> 'musicas')::int = 4 and (totais ->> 'membros')::int = 2;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'E09 auditoria; '; end if;

  -- Copies in other groups survive, now without origin.
  select count(*) into v_n from public.musicas where id = v_hc and copiada_de_id is null;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'E10 copia em H; '; end if;
  select count(*) into v_n from public.musicas where grupo_id = v_d and copiada_de_id is null;
  if v_n = 3 then ok := ok + 1; else falhas := falhas || 'E11 copias em D = ' || v_n || '; '; end if;
  select count(*) into v_n from public.musicas where id in (v_h1, v_h2);
  if v_n = 2 then ok := ok + 1; else falhas := falhas || 'E12 originais em H; '; end if;

  -- Deleting again: the group no longer exists.
  set local role authenticated;
  begin
    perform public.excluir_grupo(v_g, 'Teste Excluir G');
    falhas := falhas || 'E13 excluiu de novo; ';
  exception when others then
    if sqlerrm = 'Grupo não encontrado.' then ok := ok + 1; else falhas := falhas || 'E13 ' || sqlerrm || '; '; end if;
  end;

  raise exception 'RESULTADO: % ok, % falhas. %',
    ok,
    case when falhas = '' then 0 else array_length(string_to_array(rtrim(falhas, '; '), '; '), 1) end,
    falhas;
end $$;
