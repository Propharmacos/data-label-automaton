

## Diagnóstico

Nas fotos, o layout A.PAC.GRAN (57 colunas) mostra:

- **Print 1**: Nome do médico truncado: `DR(A)MATEUS SANCHES DO` (cortado em 22 caracteres)
- **Print 2**: Usuário tentou forçar o nome completo manualmente e o texto sobrepôs o conselho, criando borrão preto

**Causa raiz**: Na função `generateTextPacGran`, a zona direita da linha 2 (`RIGHT_L2_WIDTH`) está definida como **35 caracteres**, deixando apenas `57 - 35 = 22` caracteres para o nome do médico. O campo direito real ("CRBM-SP-67499 REG:24017") usa apenas ~24 caracteres, então há 11 colunas desperdiçadas.

**Solução**: Duas correções combinadas:

1. **Reduzir RIGHT_L2_WIDTH** de 35 para **26** (o suficiente para o maior conselho+REG possível), dando ao médico **31 caracteres** em vez de 22.

2. **Aplicar `abbreviateName`** ao nome do médico (já existe no código para A.PAC.PEQ) para que nomes que ainda excedam o limite sejam abreviados progressivamente em vez de cortados bruscamente.

Isso garante: nomes curtos aparecem completos, nomes longos são abreviados de forma inteligente (ex: `DR(A)M. S. D. DE SOUZA`), e nunca há sobreposição com o conselho.

---

## Plano

### Arquivo: `src/components/LabelTextEditor.tsx`

Na função `generateTextPacGran` (~linha 326):

1. Alterar `RIGHT_L2_WIDTH` de `35` para `26`
2. Antes de montar `drName`, calcular o espaço disponível e usar `abbreviateName`:
   ```
   const medicoMax = LEFT_L2 - 5;  // 5 = "DR(A)" prefix
   const medicoAbrev = abbreviateName(medico, medicoMax);
   const drName = medicoAbrev ? `DR(A)${medicoAbrev}` : "";
   ```

### Nenhuma alteração no agente
O layout, coordenadas Y e parsing do agente permanecem intactos.

