

## Diagnóstico

O A.PAC.PEQ usa `colunasMax: 28`, mas o Fórmula Certa mostra que a etiqueta suporta até **41 colunas** (print 1: "Col: 41/27"). Com apenas 28 colunas, o espaço para o nome do médico fica limitado a **7 caracteres** (28 - 5 do prefixo "DR(A)" - 15 do conselho - 1 espaço), causando a truncagem "DR(A)NATHALIA VE" no print 2.

Com 41 colunas, o nome do médico terá **20 caracteres** disponíveis — suficiente para "NATHALIA VERISSIMO" (18 chars) sem abreviação.

## Plano

### 1. `src/config/layouts.ts` — Aumentar colunasMax de 28 para 41

### 2. `src/components/LabelTextEditor.tsx` — Ajustar fallback de detecção

Na linha 586, o fallback que detecta A_PAC_PEQ por `colunasMax === 28` precisa incluir `41`:
```
if ((layoutConfig.colunasMax === 28 || layoutConfig.colunasMax === 38 || layoutConfig.colunasMax === 41) ...
```

### 3. `src/components/LabelTextEditor.tsx` — Ajustar default na função

Linha 160: trocar o fallback `|| 28` para `|| 41`.

### Nenhuma alteração no agente ou no layout
O agente já usa coordenadas em dots (X=12, X=116, X=129) que não dependem do colunasMax do frontend. O layout (estrutura de linhas, fontes, coordenadas Y) permanece intacto.

