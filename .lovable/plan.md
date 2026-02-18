
## Comparador PPLA: Campo de Colagem para Comandos do Formula Certa

### Objetivo
Adicionar ao modal de diagnostico PPLA existente um campo de texto onde o usuario pode colar os comandos capturados do arquivo `.prn` do Formula Certa, com comparacao lado a lado e destaque visual nas diferencas.

### O que sera feito

1. **Campo de texto para colagem** - Um textarea no modal de diagnostico onde o usuario cola o conteudo do arquivo `.prn` capturado do Formula Certa.

2. **Parser de comandos PPLA** - Funcao que extrai e categoriza os comandos colados:
   - Cabecalho (STX f, STX L, STX e)
   - Configuracao (PA, D11, H14)
   - Linhas de texto (coordenadas + dados)
   - Finalizacao (Q, E)

3. **Comparacao lado a lado** - Dois paineis no modal:
   - **Esquerda**: "Nosso Sistema" (saida do diagnostico PPLA existente)
   - **Direita**: "Formula Certa" (comandos colados)
   - Linhas com diferencas destacadas em vermelho/amarelo
   - Linhas identicas em verde

4. **Analise automatica de diferencas** - Resumo indicando:
   - Diferencas em coordenadas (X, Y)
   - Diferencas em fonte/rotacao/multiplicadores
   - Diferencas em comandos de calibracao (D, H, contraste)
   - Comandos presentes em um lado mas ausentes no outro

### Detalhes Tecnicos

**Arquivos modificados:**
- `src/components/LabelSettings.tsx` - Adicionar botao "Comparar com FC" e o modal de comparacao com textarea + visualizacao lado a lado
- Possivelmente extrair o comparador em um componente separado (`src/components/PPLAComparer.tsx`) para manter o codigo organizado

**Estrutura do parser:**
- Detectar blocos de etiqueta separados por `STX L` / `Q0001E`
- Extrair apenas o primeiro bloco (uma etiqueta) para comparacao
- Separar cada linha em: tipo (cabecalho/config/texto/fim), e para linhas de texto: font, rotation, hmult, vmult, x, y, conteudo

**UI do comparador:**
- Dialog/modal com largura expandida (max-w-4xl)
- ScrollArea com dois paineis lado a lado
- Textarea na parte superior para colar os comandos
- Botao "Analisar" que processa e exibe a comparacao
- Badge colorido por linha: verde (identico), amarelo (similar), vermelho (diferente)

**Fluxo do usuario:**
1. Abrir Notepad++ com o arquivo `.prn`
2. Copiar todo o conteudo (Ctrl+A, Ctrl+C)
3. No sistema web, clicar "Diagnostico PPLA" e depois "Comparar com FC"
4. Colar no textarea e clicar "Analisar"
5. Visualizar diferencas destacadas lado a lado
