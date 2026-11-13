-- ============================================================
-- Vozes da Catedral — Supabase Schema
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── Users ─────────────────────────────────────────────────────────────────────
create table if not exists public.users (
  id        uuid primary key references auth.users(id) on delete cascade,
  nome      text not null,
  email     text not null,
  foto      text,
  papel     text not null default 'membro' check (papel in ('coordenador', 'membro')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Auto-create user profile on sign-up via trigger
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, nome, email, foto)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = '';

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Groups ────────────────────────────────────────────────────────────────────
create table if not exists public.grupos (
  id          uuid primary key default uuid_generate_v4(),
  nome        text not null,
  descricao   text,
  criado_por  uuid not null references public.users(id),
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── Group Members ─────────────────────────────────────────────────────────────
create table if not exists public.membros_grupo (
  grupo_id   uuid not null references public.grupos(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  papel      text not null default 'membro' check (papel in ('coordenador', 'membro')),
  created_at timestamptz default now(),
  primary key (grupo_id, user_id)
);

-- ── Songs (Hinário) ───────────────────────────────────────────────────────────
create table if not exists public.musicas (
  id             uuid primary key default uuid_generate_v4(),
  grupo_id       uuid not null references public.grupos(id) on delete cascade,
  titulo         text not null,
  tom_original   text,
  bpm            integer,
  categorias     text[] default '{}',
  momentos_liturgicos text[] not null default '{}',
  conteudo_raw   text not null,
  conteudo_json  jsonb not null,
  criado_por     uuid not null references public.users(id),
  copiada_de_id  uuid references public.musicas(id) on delete set null,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

create unique index if not exists musicas_grupo_origem_unique
  on public.musicas (grupo_id, copiada_de_id)
  where copiada_de_id is not null;

-- ── Celebrations ──────────────────────────────────────────────────────────────
create table if not exists public.celebracoes (
  id          uuid primary key default uuid_generate_v4(),
  grupo_id    uuid not null references public.grupos(id) on delete cascade,
  titulo      text not null,
  data_hora   timestamptz not null,
  criado_por  uuid not null references public.users(id),
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── Celebration Items ─────────────────────────────────────────────────────────
create table if not exists public.itens_celebracao (
  id                uuid primary key default uuid_generate_v4(),
  celebracao_id     uuid not null references public.celebracoes(id) on delete cascade,
  musica_id         uuid references public.musicas(id) on delete set null,
  ordem             integer not null,
  momento_liturgico text not null,
  observacao        text,
  created_at        timestamptz default now()
);

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================

alter table public.users           enable row level security;
alter table public.grupos          enable row level security;
alter table public.membros_grupo   enable row level security;
alter table public.musicas         enable row level security;
alter table public.celebracoes     enable row level security;
alter table public.itens_celebracao enable row level security;

-- Helper function: check if the current user is a member of a group
create or replace function public.is_group_member(p_grupo_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.membros_grupo
    where grupo_id = p_grupo_id and user_id = auth.uid()
  );
$$ language sql security definer stable set search_path = '';

-- Group creators may add themselves when creating the group.
create or replace function public.is_group_creator(p_grupo_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.grupos
    where id = p_grupo_id and criado_por = auth.uid()
  );
$$ language sql security definer stable set search_path = '';

-- Helper function: check if the current user is coordenador of a group
create or replace function public.is_group_coordinator(p_grupo_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.membros_grupo
    where grupo_id = p_grupo_id and user_id = auth.uid() and papel = 'coordenador'
  );
$$ language sql security definer stable set search_path = '';

-- Create a group and its initial coordinator membership atomically.
create or replace function public.create_group(
  p_nome text,
  p_descricao text default null
)
returns uuid as $$
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
$$ language plpgsql security definer set search_path = '';

revoke all on function public.create_group(text, text) from public;
grant execute on function public.create_group(text, text) to authenticated;

-- ── users policies ────────────────────────────────────────────────────────────
create policy "Users can read their own profile"
  on public.users for select using (id = auth.uid());

create policy "Group members can read fellow member profiles"
  on public.users for select using (
    id = auth.uid()
    or exists (
      select 1 from public.membros_grupo mg
      where mg.user_id = users.id
        and public.is_group_member(mg.grupo_id)
    )
  );

revoke all on table public.users from public, anon, authenticated;
revoke select (id, nome, email, foto, papel, created_at, updated_at)
  on table public.users from public, anon, authenticated;

-- Authenticated users need to read the public profile fields used by the app
-- (member directory, current user lookup, group membership checks).
grant select (id, nome, papel) on table public.users to authenticated;

-- Update profile fields without granting clients access to the private email column.
create or replace function public.update_my_profile(
  p_nome text,
  p_foto text,
  p_papel text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;
  if nullif(btrim(p_nome), '') is null then
    raise exception 'O nome é obrigatório';
  end if;
  if p_papel is null or p_papel not in ('coordenador', 'membro') then
    raise exception 'Papel inválido';
  end if;

  update public.users
  set nome = btrim(p_nome),
      foto = p_foto,
      papel = p_papel,
      updated_at = now()
  where id = v_user_id;

  if not found then
    insert into public.users (id, nome, email, foto, papel)
    select v_user_id, btrim(p_nome), au.email, p_foto, p_papel
    from auth.users as au
    where au.id = v_user_id and au.email is not null;
    if not found then
      raise exception 'Não foi possível salvar o perfil';
    end if;
  end if;
end;
$$;

revoke all on function public.update_my_profile(text, text, text) from public;
grant execute on function public.update_my_profile(text, text, text)
  to authenticated;

-- add_group_member_by_email (invite by exact e-mail, never reveals whether the
-- e-mail is registered) is defined in the "Group join requests" section at the
-- end of this file, because it also closes pending join requests.

-- No RPC lists registered users (issue #24): members are invited by exact
-- e-mail through add_group_member_by_email.

-- ── grupos policies ───────────────────────────────────────────────────────────
create policy "Members can read their groups"
  on public.grupos for select
  using (public.is_group_member(id));

create policy "Coordinators can create groups"
  on public.grupos for insert
  with check (criado_por = auth.uid());

create policy "Coordinators can update their groups"
  on public.grupos for update
  using (public.is_group_coordinator(id));

create policy "Coordinators can delete their groups"
  on public.grupos for delete
  using (criado_por = auth.uid());

-- ── membros_grupo policies ────────────────────────────────────────────────────
create policy "Members can view group membership"
  on public.membros_grupo for select
  using (public.is_group_member(grupo_id));

create policy "Coordinators can manage members"
  on public.membros_grupo for insert
  with check (public.is_group_coordinator(grupo_id));

create policy "Coordinators can remove members"
  on public.membros_grupo for delete
  using (public.is_group_coordinator(grupo_id));

-- Allow self-insert for new group creation (creator adds themselves)
create policy "Users can add themselves to a group"
  on public.membros_grupo for insert
  with check (
    user_id = auth.uid()
    and public.is_group_creator(grupo_id)
  );

-- ── musicas policies ──────────────────────────────────────────────────────────
create policy "Authenticated users can browse song catalog"
  on public.musicas for select
  using ((select auth.uid()) is not null);

create policy "Coordinators can manage songs"
  on public.musicas for insert
  with check (public.is_group_coordinator(grupo_id));

create policy "Coordinators can update songs"
  on public.musicas for update
  using (public.is_group_coordinator(grupo_id));

create policy "Coordinators can delete songs"
  on public.musicas for delete
  using (public.is_group_coordinator(grupo_id));

-- Copy a catalog song into a group's independent library.
create or replace function public.copy_song_to_group(
  p_musica_id uuid,
  p_grupo_id uuid
)
returns uuid as $$
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
    momentos_liturgicos,
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
    v_source.momentos_liturgicos,
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
$$ language plpgsql security definer set search_path = '';

revoke all on function public.copy_song_to_group(uuid, uuid) from public;
grant execute on function public.copy_song_to_group(uuid, uuid) to authenticated;

-- Copy a celebration and its songs into another group's independent library.
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

-- ── celebracoes policies ──────────────────────────────────────────────────────
create policy "Group members can read celebrations"
  on public.celebracoes for select
  using (public.is_group_member(grupo_id));

create policy "Coordinators can manage celebrations"
  on public.celebracoes for insert
  with check (public.is_group_coordinator(grupo_id));

create policy "Coordinators can update celebrations"
  on public.celebracoes for update
  using (public.is_group_coordinator(grupo_id));

create policy "Coordinators can delete celebrations"
  on public.celebracoes for delete
  using (public.is_group_coordinator(grupo_id));

-- ── itens_celebracao policies ─────────────────────────────────────────────────
create policy "Group members can read celebration items"
  on public.itens_celebracao for select
  using (
    exists (
      select 1 from public.celebracoes c
      where c.id = celebracao_id and public.is_group_member(c.grupo_id)
    )
  );

-- Items may only reference songs of the celebration's own group (issue #23).
create policy "Coordinators can manage celebration items"
  on public.itens_celebracao for insert
  with check (
    exists (
      select 1 from public.celebracoes c
      where c.id = itens_celebracao.celebracao_id
        and public.is_group_coordinator(c.grupo_id)
    )
    and (
      itens_celebracao.musica_id is null
      or exists (
        select 1
        from public.celebracoes c
        join public.musicas m on m.grupo_id = c.grupo_id
        where c.id = itens_celebracao.celebracao_id
          and m.id = itens_celebracao.musica_id
      )
    )
  );

create policy "Coordinators can update celebration items"
  on public.itens_celebracao for update
  using (
    exists (
      select 1 from public.celebracoes c
      where c.id = itens_celebracao.celebracao_id
        and public.is_group_coordinator(c.grupo_id)
    )
  )
  with check (
    exists (
      select 1 from public.celebracoes c
      where c.id = itens_celebracao.celebracao_id
        and public.is_group_coordinator(c.grupo_id)
    )
    and (
      itens_celebracao.musica_id is null
      or exists (
        select 1
        from public.celebracoes c
        join public.musicas m on m.grupo_id = c.grupo_id
        where c.id = itens_celebracao.celebracao_id
          and m.id = itens_celebracao.musica_id
      )
    )
  );

create policy "Coordinators can delete celebration items"
  on public.itens_celebracao for delete
  using (
    exists (
      select 1 from public.celebracoes c
      where c.id = celebracao_id and public.is_group_coordinator(c.grupo_id)
    )
  );

-- ── Hardening (issue #23) ─────────────────────────────────────────────────────
-- Authorship: criado_por is taken from the JWT on insert and immutable after.
create or replace function public.set_criado_por()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      new.criado_por := auth.uid();
    end if;
  else
    new.criado_por := old.criado_por;
  end if;
  return new;
end;
$$;

revoke all on function public.set_criado_por() from public, anon, authenticated;

drop trigger if exists musicas_set_criado_por on public.musicas;
create trigger musicas_set_criado_por
  before insert or update on public.musicas
  for each row execute function public.set_criado_por();

drop trigger if exists celebracoes_set_criado_por on public.celebracoes;
create trigger celebracoes_set_criado_por
  before insert or update on public.celebracoes
  for each row execute function public.set_criado_por();

-- A group must always keep at least one coordinator.
create or replace function public.protect_last_coordinator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.papel = 'coordenador'
     and (tg_op = 'DELETE' or new.papel is distinct from 'coordenador')
     and exists (select 1 from public.grupos g where g.id = old.grupo_id)
     and exists (select 1 from public.users u where u.id = old.user_id)
     and not exists (
       select 1 from public.membros_grupo m
       where m.grupo_id = old.grupo_id
         and m.papel = 'coordenador'
         and m.user_id <> old.user_id
     )
  then
    raise exception 'O grupo precisa ter pelo menos um coordenador';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.protect_last_coordinator() from public, anon, authenticated;

drop trigger if exists membros_grupo_protect_last_coordinator on public.membros_grupo;
create trigger membros_grupo_protect_last_coordinator
  before update or delete on public.membros_grupo
  for each row execute function public.protect_last_coordinator();

-- Signed-out (anon) clients must not execute any RPC / helper function.
-- add_group_member_by_email: revoked in the "Group join requests" section.
revoke execute on function public.copy_celebration_to_group(uuid, uuid) from public, anon;
revoke execute on function public.copy_song_to_group(uuid, uuid) from public, anon;
revoke execute on function public.create_group(text, text) from public, anon;
revoke execute on function public.handle_new_user() from public, anon;
revoke execute on function public.is_group_coordinator(uuid) from public, anon;
revoke execute on function public.is_group_creator(uuid) from public, anon;
revoke execute on function public.is_group_member(uuid) from public, anon;
revoke execute on function public.update_my_profile(text, text, text) from public, anon;

-- ══ Group join requests (issue #41) ═══════════════════════════════════════════
-- Same content as supabase/migrations/20261116_group_join_requests.sql.
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

