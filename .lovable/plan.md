
Diagnóstico objetivo:

O motivo de “não ter mudado nada” muito provavelmente é uma combinação de 3 pontos:

1. O A.PAC.GRAN ainda pode estar imprimindo em FC Direto
- Em `src/config/api.ts`, o modo padrão é `rotutx`
- Em `src/pages/Index.tsx`, só o `A_PAC_PEQ` é forçado para `agente`
- Então, se você imprimiu em `FC Direto`, a mudança feita no `agente_impressao.py` foi ignorada completamente

2. A correção anterior mexeu só no `REG:`
- Em `agente_impressao.py`, no `A_PAC_GRAN`, o `REG` ficou dinâmico
- Mas `REQ` e `conselho` continuam presos em âncoras fixas muito à esquerda (`x_req=172`, `x_crm=159`)
- O seu print mostra exatamente isso: sobra espaço à direita da etiqueta, mas os campos da direita continuam “apertados” no meio

3. O texto salvo antigo ainda pode estar sendo reutilizado
- Em `src/pages/Index.tsx`, o descarte automático de `textoLivre` existe só para `A_PAC_PEQ`
- Para `A_PAC_GRAN`, o sistema ainda pode restaurar texto velho e manter espaçamentos antigos

Solução que eu vou aplicar:

1. Forçar `A_PAC_GRAN` a imprimir via Agente
- Ajustar `src/pages/Index.tsx` para que `A_PAC_GRAN`, assim como `A_PAC_PEQ`, use sempre `agente`
- Isso garante que as correções de posicionamento entrem de fato na impressão

2. Reposicionar todo o bloco da direita no `A_PAC_GRAN`
- Em `agente_impressao.py`, parar de usar as âncoras antigas como posição “final”
- Calcular a posição real a partir da largura da etiqueta (`largura_dots`)
- Linha 1: ancorar `REQ` pela borda direita
- Linha 2: tratar `conselho + REG` como bloco da direita, alinhado mais para a direita
- Manter o médico na esquerda
- Se houver risco de colisão, reduzir apenas a área do médico, não empurrar o bloco direito para dentro

3. Remover abreviação desnecessária no A.PAC.GRAN
- Em `src/components/LabelTextEditor.tsx`, parar de abreviar o médico nesse layout
- Usar nome completo e só cortar se ultrapassar a zona útil real
- O frontend precisa refletir a mesma regra da impressão

4. Invalidar `textoLivre` antigo do A.PAC.GRAN
- Em `src/pages/Index.tsx`, fazer o mesmo tratamento já usado no `A_PAC_PEQ`
- Se o layout for `A_PAC_GRAN`, descartar texto salvo legado e regenerar com a nova regra
- Isso evita a sensação de “mudou no código, mas continua igual”

5. Sincronizar preview e impressão
- Ajustar `generateTextPacGran()` para espelhar a nova divisão física:
  - paciente | REQ ancorado à direita
  - médico | conselho + REG ancorados à direita
- Assim, o que você vê no editor fica coerente com a etiqueta real

Resultado esperado:
- o `REQ` vai mais para a direita
- o `CREFITO-SP-...` não vai mais esmagar o `REG`
- o layout vai usar o espaço em branco que hoje está sobrando
- o A.PAC.GRAN não vai abreviar à toa
- a mudança finalmente vai aparecer na impressão real, porque deixará de passar pelo `FC Direto`

Arquivos que precisam ser ajustados:
- `src/pages/Index.tsx`
- `src/components/LabelTextEditor.tsx`
- `agente_impressao.py`

Detalhe técnico importante:
Hoje o problema principal não parece ser “falta de espaço físico”, e sim “âncoras erradas + fluxo errado de impressão”. O seu print confirma isso: existe área livre na etiqueta, mas os campos continuam sendo posicionados como se a largura útil acabasse antes. A correção certa agora é reposicionar o bloco direito inteiro e garantir que o A.PAC.GRAN passe pelo agente para essas regras valerem.
