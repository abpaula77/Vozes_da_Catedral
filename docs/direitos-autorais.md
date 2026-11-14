# Direitos autorais do catálogo

Política de uso adotada pelo projeto em 14/11/2026 (issue [#27](https://github.com/abpaula77/Vozes_da_Catedral/issues/27)).

> Este documento registra como o projeto organiza a informação de autoria e licença das músicas. Não é um parecer jurídico. Em caso de dúvida sobre uma obra específica, consulte a editora ou um profissional da área.

## Decisões

1. **O catálogo é compartilhado.** Qualquer usuário autenticado pode consultar as músicas de todos os grupos e copiá-las para o próprio hinário. É o objetivo do app: compartilhar conteúdos e estruturas de celebrações.
2. **Não há música privada** por enquanto.
3. **Nada é bloqueado** pelo app por causa da situação de direitos. Os campos de autoria e licença são informativos e servem para a manutenção do catálogo.
4. **Os autores devem ser creditados.** Cada música pode registrar letrista, compositor e editora, visíveis para todos os usuários no hinário.
5. **Uso piloto.** O app está em uso piloto pelo Coral da Catedral de Santo Antônio (Piracicaba/SP). Obras protegidas sem autorização ficam marcadas como `pendente` até a situação ser resolvida.

## Campos de cada música

Preenchidos no cabeçalho do TXT ao importar ou editar a música (detalhes em [formato-musicas.md](formato-musicas.md)):

| Campo | Exemplo |
|---|---|
| `[TITULO]` | Da cepa brotou a rama |
| `[LETRISTA]` | Dom Carlos Alberto Navarro |
| `[COMPOSITOR]` | Pe. Waldeci Farias |
| `[EDITORA]` | Edições CNBB / Paulus |
| `[DIREITOS]` | protegida até 2086 |
| `[LICENCA_APP]` | pendente |

### `[DIREITOS]`: situação da obra

| Valor | Significado |
|---|---|
| `dominio-publico` | A obra está em domínio público. |
| `protegida` | A obra está protegida. Opcionalmente, informe o último ano de proteção: `protegida até 2086`. |
| `nao-verificado` | A situação ainda não foi pesquisada. |

Referência para estimar o ano: pela Lei 9.610/1998 (art. 41), os direitos patrimoniais duram 70 anos contados de 1º de janeiro do ano seguinte ao falecimento do autor. Quando há mais de um autor (letra e música, por exemplo), o prazo conta a partir do falecimento do último deles (art. 42). Confirme sempre na fonte.

### `[LICENCA_APP]`: autorização para uso no app

| Valor | Significado |
|---|---|
| `pendente` | Pendente de autorização; uso piloto restrito. |
| `autorizada` | O detentor dos direitos autorizou o uso. |
| `nao-necessaria` | Não é necessária autorização (por exemplo, domínio público). |
| `negada` | O detentor negou o uso. Hoje o app não bloqueia a música; o registro indica o que precisa ser retirado do catálogo. |

## Onde a informação aparece

- **Hinário:** quadro "Autoria e direitos" no detalhe da música e filtro por situação de licença na lista ("Licença não informada", "Pendente", "Autorizada", "Não necessária", "Negada").
- **Celebrações e modo performance:** não aparece, porque não é relevante para a execução da música.

## Manutenção

1. No hinário, use o filtro **"Licença não informada"** para ver as músicas que ainda não foram revisadas.
2. Edite a música e acrescente as linhas de autoria e direitos no cabeçalho.
3. Com conexão, a edição já atualiza o catálogo. Se o app avisar que a alteração ficou só no dispositivo, publique as músicas do grupo quando houver conexão.

Os dados ficam no conteúdo da música e acompanham as cópias para outros grupos no momento da cópia. Uma cópia já feita não é atualizada quando o original muda.

## Wish list

- Importação e atualização em lote dos dados de autoria e licença (por exemplo, por planilha), para não editar música por música.
