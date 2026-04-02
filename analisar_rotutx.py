"""
Analisa os ultimos 100 ROTUTX do banco Firebird (FC12300)
e extrai padroes comuns por tipo de layout (ROTUID).

Uso: python analisar_rotutx.py
"""

import fdb
import re
from collections import defaultdict

DB_PATH     = '192.168.5.4/3050:D:\\Fcerta\\DB\\ALTERDB.IB'
DB_USER     = 'SYSDBA'
DB_PASSWORD = 'masterkey'

def get_conn():
    return fdb.connect(dsn=DB_PATH, user=DB_USER, password=DB_PASSWORD)

def decode_rotutx(blob_data):
    """Decodifica o BLOB ROTUTX para string (cp1252 ou latin-1)."""
    if blob_data is None:
        return None
    if isinstance(blob_data, (bytes, bytearray)):
        try:
            return blob_data.decode('cp1252')
        except Exception:
            return blob_data.decode('latin-1', errors='replace')
    return str(blob_data)

def extrair_setup(ppla):
    """Extrai comandos de setup (antes do primeiro campo de texto)."""
    linhas = ppla.replace('\r\n', '\r').split('\r')
    setup = []
    for linha in linhas:
        linha = linha.strip('\x02').strip()
        if not linha:
            continue
        # Para quando começa campo de texto (linha com muitos dígitos = coordenada)
        if re.match(r'^[01]\d{10,}', linha):
            break
        setup.append(linha)
    return setup

def extrair_campos(ppla):
    """Extrai todos os campos de texto com rot/font/wmult/hmult/y/x."""
    linhas = ppla.replace('\r\n', '\r').split('\r')
    campos = []
    for linha in linhas:
        linha_clean = linha.strip('\x02').strip()
        # Formato dots: R(1)F(1)W(1)H(1)YYYYYYY(7)XXXX(4)texto
        m = re.match(r'^([01])(\d)(\d)(\d)(\d{7})(\d{4})(.+)$', linha_clean)
        if m:
            campos.append({
                'rot': m.group(1),
                'font': m.group(2),
                'wmult': m.group(3),
                'hmult': m.group(4),
                'y': int(m.group(5)),
                'x': int(m.group(6)),
                'texto': m.group(7)[:40],
            })
            continue
        # Formato mm: R(1)F(1)W(1)H(1)YYYY(4)XXXX(4)texto
        m2 = re.match(r'^([01])(\d)(\d)(\d)(\d{4})(\d{4})(.+)$', linha_clean)
        if m2:
            campos.append({
                'rot': m2.group(1),
                'font': m2.group(2),
                'wmult': m2.group(3),
                'hmult': m2.group(4),
                'y': int(m2.group(5)),
                'x': int(m2.group(6)),
                'texto': m2.group(7)[:40],
                'modo': 'mm'
            })
    return campos

def get_colunas(cur, tabela):
    cur.execute("""
        SELECT TRIM(RDB$FIELD_NAME)
        FROM RDB$RELATION_FIELDS
        WHERE RDB$RELATION_NAME = ?
        ORDER BY RDB$FIELD_POSITION
    """, (tabela,))
    return [r[0].strip().upper() for r in cur.fetchall()]

def analisar():
    print("Conectando ao banco Firebird...")
    conn = get_conn()
    cur = conn.cursor()

    # Descobre colunas reais da FC12300
    colunas = get_colunas(cur, 'FC12300')
    print(f"Colunas da FC12300: {colunas}\n")

    # Detecta coluna de item
    col_item = next((c for c in ('NRITE', 'NRITEM', 'NRIT', 'NR_ITEM') if c in colunas), None)
    # Detecta coluna de serie/layout
    col_serie = next((c for c in ('SERIER', 'SERIE', 'SERIERQ', 'SERIERQU', 'CDROT', 'ROTUID') if c in colunas), None)

    print(f"Coluna item: {col_item}")
    print(f"Coluna serie/layout: {col_serie}\n")

    # Monta SELECT com colunas corretas
    select_cols = f"NRRQU, CDFIL, {col_item or 'NULL'}, {col_serie or 'NULL'}, ROTUTX"
    print(f"Buscando ultimos 100 registros com ROTUTX...")
    cur.execute(f"""
        SELECT FIRST 100
            {select_cols}
        FROM FC12300
        WHERE ROTUTX IS NOT NULL
        ORDER BY NRRQU DESC
    """)

    rows = cur.fetchall()
    print(f"Encontrados: {len(rows)} registros\n")

    # Agrupa por col_serie (layout)
    por_layout = defaultdict(list)
    for nrreq, cdfil, nritem, rotuid, rotutx_blob in rows:
        ppla = decode_rotutx(rotutx_blob)
        if ppla:
            por_layout[str(rotuid).strip() if rotuid else 'SEM_SERIE'].append({
                'req': nrreq,
                'filial': cdfil,
                'item': nritem,
                'ppla': ppla,
            })

    print("=" * 60)
    print(f"LAYOUTS ENCONTRADOS: {list(por_layout.keys())}")
    print("=" * 60)

    for layout_id, registros in sorted(por_layout.items()):
        print(f"\n{'='*60}")
        print(f"LAYOUT: {layout_id}  ({len(registros)} registros)")
        print(f"{'='*60}")

        # Analisa setup de todos os registros
        todos_setups = [extrair_setup(r['ppla']) for r in registros]
        # Setup mais comum
        setup_exemplo = todos_setups[0] if todos_setups else []
        print(f"  Setup (exemplo req {registros[0]['req']}):")
        for s in setup_exemplo:
            print(f"    {repr(s)}")

        # Analisa campos do primeiro registro
        campos_exemplo = extrair_campos(registros[0]['ppla'])
        print(f"\n  Campos (exemplo req {registros[0]['req']} item {registros[0]['item']}):")
        for c in campos_exemplo:
            print(f"    rot={c['rot']} font={c['font']} wmult={c['wmult']} hmult={c['hmult']} "
                  f"y={c['y']:>7} x={c['x']:>4}  '{c['texto']}'")

        # Padroes comuns: fonts usadas
        todas_fonts = set()
        todos_y = set()
        todos_x = set()
        for r in registros:
            for c in extrair_campos(r['ppla']):
                todas_fonts.add(c['font'])
                todos_y.add(c['y'])
                todos_x.add(c['x'])

        print(f"\n  Padroes em {len(registros)} registros:")
        print(f"    Fonts usadas:  {sorted(todas_fonts)}")
        print(f"    Y positions:   {sorted(todos_y)}")
        print(f"    X positions:   {sorted(todos_x)}")

        # Mostra PPLA raw do primeiro exemplo
        print(f"\n  PPLA RAW (req {registros[0]['req']}, primeiros 600 chars):")
        ppla_raw = registros[0]['ppla']
        print(f"    {repr(ppla_raw[:600])}")

    conn.close()
    print("\n\nAnalise concluida.")

if __name__ == '__main__':
    analisar()
