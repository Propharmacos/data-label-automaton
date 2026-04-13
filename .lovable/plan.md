

# Problema: as alterações WYSIWYG não estão no agente rodando nos PCs

## Causa raiz

O auto-update do agente busca o arquivo de `https://raw.githubusercontent.com/.../main/agente_impressao.py`. As mudanças feitas aqui no Lovable ainda não foram publicadas no branch `main` do GitHub. Por isso o `/update` respondeu "Já está na versão mais recente" — ele está comparando com a versão antiga no GitHub.

Evidência: o agente do Daniel retorna `"protocolo":"PPLA-mm"` no response, mas o código atualizado no repo usa modo dots.

## Plano de correção

### 1. Publicar o projeto (Publish/Deploy)
Para que as alterações do `agente_impressao.py` cheguem ao GitHub `main`, é necessário publicar/fazer deploy do projeto. Isso sincroniza o repositório Lovable com o GitHub.

### 2. Forçar update nos agentes
Após a publicação, acessar a tela de Agentes no sistema e clicar para forçar o update em ambos os PCs (Daniel e Edi). O endpoint `/update` vai detectar que o hash mudou e vai baixar a versão nova automaticamente.

### 3. Validar
Após o update, o endpoint `/health` deve refletir a versão nova e a impressão WYSIWYG deve funcionar — as edições de texto no editor serão reproduzidas na etiqueta.

## Nenhuma alteração de código necessária
O código WYSIWYG já está correto no repo. O problema é puramente de deploy/publicação.

