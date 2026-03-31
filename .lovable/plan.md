

## Plano: 3 Alterações — Impressoras, Botão Salvar e Espaçamento na Impressão

### 1. Atualizar mapeamento TIRZ → AMP PEQUENA NOVA

**Arquivo:** `src/config/api.ts`

O mapeamento dos outros 4 layouts já está correto. Apenas o TIRZ precisa mudar de `'PEQUENO'` para `'AMP PEQUENA NOVA'`.

---

### 2. Botão SALVAR para preservar edições manuais dos rótulos

**Problema:** Na linha 72 do `Index.tsx`, `resetAllLayouts()` é chamado toda vez que a página carrega, apagando qualquer edição manual. Além disso, o `textoLivre` editado pelo operador não é salvo em lugar nenhum — se ele navegar ou recarregar a página, perde tudo.

**Solução:**
- **Remover** a chamada `resetAllLayouts()` do `useEffect` no `Index.tsx` (linha 72), para que edições de layout persistam.
- **Adicionar um botão "Salvar"** no `LabelTextEditor.tsx` (no header, ao lado dos controles existentes) que salva o `textoLivre` de **todos** os rótulos da requisição atual no `localStorage`, usando a chave `saved_rotulos_{nrRequisicao}`.
- Ao buscar uma requisição, **verificar** se há dados salvos no localStorage para aquela requisição e restaurá-los automaticamente, preservando as edições do operador.

**Arquivos:** `src/pages/Index.tsx`, `src/components/LabelTextEditor.tsx`

---

### 3. Espaçamento entre linhas (1.0 +/−) afetar a impressão real

**Problema:** O controle de espaçamento (lineSpacing) hoje só muda o CSS visual no preview. Não tem nenhum efeito na impressão física.

**Solução:**
- **Frontend:** Incluir o valor `lineSpacing` no payload enviado ao agente (campo `lineSpacingFactor`), junto com `yOffsetDots`.
- **Agente (`agente_impressao.py`):** Ler `lineSpacingFactor` do rótulo e multiplicar o espaçamento entre coordenadas Y por esse fator. Ex: se o espaçamento padrão entre linhas é 11 dots e o fator é 1.2, o espaçamento passa a ser 13 dots.

**Arquivos:** `src/pages/Index.tsx`, `src/services/printAgentService.ts`, `agente_impressao.py`

---

### Resumo de arquivos alterados
- `src/config/api.ts` — TIRZ → AMP PEQUENA NOVA
- `src/pages/Index.tsx` — remover resetAllLayouts, carregar edições salvas, enviar lineSpacing
- `src/components/LabelTextEditor.tsx` — botão Salvar
- `src/services/printAgentService.ts` — incluir lineSpacingFactor no payload
- `agente_impressao.py` — aplicar fator de espaçamento nas coordenadas Y

