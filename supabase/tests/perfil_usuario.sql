-- Tests for issue #42 (user profile, photo and account deletion).
-- Spec: .kiro/specs/perfil-usuario/
--
-- Runs in a single DO block that ALWAYS ends with an exception, so every
-- change is rolled back. All accounts and groups are created here; no real
-- user is touched (the deletion test runs on a throwaway account).
--
--   A = coordinator of G and G2       B = member of G (A's colleague)
--   X = unrelated user                D = account that will be deleted

do $$
declare
  v_a uuid := gen_random_uuid();
  v_b uuid := gen_random_uuid();
  v_x uuid := gen_random_uuid();
  v_d uuid := gen_random_uuid();
  v_g uuid; v_g2 uuid; v_mus uuid; v_cel uuid;
  v_google text := 'https://lh3.googleusercontent.com/a/teste-perfil';
  v_txt text; v_n int; v_bool boolean;
  ok int := 0;
  falhas text := '';
  fn text;
begin
  -- ── Fixture (as postgres, no JWT) ──────────────────────────────────────────
  perform set_config('request.jwt.claims', '', true);

  insert into auth.users (id, email, aud, role, raw_user_meta_data)
  values
    (v_a, 'teste-a-' || v_a || '@example.invalid', 'authenticated', 'authenticated',
       jsonb_build_object('nome', 'Teste A', 'avatar_url', v_google)),
    (v_b, 'teste-b-' || v_b || '@example.invalid', 'authenticated', 'authenticated',
       jsonb_build_object('nome', 'Teste B')),
    (v_x, 'teste-x-' || v_x || '@example.invalid', 'authenticated', 'authenticated',
       jsonb_build_object('nome', 'Teste X')),
    (v_d, 'teste-d-' || v_d || '@example.invalid', 'authenticated', 'authenticated',
       jsonb_build_object('nome', 'Teste D'));

  select count(*) into v_n from public.users where id in (v_a, v_b, v_x, v_d);
  if v_n <> 4 then
    raise exception 'RESULTADO: fixture falhou, handle_new_user criou % perfis', v_n;
  end if;

  insert into public.grupos (nome, criado_por, aceita_solicitacoes)
  values ('Teste Perfil G', v_a, true) returning id into v_g;
  insert into public.grupos (nome, criado_por)
  values ('Teste Perfil G2', v_d) returning id into v_g2;

  insert into public.membros_grupo (grupo_id, user_id, papel) values
    (v_g, v_a, 'coordenador'),
    (v_g, v_b, 'membro'),
    (v_g2, v_d, 'coordenador');

  insert into public.musicas (grupo_id, titulo, conteudo_raw, conteudo_json, criado_por)
  values (v_g2, 'Teste Perfil Musica', '[TITULO]: x', '{}'::jsonb, v_d)
  returning id into v_mus;
  insert into public.celebracoes (grupo_id, titulo, data_hora, criado_por)
  values (v_g2, 'Teste Perfil Celebracao', now(), v_d)
  returning id into v_cel;

  insert into public.solicitacoes_grupo (grupo_id, user_id) values (v_g, v_x), (v_g, v_d);

  update public.users set foto = 'avatars/' || v_a || '/foto.jpg' where id = v_a;

  -- ── anon cannot execute the new RPCs ───────────────────────────────────────
  for fn in
    select p.oid::regprocedure::text from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname in ('pode_ver_foto', 'definir_minha_foto', 'atualizar_meu_nome',
                        'grupos_impedindo_exclusao', 'excluir_minha_conta',
                        'update_my_profile', '_foto_valida')
  loop
    if has_function_privilege('anon', fn, 'execute') then
      falhas := falhas || 'ANON executa ' || fn || '; ';
    else ok := ok + 1; end if;
  end loop;

  if has_function_privilege('authenticated', 'public._foto_valida(text)', 'execute') then
    falhas := falhas || 'authenticated executa _foto_valida; ';
  else ok := ok + 1; end if;

  -- ── Storage: private bucket and 4 policies ─────────────────────────────────
  select count(*) into v_n from storage.buckets
  where id = 'avatars' and not public and file_size_limit = 524288
    and allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp'];
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'S01 bucket avatars; '; end if;

  select count(*) into v_n from pg_policies
  where schemaname = 'storage' and tablename = 'objects' and policyname like 'Avatar:%';
  if v_n = 4 then ok := ok + 1; else falhas := falhas || 'S02 policies = ' || v_n || '; '; end if;

  -- ── A: photo validation ─────────────────────────────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_a, 'role', 'authenticated')::text, true);

  if public._foto_valida(null) then ok := ok + 1; else falhas := falhas || 'F01 null; '; end if;
  if public._foto_valida('avatars/' || v_a || '/abc-1.jpg') then ok := ok + 1; else falhas := falhas || 'F02 propria pasta; '; end if;
  if not public._foto_valida('avatars/' || v_b || '/abc.jpg') then ok := ok + 1; else falhas := falhas || 'F03 pasta alheia aceita; '; end if;
  if not public._foto_valida('avatars/' || v_a || '/../x.jpg') then ok := ok + 1; else falhas := falhas || 'F04 path traversal aceito; '; end if;
  if not public._foto_valida('https://evil.example/pixel.png') then ok := ok + 1; else falhas := falhas || 'F05 URL externa aceita; '; end if;
  if public._foto_valida(v_google) then ok := ok + 1; else falhas := falhas || 'F06 foto do Google recusada; '; end if;

  set local role authenticated;

  begin
    perform public.definir_minha_foto('https://evil.example/pixel.png');
    falhas := falhas || 'F07 definir_minha_foto aceitou URL externa; ';
  exception when others then
    if sqlerrm = 'Foto inválida.' then ok := ok + 1; else falhas := falhas || 'F07 ' || sqlerrm || '; '; end if;
  end;

  begin
    perform public.update_my_profile('Teste A', 'https://evil.example/pixel.png', 'membro');
    falhas := falhas || 'F08 update_my_profile aceitou URL externa; ';
  exception when others then
    if sqlerrm = 'Foto inválida.' then ok := ok + 1; else falhas := falhas || 'F08 ' || sqlerrm || '; '; end if;
  end;

  -- Old onboarding path still works with the user's own Google photo.
  perform public.update_my_profile('Teste A', v_google, 'membro');
  ok := ok + 1;

  v_txt := public.definir_minha_foto('avatars/' || v_a || '/nova.jpg');
  if v_txt = v_google then ok := ok + 1; else falhas := falhas || 'F10 anterior = ' || coalesce(v_txt, 'null') || '; '; end if;

  v_txt := public.definir_minha_foto(null);
  if v_txt = 'avatars/' || v_a || '/nova.jpg' then ok := ok + 1; else falhas := falhas || 'F11 remover; '; end if;

  perform public.definir_minha_foto('avatars/' || v_a || '/foto.jpg');

  -- ── A: name ────────────────────────────────────────────────────────────────
  begin
    perform public.atualizar_meu_nome(' a ');
    falhas := falhas || 'N01 aceitou nome curto; ';
  exception when others then ok := ok + 1; end;

  begin
    perform public.atualizar_meu_nome(repeat('x', 81));
    falhas := falhas || 'N02 aceitou nome longo; ';
  exception when others then ok := ok + 1; end;

  perform public.atualizar_meu_nome('  Ana Teste  ');
  select nome into v_txt from public.users where id = v_a;
  if v_txt = 'Ana Teste' then ok := ok + 1; else falhas := falhas || 'N03 nome = ' || coalesce(v_txt, 'null') || '; '; end if;

  -- ── Who sees the photo ─────────────────────────────────────────────────────
  -- A (coordinator of G) sees X, who has a pending request to G.
  if public.pode_ver_foto(v_x) then ok := ok + 1; else falhas := falhas || 'V01 coordenador nao ve solicitante; '; end if;
  if public.pode_ver_foto(v_a) then ok := ok + 1; else falhas := falhas || 'V02 nao ve a propria foto; '; end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_b, 'role', 'authenticated')::text, true);
  if public.pode_ver_foto(v_a) then ok := ok + 1; else falhas := falhas || 'V03 colega nao ve; '; end if;
  if not public.pode_ver_foto(v_x) then ok := ok + 1; else falhas := falhas || 'V04 membro comum ve solicitante; '; end if;

  select foto into v_txt from public.users where id = v_a;
  if v_txt = 'avatars/' || v_a || '/foto.jpg' then ok := ok + 1; else falhas := falhas || 'V05 colega nao le coluna foto; '; end if;

  begin
    select email into v_txt from public.users where id = v_a;
    falhas := falhas || 'V06 email legivel; ';
  exception when insufficient_privilege then ok := ok + 1; end;

  perform set_config('request.jwt.claims', json_build_object('sub', v_x, 'role', 'authenticated')::text, true);
  if not public.pode_ver_foto(v_a) then ok := ok + 1; else falhas := falhas || 'V07 desconhecido ve; '; end if;
  select count(*) into v_n from public.users where id = v_a;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'V08 desconhecido le o perfil; '; end if;

  -- ── Author stays immutable for clients ─────────────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_a, 'role', 'authenticated')::text, true);
  reset role;
  insert into public.membros_grupo (grupo_id, user_id, papel) values (v_g2, v_a, 'coordenador');
  set local role authenticated;

  update public.musicas set criado_por = v_a where id = v_mus;
  reset role;
  select count(*) into v_n from public.musicas where id = v_mus and criado_por = v_d;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'A01 cliente mudou o autor; '; end if;
  delete from public.membros_grupo where grupo_id = v_g2 and user_id = v_a;
  set local role authenticated;

  -- ── D: deletion blocked as the only coordinator ────────────────────────────
  perform set_config('request.jwt.claims', json_build_object('sub', v_d, 'role', 'authenticated')::text, true);

  select count(*) into v_n from public.grupos_impedindo_exclusao() where id = v_g2;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'E01 bloqueio nao listado; '; end if;

  begin
    perform public.excluir_minha_conta();
    falhas := falhas || 'E02 excluiu o unico coordenador; ';
  exception when others then
    if sqlerrm like '%único coordenador de: Teste Perfil G2.%' then ok := ok + 1;
    else falhas := falhas || 'E02 ' || sqlerrm || '; '; end if;
  end;

  -- ── D: deletion succeeds once A is also coordinator of G2 ──────────────────
  reset role;
  insert into public.membros_grupo (grupo_id, user_id, papel) values (v_g2, v_a, 'coordenador');
  set local role authenticated;

  select count(*) into v_n from public.grupos_impedindo_exclusao();
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E03 ainda bloqueado; '; end if;

  perform public.excluir_minha_conta();

  reset role;
  select count(*) into v_n from auth.users where id = v_d;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E04 auth.users ficou; '; end if;
  select count(*) into v_n from public.users where id = v_d;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E05 perfil ficou; '; end if;
  select count(*) into v_n from public.membros_grupo where user_id = v_d;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E06 participacoes ficaram; '; end if;
  select count(*) into v_n from public.solicitacoes_grupo where user_id = v_d;
  if v_n = 0 then ok := ok + 1; else falhas := falhas || 'E07 solicitacoes ficaram; '; end if;
  select count(*) into v_n from public.grupos where id = v_g2 and criado_por = v_a;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'E08 autoria do grupo; '; end if;
  select count(*) into v_n from public.musicas where id = v_mus and criado_por = v_a;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'E09 autoria da musica; '; end if;
  select count(*) into v_n from public.celebracoes where id = v_cel and criado_por = v_a;
  if v_n = 1 then ok := ok + 1; else falhas := falhas || 'E10 autoria da celebracao; '; end if;

  if coalesce(current_setting('app.reatribuir_autor', true), '') <> 'on' then ok := ok + 1;
  else falhas := falhas || 'E11 flag de autoria ficou ligada; '; end if;

  raise exception 'RESULTADO: % ok, % falhas. %',
    ok,
    case when falhas = '' then 0 else array_length(string_to_array(rtrim(falhas, '; '), '; '), 1) end,
    falhas;
end $$;
