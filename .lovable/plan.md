
# Diagnóstico objetivo

## 1. Por que a Configuração “sumiu” para o `admrotulos`
Eu encontrei um problema claro no controle de acesso do frontend:

- Em `src/contexts/AuthContext.tsx`, a role do usuário é buscada assim:
  - consulta a tabela `user_roles`
  - usa `.single()`
- Só que essa tabela foi desenhada para permitir **mais de uma role por usuário** (`UNIQUE (user_id, role)`), então um mesmo usuário pode ter `admin` + outra role.
- Quando isso acontece, `.single()` falha porque volta mais de uma linha.
- No erro, o código faz fallback para:
  - `setRole("operador")`

Resultado prático:
- `isAdmin` vira `false`
- o ícone de Configurações some no header (`src/pages/Index.tsx`)
- a rota `/configuracoes` também bloqueia, porque `ProtectedRoute` exige `requireAdmin`

Ou seja: o admin não “sumiu” de verdade. O frontend provavelmente passou a **enxergar seu usuário como operador** por causa da forma errada de ler as roles.

## 2. Por que o salvar ainda está dando erro
Achei um segundo problema estrutural no salvamento dos rótulos:

### O código salva assim
Em `src/components/LabelTextEditor.tsx`:
- faz `upsert` em `saved_rotulos`
- usando `onConflict: 'nr_requisicao,item_id,layout_type'`

### Mas o histórico de migrations do projeto mostra outra coisa
Na migration de criação da tabela `saved_rotulos`, o `UNIQUE` registrado no repositório é:
- `UNIQUE(nr_requisicao, item_id)`

E eu **não encontrei migration no projeto** adicionando formalmente a chave composta com `layout_type`.

Isso indica um descompasso entre:
- o que o frontend espera
- e o que a estrutura do banco historicamente documentada garante

Consequência provável:
- o `upsert` pode estar falhando por conflito/index incompatível
- ou o banco está tratando um mesmo item como único sem considerar o layout
- o que quebra justamente o modelo atual de salvar por layout

## 3. O que isso significa na prática
Hoje vocês têm dois problemas diferentes:

1. **Configuração sumida**
   - causada pelo carregamento incorreto das roles no `AuthContext`

2. **Erro ao salvar**
   - o RLS já foi mexido, mas o erro restante provavelmente não é mais “permissão”
   - o mais forte no código agora é **incompatibilidade entre o `upsert` e a chave única esperada para `saved_rotulos`**

---

# Plano de correção

## Etapa 1 — Corrigir leitura de roles do usuário
**Arquivos:** `src/contexts/AuthContext.tsx`, possivelmente `src/components/ProtectedRoute.tsx`

Vou ajustar a autenticação para:
- parar de usar `.single()` em `user_roles`
- ler todas as roles do usuário
- derivar `isAdmin` com base em `roles.includes("admin")`
- remover o fallback silencioso para `"operador"` quando houver múltiplas roles

Isso deve fazer o botão de Configurações voltar a aparecer para o `admrotulos` e liberar novamente a rota `/configuracoes`.

## Etapa 2 — Corrigir o salvamento de `saved_rotulos`
**Arquivos:** migration Supabase + `src/components/LabelTextEditor.tsx`

Vou alinhar o banco com o código atual:
- validar/criar a constraint correta para `saved_rotulos` com:
  - `(nr_requisicao, item_id, layout_type)`
- garantir que o `upsert` use exatamente a chave existente no banco
- manter as policies de RLS coerentes com esse fluxo

Também vou melhorar a mensagem de erro do salvar para distinguir:
- erro de permissão
- erro de constraint/index
- erro genérico de banco

## Etapa 3 — Validação ponta a ponta
Vou validar o fluxo esperado:
1. login com `admrotulos`
2. confirmar que o ícone de Configurações reaparece
3. acessar `/configuracoes`
4. abrir uma requisição
5. editar e salvar um rótulo
6. trocar layout e confirmar que o salvamento por `layout_type` continua funcionando sem conflito

---

# Resultado esperado

## Depois da correção
- o `admrotulos` volta a ser reconhecido como admin no frontend
- o botão de Configurações reaparece
- a rota de configurações volta a abrir normalmente
- o botão Salvar volta a persistir os layouts/rótulos sem erro
- cada layout continua salvo separadamente para o mesmo item, como o sistema atual exige

---

# Detalhes técnicos
- `AuthContext.tsx` hoje está incompatível com o modelo real de `user_roles` porque assume uma role única.
- `saved_rotulos` hoje está sendo salvo com `onConflict` de 3 campos, mas o histórico de migrations versionado não prova essa mesma chave no banco.
- A correção certa é tratar esses dois pontos separadamente, porque eles explicam exatamente os dois sintomas que você relatou: **configuração sumida** e **salvar quebrado**.
