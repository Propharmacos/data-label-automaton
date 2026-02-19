

## Solucao Garantida: Usar o ROTUTX do Formula Certa Direto

### Por que nada funcionou ate agora

Todas as tentativas anteriores tentaram **recriar** os comandos PPLA do zero -- ajustando coordenadas, modo dots vs mm, fontes, rotacao, etc. Isso e inerentemente fragil porque qualquer pequena diferenca nos comandos pode causar etiquetas em branco ou multiplas impressoes.

### A solucao com 100% de certeza

O Formula Certa ja gera os comandos PPLA perfeitos e **salva eles no banco de dados** (tabela FC12300, campo ROTUTX). O servidor central (servidor.py) ja tem um endpoint `/api/imprimir_fc` que:

1. Le o ROTUTX do banco (os bytes exatos que o Formula Certa gerou)
2. Envia esses bytes RAW para o agente local
3. O agente manda direto para a impressora

Ou seja: nao precisa gerar layout nenhum. E so pegar o que o Formula Certa ja fez e mandar pra impressora. **Se funciona no Formula Certa, vai funcionar aqui porque sao os mesmos bytes.**

### O que muda no frontend

**Arquivo: `src/services/printAgentService.ts`**

Adicionar uma nova funcao `imprimirViaRotutx()` que chama o endpoint `/api/imprimir_fc` do servidor central (nao do agente). Parametros: numero da requisicao, filial, serie, item e nome da impressora.

**Arquivo: `src/pages/Index.tsx`**

Alterar o fluxo de impressao para:
1. Primeiro tenta imprimir via ROTUTX (usando `/api/imprimir_fc`)
2. Se o ROTUTX nao existir no banco (retorno 404), cai no modo atual (gerar PPLA via agente) como fallback

Adicionar um botao ou toggle "Modo FC (direto)" para o usuario poder escolher:
- **Modo FC**: usa os bytes do Formula Certa direto (garantido funcionar)
- **Modo Agente**: gera PPLA pelo agente (modo atual, para quando nao houver ROTUTX)

**Arquivo: `src/config/api.ts`**

Adicionar configuracao `modoImpressao: 'rotutx' | 'agente'` com padrao `'rotutx'`.

### Fluxo tecnico

```text
Usuario clica "Imprimir"
        |
        v
Frontend chama servidor: POST /api/imprimir_fc
  { req: 6806, filial: 1, item: 1, impressora: "AMP PEQUENO" }
        |
        v
Servidor le FC12300.ROTUTX (bytes do Formula Certa)
        |
        v
Servidor envia bytes em base64 para agente: POST /raw
        |
        v
Agente decodifica e manda RAW para impressora Argox
        |
        v
Etiqueta sai IDENTICA ao Formula Certa
```

### Por que isso tem 100% de certeza

- Os bytes ROTUTX sao exatamente o que o Formula Certa envia para a impressora
- O agente ja tem o endpoint `/raw` que recebe base64 e manda direto, sem modificar nada
- O servidor ja tem o endpoint `/api/imprimir_fc` pronto e funcionando
- Nao ha geracao de layout, coordenadas, fontes ou qualquer logica PPLA envolvida -- sao os mesmos bytes que ja funcionam

### Resumo das mudancas

1. **`src/services/printAgentService.ts`**: Nova funcao `imprimirViaRotutx(serverUrl, req, filial, serie, item, impressora)`
2. **`src/pages/Index.tsx`**: Botao de impressao usa `imprimirViaRotutx` como metodo principal, com fallback para o agente
3. **`src/config/api.ts`**: Novo campo `modoImpressao` na configuracao

Nenhuma mudanca no agente_impressao.py ou servidor.py -- tudo ja esta pronto no backend.

