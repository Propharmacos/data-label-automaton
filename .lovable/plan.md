
# Plano: Corrigir Detecção de KIT - Não Usar FC05000 Como Critério Único

## Diagnóstico do Bug

### Problema Atual
A função `detecta_kit()` (linhas 262-349) considera como **KIT qualquer produto que exista na FC05000**:

```python
# ATUAL (ERRADO):
def detecta_kit(cursor, cdpro, tpforma=None):
    # ...
    cursor.execute("""
        SELECT FIRST 1 CDFRM, CDSAC, DESCRFRM, TPFORMAFARMA
        FROM FC05000 
        WHERE CDSAC = ?
    """, (cdpro_str,))
    
    if row:
        return kit_info  # ← QUALQUER produto com receita é classificado como KIT!
```

### Por que está errado?
A tabela **FC05000/FC05100** contém a **receita de fabricação (BOM)** de TODOS os produtos que têm fórmula, incluindo:
- **KITs verdadeiros**: contêm múltiplos produtos farmacêuticos independentes
- **Produtos únicos**: contêm apenas insumos de fabricação (água, ampola, selo, tampa)

**GLICOSE 75%** tem uma receita (água + ampola + selo + tampa), então entra na FC05000, mas **NÃO é um KIT** - é um produto único.

---

## Solução: Critério Explícito para KIT

### Opção Implementada: Validar Componentes

Modificar `detecta_kit()` para **validar se os componentes são produtos farmacêuticos reais** (não apenas insumos de fabricação).

**Critério de validação:**
1. Buscar componentes na FC05100
2. Para cada componente, verificar se é **embalagem/insumo** usando `is_embalagem_ou_obs()`
3. **Só retornar como KIT se houver pelo menos 2 componentes "ativos reais"**

---

## Alterações no servidor.py

### Alteração 1: Modificar `detecta_kit()` (linhas 262-349)

**Antes:**
```python
def detecta_kit(cursor, cdpro, tpforma=None):
    # ...
    if row:
        kit_info = {...}
        print(f"  [DETECTA_KIT] ✓ KIT ENCONTRADO!")
        return kit_info  # ← Retorna para QUALQUER produto na FC05000
```

**Depois:**
```python
def detecta_kit(cursor, cdpro, tpforma=None):
    # ...
    if row:
        kit_info = {...}
        
        # =====================================================
        # VALIDAÇÃO: Só é KIT se tiver componentes farmacêuticos reais
        # (não apenas insumos de fabricação como ampola/selo/tampa)
        # =====================================================
        cdfrm = kit_info["cdfrm"]
        
        # Busca componentes da FC05100
        cursor.execute("""
            SELECT k.CDPRO, p.DESCR
            FROM FC05100 k
            LEFT JOIN FC03000 p ON p.CDPRO = k.CDPRO
            WHERE k.CDFRM = ?
        """, (cdfrm,))
        componentes = cursor.fetchall()
        
        # Conta quantos componentes são "ativos reais" (não embalagem)
        ativos_reais = 0
        for comp in componentes:
            descr = comp[1] or ""
            if hasattr(descr, 'read'):
                descr = descr.read().decode('latin-1')
            
            # Usa a função existente para filtrar embalagens
            if not is_embalagem_ou_obs(descr):
                ativos_reais += 1
        
        # Só é KIT se tiver 2+ componentes ativos reais
        if ativos_reais >= 2:
            print(f"  [DETECTA_KIT] ✓ KIT VÁLIDO! {ativos_reais} ativos reais encontrados")
            return kit_info
        else:
            print(f"  [DETECTA_KIT] ✗ Não é KIT: apenas {ativos_reais} ativo(s) real(is) (resto é embalagem)")
            return None
```

---

## Fluxo Corrigido

### GLICOSE 75% (Item Único)
```text
GLICOSE 75% 2ML (CDPRO=12345)
      │
      └─► detecta_kit(12345)
              │
              └─► FC05000.CDSAC = 12345 → ENCONTRADO (tem receita)
                      │
                      └─► FC05100: Busca componentes do CDFRM
                              │
                              ├─► "ÁGUA PARA INJETÁVEIS" → is_embalagem_ou_obs = TRUE → IGNORA
                              ├─► "AMPOLA ÂMBAR 2ML"     → is_embalagem_ou_obs = TRUE → IGNORA
                              ├─► "SELO DE ALUMÍNIO"     → is_embalagem_ou_obs = TRUE → IGNORA
                              └─► "TAMPA BORRACHA"       → is_embalagem_ou_obs = TRUE → IGNORA
                              
                      └─► ativos_reais = 0
                              │
                              └─► Retorna None (NÃO É KIT)
                                      │
                                      └─► Processado como ITEM ÚNICO
                                              │
                                              └─► componentes = []
```

### KIT INTRADERMO (Kit Verdadeiro)
```text
KIT INTRADERMO (CDPRO=99999)
      │
      └─► detecta_kit(99999)
              │
              └─► FC05000.CDSAC = 99999 → ENCONTRADO
                      │
                      └─► FC05100: Busca componentes do CDFRM
                              │
                              ├─► "LIDOCAÍNA 2%"    → is_embalagem_ou_obs = FALSE → ATIVO REAL ✓
                              ├─► "ÁGUA ESTÉRIL"    → is_embalagem_ou_obs = TRUE  → IGNORA
                              ├─► "BICARBONATO..."  → is_embalagem_ou_obs = FALSE → ATIVO REAL ✓
                              └─► "HIALURONIDASE"   → is_embalagem_ou_obs = FALSE → ATIVO REAL ✓
                              
                      └─► ativos_reais = 3
                              │
                              └─► Retorna kit_info (É KIT VÁLIDO)
                                      │
                                      └─► Processado como KIT
                                              │
                                              └─► componentes = [Lidocaína, Bicarbonato, Hialuronidase]
```

---

## Arquivos Alterados

| Arquivo | Linhas | Alteração |
|---------|--------|-----------|
| `servidor.py` | 262-349 | Adicionar validação de componentes ativos em `detecta_kit()` |

---

## Garantias de Não-Regressão

1. **KITs verdadeiros continuam funcionando** - Eles têm 2+ componentes farmacêuticos reais
2. **Mesclas não são afetadas** - Lógica de mescla é separada e não depende de `detecta_kit()`
3. **Aplicação não é afetada** - Extração de aplicação vem de `buscar_aplicacao_nao_kit()`
4. **Reutiliza função existente** - Usa `is_embalagem_ou_obs()` que já está funcionando

---

## Resultado Esperado

**GLICOSE 75% 2ML (Item Único):**
```
Retorno da API:
{
  "tipoItem": "PRODUTO ÚNICO",
  "componentes": [],
  "aplicacao": "EV",
  "composicao": ""
}

Rótulo:
AMP GLICOSE 75% – 2ML
APLICAÇÃO: EV
L: 12345/25  F: 01/25  V: 01/26
```

**KIT INTRADERMO (Kit Verdadeiro):**
```
Retorno da API:
{
  "tipoItem": "KIT",
  "componentes": [
    {"nome": "LIDOCAÍNA 2%", "lote": "001", ...},
    {"nome": "BICARBONATO...", "lote": "002", ...}
  ],
  "aplicacao": "ID"
}

Rótulo:
DR. FULANO - CRM 12345/SP
PACIENTE EXEMPLO
───────────────────
LIDOCAÍNA 2%   pH:7.2  L:001  V:01/26
BICARBONATO    pH:7.0  L:002  V:03/26
───────────────────
APLICAÇÃO: ID
```

---

## Teste de Validação

Depois da alteração, testar:

1. ✅ **GLICOSE 75%**: Deve aparecer como ITEM ÚNICO, sem componentes (água/ampola/selo/tampa)
2. ✅ **Mescla real**: Deve continuar mostrando ativos corretamente
3. ✅ **KIT verdadeiro**: Deve continuar expandindo componentes farmacêuticos
