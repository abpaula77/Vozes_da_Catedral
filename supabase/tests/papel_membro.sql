-- Tests for issue #52 (promote / demote group members).
-- Runs in a single DO block that ALWAYS ends with an exception, so every
-- change is rolled back. Accounts and the group are created here.
--
--   C1 = coordinator    M = member    O = user outside the group

do $$
declare
  v_c1 uuid := gen_random_uuid();
  v_m uuid := gen_random_uuid();
  v_o uuid := gen_random_uuid();
  v_g uuid;
  v_txt text;
  ok int := 0;
  falhas text := '';
begin
  perform set_config('request.jwt.claims', '', true);

  insert into auth.users (id, email, aud, role, raw_user_meta_data) values
    (v_c1, 'teste-c1-' || v_c1 || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"C1"}'),
    (v_m,  'teste-m-'  || v_m  || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"M"}'),
    (v_o,  'teste-o-'  || v_o  || '@example.invalid', 'authenticated', 'authenticated', '{"nome":"O"}');

  insert into public.grupos (nome, criado_por) values ('Teste Papel', v_c1) returning id into v_g;
  insert into public.membros_grupo (grupo_id, user_id, papel) values
    (v_g, v_c1, 'coordenador'), (v_g, v_m, 'membro');

  if has_function_privilege('anon', 'public.alterar_papel_membro(uuid, uuid, text)', 'execute') then
    falhas := falhas || 'P00 anon executa; ';
  else ok := ok + 1; end if;

  set local role authenticated;

  -- A member cannot change roles (not even their own).
  perform set_config('request.jwt.claims', json_build_object('sub', v_m, 'role', 'authenticated')::text, true);
  begin
    perform public.alterar_papel_membro(v_g, v_m, 'coordenador');
    falhas := falhas || 'P01 membro se promoveu; ';
  exception when others then
    if sqlerrm like 'Somente coordenadores%' then ok := ok + 1; else falhas := falhas || 'P01 ' || sqlerrm || '; '; end if;
  end;

  -- Someone outside the group cannot either.
  perform set_config('request.jwt.claims', json_build_object('sub', v_o, 'role', 'authenticated')::text, true);
  begin
    perform public.alterar_papel_membro(v_g, v_m, 'coordenador');
    falhas := falhas || 'P02 externo promoveu; ';
  exception when others then ok := ok + 1; end;

  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);

  -- Invalid role and non-member target.
  begin
    perform public.alterar_papel_membro(v_g, v_m, 'admin');
    falhas := falhas || 'P03 papel invalido aceito; ';
  exception when others then ok := ok + 1; end;

  begin
    perform public.alterar_papel_membro(v_g, v_o, 'coordenador');
    falhas := falhas || 'P04 promoveu quem nao e membro; ';
  exception when others then
    if sqlerrm like 'Membro não encontrado%' then ok := ok + 1; else falhas := falhas || 'P04 ' || sqlerrm || '; '; end if;
  end;

  -- The only coordinator cannot demote themselves.
  begin
    perform public.alterar_papel_membro(v_g, v_c1, 'membro');
    falhas := falhas || 'P05 ultimo coordenador se rebaixou; ';
  exception when others then
    if sqlerrm like '%pelo menos um coordenador%' then ok := ok + 1; else falhas := falhas || 'P05 ' || sqlerrm || '; '; end if;
  end;

  -- Promote M.
  perform public.alterar_papel_membro(v_g, v_m, 'coordenador');
  select papel into v_txt from public.membros_grupo where grupo_id = v_g and user_id = v_m;
  if v_txt = 'coordenador' then ok := ok + 1; else falhas := falhas || 'P06 promocao: ' || coalesce(v_txt, 'null') || '; '; end if;

  -- Now M (coordinator) demotes C1: allowed, one coordinator remains.
  perform set_config('request.jwt.claims', json_build_object('sub', v_m, 'role', 'authenticated')::text, true);
  perform public.alterar_papel_membro(v_g, v_c1, 'membro');
  select papel into v_txt from public.membros_grupo where grupo_id = v_g and user_id = v_c1;
  if v_txt = 'membro' then ok := ok + 1; else falhas := falhas || 'P07 rebaixar outro: ' || coalesce(v_txt, 'null') || '; '; end if;

  -- C1 is no longer a coordinator and cannot change roles.
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  begin
    perform public.alterar_papel_membro(v_g, v_m, 'membro');
    falhas := falhas || 'P08 ex-coordenador alterou papel; ';
  exception when others then ok := ok + 1; end;

  -- M is now the only coordinator: demoting themselves is blocked.
  perform set_config('request.jwt.claims', json_build_object('sub', v_m, 'role', 'authenticated')::text, true);
  begin
    perform public.alterar_papel_membro(v_g, v_m, 'membro');
    falhas := falhas || 'P09 deixou o grupo sem coordenador; ';
  exception when others then ok := ok + 1; end;

  -- Direct UPDATE is still not allowed for clients.
  update public.membros_grupo set papel = 'coordenador' where grupo_id = v_g and user_id = v_c1;
  reset role;
  select papel into v_txt from public.membros_grupo where grupo_id = v_g and user_id = v_c1;
  if v_txt = 'membro' then ok := ok + 1; else falhas := falhas || 'P10 update direto alterou o papel; '; end if;

  raise exception 'RESULTADO: % ok, % falhas. %',
    ok,
    case when falhas = '' then 0 else array_length(string_to_array(rtrim(falhas, '; '), '; '), 1) end,
    falhas;
end $$;
