

# Redesign UX da Pagina Principal - Editor de Rotulos Estilo Formula Certa

## Objetivo
Substituir a visualizacao atual em grid de cards por uma interface de edicao individual por barra, inspirada no "Editor de Rotulo" do Formula Certa (conforme print de referencia).

## Mudancas Principais

### 1. Navegacao por Barra (Setas)
- Ao pesquisar uma requisicao, os rotulos sao carregados normalmente, mas em vez de exibir todos em grid, exibe **um rotulo por vez**
- Setas esquerda/direita na parte inferior para navegar entre barras (REQ/0, REQ/1, REQ/2...)
- Indicador "Registro: 1/4" no topo (como no Formula Certa)
- O nome do rotulo (layout selecionado, ex: "AMP.CX") aparece no cabecalho do editor

### 2. Area de Edicao Estilo TXT
- O conteudo do rotulo e exibido em uma **textarea monospace** editavel diretamente (sem precisar de duplo-clique)
- O texto ja vem pre-formatado com os dados da barra atual
- Edicao livre e imediata - o usuario altera qualquer linha diretamente

### 3. Indicador de Linha e Coluna
- Na parte inferior da area de texto, exibir **"Lin: X/Y Col: Z/W"** em tempo real (conforme segundo print de referencia)
- X = linha atual do cursor, Y = total de linhas
- Z = coluna atual do cursor, W = total de colunas da linha atual

### 4. Impressao Individual
- Botao "Imprimir" envia apenas o rotulo atual (barra visivel) para a impressora
- Opcao de selecionar impressora continua disponivel

### 5. Configuracao da Impressora na Parte Inferior
- Abaixo da area de edicao, exibir informacoes do layout/impressora selecionada: nome do layout, dimensoes (mm), linhas configuradas

---

## Detalhes Tecnicos

### Arquivo: `src/pages/Index.tsx`
- Adicionar estado `currentIndex` para controlar qual barra esta sendo visualizada
- Remover o grid de `LabelCard` e substituir por um unico componente de edicao
- Adicionar navegacao com setas (ChevronLeft/ChevronRight)
- O texto editavel e armazenado no campo `textoLivre` do rotulo atual
- Botao Imprimir envia apenas `rotulos[currentIndex]`

### Novo Componente: `src/components/LabelTextEditor.tsx`
- Textarea monospace com controle de cursor (linha/coluna)
- Recebe o rotulo atual e gera o texto formatado automaticamente
- Callback `onChange` para salvar alteracoes no texto
- Exibe "Lin: X/Y Col: Z/W" na barra inferior
- Header com nome do layout e "Registro: N/Total"

### Arquivo: `src/components/LabelCard.tsx`
- Permanece no projeto para uso futuro, mas nao sera mais usado na pagina principal

### Fluxo do Usuario
```text
Pesquisa REQ 6806
        |
        v
+----------------------------------+
| Nome do Rotulo: AMP.CX          |
| Registro: 1/4                   |
+----------------------------------+
|                                  |
| LENIE ANTONIA ALVES DE SOUZA    |
| DR(A)LENIE ANTONIA  COREN-SP... |
| CROMO 20MCG, COBRE 20MCG...    |
| pH:5,0  L:536/25  F:12/25...   |
| USO EM CONSULTORIO  APLICACAO:ID|
| CONTEM:1FR. DE 2ML   REG:15079 |
|                                  |
+----------------------------------+
| Lin: 1/8  Col: 1/27             |
+----------------------------------+
| [<-]  Req: 6806 - 0  [->]      |
| Layout: AMP_CX | 109x25mm      |
| [Impressora v]  [Imprimir]      |
+----------------------------------+
```

### Estimativa
- Criacao do componente `LabelTextEditor.tsx`
- Refatoracao do `Index.tsx` para navegacao por barra
- Reutilizacao da logica de `generateInitialText()` do `LabelCard.tsx`

