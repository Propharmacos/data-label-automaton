
# Plano: Corrigir Ordenação usando SERIER

## Problema Identificado

A query atual usa `ORDER BY I.ITEMID`, mas todos os itens têm `ITEMID = 1`. O campo correto é **`SERIER`**, que contém a sequência das barras (0, 1, 2, 3...).

## Solução

Alterar a query principal no `servidor.py` para:
1. Ordenar por `SERIER` em vez de `ITEMID`
2. Usar o valor de `SERIER` como `nrItem`

## Alterações no servidor.py

### 1. Query Principal (linha ~1135)

```python
# ANTES:
cursor.execute("""
    SELECT I.ITEMID, I.DESCR, I.QUANT, I.UNIDA, I.NRLOT, I.CDPRO, I.CDPRIN
    FROM FC12110 I
    WHERE I.NRRQU = ? AND I.CDFIL = ? AND I.TPCMP IN ('C', 'S')
    ORDER BY I.ITEMID
""", (nr_requisicao, filial))

# DEPOIS:
cursor.execute("""
    SELECT I.SERIER, I.DESCR, I.QUANT, I.UNIDA, I.NRLOT, I.CDPRO, I.CDPRIN
    FROM FC12110 I
    WHERE I.NRRQU = ? AND I.CDFIL = ? AND I.TPCMP IN ('C', 'S')
    ORDER BY I.SERIER
""", (nr_requisicao, filial))
```

### 2. Atribuição do nrItem (linha ~1462)

```python
# ANTES (usa índice do loop):
"nrItem": str(idx),

# DEPOIS (usa SERIER do banco):
"nrItem": str(serier),  # Valor direto do campo SERIER
```

## Resultado Esperado

| Produto | SERIER | nrItem | Exibição |
|---------|--------|--------|----------|
| Alfa-Lipóico | 0 | "0" | REQ:86482-0 |
| Coenzima Q10 | 1 | "1" | REQ:86482-1 |
| Curcumina | 2 | "2" | REQ:86482-2 |
| Resveratrol | 3 | "3" | REQ:86482-3 |

## Seção Técnica

### Fluxo Corrigido

```text
FC12110 (Banco)          servidor.py              Frontend
┌──────────────┐         ┌──────────────┐         ┌────────────┐
│ SERIER = 0   │───────▶ │ nrItem = "0" │───────▶ │ REQ:X-0    │
│ SERIER = 1   │         │ nrItem = "1" │         │ REQ:X-1    │
│ SERIER = 2   │         │ nrItem = "2" │         │ REQ:X-2    │
└──────────────┘         └──────────────┘         └────────────┘
       ↑                        ↑
  ORDER BY SERIER         nrItem = SERIER (direto do banco)
```

### Arquivos a Modificar

| Arquivo | Alteração |
|---------|-----------|
| servidor.py | Trocar ITEMID por SERIER na query (SELECT e ORDER BY) |
| servidor.py | Usar valor de SERIER como nrItem |

## Próximos Passos

1. Aplicar alterações no servidor.py
2. Reiniciar o Flask
3. Testar requisição 86482
4. Verificar se barras aparecem na ordem correta (0, 1, 2, 3...)
