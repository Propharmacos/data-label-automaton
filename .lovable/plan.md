

# Remover texto de posologia dos rótulos

## O que muda
O campo `posologia` (que traz textos como "USO SOMENTE TRATAMENTO ALOPECIA") será ignorado na geração do texto dos rótulos. A linha de uso passará a mostrar **apenas a aplicação** (`AP:ID/SC`) quando houver.

## Alteração técnica

**Arquivo**: `src/components/LabelTextEditor.tsx`

Em cada gerador de layout, onde hoje faz:
```typescript
const posologia = rotulo.posologia?.toUpperCase() || "";
const usoText = /^\d+$/.test(posologia) ? "" : posologia;
```
Passará a ser:
```typescript
const usoText = ""; // posologia removida do rótulo
```

Isso será aplicado em todos os layouts: **AMP10**, **AMP_CX**, **TIRZ** e **A_PAC** (genérico).

A aplicação (`AP:XX` / `APLICACAO:XX`) continua aparecendo normalmente, pois vem do campo `rotulo.aplicacao`, não da posologia.

