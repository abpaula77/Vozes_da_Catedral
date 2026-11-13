-- Tests for issue #41 (group join requests).
-- Spec: .kiro/specs/pedido-filiacao-grupos/
--
-- Runs against real data inside a single DO block that ALWAYS ends with an
-- exception, so every change is rolled back. The exception message is the
-- report: "RESULTADO: N ok, 0 falhas" or the list of failures.
--
-- Simulates three accounts through request.jwt.claims:
--   C  = a coordinator of the test group
--   R  = a registered user who is not a member of the test group
--   R2 = another non-member, used for the e-mail invite scenario

do $$
declare
  v_g uuid;          -- test group
  v_c uuid;          -- coordinator
  v_r uuid;          -- requester
  v_r2 uuid;         -- second requester
  v_r2_email text;
  v_s1 uuid; v_s2 uuid; v_s3 uuid; v_s4 uuid;
  v_n int;
  v_txt text;
  v_bool boolean;
  v_ts timestamptz;
  ok int := 0;
  falhas text := '';
  fn text;
begin
  -- ── Fixture (as postgres) ──────────────────────────────────────────────────
  select mg.grupo_id, mg.user_id into v_g, v_c
  from public.membros_grupo as mg
  where mg.papel = 'coordenador'
  order by (select count(*) from public.membros_grupo x where x.grupo_id = mg.grupo_id)
  limit 1;

  select u.id into v_r from public.users u
  where not exists (select 1 from public.membros_grupo m where m.grupo_id = v_g and m.user_id = u.id)
  order by u.id limit 1;

  select u.id, u.email into v_r2, v_r2_email from public.users u
  where u.id <> v_r
    and not exists (select 1 from public.membros_grupo m where m.grupo_id = v_g and m.user_id = u.id)
  order by u.id limit 1;

  if v_g is null or v_c is null or v_r is null or v_r2 is null then
    raise exception 'RESULTADO: fixture insuficiente (g=%, c=%, r=%, r2=%)', v_g, v_c, v_r, v_r2;
  end if;

  update public.grupos set aceita_solicitacoes = false where id = v_g;

  -- ── Signatures never expose e-mail or decidida_por (5.3, 6.3, 4.4) ─────────
  for fn in
    select p.oid::regprocedure::text
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname in ('listar_grupos_abertos', 'listar_minhas_solicitacoes',
                        'listar_solicitacoes_pendentes', 'contar_solicitacoes_pendentes',
                        'obter_aceita_solicitacoes')
  loop
    if pg_get_function_result(fn::regprocedure) ilike '%email%'
       or pg_get_function_result(fn::regprocedure) ilike '%decidida_por%' then
      falhas := falhas || 'ASSINATURA ' || fn || ' expõe coluna sensível; ';
    else
      ok := ok + 1;
    end if;
  end loop;

  -- ── anon cannot execute any RPC (6.6) ──────────────────────────────────────
  for fn in
    select p.oid::regprocedure::text
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname in ('definir_aceita_solicitacoes', 'obter_aceita_solicitacoes',
                        'listar_solicitacoes_pendentes', 'contar_solicitacoes_pendentes',
                        'decidir_solicitacao', 'listar_grupos_abertos', 'solicitar_entrada',
                        'listar_minhas_solicitacoes', 'cancelar_solicitacao')
  loop
    if has_function_privilege('anon', fn, 'execute') then
      falhas := falhas || 'ANON executa ' || fn || '; ';
    else
      ok := ok + 1;
    end if;
  end loop;

  set local role authenticated;

  -- ── R: closed group is invisible and rejects requests (1.1, 3.5, 6.7) ──────
  perform set_config('request.jwt.claims', json_build_object('sub', v_r, 'role', 'authenticated')::text, true);

  select count(*) into v_n from public.listar_grupos_abertos() where id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'T01 grupo fechado listado; '; end if;

  begin
    perform public.solicitar_entrada(v_g, null);
    falhas := falhas || 'T02 aceitou pedido em grupo fechado; ';
  exception when others then
    if sqlerrm like 'Grupo não encontrado ou não está aceitando%' then ok := ok + 1;
    else falhas := falhas || 'T02 ' || sqlerrm || '; '; end if;
  end;

  begin
    perform public.solicitar_entrada(gen_random_uuid(), null);
    falhas := falhas || 'T03 aceitou grupo inexistente; ';
  exception when others then
    if sqlerrm like 'Grupo não encontrado ou não está aceitando%' then ok := ok + 1;
    else falhas := falhas || 'T03 ' || sqlerrm || '; '; end if;
  end;

  -- ── R: non-coordinator cannot manage (1.5, 6.5) ────────────────────────────
  begin
    perform public.definir_aceita_solicitacoes(v_g, true);
    falhas := falhas || 'T04 não coordenador abriu o grupo; ';
  exception when others then ok := ok + 1; end;

  begin
    perform public.listar_solicitacoes_pendentes(v_g);
    falhas := falhas || 'T05 não coordenador listou pendentes; ';
  exception when others then ok := ok + 1; end;

  -- ── Direct table access is denied (6.5) ────────────────────────────────────
  begin
    perform 1 from public.solicitacoes_grupo limit 1;
    falhas := falhas || 'T06 select direto permitido; ';
  exception when insufficient_privilege then ok := ok + 1; end;

  begin
    insert into public.solicitacoes_grupo (grupo_id, user_id) values (v_g, v_r);
    falhas := falhas || 'T07 insert direto permitido; ';
  exception when insufficient_privilege then ok := ok + 1; end;

  -- ── C: open the group (1.2) ────────────────────────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_c, 'role', 'authenticated')::text, true);
  perform public.definir_aceita_solicitacoes(v_g, true);
  if public.obter_aceita_solicitacoes(v_g) then ok := ok + 1; else falhas := falhas || 'T08 grupo não abriu; '; end if;

  -- ── R: request with validations (2.1, 3.1–3.3) ─────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_r, 'role', 'authenticated')::text, true);

  select count(*) into v_n from public.listar_grupos_abertos() where id = v_g and meu_status is null;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T09 grupo aberto não listado; '; end if;

  begin
    perform public.solicitar_entrada(v_g, repeat('x', 281));
    falhas := falhas || 'T10 aceitou mensagem de 281; ';
  exception when others then
    if sqlerrm like '%280 caracteres%' then ok := ok + 1;
    else falhas := falhas || 'T10 ' || sqlerrm || '; '; end if;
  end;

  v_s1 := public.solicitar_entrada(v_g, '  Sou tenor do coral das 19h  ');
  if v_s1 is not null then ok := ok + 1; else falhas := falhas || 'T11 pedido não criado; '; end if;

  begin
    perform public.solicitar_entrada(v_g, null);
    falhas := falhas || 'T12 aceitou pedido duplicado; ';
  exception when others then
    if sqlerrm like '%já tem uma solicitação pendente%' then ok := ok + 1;
    else falhas := falhas || 'T12 ' || sqlerrm || '; '; end if;
  end;

  select count(*) into v_n from public.listar_grupos_abertos() where id = v_g and meu_status = 'pendente';
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T13 status pendente ausente na busca; '; end if;

  select m.mensagem into v_txt from public.listar_minhas_solicitacoes() m where m.id = v_s1 and m.status = 'pendente';
  if v_txt = 'Sou tenor do coral das 19h' then ok := ok + 1; else falhas := falhas || 'T14 minhas solicitações/mensagem: ' || coalesce(v_txt, 'null') || '; '; end if;

  begin
    perform public.decidir_solicitacao(v_s1, true);
    falhas := falhas || 'T15 solicitante decidiu o próprio pedido; ';
  exception when others then
    if sqlerrm = 'Solicitação não encontrada.' then ok := ok + 1;
    else falhas := falhas || 'T15 ' || sqlerrm || '; '; end if;
  end;

  -- ── C: count, list with name and photo (5.1, 5.2, 6.2) ─────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_c, 'role', 'authenticated')::text, true);

  select c.total into v_n from public.contar_solicitacoes_pendentes() c where c.grupo_id = v_g;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T16 contagem = ' || coalesce(v_n::text, 'null') || '; '; end if;

  select count(*) into v_n
  from public.listar_solicitacoes_pendentes(v_g) p
  where p.id = v_s1 and p.user_id = v_r and p.nome is not null;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T17 pendente não listado para o coordenador; '; end if;

  -- ── C: closing keeps pending requests (1.3, 1.4) ───────────────────────────
  perform public.definir_aceita_solicitacoes(v_g, false);
  select count(*) into v_n from public.listar_solicitacoes_pendentes(v_g) p where p.id = v_s1;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T18 pendente sumiu ao fechar; '; end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_r, 'role', 'authenticated')::text, true);
  select count(*) into v_n from public.listar_grupos_abertos() where id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'T19 grupo fechado ainda listado; '; end if;

  -- ── C: reject, then a second decision fails (5.5, 5.6) ─────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_c, 'role', 'authenticated')::text, true);
  perform public.decidir_solicitacao(v_s1, false);
  ok := ok + 1;

  begin
    perform public.decidir_solicitacao(v_s1, true);
    falhas := falhas || 'T21 segunda decisão aplicada; ';
  exception when others then
    if sqlerrm = 'Esta solicitação já foi decidida.' then ok := ok + 1;
    else falhas := falhas || 'T21 ' || sqlerrm || '; '; end if;
  end;

  perform public.definir_aceita_solicitacoes(v_g, true);

  -- ── R: 7-day wait after rejection (3.6) ────────────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_r, 'role', 'authenticated')::text, true);

  begin
    perform public.solicitar_entrada(v_g, null);
    falhas := falhas || 'T22 aceitou pedido dentro da espera; ';
  exception when others then
    if sqlerrm like 'Você poderá solicitar novamente a partir de __/__/____.' then ok := ok + 1;
    else falhas := falhas || 'T22 ' || sqlerrm || '; '; end if;
  end;

  select a.meu_status, a.pode_solicitar_em into v_txt, v_ts from public.listar_grupos_abertos() a where a.id = v_g;
  if v_txt = 'recusada' and v_ts > now() + interval '6 days' then ok := ok + 1;
  else falhas := falhas || 'T23 busca sem recusa/data: ' || coalesce(v_txt, 'null') || '; '; end if;

  select count(*) into v_n from public.listar_minhas_solicitacoes() m
  where m.id = v_s1 and m.status = 'recusada' and m.pode_solicitar_em is not null;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T24 recusa ausente em minhas solicitações; '; end if;

  -- Move the rejection 8 days back (as postgres).
  reset role;
  update public.solicitacoes_grupo set decidida_em = now() - interval '8 days' where id = v_s1;
  set local role authenticated;

  v_s2 := public.solicitar_entrada(v_g, null);
  if v_s2 is not null then ok := ok + 1; else falhas := falhas || 'T25 bloqueado após a espera; '; end if;

  -- ── R: cancel frees a new request immediately (4.2) ────────────────────────
  perform public.cancelar_solicitacao(v_s2);
  ok := ok + 1;

  begin
    perform public.cancelar_solicitacao(v_s2);
    falhas := falhas || 'T27 cancelou duas vezes; ';
  exception when others then ok := ok + 1; end;

  v_s3 := public.solicitar_entrada(v_g, null);
  if v_s3 is not null then ok := ok + 1; else falhas := falhas || 'T29 bloqueado após cancelar; '; end if;

  -- Another user cannot cancel R's request.
  perform set_config('request.jwt.claims', json_build_object('sub', v_r2, 'role', 'authenticated')::text, true);
  begin
    perform public.cancelar_solicitacao(v_s3);
    falhas := falhas || 'T30 outro usuário cancelou o pedido; ';
  exception when others then ok := ok + 1; end;

  -- ── C: approve is atomic and audited (5.4, 5.7) ────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_c, 'role', 'authenticated')::text, true);
  perform public.decidir_solicitacao(v_s3, true);

  reset role;
  select count(*) into v_n from public.membros_grupo where grupo_id = v_g and user_id = v_r and papel = 'membro';
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T31 aprovado não virou membro; '; end if;
  select count(*) into v_n from public.solicitacoes_grupo
  where id = v_s3 and status = 'aprovada' and decidida_por = v_c and decidida_em is not null;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T32 status/auditoria da aprovação; '; end if;
  set local role authenticated;

  -- ── R: now a member (3.4, 2.1) ─────────────────────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_r, 'role', 'authenticated')::text, true);
  select count(*) into v_n from public.listar_grupos_abertos() where id = v_g;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'T33 grupo do qual é membro listado; '; end if;

  begin
    perform public.solicitar_entrada(v_g, null);
    falhas := falhas || 'T34 membro conseguiu solicitar; ';
  exception when others then
    if sqlerrm = 'Você já faz parte deste grupo.' then ok := ok + 1;
    else falhas := falhas || 'T34 ' || sqlerrm || '; '; end if;
  end;

  -- ── R2 requests, C invites R2 by e-mail: request auto-approved (design 2) ──
  perform set_config('request.jwt.claims', json_build_object('sub', v_r2, 'role', 'authenticated')::text, true);
  v_s4 := public.solicitar_entrada(v_g, null);

  perform set_config('request.jwt.claims', json_build_object('sub', v_c, 'role', 'authenticated')::text, true);
  perform public.add_group_member_by_email(v_g, v_r2_email, 'membro');

  select count(*) into v_n from public.listar_solicitacoes_pendentes(v_g) p where p.id = v_s4;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'T35 pendente de membro ainda listado; '; end if;

  reset role;
  select count(*) into v_n from public.solicitacoes_grupo
  where id = v_s4 and status = 'aprovada' and decidida_por = v_c;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'T36 convite não aprovou o pedido; '; end if;

  raise exception 'RESULTADO: % ok, % falhas. %',
    ok,
    case when falhas = '' then 0 else array_length(string_to_array(rtrim(falhas, '; '), '; '), 1) end,
    falhas;
end $$;
