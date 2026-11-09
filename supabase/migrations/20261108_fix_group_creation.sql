create or replace function public.create_group(
  p_nome text,
  p_descricao text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_grupo_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;
  if nullif(btrim(p_nome), '') is null then
    raise exception 'O nome do grupo é obrigatório';
  end if;

  insert into public.grupos (nome, descricao, criado_por)
  values (btrim(p_nome), nullif(btrim(p_descricao), ''), v_user_id)
  returning id into v_grupo_id;

  insert into public.membros_grupo (grupo_id, user_id, papel)
  values (v_grupo_id, v_user_id, 'coordenador');

  return v_grupo_id;
end;
$$;

revoke all on function public.create_group(text, text) from public;
grant execute on function public.create_group(text, text) to authenticated;
