

## Diagnóstico

Na foto impressa do A.PAC.PEQ:
- **Linha 1**: "NATHALIA VERISSIMO CARNA**REQ**:9743-0" — o nome do paciente sobrepõe o campo REQ
- **Linha 2**: "DR(A)NATHALIA VERISSIMO CARN" — nome truncado em 28 caracteres

**Causa raiz**: O frontend gera texto com 41 colunas, mas o agente coloca o paciente em X=12 e o REQ em X=116 (coordenadas físicas fixas em dots). O espaço físico entre X=12 e X=116 só comporta ~20 caracteres — não os 30 que o frontend está permitindo. Além disso, o agente trunca campos em `cols_max=28` (config PEQUEN), cortando o nome do médico na linha 2.

**Problema duplo**:
1. Paciente: frontend permite ~30 chars, mas fisicamente só cabem ~20 antes do REQ
2. Médico: agente trunca em 28 chars, mas a linha 2 não tem campo à direita no agente (DR+CRM ficam juntos), então poderia usar mais espaço

## Plano

### 1. `agente_impressao.py` — Atualizar cols_max e adicionar limite de paciente

Na config `PRINTER_CONFIGS['PEQUEN']` (linha 59):
- Aumentar `cols_max` de 28 para **41** (para campos que usam a largura total, como médico na linha 2)

Na função `gerar_ppla_a_pac_peq` (linha 699-711):
- Adicionar constante `MAX_PAT_CHARS = 20` — limite físico do paciente antes de X=116
- Truncar `patient_part` com `[:MAX_PAT_CHARS]` em vez de `[:cols]`

### 2. `src/components/LabelTextEditor.tsx` — Limitar paciente no frontend

Na função `generateTextPacPeq` (linha 165):
- Calcular `pacienteMax` como `Math.min(maxCols - req.length - 1, 20)` — garante que o preview mostre o mesmo que a impressão física
- O médico continua usando `maxCols` normalmente (sem limite extra)

### Nenhuma alteração de layout
Linhas, dimensões, coordenadas Y e estrutura permanecem intactos.

