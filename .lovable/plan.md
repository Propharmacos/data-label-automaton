

# Navegação direta entre barras/itens da requisição

## Contexto atual
Hoje, ao pesquisar uma requisição (ex: `10436`), o sistema retorna todas as fórmulas/barras daquele pedido (ex: `10436-1`, `10436-2`, `10436-3`, …) e o usuário navega **uma a uma** via setas "próximo/anterior". Não há atalho para pular direto para uma barra específica (ex: ir do item 1 para o item 7 sem passar pelos intermediários).

## Solução proposta: Seletor de Barras (lista clicável)

Adicionar um **seletor visual de barras** no topo do editor de rótulos, mostrando todos os itens da requisição de uma vez. O usuário clica no item desejado e o editor salta direto para ele.

### Visual (no topo do editor, acima dos botões de navegação existentes)
```text
Requisição 10436  —  8 barras

[1: DUTASTERIDA 0,1%]  [2: FINASTERIDA 1MG]  [3: MINOXIDIL 5%]  
[4: BIOTINA 10MG]      [5: M.DIM.QUEDA]      [6: ALOPECIA MASC]  
[7: LAC CORPORAL]      [8: CAPIXYL 2%]

               ▲ item atual destacado (borda/cor primária)
```

Cada "chip" mostra:
- **Número da barra** (`nrItem` — 1, 2, 3…)
- **Nome curto do produto** (primeiro ativo da composição ou `formula` truncado em ~20 chars)
- **Destaque visual** no item atualmente em edição (borda colorida / fundo primary)
- **Indicador de edição salva** (bolinha verde se já tem `saved_rotulo` no Supabase para aquele item)

### Interação
- **Clique no chip** → salta direto para aquele item no editor.
- **Se houver alterações não salvas** no item atual → abre o `UnsavedChangesDialog` já existente antes de trocar.
- **Setas ← → / Home End** no teclado também funcionam para navegar entre chips (acessibilidade).
- **Scroll horizontal** se houver muitos itens (ex: 20+ barras), sem quebrar o layout.

## Alterações técnicas

### Arquivo único: `src/pages/Index.tsx` (ou onde está o editor principal)
Investigar primeiro para confirmar, mas pela estrutura do projeto o estado `currentIndex` + array de `rotulos` já existe. A mudança é:

1. **Novo componente** `src/components/RequisitionItemSelector.tsx`:
   - Props: `rotulos: RotuloItem[]`, `currentIndex: number`, `onSelect: (index: number) => void`, `savedMap: Record<string, boolean>` (qual item já tem texto salvo).
   - Renderiza chips horizontais com Tailwind (`flex flex-wrap gap-2` ou `flex overflow-x-auto`).
   - Usa `Button` variant `outline`/`default` do shadcn.

2. **Integração em `Index.tsx`**:
   - Renderizar `<RequisitionItemSelector>` acima do editor.
   - Ligar `onSelect` ao mesmo handler que hoje as setas "próximo/anterior" usam, aproveitando a proteção do `UnsavedChangesDialog`.
   - Calcular `savedMap` consultando o Supabase (ou reusar o estado que já faz isso para mostrar o badge "Salvo").

### O que NÃO muda
- Backend (`servidor.py`) — nenhuma alteração, os dados já vêm todos na mesma resposta.
- Lógica de geração de texto (`LabelTextEditor.tsx`) — intocada.
- Persistência no Supabase — intocada.
- Setas "próximo/anterior" atuais — continuam funcionando lado a lado com os chips.
- Fluxo de impressão — intocado.

## Validação
1. Pesquisar req `10436` (8 barras) → aparecem 8 chips numerados.
2. Clicar no chip "7" → editor salta direto para o item 7, sem passar por 2,3,4,5,6.
3. Item atual fica destacado (borda primary).
4. Editar item 3, clicar no chip 5 sem salvar → abre `UnsavedChangesDialog` (salvar/descartar/cancelar).
5. Chips de itens já salvos no Supabase mostram bolinha verde.
6. Requisição com 1 item só → seletor esconde (não faz sentido).
7. Requisição com 20+ itens → scroll horizontal funciona.

## Extensão futura (fora deste plano, só anotando)
- Busca textual dentro do seletor ("filtrar por nome do ativo").
- Atalhos numéricos (apertar `1`–`9` no teclado para saltar).

