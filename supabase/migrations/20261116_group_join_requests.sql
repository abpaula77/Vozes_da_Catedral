-- Issue #41: group join requests (solicitar entrada + aprovação do coordenador).
-- Spec: .kiro/specs/pedido-filiacao-grupos/
--
-- Additive only: current app builds keep working (syncGrupos uses grupos(*)
-- and ignores the new column). Apply BEFORE publishing the new app.

-- ── 1.1 Structure ─────────────────────────────────────────────────────────────

-- Groups are closed to join requests by default (opt-in).
alter table public.grupos
  add column if not exists aceita_solicitacoes boolean not null default false;

create table if not exists public.solicitacoes_grupo (
  id            uuid primary key default gen_random_uuid(),
  grupo_id      uuid not null references public.grupos(id) on delete cascade,
  user_id       uuid not null references public.users(id) on delete cascade,
  status        text not null default 'pendente'
                  check (status in ('pendente', 'aprovada', 'recusada', 'cancelada')),
  mensagem      text check (mensagem is null or char_length(mensagem) <= 280),
  criada_em     timestamptz not null default now(),
  decidida_em   timestamptz,
  decidida_por  uuid references public.users(id) on delete set null
);

-- One pending request per user and group, enforced even under concurrency.
create unique index if not exists solicitacoes_grupo_pendente_unique
  on public.solicitacoes_grupo (grupo_id, user_id)
  where status = 'pendente';

create index if not exists solicitacoes_grupo_pendentes_por_grupo
  on public.solicitacoes_grupo (grupo_id)
  where status = 'pendente';

create index if not exists solicitacoes_grupo_por_usuario
  on public.solicitacoes_grupo (user_id, grupo_id);

-- Covers the decidida_por FK (used when a user account is deleted).
create index if not exists solicitacoes_grupo_decidida_por
  on public.solicitacoes_grupo (decidida_por);

-- No direct client access: every read and write goes through the RPCs below,
-- which return only the columns each role may see (e.g. requesters never see
-- decidida_por). RLS is enabled without policies, so direct access is denied.
alter table public.solicitacoes_grupo enable row level security;
revoke all on table public.solicitacoes_grupo from public, anon, authenticated;

-- ── 1.2 Coordinator RPCs ──────────────────────────────────────────────────────

create or replace function public.definir_aceita_solicitacoes(
  p_grupo_id uuid,
  p_aceita boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if p_aceita is null then
    raise exception 'Valor inválido';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem alterar esta opção.';
  end if;

  -- Pending requests are kept when the group is closed (requirement 1.4).
  update public.grupos
  set aceita_solicitacoes = p_aceita,
      updated_at = now()
  where id = p_grupo_id;
end;
$$;

create or replace function public.obter_aceita_solicitacoes(p_grupo_id uuid)
returns boolean
language plpgsql
security definer
stable
set search_path = ''
as $$
declare
  v_aceita boolean;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not public.is_group_member(p_grupo_id) then
    raise exception 'Grupo não encontrado.';
  end if;

  select g.aceita_solicitacoes into v_aceita
  from public.grupos as g
  where g.id = p_grupo_id;

  return coalesce(v_aceita, false);
end;
$$;

-- The only place where a user's photo is exposed: to coordinators, and only
-- for users with a pending request to their group (requirements 6.2, 6.4).
create or replace function public.listar_solicitacoes_pendentes(p_grupo_id uuid)
returns table (
  id uuid,
  user_id uuid,
  nome text,
  foto text,
  mensagem text,
  criada_em timestamptz
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
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem ver as solicitações.';
  end if;

  return query
  select s.id, s.user_id, u.nome, u.foto, s.mensagem, s.criada_em
  from public.solicitacoes_grupo as s
  join public.users as u on u.id = s.user_id
  where s.grupo_id = p_grupo_id
    and s.status = 'pendente'
    and not exists (
      select 1 from public.membros_grupo as mg
      where mg.grupo_id = s.grupo_id and mg.user_id = s.user_id
    )
  order by s.criada_em;
end;
$$;

create or replace function public.contar_solicitacoes_pendentes()
returns table (grupo_id uuid, total bigint)
language plpgsql
security definer
stable
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  return query
  select s.grupo_id, count(*)
  from public.solicitacoes_grupo as s
  join public.membros_grupo as coord
    on coord.grupo_id = s.grupo_id
   and coord.user_id = auth.uid()
   and coord.papel = 'coordenador'
  where s.status = 'pendente'
    and not exists (
      select 1 from public.membros_grupo as mg
      where mg.grupo_id = s.grupo_id and mg.user_id = s.user_id
    )
  group by s.grupo_id;
end;
$$;

create or replace function public.decidir_solicitacao(
  p_solicitacao_id uuid,
  p_aprovar boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_solicitacao public.solicitacoes_grupo%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if p_aprovar is null then
    raise exception 'Decisão inválida';
  end if;

  -- Row lock: concurrent decisions by two coordinators are serialized, and
  -- the second one sees a non-pending status (requirement 5.6).
  select * into v_solicitacao
  from public.solicitacoes_grupo
  where id = p_solicitacao_id
  for update;

  if not found or not public.is_group_coordinator(v_solicitacao.grupo_id) then
    raise exception 'Solicitação não encontrada.';
  end if;
  if v_solicitacao.status <> 'pendente' then
    raise exception 'Esta solicitação já foi decidida.';
  end if;

  if p_aprovar then
    -- Atomic with the status change (requirement 5.4). The conflict clause
    -- covers a user who joined meanwhile through an e-mail invite.
    insert into public.membros_grupo (grupo_id, user_id, papel)
    values (v_solicitacao.grupo_id, v_solicitacao.user_id, 'membro')
    on conflict (grupo_id, user_id) do nothing;
  end if;

  update public.solicitacoes_grupo
  set status = case when p_aprovar then 'aprovada' else 'recusada' end,
      decidida_em = now(),
      decidida_por = auth.uid()
  where id = p_solicitacao_id;
end;
$$;

-- ── 1.3 Requester RPCs ────────────────────────────────────────────────────────

-- Open groups the user is not a member of. Closed groups are never listed
-- (requirement 6.7). Only id, name and description are exposed (2.2).
create or replace function public.listar_grupos_abertos()
returns table (
  id uuid,
  nome text,
  descricao text,
  meu_status text,
  pode_solicitar_em timestamptz
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

  return query
  select
    g.id,
    g.nome,
    g.descricao,
    case
      when pendente.id is not null then 'pendente'
      when recusa.decidida_em > now() - interval '7 days' then 'recusada'
      else null
    end,
    case
      when pendente.id is null
       and recusa.decidida_em > now() - interval '7 days'
        then recusa.decidida_em + interval '7 days'
      else null
    end
  from public.grupos as g
  left join lateral (
    select s.id
    from public.solicitacoes_grupo as s
    where s.grupo_id = g.id and s.user_id = auth.uid() and s.status = 'pendente'
    limit 1
  ) as pendente on true
  left join lateral (
    select s.decidida_em
    from public.solicitacoes_grupo as s
    where s.grupo_id = g.id and s.user_id = auth.uid() and s.status = 'recusada'
    order by s.decidida_em desc
    limit 1
  ) as recusa on true
  where g.aceita_solicitacoes
    and not exists (
      select 1 from public.membros_grupo as mg
      where mg.grupo_id = g.id and mg.user_id = auth.uid()
    )
  order by lower(g.nome);
end;
$$;

create or replace function public.solicitar_entrada(
  p_grupo_id uuid,
  p_mensagem text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_aceita boolean;
  v_mensagem text := nullif(btrim(p_mensagem), '');
  v_ultima_recusa timestamptz;
  v_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  -- Same message for missing and closed groups: do not reveal that a closed
  -- group exists (requirement 6.7).
  select g.aceita_solicitacoes into v_aceita
  from public.grupos as g
  where g.id = p_grupo_id;
  if not found or not v_aceita then
    raise exception 'Grupo não encontrado ou não está aceitando solicitações.';
  end if;

  if public.is_group_member(p_grupo_id) then
    raise exception 'Você já faz parte deste grupo.';
  end if;

  if v_mensagem is not null and char_length(v_mensagem) > 280 then
    raise exception 'A mensagem deve ter no máximo 280 caracteres.';
  end if;

  select s.decidida_em into v_ultima_recusa
  from public.solicitacoes_grupo as s
  where s.grupo_id = p_grupo_id
    and s.user_id = v_user_id
    and s.status = 'recusada'
  order by s.decidida_em desc
  limit 1;

  if v_ultima_recusa > now() - interval '7 days' then
    raise exception 'Você poderá solicitar novamente a partir de %.',
      to_char(
        (v_ultima_recusa + interval '7 days') at time zone 'America/Sao_Paulo',
        'DD/MM/YYYY'
      );
  end if;

  begin
    insert into public.solicitacoes_grupo (grupo_id, user_id, mensagem)
    values (p_grupo_id, v_user_id, v_mensagem)
    returning id into v_id;
  exception when unique_violation then
    raise exception 'Você já tem uma solicitação pendente para este grupo.';
  end;

  return v_id;
end;
$$;

-- The requester's own requests: pending ones, plus recent decisions (7 days)
-- so the app can show "aprovada" or "recusada until ...". Never returns
-- decidida_por (requirement 4.4).
create or replace function public.listar_minhas_solicitacoes()
returns table (
  id uuid,
  grupo_id uuid,
  grupo_nome text,
  status text,
  mensagem text,
  criada_em timestamptz,
  pode_solicitar_em timestamptz
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

  return query
  select
    s.id,
    s.grupo_id,
    g.nome,
    s.status,
    s.mensagem,
    s.criada_em,
    case
      when s.status = 'recusada' then s.decidida_em + interval '7 days'
      else null
    end
  from public.solicitacoes_grupo as s
  join public.grupos as g on g.id = s.grupo_id
  where s.user_id = auth.uid()
    and (
      s.status = 'pendente'
      or (
        s.status in ('aprovada', 'recusada')
        and s.decidida_em > now() - interval '7 days'
      )
    )
  order by s.criada_em desc;
end;
$$;

create or replace function public.cancelar_solicitacao(p_solicitacao_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  update public.solicitacoes_grupo
  set status = 'cancelada',
      decidida_em = now(),
      decidida_por = auth.uid()
  where id = p_solicitacao_id
    and user_id = auth.uid()
    and status = 'pendente';

  if not found then
    raise exception 'Solicitação não encontrada ou já decidida.';
  end if;
end;
$$;

-- ── 1.4 E-mail invite closes a pending request ───────────────────────────────
-- Same signature and behavior for the app; additionally, if the invited user
-- had a pending request to this group, it is marked as approved by the
-- inviting coordinator. Still never reveals whether the e-mail exists.
create or replace function public.add_group_member_by_email(
  p_grupo_id uuid,
  p_email text,
  p_papel text default 'membro'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not public.is_group_coordinator(p_grupo_id) then
    raise exception 'Somente coordenadores podem adicionar membros';
  end if;
  if nullif(btrim(p_email), '') is null then
    raise exception 'O e-mail é obrigatório';
  end if;
  if p_papel is null or p_papel not in ('coordenador', 'membro') then
    raise exception 'Papel inválido';
  end if;

  select u.id into v_user_id
  from public.users as u
  where lower(btrim(u.email)) = lower(btrim(p_email))
  limit 1;

  if v_user_id is not null then
    insert into public.membros_grupo (grupo_id, user_id, papel)
    values (p_grupo_id, v_user_id, p_papel)
    on conflict (grupo_id, user_id) do nothing;

    update public.solicitacoes_grupo
    set status = 'aprovada',
        decidida_em = now(),
        decidida_por = auth.uid()
    where grupo_id = p_grupo_id
      and user_id = v_user_id
      and status = 'pendente';
  end if;
end;
$$;

-- ── Grants ────────────────────────────────────────────────────────────────────

revoke all on function public.definir_aceita_solicitacoes(uuid, boolean) from public, anon;
revoke all on function public.obter_aceita_solicitacoes(uuid) from public, anon;
revoke all on function public.listar_solicitacoes_pendentes(uuid) from public, anon;
revoke all on function public.contar_solicitacoes_pendentes() from public, anon;
revoke all on function public.decidir_solicitacao(uuid, boolean) from public, anon;
revoke all on function public.listar_grupos_abertos() from public, anon;
revoke all on function public.solicitar_entrada(uuid, text) from public, anon;
revoke all on function public.listar_minhas_solicitacoes() from public, anon;
revoke all on function public.cancelar_solicitacao(uuid) from public, anon;
revoke all on function public.add_group_member_by_email(uuid, text, text) from public, anon;

grant execute on function public.definir_aceita_solicitacoes(uuid, boolean) to authenticated;
grant execute on function public.obter_aceita_solicitacoes(uuid) to authenticated;
grant execute on function public.listar_solicitacoes_pendentes(uuid) to authenticated;
grant execute on function public.contar_solicitacoes_pendentes() to authenticated;
grant execute on function public.decidir_solicitacao(uuid, boolean) to authenticated;
grant execute on function public.listar_grupos_abertos() to authenticated;
grant execute on function public.solicitar_entrada(uuid, text) to authenticated;
grant execute on function public.listar_minhas_solicitacoes() to authenticated;
grant execute on function public.cancelar_solicitacao(uuid) to authenticated;
grant execute on function public.add_group_member_by_email(uuid, text, text) to authenticated;

notify pgrst, 'reload schema';
