

# Tornar A.PAC.PEQ WYSIWYG (igual ao AMP10)

## Problema

Quando você edita o texto no layout A.PAC.PEQ e imprime, o agente **re-processa** o texto: re-abrevia nomes, re-posiciona REQ/REG em coordenadas fixas. Isso faz com que a etiqueta impressa saia diferente do que você vê na tela.

Os outros layouts (A_PAC_GRAN, AMP_CX, TIRZ) já imprimem literalmente — o problema é só no A_PAC_PEQ.

## Correção

### `agente_impressao.py` — Substituir o handler de textoLivre do A_PAC_PEQ

Linhas 898-958: trocar a lógica que re-parseia REQ/DR(A)/REG por impressão literal linha-a-linha (igual ao A_PAC_GRAN faz nas linhas 1034-1047):

```python
texto_livre = rotulo.get('textoLivre', '')
if texto_livre:
    lsf = float(rotulo.get('lineSpacingFactor', 1.0) or 1.0)
    linhas_texto = texto_livre.split('\n')
    pplb_lines = []
    y_positions_calc = list(y_positions)
    if lsf != 1.0 and len(y_positions_calc) >= 2:
        base_y = y_positions_calc[0]
        step = y_positions_calc[1] - y_positions_calc[0]
        for i in range(1, len(y_positions_calc)):
            y_positions_calc[i] = base_y + int(step * lsf * i)

    visible_idx = 0
    for line_text in linhas_texto:
        stripped = line_text.strip()
        if not stripped:
            continue
        y = y_positions_calc[visible_idx] if visible_idx < len(y_positions_calc) else y_positions_calc[-1]
        # WYSIWYG: imprimir literal, sem re-parsear/re-abreviar
        pplb_lines.append(ppla_text_dots(rot, font, wmult, hmult, y, x_paciente, stripped[:cols]))
        visible_idx += 1
    if not pplb_lines:
        pplb_lines.append(ppla_text_dots(rot, font, wmult, hmult, y_positions[0], x_paciente, 'SEM DADOS'))
    return _build_label_ppla(pplb_lines, cal)
```

Cada linha do editor será impressa exatamente como está, na posição X=12 (esquerda), sem re-parsear REQ:/DR(A)/REG: nem re-abreviar nomes.

## O que NÃO muda
- Coordenadas, fontes, dimensões do layout (tudo travado)
- Geração estruturada (quando não há textoLivre) continua igual
- Salvamento/restauração (já corrigido anteriormente)
- Outros layouts (já são WYSIWYG)

## Resultado esperado
Ao editar o texto no A.PAC.PEQ e imprimir, a etiqueta sairá exatamente como aparece na tela — igual ao comportamento do AMP10.

