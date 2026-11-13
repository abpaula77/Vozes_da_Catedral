# Vozes da Catedral 🎵⛪

App multiplataforma (Android / Web) para gestão e execução de cantos litúrgicos em missas da Igreja Católica Romana.

**Projeto piloto:** Coral da Catedral de Santo Antônio — Piracicaba/SP

---

## Sobre o Projeto

O **Vozes da Catedral** resolve um problema real de corais e ministérios de música sacra: a dependência de PDFs, papéis impressos e mensagens de WhatsApp desorganizadas para coordenar os cantos durante a missa.

O app permite que o **Coordenador** monte a estrutura completa de uma celebração (seguindo o Rito Romano), vincule músicas com cifras a cada momento litúrgico e compartilhe com os membros do grupo. Na hora da missa, cada membro acessa o **Modo Performance** — otimizado para uso ao vivo, com dark mode de baixo brilho, ajuste de fonte e funcionamento 100% offline.

---

## Funcionalidades do MVP

- 🔐 **Autenticação** — Google OAuth e e-mail/senha via Supabase
- 👥 **Grupos** — Coordenador adiciona membros por e-mail; emails de outros usuários não são exibidos no diretório de membros
- 🎵 **Hinário** — Importação de músicas via arquivo `.txt` com cifras e letras
- ✏️ **Edição de músicas** — Coordenadores podem editar no app o texto `.txt`, incluindo cifras, letra e metadados; alterações são sincronizadas com o grupo quando possível
- ✝️ **Classificação litúrgica** — Associação de músicas a momentos do Rito Romano, com filtros no hinário e no montador
- ✝️ **Montador de Celebração** — Estrutura do Rito Romano com slots para cada momento litúrgico
- 🔁 **Compartilhamento de celebrações** — Coordenadores podem copiar uma celebração configurada para outro grupo; a cópia é independente e leva as músicas usadas para o hinário de destino
- 🌙 **Modo Performance** — Dark mode, ajuste de fonte, toggle de cifras, rolagem contínua, tela sempre ativa
- 📲 **Offline-first** — Músicas e celebrações sincronizadas ficam disponíveis sem internet durante a missa

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Frontend/Mobile | Flutter 3.x |
| Backend | Supabase (Auth + PostgreSQL + Storage) |
| Persistência local | `drift` (SQLite type-safe) |
| Estado | `riverpod` |
| Navegação | `go_router` |
| Importação de arquivos | `file_picker` |
| Tela ativa | `wakelock_plus` |

---

## Arquitetura

```
lib/
├── core/
│   ├── config/        # Configuração do Supabase
│   ├── database/      # Schema local Drift (SQLite)
│   ├── router/        # Rotas go_router
│   └── theme/         # Temas claro/escuro
└── features/
    ├── auth/          # Autenticação e perfil
    ├── groups/        # Grupos e membros
    ├── songs/         # Hinário, parser de cifras
    ├── celebrations/  # Montador de celebração
    ├── performance/   # Modo Performance (leitor litúrgico)
    └── splash/        # Tela inicial
```

---

## Formato de Músicas

O app utiliza um formato de texto simples para importação de cifras:

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

Consulte o [guia completo do formato `.txt`](docs/formato-musicas.md) para os campos, seções e regras de formatação aceitos.

---

## Instalação para Desenvolvimento

### Pré-requisitos

- Flutter SDK `>=3.7.0`
- Conta no [Supabase](https://supabase.com) (free tier)

### Setup

```bash
# Clone o repositório
git clone https://github.com/abpaula77/Vozes_da_Catedral.git
cd Vozes_da_Catedral

# Instale as dependências
flutter pub get

# Copie o arquivo de variáveis de ambiente
cp .env.example .env
# Edite .env com suas credenciais do Supabase

# Execute o app
flutter run
```

Em projetos Supabase já configurados, aplique as migrations em
`supabase/migrations/` no SQL Editor do Supabase para habilitar as
funcionalidades correspondentes.

---

## Distribuição do Piloto (Android)

Compile o APK para teste/sideload:

```powershell
flutter build apk --release
```

O arquivo será gerado em `build/app/outputs/flutter-apk/app-release.apk`.
Sem uma chave de release configurada, o APK é assinado com a chave debug e
serve apenas para testes. Para distribuir atualizações assinadas de forma
consistente, crie e guarde uma chave privada fora do repositório:

```powershell
keytool -genkey -v -keystore "$HOME\vozes-da-catedral-release.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 -alias vozes
```

Crie `android/key.properties` (já ignorado pelo Git) apontando para a chave:

```properties
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_CHAVE
keyAlias=vozes
storeFile=C:/Users/SEU_USUARIO/vozes-da-catedral-release.jks
```

Não compartilhe nem perca a chave e as senhas. Builds release seguintes
usarão essa chave automaticamente.

Para instalar o APK diretamente no Android (sideload):

1. Transfira o arquivo APK para o aparelho.
2. Autorize a instalação para o app usado para abrir o arquivo, se o Android solicitar.
3. Abra o APK e toque em **Instalar**.

## Build e publicação Web

Gere os arquivos estáticos Flutter:

```powershell
flutter build web --release
```

O site estará em `build/web`. Para publicar na Vercel, instale e autentique o
CLI (`npm install --global vercel` e `vercel login`) e publique somente o build:

```powershell
vercel deploy .\build\web --prod
```

A configuração da Vercel fica em `web/vercel.json` (cabeçalhos de segurança,
CSP e redirecionamento de rotas para a entrada Flutter). O `flutter build web`
copia esse arquivo para `build/web`, que é a raiz do deploy. Depois de publicar,
confira os cabeçalhos da resposta em produção.

O banco local Drift na Web usa `web/sqlite3.wasm` e `web/drift_worker.js`.
Esses arquivos devem acompanhar a versão de `drift` e `sqlite3` definida em
`pubspec.lock`.

Os builds móveis e web usam a configuração Supabase definida em
`lib/core/config/supabase_config.dart`; use somente uma chave publicável/anon
protegida pelas políticas RLS, nunca uma chave `service_role`.

### Login com Google (Supabase)

Para habilitar **Continuar com Google**:

1. No Google Cloud Console, crie um OAuth Client ID do tipo Web e configure a
   tela de consentimento.
2. No Supabase, abra **Authentication → Providers → Google**, habilite o
   provedor e informe o Client ID e o Client Secret.
3. No Google Cloud, adicione como URI de redirecionamento autorizado o callback
   mostrado pelo Supabase (para este projeto:
   `https://npujroyocclobjrpeaed.supabase.co/auth/v1/callback`).
4. Em **Supabase → Authentication → URL Configuration**, mantenha a URL do site
   de produção e adicione `https://vozes-da-catedral.vercel.app` às URLs de
   redirecionamento permitidas. Para desenvolvimento Web local, permita também
   a origem local utilizada pelo Flutter.
5. O Android retorna pelo deep link
   `io.supabase.vozesdacatedral://login-callback/`, registrado no manifesto do
   app.

O Client Secret pertence apenas à configuração do provedor no Supabase; não o
coloque no código nem no repositório.

---

## Contribuindo

Contribuições são bem-vindas! Abra uma issue ou pull request.

---

## Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.

---

*Desenvolvido com ❤️ para o Coral da Catedral de Santo Antônio de Piracicaba/SP*
