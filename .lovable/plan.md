
# Plano: Corrigir Numeração das Barras (ITEMID → Barra 0, 1, 2)

## Problema Atual

O FórmulaCerta usa numeração baseada em **zero** para as abas/barras:
- **Barra 0** = Alfa-Lipóico (Código 90530)
- **Barra 1** = Coenzima Q10 (Código 92421)
- **Barra 2** = Curcumina (Código 92457)

Porém, o banco de dados Firebird armazena `ITEMID` começando em **1**:
- ITEMID 1 = Alfa-Lipóico
- ITEMID 2 = Coenzima Q10
- ITEMID 3 = Curcumina

O sistema está exibindo `REQ:86482-1, REQ:86482-2, REQ:86482-3` quando deveria exibir `REQ:86482-0, REQ:86482-1, REQ:86482-2`.

---

## Solução

Alterar o **backend (servidor.py)** para subtrair 1 do `ITEMID` ao gerar o `nrItem`, convertendo para numeração base-zero.

### Arquivo: `servidor.py` (linha ~1462)

```python
# ANTES (errado):
"nrItem": str(item_id),

# DEPOIS (correto - converte para base zero):
"nrItem": str(item_id - 1),  # Converte ITEMID (1,2,3) para barra (0,1,2)
```

---

## Resultado Esperado

| Produto | ITEMID (banco) | nrItem (API) | Exibição |
|---------|----------------|--------------|----------|
| Alfa-Lipóico | 1 | 0 | REQ:86482-0 |
| Coenzima Q10 | 2 | 1 | REQ:86482-1 |
| Curcumina | 3 | 2 | REQ:86482-2 |

---

## Seção Técnica

### Fluxo de Dados Corrigido

```text
FC12110 (Banco)          servidor.py              Frontend
┌──────────────┐         ┌──────────────┐         ┌────────────┐
│ ITEMID = 1   │───────▶ │ nrItem = "0" │───────▶ │ REQ:X-0    │
│ ITEMID = 2   │         │ nrItem = "1" │         │ REQ:X-1    │
│ ITEMID = 3   │         │ nrItem = "2" │         │ REQ:X-2    │
└──────────────┘         └──────────────┘         └────────────┘
       ↑                        ↑
  ORDER BY ITEMID         item_id - 1 (converte para base zero)
```

### Alteração Específica

Na função que processa itens (linha ~1462 do servidor.py):

```python
rotulo = {
    **dados_base,
    "nrItem": str(item_id - 1),  # CORRIGIDO: Converte para base zero (barra 0, 1, 2)
    "formula": nome_formula,
    "volume": str(item[2]) if item[2] else dados_base["volume"],
    # ... resto igual
}
```

### Verificação no Fallback

Também ajustar a linha ~1479 (caso de requisição sem itens):

```python
# ANTES:
data = [{**dados_base, "nrItem": "1", ...}]

# DEPOIS:
data = [{**dados_base, "nrItem": "0", ...}]
```

---

## Próximos Passos

1. Aplicar alteração no `servidor.py`
2. Reiniciar o servidor Flask
3. Testar a requisição 86482 novamente
4. Verificar se os rótulos exibem REQ:86482-0, REQ:86482-1, REQ:86482-2 na ordem correta
