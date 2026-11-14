# Requisitos — Excluir grupo

> Issue: [#61](https://github.com/abpaula77/Vozes_da_Catedral/issues/61)
> Status: **aprovado em 14/11/2026**.

## Introdução

Hoje o app não tem como excluir um grupo. Esta feature dá ao coordenador essa opção, mostra antes o que será perdido, permite salvar o conteúdo exclusivo em outro grupo e avisa os membros dentro do app.

### Decisões já tomadas (14/11/2026)

1. **Qualquer coordenador** do grupo pode excluí-lo.
2. **Sem lixeira:** a exclusão é imediata e definitiva.
3. Antes de excluir, o coordenador pode **copiar de uma vez** para outro grupo que coordena as músicas que só existem no grupo e todas as celebrações.
4. Os membros são avisados **só dentro do app**, na próxima sincronização. Push e e-mail ficam com a #56.

### O que existe hoje (levantado em 14/11/2026)

- A regra de exclusão no banco permite excluir **só a quem consta como criador** (`grupos.criado_por`), mesmo que ele tenha sido rebaixado a membro (#52). **Falha de segurança:** um membro comum que criou o grupo pode apagá-lo pela API.
- Excluir o grupo no banco apaga junto, em cascata, membros, músicas, celebrações (e itens) e solicitações de entrada.
- Cópias de músicas em outros grupos são independentes e **sobrevivem** (perdem só o vínculo com a origem).
- O plano Free do Supabase não tem backup restaurável: a exclusão não tem volta.
- Quando um grupo deixa de aparecer para o usuário, a sincronização tira o grupo da lista do aparelho, mas **deixa as músicas e celebrações dele no banco local**.
- O **banco local é do aparelho, não da conta**: sair da conta não o limpa. Ver ponto de atenção 1.

### Números atuais (14/11/2026)

| Grupo | Membros | Músicas | Exclusivas | Celebrações |
|---|---|---|---|---|
| Vozes Da Catedral | 2 | 113 | 15 | 2 |
| Grupo Jovem | 5 | 98 | 5 (cópias editadas no grupo) | 1 |
| teste de grupo | 1 | 1 | 0 | 0 |
| Flores de Deus | 2 | 0 | 0 | 0 |
| Jardim de Maria | 2 | 0 | 0 | 0 |

"Exclusivas" segue a definição do glossário: as 5 do Grupo Jovem são cópias de músicas do Vozes Da Catedral que foram editadas no Grupo Jovem; a versão editada só existe lá.

### Glossário

- **Música exclusiva**: música do grupo que deixaria de existir no app com a exclusão. É uma música que não foi copiada para nenhum outro grupo e que não é uma cópia idêntica de uma música que continua existindo em outro grupo.
- **Conteúdo exclusivo**: as músicas exclusivas e todas as celebrações do grupo.

### Fora do escopo

- Lixeira ou recuperação de grupos excluídos.
- Notificação por push ou e-mail (#56).
- Transferir membros para outro grupo.

---

## Requisitos

### Requisito 1 — Opção de excluir

**História:** Como coordenador, quero excluir um grupo que não é mais usado.

#### Critérios de aceite

1. O sistema DEVE mostrar a opção "Excluir grupo" só para coordenadores do grupo, na tela de membros.
2. SE quem pede a exclusão não for coordenador do grupo, ENTÃO o sistema DEVE recusar, inclusive para quem consta como criador.
3. O sistema NÃO DEVE permitir excluir o grupo por acesso direto à tabela; só pela operação de exclusão (requisito 3).
4. SE o usuário estiver sem conexão, ENTÃO o sistema DEVE informar que a exclusão exige internet.

### Requisito 2 — Resumo antes de excluir

**História:** Como coordenador, quero saber o que será perdido antes de confirmar.

#### Critérios de aceite

1. ANTES de confirmar, o sistema DEVE mostrar quantos **membros**, **músicas**, **músicas exclusivas**, **celebrações** e **solicitações de entrada pendentes** o grupo tem.
2. O sistema DEVE explicar que músicas copiadas para outros grupos continuam existindo neles.
3. O sistema DEVE explicar que a exclusão é **definitiva** e não pode ser desfeita.

### Requisito 3 — Confirmação e exclusão

#### Critérios de aceite

1. O sistema DEVE exigir que o coordenador **digite o nome do grupo** para confirmar (sem diferenciar maiúsculas e espaços nas pontas).
2. QUANDO confirmada, ENTÃO o sistema DEVE apagar, numa única operação, o grupo, os membros, as músicas, as celebrações (com os itens) e as solicitações de entrada.
3. SE qualquer parte falhar, ENTÃO o sistema NÃO DEVE apagar nada.
4. O sistema DEVE registrar a exclusão (grupo, nome, quem excluiu, quando) para auditoria, sem dados de membros. O registro fica só no Supabase, sem acesso pelo app.
5. QUANDO a exclusão termina, ENTÃO o sistema DEVE voltar o coordenador para "Meus Grupos" e remover o grupo e o conteúdo dele do aparelho.

### Requisito 4 — Copiar o conteúdo exclusivo antes de excluir

**História:** Como coordenador, quero salvar em outro grupo o que só existe neste, antes de excluir.

#### Critérios de aceite

1. O sistema DEVE oferecer "Copiar para outro grupo" no resumo da exclusão, quando houver conteúdo exclusivo.
2. O destino DEVE ser escolhido entre os outros grupos que o usuário **coordena**. SE não houver nenhum, ENTÃO o sistema DEVE explicar isso e sugerir criar um grupo antes.
3. QUANDO confirmada, ENTÃO o sistema DEVE copiar para o destino as **músicas exclusivas** e **todas as celebrações** (as celebrações levam junto as músicas que usam).
4. O sistema DEVE mostrar quantas músicas e celebrações foram copiadas.
5. Copiar NÃO DEVE excluir o grupo; a exclusão continua sendo um passo separado e confirmado.
6. Copiar de novo para o mesmo destino NÃO DEVE duplicar músicas (as cópias de música já são únicas por origem). Depois de copiar, o botão DEVE ficar desabilitado naquela tela, para não duplicar celebrações.

### Requisito 5 — Aviso aos membros

**História:** Como membro, quero saber que deixei de ter acesso a um grupo.

#### Critérios de aceite

1. QUANDO a sincronização dos grupos detecta que o usuário não participa mais de um grupo que estava no aparelho, ENTÃO o sistema DEVE avisar: "Você não participa mais do grupo X."
2. O aviso DEVE aparecer tanto para grupo excluído quanto para remoção do membro pelo coordenador (o app não diferencia os dois casos).
3. O sistema DEVE remover do aparelho as músicas, celebrações, itens e status de sincronização desse grupo.
4. O sistema NÃO DEVE mostrar o aviso por causa de troca de conta no mesmo aparelho (ver requisito 6).

### Requisito 6 — Cache local por conta

**História:** Como usuário de um aparelho compartilhado, não quero ver nem guardar dados de outra conta.

#### Critérios de aceite

1. O sistema DEVE guardar no aparelho de qual conta é o conteúdo local.
2. QUANDO entra uma conta diferente da dona do conteúdo local, ENTÃO o sistema DEVE apagar esse conteúdo **antes** de mostrar os grupos, sem avisos.
3. QUANDO a mesma conta sai e entra de novo, ENTÃO o sistema DEVE manter o conteúdo local (uso offline).

### Requisito 7 — Compatibilidade

1. As mudanças no banco DEVEM manter funcionando as versões atuais do app (Web e APK 0.2.0), que não têm opção de excluir grupo.
2. A exclusão de conta (#42) continua bloqueada para quem é o único coordenador; a mensagem já sugere excluir o grupo, o que passa a ser possível.

---

## Pontos de atenção

1. **Cache local compartilhado entre contas (privacidade).** *Decidido: proposta aceita (requisito 6).* O banco local do aparelho não é limpo ao sair da conta. Se outra pessoa entra no mesmo aparelho:
   - ela vê por instantes os grupos da conta anterior, até a sincronização;
   - as músicas e celebrações da conta anterior continuam guardadas no aparelho;
   - com o aviso do requisito 5, ela receberia "Você não participa mais do grupo X" para cada grupo da conta anterior.

   **Proposta:** guardar no banco local de qual conta é o cache e **limpá-lo quando entrar outra conta** (sem avisos). Quem sai e entra com a mesma conta mantém o conteúdo offline. Alternativa: limpar sempre ao sair, perdendo alterações offline ainda não sincronizadas.
2. **Alterações offline não sincronizadas** de um grupo excluído (por exemplo, uma celebração editada sem internet) são descartadas no aparelho. Proposta: aceitar; o grupo não existe mais.
3. **Copiar celebrações duas vezes** para o mesmo destino cria celebrações repetidas (a cópia de celebração não verifica repetição). *Decidido:* depois de copiar, o botão fica desabilitado naquela tela; não impedir no banco.
4. **Registro de auditoria.** Proposta: uma tabela simples `grupos_excluidos` (id, nome, quem excluiu, quando), sem acesso pelo app, consultável só pelo painel do Supabase. Ajuda a responder "quem apagou o grupo X?". *Decidido: registrar, só no Supabase.*
5. **Solicitações de entrada pendentes** para o grupo somem; o solicitante simplesmente deixa de ver o pedido em "Minhas solicitações". Proposta: aceitar.
6. **Membros sem internet** continuam vendo o conteúdo guardado no aparelho até a próxima sincronização. Proposta: aceitar.
7. **Cópia editada.** Uma música do grupo que é cópia de outra, mas foi editada aqui, conta como **exclusiva** (a versão editada se perderia). O original continua existindo no outro grupo.
8. **Modelo de cópias por grupo.** Registrado como a #65 a proposta de um cadastro central de músicas (hinário do app; grupos só referenciam; celebrações dos grupos). Esta feature segue com o modelo atual de cópias.

Os pontos 2, 5, 6 e 7 foram aceitos como propostos.