# Design — Perfil de usuário e uso da foto

> Issue: [#42](https://github.com/abpaula77/Vozes_da_Catedral/issues/42) · Requisitos: [requirements.md](./requirements.md)
> Status: **aprovado em 13/11/2026**

## Visão geral

Três partes, todas online:

1. **Perfil**: tela "Meu perfil" para editar o nome e a foto, e um primeiro acesso mais simples (só confirma o nome).
2. **Foto**: enviada para um bucket privado do Supabase Storage, ou a foto do Google. Aparece na lista de membros, nas solicitações (#41) e no avatar do próprio usuário.
3. **Excluir conta**: uma RPC que apaga a conta e passa a autoria do que o usuário criou para outro coordenador.

Como na #41, as regras ficam no banco (RPCs `security definer` e policies do Storage), e o SQLite local (Drift) não muda.

## Como a foto é guardada

A coluna `users.foto` continua sendo a única referência, com dois formatos possíveis:

| Valor | Origem | Como o app mostra |
|---|---|---|
| `null` | sem foto | inicial do nome |
| `https://...` | foto do Google | carrega o endereço direto |
| `avatars/<user_id>/<arquivo>` | foto enviada | pede um link temporário ao Storage e carrega |

Assim não é preciso coluna nova, e o Web e o APK atuais continuam lendo `foto` como texto. Eles não leem `foto` em nenhuma tela, então o formato novo não os afeta (requisito 7.1).

### Validação do valor (segurança)

Hoje `update_my_profile` aceita **qualquer** texto em `foto`. Isso permitiria gravar o endereço de uma imagem num servidor de terceiros: quem visse a foto teria o IP registrado por esse servidor. Por isso a gravação da foto passa a aceitar só:

- `null`;
- um caminho dentro da **própria** pasta: `avatars/<auth.uid()>/...`;
- o `avatar_url` ou `picture` da **própria** conta Google, lido de `auth.users.raw_user_meta_data` no servidor.

A regra fica numa função interna `public._foto_valida(p_foto text) → boolean`, usada pelas RPCs de perfil. O `update_my_profile` antigo também passa a usá-la. Ele só recebe a foto do Google vinda do próprio onboarding, que continua válida.

## Banco de dados

### Bucket `avatars` (privado)

Criado pela migration em `storage.buckets`:
- `public = false` (requisito 4.3);
- `file_size_limit = 524288` (512 KB, margem sobre os ~200 KB esperados);
- `allowed_mime_types = {image/jpeg, image/png, image/webp}` (2.5).

Caminho dos arquivos: `avatars/<user_id>/<uuid>.jpg`. Um nome novo a cada envio evita que o navegador mostre a imagem antiga em cache.

### Quem pode ver a foto — `public.pode_ver_foto(p_dono uuid) → boolean`

`security definer`, `stable`. Verdadeiro se:
1. `p_dono = auth.uid()`; ou
2. os dois têm pelo menos um grupo em comum; ou
3. `p_dono` tem solicitação **pendente** para um grupo que `auth.uid()` coordena (#41).

Essa função é a regra única do requisito 4.1. Ela é usada pela policy de leitura do Storage e protege tanto a foto enviada quanto o caminho dela.

### Policies em `storage.objects` (bucket `avatars`)

| Operação | Regra |
|---|---|
| `select` (necessário para gerar link temporário) | `bucket_id = 'avatars' and public.pode_ver_foto(((storage.foldername(name))[1])::uuid)` |
| `insert` | `bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text` |
| `update` | mesma regra do insert |
| `delete` | mesma regra do insert |

Só para o papel `authenticated` (4.5). O dono só escreve na própria pasta (4.4).

### Leitura da foto dos colegas

Hoje `users.foto` não pode ser lida pelo cliente. A RLS de `users` já limita as **linhas** visíveis ao próprio usuário e aos colegas de grupo. Com isso, liberar a **coluna** `foto` (`grant select (foto)`) entrega exatamente a regra 4.1, itens 1 e 2. O item 3, solicitantes, já sai pela `listar_solicitacoes_pendentes` da #41.

O e-mail continua bloqueado (4.2). O link temporário de uma foto enviada só é gerado se `pode_ver_foto` permitir, então ler o caminho não basta para ver a imagem.

### RPCs novas

Todas `security definer`, `search_path = ''`, sem `anon` e com `grant execute to authenticated`.

| Função | O que faz | Requisitos |
|---|---|---|
| `atualizar_meu_nome(p_nome text) → void` | `btrim`, 2 a 80 caracteres. Cria o perfil se ainda não existir (primeiro acesso). | 1.3, 5.2 |
| `definir_minha_foto(p_foto text) → text` | Valida com `_foto_valida` e grava. Devolve o valor **anterior**, para o app apagar o arquivo antigo do Storage. | 2.1, 2.3, 2.4, 2.6, 4.4 |
| `grupos_impedindo_exclusao() → table(id, nome)` | Grupos em que o usuário é o **único coordenador**. | 6.3 |
| `excluir_minha_conta() → void` | Ver abaixo. | 6.2–6.4 |

`update_my_profile` continua existindo, para as versões antigas do app, e passa a validar a foto.

### `excluir_minha_conta`

1. Se `grupos_impedindo_exclusao()` não estiver vazio → erro `Você é o único coordenador de: Coral 19h, Ministério X. Promova outro coordenador ou exclua esses grupos antes.` (6.3).
2. **Passa a autoria** de `grupos`, `musicas` e `celebracoes` com `criado_por = auth.uid()` para um coordenador do mesmo grupo, escolhido pelo mais antigo no grupo (6.4).
   - Necessário porque essas FKs **não** têm `on delete`, e a exclusão falharia.
   - Preferido a `set null` porque o app atual lê `criado_por` como obrigatório, e um valor nulo quebraria a sincronização de quem ainda não atualizou.
   - A trigger `set_criado_por` (#23) impede mudar o autor. A função liga uma flag local da transação (`set_config('app.reatribuir_autor', 'on', true)`), e a trigger passa a respeitá-la. O cliente não consegue ligar essa flag, porque `set_config` não é exposto pela API.
   - Efeito colateral: quem recebe a autoria de um **grupo** passa a poder excluí-lo, porque a policy de exclusão usa `criado_por`. É o esperado, já que ele é coordenador.
3. `delete from auth.users where id = auth.uid()`. As FKs com `cascade` apagam `public.users`, `membros_grupo` e `solicitacoes_grupo`; `decidida_por` vira `null` (6.2).
   - A trigger `protect_last_coordinator` (#23) já permite essa cascata.

A foto enviada é apagada **pelo app** antes da chamada, pela API do Storage, que a policy de `delete` permite. Se essa etapa falhar, a exclusão segue: o arquivo fica órfão, mas ninguém consegue vê-lo, porque `pode_ver_foto` de um usuário inexistente é sempre falso.

## App (Flutter)

### Pacote novo

- `image_picker: 1.2.1` (versão fixada; é a última compatível com o Dart 3.7 do projeto). Pacote oficial do time do Flutter, com suporte a Android e Web.
- A redução da imagem usa os parâmetros do próprio `pickImage` (`maxWidth: 512`, `maxHeight: 512`, `imageQuality: 80`), que funcionam no Android e no Web. Não precisa de outro pacote (2.2).
- Android: galeria e câmera. Web: seletor de arquivo; a câmera fica disponível só onde o navegador oferecer.
- Nenhuma permissão nova no Android: o `image_picker` abre o app de câmera do sistema por intent, e o manifesto do app não declara `CAMERA`.

### Camada de dados — `lib/features/profile/`

- `domain/meu_perfil_model.dart`: `MeuPerfilModel` (`id`, `nome`, `foto`, `email`).
- `data/profile_service.dart` (`ProfileService`):
  - `carregar()`: lê `id, nome, foto` de `users` e o e-mail de `auth.currentUser`;
  - `atualizarNome`, `definirFoto`, `usarFotoDoGoogle`, `removerFoto`;
  - `enviarFoto(XFile)`: upload em `avatars/<uid>/<uuid>.jpg`, depois `definir_minha_foto`, depois apaga o arquivo anterior;
  - `gruposImpedindoExclusao`, `excluirConta`: apaga a pasta no Storage, chama a RPC e faz `signOut`.
- `data/foto_resolver.dart`: transforma `users.foto` em endereço de imagem.
  - `https://` → direto;
  - `avatars/...` → `createSignedUrls` em **lote** (um pedido para a lista inteira de membros), com validade de 1 hora, guardado em memória enquanto o app está aberto.
  - Falha → `null` (mostra a inicial, 3.4).

### Widget compartilhado — `lib/core/widgets/user_avatar.dart`

`UserAvatar(nome:, foto:, radius:)`: resolve a foto com `foto_resolver`, mostra a imagem ou a inicial e trata erros de carregamento sem aviso (3.4). Substitui os `CircleAvatar` com inicial da lista de membros e das solicitações.

### Telas

**1. Meus Grupos**: o ícone "Sair" vira um `UserAvatar` que abre "Meu perfil" (1.1, 1.4).

**2. Meu perfil (nova, rota `/profile`)**
- Foto grande, com botão "Alterar foto" que abre um menu: Escolher da galeria · Tirar foto (Android) · Usar a foto do Google (se a conta tiver) · Remover foto.
- Nome editável, com Salvar; e-mail só leitura (1.2, 1.3).
- Botão "Sair".
- Seção "Excluir minha conta":
  - primeiro consulta `grupos_impedindo_exclusao`; se houver grupos, mostra a lista e o motivo;
  - senão, abre a confirmação: digitar `EXCLUIR`;
  - depois da exclusão, volta para o login.
- Sem conexão: mostra os dados conhecidos e desabilita as ações, com aviso (1.5).

**3. Primeiro acesso (onboarding)**: sai a escolha Coordenador/Membro. Fica a foto (se houver), o nome pré-preenchido e editável, e o botão Continuar, que chama `atualizar_meu_nome` e `definir_minha_foto` com a foto do Google, se houver (5.1, 5.2).

**4. Membros**: `getMembros` passa a ler `id, nome, foto`, e a lista usa `UserAvatar` (3.1).

**5. Solicitações (#41)**: a lista de pendentes usa `UserAvatar`, que agora também entende fotos enviadas (3.2).

### CSP do Web

Os links temporários do Storage vêm de `https://npujroyocclobjrpeaed.supabase.co/storage/...`, já coberto por `img-src https:` e `connect-src https://*.supabase.co`. A CSP não muda.

## Tratamento de erros

| Situação | Resposta |
|---|---|
| Imagem acima de 512 KB após reduzir, ou formato não aceito | "Escolha uma imagem JPEG, PNG ou WebP." / "A imagem é grande demais." |
| Upload falha | Mantém a foto atual; mensagem de conexão |
| Nome inválido | Validação no campo (2 a 80 caracteres) |
| Exclusão bloqueada | Lista dos grupos em que é o único coordenador |
| Sem conexão | Ações desabilitadas, aviso de internet |

## Testes

### Banco — `supabase/tests/perfil_usuario.sql` (transação revertida)

- `_foto_valida`: aceita `null`, a própria pasta e a foto do Google da própria conta; recusa a pasta de outro usuário e um `https://` qualquer.
- `update_my_profile` e `definir_minha_foto` recusam foto inválida.
- `pode_ver_foto`: o próprio usuário, colega e coordenador de grupo com pedido pendente → verdadeiro; desconhecido → falso.
- Coluna `foto` legível para colega e não para desconhecido (RLS); `email` continua bloqueado.
- `atualizar_meu_nome` valida os limites.
- `excluir_minha_conta`:
  - bloqueia o único coordenador;
  - com outro coordenador presente, passa a autoria de grupo, música e celebração e apaga usuário, participações e pedidos;
  - músicas e celebrações continuam existindo;
  - roda em uma conta **criada só para o teste** dentro da transação, para nunca apagar um usuário real.
- `anon` não executa as RPCs.
- As policies do Storage existem com as regras acima. O upload em si é testado manualmente, porque a API do Storage não roda dentro do SQL.

### App

- Unidade: `MeuPerfilModel`, a classificação de `foto` (Google, enviada, nula) no `foto_resolver` e a validação do nome.
- `flutter analyze` e `flutter test` limpos.

### Manual (Web e Android)

Enviar foto pela galeria (e pela câmera no Android) → aparece no perfil e, para um colega, na lista de membros. Trocar e conferir que o arquivo antigo sumiu do bucket. "Usar a foto do Google" e remover. Editar o nome. Novo cadastro sem a escolha de papel. Excluir uma conta de teste: bloqueio como único coordenador e exclusão com sucesso.

## Publicação

1. Migration (aditiva) e testes SQL. O app atual continua funcionando.
2. Merge, deploy Web, APK, e subir a versão para `0.2.0+3` (feature nova visível).
3. Teste manual.

## Decisões da revisão (13/11/2026)

1. **Autoria ao excluir a conta**: passa para o coordenador mais antigo do grupo.
2. **Arquivo órfão**: se apagar a foto do Storage falhar, a exclusão da conta segue; o arquivo fica inacessível.
3. **Versão do app**: sobe para `0.2.0+3` nesta entrega.