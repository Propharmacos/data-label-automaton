

# Correcao: APLICACAO no OBSFIC de Kit Sinonimo

## Problema Identificado

A funcao `extrair_obsfic_componente` em `servidor.py` (linha 887) filtra linhas de aplicacao com:

```python
if texto and not texto.upper().startswith("APLICAC"):
```

Porem, o texto vindo do banco e `"APLICAÇÃO: MICROAGULHAMENTO"`. O `.upper()` do Python NAO remove acentos: `"APLICAÇÃO".upper()` = `"APLICAÇÃO"`, que NAO comeca com `"APLICAC"` (C != Ç). O filtro falha silenciosamente e a linha de aplicacao e concatenada junto com os ativos.

Resultado atual no rotulo:
```
APLICAÇÃO: MICROAGULHAMENTO, ACIDO HIALURONICO NÃO RETICULADO 5MG
```

Resultado correto:
```
ACIDO HIALURONICO NÃO RETICULADO 5MG
(e AP:MICROAGULHAMENTO no rodape)
```

## Solucao

### 1. Backend (`servidor.py`) - Corrigir `extrair_obsfic_componente`

Alterar a funcao para:
- Usar `norm_texto()` (ja existe no projeto) para normalizar acentos antes de comparar
- Extrair o valor da aplicacao das linhas filtradas
- Retornar um dicionario com `composicao` e `aplicacao` em vez de apenas string

```python
def extrair_obsfic_componente(cursor, cdpro_comp):
    # ... busca existente ...
    
    textos = []
    aplicacao_comp = ""
    for reg in registros:
        texto = ...  # leitura existente
        texto_norm = norm_texto(texto.upper())
        if texto_norm.startswith("APLIC") or "APLICAC" in texto_norm:
            # Extrai valor apos ":"
            if ":" in texto:
                aplicacao_comp = texto.split(":", 1)[1].strip()
        else:
            textos.append(texto)
    
    return {
        "composicao": ", ".join(textos),
        "aplicacao": aplicacao_comp
    }
```

### 2. Backend (`servidor.py`) - Atualizar `montar_kit_expandido`

Nos dois blocos (linhas ~1186 e ~1213), tratar o retorno como dicionario e armazenar a aplicacao por componente:

```python
if e_sinonimo:
    obsfic_data = extrair_obsfic_componente(cursor, cdpro_comp)
    composicao_comp = obsfic_data["composicao"]
    aplicacao_comp = obsfic_data["aplicacao"]
else:
    composicao_comp = extrair_composicao_componente(cursor, cdpro_comp)
    aplicacao_comp = ""
```

Adicionar `"aplicacao": aplicacao_comp` ao dicionario do componente.

### 3. Frontend - Tipo `ComponenteKit` (`src/types/requisicao.ts`)

Adicionar campo opcional `aplicacao` ao tipo:

```typescript
export interface ComponenteKit {
  // ... campos existentes ...
  aplicacao?: string;
}
```

### 4. Frontend - Mapeamento (`src/services/requisicaoService.ts`)

Adicionar mapeamento do campo `aplicacao`:

```typescript
const mapearComponenteKit = (comp: any) => ({
  // ... existente ...
  aplicacao: comp.aplicacao || "",
});
```

### 5. Frontend - Renderizacao (`src/components/LabelCard.tsx`)

Na `renderKitContent`, para kits sinonimos, exibir a aplicacao de cada componente junto aos metadados (na mesma linha de pH/Lote/Fab/Val):

```tsx
{comp.aplicacao && <span>AP:{comp.aplicacao}</span>}
```

Isso segue o padrao visual dos outros kits, com "AP:" como prefixo.

## Arquivos Modificados

- `servidor.py` - Corrigir filtro de acentos e retornar aplicacao separada
- `src/types/requisicao.ts` - Adicionar `aplicacao` ao `ComponenteKit`
- `src/services/requisicaoService.ts` - Mapear campo `aplicacao`
- `src/components/LabelCard.tsx` - Exibir `AP:` por componente

## Resultado Esperado

Componente 1:
```
ACIDO HIALURONICO NÃO RETICULADO 5MG
pH:6,0  L:12012  F:12/25  V:12/26
```

Componente 2:
```
ACIDO TRANEXAMICO 8MG, TGP2 20MG, BELIDES 2%, LIP. VIT C 10MG, NIACINAMIDA 40MG
pH:6,5  L:329  F:11/25  V:05/26
```

Rodape (ou por componente):
```
USO EM CONSULTORIO  AP:MICROAGULHAMENTO
```

