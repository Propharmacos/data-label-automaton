
# Plano: Corrigir Extração de Aplicação e Composição da FC03300

## Diagnóstico

Após análise detalhada do código atual, identifiquei que:

1. **A query FC03300 está correta** - usa `cdpro_str` como string
2. **O problema pode ser o tipo de dado** - o campo CDPRO na FC03300 pode ser numérico (INTEGER), não texto

No Firebird, comparar `INTEGER = 'string'` pode falhar silenciosamente, retornando zero resultados.

---

## Solução

### Arquivo: `servidor.py`

#### Alteração 1: Converter CDPRO para inteiro na query FC03300 (linhas 3008-3014)

**Antes:**
```python
for codigo_aplicacao in codigos_buscar:
    cursor.execute("""
        SELECT FRFAR, CDICP, OBSER 
        FROM FC03300 
        WHERE CDPRO = ?
        ORDER BY FRFAR, CDICP
    """, (codigo_aplicacao,))
```

**Depois:**
```python
for codigo_aplicacao in codigos_buscar:
    # Tenta como inteiro (caso o campo seja numérico no banco)
    try:
        codigo_int = int(codigo_aplicacao)
    except:
        codigo_int = 0
    
    cursor.execute("""
        SELECT FRFAR, CDICP, OBSER 
        FROM FC03300 
        WHERE CDPRO = ? OR CDPRO = ?
        ORDER BY FRFAR, CDICP
    """, (codigo_aplicacao, codigo_int))
```

#### Alteração 2: Melhorar debug logging (após linha 3016)

Adicionar log do tipo de dado e valor exato:

```python
print(f"\n  DEBUG FC03300 - Buscando CDPRO={codigo_aplicacao} (str) ou {codigo_int} (int)")
obs_encontradas = cursor.fetchall()
print(f"    -> Encontrou {len(obs_encontradas)} registros")
```

#### Alteração 3: Adicionar fallback de busca CAST (se ainda não funcionar)

Como opção robusta, usar CAST explícito:

```python
cursor.execute("""
    SELECT FRFAR, CDICP, OBSER 
    FROM FC03300 
    WHERE CAST(CDPRO AS VARCHAR(20)) = ?
    ORDER BY FRFAR, CDICP
""", (codigo_aplicacao,))
```

---

## Resumo das Mudanças

| Linha | Alteração |
|-------|-----------|
| 3008-3014 | Passar CDPRO como inteiro E string para a query |
| 3016-3023 | Melhorar logs de debug |
| (opcional) | Usar CAST se necessário |

---

## Resultado Esperado

Após as correções:

1. O console Flask mostrará:
   ```
   DEBUG FC03300 - Buscando CDPRO=92602 (str) ou 92602 (int)
     -> Encontrou 4 registros
     - FRFAR=14, CDICP=00001: 'APLICAÇÃO: SC...'
     -> APLICAÇÃO extraída: 'SC'
   ```

2. O rótulo exibirá:
   - **APLICAÇÃO: SC**
   - **Composição com os ativos extraídos**

---

## Nota Técnica

O Firebird é sensível a tipos de dados em comparações. Se o campo `FC03300.CDPRO` for `INTEGER`, passar uma string `'92602'` não encontrará o registro. A solução é passar ambos os formatos ou usar `CAST` para garantir compatibilidade.
