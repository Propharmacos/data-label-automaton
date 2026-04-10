

## Problema

A linha do **paciente** no A.PAC.PEQ está usando `abbreviateName` que, quando o nome não cabe em 20 caracteres, simplesmente **descarta todos os nomes do meio**, resultando em:
```
ADRIANA OLIVEIRA          REQ:9750-0
```

O usuário quer ver o mesmo padrão de abreviação com iniciais:
```
ADRIANA A.D.C. OLIVEIRA   REQ:9750-0
```

## Causa raiz

- Linha 207-208 em `LabelTextEditor.tsx`: `pacienteMax = Math.min(..., 20)` e usa `abbreviateName` (que descarta middle names)
- Linha 734 em `agente_impressao.py`: `MAX_PAT_CHARS = 20` e faz truncamento simples

O limite de 20 chars é muito apertado para caber iniciais. "ADRIANA A.D.C. OLIVEIRA" = 23 chars. Precisa subir para ~25.

## Ajustes

### 1. `src/components/LabelTextEditor.tsx` — Paciente com abreviação estrita
- Linha 207: aumentar limite de `20` para `25`
- Linha 208: trocar `abbreviateName` por `abbreviateNameStrict` para o paciente
- Resultado: iniciais dos nomes do meio são preservadas em vez de descartadas

### 2. `agente_impressao.py` — Aumentar limite e aplicar abreviação no paciente
- Linha 734: `MAX_PAT_CHARS = 20` → `MAX_PAT_CHARS = 25`
- Aplicar `_abbreviate_name` no `patient_part` antes de imprimir (barreira final)

### 3. `src/pages/Index.tsx` — Invalidar textos salvos antigos
- Ajustar a validação para descartar `textoLivre` salvo onde o paciente use o formato antigo (sem iniciais)

## Resultado esperado
```
ADRIANA A.D.C. OLIVEIRA   REQ:9750-0
DR(A)ADRIANA A.D.C.OLIVEIRA CRM-RJ-4651
                           REG:24206
```

Primeiro e último nome inteiros, nomes do meio como iniciais, tanto no paciente quanto no médico.

