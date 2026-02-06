

# Plano: Redesign Visual com Logo ProPharmacos + Novo Layout AMP 10

## Visão Geral

Este plano implementa uma atualização visual completa do sistema de rótulos, incluindo:
1. Adicionar a logo da ProPharmacos ao projeto
2. Atualizar o design system com as cores da marca
3. Melhorar a interface do usuário (UI) do frontend
4. Ajustar o layout de etiqueta AMP 10 conforme referência física

---

## 1. Cores Extraídas da Logo ProPharmacos

Da logo fornecida, identifiquei as seguintes cores principais:

| Cor | Uso | HSL |
|-----|-----|-----|
| **Azul Escuro** | Texto "pharmacos", fundo do símbolo | hsl(206, 45%, 40%) - #456B8A |
| **Rosa/Pink** | Texto "pró", pétalas da flor | hsl(343, 55%, 65%) - #D4849A |
| **Rosa Claro** | Acentos, pétalas claras | hsl(343, 40%, 85%) - #E8C8D0 |
| **Branco** | Fundo | hsl(0, 0%, 100%) |

---

## 2. Alterações de Arquivos

### 2.1 Copiar Logo para o Projeto
- **Destino**: `src/assets/logo-propharmacos.png`
- A logo será usada no header e footer

### 2.2 Atualizar Design System (`src/index.css`)

Novas variáveis CSS baseadas nas cores da marca:

```text
Antes:
  --primary: 212 72% 39%;        (Azul genérico)
  --secondary: 344 78% 72%;      (Rosa genérico)

Depois:
  --primary: 206 45% 40%;        (Azul ProPharmacos)
  --secondary: 343 55% 65%;      (Rosa ProPharmacos)
  --accent: 343 40% 92%;         (Rosa bem claro para hover)
```

### 2.3 Atualizar Header da Página Principal (`src/pages/Index.tsx`)

**Antes**:
- Ícone quadrado com letra "P"
- Layout simples

**Depois**:
- Logo real da ProPharmacos (imagem)
- Design mais profissional
- Gradiente sutil no header
- Melhor espaçamento

### 2.4 Melhorar Interface de Busca (`src/components/SearchRequisition.tsx`)

- Adicionar visual mais moderno
- Bordas arredondadas maiores
- Sombras suaves
- Cores da marca nos botões

### 2.5 Atualizar Cards de Rótulo (`src/components/LabelCard.tsx`)

- Bordas com cor da marca quando selecionado
- Visual mais limpo e profissional
- Melhor contraste

### 2.6 Atualizar Página de Configurações (`src/pages/Settings.tsx`)

- Consistência visual com a página principal
- Header com logo

---

## 3. Layout AMP 10 (Etiqueta de Referência)

Da foto da etiqueta física fornecida, identifiquei a estrutura:

```text
┌─────────────────────────────────────────────┐
│ Logo ProVitae + REQ:006547-N                │
│ DRA. ISABELLE VICALVI                       │
│ CRF-SP-92804                                │
│ ISABELLE VICALVI                            │
│ LIPOSSOMAS DE DESOXICOLATO 10MG 4amp        │
│                                             │
│ pH:     L:      F:      V:                  │
│ USO EM CONSULTÓRIO                          │
│ CONTEM: FR. DE ML                           │
│                                             │
│ APLICAÇÃO:                                  │
│ REG:11600                                   │
├─────────────────────────────────────────────┤
│ FARM. RESP: VANIA MOLINARI CRF-SP 19619     │
│ CNPJ 73.119.927/0008-95                     │
│ R. Campos Sales, 545 - Centro - S.A.        │
│ TEL: (11) 3777-6087                         │
└─────────────────────────────────────────────┘
```

### Estrutura de Linhas para AMP10:

| Linha | Campos | Observação |
|-------|--------|------------|
| 1 | `requisicao` | Canto superior direito |
| 2 | `medico` | Prescritor com prefixo DR./DRA. |
| 3 | `paciente` | Nome do paciente |
| 4 | `formula` ou `composicao` | Exclusão mútua |
| 5 | `ph`, `lote`, `fabricacao`, `validade` | Linha compacta |
| 6 | `tipoUso` | Ex: "USO EM CONSULTÓRIO" |
| 7 | `contem` | Ex: "CONTEM: 4 FR. DE 2ML" |
| 8 | `aplicacao` | Ex: "APLICAÇÃO: ID/SC" |
| 9 | `registro` | Ex: "REG:11600" |

---

## 4. Fluxo de Implementação

```text
1. Copiar logo para src/assets/
       │
       ▼
2. Atualizar index.css (cores da marca)
       │
       ▼
3. Atualizar Index.tsx (header com logo + UI)
       │
       ▼
4. Atualizar SearchRequisition.tsx (visual moderno)
       │
       ▼
5. Atualizar LabelCard.tsx (bordas e cores)
       │
       ▼
6. Atualizar Settings.tsx (consistência visual)
       │
       ▼
7. Atualizar layouts.ts (estrutura AMP10)
```

---

## 5. Prévia Visual Esperada

### Header Novo:
```text
┌──────────────────────────────────────────────────────────┐
│  [LOGO ProPharmacos]     Farmácia de Manipulação   [⚙️]  │
│  Sistema de Rótulos                                      │
└──────────────────────────────────────────────────────────┘
```

### Busca:
```text
         ┌─────────────────────────────────────────┐
         │ 🔍 Digite o número da requisição...     │  [ Buscar ]
         └─────────────────────────────────────────┘
                    (bordas arredondadas, sombra suave)
```

### Cards de Rótulo:
```text
┌─────────────────────────────────────────────────┐
│ ☑ Selecionar                               📝   │  ← Borda rosa quando selecionado
├─────────────────────────────────────────────────┤
│ [CONTEÚDO DO RÓTULO]                            │
│                                                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 6. Seção Técnica

### Arquivos a Modificar:

| Arquivo | Alteração |
|---------|-----------|
| `src/assets/logo-propharmacos.png` | **CRIAR** - Copiar logo do usuário |
| `src/index.css` | Atualizar variáveis CSS de cores |
| `src/pages/Index.tsx` | Redesign do header, adicionar logo |
| `src/components/SearchRequisition.tsx` | Visual mais moderno |
| `src/components/LabelCard.tsx` | Bordas e cores da marca |
| `src/pages/Settings.tsx` | Header com logo |
| `src/config/layouts.ts` | Ajustar estrutura AMP10 |

### Código da Atualização de Cores (index.css):

```css
:root {
  /* Azul ProPharmacos - texto principal, botões primários */
  --primary: 206 45% 40%;
  --primary-foreground: 0 0% 100%;

  /* Rosa ProPharmacos - acentos, botões secundários */
  --secondary: 343 55% 65%;
  --secondary-foreground: 0 0% 100%;

  /* Rosa claro - backgrounds de destaque */
  --accent: 343 40% 95%;
  --accent-foreground: 206 45% 40%;

  /* Ring (foco) - rosa */
  --ring: 343 55% 65%;
}
```

### Código do Novo Header (Index.tsx):

```tsx
<header className="bg-gradient-to-r from-card to-background border-b border-border shadow-sm">
  <div className="container mx-auto px-4 py-4">
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-4">
        <img 
          src={logoProPharmacos} 
          alt="ProPharmacos" 
          className="h-12 w-auto"
        />
        <div>
          <h1 className="text-xl font-bold text-primary">Sistema de Rótulos</h1>
          <p className="text-xs text-muted-foreground">Farmácia de Manipulação</p>
        </div>
      </div>
      {/* ... botões */}
    </div>
  </div>
</header>
```

---

## 7. Garantias

1. **Consistência**: Todas as páginas usarão as mesmas cores da marca
2. **Logo Visível**: Header de todas as páginas terá a logo
3. **Responsividade**: Design funciona em desktop e mobile
4. **Fontes Padronizadas**: Manter Inter como fonte principal, tamanhos consistentes
5. **Compatibilidade**: Não quebra funcionalidades existentes

---

## 8. Resultado Esperado

Após a implementação:
- Visual profissional alinhado com a identidade da ProPharmacos
- Cores azul e rosa da marca em toda a interface
- Logo visível no header
- Cards de rótulo mais elegantes
- Layout AMP10 seguindo a referência física fornecida

