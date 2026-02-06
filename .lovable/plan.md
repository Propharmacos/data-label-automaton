
# Plano: Corrigir Classificação ITEM ÚNICO vs MESCLA

## Diagnóstico do Bug

O problema está na lista **`IGNORAR_ATIVOS`** (linha 2997) que é muito curta:

```python
IGNORAR_ATIVOS = ['ETIQUETA', 'CATALOGO', 'PREGA', 'SUG.', 'SUGESTAO', 'CATÁLOGO', 'INSTRUC', 'AVISO']
```

Isso faz com que linhas de **embalagem/observação** como:
- "ÁGUA PARA INJETÁVEIS..."
- "FRASCO ÂMBAR..."
- "AMPOLA..."
- "SELO DE ALUMÍNIO..."
- "TAMPA DE BORRACHA..."

...sejam adicionadas à lista `ativos_mescla` (linha 3079), fazendo um **ITEM ÚNICO** (GLICOSE 75%) parecer uma **MESCLA**.

---

## Solução

### Alteração 1: Criar função `is_embalagem_ou_obs()` (nova função utilitária)

Adicionar uma função dedicada que identifica linhas de embalagem/observação usando uma lista abrangente de palavras-chave:

```python
def is_embalagem_ou_obs(linha: str) -> bool:
    """
    Retorna True se a linha indicar embalagem, material físico ou observação operacional.
    Essas linhas NÃO devem ser tratadas como ativos de mescla.
    """
    if not linha or not linha.strip():
        return True  # Linha vazia = ignorar
    
    import unicodedata
    # Normaliza removendo acentos para comparação
    linha_norm = ''.join(
        c for c in unicodedata.normalize('NFD', linha.upper()) 
        if unicodedata.category(c) != 'Mn'
    )
    
    # Lista de palavras-chave que indicam embalagem/material físico
    EMBALAGEM_KEYWORDS = [
        # Recipientes
        'FRASCO', 'AMBAR', 'AMPOLA', 'SERINGA', 'AGULHA', 'TUBO',
        'BISNAGA', 'POTE', 'GARRAFA', 'SACHÊ', 'SACHE', 'ENVELOPE',
        # Vedação/fechamento
        'SELO', 'TAMPA', 'BORRACHA', 'LACRE', 'ROLHA', 'FLIP-OFF',
        'FLIPOFF', 'FLIP OFF', 'ALUMINIO',
        # Veículos/diluentes (não são ativos)
        'AGUA PARA INJETAVEIS', 'AGUA PARA INJECAO', 'AGUA ESTERIL',
        'SORO FISIOLOGICO', 'NACL 0,9',
        # Acessórios
        'VALVULA', 'DOSADOR', 'CONTA-GOTAS', 'APLICADOR',
        # Identificação
        'ROTULO', 'ETIQUETA', 'EMBALAGEM',
        # Termos operacionais/instruções
        'CATALOGO', 'PESAGEM', 'OBSERVACAO', 'INSTRUCAO', 'INSTRUC',
        'PREGA', 'SUG.', 'SUGESTAO', 'AVISO', 'OBS:',
        # Medidas de embalagem
        'MENOR 3CM', 'MENOR 4CM', 'MENOR 5CM',
        # Registro (não é ativo)
        'REG:',
    ]
    
    for keyword in EMBALAGEM_KEYWORDS:
        if keyword in linha_norm:
            return True
    
    return False
```

### Alteração 2: Criar função `is_ativo_mescla()` (validação adicional)

```python
def is_ativo_mescla(linha: str) -> bool:
    """
    Retorna True se a linha parece ser um ativo real de mescla.
    Critérios: NÃO é embalagem E tem características de ativo.
    """
    if is_embalagem_ou_obs(linha):
        return False
    
    linha_upper = linha.upper().strip()
    
    # Ignora linhas muito curtas (provavelmente não é ativo)
    if len(linha_upper) < 3:
        return False
    
    # Indicadores positivos de que É um ativo
    INDICADORES_ATIVO = ['MG', 'ML', '%', 'UI', 'IU', 'MCG', 'G/ML', 'MG/ML']
    
    # Se contém indicador de concentração, provavelmente é ativo
    for indicador in INDICADORES_ATIVO:
        if indicador in linha_upper:
            return True
    
    # Se não é embalagem e tem tamanho razoável, considera como potencial ativo
    if len(linha_upper) >= 5:
        return True
    
    return False
```

### Alteração 3: Substituir lógica de coleta de ativos (linhas 2996-3080)

No loop que processa registros da FC99999, substituir a verificação simples por chamadas às novas funções:

**Antes (linha 3061-3080):**
```python
# Ignora se contém palavra de exclusão
if any(ignorar in texto_upper for ignorar in IGNORAR_ATIVOS):
    print(f"    IGNORADO (não é ativo): '{texto[:50]}...'")
    continue

# ... adiciona à ativos_mescla
```

**Depois:**
```python
# =====================================================
# CLASSIFICAÇÃO: EMBALAGEM/OBS vs ATIVO REAL
# =====================================================
if is_embalagem_ou_obs(texto):
    print(f"    EMBALAGEM/OBS (ignorado): '{texto[:50]}...'")
    continue

if not is_ativo_mescla(texto):
    print(f"    NÃO É ATIVO (ignorado): '{texto[:50]}...'")
    continue

# Só chega aqui se for ativo válido
ativos_mescla.append(texto_limpo)
print(f"  -> ATIVO REAL encontrado: '{texto_limpo[:50]}...'")
```

### Alteração 4: Ajustar lógica de classificação final (linhas 3120-3165)

Garantir que a decisão ITEM ÚNICO vs MESCLA seja baseada apenas em ativos reais:

```python
# =====================================================
# LÓGICA: PRODUTO ÚNICO vs MESCLA vs KIT
# =====================================================
if e_kit:
    # KIT: mantém comportamento atual (intocado!)
    pass
elif len(ativos_mescla) == 0:
    # SEM ATIVOS REAIS = ITEM ÚNICO
    e_mescla = False
    composicao = ""
    print(f"  -> TIPO: ITEM ÚNICO (sem ativos após filtro)")
elif len(ativos_mescla) >= 1:
    # COM ATIVOS REAIS = MESCLA
    e_mescla = True
    composicao = ", ".join(ativos_mescla)
    print(f"  -> TIPO: MESCLA ({len(ativos_mescla)} ativos)")
```

---

## Arquivos Alterados

| Arquivo | Linhas | Alteração |
|---------|--------|-----------|
| `servidor.py` | ~30-50 | Adicionar funções `is_embalagem_ou_obs()` e `is_ativo_mescla()` |
| `servidor.py` | 2996-3080 | Substituir `IGNORAR_ATIVOS` por chamadas às novas funções |
| `servidor.py` | 3120-3165 | Simplificar lógica de classificação |

---

## Fluxo Corrigido

```text
GLICOSE 75% 2ML
      │
      └─► FC99999 retorna linhas:
              ├─► "APLICAÇÃO: EV"          → Extrai aplicação
              ├─► "ÁGUA PARA INJETÁVEIS"   → is_embalagem_ou_obs = TRUE → IGNORA
              ├─► "FRASCO ÂMBAR"           → is_embalagem_ou_obs = TRUE → IGNORA
              ├─► "SELO DE ALUMÍNIO"       → is_embalagem_ou_obs = TRUE → IGNORA
              └─► "TAMPA DE BORRACHA"      → is_embalagem_ou_obs = TRUE → IGNORA
              
      └─► ativos_mescla = [] (VAZIO após filtro)
              │
              └─► TIPO = ITEM ÚNICO
                      │
                      └─► Renderiza: Nome + Aplicação + Lote/Fab/Val
```

---

## Garantias de Não-Regressão

1. **KIT permanece intocado** - A lógica de kit (linhas 3082-3118) não é alterada
2. **Extração de APLICAÇÃO permanece igual** - As funções de extração não são modificadas
3. **Mesclas reais continuam funcionando** - Ativos com indicadores (MG, ML, %) são identificados corretamente
4. **Lista de keywords é conservadora** - Só ignora itens claramente de embalagem

---

## Resultado Esperado

**GLICOSE 75% 2ML (Item Único):**
```
AMP GLICOSE 75% – 2ML
APLICAÇÃO: EV
L: 12345/25  F: 01/25  V: 01/26
```

**MESCLA LIPOSSOMAS (Mescla Real):**
```
APLICAÇÃO: SC
L-CARNITINA 500MG, TAURINA 100MG, CAFEÍNA 50MG
L: 12345/25  F: 01/25  V: 01/26
```

**KIT INTRADERMO (Kit - inalterado):**
```
DR. FULANO - CRM 12345/SP
PACIENTE EXEMPLO
───────────────────
LIDOCAÍNA 2%   pH:7.2  L:001  V:01/26
ÁGUA ESTÉRIL   pH:7.0  L:002  V:03/26
───────────────────
APLICAÇÃO: ID
```
