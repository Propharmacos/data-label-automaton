

## Plano: Controle de deslocamento vertical (subir/descer linhas) no A.PAC.PEQ

### Problema
No layout A.PAC.PEQ, as linhas do rótulo começam na coordenada Y=78 (dots). O usuário precisa poder subir o texto ainda mais no rótulo físico, mas hoje não existe nenhum controle para isso.

### Solução
Adicionar um controle de **offset vertical** (em dots) no editor, específico para o A.PAC.PEQ, que desloca todas as coordenadas Y para cima. O valor é salvo no localStorage e enviado ao agente de impressão.

### Alterações

**1. Frontend — `src/components/LabelTextEditor.tsx`**
- Novo state `yOffset` persistido no localStorage (chave `label_editor_y_offset_A_PAC_PEQ`)
- Valor padrão: 0, range: 0 a +30 dots (cada +1 ≈ 0.12mm para cima), incremento de 1
- Controle visual: ícone de seta vertical ↕ com botões +/− no header, visível apenas quando o layout é A_PAC_PEQ
- O valor de offset é incluído no objeto do rótulo ao enviar para impressão (campo `yOffsetDots`)

**2. Frontend — `src/pages/Index.tsx`**
- Ao chamar a API de impressão, incluir o `yOffsetDots` do localStorage no payload enviado ao agente

**3. Backend — `agente_impressao.py`**
- Na função `gerar_ppla_a_pac_peq`, ler o campo `yOffsetDots` do rótulo recebido
- Somar esse valor a cada coordenada Y da lista `y_positions = [78, 67, 56, 45, 34, 23, 12]`, resultando em `[78+N, 67+N, 56+N, ...]`
- O mesmo se aplica ao modo estruturado (linhas fixas de Paciente, Médico, REG)

### Resultado
O operador terá botões +/− no header do editor (visíveis apenas no A.PAC.PEQ) para ajustar quantos dots subir o texto. Exemplo: com offset +11, a linha do Paciente sai em Y=89 em vez de Y=78.

### Arquivos alterados
- `src/components/LabelTextEditor.tsx`
- `src/pages/Index.tsx`
- `agente_impressao.py`

