# Handoff — Vozes da Catedral

> Documento de continuidade para outra sessão de IA ou desenvolvedor.
> Última atualização: novembro/2026

---

## Resumo Executivo

App Flutter (Android + Web) para gestão e execução de cantos litúrgicos em missas da Igreja Católica.
Projeto piloto: Coral da Catedral de Santo Antônio — Piracicaba/SP.

**Stack:** Flutter 3.x · Riverpod · go_router · Drift (SQLite) · Supabase (free tier)
**Repositório:** https://github.com/abpaula77/Vozes_da_Catedral
**GitHub Project (Kanban):** https://github.com/users/abpaula77/projects/3
**Último commit:** `7b7bc29` — feat: compartilhar catalogo de musicas entre grupos

---

## Estado das Tasks

| Task | Descrição | Status | Issue | Commit |
|------|-----------|--------|-------|--------|
| 1 | Setup base, Supabase config, schema Drift, modelos | ✅ Done | #10 | 5218503 |
| 2 | Auth (login, signup, onboarding papel) | ✅ Done | #11 | 3d5e8fc |
| 3 | Parser de cifras + CifraView (RobotoMono) | ✅ Done | #12 | 3d5e8fc |
| 4 | Hinário local + importação de .txt | ✅ Done | #13 | 3d5e8fc |
| 5 | Grupos, RLS, gestão de membros | ✅ Correção via RPC aplicada no Supabase; smoke test pendente | #14 | — |
| 6 | Catálogo compartilhado e sync de músicas | ✅ Catálogo/cópias aplicado no Supabase; teste entre grupos pendente | #15 | — |
| 7 | Montador de Celebração (Rito Romano) | ✅ Implementado e aberto no aparelho; validação funcional Supabase/offline pendente | #16 | — |
| 8 | Modo Performance (wakelock, dark mode, rolagem) | ⏳ Todo | #17 | — |
| 9 | APK release + deploy web Vercel | ⏳ Todo | #18 | — |

---

## Configurações de Ambiente

| Item | Valor |
|------|-------|
| Workspace local | `d:\Vozes_da_Catedral` |
| Flutter SDK | `C:\Flutter\flutter` (v3.29.0, Dart 3.7.0) |
| Supabase Project ID | `npujroyocclobjrpeaed` |
| Supabase URL | `https://npujroyocclobjrpeaed.supabase.co` |
| Supabase Anon Key | Ver `d:\Vozes_da_Catedral\.env` ou `lib/core/config/supabase_config.dart` |
| Dispositivo Android | Samsung SM-A546E · serial `RQCW701905N` · Android 16 (API 36) |
| GitHub CLI | autenticado como `abpaula77` |

---

## Build Android

O APK debug foi compilado e instalado no Samsung (`RQCW701905N`). Em 08/11/2026, `flutter run -d RQCW701905N --no-pub --no-resident` iniciou o app com sucesso; a migração Drift local v1→v2 também foi exercitada ao abrir o banco existente.

### Para repetir:

```bash
cd d:\Vozes_da_Catedral
adb devices   # confirmar que RQCW701905N aparece como "device"
flutter clean
flutter run -d RQCW701905N
```

Para validar somente a compilação, use `flutter build apk --debug --no-pub`.

### Fixes Android já aplicados:
- `android/settings.gradle.kts` → Kotlin `2.1.0` (era 1.8.22)
- `android/app/build.gradle.kts` → `ndkVersion = "27.0.12077973"` (era flutter.ndkVersion)

---

## Supabase — Schema já aplicado ✅

O arquivo `supabase/schema.sql` foi executado no SQL Editor do Supabase dashboard.
Tabelas criadas: `users`, `grupos`, `membros_grupo`, `musicas`, `celebracoes`, `itens_celebracao`
Trigger: auto-criação de perfil no `auth.users` ao fazer signup
RLS: Coordenador tem escrita no grupo, Membro somente leitura

---

## Arquitetura Atual (o que está implementado)

```
lib/
├── main.dart                             inicializa Supabase + ProviderScope
├── app.dart                              MaterialApp.router + temas
├── core/
│   ├── config/supabase_config.dart       URL + anon key via dart-define
│   ├── database/
│   │   ├── tables.dart                   6 tabelas Drift
│   │   ├── app_database.dart             queries + DAOs, schema v3
│   │   ├── app_database.g.dart           gerado (build_runner)
│   │   └── database_provider.dart        Provider<AppDatabase>
│   ├── router/app_router.dart            GoRouter + redirect auth + nav helpers
│   └── theme/app_theme.dart              tema claro/escuro (dark otimizado altar)
└── features/
    ├── auth/
    │   ├── domain/user_model.dart
    │   └── presentation/
    │       ├── auth_provider.dart         AuthService, supabaseProvider, authSessionProvider
    │       ├── login_screen.dart          login + signup email/senha
    │       └── onboarding_screen.dart     seleção papel (Coordenador/Membro) 1º acesso
    ├── groups/
    │   ├── domain/group_model.dart        GrupoModel, PapelGrupo enum
    │   ├── data/groups_provider.dart      GruposService (createGrupo, syncGrupos, addMembro, removeMembro)
    │   └── presentation/
    │       ├── groups_screen.dart         lista grupos + FAB criar grupo
    │       ├── group_detail_screen.dart   tabs: Hinário | acesso às celebrações
    │       └── group_members_screen.dart  lista, convite e remoção de membros
    ├── songs/
    │   ├── domain/
    │   │   ├── song_model.dart            SongModel, SongContent, SongSection, SongLine
    │   │   └── song_parser.dart           parser .txt → JSON (seções, cifra+letra)
    │   ├── data/songs_provider.dart       SongsService (importFromFile, publishMusicas, syncMusicas)
    │   └── presentation/
    │       ├── cifra_view.dart            ⭐ CifraView com RobotoMono, toggle cifras, font size
    │       ├── songs_screen.dart          hinário com import .txt, delete, sync
    │       └── song_detail_screen.dart    visualizador CifraView + controles fonte/toggle
    ├── celebrations/
    │   ├── data/celebrations_provider.dart CRUD local e sincronização Supabase
    │   ├── domain/celebration_model.dart  CelebracaoModel, MomentoLiturgico (12 momentos)
    │   └── presentation/celebrations_screen.dart lista, edição e montador
    └── splash/presentation/splash_screen.dart
```

### Rotas (go_router)
```
/                   → SplashScreen (redireciona para /login ou /groups)
/login              → LoginScreen
/onboarding         → OnboardingScreen (seleção de papel no 1º login)
/groups             → GroupsScreen
/groups/:grupoId    → GroupDetailScreen
/groups/:grupoId/members → GroupMembersScreen
/groups/:grupoId/songs/:musicaId → SongDetailScreen
/groups/:grupoId/celebrations → CelebrationsScreen
/groups/:grupoId/celebrations/:celebracaoId → CelebrationDetailScreen
```

### Fluxo de auth
1. Splash verifica sessão Supabase
2. Se logado: busca perfil em `users` → se não existe → `/onboarding` → se existe → `/groups`
3. Se não logado → `/login`
4. Qualquer mudança na sessão atualiza o router via `_AuthNotifier`

---

## Modelo de Dados Supabase

```
users              id (uuid, FK auth.users), nome, email, foto, papel
grupos             id, nome, descricao, criado_por (FK users)
membros_grupo      grupo_id + user_id (PK composta), papel (coordenador|membro)
musicas            id, grupo_id, titulo, tom_original, bpm, categorias[], conteudo_raw, conteudo_json
celebracoes        id, grupo_id, titulo, data_hora, criado_por
itens_celebracao   id, celebracao_id, musica_id, ordem, momento_liturgico, observacao
```

**RLS resumido:**
- `users`: leitura própria + perfis de pessoas do mesmo grupo; convites por RPC restrita a coordenadores
- `grupos`: leitura para membros, escrita para coordenador/criador
- `membros_grupo`: leitura para membros do grupo, escrita para coordenador
- `musicas`, `celebracoes`, `itens_celebracao`: leitura para membros, escrita para coordenador

---

## Formato de Arquivo de Música (.txt)

```text
[TITULO]: Santo, Santo, Santo
[TOM]: D
[CATEGORIA]: santo
[BPM]: 80

[ESTROFE]
D        F#m
Santo, Santo, Santo
G        A4  A
Senhor Deus do Universo

[REFRAO]
D        A
Hosana nas alturas!
G        A  D
Hosana nas alturas!
```

Seções suportadas: ESTROFE, REFRAO/REFRÃO, PONTE, PRE-REFRAO, INTRO, OUTRO, CODA, VERSO

---

## Próximas Tasks em Detalhe

### Task 5 — Grupos, papéis e controle de acesso (issue #14)
O `GruposService` já existe em `lib/features/groups/data/groups_provider.dart` com:
- `createGrupo(nome, descricao)` — cria no Supabase + SQLite local
- `syncGrupos()` — baixa grupos do usuário para SQLite
- `addMembro(grupoId, email, papel)` — busca usuário por email e adiciona
- `removeMembro(grupoId, userId)` — remove membro

**Implementado nesta continuação:**
- Tela de membros com papéis, convite por e-mail e remoção para coordenadores
- Sincronização automática ao abrir a lista de grupos e botão manual com erros visíveis
- Reconciliação do cache SQLite com a lista remota do usuário
- RLS sem busca pública do diretório de usuários; coordenador procura convite por RPC, e auto-inclusão em grupo fica limitada ao criador

**Validação operacional pendente:**
- Testar com uma conta membro que a lista de grupos não inclui grupos aos quais ela não pertence; esse teste multiusuário remoto ainda não foi executado nesta sessão
- A migration `supabase/migrations/20261108_task5_group_access.sql` foi aplicada no Supabase em 08/11/2026
- A migration `supabase/migrations/20261108_fix_group_creation.sql` foi aplicada no Supabase em 08/11/2026; o APK com criação via RPC foi instalado no dispositivo

### Task 6 — Sincronização de músicas (issue #15)
O `SongsService` já existe em `lib/features/songs/data/songs_provider.dart` com:
- `publishMusicas(grupoId)` — já implementado (upload local → Supabase)
- `syncMusicas(grupoId)` — já implementado (download Supabase → local)

**Implementado nesta continuação:**
- IDs locais de músicas agora são UUIDs compatíveis com o schema remoto; IDs legados são convertidos antes da publicação, mantendo referências locais
- Persistência local da última sincronização bem-sucedida e indicador de horário no Hinário
- `CelebracoesService.syncCelebracoes` baixa celebrações e itens para SQLite em transação, preparando o cache offline para a Task 7
- Migração Drift v1→v2 cria a tabela local de status sem apagar dados existentes
- Catálogo compartilhado: usuários autenticados podem consultar músicas de todos os grupos; coordenadores adicionam uma cópia independente ao próprio hinário
- A cópia registra a música de origem e é idempotente por grupo; alterações posteriores no original não alteram a cópia
- Guia para preparar arquivos de importação: `docs/formato-musicas.md`

**Validação pendente:**
- Testar manualmente com duas contas: coordenador publica, membro sincroniza e abre as músicas offline
- A migration `supabase/migrations/20261108_shared_song_catalog.sql` foi aplicada no Supabase em 08/11/2026; o APK com catálogo compartilhado foi instalado no dispositivo
- O APK debug compila; os testes do parser TXT e dos UUIDs passam. O analyzer reporta apenas um aviso informativo preexistente.

### Task 7 — Montador de Celebração (issue #16)
O `MomentoLiturgico` enum já existe com os 12 momentos.
O `defaultRitoRomano(celebracaoId)` factory já cria a estrutura vazia.

**Implementado nesta continuação:**
- Lista de celebrações e formulário para título, data e horário; coordenadores podem criar e editar
- Montador com os 12 momentos do Rito Romano, seleção de músicas do hinário local e observações por momento
- Alterações são salvas primeiro no SQLite e mantêm flags de sincronização pendente para funcionar offline
- Sincronização envia celebrações/itens pendentes e baixa os dados remotos; ações de escrita respeitam as políticas RLS existentes
- IDs de celebrações e itens gerados como UUID; migração Drift v2→v3 adiciona estado de sincronização sem apagar os dados existentes
- Reconciliação remove do cache as celebrações apagadas remotamente

**Validação pendente:**
- `flutter test` passou; `dart analyze` nos arquivos alterados não encontrou problemas
- `flutter build apk --debug` passou; APK instalado e app aberto no Samsung SM-A546E (`RQCW701905N`) em 09/11/2026
- A conexão do Flutter com o protocolo de depuração caiu depois da abertura; instalação e processo/tela ativa foram confirmados via ADB
- Testar no Supabase as operações de coordenador/membro e a sincronização com rede indisponível e posterior restauração; não foi necessária migration Supabase nesta task

### Task 8 — Modo Performance (issue #17)
**O que implementar:**
- `PerformanceScreen` — recebe celebracaoId, carrega todos os itens offline do SQLite
- `wakelock_plus`: `WakelockPlus.enable()` ao entrar, `disable()` ao sair
- Rolagem contínua: `ListView` com todas as músicas da celebração em sequência
- Barra flutuante de controles: fonte+/-, toggle cifras, tema dark/light
- Navegação rápida: índice lateral ou bottom bar com os momentos
- Dark mode: já configurado em `AppTheme.dark` (surface `#1A1A1A`, onSurface `#E8E0D5`)

### Task 9 — Build e Deploy (issue #18)
```bash
# APK release (sideload Android)
flutter build apk --release
# Arquivo gerado: build/app/outputs/flutter-apk/app-release.apk

# Web
flutter build web
# Deploy: vercel --prod (instalar com npm i -g vercel)
```
- Antes do release: trocar ícone padrão Flutter (ic_launcher.png em todas as densidades)
- Criar release no GitHub com o APK anexado

---

## Comandos Úteis

```bash
# Rodar no Android
flutter run -d RQCW701905N

# Regenerar código Drift após mudar tabelas
dart run build_runner build --delete-conflicting-outputs

# Verificar problemas de código
flutter analyze

# Limpar build cache
flutter clean

# Ver dispositivos disponíveis
flutter devices
adb devices
```

---

## Como Retomar com Outra IA

1. Leia este arquivo (`HANDOFF.md`)
2. Confirme o dispositivo Android: `adb devices` → deve mostrar `RQCW701905N device`
3. Tente o build: `flutter run -d RQCW701905N` em `d:\Vozes_da_Catedral`
4. Se o build funcionar, o app deve mostrar tela de splash → login
5. Crie uma conta de teste no app → será redirecionado para onboarding
6. **Lembre o usuário:** antes de testar grupos/músicas, precisa criar um grupo pelo app
7. Continue pela **Task 5** (testar o que já está implementado + completar partes faltantes)

> Para atualizar o GitHub Projects ao concluir cada task:
> `gh issue close <NUMBER> --repo abpaula77/Vozes_da_Catedral --comment "Task concluída: <descrição>"`
> E atualizar o status no board via `gh project item-edit`
