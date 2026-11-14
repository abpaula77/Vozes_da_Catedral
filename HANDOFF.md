# Handoff — Vozes da Catedral

> Documento de continuidade para outra sessão de IA ou desenvolvedor.
> Última atualização: 14/11/2026

---

## Resumo Executivo

App Flutter (Android + Web) para gestão e execução de cantos litúrgicos em missas da Igreja Católica.
Projeto piloto: Coral da Catedral de Santo Antônio — Piracicaba/SP.

**Stack:** Flutter 3.x · Riverpod · go_router · Drift (SQLite) · Supabase (free tier)
**Repositório:** https://github.com/abpaula77/Vozes_da_Catedral
**GitHub Project (Kanban):** https://github.com/users/abpaula77/projects/3
**Último commit de código na `master`:** `711d1da` — merge do PR #59 (data e hora no padrão brasileiro, #55)
**Produção (14/11/2026):** Web publicado na Vercel a partir de `711d1da`; APK release **0.2.0 (code 3)** do mesmo commit instalado no Samsung de teste. Antes de distribuir a outros usuários, suba `version` no `pubspec.yaml` (ainda `0.2.0+3`, mas com #52, #54 e #55 a mais).

**Fluxo de trabalho:** uma issue por melhoria e uma branch por issue (`fix/<n>-<nome>` ou `feat/<n>-<nome>`), com PR próprio. Não commitar direto na `master`. Features maiores usam spec em `.kiro/specs/<nome>/` (requisitos → design → tarefas), revisado pelo usuário antes de implementar.

**Sessões em paralelo:** o usuário pode rodar outras sessões em **worktrees separados** (ex.: `D:/Vozes_da_Catedral_54`). Nunca edite os arquivos de outra sessão; se a pasta principal tiver alterações que não são suas, pergunte antes de agir. Valide sempre **antes** do merge, nunca no mesmo comando (em 14/11/2026 um merge entrou com validação falhando por causa de rascunhos de outra sessão na pasta principal; a `master` estava íntegra, conferida numa cópia limpa).

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

### Issues concluídas depois das Tasks (todas validadas pelo usuário)

| Issue | Tema | PRs |
|-------|------|-----|
| #22–#26 | Varredura de segurança (schema, RLS, enumeração de usuários, CSP, Android) | #34–#43 |
| #41 | Pedido de filiação a grupos | #45 |
| #42 | Perfil de usuário, foto e exclusão de conta | #48, #49, #50, #57 |
| #52 | Promover/rebaixar membros + troca de conta na mesma aba | #53 |
| #54 | Link de vídeo por música (`[VIDEO]` no TXT) | #58 (outra sessão) |
| #55 | Data e hora no padrão brasileiro (`dd/MM/aaaa HH:mm`) | #59 (outra sessão) |

### Issues abertas

| Issue | Tema | Situação |
|-------|------|----------|
| #27 | Política de direitos autorais do catálogo compartilhado | Decisão do usuário, não é código |
| #51 | E-mails de autenticação com a identidade do app | **Bloqueada:** não há servidor de e-mail (SMTP) nem domínio. Ver "Riscos conhecidos" |
| #56 | Avaliar notificações para novas celebrações (push/e-mail/Telegram) | Spike criado pela outra sessão; priorizar opções gratuitas |

---

## Varredura técnica e de segurança (12–13/11/2026)

| Issue | Tema | Estado |
|-------|------|--------|
| #22 | `schema.sql` desatualizado + `search_path` das funções `security definer` | ✅ PR #35 |
| #23 | RLS: autor imutável, último coordenador, música do mesmo grupo, revogar `anon` | ✅ PR #36 |
| #24 | `list_group_invitees` permitia enumerar todos os usuários (risco médio) | ✅ PR #43. Convite só por e-mail exato |
| #25 | Cabeçalhos de segurança Web (CSP etc.) | ✅ PRs #37 e #38 |
| #26 | Android: `allowBackup`, deep link, assinatura de release | ✅ PR #40. App Links avaliado e não adotado (login usa PKCE) |

(#28 a #33 foram duplicatas e estão fechadas.)

- **Mudanças de banco que quebram builds antigos:** publique primeiro o Web e o APK novos, valide e só então aplique a migration (feito na restrição de e-mail e na #24). Use `Refs #<n>` no PR, em vez de `Closes`, quando a issue só fecha depois da migration ou do teste do usuário.
- **Mudanças aditivas** (#41, #42, #52): migration antes do app.

---

## Features recentes

### #41 — Pedido de filiação a grupos
- Spec: `.kiro/specs/pedido-filiacao-grupos/`.
- **Banco** (`20261116_group_join_requests.sql`): coluna `grupos.aceita_solicitacoes` (default `false`, opt-in), tabela `solicitacoes_grupo` **sem acesso direto** (RLS sem policies + `revoke`), 9 RPCs `security definer` (`definir_aceita_solicitacoes`, `obter_aceita_solicitacoes`, `listar_solicitacoes_pendentes`, `contar_solicitacoes_pendentes`, `decidir_solicitacao`, `listar_grupos_abertos`, `solicitar_entrada`, `listar_minhas_solicitacoes`, `cancelar_solicitacao`).
- `add_group_member_by_email` também aprova o pedido pendente de quem é convidado.
- Testes: `supabase/tests/solicitacoes_grupo.sql` (49 verificações).
- **App:** tela `/explore` (Encontrar grupos), switch "Aceitar solicitações" e lista de pendentes na tela de membros, badge em Meus Grupos. Online only.
- Estado em 14/11/2026: 4 dos 5 grupos com `aceita_solicitacoes = true` (decisão do usuário: ficam abertos).

### #42 — Perfil de usuário, foto e exclusão de conta
- Spec: `.kiro/specs/perfil-usuario/`.
- **Foto:** `users.foto` guarda `null`, a URL do Google (`https://...`) ou o caminho de uma foto enviada (`avatars/<user_id>/<uuid>.jpg`).
  - Bucket **privado** `avatars` (512 KB; JPEG/PNG/WebP); exibição por link temporário de 1 h, pedido em lote (`lib/features/profile/data/foto_resolver.dart`).
  - Quem vê (`pode_ver_foto`): o próprio usuário, colegas de grupo e coordenadores de grupo com pedido pendente dele.
  - `_foto_valida` aceita só `null`, a própria pasta ou a foto do Google da própria conta (metadados do login **ou** identidade Google vinculada). Bloqueia URL externa (rastreio de IP). Usada também por `update_my_profile`.
  - `grant select (foto)` em `users`; `email` continua bloqueado.
- **Excluir conta** (`excluir_minha_conta`): bloqueada se o usuário for o único coordenador de algum grupo (`grupos_impedindo_exclusao`). A autoria de grupos, músicas e celebrações passa para o coordenador mais antigo do grupo; a trigger `set_criado_por` respeita a flag `app.reatribuir_autor` só nessa função. O app apaga a foto do Storage antes.
- **Primeiro acesso** só confirma o nome; a escolha "Coordenador/Membro" foi removida (`users.papel` fica no banco sem uso).
- **App:** "Meu perfil" (`/profile`), aberto pelo avatar em Meus Grupos (o botão Sair foi para lá). `image_picker: 1.2.1` fixado (última versão compatível com Dart 3.7). No Web a opção se chama "Escolher arquivo".
- Testes: `supabase/tests/perfil_usuario.sql` (47 verificações, com contas descartáveis criadas dentro da transação).

### #52 — Promover/rebaixar membros e troca de conta
- RPC `alterar_papel_membro` (só coordenadores; `protect_last_coordinator` mantém pelo menos um). Não há policy de UPDATE em `membros_grupo`: a RPC é o único caminho. Testes: `supabase/tests/papel_membro.sql` (11).
- Tela de membros: menu ⋮ por membro (tornar coordenador/membro, remover). O próprio coordenador pode "Deixar de ser coordenador" se houver outro.
- **Defeito corrigido:** `currentUserIdProvider` guardava o id da primeira conta da aba; agora acompanha a sessão. Lista de membros (`autoDispose`) e perfil recarregam ao abrir a tela e na troca de conta.

### #54 e #55 (outra sessão)
- **#54:** link de vídeo opcional por música, pela linha `[VIDEO]: https://...` no TXT (documentado em `docs/formato-musicas.md`). Fica dentro de `conteudo_json`; sem migration. Abre fora do app (`url_launcher`, só http/https, validado de novo antes de abrir). Aparece no hinário e no montador, não no modo performance.
- **#55:** utilitário `lib/core/utils/date_format_br.dart` (`intl`): `dd/MM/aaaa` e `HH:mm`, seletor de hora em 24h. Usa o fuso **do aparelho** (a issue pedia `America/Sao_Paulo`; mesmo resultado para quem está no Brasil).

---

## Deploy Web (importante)
- O deploy é `vercel deploy .\build\web --prod`, então a raiz do deploy é `build/web`.
- A configuração da Vercel fica em **`web/vercel.json`** (o `flutter build web` copia para `build/web`). Um `vercel.json` na raiz do repositório **não** é lido.
- O vínculo do projeto fica em `build/web/.vercel/project.json` (projeto `vozes-da-catedral`, fora do git). Se precisar publicar de outra pasta (ex.: cópia limpa da `master`), copie esse arquivo para o `build/web` dela.
- **CSP:** libera `self`, `*.supabase.co` (https/wss), `www.gstatic.com`, `fonts.gstatic.com`, `*.googleusercontent.com` (em `connect-src`), `wasm-unsafe-eval` e workers `blob:`. No Flutter Web (CanvasKit) **imagens são baixadas com `fetch`**, então valem as regras de `connect-src`, não só de `img-src`. Um recurso bloqueado aparece no Console como "Refused to…".
- **Armadilha do cache de plugins:** depois de adicionar um pacote com parte Web, o build pode reutilizar um `web_plugin_registrant.dart` antigo em `.dart_tool/flutter_build/<hash>/` e o plugin some do site (aconteceu com o `image_picker`: "Não foi possível abrir"). Solução: apagar essa pasta de cache e compilar de novo; conferir no `main.dart.js` se o plugin entrou.
- Depois de publicar, confira os cabeçalhos (CSP, `X-Frame-Options`) e que o `main.dart.js` de produção contém o código novo.

## Android: assinatura e backup
- `flutter build apk --release` **falha** sem `android/key.properties` (sem fallback para a chave debug). Para testes sem a chave, use `--debug`.
- O app não participa de backup do Android (`allowBackup="false"` + `res/xml/data_extraction_rules.xml`).
- O APK release é assinado com `C:\Users\abpau\vozes-da-catedral-release.jks` (fora do repositório; `android/key.properties` está no `.gitignore`). **Faça backup desse keystore**: sem ele, não há como atualizar o app instalado.
- Usuários com APK assinado com a chave debug precisam desinstalar uma vez (perdem o cache local; sincronizar antes). Depois, `adb install -r` funciona.

## Estado do banco Supabase (14/11/2026)
- 26 funções `security definer` em `public`, todas com `search_path` vazio; `anon` sem `EXECUTE` nas RPCs do app.
- Advisors: avisos esperados de RPCs executáveis por `authenticated`, `rls_enabled_no_policy` em `solicitacoes_grupo` (intencional) e a proteção de senhas vazadas desligada (risco aceito: só no plano Pro).
- `public.users`: o cliente lê só `id`, `nome`, `papel` e `foto`; `email` bloqueado. Perfil gravado pelas RPCs `atualizar_meu_nome`, `definir_minha_foto` e `update_my_profile` (versões antigas do app).
- Triggers: `set_criado_por` (`musicas`, `celebracoes`), `protect_last_coordinator` (`membros_grupo`).
- Contagens: 6 usuários, 5 grupos, 12 participações, 211 músicas, 3 celebrações, 4 solicitações, 2 fotos enviadas.
- **APKs anteriores a 0.1.1 não funcionam** (liam `email`). Todos os usuários Android precisam de 0.1.1 ou superior; para as features recentes, 0.2.0.
- Testes do banco (rodam em transação revertida; rode de novo após mexer nessas funções): `supabase/tests/solicitacoes_grupo.sql`, `perfil_usuario.sql`, `papel_membro.sql`. Eles terminam sempre com um erro `RESULTADO: N ok, M falhas` — é o relatório, não uma falha.

## Riscos conhecidos e pendências
1. **E-mail de confirmação (#51):** o SMTP padrão do Supabase só envia para endereços pré-autorizados (time do projeto) e tem limite baixo por hora. Pessoas de fora que se cadastrarem por **e-mail e senha** podem não receber a confirmação nem a recuperação de senha. Login com Google não é afetado. Resolver antes de abrir o app a mais usuários.
2. Aplicar/validar o `schema.sql` em um banco vazio (não testado).
3. As migrations do repositório não correspondem 1:1 ao histórico do Supabase (parte foi aplicada pelo SQL Editor). O `schema.sql` é a referência do estado final.
4. Distribuir o APK 0.2.x aos demais usuários Android (subir a versão antes).
5. Cobertura de testes do app ainda baixa em sync e telas (34 testes, focados em modelos, parser e datas).

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

Hoje o Samsung (`RQCW701905N`) usa o **APK release** (ver "Android: assinatura e backup"). O roteiro abaixo é para desenvolvimento com o app em modo debug; instalar um build debug por cima do release exige desinstalar (assinaturas diferentes).

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

O schema inicial foi aplicado pelo SQL Editor; as mudanças posteriores estão em `supabase/migrations/` (aplicadas pelo MCP ou pelo SQL Editor). `supabase/schema.sql` acumula o estado final, mas nunca foi testado num banco vazio.
Tabelas: `users`, `grupos`, `membros_grupo`, `musicas`, `celebracoes`, `itens_celebracao`, `solicitacoes_grupo`; bucket `avatars`.
Trigger: auto-criação de perfil no `auth.users` ao fazer signup.
Detalhes de acesso em "Modelo de Dados Supabase" e "Estado do banco Supabase".

---

## Arquitetura Atual (o que está implementado)

```
lib/
├── main.dart                             inicializa Supabase + ProviderScope
├── app.dart                              MaterialApp.router + temas + localização pt_BR
├── core/
│   ├── config/supabase_config.dart       URL + chave publicável via dart-define
│   ├── database/                         Drift: 6 tabelas, schema v4, DAOs, provider
│   ├── domain/momento_liturgico.dart     12 momentos do Rito Romano
│   ├── router/app_router.dart            GoRouter + redirect auth + nav helpers
│   ├── theme/app_theme.dart              tema claro/escuro (dark otimizado altar)
│   └── utils/date_format_br.dart         datas dd/MM/aaaa e horas HH:mm (#55)
└── features/
    ├── auth/
    │   ├── domain/user_model.dart
    │   └── presentation/
    │       ├── auth_provider.dart         AuthService, sessão, currentUserIdProvider (segue a sessão, #52)
    │       ├── login_screen.dart          login e-mail/senha + Google
    │       └── onboarding_screen.dart     1º acesso: confirma o nome (#42)
    ├── groups/
    │   ├── domain/                        GrupoModel, PapelGrupo, MembroGrupoModel, modelos de solicitação (#41)
    │   ├── data/
    │   │   ├── groups_provider.dart       GruposService (criar, sync, convidar, alterar papel, remover)
    │   │   └── solicitacoes_provider.dart SolicitacoesService (#41)
    │   └── presentation/
    │       ├── groups_screen.dart         Meus Grupos: avatar do perfil, Encontrar grupos, badge de pendentes
    │       ├── explore_groups_screen.dart Encontrar grupos e minhas solicitações (#41)
    │       ├── group_detail_screen.dart   tabs: Hinário | celebrações
    │       ├── group_members_screen.dart  membros com foto, convite, menu de papel/remoção (#52)
    │       └── join_requests_widgets.dart switch "Aceitar solicitações" e pendentes (#41)
    ├── profile/                           (#42)
    │   ├── domain/meu_perfil_model.dart   tipos de foto, validação do nome
    │   ├── data/
    │   │   ├── profile_service.dart       nome, foto (envio/Google/remover), excluir conta
    │   │   └── foto_resolver.dart         links temporários das fotos, em lote
    │   └── presentation/
    │       ├── profile_screen.dart        Meu perfil
    │       └── user_avatar.dart           avatar com foto ou inicial
    ├── songs/
    │   ├── domain/                        SongModel, SongContent (videoUrl #54), parser .txt, SongId
    │   ├── data/songs_provider.dart       importação, publicação, sync, catálogo
    │   └── presentation/                  hinário, CifraView, detalhe, botão de vídeo (#54)
    ├── celebrations/                      montador (Rito Romano), sync, modo performance
    └── splash/presentation/splash_screen.dart
```

### Rotas (go_router)
```
/                   → SplashScreen (redireciona para /login ou /groups)
/login              → LoginScreen
/onboarding         → OnboardingScreen (confirma o nome no 1º acesso)
/groups             → GroupsScreen (Meus Grupos)
/explore            → ExploreGroupsScreen (Encontrar grupos, #41)
/profile            → ProfileScreen (Meu perfil, #42)
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
4. Qualquer mudança na sessão atualiza o router via `_AuthNotifier` e o `currentUserIdProvider`

---

## Modelo de Dados Supabase

```
users                id (uuid, FK auth.users), nome, email (não legível pelo cliente), foto, papel (sem uso)
grupos               id, nome, descricao, criado_por (FK users), aceita_solicitacoes
membros_grupo        grupo_id + user_id (PK composta), papel (coordenador|membro)
musicas              id, grupo_id, titulo, tom_original, bpm, categorias[], momentos_liturgicos[],
                     conteudo_raw, conteudo_json (inclui videoUrl), criado_por, copiada_de_id
celebracoes          id, grupo_id, titulo, data_hora, criado_por
itens_celebracao     id, celebracao_id, musica_id, ordem, momento_liturgico, observacao
solicitacoes_grupo   id, grupo_id, user_id, status, mensagem, criada_em, decidida_em, decidida_por (#41)
storage: avatars     bucket privado, avatars/<user_id>/<arquivo> (#42)
```

**Acesso resumido:**
- `users`: leitura própria + colegas de grupo (só `id`, `nome`, `papel`, `foto`); gravação só por RPC
- `grupos`: leitura para membros, escrita para coordenador/criador; busca de abertos só por RPC
- `membros_grupo`: leitura para membros do grupo; inserção e remoção por coordenador; papel só pela RPC `alterar_papel_membro`
- `musicas`: catálogo legível por qualquer usuário autenticado; escrita para coordenador
- `celebracoes`, `itens_celebracao`: leitura para membros, escrita para coordenador
- `solicitacoes_grupo`: sem acesso direto; só RPCs
- `avatars`: leitura conforme `pode_ver_foto`; escrita só na própria pasta

---

## Formato de Arquivo de Música (.txt)

```text
[TITULO]: Santo, Santo, Santo
[TOM]: D
[CATEGORIA]: santo
[BPM]: 80
[VIDEO]: https://www.youtube.com/watch?v=...

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

Seções suportadas: ESTROFE, REFRAO/REFRÃO, PONTE, PRE-REFRAO, INTRO, OUTRO, CODA, VERSO. `[VIDEO]` é opcional (só `http`/`https`). Guia completo: `docs/formato-musicas.md`.

---

## Histórico das Tasks 5–11 (registro da implementação original)


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

# Publicar o Web (a partir de build/web; ver "Deploy Web")
flutter build web --release
vercel deploy .\build\web --prod

# Instalar o release por cima, sem perder dados
flutter build apk --release
adb -s RQCW701905N install -r build\app\outputs\flutter-apk\app-release.apk
```

Testes do banco: cole o conteúdo de `supabase/tests/*.sql` no SQL Editor (ou execute pelo MCP). Cada script termina com o erro `RESULTADO: N ok, M falhas`, que é o relatório; nada fica gravado.

---

## Como Retomar com Outra IA

1. Leia este arquivo (`HANDOFF.md`)
2. Confirme o dispositivo Android: `adb devices` → deve mostrar `RQCW701905N device`
3. Tente o build: `flutter run -d RQCW701905N` em `d:\Vozes_da_Catedral`
4. Se o build funcionar, o app deve mostrar tela de splash → login
5. Crie uma conta de teste no app → será redirecionado para onboarding
6. **Lembre o usuário:** antes de testar grupos/músicas, precisa criar um grupo pelo app
7. Estão concluídas e validadas: Tasks 1–11, varredura de segurança (#22–#26), #41, #42, #52, #54 e #55. Abertas: **#27** (decisão do usuário), **#51** (bloqueada sem servidor de e-mail) e **#56** (spike de notificações). Antes de distribuir o APK a outras pessoas, subir a versão. Uma branch por issue; validar antes do merge.

> Para atualizar o GitHub Projects ao concluir cada task:
> `gh issue close <NUMBER> --repo abpaula77/Vozes_da_Catedral --comment "Task concluída: <descrição>"`
> E atualizar o status no board via `gh project item-edit`
