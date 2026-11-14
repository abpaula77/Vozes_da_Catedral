# Tarefas — Excluir grupo

> Issue: [#61](https://github.com/abpaula77/Vozes_da_Catedral/issues/61) · [Requisitos](./requirements.md) · [Design](./design.md)
> Branch: `feat/61-excluir-grupo`

A migration pode ser aplicada antes do app: nenhuma versão atual exclui grupos.

## 1. Banco de dados

- [ ] 1.1 Migration `supabase/migrations/20261120_excluir_grupo.sql`: remover a policy de exclusão direta; tabela `grupos_excluidos` (RLS sem policies, `revoke all`)
  - _Requisitos: 1.2, 1.3, 3.4_
- [ ] 1.2 Função interna `_musicas_exclusivas` e RPC `resumo_exclusao_grupo`
  - _Requisitos: 2.1_
- [ ] 1.3 RPC `copiar_conteudo_exclusivo` (reaproveita `copy_song_to_group` e `copy_celebration_to_group`)
  - _Requisitos: 4.2–4.6_
- [ ] 1.4 RPC `excluir_grupo` (coordenador, `for update`, confere o nome, registra, apaga)
  - _Requisitos: 1.2, 3.1–3.4_
- [ ] 1.5 Testes `supabase/tests/excluir_grupo.sql` (inclui a trigger do último coordenador na cascata)
- [ ] 1.6 Aplicar a migration, rodar os testes e os advisors; conferir que os dados reais não mudaram
- [ ] 1.7 Atualizar `supabase/schema.sql`

## 2. Banco local e dados (app)

- [ ] 2.1 Drift v5: tabela `AppMetaLocal`, migração, `removerConteudoDoGrupo`, `limparTudo`, `lerMeta`/`gravarMeta`, `AppDatabase.forTesting`; regenerar o código do Drift
  - _Requisitos: 5.3, 6_
- [ ] 2.2 `garantirDonoDoCache` e `cacheLocalProntoProvider`; `gruposProvider` e as telas que leem o banco local aguardam o provider
  - _Requisitos: 6.1–6.3, 5.4_
- [ ] 2.3 `syncGrupos` devolve os grupos removidos e limpa o conteúdo deles
  - _Requisitos: 5.1–5.3_
- [ ] 2.4 `GruposService`: `resumoExclusao`, `copiarConteudoExclusivo`, `excluirGrupo` (com limpeza local)
  - _Requisitos: 1.4, 3.5_
- [ ] 2.5 Testes do banco local em memória (limpeza por grupo; dono do cache)

## 3. Telas

- [ ] 3.1 Meus Grupos: aviso "Você não participa mais do grupo X." depois da sincronização
  - _Requisitos: 5.1, 5.2_
- [ ] 3.2 Membros: "Zona de perigo" com o botão Excluir grupo (só coordenador)
  - _Requisitos: 1.1_
- [ ] 3.3 Fluxo de exclusão: resumo, cópia para outro grupo (botão desabilita depois), confirmação pelo nome, volta para Meus Grupos
  - _Requisitos: 2.1–2.3, 3.1, 3.5, 4.1–4.6_
- [ ] 3.4 Testes de tela do fluxo (nome certo habilita; cópia desabilita)

## 4. Verificação e publicação

- [ ] 4.1 `dart format`, `flutter analyze`, `flutter test`
- [ ] 4.2 Commit e PR (`Refs #61`)
- [ ] 4.3 Merge, deploy Web, APK no Samsung
- [ ] 4.4 Teste manual (usuário): copiar, excluir, aviso em outra conta, troca de conta no mesmo aparelho
- [ ] 4.5 Fechar a #61 e atualizar o HANDOFF
