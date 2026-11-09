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
$$ language plpgsql security definer;

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
$$ language sql security definer stable;

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

create policy "Users can update their own profile"
  on public.users for update using (id = auth.uid());

create policy "Users can insert their own profile"
  on public.users for insert with check (id = auth.uid());

create policy "Group members can read fellow member profiles"
  on public.users for select using (
    id = auth.uid()
    or exists (
      select 1 from public.membros_grupo mg
      where mg.user_id = users.id
        and public.is_group_member(mg.grupo_id)
    )
  );

-- Coordinators can look up an invitee without exposing the user directory.
create or replace function public.find_group_invitee(
  p_grupo_id uuid,
  p_email text
)
returns uuid as $$
  select u.id
  from public.users u
  where lower(u.email) = lower(p_email)
    and public.is_group_coordinator(p_grupo_id)
  limit 1;
$$ language sql security definer stable set search_path = '';

revoke all on function public.find_group_invitee(uuid, text) from public;
grant execute on function public.find_group_invitee(uuid, text) to authenticated;

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

create policy "Coordinators can manage celebration items"
  on public.itens_celebracao for insert
  with check (
    exists (
      select 1 from public.celebracoes c
      where c.id = celebracao_id and public.is_group_coordinator(c.grupo_id)
    )
  );

create policy "Coordinators can update celebration items"
  on public.itens_celebracao for update
  using (
    exists (
      select 1 from public.celebracoes c
      where c.id = celebracao_id and public.is_group_coordinator(c.grupo_id)
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
