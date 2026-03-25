

## Plano: Remover seletor único de impressora da aba Agente HTTP

### Problema
A aba "Agente HTTP" tem um campo "Impressora" que permite selecionar apenas UMA impressora por estação. Na prática, cada PC tem DUAS impressoras (Edi: PEQUENO + GRANDE; Daniel: AMP_CX + AMP10), e a impressora correta já é determinada pelo layout selecionado via o mapeamento layout-impressora existente.

### O que será feito

1. **Remover o campo "Impressora"** (Select) da aba Agente HTTP em `LabelSettings.tsx` (linhas 394-425)
2. **Remover o campo `impressora` da interface `PrintStation`** em `api.ts` — cada estação passa a ter apenas `id`, `nome`, `agentUrl` e `calibracao`
3. **Manter o mapeamento layout → impressora** que já existe via `getLayoutPrinter()` / `setLayoutPrinter()` — esse é o mecanismo correto para rotear cada layout para sua impressora física
4. **Limpar referências** ao campo `impressora` da estação nos handlers de save/switch de estação

### Arquivos alterados
- `src/components/LabelSettings.tsx` — remover bloco do Select de impressora e referências a `station.impressora`
- `src/config/api.ts` — remover campo `impressora` de `PrintStation` e dos defaults

### O que NÃO muda
- O mapeamento layout → impressora (`LayoutPrinterMap`) continua funcionando normalmente
- A URL do agente por estação continua configurável
- O fluxo de impressão PPLA direto não é afetado

