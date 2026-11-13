# Requisitos — Perfil de usuário e uso da foto

> Issue: [#42](https://github.com/abpaula77/Vozes_da_Catedral/issues/42)
> Status: **aprovado em 13/11/2026**.

## Introdução

Hoje o usuário não tem onde ver ou mudar os próprios dados. O nome e a foto são gravados uma única vez, no primeiro acesso (onboarding), a partir do cadastro ou da conta Google, e não mudam mais. A foto só aparece para o coordenador, na lista de solicitações de entrada (#41). Na lista de membros, todos aparecem só com a inicial do nome.

Esta feature cria uma tela de perfil e passa a mostrar a foto onde ela ajuda a reconhecer as pessoas.

### O que existe hoje (levantado em 13/11/2026)

- `public.users`: `id`, `nome`, `email`, `foto`, `papel`. O cliente só lê `id`, `nome` e `papel`; `email` e `foto` não podem ser lidos diretamente (restrição de 13/11/2026).
- Visibilidade de perfis (RLS): cada usuário vê o próprio perfil e o de quem está em algum grupo com ele.
- O perfil é gravado pela RPC `update_my_profile(nome, foto, papel)`.
- Fotos: 2 dos 6 usuários têm foto, as duas vindas do Google. Não há bucket no Supabase Storage.
- Login: e-mail/senha e Google.
- **Achado:** o onboarding pergunta se a pessoa é "Coordenador" ou "Membro" e grava isso em `users.papel`, mas o app não usa esse valor em nenhum lugar. O papel que vale é o de cada grupo (`membros_grupo.papel`). Hoje nenhum usuário tem `papel = coordenador` no perfil.

### Glossário

- **Perfil**: nome, foto e e-mail da conta.
- **Foto do Google**: endereço da imagem da conta Google (`avatar_url`), gravado no primeiro acesso.
- **Colega de grupo**: usuário que participa de pelo menos um grupo em comum.

### Fora do escopo

- Trocar e-mail ou senha pelo app (continua pelo fluxo do Supabase/Google).
- Perfil público ou visível para quem não é colega de grupo.
- Informações extras no perfil (naipe de voz, telefone, biografia). Ver wish list.

---

## Requisitos

### Requisito 1 — Tela "Meu perfil"

**História:** Como usuário, quero ver e ajustar meus dados, para que os colegas me reconheçam.

#### Critérios de aceite

1. O sistema DEVE oferecer acesso à tela "Meu perfil" a partir de "Meus Grupos", por um avatar com a foto (ou a inicial) do usuário na barra superior.
2. A tela DEVE mostrar a foto (ou a inicial), o nome e o e-mail da conta. O e-mail é só leitura e vem da sessão de login, sem consulta ao banco.
3. A tela DEVE permitir editar o nome, com no mínimo 2 e no máximo 80 caracteres, sem espaços sobrando nas pontas.
4. A tela DEVE ter o botão "Sair", que hoje fica direto na barra de "Meus Grupos".
5. SE o usuário estiver sem conexão, ENTÃO o sistema DEVE mostrar os dados conhecidos e avisar que alterações exigem internet.

### Requisito 2 — Foto do perfil

**História:** Como usuário, quero escolher minha foto, para ser reconhecido no grupo.

#### Critérios de aceite

1. O sistema DEVE permitir **enviar uma foto** do aparelho (galeria; câmera no Android).
2. QUANDO a foto é enviada, ENTÃO o sistema DEVE reduzi-la a no máximo 512×512 px e cerca de 200 KB antes de enviar.
3. O sistema DEVE permitir **remover** a foto, voltando a mostrar a inicial do nome.
4. SE o usuário entrou com Google, ENTÃO o sistema DEVE oferecer "Usar a foto do Google".
5. O sistema DEVE aceitar apenas imagens JPEG, PNG ou WebP.
6. Ao trocar ou remover a foto, a foto anterior enviada pelo usuário DEVE ser apagada do armazenamento.

### Requisito 3 — Onde a foto aparece

**História:** Como membro de um grupo, quero ver a foto dos colegas, para saber quem é quem.

#### Critérios de aceite

1. O sistema DEVE mostrar a foto na **lista de membros** do grupo, no lugar da inicial.
2. O sistema DEVE continuar mostrando a foto na lista de **solicitações de entrada** (#41).
3. O sistema DEVE mostrar a foto do próprio usuário no avatar de "Meus Grupos" e em "Meu perfil".
4. SE a foto não carregar (sem conexão ou endereço inválido), ENTÃO o sistema DEVE mostrar a inicial do nome, sem mensagem de erro.
5. O sistema NÃO DEVE guardar fotos para uso sem conexão: elas carregam só com internet; sem conexão, aparece a inicial.

### Requisito 4 — Privacidade da foto

#### Critérios de aceite

1. A foto de um usuário DEVE ser visível apenas para ele mesmo, para os **colegas de grupo** e para os coordenadores de grupos aos quais ele pediu entrada (#41).
2. O e-mail continua NÃO legível por outros usuários.
3. O arquivo de foto enviado DEVE ficar em um bucket **privado**, acessível só para quem pode ver a foto, por meio de links temporários.
4. Só o próprio usuário DEVE poder enviar, trocar ou apagar a sua foto.
5. Nenhuma operação de perfil DEVE estar disponível sem login.

### Requisito 5 — Papel no onboarding

#### Critérios de aceite

1. O sistema DEVE **remover** do primeiro acesso a escolha "Coordenador / Membro", porque o papel que vale é o de cada grupo. Quem cria um grupo já vira coordenador dele.
2. No lugar, o primeiro acesso DEVE confirmar o nome (pré-preenchido do cadastro ou do Google) e mostrar a foto, se houver.
3. A coluna `users.papel` PODE continuar no banco, sem uso, para não quebrar versões antigas do app.

### Requisito 6 — Excluir a conta

**História:** Como usuário, quero poder apagar minha conta e meus dados.

#### Critérios de aceite

1. "Meu perfil" DEVE ter a opção "Excluir minha conta", com confirmação digitando uma palavra (por exemplo "EXCLUIR").
2. A exclusão DEVE apagar o perfil, a foto enviada, as participações em grupos e as solicitações de entrada.
3. SE o usuário for o **único coordenador** de algum grupo, ENTÃO o sistema DEVE impedir a exclusão e listar esses grupos, pedindo que ele promova outro coordenador ou apague o grupo antes.
4. As músicas, celebrações e grupos criados pelo usuário DEVEM continuar existindo. A autoria passa para um coordenador do respectivo grupo.

### Requisito 7 — Compatibilidade

1. As mudanças no banco DEVEM ser aditivas: o Web e o APK atuais DEVEM continuar funcionando.
2. A lista de membros DEVE continuar funcionando se a foto não puder ser carregada.

---

## Decisões da revisão (13/11/2026)

1. **Envio de foto:** sim, pelo aparelho (galeria; câmera no Android).
2. **Foto do Google:** sim, com a opção "Usar a foto do Google".
3. **Armazenamento:** bucket **privado**, com links temporários.
4. **Primeiro acesso:** remover a escolha "Coordenador / Membro" e só confirmar o nome.
5. **Excluir conta:** incluir agora.
6. **Fotos sem conexão:** não; carregam só com internet.
7. **Campos extras:** wish list.

## Wish list (sem demanda atual)

- **Naipe de voz e outros campos no perfil** (soprano, contralto, tenor, baixo; telefone; biografia). Útil para o coordenador organizar o coral.