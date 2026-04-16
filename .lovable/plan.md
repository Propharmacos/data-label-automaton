

# Corrigir layout TIRZ — compactar e alinhar à esquerda

## Problema
O layout TIRZ usa `fixedLine` com zonas largas (REQ=18, CONSELHO=20 colunas) que empurram o texto para a direita, criando espaço vazio à esquerda e cortando informações. A foto de referência mostra que o estilo correto é compacto (como AMP_CX), com gap pequeno entre os campos esquerdo e direito.

Além disso, a UI limita o `lineSpacing` mínimo a `1.0`, mas o TIRZ precisa de `0.85` — o que significa que se o usuário mexer no controle, não consegue voltar abaixo de 1.0.

## Alterações técnicas

**Arquivo**: `src/components/LabelTextEditor.tsx`

### 1. Trocar `fixedLine` por `compactLine` no `generateTextTirz` (linhas 652-733)

Reescrever `generateTextTirz` para usar o mesmo padrão `compactLine` do AMP_CX em vez de zonas fixas:

- **Linha 1 (Paciente + REQ)**: `compactLine(cleanName, reqStr, 4)` em vez de `fixedLine(..., LEFT_L1, REQ_WIDTH)`
- **Linha 2 (DR(A) + Conselho)**: `compactLine(drName, conselhoStr, 3)`
- **Linha 3+ (Produto + Posologia)**: mantém `wrapText` atual (já funciona)
- **Linha meta (pH/L/F/V)**: usar `metaParts.join(' ')` compacto em vez de zonas de 1/4
- **Linha uso**: `compactLine(usoText, "AP:" + aplicacao, 3)` — usar `AP:` curto como no AMP_CX
- **Linha contém/REG**: `compactLine(contemStr, regStr, 3)`

### 2. Permitir lineSpacing menor que 1.0 para TIRZ (linha 1152)

Alterar o `Math.max(1.0, ...)` para `Math.max(0.7, ...)` quando o layout for TIRZ, permitindo compactação real via controle de UI.

### 3. Resultado esperado (conforme foto referência)

```text
VALDIR JOSE CALABRO    REQ:010337-0
DR(A)MARCO ANTONIO   CRM.SP-141260
TIRZEPATIDA 60MG/2,4ML   APLICAR
APLICAR 0,2ML VIA SC 1X POR SEMANA
DURANTE 12 SEMANAS
PH:7,5 L:521/25 F:12/25 V:12/26
USO EM CONSULTORIO   AP:SC
CONTEM:   REG:25538
```

Texto alinhado à esquerda, gap mínimo entre campos, sem desperdício de espaço.

