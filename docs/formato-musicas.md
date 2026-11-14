# Formato de músicas `.txt`

O hinário importa arquivos de texto simples em UTF-8 com extensão `.txt`. O formato é interpretado pelo parser do app; os nomes dos campos e das seções devem seguir os exemplos abaixo.

Coordenadores também podem editar uma música diretamente no app. O editor usa
este mesmo formato e valida o conteúdo antes de salvar. Se não houver conexão
com o Supabase, a alteração fica salva no dispositivo; conecte-se e publique as
músicas do grupo para sincronizá-la.

## Modelo

```text
[TITULO]: Nome da música
[TOM]: D
[CATEGORIA]: entrada, advento
[MOMENTO]: entrada, comunhao
[BPM]: 92
[VIDEO]: https://www.youtube.com/watch?v=XXXXXXXXXXX
[LETRISTA]: Nome de quem escreveu a letra
[COMPOSITOR]: Nome de quem compôs a música
[EDITORA]: Editora ou gravadora
[DIREITOS]: protegida até 2086
[LICENCA_APP]: pendente

[ESTROFE 1]
D                 A
Primeira linha da letra
G                 D
Segunda linha da letra

[REFRAO]
G              D
Refrão da música
A              D
Refrão continua aqui

[ESTROFE 2]
D                 A
Outra estrofe
G                 D
Mais uma linha
```

## Cabeçalho

Os campos devem ficar no início do arquivo, antes da primeira seção:

| Campo | Obrigatório | Descrição |
|---|---|---|
| `[TITULO]` | Sim | Título exibido no hinário. Use esta grafia sem acento. |
| `[TOM]` | Não | Tom original, por exemplo `D`, `F#m` ou `Bb`. |
| `[CATEGORIA]` | Não | Categoria ou lista separada por vírgulas. |
| `[CATEGORIAS]` | Não | Forma alternativa para informar categorias separadas por vírgulas. |
| `[MOMENTO]` | Não | Um ou mais momentos litúrgicos separados por vírgulas. Use os identificadores listados abaixo. |
| `[MOMENTOS]` | Não | Forma alternativa de `[MOMENTO]`. |
| `[BPM]` | Não | Andamento em número inteiro, por exemplo `92`. |
| `[VIDEO]` | Não | Link de um vídeo da música (YouTube, Vimeo ou outra plataforma). Deve ser um endereço completo `http://` ou `https://`. |
| `[LETRISTA]` | Não | Autor da letra. Texto livre, até 200 caracteres. |
| `[COMPOSITOR]` | Não | Autor da música (melodia). Texto livre, até 200 caracteres. |
| `[EDITORA]` | Não | Editora, gravadora ou detentora dos direitos. Texto livre, até 200 caracteres. |
| `[DIREITOS]` | Não | Situação dos direitos autorais: `dominio-publico`, `protegida` ou `nao-verificado`. Para obras protegidas, o último ano de proteção é opcional: `protegida até 2086`. |
| `[LICENCA_APP]` | Não | Autorização para usar a música no app: `pendente`, `autorizada`, `nao-necessaria` (domínio público) ou `negada`. |

O link de `[VIDEO]` aparece como botão "Assistir vídeo" no hinário (lista e detalhe da música) e na montagem da celebração. Ele não aparece no modo performance. Um link inválido faz a importação ou a edição falhar com uma mensagem de erro. Arquivos sem `[VIDEO]` continuam válidos.

Categorias também podem ser informadas em mais de uma linha `[CATEGORIA]`. O app as normaliza para minúsculas.

Uma música pode ser classificada para mais de um momento. Os identificadores válidos são: `entrada`, `atoPenitencial`, `gloria`, `salmoResponsorial`, `aclamacaoEvangelho`, `oferta`, `santo`, `cordeiroDeDeus`, `comunhao`, `posComunhao`, `consagracao`, `final_` e `outros`. O hinário e o seletor de músicas permitem filtrar por esses momentos. Coordenadores também podem alterar a classificação no hinário.

No montador, músicas sem classificação continuam disponíveis para qualquer momento. Ao selecionar a mesma música em mais de um momento, o app avisa, mas permite continuar.

### Autoria e direitos

Os campos `[LETRISTA]`, `[COMPOSITOR]`, `[EDITORA]`, `[DIREITOS]` e `[LICENCA_APP]` identificam os autores e a situação de direitos da música. São informativos: o app não bloqueia nenhuma música por causa deles. A política de uso está em [direitos-autorais.md](direitos-autorais.md).

- Os valores de `[DIREITOS]` e `[LICENCA_APP]` aceitam maiúsculas, acentos, espaços ou hífens: `Domínio Público`, `dominio_publico` e `dominio-publico` são o mesmo valor. `[DIREITOS]` também aceita `Protegida (até 2086)`. Um valor fora da lista faz a importação ou a edição falhar com uma mensagem de erro.
- Os nomes dos campos aceitam acento (`[LICENÇA_APP]`).
- Músicas sem esses campos continuam válidas e aparecem como "não informados".
- As informações aparecem só no **hinário**: no detalhe da música (quadro "Autoria e direitos") e no filtro por situação de licença. Não aparecem nas celebrações nem no modo performance.
- Para preencher, edite a música no app e acrescente as linhas no cabeçalho.

O parser não usa outros campos de cabeçalho; linhas `[CAMPO]: valor` desconhecidas são ignoradas.

## Seções aceitas

Cada seção começa em uma linha própria, entre colchetes:

- `[ESTROFE]` ou `[ESTROFE 1]`, `[ESTROFE 2]` etc.
- `[VERSO]` ou `[VERSO 1]`, `[VERSO 2]` etc.
- `[REFRAO]` ou `[REFRÃO]`
- `[PONTE]`
- `[PRE-REFRAO]` ou `[PRÉ-REFRÃO]`
- `[INTRO]`
- `[OUTRO]`
- `[CODA]`

As seções podem se repetir e aparecem na mesma ordem do arquivo. O texto fora de uma seção é ignorado, exceto os campos do cabeçalho.

## Cifras e letra

- Coloque a linha de cifras imediatamente acima da linha de letra correspondente.
- Use acordes com a fundamental em maiúscula (`A` a `G`), como `D`, `F#m`, `Bb`, `A4`, `G7` ou `C/E`.
- Separe acordes com espaços. Espaços no início da linha de cifra são preservados.
- Uma linha de letra pode não ter cifra: basta escrever a letra sem uma linha de acorde acima.
- Linhas em branco são permitidas entre estrofes ou blocos; não coloque uma linha em branco entre a cifra e a letra que ela acompanha.

Exemplo:

```text
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

## Cuidados antes de importar

1. Salve como texto simples em UTF-8 e use a extensão `.txt`.
2. Confira se `[TITULO]` tem um valor não vazio.
3. Escreva cada marcador de seção em uma linha separada, como `[ESTROFE]`.
4. Mantenha cada linha de cifra imediatamente antes da respectiva linha de letra.
5. Evite anotações ou cifras com parênteses; a detecção atual aceita uma notação simples de acordes.
