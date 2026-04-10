

## Problema

No layout A.PAC.GRAN, a Linha 2 coloca 3 campos em posições X fixas:
- DR(A)Médico em X=12
- Conselho em X=159
- REG em X=223

Com Font 1 (~8 dots por caractere), "CREFITO-SP-104835" ocupa ~136 dots. Começando em X=159, vai até X=295 — mas REG começa em X=223. Resultado: o conselho longo invade fisicamente o REG, causando o borrão/sobreposição que aparece no print.

O mesmo acontece no modo `textoLivre`: o agente extrai conselho e REG do texto e os ancora nas mesmas posições fixas que não cabem um CREFITO longo.

## Solução

Tornar a posição do REG **dinâmica** no agente: em vez de fixar x_reg=223, calcular a posição de REG com base no comprimento real do conselho. Assim, se o conselho for longo (CREFITO), o REG se desloca para a direita automaticamente, sem sobreposição.

No frontend o problema não ocorre visualmente porque ele já combina conselho+REG como texto corrido na mesma zona. A correção é exclusivamente no agente.

## Ajustes

### 1. `agente_impressao.py` — `gerar_ppla_a_pac_gran` (modo estruturado, ~linha 901-906)

Substituir `x_reg = 223` fixo por cálculo dinâmico:
```python
# Calcular x_reg baseado no comprimento real do conselho
CHAR_WIDTH = 8  # Font 1 approx width in dots
if crm:
    x_reg_calc = x_crm + (len(crm) + 1) * CHAR_WIDTH  # +1 char de espaço
else:
    x_reg_calc = x_reg  # fallback
```

### 2. `agente_impressao.py` — `gerar_ppla_a_pac_gran` (modo textoLivre, ~linha 862-879)

Mesma lógica: quando extrai `crm_part` do texto, calcular x_reg dinamicamente:
```python
if crm_part:
    x_reg_calc = x_crm + (len(crm_part) + 1) * CHAR_WIDTH
else:
    x_reg_calc = x_reg
```

### 3. Definir `x_reg` como valor padrão/fallback no topo, não como posição mandatória

Manter `x_reg = 223` apenas como fallback quando não há conselho. O valor real será sempre calculado.

## Resultado esperado

```
JESSICA FERRETTI TISANO                    REQ:009752-4
DR(A)FERNANDA FERNANDES PEREIRA CREFITO-SP-104835 REG:24297
```

Cada campo com espaço próprio, sem sobreposição física.

## Arquivos

- `agente_impressao.py` (único arquivo alterado)

