
# Plano de Implementação: Login + Layouts Corrigidos

## Visão Geral

Implementar sistema de autenticação com dois níveis de acesso e corrigir os 5 layouts de rótulos conforme a imagem de referência.

---

## PARTE 1: Sistema de Autenticação

### 1.1 Estrutura do Banco de Dados (Supabase)

Criar migração SQL com:

```sql
-- Enum para roles
CREATE TYPE public.app_role AS ENUM ('admin', 'operador');

-- Tabela de roles dos usuários
CREATE TABLE public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role app_role NOT NULL DEFAULT 'operador',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, role)
);

-- Habilitar RLS
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Função security definer para verificar role (evita recursão)
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Política: usuários podem ver seu próprio role
CREATE POLICY "Users can read own role"
ON public.user_roles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Política: admins podem ver todos os roles
CREATE POLICY "Admins can read all roles"
ON public.user_roles FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));
```

### 1.2 Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `src/contexts/AuthContext.tsx` | Contexto React para estado de autenticação |
| `src/hooks/useAuth.ts` | Hook para consumir o contexto |
| `src/pages/Login.tsx` | Página de login com formulário |
| `src/components/ProtectedRoute.tsx` | Componente para proteger rotas |

### 1.3 Contexto de Autenticação

O `AuthContext` irá:
- Gerenciar sessão do usuário via `supabase.auth.onAuthStateChange`
- Buscar role do usuário na tabela `user_roles`
- Expor `user`, `role`, `isAdmin`, `isLoading`, `signIn`, `signOut`

### 1.4 Página de Login

- Formulário simples com email e senha
- Usar `supabase.auth.signInWithPassword`
- Redirecionar para `/` após login bem-sucedido
- Logo da ProPharmacos no topo

### 1.5 Proteção de Rotas

**Modificar `src/App.tsx`:**
- Envolver rotas com `AuthProvider`
- Rota `/login` pública
- Rotas `/` e `/configuracoes` protegidas
- Rota `/configuracoes` exige role `admin`

**Modificar `src/pages/Index.tsx`:**
- Ocultar botão de configurações (engrenagem) se `!isAdmin`
- Adicionar botão de logout no header

**Modificar `src/pages/Settings.tsx`:**
- Verificar se usuário é admin
- Redirecionar para `/` se não for admin

### 1.6 Fluxo de Usuários

```text
rótulos@propharmacos.com (operador):
  ✓ Pode fazer login
  ✓ Pode buscar requisições
  ✓ Pode imprimir rótulos
  ✗ NÃO vê botão de configurações
  ✗ NÃO acessa /configuracoes

Admrótulos@propharmacos.com (admin):
  ✓ Pode fazer tudo acima
  ✓ Vê botão de configurações
  ✓ Acessa /configuracoes
```

---

## PARTE 2: Correção dos Layouts

### 2.1 Adicionar Novo Layout

**Modificar `src/types/requisicao.ts`:**
```typescript
// Adicionar A_PAC_PEQ ao tipo
export type LayoutType = 'AMP10' | 'AMP_CX' | 'A_PAC_GRAN' | 'A_PAC_PEQ' | 'TIRZ';
```

### 2.2 Configuração dos 5 Layouts (baseado na imagem)

**Modificar `src/config/layouts.ts`:**

#### Layout 1: AMP_CX (Ampola Caixa)
```text
Linha 1: PACIENTE                          REQ:XXXXXX-X
Linha 2: DR(A)NOME DO MÉDICO CONSELHO-UF-NÚMERO
Linha 3: NOME DO ATIVO
Linha 4: pH:X,X L:XXX/XX F:XX/XX V:XX/XX
Linha 5: USO EM CONSULTÓRIO    APLICAÇÃO:XX
Linha 6: CONTÉM:XXXXXX
Linha 7: REG:XXXXX
```

#### Layout 2: AMP10 (Ampola 10)
```text
Linha 1: PACIENTE                          REQ:XXXXXX-X
Linha 2: DR(A)NOME DO MÉDICO CONSELHO-UF-NÚMERO
Linha 3: COMPOSIÇÃO (ativos linha 1)
Linha 4: COMPOSIÇÃO (ativos linha 2, continuação)
Linha 5: COMPOSIÇÃO + REG:XXXXX
Linha 6: pH:X,X L:XXX/XX V:XX/XX   AP:XX SUPERFICIAL
Linha 7: USO EM CONSULTÓRIO/POSOLOGIA
```

#### Layout 3: A_PAC_PEQ (NOVO - Ampola Pacote Pequeno)
```text
Linha 1: PACIENTE                          REQ:XXXXXX-X
Linha 2: DR(A)NOME CONSELHO-UF-NÚMERO
Linha 3: REG:XXXXX
```

#### Layout 4: A_PAC_GRAN (Ampola Pacote Grande)
```text
Linha 1: PACIENTE                          REQ:XXXXXX-X
Linha 2: DR(A)NOME CONSELHO-UF-NÚMERO      REG:XXXXX
```

#### Layout 5: TIRZ (Tirzepatida)
```text
Linha 1: PACIENTE                          REQ:XXXXXX-X
Linha 2: DR(A)NOME DO MÉDICO CRM-UF-NÚMERO
Linha 3: TIRZEPATIDA XXmg/X,XML
Linha 4: APLICAR XMG POR SEMANA
Linha 5: pH:X,X L:XXX/XX F:XX/XX V:XX/XX
Linha 6: USO EM CONSULTÓRIO    APLICAÇÃO:SC
Linha 7: CONTÉM:XFR. DE X,XML    REG:XXXXX
```

### 2.3 Atualizar Seletor de Layouts

**Modificar `src/components/LayoutSelector.tsx`:**
```typescript
const layoutOptions = [
  { value: 'AMP_CX', label: 'AMP.CX' },
  { value: 'AMP10', label: 'AMP 10' },
  { value: 'A_PAC_PEQ', label: 'A.PAC.PEQ' },
  { value: 'A_PAC_GRAN', label: 'A.PAC.GRAN' },
  { value: 'TIRZ', label: 'TIRZ' },
];
```

---

## Ordem de Implementação

1. **Migração SQL** - Criar tabela `user_roles` e função `has_role`
2. **AuthContext + useAuth** - Contexto de autenticação
3. **Login.tsx** - Página de login
4. **ProtectedRoute** - Componente de proteção
5. **App.tsx** - Integrar autenticação nas rotas
6. **Index.tsx** - Ocultar engrenagem para operador
7. **Settings.tsx** - Verificar permissão admin
8. **types/requisicao.ts** - Adicionar tipo A_PAC_PEQ
9. **config/layouts.ts** - Reconfigurar todos os 5 layouts
10. **LayoutSelector.tsx** - Adicionar opção A.PAC.PEQ

---

## Após Implementação

Você precisará criar os dois usuários no painel do Supabase:

1. Acesse **Authentication > Users** no dashboard do Supabase
2. Clique em **Add user**
3. Crie os dois usuários:
   - `rótulos@propharmacos.com` com uma senha
   - `Admrótulos@propharmacos.com` com uma senha
4. Após criar, execute SQL para atribuir roles:

```sql
-- Buscar IDs dos usuários
SELECT id, email FROM auth.users;

-- Atribuir role admin (substitua UUID pelo ID correto)
INSERT INTO public.user_roles (user_id, role)
VALUES ('UUID_DO_ADMIN', 'admin');

-- Atribuir role operador (substitua UUID pelo ID correto)
INSERT INTO public.user_roles (user_id, role)
VALUES ('UUID_DO_OPERADOR', 'operador');
```
