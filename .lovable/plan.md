
# Plano: Corrigir HTTP 404 - Conversão de Parâmetros para Inteiros

## Diagnóstico

O problema é a falta de conversão explícita dos parâmetros `nr_requisicao` e `filial` para inteiros no Firebird.

### Print do Servidor
```
GET /api/requisicao/6806?filial=392 HTTP/1.1" 404
GET /api/requisicao/6802?filial=392 HTTP/1.1" 404
GET /api/requisicao/6801?filial=392 HTTP/1.1" 404
```

### Causa Raiz

Conforme documentado no memory `backend/sql-parameter-casting-requirement`:
> Para evitar erros de conversão no Firebird (SQLCODE -413), todos os parâmetros numéricos enviados ao cursor do banco de dados (especialmente NRRQU, SERIER e CDFIL) devem ser explicitamente convertidos para inteiros utilizando `int()` no backend Python.

O problema está nas linhas **2466** e **2501** do `servidor.py`:

```python
# Linha 2466 - PROBLEMA
cursor.execute(query, (nr_requisicao, filial))  # ← Passando strings!

# Linha 2501 - PROBLEMA
cursor.execute(query, (nr_requisicao, filial))  # ← Passando strings!
```

---

## Solução

Converter os parâmetros para inteiros antes de passar para o cursor.

### Arquivo: `servidor.py`

| Linha | Código Atual | Código Corrigido |
|-------|--------------|------------------|
| 2466 | `""", (nr_requisicao, filial))` | `""", (int(nr_requisicao), int(filial)))` |
| 2501 | `""", (nr_requisicao, filial))` | `""", (int(nr_requisicao), int(filial)))` |

---

## Alterações Detalhadas

### Linha 2466 - Query principal da requisição
**Antes:**
```python
cursor.execute("""
    SELECT R.NRRQU, R.CDFIL, R.NOMEPA, R.PFCRM, R.NRCRM, R.UFCRM,
           R.DTCAD, R.DTVAL, R.NRREG, R.POSOL, R.TPUSO, R.OBSERFIC,
           R.VOLUME, R.UNIVOL, M.NOMEMED, R.TPFORMAFARMA
    FROM FC12100 R
    LEFT JOIN FC04000 M ON R.PFCRM = M.PFCRM AND R.NRCRM = M.NRCRM AND R.UFCRM = M.UFCRM
    WHERE R.NRRQU = ? AND R.CDFIL = ?
""", (nr_requisicao, filial))
```

**Depois:**
```python
cursor.execute("""
    SELECT R.NRRQU, R.CDFIL, R.NOMEPA, R.PFCRM, R.NRCRM, R.UFCRM,
           R.DTCAD, R.DTVAL, R.NRREG, R.POSOL, R.TPUSO, R.OBSERFIC,
           R.VOLUME, R.UNIVOL, M.NOMEMED, R.TPFORMAFARMA
    FROM FC12100 R
    LEFT JOIN FC04000 M ON R.PFCRM = M.PFCRM AND R.NRCRM = M.NRCRM AND R.UFCRM = M.UFCRM
    WHERE R.NRRQU = ? AND R.CDFIL = ?
""", (int(nr_requisicao), int(filial)))
```

### Linha 2501 - Query dos itens da requisição
**Antes:**
```python
cursor.execute("""
    SELECT I.SERIER, I.DESCR, I.QUANT, I.UNIDA, I.NRLOT, I.CDPRO, I.CDPRIN, I.ITEMID
    FROM FC12110 I
    WHERE I.NRRQU = ? AND I.CDFIL = ? AND I.TPCMP IN ('C', 'S')
    ORDER BY I.SERIER
""", (nr_requisicao, filial))
```

**Depois:**
```python
cursor.execute("""
    SELECT I.SERIER, I.DESCR, I.QUANT, I.UNIDA, I.NRLOT, I.CDPRO, I.CDPRIN, I.ITEMID
    FROM FC12110 I
    WHERE I.NRRQU = ? AND I.CDFIL = ? AND I.TPCMP IN ('C', 'S')
    ORDER BY I.SERIER
""", (int(nr_requisicao), int(filial)))
```

---

## Por Que Isso Resolve

O driver `fdb` do Firebird pode ter comportamento inconsistente quando recebe tipos Python `str` para colunas que são `INTEGER` no banco:

- **String "6806"** → Pode falhar ou retornar vazio
- **Inteiro 6806** → Sempre funciona corretamente

A conversão explícita com `int()` garante que o tipo correto seja enviado para o banco.

---

## Teste Após Correção

1. Reiniciar o servidor Python
2. Buscar a requisição 6806 com filial 392
3. Deve retornar os dados corretamente (HTTP 200)

---

## Impacto

- **Risco**: Muito baixo - apenas adiciona conversão de tipo
- **Funcionalidade**: Resolve o 404 para todas as requisições
- **Compatibilidade**: Nenhuma quebra de código
