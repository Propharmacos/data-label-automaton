

# Plano: Distinguir KIT de MESCLA na Detecção

## Diagnóstico do Bug

### Problema Atual
A correção anterior resolveu o caso de **ITEM ÚNICO** (GLICOSE), mas criou um novo problema: **MESCLAS com 2+ ativos estão sendo classificadas como KIT**.

**Exemplo: CAF/CARN (código 92446)**
- É uma **MESCLA** (ampola única com cafeína + carnitina combinadas)
- Mas na FC05100 tem 2 componentes: CAFEÍNA e L-CARNITINA
- Nenhum é embalagem, então `ativos_reais = 2`
- O sistema classifica erroneamente como **KIT**

### A Diferença Conceitual
| Tipo | Definição | Exemplo | Resultado esperado |
|------|-----------|---------|-------------------|
| **KIT** | Múltiplos produtos **acabados/separados** | Kit com 4 ampolas diferentes | Lista componentes individualmente |
| **MESCLA** | Múltiplos **ativos em 1 produto final** | Ampola com cafeína+carnitina | Mostra "CAFEINA, L-CARNITINA" na composição |
| **ITEM ÚNICO** | 1 ativo em 1 produto | Glicose 75% ampola | Só nome do produto |

## Solução: Critério de Nomenclatura para KIT

A característica mais confiável para distinguir KIT de MESCLA é o **nome do produto**. KITs verdadeiros geralmente têm:
- Prefixo "KIT" no nome (ex: "KIT INTRADERMO", "KIT EMAG")
- Ou contêm "KIT" em alguma posição do nome

Mesclas **nunca** têm "KIT" no nome - têm siglas como "CAF/CARN", "TRISH", etc.

### Lógica Proposta
Em `detecta_kit()`, **antes** de contar ativos reais, verificar se o nome do produto contém "KIT":

```python
def detecta_kit(cursor, cdpro, tpforma=None):
    # ... código existente até encontrar na FC05000 ...
    
    if row:
        kit_info = {...}
        
        # =====================================================
        # PRÉ-VALIDAÇÃO: Verifica se o nome sugere que é KIT
        # MESCLAS têm 2+ ativos na FC05100 mas NÃO são KITs
        # =====================================================
        descrfrm = kit_info.get("descrfrm", "")
        if descrfrm and hasattr(descrfrm, 'read'):
            descrfrm = descrfrm.read().decode('latin-1')
        descrfrm_upper = (descrfrm or "").upper().strip()
        
        # Se o nome NÃO contém "KIT", provavelmente é MESCLA, não KIT
        if "KIT" not in descrfrm_upper:
            print(f"  [DETECTA_KIT] ✗ Nome não contém 'KIT': '{descrfrm_upper[:50]}' - Ignorando")
            return None
        
        # ... resto do código de validação de componentes ...
```

## Alterações no servidor.py

### Alteração 1: Adicionar pré-filtro por nome em `detecta_kit()`

**Estratégia 1 (linhas ~314-364):**
Após encontrar o produto na FC05000, verificar se o nome (DESCRFRM) contém "KIT".

**Estratégia 2 (linhas ~372-418):**
Mesma verificação.

## Fluxo Corrigido

### GLICOSE 75% (Item Único)
```text
GLICOSE 75% 2ML
      │
      └─► detecta_kit()
              │
              └─► FC05000: DESCRFRM = "GLICOSE 75% 2ML"
                      │
                      └─► "KIT" não está no nome
                              │
                              └─► Retorna None imediatamente (NÃO É KIT) ✅
```

### CAF/CARN (Mescla)
```text
AMP CAF/CARN 20/60/ML - 2ML
      │
      └─► detecta_kit()
              │
              └─► FC05000: DESCRFRM = "CAF/CARN 20/60/ML"
                      │
                      └─► "KIT" não está no nome
                              │
                              └─► Retorna None imediatamente (NÃO É KIT) ✅
                                      │
                                      └─► Processado como MESCLA
                                              │
                                              └─► composição = "CAFEINA 20MG/ML, L-CARNITINA 60MG/ML"
                                              └─► aplicação = "SC/IM"
```

### KIT INTRADERMO (Kit Verdadeiro)
```text
KIT INTRADERMO
      │
      └─► detecta_kit()
              │
              └─► FC05000: DESCRFRM = "KIT INTRADERMO MESOTERAPIA"
                      │
                      └─► "KIT" ESTÁ no nome ✓
                              │
                              └─► Continua validação de componentes
                                      │
                                      ├─► LIDOCAÍNA 2%      → ATIVO ✅
                                      ├─► BICARBONATO       → ATIVO ✅
                                      └─► HIALURONIDASE     → ATIVO ✅
                                      
                              └─► ativos_reais = 3 ≥ 2
                                      │
                                      └─► Retorna kit_info (É KIT VÁLIDO) ✅
```

## Garantias

1. **GLICOSE (Item Único)**: Nome não contém "KIT" → Não é KIT → OK
2. **CAF/CARN (Mescla)**: Nome não contém "KIT" → Não é KIT → Processa como Mescla via FC99999 → OK
3. **KIT INTRADERMO (Kit)**: Nome contém "KIT" → Valida componentes → É KIT → OK
4. **Mesclas em geral**: Não usam "KIT" no nome → Processadas corretamente

## Resultado Esperado

**CAF/CARN (após correção):**
```text
Rótulo:
DR. FULANO - CRM 12345/SP
PACIENTE: EXEMPLO
CAFEINA 20MG/ML, L-CARNITINA 60MG/ML
L: 12345   F: 01/25   V: 06/25
APLICAÇÃO: SC/IM
```

Sem componentes expandidos como se fosse KIT!

## Seção Técnica

### Arquivos a Alterar
| Arquivo | Linhas | Alteração |
|---------|--------|-----------|
| `servidor.py` | ~314-320 | Adicionar verificação de "KIT" no nome antes de validar componentes |
| `servidor.py` | ~372-378 | Mesma verificação para estratégia 2 |

### Código da Alteração

```python
# Após obter kit_info em cada estratégia, ANTES de buscar componentes:

# =====================================================
# PRÉ-VALIDAÇÃO: Só considera KIT se o nome indicar isso
# MESCLAS têm 2+ ativos na FC05100 mas NÃO são KITs reais
# =====================================================
descrfrm = kit_info.get("descrfrm", "")
if descrfrm and hasattr(descrfrm, 'read'):
    descrfrm = descrfrm.read().decode('latin-1')
descrfrm_upper = (descrfrm or "").upper().strip()

# Se o nome NÃO contém "KIT", provavelmente é MESCLA, não KIT
if "KIT" not in descrfrm_upper:
    print(f"  [DETECTA_KIT] ✗ Nome não contém 'KIT': '{descrfrm_upper[:50]}' - Tratando como NÃO-KIT")
    return None
```

