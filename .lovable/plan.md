
# Plano: Corrigir Busca de APLICAÇÃO para Não-Kits

## Diagnóstico do Problema

Analisando a imagem do DBeaver enviada, identifiquei a discrepância:

| O que o banco tem | O que o código busca |
|-------------------|---------------------|
| `ARGUMENTO = OBSFIC9263814` (7 dígitos após OBSFIC) | `ARGUMENTO = OBSFIC92638` (5 dígitos) |
| `ARGUMENTO = OBSFIC9263914` | Match exato falha |
| `ARGUMENTO = OBSFIC9264114` | Não encontra registros |

**Causa raiz:** O código usa `WHERE ARGUMENTO = ?` (igualdade exata), mas os ARGUMENTOs reais no banco têm sufixos adicionais além do CDPRO.

Exemplo:
- CDPRO do produto: `92638`
- ARGUMENTO esperado pelo código: `OBSFIC92638`
- ARGUMENTO real no banco: `OBSFIC9263814` (CDPRO + sufixo numérico)

---

## Solução

Modificar a função `buscar_aplicacao_nao_kit()` para usar `STARTING WITH` em vez de igualdade exata, e adicionar log de debug para rastrear a busca.

### Alteração na Linha 60-67 do servidor.py

**Antes:**
```python
cursor.execute("""
    SELECT FIRST 5 ARGUMENTO, SUBARGUM, PARAMETRO, DESCRPAR
    FROM FC99999
    WHERE ARGUMENTO = ?
      AND (UPPER(PARAMETRO) CONTAINING 'APLIC'
           OR UPPER(DESCRPAR) CONTAINING 'APLIC')
    ORDER BY SUBARGUM
""", (argumento,))
```

**Depois:**
```python
print(f"  [APLICAÇÃO NÃO-KIT] Tentando ARGUMENTO STARTING WITH '{argumento}'")
cursor.execute("""
    SELECT FIRST 10 ARGUMENTO, SUBARGUM, PARAMETRO, DESCRPAR
    FROM FC99999
    WHERE ARGUMENTO STARTING WITH ?
      AND (UPPER(PARAMETRO) CONTAINING 'APLIC'
           OR UPPER(DESCRPAR) CONTAINING 'APLIC')
    ORDER BY ARGUMENTO, SUBARGUM
""", (argumento,))
```

### Alteração nos argumentos a tentar (Linha 50-54)

**Antes:**
```python
argumentos_tentar = [
    f"OBSFIC{cdpro_str}",
    f"OBSFIC0{cdpro_str}",
    f"OBSFIC00{cdpro_str}",
]
```

**Depois:**
```python
argumentos_tentar = [
    f"OBSFIC{cdpro_str}",      # Ex: OBSFIC92638 -> encontra OBSFIC9263814
]
```

Apenas um prefixo é necessário com `STARTING WITH`, pois já cobre todas as variações com sufixo.

---

## Arquivos Alterados

| Arquivo | Alteração |
|---------|-----------|
| `servidor.py` | Modificar query de `ARGUMENTO = ?` para `ARGUMENTO STARTING WITH ?` |
| `servidor.py` | Adicionar log de debug mostrando o prefixo buscado |
| `servidor.py` | Aumentar limite de registros para 10 (garantir cobertura) |

---

## Fluxo Corrigido

```text
Item da requisição (não-kit)
      │
      └─► buscar_aplicacao_nao_kit(cursor, 92638)
              │
              └─► Query: WHERE ARGUMENTO STARTING WITH 'OBSFIC92638'
                      │
                      └─► Encontra: OBSFIC9263814, OBSFIC9263914, etc.
                              │
                              └─► Filtra: PARAMETRO ou DESCRPAR contém 'APLIC'
                                      │
                                      └─► Extrai: "SC", "ID", "ID/SC", "IM/EV"
```

---

## Resultado Esperado

Após implementação, o console Flask mostrará:
```
  [APLICAÇÃO NÃO-KIT] Tentando ARGUMENTO STARTING WITH 'OBSFIC92638'
  [APLICAÇÃO NÃO-KIT] Encontrado: 'SC' em OBSFIC9263814
  [APLICAÇÃO] Usando busca não-kit: 'SC'
```

---

## Garantias de Não-Regressão

- Não altera nada relacionado a KIT
- A função continua isolada e só é chamada dentro de `if not e_kit`
- Apenas muda a estratégia de match de "exato" para "prefixo"
