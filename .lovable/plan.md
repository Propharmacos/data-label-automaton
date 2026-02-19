

## Corrigir Parser ROTUTX: Apenas 1 Linha Sendo Extraida

### Problema

A funcao `parse_rotutx` no `servidor.py` (linha 4719) esta filtrando quase todas as linhas do ROTUTX. Ela exige:
1. Linha com pelo menos 25 caracteres
2. Pelo menos 6 partes separadas por espaco
3. A primeira parte deve ser um numero (line_num)
4. A terceira parte deve ser um numero (width)
5. O texto util e assumido como estando na posicao parts[5]

Essas regras sao baseadas em uma suposicao do formato interno do Formula Certa: `NNNN PPPP WWWW XXXX YYYY texto`. Na pratica, a maioria das linhas do ROTUTX nao segue esse formato rigido, entao sao descartadas. Apenas a linha com "RESVERATROL 0,5%" por coincidencia tem partes suficientes para passar no filtro.

### Solucao

Reescrever `parse_rotutx` para ser muito mais permissiva:

1. Remover o filtro de 25 caracteres minimos - aceitar linhas com 3+ caracteres
2. Primeiro tentar o parse estruturado (6 partes com numeros nas posicoes esperadas)
3. Se falhar, extrair o texto inteiro da linha como conteudo util
4. Filtrar apenas linhas que sao claramente nao-texto (linhas so com numeros, linhas vazias, caracteres de controle)

### Mudancas Tecnicas

**1. `servidor.py` - Funcao `parse_rotutx` (linhas 4719-4746)**

Reescrever para:
- Aceitar linhas com 3+ caracteres (em vez de 25)
- Tentar parse estruturado (formato NNNN PPPP WWWW XXXX YYYY texto)
- Se nao bater no formato estruturado, usar a linha inteira como texto
- Atribuir line_num sequencial para linhas sem numero explicito
- Filtrar linhas que contenham apenas numeros/espacos (metadados puros)
- Logar quantas linhas foram extraidas por cada metodo (estruturado vs texto puro) para debug

```python
def parse_rotutx(data: bytes) -> list:
    try:
        text = data.decode('latin-1')
    except Exception:
        text = data.decode('cp1252', errors='replace')

    results = []
    raw_lines = text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    seq = 0

    for raw_line in raw_lines:
        raw_line = raw_line.strip()
        if len(raw_line) < 3:
            continue

        # Tentar parse estruturado: NNNN PPPP WWWW XXXX YYYY texto
        parts = raw_line.split(None, 5)
        if len(parts) >= 6:
            try:
                line_num = int(parts[0])
                width = int(parts[2])
                text_content = parts[5].strip()
                if text_content:
                    results.append({
                        'line_num': line_num,
                        'width': width,
                        'text': text_content
                    })
                    continue
            except (ValueError, IndexError):
                pass

        # Fallback: usar linha inteira como texto
        # Ignorar linhas que sao so numeros/espacos
        cleaned = raw_line.strip()
        if cleaned and not cleaned.replace(' ', '').replace('.', '').isdigit():
            seq += 1
            results.append({
                'line_num': seq * 100,
                'width': len(cleaned),
                'text': cleaned
            })

    results.sort(key=lambda x: x['line_num'])
    return results
```

**2. `servidor.py` - Endpoint `/api/imprimir-fc-v2` (linha 4784)**

Adicionar log mais detalhado mostrando quantas linhas foram extraidas e quais sao, para facilitar debug futuro:

```python
print(f"[IMPRIMIR-FC-V2] REQ={nr_requisicao} -> {len(linhas_parsed)} linhas extraidas do ROTUTX ({len(rotutx_bytes)} bytes):")
```

### Resultado Esperado

- Todas as linhas de texto do ROTUTX serao extraidas (paciente, medico, formula, lote, validade, etc.)
- Nao apenas "RESVERATROL 0,5%" mas todos os campos do rotulo
- O agente recebera todas as linhas e gerara um PPLA completo com todas as informacoes
- A etiqueta saira com todas as informacoes do rotulo, nao apenas o nome do produto
