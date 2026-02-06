

# Plano: Adicionar Endpoint de Diagnóstico e Corrigir Parâmetros Restantes

## Problema Identificado

O servidor Python no seu computador local **não está usando o arquivo atualizado**. As alterações que fizemos no Lovable precisam ser copiadas para o seu computador.

Além disso, encontrei **mais locais** no arquivo onde falta a conversão `int()`:

| Linha | Endpoint | Problema |
|-------|----------|----------|
| 1394 | `/api/debug/fc12110-completo` | `(nr_requisicao, filial)` sem `int()` |

---

## Solução em 2 Etapas

### Etapa 1: Corrigir Parâmetros Restantes

**Arquivo**: `servidor.py`

| Linha | Antes | Depois |
|-------|-------|--------|
| 1394 | `""", (nr_requisicao, filial))` | `""", (int(nr_requisicao), int(filial)))` |

### Etapa 2: Adicionar Endpoint de Diagnóstico Simples

Criar um endpoint `/api/debug/verificar-requisicao/<nr_requisicao>` que faz uma query mínima para confirmar se a requisição existe:

```python
@app.route('/api/debug/verificar-requisicao/<nr_requisicao>', methods=['GET'])
def debug_verificar_requisicao(nr_requisicao):
    """
    Endpoint simples para verificar se uma requisição existe no banco.
    Retorna apenas contagem de registros.
    """
    filial = request.args.get('filial', '1')
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Verifica FC12100 (cabeçalho da requisição)
        cursor.execute("""
            SELECT COUNT(*) FROM FC12100 
            WHERE NRRQU = ? AND CDFIL = ?
        """, (int(nr_requisicao), int(filial)))
        count_12100 = cursor.fetchone()[0]
        
        # Verifica FC12110 (itens da requisição)
        cursor.execute("""
            SELECT COUNT(*) FROM FC12110 
            WHERE NRRQU = ? AND CDFIL = ?
        """, (int(nr_requisicao), int(filial)))
        count_12110 = cursor.fetchone()[0]
        
        # Lista todas as filiais que têm essa requisição
        cursor.execute("""
            SELECT DISTINCT CDFIL FROM FC12100 
            WHERE NRRQU = ?
        """, (int(nr_requisicao),))
        filiais = [row[0] for row in cursor.fetchall()]
        
        conn.close()
        
        return jsonify({
            "success": True,
            "requisicao": nr_requisicao,
            "filialBuscada": filial,
            "encontradoFC12100": count_12100 > 0,
            "quantidadeFC12100": count_12100,
            "encontradoFC12110": count_12110 > 0,
            "quantidadeFC12110": count_12110,
            "filiaisDisponiveis": filiais,
            "mensagem": f"Requisição existe nas filiais: {filiais}" if filiais else "Requisição não encontrada em nenhuma filial"
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500
```

---

## Como Testar Após Atualizar

1. **Copiar** o arquivo `servidor.py` do Lovable para seu computador
2. **Reiniciar** o servidor (Ctrl+C e executar novamente)
3. **Testar** no navegador:
   ```
   http://localhost:5000/api/debug/verificar-requisicao/6806?filial=392
   ```

Se retornar `"filiaisDisponiveis": []` significa que a requisição 6806 **não existe** com filial 392. O endpoint mostrará em qual filial ela existe.

---

## Impacto

- **Risco**: Nenhum - apenas adiciona diagnóstico
- **Benefício**: Permite identificar rapidamente se o problema é a filial errada ou se a requisição não existe

