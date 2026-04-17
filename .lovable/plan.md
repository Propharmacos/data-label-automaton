

# Plano de correção — Salvar e ativos duplicados

## Diagnóstico real (verificado no código + banco)

### 1. Por que o "Salvar" parou de funcionar
Confirmei agora consultando o `pg_policies` da tabela `saved_rotulos`. As policies atuais são:

| Operação | Quem pode |
|----------|-----------|
| SELECT | qualquer autenticado ✅ |
| INSERT | **só admin ou financeiro** ❌ |
| UPDATE | **só admin ou financeiro** ❌ |
| DELETE | só admin ou financeiro |

E os usuários reais do sistema (consulta no `user_roles`):
- 17 com role `lider`
- 3 `operador_lab`
- 1 `operador`
- 4 `viewer`
- 3 `admin`
- 3 `financeiro`

Ou seja: **24 dos 31 usuários não têm permissão de gravar** em `saved_rotulos`. O `performSave` em `LabelTextEditor.tsx` faz `upsert` e o Supabase devolve erro de RLS — por isso o botão "parou" de salvar de uma hora para outra (alguém apertou as policies em algum momento).

Isso bate exatamente com a memória `mem://database/security/saved-rotulos-shared-access`, que diz que o acesso deveria ser compartilhado para todos os autenticados. As policies atuais contradizem essa regra.

### 2. Por que os ativos estão duplicados — preciso de info sua
Aqui não vou inventar. Olhando o código existente:
- `generateTextAmpCx` (linha 332) e `generateTextAmp10` (linha 573) usam `rotulo.componentes` para KITs e `rotulo.composicao` para mesclas — sem deduplicação.
- Se o backend retornar o mesmo `CDICP` 2x, o frontend imprime 2x.

Antes de mexer, **preciso de 1 print** do rótulo com os ativos duplicados + a **req e item (barra)** do caso. Com isso eu rodo um SELECT no Firebird via servidor.py e vejo se a duplicação vem do banco (FC03300/FC99999) ou se é a função do frontend que está concatenando errado. Sem isso, qualquer mudança é chute e pode quebrar layouts que estão funcionando.

## Correção que vou fazer agora (parte 1 — Salvar)

### Migração SQL
Recriar as policies de `saved_rotulos` para liberar INSERT/UPDATE para todas as roles operacionais (admin, financeiro, lider, operador, operador_lab). `viewer` continua só leitura.

### `src/components/LabelTextEditor.tsx` — `performSave`
Adicionar log do `error.code` no console e detectar `42501` (violação de RLS) para mostrar toast claro: *"Sua conta não tem permissão para salvar."* — assim, se isso acontecer de novo, identificamos em segundos.

## Próximo passo (parte 2 — duplicação)
Assim que você me mandar **o print + o nº da req/item duplicado**, eu investigo a fonte (banco ou frontend) e corrijo de forma cirúrgica, sem tocar nos layouts homologados.

## Arquivos afetados agora
- Nova migration SQL (policies de `saved_rotulos`)
- `src/components/LabelTextEditor.tsx` (melhor mensagem de erro no `performSave`)

## Resultado esperado
- Qualquer operador/líder/lab consegue salvar normalmente, como era antes.
- Se algum erro de permissão ocorrer no futuro, o toast diz exatamente o motivo.
- Duplicação de ativos: corrigida em seguida com base no print que você enviar.

