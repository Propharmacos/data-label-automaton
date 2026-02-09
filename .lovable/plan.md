

# Correcao da Renderizacao de KIT no Rotulo AMP.CX

## Problema
O rotulo de KIT esta quase correto apos a resolucao de sinonimos, porem faltam informacoes comparado com o sistema original do FormulaCerta. A imagem de referencia mostra o formato correto para Req 392-6806 -2.

## Diferencas Identificadas (referencia vs codigo atual)

Referencia do FormulaCerta:
```text
LENIE ANTONIA ALVES DE SOUZA    REQ:006806-2
DR(A)LENIE ANTONIA A.DE SOUZA    COREN-SP-826211
ACIDO HIALURONICO N RETIC. 5MG
pH:6,0  L:12012/25   F:12/25  V:12/26
ACIDO TRANEXAMICO 8MG, TGP2 20MG, BELIDES 2%
LIP. VIT C 10MG, NIACINAMIDA 40MG pH:6,5
L:329/25   F:11/25   V:05/26
USO EM CONSULTORIO  AP:MICROAGULHAMENTO
CONTEM: 4FR. DE 2ML   REG:15081
```

### Problemas encontrados:

1. **Fabricacao (F:) ausente nos componentes do kit** - O frontend (`renderKitContent`) exibe lote e validade mas NAO exibe a fabricacao de cada componente, embora o backend envie `comp.fabricacao`.

2. **pH dos componentes sempre vazio** - No backend (linha 3469), o pH e hardcoded como `""` com comentario "sera preenchido manualmente". A referencia mostra pH individual por componente (6,0 e 6,5).

3. **Tipo de Uso (USO EM CONSULTORIO) ausente** - O `renderKitContent` nao exibe o campo `tipoUso`, mas a referencia mostra na penultima linha.

4. **CONTEM ausente** - O `renderKitContent` nao exibe o campo `contem` ("4FR. DE 2ML"), mas a referencia mostra na ultima linha junto com REG.

5. **Formato AP: vs APLICACAO:** - A referencia usa "AP:MICROAGULHAMENTO" (abreviado na mesma linha do tipoUso), nao "APLICACAO:" em linha separada.

## Alteracoes Necessarias

### 1. Frontend: `src/components/LabelCard.tsx` - renderKitContent()

Adicionar os campos ausentes na renderizacao de KIT:
- Incluir `comp.fabricacao` (F:) na linha de cada componente
- Adicionar linha de `tipoUso` + `aplicacao` (formato: "USO EM CONSULTORIO  AP:MICROAGULHAMENTO")
- Adicionar `contem` na mesma linha do registro (formato: "CONTEM: 4FR. DE 2ML   REG:15081")

### 2. Frontend: `src/components/LabelCard.tsx` - generateKitText()

Atualizar o texto de edicao livre para incluir:
- Fabricacao na linha de metadados de cada componente
- tipoUso + aplicacao na mesma linha
- contem + registro na mesma linha

### 3. Backend: `servidor.py` - Mapeamento de componentes (linha 3469)

O pH esta hardcoded como vazio. Verificar se o `kit_expandido` ja traz pH dos componentes ou se e necessario buscar. Se o campo existir no backend, mapear corretamente em vez de forcar "".

## Detalhes Tecnicos

### LabelCard.tsx - renderKitContent (linhas 402-446)

Estrutura atual:
```
Prescritor
Paciente | REQ
---
Componente1 pH L: V:
Componente2 pH L: V:
---
APLICACAO: xxx
REG: xxx
```

Estrutura corrigida (conforme referencia):
```
Paciente | REQ
Prescritor
Componente1
pH:x,x  L:xxx  F:mm/aa  V:mm/aa
Componente2
pH:x,x  L:xxx  F:mm/aa  V:mm/aa
TIPO_USO  AP:xxx
CONTEM: xxx   REG:xxx
```

Mudancas especificas:
- Inverter ordem: Paciente primeiro, Prescritor segundo (conforme referencia)
- Separar nome do componente dos metadados (nome em uma linha, pH/L/F/V na linha seguinte)
- Adicionar `comp.fabricacao` com formato `F:mm/aa`
- Adicionar linha `tipoUso` + `AP:aplicacao` (juntos, sem "APLICACAO:", usar "AP:")
- Adicionar linha `CONTEM: xxx   REG:xxxxx` (juntos na mesma linha)

### servidor.py - pH dos componentes (linha 3469)

Verificar se `comp.get("ph", "")` existe nos dados do kit_expandido. Se nao existir no backend, manter vazio (editavel manualmente). Se existir, mapear corretamente.

