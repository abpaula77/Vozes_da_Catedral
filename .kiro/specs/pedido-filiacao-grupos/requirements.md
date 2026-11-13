# Requisitos — Pedido de filiação a grupos

> Issue: [#41](https://github.com/abpaula77/Vozes_da_Catedral/issues/41)
> Status: **aprovado em 13/11/2026**.

## Introdução

Hoje a única forma de entrar em um grupo é o coordenador convidar pelo e-mail completo da conta (#24). Isso exige que o coordenador saiba o e-mail de cada pessoa.

Esta feature cria um segundo caminho, iniciado pelo usuário: ele encontra o grupo, pede para entrar e um coordenador aprova ou recusa. O coordenador só vê os dados de quem pediu para entrar, então não volta a existir uma forma de listar todos os usuários cadastrados.

### Decisões já tomadas (13/11/2026)

1. O grupo só aparece na busca se um coordenador o marcar como **aberto a solicitações** (opt-in).
2. Quem for recusado pode pedir de novo **após 7 dias**.
3. O coordenador vê **nome e foto** (se houver) do solicitante. Nunca o e-mail.
4. **Sem notificação push.** O coordenador vê as solicitações ao abrir o app ou sincronizar.

### Glossário

- **Grupo aberto**: grupo com a opção "aceitar solicitações de entrada" ligada.
- **Solicitante**: usuário autenticado que pediu para entrar em um grupo do qual não é membro.
- **Solicitação**: registro do pedido, com status `pendente`, `aprovada`, `recusada` ou `cancelada`.
- **Coordenador**: membro com papel `coordenador` no grupo. Qualquer coordenador do grupo pode decidir.

### Fora do escopo

- Notificações push ou por e-mail.
- Convite por link ou QR code.
- Tela de perfil do usuário e upload de foto (ficam na #42). Aqui a foto usada é a que já existe em `users.foto`, vinda do Google.
- Funcionamento offline: buscar grupos, solicitar e decidir exigem conexão.

---

## Requisitos

### Requisito 1 — Abrir e fechar o grupo para solicitações

**História:** Como coordenador, quero escolher se meu grupo aceita pedidos de entrada, para que só grupos que desejam novos membros apareçam na busca.

#### Critérios de aceite

1. QUANDO um grupo é criado, ENTÃO o sistema DEVE deixá-lo **fechado** para solicitações.
2. QUANDO um coordenador liga a opção "Aceitar solicitações de entrada", ENTÃO o sistema DEVE passar a listar o grupo na busca de grupos abertos.
3. QUANDO um coordenador desliga a opção, ENTÃO o sistema DEVE retirar o grupo da busca e recusar novos pedidos para ele.
4. QUANDO um coordenador desliga a opção e existem solicitações pendentes, ENTÃO o sistema DEVE mantê-las pendentes até um coordenador aprová-las ou recusá-las.
5. SE um usuário que não é coordenador do grupo tentar alterar a opção, ENTÃO o sistema DEVE rejeitar a alteração.
6. O sistema DEVE mostrar a opção apenas para coordenadores, na tela de membros do grupo.

### Requisito 2 — Encontrar grupos abertos

**História:** Como usuário, quero ver os grupos que aceitam novos membros, para escolher em qual pedir entrada.

#### Critérios de aceite

1. QUANDO o usuário abre "Encontrar grupos" a partir da tela "Meus Grupos", ENTÃO o sistema DEVE listar apenas os grupos abertos dos quais ele **não** é membro.
2. O sistema DEVE mostrar de cada grupo apenas **nome e descrição**. Não DEVE mostrar membros, quantidade de membros, coordenadores, músicas nem celebrações.
3. O sistema DEVE permitir filtrar a lista pelo nome do grupo.
4. PARA cada grupo listado, o sistema DEVE indicar se o usuário já tem uma solicitação pendente ou recusada para ele.
5. SE não houver grupos abertos, ENTÃO o sistema DEVE informar isso com uma mensagem amigável.
6. SE o usuário estiver sem conexão, ENTÃO o sistema DEVE informar que a busca exige internet.

### Requisito 3 — Solicitar entrada

**História:** Como usuário, quero pedir para entrar em um grupo aberto, para participar sem depender de alguém saber meu e-mail.

#### Critérios de aceite

1. QUANDO o usuário toca em "Solicitar entrada" em um grupo aberto, ENTÃO o sistema DEVE criar uma solicitação `pendente`.
2. O sistema DEVE permitir que o usuário escreva uma **mensagem opcional** junto ao pedido (por exemplo "Sou tenor do coral das 19h"), com no máximo 280 caracteres. O pedido DEVE poder ser enviado sem mensagem.
3. SE o usuário já tiver uma solicitação pendente para o grupo, ENTÃO o sistema NÃO DEVE criar outra. O pedido fica pendente, sem prazo de expiração, até um coordenador decidir ou o próprio usuário cancelar.
4. SE o usuário já for membro do grupo, ENTÃO o sistema DEVE rejeitar o pedido.
5. SE o grupo estiver fechado, ENTÃO o sistema DEVE rejeitar o pedido.
6. SE a última solicitação do usuário para o grupo foi recusada há menos de 7 dias, ENTÃO o sistema DEVE rejeitar o pedido e informar a partir de quando ele poderá pedir de novo.
7. O sistema NÃO DEVE limitar quantos grupos **diferentes** um usuário pode solicitar ao mesmo tempo. *Motivo: o risco é só spam (não exposição de dados), o alcance é pequeno (grupos começam fechados) e um limite por conta é contornável com outra conta. As contenções são a recusa pelo coordenador, a espera de 7 dias e o limite da mensagem. Ver "Wish list".*

### Requisito 4 — Acompanhar e cancelar o próprio pedido

**História:** Como solicitante, quero saber o status do meu pedido e poder desistir dele.

#### Critérios de aceite

1. O sistema DEVE mostrar ao solicitante o status de cada pedido: pendente, recusado (com a data a partir da qual pode pedir de novo) ou aprovado.
2. QUANDO o solicitante cancela um pedido pendente, ENTÃO o sistema DEVE marcá-lo como `cancelado` e permitir um novo pedido imediatamente.
3. QUANDO um pedido é aprovado, ENTÃO o grupo DEVE aparecer em "Meus Grupos" na próxima sincronização.
4. O solicitante NÃO DEVE ver quem decidiu o pedido.

### Requisito 5 — Ver e decidir solicitações (coordenador)

**História:** Como coordenador, quero ver quem pediu para entrar e aprovar ou recusar cada pedido.

#### Critérios de aceite

1. O sistema DEVE mostrar na tela de membros uma seção "Solicitações pendentes" com um contador, visível só para coordenadores.
2. PARA cada solicitação pendente, o sistema DEVE mostrar **nome**, **foto** (se houver; senão, a inicial do nome), a data do pedido e a mensagem, se houver.
3. O sistema NÃO DEVE mostrar o e-mail do solicitante.
4. QUANDO o coordenador aprova, ENTÃO o sistema DEVE, em uma única operação, adicionar o solicitante como `membro` e marcar a solicitação como `aprovada`.
5. QUANDO o coordenador recusa, ENTÃO o sistema DEVE marcar a solicitação como `recusada` e registrar a data, iniciando o prazo de 7 dias.
6. SE dois coordenadores decidirem o mesmo pedido ao mesmo tempo, ENTÃO o sistema DEVE aplicar só a primeira decisão e informar ao segundo que o pedido já foi decidido.
7. O sistema DEVE registrar quem decidiu e quando, para auditoria.
8. QUANDO o coordenador abre a tela "Meus Grupos", ENTÃO o sistema DEVE indicar os grupos com solicitações pendentes.

### Requisito 6 — Privacidade e segurança

**História:** Como responsável pelo app, quero que este fluxo não reabra a exposição de dados de usuários corrigida nas issues #24 e de minimização de dados.

#### Critérios de aceite

1. O sistema NÃO DEVE oferecer nenhuma forma de listar usuários que não pediram para entrar no grupo.
2. O sistema DEVE expor nome e foto de um usuário apenas aos coordenadores de grupos para os quais ele tem solicitação **pendente**.
3. O sistema NÃO DEVE expor o e-mail em nenhuma tela ou resposta deste fluxo.
4. O sistema NÃO DEVE liberar leitura direta da coluna `users.foto`; a foto sai apenas pela consulta de solicitações.
5. Um usuário DEVE ver apenas as próprias solicitações; um coordenador, apenas as dos seus grupos.
6. Nenhuma operação deste fluxo DEVE estar disponível para usuários não autenticados.
7. A busca de grupos NÃO DEVE revelar a existência de grupos fechados.

### Requisito 7 — Compatibilidade

#### Critérios de aceite

1. O convite por e-mail exato (#24) DEVE continuar funcionando sem mudanças.
2. As mudanças no banco DEVEM ser apenas aditivas, para que as versões atuais do app (Web e APK 0.1.1) continuem funcionando até receberem a atualização.
3. Remover um membro aprovado DEVE seguir as regras atuais, incluindo a proteção do último coordenador.

---

## Decisões da revisão (13/11/2026)

1. **Pedidos pendentes ao fechar o grupo** (1.4): ficam pendentes até um coordenador decidir.
2. **Mensagem opcional no pedido** (3.2): incluída, até 280 caracteres.
3. **Limite entre grupos diferentes** (3.7): não implementar agora; registrado na wish list.
4. **Detalhes do grupo na busca** (2.2): só nome e descrição, sem quantidade de membros.

## Wish list (sem demanda atual)

- **Limite de solicitações pendentes por usuário em grupos diferentes.** Contra spam, se aparecer abuso. Pode ser feito só no banco (checagem na RPC de solicitar entrada), sem mudar o app.
- **Convite para e-mail ainda não cadastrado.** Hoje o convite por e-mail não tem efeito se a conta não existe: nada é guardado e a pessoa não entra depois de se cadastrar. Uma opção seria guardar o convite e aplicá-lo no cadastro, sem revelar ao coordenador se o e-mail já existia. Exigiria guardar e-mails de não usuários, o que tem impacto de privacidade (LGPD). Com o pedido de filiação, a pessoa recém-cadastrada pode pedir entrada sozinha, o que reduz a necessidade.
