# Tarefas — Perfil de usuário e uso da foto

> Issue: [#42](https://github.com/abpaula77/Vozes_da_Catedral/issues/42) · [Requisitos](./requirements.md) · [Design](./design.md)
> Branch: `feat/42-perfil-usuario`

A migration é aditiva e pode ser aplicada antes do app. Cada tarefa indica os requisitos que atende.

## 1. Banco de dados

- [x] 1.1 Criar `supabase/migrations/20261117_user_profile.sql`: bucket `avatars` privado (512 KB, JPEG/PNG/WebP) e as 4 policies de `storage.objects`
  - _Requisitos: 2.5, 4.3, 4.4, 4.5_

- [x] 1.2 Funções de foto: `_foto_valida`, `pode_ver_foto`, `definir_minha_foto`; `update_my_profile` passa a validar a foto; `grant select (foto)` em `users`
  - _Requisitos: 2.1, 2.3, 2.4, 2.6, 3.1, 4.1, 4.2_

- [x] 1.3 `atualizar_meu_nome` (2 a 80 caracteres; cria o perfil no primeiro acesso)
  - _Requisitos: 1.3, 5.2_

- [x] 1.4 Exclusão: `grupos_impedindo_exclusao`, `excluir_minha_conta` (autoria para o coordenador mais antigo) e ajuste da trigger `set_criado_por` para a flag `app.reatribuir_autor`
  - _Requisitos: 6.2–6.4_

- [x] 1.5 Escrever `supabase/tests/perfil_usuario.sql` com os cenários do design (exclusão em conta criada só para o teste)

- [x] 1.6 Aplicar a migration, rodar os testes SQL e os advisors; conferir que os dados reais não mudaram

- [x] 1.7 Atualizar `supabase/schema.sql`

## 2. Dados e domínio (app)

- [ ] 2.1 Adicionar `image_picker: 1.2.1` (versão fixada) ao `pubspec.yaml` e subir a versão para `0.2.0+3`

- [ ] 2.2 `lib/features/profile/domain/meu_perfil_model.dart` e validação do nome

- [ ] 2.3 `lib/features/profile/data/foto_resolver.dart` (Google direto; enviadas por link temporário em lote, 1 h, em memória; falha → inicial)
  - _Requisitos: 3.4, 3.5_

- [ ] 2.4 `lib/features/profile/data/profile_service.dart` e providers (carregar, nome, enviar/usar Google/remover foto, apagar arquivo anterior, excluir conta)
  - _Requisitos: 1.2, 1.3, 2.1–2.6, 6.1–6.3_

- [ ] 2.5 Testes de unidade: modelo, classificação da foto e validação do nome

## 3. Telas

- [ ] 3.1 Widget `lib/core/widgets/user_avatar.dart`
  - _Requisitos: 3.4_

- [ ] 3.2 Tela "Meu perfil" (rota `/profile`): foto com menu, nome, e-mail, Sair, excluir conta com confirmação `EXCLUIR`
  - _Requisitos: 1.1–1.5, 2.1–2.4, 6.1, 6.3_

- [ ] 3.3 Meus Grupos: avatar abre o perfil, no lugar do botão Sair
  - _Requisitos: 1.1, 1.4, 3.3_

- [ ] 3.4 Primeiro acesso: só confirmação do nome e foto do Google
  - _Requisitos: 5.1, 5.2_

- [ ] 3.5 Membros e solicitações com `UserAvatar`; `getMembros` lê `foto`
  - _Requisitos: 3.1, 3.2_

## 4. Verificação e publicação

- [ ] 4.1 `dart format`, `flutter analyze`, `flutter test`

- [ ] 4.2 Commit e PR (`Refs #42`)

- [ ] 4.3 Merge, deploy Web, APK `0.2.0+3` no Samsung

- [ ] 4.4 Teste manual (usuário): enviar foto (galeria; câmera no Android), ver no colega, trocar, Google, remover, nome, novo cadastro, excluir conta de teste

- [ ] 4.5 Fechar a #42 e atualizar o HANDOFF
