

## Plano: Resolver dimensões pelo layout_tipo em vez do nome da impressora

### O problema (1 linha)
`get_printer_dims('CAIXA GRANDE')` não encontra "AMP10" no nome → retorna PEQUEN (38 cols) → texto truncado.

### A correção

**`agente_impressao.py`** — 2 pontos:

1. **Adicionar mapeamento layout→config** (após linha 100):
```python
LAYOUT_TO_CONFIG = {
    'AMP10': 'AMP10',
    'AMP_CX': 'AMP_CX',
    'A_PAC_PEQ': 'PEQUEN',
    'A_PAC_GRAN': 'A_PAC_GRAN',
    'TIRZ': 'PEQUEN',
}
```

2. **Linha 1039** — trocar resolução:
```python
# ANTES:
dims = get_printer_dims(impressora)

# DEPOIS:
config_key = LAYOUT_TO_CONFIG.get(layout_tipo, 'PEQUEN')
dims = PRINTER_CONFIGS.get(config_key, PRINTER_CONFIGS['PEQUEN'])
```

3. **Linha 1191** — mesma correção no `/diagnostico-ppla`.

### Arquivo alterado
- `agente_impressao.py` (3 edições pequenas)

