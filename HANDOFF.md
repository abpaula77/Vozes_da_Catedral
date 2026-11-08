# Handoff — Vozes da Catedral

> Documento de continuidade para outra sessão de IA ou desenvolvedor.  
> Atualizado em: novembro/2026

---

## Estado Atual

### Tasks Concluídas (código escrito)

| Task | Status | Commitada |
|------|--------|-----------|
| Task 1 — Setup base, Supabase config, schema Drift, modelos | ✅ | ✅ |
| Task 2 — Auth (login, signup, onboarding de papel) | ✅ | ❌ |
| Task 3 — Parser de cifras + CifraView (RobotoMono) | ✅ | ❌ |
| Task 4 — Hinário local + importação de .txt | ✅ | ❌ |
| Task 5 — Grupos, RLS, gestão de membros | ❌ | — |
| Task 6 — Sync músicas Supabase | ❌ | — |
| Task 7 — Montador de Celebração | ❌ | — |
| Task 8 — Modo Performance | ❌ | — |
| Task 9 — Build APK + deploy web | ❌ | — |

---

## Ação Imediata Necessária

### 1. Commitar e pushar tasks 2, 3 e 4

```bash
cd d:\Vozes_da_Catedral
git add .
git commit -m "feat: Tasks 2-4 — auth, song parser, CifraView, hinário local"
git push origin master
```

### 2. Aplicar schema no Supabase

1. Acesse https://supabase.com/dashboard → projeto `npujroyocclobjrpeaed`
2. Vá em **SQL Editor**
3. Cole e execute o conteúdo de `supabase/schema.sql`

Isso cria: tabelas `users`, `grupos`, `membros_grupo`, `musicas`, `celebracoes`, `itens_celebracao` + trigger de auto-criação de perfil + políticas RLS.

### 3. Testar no Android

```bash
adb devices  # verificar SM-A546E serial RQCW701905N
flutter run -d RQCW701905N
```

Se der erro de cache Kotlin (drives C: e D: diferentes):
```bash
flutter clean
flutter run -d RQCW701905N
```

---

## Arquivos Pendentes de Commit

```
android/app/build.gradle.kts          ndkVersion = "27.0.12077973"
android/settings.gradle.kts           Kotlin 2.1.0
pubspec.yaml                           fontes RobotoMono adicionadas
lib/core/router/app_router.dart        rotas completas + nav helpers
lib/features/auth/presentation/
  login_screen.dart                    tela login/signup
  onboarding_screen.dart               seleção de papel no 1º acesso
lib/features/songs/
  domain/song_parser.dart              parser formato .txt custom
  presentation/cifra_view.dart         widget CifraView monoespaçado
  presentation/songs_screen.dart       tela hinário
  presentation/song_detail_screen.dart visualizador com controles
  data/songs_provider.dart             SongsService (import/sync/publish)
lib/features/groups/presentation/
  group_detail_screen.dart             detalhe grupo (tabs hinário+celebrações)
assets/fonts/RobotoMono-*.ttf          4 arquivos de fonte
```

---

## Configurações de Ambiente

| Item | Valor |
|------|-------|
| Workspace | `d:\Vozes_da_Catedral` |
| Flutter SDK | `C:\Flutter\flutter` |
| Supabase Project ID | `npujroyocclobjrpeaed` |
| Supabase URL | `https://npujroyocclobjrpeaed.supabase.co` |
| Anon key | Ver `.env` ou `lib/core/config/supabase_config.dart` |
| Dispositivo Android | Samsung SM-A546E, serial `RQCW701905N`, Android 16 |
| GitHub | https://github.com/abpaula77/Vozes_da_Catedral |
| GitHub Project | https://github.com/users/abpaula77/projects/3 |

---

## Arquitetura Resumida

```
lib/
├── core/
│   ├── config/supabase_config.dart      credenciais Supabase
│   ├── database/
│   │   ├── tables.dart                  definição das 5 tabelas Drift
│   │   ├── app_database.dart            database + queries
│   │   ├── app_database.g.dart          gerado pelo build_runner
│   │   └── database_provider.dart       provider Riverpod
│   ├── router/app_router.dart           go_router + redirect auth
│   └── theme/app_theme.dart             temas claro/escuro (altar-friendly)
└── features/
    ├── auth/
    │   ├── domain/user_model.dart
    │   └── presentation/
    │       ├── auth_provider.dart        AuthService + providers
    │       ├── login_screen.dart
    │       └── onboarding_screen.dart
    ├── groups/
    │   ├── domain/group_model.dart       PapelGrupo enum
    │   ├── data/groups_provider.dart     GruposService
    │   └── presentation/
    │       ├── groups_screen.dart        lista de grupos
    │       └── group_detail_screen.dart  tabs hinário/celebrações
    ├── songs/
    │   ├── domain/
    │   │   ├── song_model.dart           SongModel, SongContent, SongSection
    │   │   └── song_parser.dart          parser .txt → JSON
    │   ├── data/songs_provider.dart      SongsService
    │   └── presentation/
    │       ├── cifra_view.dart           widget CifraView ⭐
    │       ├── songs_screen.dart         hinário
    │       └── song_detail_screen.dart   visualizador
    ├── celebrations/
    │   └── domain/celebration_model.dart MomentoLiturgico enum (12 momentos)
    └── splash/presentation/splash_screen.dart
```

---

## Modelo de Dados Supabase

```sql
users              id, nome, email, foto, papel
grupos             id, nome, descricao, criado_por
membros_grupo      grupo_id, user_id, papel (coordenador|membro)
musicas            id, grupo_id, titulo, tom_original, bpm, categorias[], conteudo_raw, conteudo_json
celebracoes        id, grupo_id, titulo, data_hora, criado_por
itens_celebracao   id, celebracao_id, musica_id, ordem, momento_liturgico, observacao
```

**RLS**: Coordenador tem escrita em tudo do seu grupo. Membro tem somente leitura em músicas, celebrações e itens.

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
```

---

## Próximas Tasks em Detalhe

### Task 5 — Grupos e RLS
- Tela de membros do grupo (Coordenador only)
- Adicionar membro por e-mail → busca em `users` por email
- Remover membro
- Testar isolamento: membro não vê grupo de outro usuário

### Task 6 — Sync
- `SongsService.publishMusicas(grupoId)` — já implementado, testar
- `SongsService.syncMusicas(grupoId)` — já implementado, testar
- Sync de celebrações (ainda não implementado)

### Task 7 — Montador de Celebração
- Tela nova celebração: data/hora + título
- Lista dos 12 momentos do Rito Romano (ver `MomentoLiturgico` enum)
- Por momento: selecionar música do hinário local + campo de observação
- Persistência local (Drift) + sync Supabase

### Task 8 — Modo Performance
- Usar `wakelock_plus` para manter tela ativa
- Rolagem contínua pela celebração inteira (todas as músicas em sequência)
- Controles flutuantes: fonte+/-, toggle cifras, tema dark/light
- Dark mode com cores de baixo brilho (já definido em AppTheme.dark)
- Funciona 100% offline

### Task 9 — Build e Deploy
- `flutter build apk --release` → distribuir via WhatsApp/Drive
- `flutter build web` → deploy Vercel (gratuito)
- Configurar ícone do app (substituir ícone padrão Flutter)
