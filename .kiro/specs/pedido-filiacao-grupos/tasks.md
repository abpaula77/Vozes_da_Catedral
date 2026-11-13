# Tarefas — Pedido de filiação a grupos

> Issue: [#41](https://github.com/abpaula77/Vozes_da_Catedral/issues/41) · [Requisitos](./requirements.md) · [Design](./design.md)
> Branch: `feat/41-pedido-filiacao`

Cada tarefa indica os requisitos que atende. As tarefas de banco vêm primeiro porque a migration é aditiva e pode ser aplicada antes do app (ver "Publicação" no design).

## 1. Banco de dados

- [x] 1.1 Criar a migration `supabase/migrations/20261116_group_join_requests.sql` com a estrutura
  - Coluna `grupos.aceita_solicitacoes boolean not null default false`
  - Tabela `solicitacoes_grupo` com FKs, `check` de status e de tamanho da mensagem (280)
  - Índice único parcial `(grupo_id, user_id) where status = 'pendente'` e índice de pendentes por grupo
  - RLS ligado sem policies; `revoke all` de `public`, `anon` e `authenticated`
  - _Requisitos: 1.1, 3.2, 3.3, 5.7, 6.5, 7.2_

- [x] 1.2 Adicionar à migration as RPCs do coordenador
  - `definir_aceita_solicitacoes`, `obter_aceita_solicitacoes`
  - `listar_solicitacoes_pendentes` (nome e foto, nunca e-mail; ignora quem já é membro)
  - `contar_solicitacoes_pendentes`
  - `decidir_solicitacao` com `select ... for update`, insert atômico em `membros_grupo` e auditoria
  - Todas `security definer`, `search_path = ''`, sem acesso para `anon`
  - _Requisitos: 1.2–1.6, 5.1–5.7, 6.2–6.6_

- [x] 1.3 Adicionar à migration as RPCs do solicitante
  - `listar_grupos_abertos` (só abertos e dos quais não é membro, com o status do próprio pedido)
  - `solicitar_entrada` com as validações na ordem do design (mensagem genérica para grupo fechado ou inexistente, espera de 7 dias, duplicado)
  - `listar_minhas_solicitacoes` (sem `decidida_por`) e `cancelar_solicitacao`
  - _Requisitos: 2.1–2.4, 3.1–3.6, 4.1–4.4, 6.7_

- [x] 1.4 Atualizar `add_group_member_by_email` para marcar como `aprovada` o pedido pendente de quem entra pelo convite
  - Manter a assinatura e o comportamento atual (não revela se o e-mail existe)
  - _Requisitos: 7.1; decisão 2 do design_

- [x] 1.5 Escrever `supabase/tests/solicitacoes_grupo.sql` cobrindo todos os cenários da seção "Testes > Banco" do design
  - Roda em transação revertida, com duas contas simuladas por `request.jwt.claims`
  - _Requisitos: todos os de banco_

- [x] 1.6 Aplicar a migration no Supabase, rodar o script de testes e os advisors de segurança
  - Conferir que as contagens de dados não mudaram e que o app atual (Web) continua funcionando
  - _Requisitos: 7.2_

- [x] 1.7 Atualizar `supabase/schema.sql` com a coluna, a tabela e as RPCs novas

## 2. Domínio e dados (app)

- [x] 2.1 Criar `lib/features/groups/domain/solicitacao_model.dart`
  - `StatusSolicitacao`, `GrupoAbertoModel`, `MinhaSolicitacaoModel`, `SolicitacaoPendenteModel`, todos com `fromJson`
  - _Requisitos: 2.4, 4.1, 5.2_

- [x] 2.2 Escrever testes de unidade dos modelos em `test/features/groups/domain/solicitacao_model_test.dart`
  - `fromJson`, `fromString`, `podeSolicitar`, data de fim da espera

- [x] 2.3 Criar `lib/features/groups/data/solicitacoes_provider.dart`
  - `SolicitacoesService` chamando as 9 RPCs
  - Providers `gruposAbertosProvider`, `minhasSolicitacoesProvider`, `solicitacoesPendentesProvider`, `contagemSolicitacoesProvider`, `aceitaSolicitacoesProvider`
  - Função para transformar `PostgrestException` e erros de rede em mensagens para o usuário
  - _Requisitos: 2.6, 5.6_

## 3. Telas

- [x] 3.1 Tela de membros (coordenador): switch "Aceitar solicitações de entrada"
  - Visível só para coordenadores; mostra estado de carregamento e erro
  - _Requisitos: 1.2, 1.3, 1.6_

- [x] 3.2 Tela de membros (coordenador): seção "Solicitações pendentes (N)"
  - Avatar com foto ou inicial, nome, data, mensagem, botões Recusar (com confirmação) e Aprovar
  - Recarrega membros e pendentes após decidir; trata "já foi decidida"
  - _Requisitos: 5.1–5.6_

- [x] 3.3 Rota `/explore` e helper `pushExploreGroups` em `app_router.dart`

- [x] 3.4 Tela "Encontrar grupos" (`explore_groups_screen.dart`)
  - Seção "Minhas solicitações" com status e Cancelar
  - Filtro por nome, lista de grupos abertos com ação conforme o estado
  - Diálogo de solicitação com mensagem opcional (280, contador)
  - Estados vazio e sem conexão
  - _Requisitos: 2.1–2.6, 3.1–3.6, 4.1, 4.2_

- [x] 3.5 Tela "Meus Grupos": botão "Encontrar grupos" na AppBar e no estado vazio; badge de pendentes nos grupos coordenados
  - O badge não aparece se a contagem falhar
  - _Requisitos: 4.3, 5.8_

## 4. Verificação e publicação

- [x] 4.1 `dart format`, `flutter analyze` e `flutter test` limpos

- [x] 4.2 Commit e PR (`Refs #41`)

- [x] 4.3 Após aprovação: merge, deploy Web, APK novo no Samsung
  - Conferir cabeçalhos da Vercel e que a foto do Google carrega com a CSP

- [x] 4.4 Teste manual com duas contas (usuário): pedir com mensagem, aprovar, recusar e espera de 7 dias, cancelar, fechar o grupo com pendentes; Web e Android

- [x] 4.5 Fechar a #41 e atualizar o HANDOFF
