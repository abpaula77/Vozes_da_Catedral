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
- 👥 **Grupos** — Coordenador gerencia membros; membros acessam no modo leitura
- 🎵 **Hinário** — Importação de músicas via arquivo `.txt` com cifras e letras
- ✝️ **Montador de Celebração** — Estrutura do Rito Romano com slots para cada momento litúrgico
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

---

## Distribuição do Piloto (Android)

Para instalar o APK diretamente no Android (sideload):

1. No Android, acesse **Configurações > Segurança > Fontes desconhecidas** e habilite.
2. Receba o arquivo `.apk` via WhatsApp ou Google Drive.
3. Abra o arquivo e toque em **Instalar**.

---

## Contribuindo

Contribuições são bem-vindas! Abra uma issue ou pull request.

---

## Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.

---

*Desenvolvido com ❤️ para o Coral da Catedral de Santo Antônio de Piracicaba/SP*
