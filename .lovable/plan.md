

## Implementacao: Pagina de Fila de Impressao + Endpoint FC90100

### Resumo

Criar uma nova pagina no frontend para visualizar a fila de impressao (FC12B00) e adicionar endpoints no backend para consultar FC12B00 (pendentes) e FC90100 (configuracoes de impressora com dimensoes automaticas).

---

### Parte 1: Backend (servidor.py)

**1.1 - Novo endpoint: GET /api/fila-impressao**
- Consulta FC12B00 filtrando por STATUS=0 (pendentes) e CDFIL (filial)
- Para cada registro, faz JOIN com FC12300 para trazer dados do rotulo (SERIER, NRRQU)
- Retorna lista com: NRRQU, SERIER, STATUS, CODIGOROTULO, DTCRIACAO

**1.2 - Novo endpoint: POST /api/fila-impressao/marcar**
- Recebe array de IDs (NRRQU + SERIER) para marcar como "em impressao"
- Atualiza STATUS na FC12B00 (ex: 0 -> 1)

**1.3 - Novo endpoint: GET /api/impressoras-config**
- Consulta FC90100 e retorna as configuracoes de impressora
- Expoe campos: ROTULOID, ALTURA, LARGURA, TPIMPRESSORA, PORTAREDE, NOMEPC
- O frontend usa ALTURA/LARGURA para configurar automaticamente as dimensoes do layout

---

### Parte 2: Frontend

**2.1 - Nova pagina: src/pages/PrintQueue.tsx**
- Tabela listando rotulos pendentes (STATUS=0) da FC12B00
- Colunas: Requisicao, Serie, Data Criacao, Status, Acoes
- Botao "Atualizar" para recarregar a fila
- Checkbox para selecionar rotulos e botao "Imprimir Selecionados"
- Seletor de impressora (usando dados do FC90100)

**2.2 - Novo service: src/services/filaImpressaoService.ts**
- `buscarFilaImpressao(filial)` - GET /api/fila-impressao
- `marcarParaImpressao(ids)` - POST /api/fila-impressao/marcar
- `buscarConfigImpressoras()` - GET /api/impressoras-config

**2.3 - Novos tipos em src/types/requisicao.ts**
- `FilaImpressaoItem` - representa um registro da FC12B00
- `ImpressoraConfig` - representa configuracao da FC90100

**2.4 - Rota e navegacao**
- Nova rota `/fila` em App.tsx (protegida)
- Botao de acesso na header do Index.tsx (icone de lista/fila)

---

### Parte 3: Fluxo do Usuario

```text
1. Usuario acessa /fila
2. Frontend chama GET /api/fila-impressao?filial=279
3. Backend consulta FC12B00 WHERE STATUS=0
4. Tabela mostra rotulos pendentes
5. Usuario seleciona rotulos e clica "Imprimir"
6. Frontend chama POST /api/fila-impressao/marcar
7. Backend atualiza STATUS e dispara impressao via agente
```

---

### Detalhes Tecnicos

- Os endpoints do backend seguem o padrao existente (Flask + fdb + ngrok headers)
- A pagina usa os mesmos componentes UI (Card, Table, Button, Select) do projeto
- As dimensoes de FC90100 (ALTURA/LARGURA) sao usadas para pre-configurar o LabelConfig automaticamente
- O seletor de impressora na fila usa as impressoras do FC90100 (PORTAREDE) em vez do agente local

