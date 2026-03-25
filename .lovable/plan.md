

## Plano: Mapeamento automático Layout → Impressora + Estação

### Contexto
O mecanismo de auto-seleção já existe (`getLayoutPrinter` / `setLayoutPrinter`), mas começa vazio — o operador precisa selecionar manualmente a impressora para cada layout na primeira vez. Precisamos de **defaults hardcoded** que reflitam a realidade física.

### Mapeamento físico real

```text
Layout       → Impressora    → Estação
─────────────────────────────────────────
A_PAC_PEQ    → (pequena Edi) → PC da Edi
A_PAC_GRAN   → (grande Edi)  → PC da Edi
AMP_CX       → (caixa Dan)   → PC do Daniel
AMP10        → (amp10 Dan)   → PC do Daniel
TIRZ         → (caixa Dan?)  → PC do Daniel
```

**Preciso confirmar com você**: quais são os **nomes exatos** das impressoras que aparecem quando o agente lista? (ex: "AMP GRANDE", "PEQUENO", "argox01", etc.). Sem esses nomes exatos, não consigo pré-configurar o mapeamento corretamente.

### O que será feito (após confirmação dos nomes)

1. **Defaults no `api.ts`** — Definir um `DEFAULT_LAYOUT_PRINTER_MAP` com os nomes corretos para que `getLayoutPrinterMap()` retorne os defaults quando o localStorage está vazio

2. **Auto-switch de estação** — Quando o operador selecionar um layout no dashboard, além de trocar a impressora, trocar automaticamente a **estação ativa** (ex: selecionar A_PAC_PEQ → ativar "PC da Edi"; selecionar AMP_CX → ativar "PC do Daniel")

3. **Mapeamento layout → estação** no `api.ts`:
   - Nova constante `DEFAULT_LAYOUT_STATION_MAP` com layout→station_id
   - Nova função `getLayoutStation(layout)` que retorna o station_id correto

4. **Atualizar `handleLayoutChange` em `Index.tsx`** — Após trocar layout, também chamar `setActiveStationId()` para a estação correta, atualizando a URL do agente automaticamente

### Arquivos alterados
- `src/config/api.ts` — defaults de mapeamento layout→impressora e layout→estação
- `src/pages/Index.tsx` — auto-switch de estação no `handleLayoutChange`

### Pergunta antes de implementar
Me diga os nomes exatos das 4 impressoras como aparecem no agente (pode checar rodando `http://URL_AGENTE/impressoras` no navegador de cada PC).

