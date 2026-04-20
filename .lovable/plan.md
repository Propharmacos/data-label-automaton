

# Diagnóstico — DUTASTERIDA duplicada no AMP_CX (Req 10436-4)

## Causa raiz
No editor AMP_CX (`LabelTextEditor.tsx`, linhas 606–618), quando o item tem `composicao` preenchida o código:
1. Imprime a `composicao` linha a linha (linha 611)
2. **Em seguida**, imprime também a `formula` (linha 614)

Isso foi pensado para **mesclas** (ex.: "BAICALINA 5MG, BIOTINA 10MG" + nome reduzido do produto). Mas para **produto único**, o backend devolve os dois campos com o mesmo conteúdo:
- `composicao` = `DUTASTERIDA 0,1%` (extraído de FC03300/CDICP 00001-00002)
- `formula` = `DUTASTERIDA 0,1%` (extraído de FC03000.DESCRPRD)

Resultado: a mesma linha sai duas vezes.

O **mesmo bug existe no AMP10** (linhas 367–370). O AMP_CX salvo no Supabase para `10436-4-816` está correto (uma linha só) — a duplicação aparece no preview ao vivo quando o editor regenera o texto sem usar o salvo.

## Correção proposta

Aplicar **deduplicação simples** nas duas funções (`generateTextAmpCaixa` e `generateTextAmp10`):

- Comparar `composicao` e `formula` normalizados (uppercase, sem acento, sem espaços extras, sem `%` nem vírgula extra).
- Se forem iguais → imprimir só **uma vez** (composição, omite formula).
- Se a `composicao` já contiver a `formula` como substring → omite formula.
- Se forem diferentes → manter o comportamento atual (mescla real continua imprimindo as duas).

Pseudocódigo:
```ts
const norm = (s: string) => s.toUpperCase().replace(/\s+/g, ' ').trim();
const compNorm = norm(rotulo.composicao);
const formNorm = norm(rotulo.formula);
const formulaJaEstaNaComposicao = compNorm === formNorm || compNorm.includes(formNorm);
if (formulaRaw && !formulaJaEstaNaComposicao) {
  lines.push(indentLine(formulaRaw));
}
```

## Arquivos afetados
- `src/components/LabelTextEditor.tsx` — único arquivo, dois pontos:
  - `generateTextAmp10` (linhas 363–375)
  - `generateTextAmpCaixa` (linhas 606–619)

## O que NÃO muda
- Backend (`servidor.py`) — continua devolvendo os dois campos como hoje (aditividade preservada).
- Layouts A_PAC_PEQ, A_PAC_GRAN, TIRZ — não usam essa lógica de "composicao + formula", não regridem.
- Mesclas reais (ex: req 10436-7 "PROHAIRIN 3%, CAPIXYL 2%, ...") — continuam mostrando todos os ativos + nome reduzido se forem distintos.
- Textos já salvos no Supabase — intocados.

## Validação
1. Req `10436-4` (DUTASTERIDA 0,1% — produto único) → deve sair **uma linha** só.
2. Req `10436-7` (mescla PROHAIRIN/CAPIXYL/D-PANTENOL) → continua mostrando todos os ativos.
3. Req `10436-8` (mescla D PANTENOL + BIOTINA + IGF + ...) → continua igual.
4. Mesma checagem no layout AMP10 com um produto único.

