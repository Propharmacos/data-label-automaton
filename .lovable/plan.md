# ✅ CONCLUÍDO: Corrigir Prioridade do Lote para NRLOT

## Correções Aplicadas

### 1. Linha 280-281 - `resolve_lote_componente()`
```python
# ANTES: lote = str(ctlot or nrlot or "").strip()
# DEPOIS: lote = str(nrlot or ctlot or "").strip()
```

### 2. Linha 298 - Fallback de lote
```python
# ANTES: lote = str(row[0] or row[1] or "").strip()
# DEPOIS: lote = str(row[1] or row[0] or "").strip()
```

### 3. Linha 410 - `tenta_fc12111_componentes()` 
Já estava correto: `lote_req = str(nrlot or ctlot or "").strip()`

### 4. Linhas 2370, 2390 - `buscar_lote_componente()`
Já estavam corretas: SELECT retorna NRLOT em row[0]

## Resultado
Rótulos agora exibem números de lote comerciais (10416, 10160...) em vez de IDs internos.

