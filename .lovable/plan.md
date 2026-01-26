
# Plano: Correção da Lógica de Extração FC99999 no servidor.py

## Problemas Identificados nos Logs

| CDPRO | CDPRIN | Problema | Causa Raiz |
|-------|--------|----------|------------|
| 92446 | 92446 | Rejeita `OBSFIC9244614` | Validação CONTAINING muito restritiva |
| 92497 | 92496 | Classifica como ÚNICO tendo 4 ativos | Lógica de comparação de nome vs ativos falha |
| 92781 | 92779 | Rejeita `OBSFIC9277914` | Mesmo problema do 92446 |
| 92406 | 92406 | Encontra "L CARNITINA" (dado errado?) | Dado pode estar incorreto na FC99999 |

---

## Correções Necessárias

### Correção 1: Validação CONTAINING mais flexível (linha ~1240)

**Problema**: A validação atual rejeita `OBSFIC9244614` porque exige que termine exatamente com `92446`.

**Solução**: Aceitar se o código está **contido** no argumento após remover o prefixo "OBSFIC".

```text
ANTES:  OBSFIC9244614 → rejeita (não termina com 92446)
DEPOIS: OBSFIC9244614 → extrai "9244614" → contém "92446"? → ACEITA
```

**Código a alterar** (linhas 1235-1247):
```python
# Filtra registros que contêm o código buscado
todos_args = []
for arg in todos_args_containing:
    argumento = arg[0].strip() if arg[0] else ""
    # Remove prefixo OBSFIC para comparação
    codigo_no_arg = argumento.replace("OBSFIC", "").strip()
    
    # Aceita se o código buscado está contido no argumento
    if (codigo_busca in codigo_no_arg or 
        codigo_busca_padded in codigo_no_arg or
        argumento.endswith(codigo_busca) or 
        argumento.endswith(codigo_busca_padded)):
        todos_args.append(arg)
        print(f"    VALIDADO: '{argumento}'")
    else:
        print(f"    REJEITADO: '{argumento}' (não corresponde ao código)")
```

---

### Correção 2: Classificação MESCLA vs PRODUTO ÚNICO (linhas 1294-1331)

**Problema**: O produto 92496 tem 4 ativos reais mas é classificado como ÚNICO porque palavras do nome ("GORD", "LOC") podem estar sendo encontradas nos ativos.

**Solução**: Usar critérios mais simples e confiáveis:
1. Se `CDPRIN != CDPRO` → provavelmente é derivado/mescla
2. Se encontra múltiplos ativos com vírgula/separador → é MESCLA
3. Se o primeiro ativo contém vírgula (lista de componentes) → é MESCLA

**Código a alterar** (linhas 1299-1331):
```python
e_mescla = False
composicao = ""
nome_formula = nome_produto

if ativos_mescla:
    primeiro_ativo = ativos_mescla[0] if ativos_mescla else ""
    
    # CRITÉRIO 1: CDPRIN diferente de CDPRO indica derivado
    if cdprin_str and cdprin_str != cdpro_str and cdprin_str != '0':
        e_mescla = True
        print(f"  -> MESCLA (CDPRIN diferente de CDPRO)")
    
    # CRITÉRIO 2: Primeiro ativo contém vírgula (lista de componentes)
    elif ',' in primeiro_ativo:
        e_mescla = True
        print(f"  -> MESCLA (ativos com vírgula = múltiplos componentes)")
    
    # CRITÉRIO 3: Nome do produto NÃO está contido no ativo
    elif primeiro_ativo and nome_produto_upper not in primeiro_ativo.upper():
        # Verifica se é realmente diferente
        palavras_produto = [p for p in nome_produto_upper.split() if len(p) > 3]
        if not any(p in primeiro_ativo.upper() for p in palavras_produto[:2]):
            e_mescla = True
            print(f"  -> MESCLA (ativo diferente do nome do produto)")

    if e_mescla:
        # Usa o primeiro ativo como composição (geralmente é a lista completa)
        composicao = primeiro_ativo
        # Remove prefixo AMP do nome se houver
        nome_formula = nome_produto.replace("AMP ", "").strip()
        print(f"  -> TIPO: MESCLA")
        print(f"  -> COMPOSIÇÃO: '{composicao}'")
    else:
        composicao = ""
        print(f"  -> TIPO: PRODUTO ÚNICO")
```

---

### Correção 3: Filtrar ativos inválidos

**Problema**: Registros como "ETIQUETA (CATALOGO...)" e "PREGA MENOR 3CM" estão sendo capturados como ativos.

**Solução**: Adicionar filtro para ignorar registros que são instruções, não ativos.

```python
# Lista de prefixos/palavras que indicam que NÃO é um ativo
IGNORAR_ATIVOS = ['ETIQUETA', 'CATALOGO', 'PREGA', 'SUG.', 'SUGESTAO']

# Na hora de processar os ativos:
for arg in todos_args:
    parametro = (arg[2] or "").strip()
    # Ignora se é instrução/etiqueta
    if any(ignorar in parametro.upper() for ignorar in IGNORAR_ATIVOS):
        print(f"    IGNORADO (não é ativo): '{parametro[:50]}...'")
        continue
    ativos_mescla.append(parametro)
```

---

## Arquivo Atualizado

Vou gerar o `servidor.py` completo com todas as correções aplicadas para você copiar e colar.

---

## Resultado Esperado Após Correções

| CDPRO | Antes | Depois |
|-------|-------|--------|
| 92446 | Sem ativos | Encontra composição via OBSFIC9244614 |
| 92496 | "PRODUTO ÚNICO" | "MESCLA" com ativos corretos |
| 92779 | Sem ativos | Encontra composição via OBSFIC9277914 |

---

## Resumo das Alterações

1. **Linha ~1240**: Validação CONTAINING aceita códigos contidos (não só terminando)
2. **Linha ~1299**: Nova lógica de classificação baseada em CDPRIN e vírgulas
3. **Linha ~1260**: Filtro para ignorar registros de etiqueta/catálogo

