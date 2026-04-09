
## Diagnóstico

Pelo print, o problema agora não é mais “qual regra usar”, e sim **onde a regra está sendo perdida**.

Hoje o projeto já tem lógica para abreviar o médico no `A_PAC_PEQ`, mas o fluxo real é WYSIWYG:
- o `textoLivre` salvo/reutilizado continua tendo a linha antiga do `DR(A)`
- no `A_PAC_PEQ`, o preview pode manter esse texto já salvo
- no agente, quando chega `textoLivre`, ele imprime essa linha praticamente como veio

Resultado: mesmo com a função de abreviação existente, a linha do prescritor continua aparecendo como `DR(A)KAROLINY ADRIANA VIEI...` em vez de algo no padrão obrigatório, como:
```text
DR(A)KAROLINY VIEIRA COREN-SC-59418
```
ou, se precisar reduzir mais:
```text
DR(A)KAROLINY A. VIEIRA COREN-SC-59418
```

## O que vou ajustar

### 1. `src/components/LabelTextEditor.tsx` — forçar a linha 2 do A.PAC.PEQ
Vou ajustar a geração do `A_PAC_PEQ` para que a linha do prescritor siga obrigatoriamente esta regra:
- manter **primeiro nome inteiro**
- manter **último sobrenome inteiro**
- abreviar/remover apenas nomes do meio
- nunca deixar o final do nome “cortado no meio”

Também vou adicionar uma normalização específica para a linha 2 do `textoLivre` do `A_PAC_PEQ`, para que texto antigo/manual seja refeito nesse padrão ao abrir/editar.

### 2. `src/pages/Index.tsx` — invalidar texto salvo antigo do DR(A)
Hoje a restauração salva já valida a linha do paciente antes da `REQ`.  
Vou ampliar essa validação para a linha 2:
- se a linha `DR(A)` salva não respeitar o formato novo
- ou se o nome do prescritor estiver truncado em vez de abreviado
- o sistema vai **descartar esse texto salvo** e regenerar com a regra correta

Isso evita que o sistema continue reaproveitando uma linha velha quebrada.

### 3. `agente_impressao.py` — proteção final no modo `textoLivre`
Como o `A_PAC_PEQ` imprime em fluxo WYSIWYG, vou colocar uma barreira final no agente:
- detectar linha com `DR(A)`
- separar nome e conselho
- reaplicar a abreviação obrigatória do médico antes de enviar para a impressora

Assim, mesmo se escapar algum `textoLivre` antigo, a impressão ainda sai com:
- primeiro nome inteiro
- último sobrenome inteiro
- nomes do meio abreviados ou removidos
- sem truncar o sobrenome final

## Resultado esperado

No layout pequeno, a linha do prescritor vai sair no padrão obrigatório:
- primeiro nome inteiro
- último sobrenome inteiro
- sobrenomes do meio abreviados
- sem cortar o final do nome
- sem mexer no restante do layout

## Arquivos envolvidos

- `src/components/LabelTextEditor.tsx`
- `src/pages/Index.tsx`
- `agente_impressao.py`

## Detalhe técnico

A correção precisa acontecer em **3 camadas ao mesmo tempo** porque o sistema reutiliza `textoLivre`:
1. geração nova correta
2. descarte do texto salvo antigo
3. proteção final no agente

Se eu mexer só em uma dessas partes, o problema pode continuar aparecendo.
