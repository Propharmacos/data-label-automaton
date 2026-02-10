

## Correção: Rótulos Saindo Separados (Pulando Etiquetas)

### Causa Raiz Identificada

O problema principal esta no `agente_impressao.py`, na funcao `imprimir()`. Atualmente, para cada rotulo no array, o agente:

1. Abre a impressora (`OpenPrinter`)
2. Inicia um documento (`StartDocPrinter`)
3. Envia os comandos PPLB
4. Fecha o documento (`EndDocPrinter`)
5. Fecha a impressora (`ClosePrinter`)

Isso significa que se voce seleciona 4 rotulos, a impressora recebe **4 trabalhos de impressao separados**. Entre cada trabalho, a Argox OS-2140 recalibra o sensor de gap, avanca o papel e reposiciona -- causando o "pulo" entre etiquetas.

### Solucao

Concatenar todos os comandos PPLB em uma unica string e enviar tudo em **um unico trabalho de impressao**. Cada bloco PPLB ja contem seu proprio comando `E` (fim/imprimir), entao a impressora processa cada etiqueta sequencialmente dentro do mesmo job sem recalibrar.

### Alteracoes no `agente_impressao.py`

**Funcao `imprimir()` -- logica de envio:**

Antes (problematico):
```text
para cada rotulo:
    gerar comandos PPLB
    abrir impressora
    enviar comandos
    fechar impressora
```

Depois (corrigido):
```text
comandos_todos = ""
para cada rotulo:
    gerar comandos PPLB
    concatenar em comandos_todos
abrir impressora UMA VEZ
enviar comandos_todos
fechar impressora UMA VEZ
```

### Detalhes tecnicos

- A funcao `enviar_para_impressora` continua igual, mas recebe a string concatenada de todos os rotulos
- Cada bloco PPLB individual ja possui `\x02L` (inicio) e `E` (fim), garantindo que a impressora interpreta cada etiqueta corretamente
- O encoding `cp850` e o modo `RAW` permanecem inalterados
- A contagem de `impressos` sera ajustada para refletir o total enviado no batch

### Resultado esperado

- Todos os rotulos saem em sequencia sem pulos
- A quantidade de copias (ex: 2x) funciona corretamente pois o frontend ja duplica os rotulos no array
- A impressora nao recalibra entre etiquetas

