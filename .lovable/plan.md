

## Atualizar Layout A_PAC_PEQ para Paridade com Formula Certa

### Objetivo
Ajustar a configuracao do rotulo A.PAC.PEQ (45x25mm) para seguir exatamente o template de referencia do Formula Certa, com 3 linhas de conteudo e grade de 8 linhas disponiveis.

### Template de Referencia (Print 1)

```text
L1: PPPPPPPPPPPPPPPPPPPPPPPPP REQ:RRRRRRR
L2: DR(A)MMMMMMMMMMMMMMMM ÇÇÇÇÇÇÇÇÇÇÇÇÇÇÇ
L3:                          REG:GGGGGGGG
L4-L8: (vazias, disponiveis para edicao)
```

Onde:
- P (25 chars) = Nome do paciente (variavel do banco)
- R (7 chars) = Numero da requisicao (variavel do banco)
- M (16 chars) = Nome do prescritor (variavel do banco)
- C (15 chars) = Registro do conselho do prescritor (variavel do banco)
- G (8 chars) = Codigo de registro (variavel do banco)

### Alteracoes

#### 1. `src/config/layouts.ts` - Configuracao do layout A_PAC_PEQ

- Alterar `linhasMax` de `3` para `8` (conforme barra de status do Formula Certa: "Lin: 4/8")
- Manter `colunasMax` adequado ao template (a linha mais longa tem ~38 chars, manter `38`)
- Manter `dimensoes` iguais (45x25mm)
- Ajustar as linhas para incluir os campos corretos:
  - Linha 1: `paciente` + `requisicao`
  - Linha 2: `medico` + `registro` (conselho do prescritor -- sera o campo existente reutilizado)
  - Linha 3: `registro` (REG: alinhado a direita)
- Tornar visiveis apenas: `paciente`, `requisicao`, `medico`, `registro`
- Os demais campos permanecem `visible: false`

#### 2. `src/components/LabelTextEditor.tsx` - Gerador de texto `generateTextPacPeq`

Atualizar a funcao para respeitar os limites de caracteres do template:

- **Linha 1**: Nome do paciente truncado em 25 caracteres + espaco + `REQ:` + numero requisicao truncado em 7 caracteres, alinhados com `padLine`
- **Linha 2**: `DR(A)` + nome do medico truncado em 16 caracteres + espaco + conselho truncado em 15 caracteres, alinhados com `padLine`
- **Linha 3**: `REG:` + registro truncado em 8 caracteres, alinhado a direita
- **Linhas 4-8**: Vazias (disponiveis para edicao manual pelo usuario)

#### 3. Comportamento no editor

- O editor ja suporta `truncateText` para A_PAC_PEQ -- isso permanece
- A barra de status mostrara `Lin: X/8 Col: Y/38`
- O usuario podera editar manualmente o conteudo das 8 linhas

### Detalhes Tecnicos

**Arquivos modificados:**
- `src/config/layouts.ts` (linhas ~100-130): Atualizar bloco `A_PAC_PEQ` com `linhasMax: 8` e campos visiveis corretos
- `src/components/LabelTextEditor.tsx` (linhas ~108-143): Reescrever `generateTextPacPeq` com truncamento por campo e 8 linhas de saida

**Campos e limites de caracteres:**

| Campo | Variavel | Max Chars | Posicao |
|-------|----------|-----------|---------|
| Paciente | nomePaciente | 25 | L1, esquerda |
| Requisicao | nrRequisicao-nrItem | 7 | L1, direita (REQ:) |
| Prescritor | nomeMedico | 16 | L2, esquerda (DR(A)) |
| Conselho | prefixoCRM+ufCRM+numeroCRM | 15 | L2, direita |
| Registro | numeroRegistro | 8 | L3, direita (REG:) |

