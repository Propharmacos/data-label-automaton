
# Plano: Implementar Logica de KITs via FC12111 no servidor.py

## Resumo

Vou atualizar o `servidor.py` para usar a tabela **FC12111** como fonte definitiva de identificacao de KITs. A logica atual usa FC05000/FC05100 que nao funciona para todos os casos. A FC12111 contem a "explosao" do kit na requisicao - se existir registro em FC12111 para um determinado (NRRQU, SERIER, CDFIL), o item e definitivamente um KIT.

## Fluxo de Identificacao

```text
REQUISICAO (FC12100)
       |
       v
   ITENS (FC12110)
       |
   +---+---+
   |       |
   v       v
SERIER   SERIER
   1       9
   |       |
   v       v
Existe    Existe
FC12111?  FC12111?
   |         |
  NAO       SIM
   |         |
   v         v
Prod/Mescla  KIT (com componentes)
```

## Mudancas no servidor.py

### 1. Nova Funcao: `verificar_kit_fc12111()`

Conta registros em FC12111 para determinar se e KIT:

```text
SELECT COUNT(*) FROM FC12111 
WHERE NRRQU = ? AND SERIER = ? AND CDFIL = ?

Se count > 0 -> E KIT
Se count = 0 -> NAO E KIT
```

### 2. Nova Funcao: `buscar_componentes_kit_fc12111()`

Busca componentes com descoberta dinamica de colunas:

```text
SELECT c.CDPRO, c.QUANT, c.UNIDADE, c.ORDCAP, p.DESCR
FROM FC12111 c
LEFT JOIN FC03000 p ON p.CDPRO = c.CDPRO
WHERE c.NRRQU = ? AND c.SERIER = ? AND c.CDFIL = ?
ORDER BY c.ORDCAP
```

### 3. Nova Funcao: `buscar_lote_componente()`

Busca lote/fabricacao/validade com duas estrategias:

**Estrategia A** (preferencial): Se FC12111 tiver NRLOT/CTLOT, usa para buscar em FC03140

**Estrategia B** (fallback): Busca lote mais recente em FC03140:
```text
SELECT FIRST 1 NRLOT, CTLOT, DTFAB, DTVAL
FROM FC03140 
WHERE CDPRO = ? AND CDFIL = ?
ORDER BY DTVAL DESC
```

### 4. Modificar Loop Principal

Na linha ~1869 onde processa os itens, adicionar verificacao FC12111 ANTES da verificacao FC05000:

```text
PARA cada item em itens:
  1. Verificar se e KIT via FC12111:
     - count = SELECT COUNT(*) FROM FC12111 WHERE ...
     - SE count > 0: E KIT
  
  2. SE e KIT:
     - componentes = buscar_componentes_kit_fc12111()
     - PARA cada componente:
       - dados_lote = buscar_lote_componente()
     - tipoItem = "KIT"
  
  3. SE NAO e KIT:
     - Manter logica atual (FC05000/FC05100 ou MESCLA/PRODUTO UNICO)
```

### 5. Conversao de Tipos (Evitar SQLCODE -413)

Todos os parametros numericos (NRRQU, SERIER, CDFIL) serao convertidos para `int()` antes de passar para o cursor.

### 6. Logs de Debug

Adicionar logs detalhados para cada SERIER:

```text
[DEBUG] SERIER=9 CDPRO_PAI=92487
[DEBUG] FC12111 count=4 => KIT
[DEBUG] comp 92494 lote=ABC123 fab=01/25 val=01/26 (A)
[DEBUG] comp 92681 lote=DEF456 fab=02/25 val=02/26 (B)
```

## Estrutura JSON de Resposta

```text
{
  "tipoItem": "KIT",
  "nrItem": "9",
  "formula": "EMAG SUG 2",
  "componentes": [
    {
      "codigo": "92494",
      "nome": "HMB 50MG/2ML",
      "ph": "",
      "lote": "ABC123",
      "fabricacao": "01/25",
      "validade": "01/26"
    }
  ]
}
```

## Locais de Edicao no servidor.py

| Linhas | Mudanca |
|--------|---------|
| ~1583-1600 | Adicionar novas funcoes FC12111 (verificar_kit_fc12111, buscar_componentes_kit_fc12111, buscar_lote_componente) |
| ~1869-1890 | Modificar inicio do loop para verificar FC12111 primeiro |
| ~2037-2047 | Substituir chamada de verificar_se_kit() pela nova logica FC12111 |

## Resultado Esperado

- Item "AMP EMAG SUG 2 2ML" (CDPRO 92487) sera identificado como **KIT**
- Os componentes (92494, 92681, 92377, 92435) serao retornados com lote/fab/val
- Frontend recebera dados corretos para renderizar rotulo de kit

## Validacao

Apos atualizar servidor.py:
1. Reiniciar servidor Flask
2. Acessar http://localhost:5000/api/requisicao/89489?filial=279
3. Verificar logs no terminal com linhas `[DEBUG] FC12111 count=...`
4. Confirmar que itens KIT aparecem com `tipoItem: "KIT"` e `componentes: [...]`
