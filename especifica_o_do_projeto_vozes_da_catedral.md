# Especificação de Projeto — Vozes da Catedral

**Versão:** 1.0.0  
**Status:** Em Definição  
**Projeto Piloto:** Catedral de Santo Antônio (Piracicaba/SP)  
**Público-alvo:** Corais, ministérios de música sacra e instrumentistas da Igreja Católica (Rito Católico Romano)

---

## 1. Visão Geral do Produto

O **Vozes da Catedral** é uma aplicação (Mobile/Web) projetada para otimizar o acompanhamento de cantos litúrgicos durante a celebração da Missa. O aplicativo permite a gestão de repertórios, montagem do rito litúrgico romano, compartilhamento entre membros do coral e visualização adaptada para a execução ao vivo (com controle de fontes, modos claro/escuro e cifras posicionadas).

---

## 2. Arquitetura de Dados & Formato de Músicas

O sistema deve trabalhar com arquivos estruturados para fácil parsing e renderização visual.

### 2.1 Formato Marcado em Texto (Custom Markdown/Plain Text)
Formato recomendado para digitação rápida, armazenamento em `.txt` ou `.md` e compartilhamento manual.

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

### 2.2 Formato JSON (Representação Interna / API)
Estrutura utilizada pelo app para manipulação no estado da aplicação, transposição de tons e persistência no banco de dados.

```json
{
  "id": "musica-santo-001",
  "titulo": "Santo, Santo, Santo",
  "tomOriginal": "D",
  "bpm": 80,
  "categorias": ["santo"],
  "secoes": [
    {
      "tipo": "ESTROFE",
      "linhas": [
        { "cifra": "D        F#m", "letra": "Santo, Santo, Santo" },
        { "cifra": "G        A4  A", "letra": "Senhor Deus do Universo" }
      ]
    },
    {
      "tipo": "REFRAO",
      "linhas": [
        { "cifra": "D        A",    "letra": "Hosana nas alturas!" },
        { "cifra": "G        A  D", "letra": "Hosana nas alturas!" }
      ]
    }
  ]
}
```

---

## 3. Requisitos Funcionais (RF)

### RF01 — Autenticação & Perfil de Usuários
* **RF01.1:** Autenticação via Google OAuth 2.0 e E-mail/Senha.
* **RF01.2:** Perfil do usuário contendo nome, e-mail, foto e função (Cantor, Instrumentista, Regente/Líder).

### RF02 — Gestão de Grupos / Ministérios
* **RF02.1:** Criação e gestão de grupos (ex: *Coral Santo Antônio - 19h*).
* **RF02.2:** Entradas em grupos através de convites por link de compartilhamento ou código identificador.
* **RF02.3:** Permissões de grupo: *Administrador/Regente* (monta celebrações e adiciona músicas) e *Membro/Cantor* (visualiza e acompanha as missas).

### RF03 — Repositório & Classificação Litúrgica
* **RF03.1:** Cadastro, edição e exclusão de músicas.
* **RF03.2:** Classificação obrigatória por momento litúrgico:
  * Entrada
  * Ato Penitencial
  * Glória
  * Salmo Responsorial
  * Aclamação ao Evangelho
  * Oferta / Oferdas
  * Santo
  * Cordeiro de Deus
  * Comunhão
  * Pós-Comunhão / Meditação
  * Consagração / Canto Mariano
  * Final / Envio
  * Outras (Adoração, Diversas, etc.)
* **RF03.3:** Filtro de busca por título, momento litúrgico, trecho de letra ou tom.

### RF04 — Montagem e Estruturação da Celebração
* **RF04.1:** Criação de uma "Nova Celebração" pré-estruturada no Rito Católico Romano.
* **RF04.2:** Vínculo de uma música cadastrada para cada momento do rito.
* **RF04.3:** Possibilidade de adicionar avisos ou orientações litúrgicas entre as músicas (ex: *"Aguardar a entrada do padre antes do 2º verso"*).
* **RF04.4:** Compartilhamento direto da celebração montada via link de aplicativo, WhatsApp ou distribuição interna do grupo.

### RF05 — Visualização & Performance (Modo Execução)
* **RF05.1:** **Ajuste Dinâmico de Fonte:** Botões para alterar o tamanho da letra e da cifra de forma independente ou global.
* **RF05.2:** **Suporte a Temas (Claro e Escuro):**
  * Alternância manual ou automática baseada nas configurações do sistema.
  * O Modo Escuro (Dark Mode) deve ser otimizado para ambientes de pouca iluminação (evitando cores excessivamente brilhantes e reflexos no altar).
* **RF05.3:** **Alternância de Cifras:** Botão para ocultar/exibir cifras (visão otimizada para cantores vs. instrumentistas).
* **RF05.4:** **Navegação Contínua:** Modo de rolagem contínua para acompanhar toda a missa sequencialmente sem trocas manuais de tela entre as músicas.
* **RF05.5:** Manter a tela ativa (Prevent Screen Sleep) durante a exibição do modo celebração.

### RF06 — Sincronização & Integrações
* **RF06.1:** Importação/Exportação de arquivos `.txt` / `.json`.
* **RF06.2:** Suporte para sincronização de repositório via GitHub (para manutenção do repositório oficial de cifras da Catedral).
* **RF06.3:** Compartilhamento rápido via WhatsApp (envio do arquivo de música ou estrutura da missa).

---

## 4. Requisitos Não Funcionais (RNF)

* **RNF01 — Performance:** O parser de cifra e o carregamento do texto devem responder em menos de 100ms em dispositivos móveis.
* **RNF02 — Disponibilidade Offline:** A celebração montada e as músicas sincronizadas do grupo devem funcionar sem conexão com a internet durante a missa.
* **RNF03 — Multiplataforma:** O app deve ser compatível com Android, iOS e Web.
* **RNF04 — Usabilidade:** A interface de apresentação das cifras deve garantir tipografia monoespaçada (para a linha de cifras) mantendo o alinhamento correto com as letras.

---

## 5. Arquitetura de Telas (Wireframe Conceitual)

1. **Dashboard / Início:**
   * Lista da Próxima Celebração Agendada.
   * Acesso rápido às músicas favoritas e aos grupos.
2. **Montador de Missa (Rito Romano):**
   * Lista ordenada dos momentos litúrgicos com slots para inserir as músicas.
3. **Leitor Litúrgico (Modo Performance):**
   * Barra superior com controles (Fonte +, Fonte -, Toggle Cifra, Dark/Light Mode).
   * Visualizador central de cifra/letra.
   * Barra de navegação rápida entre as músicas da missa.
4. **Gerenciador do Hinário:**
   * Lista de músicas com badges dos momentos litúrgicos.
   * Editor de arquivo `.txt` / `.json` com preview em tempo real.

---

## 6. Próximos Passos de Desenvolvimento

1. Configuração do repositório e stack tecnológica (ex: Flutter / React Native + Supabase/Firebase).
2. Construção do módulo de *Parsing* de texto e renderizador monoespaçado de cifras sobre letras.
3. Criação da estrutura de dados do Rito Romano e prototipagem da tela de execução (Modo Performance com Dark Mode).
4. Teste piloto com o grupo **Vozes da Catedral** na Catedral de Santo Antônio.