

## Corrigir Etiquetas em Branco: Modo Dots (Compativel com Formula Certa)

### Causa Raiz

O agente de impressao usa o comando `m` (modo milimetros) do PPLA. Se a impressora Argox nao reconhece esse comando (firmware antigo, modelo incompativel), ela ignora o `m` e interpreta TODAS as coordenadas como dots:

- Y=220 em mm mode = 22.0mm do fundo (dentro da etiqueta)
- Y=220 em dot mode = 220 dots = ~27.5mm (FORA de uma etiqueta de 25mm = 200 dots)

Resultado: todo o texto fica fora da area imprimivel. Etiqueta sai em branco.

### Solucao

Adicionar modo dots ao agente como opcao, e criar um teste que imprime em dots para confirmar a hipotese. Se funcionar, converter todos os geradores para dots.

### Mudancas no Agente (agente_impressao.py)

**1. Novo endpoint `/teste-dots`**

Imprime uma etiqueta de teste usando coordenadas em DOTS (sem comando `m`), exatamente como o Formula Certa faz:
- Setup: `STX L`, `D11`, `H14`, `q360` (largura), `Q200,24` (altura+gap)
- Texto: coordenadas em dots (ex: Y=160 dots = ~20mm do fundo)
- Finaliza com `E`

Se essa etiqueta sair com texto, confirmamos que o problema e o modo milimetros.

**2. Novo modo `dots` nos geradores**

Adicionar parametro `modo` na calibracao (valor: `'mm'` ou `'dots'`). Quando `modo='dots'`:
- Nao envia comando `m`
- Usa `ppla_setup_dots()` com `q` (largura em dots) e `Q` (altura em dots + gap)
- Converte as coordenadas Y de 0.1mm para dots (multiplicando por 0.203 para 203 DPI)
- Mantém a mesma logica de geracao, so muda as unidades

**3. Converter coordenadas**

Para a impressora "AMP PEQUENO" (45x25mm a 203 DPI):
- Largura: 45mm x 8 dots/mm = 360 dots
- Altura: 25mm x 8 dots/mm = 200 dots
- Gap: 3mm = 24 dots

Coordenadas Y em dots (de baixo para cima, 200 dots total):
- Linha 1 (topo): Y = 180 dots (~22mm)
- Linha 2: Y = 150 dots (~18.5mm)
- Linha 3: Y = 120 dots (~15mm)
- Linha 4: Y = 90 dots (~11mm)
- Linha 5: Y = 60 dots (~7.5mm)
- Linha 6: Y = 30 dots (~3.7mm)
- Linha 7: Y = 10 dots (~1.2mm)

### Mudancas no Frontend

**1. `src/components/LabelSettings.tsx`**

- Adicionar botao "Teste Dots" ao lado do "Teste Progressivo"
- Este botao chama o novo endpoint `/teste-dots` do agente
- Se funcionar, exibe toast sugerindo ativar modo dots

**2. `src/types/requisicao.ts`**

- Adicionar campo `modo?: 'mm' | 'dots'` no tipo `PrinterCalibrationConfig`

**3. `src/config/api.ts`**

- Adicionar `modo: 'dots'` como padrao na calibracao (mais seguro que mm)

**4. `src/services/printAgentService.ts`**

- Adicionar funcao `testeDotsAgente(url, impressora)` que chama `/teste-dots`

### Ordem de Implementacao

1. Adicionar endpoint `/teste-dots` no agente (teste isolado em dots)
2. Adicionar botao "Teste Dots" na UI
3. Adicionar `ppla_setup_dots()` e `ppla_text_dots()` no agente
4. Adicionar flag `modo` na calibracao
5. Modificar geradores para usar dots quando `modo='dots'`
6. Mudar padrao para `dots`

### Resultado Esperado

1. Clicar "Teste Dots" imprime etiqueta com texto visivel (confirma a causa)
2. Ativar modo dots faz todas as etiquetas imprimirem corretamente
3. Modo mm continua disponivel para impressoras que suportam

