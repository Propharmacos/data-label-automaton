

# Ajustar layout TIRZ — compactar e incluir posologia

## O que muda
O layout TIRZ precisa incluir a posologia (que foi removida dos outros layouts) e ter espaçamento entre linhas mais compactado para caber no rótulo pequeno da impressora da Edi.

## Alterações técnicas

### 1. `src/components/LabelTextEditor.tsx` — função `generateTextTirz`

**Restaurar posologia no TIRZ** (exceção à política de supressão dos outros layouts):

- Linha 698-702: Em vez de pular a posologia, incluí-la após o produto com wrap por largura de coluna
- O produto e a posologia fluem juntos nas linhas 3-5, quebrando naturalmente pelo `W` (73 colunas)

```typescript
// LINE 3+: Fórmula/Produto + Posologia (wrapping)
const produto = formatarFormula(rotulo.formula) || "";
const posologia = rotulo.posologia?.toUpperCase().trim() || "";
const produtoCompleto = posologia ? `${produto}   ${posologia}` : produto;
wrapText(produtoCompleto, W, 0).split('\n').forEach(l => lines.push(l.substring(0, W)));
```

### 2. `src/components/LabelTextEditor.tsx` — `lineSpacingFactor` padrão para TIRZ

Na função principal de renderização, quando o layout é TIRZ e o usuário não definiu um `lineSpacingFactor` customizado, usar um fator reduzido (ex: `0.85`) para compactar o espaçamento entre linhas no preview e na impressão.

### 3. Atualizar a política de supressão de posologia

**Arquivo**: `mem://business-logic/data-extraction/posologia-suppression-policy`

Registrar que TIRZ é a exceção: posologia aparece no TIRZ porque é informação essencial de aplicação (ex: "APLICAR 0,2ML VIA SC 1X POR SEMANA DURANTE 12 SEMANAS").

## Resultado esperado
O rótulo TIRZ sairá com 7-8 linhas compactadas, incluindo a posologia completa, idêntico ao padrão Formula Certa da foto de referência.

