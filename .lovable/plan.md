
# Plano: Investigar e Corrigir Ordem das Barras (Requisição)

## Problema Identificado

A ordem dos itens retornados pela API não corresponde à ordem das "barras" no FórmulaCerta:

| Barra no FórmulaCerta | Produto esperado | nrItem atual na API |
|----------------------|------------------|---------------------|
| Barra 0 | Alfa-Lipóico (90530) | 0 ✓ |
| Barra 1 | Coenzima Q10 (92421) | 7 ✗ |
| Barra 2 | Curcumina (92457) | 6 ✗ |

A query atual usa `ORDER BY I.ITEMID`, mas o ITEMID no banco não reflete a ordem visual das barras.

---

## Solução Proposta

### Etapa 1: Criar endpoint de debug para descobrir campos de ordenação

Adicionar um endpoint que mostra **TODOS os campos** da tabela FC12110 para uma requisição específica:

```python
@app.route('/api/debug/fc12110-completo/<nr_requisicao>', methods=['GET'])
def debug_fc12110_completo(nr_requisicao):
    filial = request.args.get('filial', '1')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT * FROM FC12110 
        WHERE NRRQU = ? AND CDFIL = ? AND TPCMP IN ('C', 'S')
        ORDER BY ITEMID
    """, (nr_requisicao, filial))
    
    colunas = [desc[0].strip() for desc in cursor.description]
    itens = []
    for row in cursor.fetchall():
        item = {}
        for i, col in enumerate(colunas):
            item[col] = str(row[i]) if row[i] is not None else None
        itens.append(item)
    
    conn.close()
    return jsonify({"colunas": colunas, "itens": itens})
```

### Etapa 2: Testar e identificar campo de ordenação

Após criar o endpoint, você poderá acessar:
```
GET /api/debug/fc12110-completo/86482?filial=279
```

Isso mostrará todos os campos disponíveis. Campos potenciais para ordenação:
- `ORDEM` ou `SEQBARRA` - campo específico de sequência
- `CDPRO` - código do produto (ordem de cadastro)
- `DTCAD` ou timestamp - data de inclusão

### Etapa 3: Alterar query principal

Uma vez identificado o campo correto, alterar a query na linha ~1139:

```python
# ANTES:
ORDER BY I.ITEMID

# DEPOIS (exemplo se o campo for ORDEM):
ORDER BY I.ORDEM

# OU (se for por código do produto):
ORDER BY I.CDPRO
```

---

## Seção Técnica

### Arquivos a Modificar

| Arquivo | Alteração |
|---------|-----------|
| `servidor.py` | 1. Adicionar endpoint debug FC12110 completo |
| `servidor.py` | 2. Alterar ORDER BY na query principal (linha ~1139) |

### Query Principal Atual (linha 1135-1140)

```python
cursor.execute("""
    SELECT I.ITEMID, I.DESCR, I.QUANT, I.UNIDA, I.NRLOT, I.CDPRO, I.CDPRIN
    FROM FC12110 I
    WHERE I.NRRQU = ? AND I.CDFIL = ? AND I.TPCMP IN ('C', 'S')
    ORDER BY I.ITEMID  -- ← Campo a ser alterado
""", (nr_requisicao, filial))
```

### Fluxo de Investigação

```text
1. Criar endpoint debug
2. Acessar: /api/debug/fc12110-completo/86482?filial=279
3. Analisar todos os campos retornados
4. Identificar campo que corresponde à ordem das barras
5. Alterar ORDER BY na query principal
6. Testar novamente a requisição 86482
```

---

## Próximos Passos

1. **Aprovar este plano** para criar o endpoint de debug
2. **Você acessa o endpoint** e me envia a resposta JSON
3. **Identificamos juntos** o campo correto de ordenação
4. **Aplicamos a correção** no ORDER BY
