
# Plano: Exibir Observações Apenas Quando Existir Conteúdo

## Regra de Negócio

| Tipo | observacoes no banco | Exibição |
|------|---------------------|----------|
| Produto Único | Vazio | ❌ Oculta |
| Mescla | "procaina mais L-carnitina" | ✅ Mostra |

A presença de conteúdo em `observacoes` indica que é uma mescla.

## Alteração em `src/components/LabelCard.tsx`

### Modificar case 'observacoes' (linha 289-290)

```typescript
// ANTES:
case 'observacoes':
  return observacoes || "";

// DEPOIS:
case 'observacoes':
  // Só exibe se tiver conteúdo (indica mescla)
  // Produto único não tem observação
  return observacoes ? observacoes.toUpperCase() : "";
```

## Resultado Esperado

**Vitamina D (Produto Único):**
- Exibe: `VIT D 100.000UI/ML`
- Exibe: `APLICAÇÃO: IM`
- Observações: ❌ (campo vazio no banco)

**Procaína + L-Carnitina (Mescla):**
- Exibe: Composição dos ativos
- Observações: ✅ `PROCAINA MAIS L-CARNITINA`

## Seção Técnica

### Arquivo a Modificar

| Arquivo | Alteração |
|---------|-----------|
| `src/components/LabelCard.tsx` | Ajustar case `observacoes` para exibir apenas se houver conteúdo |

### Nota

A lógica atual já retorna `observacoes || ""`, mas o campo pode estar visível no layout mesmo vazio. A alteração garante que só aparece quando há conteúdo real.
