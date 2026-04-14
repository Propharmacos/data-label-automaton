

# Restaurar `tipoUso` (ex: "USO EM CONSULTORIO") nos rótulos

## Problema
Ao remover a `posologia`, o `tipoUso` também foi perdido porque ambos compartilhavam a mesma variável `usoText`. O campo `tipoUso` (ex: "USO EM CONSULTORIO") deve continuar aparecendo.

## Alteração

**Arquivo**: `src/components/LabelTextEditor.tsx`

Nas 2 linhas onde `usoText` foi zerado (AMP_CX linha 379 e AMP10 linha 618), restaurar usando `rotulo.tipoUso` em vez de `rotulo.posologia`:

```typescript
// Antes (errado — removeu tudo):
const usoText = "";

// Depois (correto — usa tipoUso, ignora posologia):
const usoText = rotulo.tipoUso?.toUpperCase() || "";
```

O layout TIRZ (linha 702) e o genérico A_PAC (linha 860) já estão corretos — ambos usam `rotulo.tipoUso`.

Resultado: "USO EM CONSULTORIO" volta a aparecer; "USO SOMENTE TRATAMENTO ALOPECIA" (posologia) continua removido.

