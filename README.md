# 🎵 Vozes da Catedral

App multiplataforma para gestão e execução de cantos litúrgicos em missas da Igreja Católica.

**Projeto Piloto:** Catedral de Santo Antônio — Piracicaba/SP

---

## Sobre o Projeto

O **Vozes da Catedral** é uma aplicação Flutter (Android + Web) que ajuda corais e ministérios de música sacra a organizar e executar o repertório litúrgico durante a Missa Romana. O app permite ao **Coordenador** do grupo montar a estrutura da celebração com as músicas de cada momento litúrgico, e os **Membros** acompanham em modo performance — com dark mode otimizado para ambientes de pouca iluminação, ajuste de fonte e suporte offline.

---

## Funcionalidades (MVP)

- 🔐 **Autenticação** — Google OAuth e e-mail/senha (via Supabase)
- 👥 **Grupos** — Coordenador cria e gerencia membros do grupo
- 🎶 **Hinário** — Importação de músicas em formato `.txt` com cifras
- ⛪ **Montador de Missa** — Estrutura do Rito Romano com músicas vinculadas por momento litúrgico
- 🌙 **Modo Performance** — Dark mode para altar, ajuste de fonte, toggle de cifras, tela ativa
- 📴 **Offline-first** — Músicas e celebrações disponíveis sem internet durante a missa

---

## Stack

| Camada | Tecnologia |
|---|---|
| Mobile/Web | Flutter 3.x |
| Backend | Supabase (free tier) |
| Banco Local | Drift (SQLite) |
| Estado | Riverpod |
| Navegação | GoRouter |

---

## Formato de Música (`.txt`)

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

---

## Configuração do Ambiente

### Pré-requisitos
- Flutter 3.x ([instalação](https://flutter.dev/docs/get-started/install))
- Conta no [Supabase](https://supabase.com) (free tier)

### Setup

```bash
# Clone o repositório
git clone https://github.com/abpaula77/Vozes_da_Catedral.git
cd Vozes_da_Catedral

# Instale as dependências
flutter pub get

# Configure as credenciais do Supabase
# Crie um arquivo .env ou passe via --dart-define:
flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=sua-chave-anon
```

---

## Instalação Android (Piloto — Sideload)

1. Baixe o arquivo `.apk` na seção [Releases](https://github.com/abpaula77/Vozes_da_Catedral/releases)
2. No Android, ative **"Instalar de fontes desconhecidas"** nas configurações
3. Abra o arquivo `.apk` para instalar

---

## Licença

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE) para mais informações.

---

## Projeto Piloto

Este app foi desenvolvido para o grupo **Vozes da Catedral** da Catedral de Santo Antônio (Piracicaba/SP). Contribuições e adaptações para outros grupos são bem-vindas.
