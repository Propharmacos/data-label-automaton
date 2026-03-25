

## Plano: Atualizar gerador AMP10 no agente para paridade FC

### Análise do exemplo FC capturado

```text
Setup: f289 / L / e / PA / D11 / H14
Prefixo texto: 1111 (Rot=1, Font=1, W=1, H=1)

Coordenadas (dots):
  Linha 1: Y=78, X=21  → Paciente + REQ
  Linha 2: Y=67, X=21  → DR(A) + Conselho
  Linha 3: Y=56, X=21  → Componente 1 (pH, L, F, V)
  Linha 4: Y=45, X=21  → Componente 2
  Linha 5: Y=34, X=21  → Componente 3
  Linha 6: Y=23, X=21  → Componente 4
  Linha 7: Y=12, X=4   → Componente 5
  Linha 8: Y=1,  X=4   → Componente 6
  Linha 9: Y=-9, X=4   → Uso/Aplicação/REG
Fim: Q0001E
```

### Problemas no agente atual

1. **Font/Rotação**: Usa valores da calibração (font=2, rot=0) em vez de forçar font=1, rot=1
2. **Coordenadas Y**: Usa 0.1mm [350,310,270...] em vez de dots FC [78,67,56,45,34,23,12,1,-9]
3. **Coordenadas X**: Usa x=10/400 genéricos em vez de x=21 (linhas 1-6) e x=4 (linhas 7-9)
4. **Setup**: Usa `_build_label` genérico em vez do setup FC exato (f289, L, e, PA, D11, H14)
5. **Y negativo**: `ppla_text_dots` com `f"{-9:07d}"` gera `-000009` mas FC gera `00000-9`
6. **Componentes de kit**: Não renderiza cada componente em linha separada com pH/L/F/V individuais
7. **Dados**: Frontend não envia `componentes[]` para o agente (falta no payload)

### Alterações

**1. `agente_impressao.py` — Função `ppla_text_dots` (linha 193)**
- Corrigir formatação de Y negativo para match FC: `str(y).rjust(7, '0')` para positivos, formato `00000-9` para negativos

**2. `agente_impressao.py` — Nova função `_build_label_amp10`**
- Setup FC exato: f289, L, e, PA, D11, H14 (igual ao `_build_label_ampcx` mas com f289)

**3. `agente_impressao.py` — Reescrever `gerar_ppla_amp10` (linhas 414-455)**
- Font=1, Rot=1 (forçados, como PEQ e GRAN)
- Y dots: [78, 67, 56, 45, 34, 23, 12, 1, -9] (9 níveis)
- X dots: 21 (linhas 1-6), 4 (linhas 7-9)
- Modo dots forçado
- Para KITs: renderizar cada componente em linha separada com formato `NOME pH:X,X L:XXX/XX F:XX/XX V:XX/XX`
- Para não-KIT: composição + dados na estrutura tradicional
- Linha 1: `PACIENTE REQ:XXXXXX-N`
- Linha 2: `DR(A)NOME CONSELHO-UF-NUMERO`
- Linhas 3-8: Componentes individuais (kit) ou composição + metadados (não-kit)
- Linha 9: `USO/ APLICACAO REG:XXXXX`

**4. `agente_impressao.py` — Atualizar `PRINTER_CONFIGS['AMP10']`**
- Corrigir `font: 1` (era 2)
- Adicionar `form_length: 289`

**5. `src/services/printAgentService.ts` — `imprimirViaAgente` (linha 301)**
- Incluir `componentes` no payload enviado ao agente para que kits funcionem

**6. `agente_impressao.py` — Formatação Y negativo**
- Criar helper `_format_y_dots(y)` que gera o formato FC correto:
  - `y >= 0` → `f"{y:07d}"` (ex: `0000078`)
  - `y < 0` → `f"-{abs(y)}".rjust(7, '0')` (ex: `00000-9`)
- Usar este helper em `ppla_text_dots`

### Resultado esperado

O AMP10 gerará PPLA byte-a-byte idêntico ao FC capturado, com suporte a kits (cada componente em linha separada com seus dados individuais).

### Arquivos alterados
- `agente_impressao.py` — Reescrever gerador AMP10, fix Y negativo, novo setup
- `src/services/printAgentService.ts` — Incluir `componentes` no payload

