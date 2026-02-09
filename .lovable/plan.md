

# Diagnostico e Correcao: Kit Sinonimo OBSFIC

## Situacao Atual

O codigo em `servidor.py` (no projeto Lovable) ja contem todas as alteracoes corretas:
- Funcao `extrair_obsfic_componente` (linha 852)
- Flag `e_sinonimo` em `montar_kit_expandido` (linha 1115)
- Chamada com `e_sinonimo` no loop principal (linha 3756)
- Frontend `LabelCard.tsx` ja renderiza `comp.composicao` para sinonimos (linhas 222, 439)

## Diagnostico: Por que nao funciona?

Existem 2 possibilidades:

### Possibilidade 1: Servidor local desatualizado (mais provavel)

O Flask roda em `C:\ServidorRotulos\servidor.py`. Se este arquivo nao foi atualizado com as mudancas do projeto Lovable, a logica antiga ainda esta em execucao.

**Acao**: Copiar o `servidor.py` do projeto para `C:\ServidorRotulos\servidor.py` e reiniciar o servidor.

### Possibilidade 2: Formato do ARGUMENTO na FC99999

A funcao `extrair_obsfic_componente` usa `STARTING WITH 'OBSFIC92607'`, mas o campo ARGUMENTO na FC99999 pode ter formato diferente:
- Pode ter espacos: `'OBSFIC 92607'`
- Pode ter zeros a esquerda: `'OBSFIC00092607'`
- O campo ARGUMENTO pode ser CHAR (com padding de espacos)

## Plano de Acao

### 1. Confirmar que o servidor local esta atualizado

Verificar se o `servidor.py` em `C:\ServidorRotulos\` contem a funcao `extrair_obsfic_componente`. Se nao, copiar o arquivo do projeto.

### 2. Adicionar endpoint de debug para OBSFIC

Criar um endpoint `/api/debug/obsfic/<cdpro>` no `servidor.py` para inspecionar exatamente o que a FC99999 retorna:

```python
@app.route('/api/debug/obsfic/<cdpro>')
def debug_obsfic(cdpro):
    """Debug: mostra OBSFIC bruto de um componente"""
    cursor = get_cursor()
    cdpro_str = str(cdpro).strip()
    
    # Busca 1: STARTING WITH (como a funcao faz)
    cursor.execute("""
        SELECT ARGUMENTO, SUBARGUM, PARAMETRO, DESCRPAR 
        FROM FC99999 
        WHERE ARGUMENTO STARTING WITH ?
        ORDER BY SUBARGUM
    """, (f'OBSFIC{cdpro_str}',))
    resultado_starting = []
    for row in cursor.fetchall():
        arg = row[0]
        if hasattr(arg, 'read'):
            arg = arg.read().decode('latin-1')
        param = row[2]
        if param and hasattr(param, 'read'):
            param = param.read().decode('latin-1')
        descrpar = row[3]
        if descrpar and hasattr(descrpar, 'read'):
            descrpar = descrpar.read().decode('latin-1')
        resultado_starting.append({
            "argumento": str(arg).strip(),
            "subargum": str(row[1]).strip(),
            "parametro": str(param).strip() if param else "",
            "descrpar": str(descrpar).strip() if descrpar else ""
        })
    
    # Busca 2: LIKE (mais flexivel)
    cursor.execute("""
        SELECT ARGUMENTO, SUBARGUM, PARAMETRO, DESCRPAR 
        FROM FC99999 
        WHERE ARGUMENTO LIKE ?
        ORDER BY SUBARGUM
    """, (f'%OBSFIC%{cdpro_str}%',))
    resultado_like = []
    for row in cursor.fetchall():
        arg = row[0]
        if hasattr(arg, 'read'):
            arg = arg.read().decode('latin-1')
        param = row[2]
        if param and hasattr(param, 'read'):
            param = param.read().decode('latin-1')
        descrpar = row[3]
        if descrpar and hasattr(descrpar, 'read'):
            descrpar = descrpar.read().decode('latin-1')
        resultado_like.append({
            "argumento": str(arg).strip(),
            "subargum": str(row[1]).strip(),
            "parametro": str(param).strip() if param else "",
            "descrpar": str(descrpar).strip() if descrpar else ""
        })
    
    return jsonify({
        "cdpro": cdpro_str,
        "starting_with": resultado_starting,
        "like": resultado_like,
        "count_starting": len(resultado_starting),
        "count_like": len(resultado_like)
    })
```

### 3. Testar o endpoint de debug

Acessar no navegador:
- `http://localhost:5000/api/debug/obsfic/92607`
- `http://localhost:5000/api/debug/obsfic/92729`

Se `starting_with` retornar vazio mas `like` retornar dados, o formato do ARGUMENTO e diferente do esperado e a funcao `extrair_obsfic_componente` precisa de ajuste.

### 4. Corrigir formato se necessario

Com base no resultado do debug, ajustar a query em `extrair_obsfic_componente` para usar o formato correto do ARGUMENTO.

## Detalhes Tecnicos

### Arquivo modificado
- `servidor.py` - novo endpoint de debug `/api/debug/obsfic/<cdpro>`

### Sequencia de teste
1. Copiar `servidor.py` atualizado para `C:\ServidorRotulos\`
2. Reiniciar o Flask
3. Acessar `/api/debug/obsfic/92607` para validar dados
4. Buscar req 6806-2 e verificar nos logs do terminal se aparece `[OBSFIC_COMP]`
5. Confirmar no frontend se a composicao aparece no rotulo

