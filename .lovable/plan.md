

# Plano: Remover Mapeamento Incorreto de Filiais

## Problema Identificado

O arquivo `servidor.py` contém um **mapeamento de filiais** que está redirecionando todas as buscas da filial 392 para a filial 279:

```python
# Linha 24-26
FILIAL_MAP = {
    392: 279,  # ← ESTE É O PROBLEMA!
}
```

### Fluxo Atual (Errado)

1. Frontend envia: `GET /api/requisicao/6806?filial=392`
2. Servidor recebe `filial=392`
3. Função `mapear_filial(392)` retorna `279`
4. Query busca: `WHERE NRRQU = 6806 AND CDFIL = 279`
5. Resultado: Dados do médico "BRUNA CATALLANI" (filial 279)

### Fluxo Esperado (Correto)

1. Frontend envia: `GET /api/requisicao/6806?filial=392`
2. Servidor recebe `filial=392`
3. Query busca: `WHERE NRRQU = 6806 AND CDFIL = 392`
4. Resultado: Dados do médico "LENIE" (filial 392)

---

## Solução

Remover a entrada `392: 279` do dicionário `FILIAL_MAP`, deixando-o vazio.

### Arquivo: `servidor.py`

| Linha | Antes | Depois |
|-------|-------|--------|
| 24-26 | `FILIAL_MAP = { 392: 279, }` | `FILIAL_MAP = { }` |

---

## Alteração Específica

**Antes (linhas 21-28):**
```python
# --- Mapeamento de filiais (Frontend -> Código no Firebird) ---
# Em algumas instalações, o frontend usa um "código de filial" diferente do CDFIL do banco.
# Ex.: Frontend 392 -> Banco 279 (PROPHARMACOS). Ajuste conforme necessário.
FILIAL_MAP = {
    392: 279,
}
def mapear_filial(filial: int) -> int:
    return FILIAL_MAP.get(filial, filial)
```

**Depois (linhas 21-28):**
```python
# --- Mapeamento de filiais (Frontend -> Código no Firebird) ---
# Em algumas instalações, o frontend usa um "código de filial" diferente do CDFIL do banco.
# Deixe vazio se o frontend usar o mesmo código CDFIL do banco.
FILIAL_MAP = {
    # Adicione mapeamentos aqui se necessário, ex: 999: 1
}
def mapear_filial(filial: int) -> int:
    return FILIAL_MAP.get(filial, filial)
```

---

## Passos Após Aprovação

1. Vou aplicar a alteração no arquivo `servidor.py`
2. Você copia o arquivo para `C:\ServidorRotulos\servidor.py`
3. Reinicia o servidor Python (Ctrl+C e executa novamente)
4. Testa: `http://localhost:5000/api/requisicao/6806?filial=392`
5. O médico deve aparecer como "LENIE"

---

## Por Que Este Mapeamento Existia?

O mapeamento foi criado assumindo que o frontend usa um código diferente do banco. Porém, se o seu sistema já usa o CDFIL correto (392), o mapeamento está causando o problema.

**Se no futuro** você precisar que o frontend use um código diferente do banco, basta adicionar a regra novamente.

---

## Impacto

- **Risco**: Nenhum - apenas remove redirecionamento incorreto
- **Benefício**: Filial 392 será consultada corretamente
- **Compatibilidade**: Todas as outras filiais continuam funcionando normalmente

