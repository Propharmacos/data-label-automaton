

# Corrigir TIRZ — copiar formato físico do A.PAC.PEQ

## Problema
O layout TIRZ está configurado como etiqueta larga (109x25mm, 73 colunas, PPLA `f250`/`PB`) mas imprime na impressora pequena da Edi (mesma do A.PAC.PEQ — 35x25mm). O resultado é texto cortado, deslocado para a direita e com fonte errada.

## Solução
Copiar todas as configurações físicas do A.PAC.PEQ para o TIRZ — mesma dimensão de etiqueta, mesmas colunas, mesmo PPLA header/config, mesma fonte — e adaptar apenas o gerador de texto para incluir as informações extras (produto, posologia, pH, lote, uso, contém, registro).

## Alterações técnicas

### 1. `src/config/layouts.ts` — Layout TIRZ
- `dimensoes`: de `{ 109, 25 }` para `{ 35, 25 }` (igual A_PAC_PEQ)
- `colunasMax`: de `73` para `41` (igual A_PAC_PEQ)

### 2. `src/config/pplaTemplates.ts` — Template PPLA TIRZ
- `header`: de `[f250, L, e]` para `[f289, L, e]` (igual A_PAC_PEQ)
- `config`: de `[PB, D11, H14]` para `[PA, D11, H14]` (igual A_PAC_PEQ)
- `fields`: manter os mesmos campos mas atualizar prefixos para coordenadas compatíveis com etiqueta pequena (baseados nos prefixos do A_PAC_PEQ com Y ajustado para mais linhas)

### 3. `src/types/printerDefinition.ts` — Definição TIRZ
- `medidas.largura`: de `4.29` para `1.39` (igual A_PAC_PEQ)
- `fonte`: de `2` para `1` (igual A_PAC_PEQ)

### 4. `src/components/LabelTextEditor.tsx` — Gerador TIRZ
Reescrever `generateTextTirz` para usar 41 colunas (como A_PAC_PEQ) com as seguintes linhas compactadas:

```text
PACIENTE         REQ:XXXXXX-X
DR(A)MEDICO      CRM.SP-XXXXX
PRODUTO + POSOLOGIA (wrap 41 cols)
PH:X,X L:XXX/XX F:XX/XX V:XX/XX
USO EM CONSULTORIO  AP:XX
CONTEM:XXX  REG:XXXXX
```

Usa `padLine` e `abbreviateNameStrict` do A_PAC_PEQ para as 2 primeiras linhas, depois linhas adicionais com wrap a 41 colunas.

Também ajustar `getStoredFontSize` para TIRZ retornar `5` (igual A_PAC_PEQ).

### 5. Forçar roteamento do agente para TIRZ
Adicionar `TIRZ` à lista de layouts forçados para modo agente (junto com A_PAC_PEQ e A_PAC_GRAN), já que imprime na mesma impressora pequena.

## Resultado esperado
O rótulo TIRZ sairá no mesmo tamanho físico e fonte do A_PAC_PEQ, mas com todas as informações do produto compactadas em ~6-8 linhas de 41 colunas.

