

## Comparador PPLA Inteligente: Diagnosticar + Corrigir Automaticamente

### O Problema
Hoje o comparador mostra as diferenças entre o nosso sistema e o Formula Certa, mas para na tela. O usuario tem que olhar os numeros, entender o que significa, e ir manualmente nos campos de calibracao para ajustar. Isso nao faz sentido -- se o sistema ja sabe a diferenca, ele deveria corrigir sozinho.

### A Solucao
Transformar o comparador em um **diagnosticador com autocorrecao**. Apos a analise, o sistema vai:

1. **Identificar as diferencas corrigiveis** -- quais parametros do nosso sistema podem ser ajustados
2. **Mostrar um resumo claro** -- "O FC usa contraste H14, nos usamos H08. Quer corrigir?"
3. **Aplicar com um clique** -- botao "Aplicar Correcoes" que atualiza automaticamente os campos de calibracao

### O que pode ser corrigido automaticamente

O nosso sistema tem estes campos ajustaveis na calibracao:

| Campo | Comando PPLA | O que faz |
|-------|-------------|-----------|
| Contraste | Hxx | Intensidade de impressao |
| Fonte PPLA | 0-9 | Tamanho da fonte |
| Rotacao | 0-3 | Orientacao do texto |
| Margem Esquerda | Cxxxx | Deslocamento horizontal |
| Offset Vertical | Rxxxx | Deslocamento vertical |

Se o comparador detectar que o FC usa H14 e nos usamos H08, ele pode automaticamente mudar o contraste para 14. Se o FC usa fonte 2 e nos usamos fonte 5, ele pode ajustar.

### Como vai funcionar para o usuario

1. Roda o Diagnostico PPLA (como ja faz)
2. Clica "Comparar com FC" e cola os comandos do .prn
3. Clica "Analisar" -- ve as diferencas agrupadas (como ja existe)
4. **NOVO**: Aparece um painel "Correcoes Sugeridas" com cada diferenca corrigivel listada
5. **NOVO**: Botao "Aplicar Todas as Correcoes" que atualiza os campos de calibracao do nosso sistema automaticamente
6. Os campos de Contraste, Fonte, Rotacao, Margem e Offset sao atualizados instantaneamente
7. O usuario pode rodar o diagnostico novamente para confirmar que agora esta igual

### Detalhes Tecnicos

**Arquivos modificados:**

1. **`src/utils/pplaParser.ts`** -- Adicionar nova funcao `extractCalibrationFromDiff()`:
   - Recebe o array de `DiffResult[]`
   - Extrai os valores de calibracao do lado direito (Formula Certa): contraste (H), fonte, rotacao
   - Extrai diferencas de coordenadas para calcular offsets de margem e deslocamento vertical
   - Retorna um objeto `SuggestedFixes` com os valores sugeridos e a justificativa de cada um

2. **`src/components/PPLAComparer.tsx`** -- Adicionar painel de correcoes:
   - Nova secao "Correcoes Sugeridas" que aparece apos a analise
   - Lista cada correcao com valor atual vs valor sugerido
   - Checkbox para selecionar/deselecionar correcoes individuais
   - Botao "Aplicar Correcoes Selecionadas"
   - Recebe uma callback `onApplyFixes` do componente pai (LabelSettings) que atualiza o `agentConfig.calibracao`

3. **`src/components/LabelSettings.tsx`** -- Conectar a aplicacao das correcoes:
   - Passar callback `onApplyFixes` para o PPLAComparer
   - A callback recebe o objeto `SuggestedFixes` e atualiza `agentConfig.calibracao` com os novos valores
   - Como ja existe auto-save via useEffect, os valores sao persistidos automaticamente no localStorage
   - Exibir toast de confirmacao "Calibracao atualizada com base no Formula Certa"

**Estrutura do `SuggestedFixes`:**
```text
{
  contraste: { atual: 8, sugerido: 14, motivo: "FC usa H14, sistema usa H08" },
  fonte: { atual: 2, sugerido: 2, motivo: null },  // sem diferenca
  rotacao: { atual: 1, sugerido: 1, motivo: null },
  margem_c: { atual: 0, sugerido: 15, motivo: "Coords X do FC deslocadas ~15 unidades" },
  offset_r: { atual: 0, sugerido: 0, motivo: null }
}
```

**Logica de extracao dos valores do FC:**
- Contraste: procurar linha de config com prefixo "H", extrair numero (ex: H14 -> 14)
- Fonte: pegar a fonte mais frequente nas linhas de texto do FC
- Rotacao: pegar a rotacao mais frequente nas linhas de texto do FC
- Margem/Offset: calcular a media das diferencas de coordenadas X e Y entre linhas pareadas

### Resultado Final
O comparador deixa de ser apenas informativo e passa a ser uma ferramenta de **autocalibracao**: compara, diagnostica e corrige com um clique.
