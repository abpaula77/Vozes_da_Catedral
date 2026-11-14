-- Issue #61: delete group (coordinators only), with a summary, a bulk copy
-- of the group's exclusive content and an audit record.
-- Spec: .kiro/specs/excluir-grupo/
--
-- Safe for current app builds: none of them deletes groups.

-- ── 1.1 No direct deletion; audit table ──────────────────────────────────────

-- The old policy let whoever is recorded as creator delete the group, even
-- after being demoted to member (#52). Deletion now goes only through
-- excluir_grupo, which requires a coordinator.
drop policy if exists "Coordinators can delete their groups" on public.grupos;

create table if not exists public.grupos_excluidos (
  id            uuid primary key default gen_random_uuid(),
  grupo_id      uuid not null,           -- no FK: the group no longer exists
  nome          text not null,
  excluido_por  uuid not null,           -- no FK: survives account deletion
  excluido_em   timestamptz not null default now(),
  totais        jsonb not null default '{}'::jsonb
);

-- Readable only from the Supabase dashboard.
alter table public.grupos_excluidos enable row level security;
revoke all on table public.grupos_excluidos from public, anon, authenticated;

-- ── 1.2 Exclusive songs and summary ──────────────────────────────────────────

-- Songs that would no longer exist anywhere if the group were deleted:
-- not copied to another group, and not an identical copy of a song that
-- exists in another group. An edited copy counts as exclusive.
create or replace function public._musicas_exclusivas(p_grupo_id uuid)
returns setof uuid
language sql
security definer
stable
set search_path = ''
as $$
  select s.id
  from public.musicas as s
  where s.grupo_id = p_grupo_id
    and not exists (
      select 1 from public.musicas as c
      where c.copiada_de_id = s.id and c.grupo_id <> p_grupo_id
    )
    and not exists (
      select 1 from public.musicas as o
      where o.id = s.copiada_de_id
        and o.grupo_id <> p_grupo_id
        and o.conteudo_raw = s.conteudo_raw
    );
$$;

create or replace function public.resumo_exclusao_grupo(p_grupo_id uuid)
returns table (
  membros integer,
  musicas integer,
  musicas_exclusivas integer,
  celebracoes integer,
  solicitacoes_pendentes integer
)
language plpgsql
security definer
stable
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not exists (select 1 from public.grupos as g where g.id = p_grupo_id) then
    raise exception 'Grupo não encontrado.';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem excluir o grupo.';
  end if;

  return query
  select
    (select count(*) from public.membros_grupo as m where m.grupo_id = p_grupo_id)::integer,
    (select count(*) from public.musicas as s where s.grupo_id = p_grupo_id)::integer,
    (select count(*) from public._musicas_exclusivas(p_grupo_id))::integer,
    (select count(*) from public.celebracoes as c where c.grupo_id = p_grupo_id)::integer,
    (select count(*) from public.solicitacoes_grupo as r
      where r.grupo_id = p_grupo_id and r.status = 'pendente')::integer;
end;
$$;

-- ── 1.3 Copy the exclusive content to another group ──────────────────────────

-- Copies the exclusive songs and every celebration (which brings along the
-- songs it uses). Song copies are idempotent per origin; celebration copies
-- are not, so the app disables the action after the first copy.
create or replace function public.copiar_conteudo_exclusivo(
  p_origem uuid,
  p_destino uuid
)
returns table (musicas integer, celebracoes integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_musicas integer := 0;
  v_celebracoes integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if p_origem is null or p_destino is null or p_origem = p_destino then
    raise exception 'Escolha um grupo de destino diferente do grupo atual.';
  end if;
  if not public.is_group_coordinator(p_origem)
     or not public.is_group_coordinator(p_destino) then
    raise exception 'Você precisa ser coordenador dos dois grupos.';
  end if;

  for v_id in select * from public._musicas_exclusivas(p_origem) loop
    perform public.copy_song_to_group(v_id, p_destino);
    v_musicas := v_musicas + 1;
  end loop;

  for v_id in
    select c.id from public.celebracoes as c
    where c.grupo_id = p_origem
    order by c.data_hora, c.id
  loop
    perform public.copy_celebration_to_group(v_id, p_destino);
    v_celebracoes := v_celebracoes + 1;
  end loop;

  return query select v_musicas, v_celebracoes;
end;
$$;

-- ── 1.4 Delete the group ─────────────────────────────────────────────────────

create or replace function public.excluir_grupo(
  p_grupo_id uuid,
  p_confirmacao text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nome text;
  v_totais jsonb;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  -- Row lock: concurrent deletions by two coordinators are serialized.
  select g.nome into v_nome
  from public.grupos as g
  where g.id = p_grupo_id
  for update;

  if not found then
    raise exception 'Grupo não encontrado.';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem excluir o grupo.';
  end if;
  -- Also checked here, not only in the app, against direct API calls.
  if lower(btrim(v_nome)) <> lower(btrim(coalesce(p_confirmacao, ''))) then
    raise exception 'O nome digitado não confere com o nome do grupo.';
  end if;

  select jsonb_build_object(
    'membros', (select count(*) from public.membros_grupo where grupo_id = p_grupo_id),
    'musicas', (select count(*) from public.musicas where grupo_id = p_grupo_id),
    'celebracoes', (select count(*) from public.celebracoes where grupo_id = p_grupo_id),
    'solicitacoes_pendentes', (select count(*) from public.solicitacoes_grupo
                               where grupo_id = p_grupo_id and status = 'pendente')
  ) into v_totais;

  insert into public.grupos_excluidos (grupo_id, nome, excluido_por, totais)
  values (p_grupo_id, v_nome, auth.uid(), v_totais);

  -- ON DELETE CASCADE removes members, songs, celebrations (and items) and
  -- join requests. Copies in other groups stay, with copiada_de_id = null.
  delete from public.grupos where id = p_grupo_id;
end;
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────

revoke all on function public._musicas_exclusivas(uuid) from public, anon, authenticated;
revoke all on function public.resumo_exclusao_grupo(uuid) from public, anon;
revoke all on function public.copiar_conteudo_exclusivo(uuid, uuid) from public, anon;
revoke all on function public.excluir_grupo(uuid, text) from public, anon;

grant execute on function public.resumo_exclusao_grupo(uuid) to authenticated;
grant execute on function public.copiar_conteudo_exclusivo(uuid, uuid) to authenticated;
grant execute on function public.excluir_grupo(uuid, text) to authenticated;

notify pgrst, 'reload schema';
