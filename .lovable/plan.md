

## Melhorar Comparador PPLA: Alinhamento por Tipo

### Problema Atual
O comparador atual compara linha 1 com linha 1, linha 2 com linha 2, etc. Como o sistema e o Formula Certa geram comandos em ordens diferentes, quase tudo aparece como "diferente" mesmo quando os comandos sao equivalentes -- so estao em posicoes diferentes.

### Solucao
Substituir a comparacao posicional por uma comparacao **por grupos de tipo**, onde headers sao comparados com headers, configs com configs, e linhas de texto sao pareadas pelo conteudo mais similar.

### Como vai funcionar

**1. Agrupar comandos por tipo**
Apos o parse, separar cada lado em 4 grupos:
- `header` (STX L, STX f, etc.)
- `config` (PA, D11, H14, S4, q, C, c)
- `text` (linhas com fonte/coordenadas/conteudo)
- `end` (Q0001, E)

**2. Comparar cada grupo separadamente**

- **Headers**: Comparar por comando base (ex: ambos tem `STX L`? identico)
- **Config**: Comparar por prefixo (ex: `D11` vs `D11` = identico, `H08` vs `H14` = diferente)
- **Texto**: Parear linhas de texto pelo conteudo mais similar (matching por conteudo textual, depois comparar coordenadas/fonte)
- **End**: Comparar diretamente

**3. Matching inteligente de linhas de texto**
Para linhas de texto, usar um algoritmo que:
- Primeiro tenta match exato pelo conteudo (`content`)
- Depois tenta match parcial (conteudo parecido)
- Linhas sem par ficam como "only-left" ou "only-right"

**4. Exibicao agrupada no modal**
A tabela lado a lado vai mostrar separadores visuais entre cada grupo:
```text
[HEADERS]
  STX L          | STX L         -> verde
[CONFIGURACAO]
  D11            | D11           -> verde
  H08            | H14           -> vermelho (diferenca real!)
  PA             | PA            -> verde
[TEXTO]
  ...medicamento | ...medicamento -> amarelo (coord diferente)
[FIM]
  Q0001          | Q0001         -> verde
  E              | E             -> verde
```

### Detalhes Tecnicos

**Arquivo modificado:** `src/components/PPLAComparer.tsx`

**Mudancas especificas:**

1. **Nova funcao `groupByType(lines: PPLALine[])`** -- Separa o array parseado em `{ headers, configs, texts, ends, unknowns }`.

2. **Nova funcao `matchTextLines(left: PPLALine[], right: PPLALine[])`** -- Pareia linhas de texto pelo conteudo mais similar usando comparacao de string. Para cada linha da esquerda, encontra a melhor correspondencia na direita (pelo `content`). Linhas sem par ficam como sobras.

3. **Nova funcao `compareConfigs(left: PPLALine[], right: PPLALine[])`** -- Agrupa configs pelo prefixo (D, H, S, PA, q, C, c) e compara valores.

4. **Substituir `buildDiff()`** por **`buildGroupedDiff()`** -- Retorna um array de `DiffResult` com um campo adicional `section` (string) para indicar o grupo. Processa cada grupo separadamente e concatena os resultados com separadores.

5. **Atualizar a renderizacao** -- Adicionar linhas separadoras visuais entre grupos (ex: uma barra cinza com o nome da secao: "HEADERS", "CONFIGURACAO", "TEXTO", "FIM").

6. **Atualizar `summarizeDiffs()`** -- Manter a mesma logica de resumo, mas agora os dados estao corretamente pareados, entao os numeros refletem diferencas reais.

