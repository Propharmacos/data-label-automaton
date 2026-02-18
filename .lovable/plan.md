
## Fazer as Etiquetas Imprimirem com Informacao

### O Problema
Quando voce manda imprimir, a etiqueta sai mas esta em branco -- sem nenhum texto. Isso acontece porque os parametros de calibracao do nosso sistema (contraste, fonte, rotacao) estao diferentes do que a impressora Argox precisa para funcionar. O comparador PPLA que criamos mostrou que o Formula Certa usa valores diferentes dos nossos.

### A Solucao (3 partes)

**Parte 1: Corrigir os valores padrao de calibracao**

O valor padrao de contraste no sistema esta em `12`, mas o comparador mostrou que o Formula Certa usa `14` (comando H14). Alem disso, a rotacao padrao esta em `1` (90 graus), o que pode estar jogando o texto para fora da area da etiqueta em algumas impressoras.

Vamos atualizar o `src/config/api.ts` com valores padrao que funcionam:
- Contraste: 12 -> 14 (para garantir que a impressao termica fique visivel)
- Rotacao: manter como 1 (padrao PPLA para Argox)

**Parte 2: Adicionar botao "Impressao de Diagnostico" na tela principal**

Na tela principal (Index), quando o usuario tiver rotulos carregados, adicionar um botao que imprime UMA etiqueta de teste com os dados reais do rotulo atual, mostrando no toast exatamente quais parametros foram usados (contraste, fonte, rotacao, impressora). Assim o usuario sabe imediatamente o que esta sendo enviado.

**Parte 3: Adicionar "Teste Progressivo" nas Configuracoes**

Na aba Agente HTTP das configuracoes, adicionar um botao "Teste Progressivo" que imprime 3 etiquetas de teste automaticamente, cada uma com configuracoes diferentes:
- Etiqueta 1: Rotacao 0 (horizontal), Fonte 2, Contraste 14
- Etiqueta 2: Rotacao 1 (90 graus), Fonte 2, Contraste 14
- Etiqueta 3: Rotacao 1, Fonte 0, Contraste 16

Cada etiqueta tera um titulo identificando qual configuracao esta usando (ex: "TESTE R0 F2 H14"). Assim o usuario identifica visualmente qual combinacao funciona na impressora dele e pode aplicar aquela configuracao.

### Detalhes Tecnicos

**Arquivo 1: `src/config/api.ts`**
- Alterar `DEFAULT_PRINT_AGENT_CONFIG.calibracao.contraste` de `12` para `14`

**Arquivo 2: `src/services/printAgentService.ts`**
- Adicionar funcao `testeProgressivoAgente(url, impressora)` que envia 3 etiquetas com configuracoes diferentes, cada uma com texto identificando os parametros usados
- Cada etiqueta usa o endpoint `/teste` ou `/imprimir` do agente com calibracao especifica

**Arquivo 3: `src/components/LabelSettings.tsx`**
- Adicionar botao "Teste Progressivo" na secao do Agente HTTP, ao lado do botao de teste existente
- Ao clicar, chama `testeProgressivoAgente` e exibe toast com resultado
- Ao identificar qual configuracao funciona, o usuario pode ajustar os campos de calibracao manualmente ou usar o comparador para aplicar automaticamente

**Arquivo 4: `src/pages/Index.tsx`**
- Adicionar indicador visual dos parametros de impressao ativos (contraste, fonte, rotacao) proximo ao seletor de impressora, para que o usuario veja o que esta sendo usado sem precisar ir nas configuracoes

### Resultado Esperado
1. Com o contraste padrao atualizado para H14, etiquetas que antes saiam em branco devem comecar a mostrar texto
2. Se ainda nao funcionar, o teste progressivo revela exatamente qual combinacao de parametros a impressora aceita
3. O usuario tem visibilidade total do que esta sendo enviado para a impressora
