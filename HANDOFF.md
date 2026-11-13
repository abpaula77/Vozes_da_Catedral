# Handoff — Vozes da Catedral

> Documento de continuidade para outra sessão de IA ou desenvolvedor.
> Última atualização: 13/11/2026

---

## Resumo Executivo

App Flutter (Android + Web) para gestão e execução de cantos litúrgicos em missas da Igreja Católica.
Projeto piloto: Coral da Catedral de Santo Antônio — Piracicaba/SP.

**Stack:** Flutter 3.x · Riverpod · go_router · Drift (SQLite) · Supabase (free tier)
**Repositório:** https://github.com/abpaula77/Vozes_da_Catedral
**GitHub Project (Kanban):** https://github.com/users/abpaula77/projects/3
**Último commit na `master`:** `c714354` — merge do PR #38 (`vercel.json` dentro de `build/web`)
**Produção (13/11/2026):** Web publicado na Vercel a partir de `c714354`; APK release 0.1.1 (code 2) instalado no Samsung de teste

**Fluxo de trabalho a partir de 12/11/2026:** uma issue por melhoria e uma branch por issue (`fix/<n>-<nome>`), com PR próprio. Não commitar direto na `master`.

---

## Estado das Tasks

| Task | Descrição | Status | Issue | Commit |
|------|-----------|--------|-------|--------|
| 1 | Setup base, Supabase config, schema Drift, modelos | ✅ Done | #10 | 5218503 |
| 2 | Auth (login, signup, onboarding papel) | ✅ Done | #11 | 3d5e8fc |
| 3 | Parser de cifras + CifraView (RobotoMono) | ✅ Done | #12 | 3d5e8fc |
| 4 | Hinário local + importação de .txt | ✅ Done | #13 | 3d5e8fc |
| 5 | Grupos, RLS, gestão de membros | ✅ Concluída | #14 | fd79835 |
| 6 | Catálogo compartilhado e sync de músicas | ✅ Concluída | #15 | 7b7bc29 |
| 7 | Montador de Celebração (Rito Romano) | ✅ Concluída, com correção de sincronização | #16 | cb28a56 |
| 8 | Modo Performance (wakelock, dark mode, rolagem) | ✅ Implementada e testada no aparelho | #17 | 5ed8db9 |
| 9 | APK release + deploy web Vercel | ✅ Build e deploy validados pelo usuário | #18 | 145af1e |
| 10 | Classificação de músicas por momento litúrgico e reutilização | ✅ Concluída, publicada e validada pelo usuário | #19 | 02cbbfe |
| 11 | Autenticação com Google (Web e Android) | ✅ Implementada e validada pelo usuário na Web e Android | #20 | 44ad595 |

---

## Varredura técnica e de segurança (12–13/11/2026)

Resultado da varredura: `flutter analyze` sem problemas e `flutter test` com 6 testes passando. A cobertura de testes é baixa (só parser, UUID e modelo de celebração; sync, RLS e auth não têm teste).

| Issue | Tema | Estado |
|-------|------|--------|
| #22 | `schema.sql` desatualizado + `search_path` das funções `security definer` | ✅ Fechada (PR #35). Migration aplicada |
| #23 | RLS: autor imutável, último coordenador, música do mesmo grupo, revogar `anon` | ✅ Fechada (PR #36). Migration aplicada |
| #24 | `list_group_invitees` permite enumerar todos os usuários (risco médio) | Aberta, sem branch. Muda o fluxo de convite: combinar com o usuário antes |
| #25 | Cabeçalhos de segurança Web (CSP etc.) | ✅ Fechada (PRs #37 e #38). Validada em produção pelo usuário |
| #26 | Android: `allowBackup`, deep link/App Links, assinatura de release | Aberta, sem branch |
| #27 | Política de direitos autorais do catálogo compartilhado | Aberta, sem branch (decisão do usuário) |

(#28 a #33 foram duplicatas e estão fechadas.)

### PRs e branches
- Mergeados em `master`: **#34** (minimização de dados), **#35** (#22), **#36** (#23), **#37** e **#38** (#25).
- Ordem sugerida do restante: #26, #24, #27.

### Deploy Web (importante)
- O deploy é `vercel deploy .\build\web --prod`, então a raiz do deploy é `build/web`.
- A configuração da Vercel fica em **`web/vercel.json`** (o `flutter build web` copia para `build/web`). Um `vercel.json` na raiz do repositório **não** é lido; foi por isso que a CSP e os rewrites não chegavam à produção até o PR #38.
- O vínculo do projeto fica em `build/web/.vercel/project.json` (projeto `vozes-da-catedral`). O `flutter build web` não apaga esse arquivo, mas confira antes de publicar.
- Depois de publicar, confira os cabeçalhos da resposta (CSP, `X-Frame-Options`, etc.). O app usa URLs com `#` (estratégia padrão), então rotas profundas não dependem do rewrite.
- A CSP libera `self`, `*.supabase.co` (https/wss), `www.gstatic.com` e `fonts.gstatic.com`, `wasm-unsafe-eval` e workers `blob:`. Se um recurso novo for bloqueado, o Console mostra "Refused to…".

### Android: assinatura
- O APK release é assinado com `C:\Users\abpau\vozes-da-catedral-release.jks` (fora do repositório; configurado em `android/key.properties`, que está no `.gitignore`). Faça backup desse keystore: sem ele, não há como atualizar o app instalado.
- Em 13/11/2026 o Samsung estava com um APK assinado com a chave **debug**; foi preciso desinstalar uma vez para instalar o release. Daqui em diante, `adb install -r` funciona.
- Outros usuários Android com APK de debug também precisam desinstalar uma vez (perdem o cache local; sincronizar antes).

### Estado do banco Supabase (validado via MCP em 13/11/2026)
- As 10 funções `security definer` de `public` têm `search_path` vazio e `anon` sem `EXECUTE`.
- Triggers ativos: `set_criado_por` (`musicas`, `celebracoes`) e `protect_last_coordinator` (`membros_grupo`).
- `itens_celebracao` só aceita `musica_id` de música do mesmo grupo da celebração.
- Contagens no momento da validação: 4 grupos, 9 membros, 211 músicas, 3 celebrações, 36 itens, 6 usuários.
- Testes feitos em transação revertida (nada gravado). **Não** houve teste pelo app com duas contas (coordenador e membro).
- 3 dos 4 grupos têm um único coordenador; remover esse coordenador agora retorna erro. O app não trata essa mensagem de forma específica.

- **Restrição de e-mail aplicada em 13/11/2026** (migration `fix_public_users_select_grant`): `authenticated` só lê `id`, `nome` e `papel` de `public.users`; `email`, `foto`, `select *` e `update` direto retornam erro de permissão. Perfil é gravado pela RPC `update_my_profile`. Validado em transação revertida. Para reverter: `grant select on public.users to authenticated;`
- **O APK 0.1.0 (anterior ao #34) não funciona mais** com essa restrição (lia `email` e fazia `upsert` em `users`). Todo usuário Android precisa do 0.1.1 ou superior.
- Advisor de segurança: restam só avisos esperados de RPCs `security definer` executáveis por `authenticated` (necessário para o app e para as policies) e a proteção de senhas vazadas desligada.

- **Proteção contra senhas vazadas (HaveIBeenPwned): risco aceito.** Disponível só no plano Pro; a organização está no Free. O aviso `auth_leaked_password_protection` do advisor continua aparecendo e é esperado. Alternativa disponível no Free (não aplicada): tamanho mínimo e caracteres obrigatórios em Sign In / Providers → Email; senhas antigas fora da regra passam a receber `WeakPasswordError` no login.

### Pendências importantes
1. Aplicar/validar o `schema.sql` em um banco vazio (não testado).
2. As migrations do repositório não correspondem 1:1 ao histórico do Supabase (`list_migrations` mostra só as aplicadas via MCP; parte foi aplicada pelo SQL Editor). O `schema.sql` é a referência do estado final.
3. Testar com duas contas: sincronizar celebração, convidar membro e tentar remover o único coordenador.
4. Distribuir o APK 0.1.1 aos demais usuários Android (`build\app\outputs\flutter-apk\app-release.apk`).

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
| MCP Supabase | `.kiro/settings/mcp.json` (workspace) aponta para o projeto `npujroyocclobjrpeaed` **com permissão de escrita** (sem `read_only`). Autenticação por OAuth no navegador. Esse arquivo e `.vscode/mcp.json` estão fora do git. Prefira validar com leitura/advisors e confirmar antes de qualquer escrita; o banco é o de produção |
| Aprovação de PR | o GitHub não deixa o autor aprovar o próprio PR; como o único contribuidor é o dono, o merge é feito direto |

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
/groups/:grupoId/celebrations/:celebracaoId/performance → PerformanceScreen
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
- Antes de sincronizar itens pendentes, garante que cada música referenciada exista no Supabase; músicas locais ainda não publicadas são publicadas pelo coordenador, evitando violação da FK `itens_celebracao.musica_id`

**Validação pendente:**
- `flutter test` passou; `dart analyze` nos arquivos alterados não encontrou problemas
- `flutter build apk --debug` passou; APK instalado e app aberto no Samsung SM-A546E (`RQCW701905N`) em 09/11/2026
- Correção da FK de música validada por análise/testes/build; APK corrigido reinstalado em 09/11/2026, aguardando reteste funcional da celebração no aparelho
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

**Implementação iniciada:**
- Rota de performance adicionada ao detalhe da celebração
- Leitura contínua offline de itens e músicas locais, com cifras/letras, observações e navegação rápida por momento
- Barra inferior de controles para fonte, cifras e tema; usuário confirmou claro/escuro funcionando
- Navegação rápida funciona também para momentos ainda fora da área visível da rolagem
- Wakelock ativado enquanto a tela está em primeiro plano
- `flutter test` e análise Dart dos arquivos alterados passaram; `flutter build apk --debug` concluiu
- APK debug instalado e app aberto no Samsung SM-A546E (`RQCW701905N`); usuário confirmou teste funcional concluído com sucesso

### Melhorias futuras do montador (issue #19)
- Classificar/filtrar o catálogo por momento litúrgico, além das categorias livres atuais
- Avaliar aviso ou política configurável para reutilização da mesma música em vários momentos

### Task 9 — Build e Deploy (issue #18)
**Iniciada após a conclusão validada da Task 8.**

```bash
# APK release (sideload Android)
flutter build apk --release
# Arquivo gerado: build/app/outputs/flutter-apk/app-release.apk

# Web
flutter build web --release
# Deploy somente o build, evitando enviar o repositório inteiro
vercel deploy .\build\web --prod
```
- Ícone, splash, nome do app e manifestos Android/Web foram personalizados com a identidade provisória do projeto
- O release usa `android/key.properties` quando configurado; sem chave usa assinatura debug, apenas para testes
- `web/vercel.json` (copiado para `build/web` no build) define cabeçalhos de segurança e redireciona rotas para a entrada Flutter; ver "Deploy Web" na seção de varredura
- `flutter build apk --release` e `flutter build web --release` validados; APK instalado e aberto no Samsung SM-A546E
- Drift Web configurado com `DriftWebOptions` e runtime WASM compatível com as versões do `pubspec.lock`; login e lista de grupos validados no navegador local
- O usuário confirmou o deploy e o webapp funcionando em 09/11/2026

### Task 10 — Classificação litúrgica e reutilização (issue #19)
- Iniciada após a conclusão validada da Task 9
- Implementação concluída e enviada em `02cbbfe`: classificação múltipla por momento, filtros no hinário e seletor da celebração, aviso confirmável ao reutilizar música
- Migration `supabase/migrations/20261109_song_liturgical_moments.sql` aplicada pelo usuário em 09/11/2026
- Build Web de produção publicado em `https://vozes-da-catedral.vercel.app` após a aplicação da migration
- Testes automatizados passaram e o usuário confirmou que a aplicação está funcionando na Vercel
- Issue #19 fechada e cartão do GitHub Project marcado como Done

### Task 11 — Autenticação com Google (issue #20)
- Adicionado botão “Continuar com Google” e redirecionamento para a origem Web ou deep link Android
- Deep link `io.supabase.vozesdacatedral://login-callback/` registrado no manifesto Android
- README documenta a configuração externa; credenciais Google/Supabase configuradas pelo usuário
- Login Google na Vercel validado pelo usuário em 10/11/2026; após autorização, retornou ao app autenticado na tela de grupos
- Login Google no Android validado pelo usuário no Samsung SM A546E em 10/11/2026
- Issue #20 fechada e cartão do GitHub Project marcado como Done

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
7. Todas as Tasks 1–11 estão concluídas, assim como #22, #23 e #25 e a restrição de e-mail. Continue pela seção **Varredura técnica e de segurança**: #26, #24 e #27 (uma branch por issue).

> Para atualizar o GitHub Projects ao concluir cada task:
> `gh issue close <NUMBER> --repo abpaula77/Vozes_da_Catedral --comment "Task concluída: <descrição>"`
> E atualizar o status no board via `gh project item-edit`
