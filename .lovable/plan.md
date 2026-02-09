

# Padronizacao Visual dos Rotulos - Layout Identico aos Prints

## Problemas Identificados

1. **Kit Sinonimo (6806-2)**: APLICACAO de cada componente nao aparece no rotulo
2. **Formatacao inconsistente**: Textos com negrito, tamanhos diferentes de fonte, font-semibold nos nomes de componentes
3. **Layouts nao correspondem aos prints de referencia**: A estrutura atual dos layouts diverge do padrao visual do Formula Certa

## Referencia Visual (dos prints enviados)

### AMP_CX (Ampola Caixa) - Print 311
```
PACIENTE                    REQ:006827-0
DR(A)NOME MEDICO  CONSELHO-UF-NUMERO
FORMULA OU COMPOSICAO
pH:5,0  L:289/25  F:11/25  V:11/26
USO EM CONSULTORIO    APLICACAO:IM
CONTEM:10FR. DE 1ML    REG:15136
```

### AMP10 (Ampola 10) - Print 311
```
PACIENTE                    REQ:006788-0
DR(A)NOME  CONSELHO-UF-NUMERO
COMPOSICAO ITEM 1
pH:7,0 L:12042/26 F:01/26 V:01/27
COMPOSICAO ITEM 2              REG:15010
pH:7,0 L:333/25 F:11/25 V:11/26  AP:SC SUPERFICIAL
USO EM CONSULTORIO/ 2 SERINGAS DE 1ML E 2FR DE 2ML
```

### A.PAC.PEQ - Print 311
```
PACIENTE REQ:006788-0
DR(A)NOME CONSELHO-UF-NUMERO
                       REG:15010
```

### A.PAC.GRAN - Print 311
```
PACIENTE REQ:006788-0
DR(A)NOME CONSELHO-UF-NUMERO REG:15010
```

### TIRZ (Tirzepatida) - Print 311
```
PACIENTE                    REQ:006801-0
DR(A)NOME  CONSELHO-UF-NUMERO
TIRZEPATIDA 30MG/1,2ML
APLICAR 5MG POR SEMANA
pH:7,5  L:522/25  F:12/25  V:12/26
USO EM CONSULTORIO    APLICACAO:SC
CONTEM:1FR. DE 1,2ML  REG:15061
```

### Kit Normal (6806-3) - Print 310
```
PACIENTE                    REQ:006806-3
DR(A)NOME  CONSELHO-UF-NUMERO
COMPONENTE1 DOSE pH:X L:XXX/XX F:XX/XX V:XX/XX
COMPONENTE2 DOSE pH:X L:XXX/XX F:XX/XX V:XX/XX
...
USO EM CONSULTORIO    APLICACAO: ID
CONTEM:1KIT C/5FR. DE 2ML   REG:15082
```

### Kit Sinonimo (6806-2) - Esperado
```
PACIENTE                    REQ:6806-2
DR(A)NOME  CONSELHO-UF-NUMERO
COMPOSICAO_OBSFIC_COMP1
L:12012 F:12/25 V:12/26
COMPOSICAO_OBSFIC_COMP2
L:705 F:01/26 V:01/27
USO EM CONSULTORIO   APLICACAO:MICROAGULHAMENTO
CONTEM:XXX   REG:15079
```

## Plano de Alteracoes

### 1. Layouts (`src/config/layouts.ts`)

Remover TODOS os `bold: true` de TODOS os layouts. Uniformizar fontSize para `9` em todos os campos de todos os layouts (exceto onde os prints mostram tamanho diferenciado, que nao e o caso - tudo igual).

Campos afetados:
- `paciente`: remover `bold: true`, fontSize `9`
- `formula`: remover `bold: true`, fontSize `9`
- `aplicacao`: remover `bold: true`, fontSize `9`
- `posologia`: remover `bold: true`, fontSize `9`

Isso se aplica a AMP_CX, AMP10, A_PAC_PEQ, A_PAC_GRAN e TIRZ.

### 2. Renderizacao de KIT (`src/components/LabelCard.tsx`)

#### renderKitContent():
- Remover `font-bold` do nome do paciente (linha 429)
- Remover `font-semibold` dos nomes de componentes (linha 439)
- Uniformizar todos os textos para `text-[9px]` sem decoracao
- Garantir que `comp.aplicacao` seja exibido com prefixo `APLICACAO:` na linha de metadados de cada componente

#### renderCompactContent():
- Remover `font-bold` do paciente (linha 492)

#### Layout baseado em linhas (expandido):
- Garantir que a renderizacao respeite `bold: false` dos configs atualizados

### 3. Prescritor - formato DR(A) (`src/components/LabelCard.tsx`)

Os prints de referencia usam `DR(A)` em vez de `DR.`/`DRA.`, e o formato do conselho e `CONSELHO-UF-NUMERO` (ex: `COREN-SP-826211`) em vez de `CONSELHO NUMERO/UF`.

Atualizar `formatarPrescritor()` para:
- Usar `DR(A)` como prefixo universal
- Formato: `DR(A)NOME  CONSELHO-UF-NUMERO`

### 4. Formato do Lote nos Kits

Os prints mostram lote no formato `L:585/26` (lote/ano). Atualizar a renderizacao dos componentes de kit para incluir o ano no lote, usando o mesmo `formatarLote` pattern.

## Detalhes Tecnicos

### Arquivos modificados:
- `src/config/layouts.ts` - Remover bold e uniformizar fontSize em todos os 5 layouts
- `src/components/LabelCard.tsx` - Remover estilos de negrito, atualizar formato do prescritor, uniformizar tamanho de fonte

### Nao modificar:
- `servidor.py` - A logica de extracao ja foi corrigida na versao anterior
- `src/types/requisicao.ts` - O campo `aplicacao` em ComponenteKit ja existe
- `src/services/requisicaoService.ts` - O mapeamento ja existe

