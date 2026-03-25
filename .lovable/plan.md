

## Plano: Corrigir nomes das impressoras no mapeamento padrão

### Mapeamento correto confirmado

```text
Layout       → Impressora      → Estação
──────────────────────────────────────────
A_PAC_PEQ    → PEQUENO          → PC da Edi
A_PAC_GRAN   → AMP GRANDE       → PC da Edi
AMP_CX       → AMP CAIXA        → PC do Daniel
AMP10        → CAIXA GRANDE     → PC do Daniel
TIRZ         → PEQUENO          → PC da Edi (!)
```

**Mudança importante**: TIRZ passa do PC do Daniel para o PC da Edi.

### Alterações

**`src/config/api.ts`**:
- `DEFAULT_LAYOUT_PRINTER_MAP`: atualizar `A_PAC_GRAN` → `'AMP GRANDE'`, `AMP_CX` → `'AMP CAIXA'`, `AMP10` → `'CAIXA GRANDE'`, `TIRZ` → `'PEQUENO'`
- `DEFAULT_LAYOUT_STATION_MAP`: mudar `TIRZ` de `'daniel'` para `'edi'`

