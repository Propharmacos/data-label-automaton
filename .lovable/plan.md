
# Plano: Padronização de Rótulos - Produto Único vs Mescla

## Regras de Negócio Documentadas

### Os 3 Tipos de Produtos
| Tipo | Descrição | pH/Lote/Val | O que aparece no rótulo |
|------|-----------|-------------|-------------------------|
| **Produto Único** | Ativo sozinho (ex: Glicose) | 1 único | Só o nome do ativo (sem "AMP") |
| **Mescla** | Vários ativos juntos (ex: Glicose + Lidocaína + L-Carnitina) | 1 único compartilhado | Só os ativos da mescla (NÃO o nome comercial) |
| **Kit** | Vários ativos separados | Cada um tem seu próprio | *(Implementar depois)* |

### Regras de Exibição
- **Produto Único**: Mostrar apenas o campo `formula` (nome do ativo). Ocultar `composicao`.
- **Mescla**: Mostrar apenas o campo `composicao` (lista de ativos). Ocultar `formula` (nome comercial).
- **Sempre remover** o prefixo "AMP " do nome.

---

## Alterações Técnicas

### 1. Frontend - LabelCard.tsx
Ajustar a lógica de renderização para:
- Se `composicao` existir e for diferente de `formula`: é **MESCLA** - mostrar só `composicao`
- Se `composicao` estiver vazio ou igual à `formula`: é **PRODUTO ÚNICO** - mostrar só `formula`

```text
Arquivo: src/components/LabelCard.tsx

Lógica a implementar:
┌─────────────────────────────────────────────────────────┐
│  Se composicao tem valor?                               │
│      ├── SIM → É MESCLA → Mostrar só composicao         │
│      └── NÃO → É PRODUTO ÚNICO → Mostrar só formula     │
└─────────────────────────────────────────────────────────┘
```

**Modificações específicas:**
1. Na função `getFieldContent()`:
   - Campo `composicao`: retorna o valor apenas se existir e for diferente da fórmula
   - Campo `formula`: retorna o valor apenas se `composicao` estiver vazio

2. Na função `shouldRenderField()`:
   - Aplicar a mesma lógica de exclusão mútua entre `composicao` e `formula`

3. Na função `generateInitialText()`:
   - Ajustar para usar a lógica de exclusão mútua no texto livre

### 2. Frontend - layouts.ts
Garantir que ambos os campos (`composicao` e `formula`) estejam habilitados nos layouts, pois a decisão de qual mostrar será feita dinamicamente no LabelCard.

### 3. Backend - servidor.py
O backend já implementa a lógica de diferenciação. Apenas verificar se:
- Para Produto Único: `composicao` volta vazio
- Para Mescla: `composicao` vem preenchido com os ativos

---

## Resultado Esperado

### Exemplo: Produto Único (Glicose)
```
DR. FULANO DE TAL - CRM 12345/SP
MARIA DA SILVA
GLICOSE 75% 2ML
L: 1234/25  F: 01/25  V: 07/25
pH: 7.0  APLICAÇÃO: EV
```

### Exemplo: Mescla (Fator Crescimento)
```
DR. FULANO DE TAL - CRM 12345/SP
MARIA DA SILVA
LIDOCAÍNA + GLICOSE + L-CARNITINA
L: 5678/25  F: 01/25  V: 07/25
pH: 7.5  APLICAÇÃO: ID/SC
```

---

## Arquivos a Modificar

1. **src/components/LabelCard.tsx** - Lógica de exclusão mútua composicao/formula
2. **src/config/layouts.ts** - Garantir que ambos campos estejam enabled por padrão

---

## Memória para Salvar

Após implementar, criar memória documentando:
- As 3 categorias de produtos (Único, Mescla, Kit)
- Regra: composicao aparece → é mescla → oculta formula
- Regra: composicao vazio → é único → mostra só formula
- Kit será implementado futuramente com lógica separada
