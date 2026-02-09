"""
Agente de Impressão Local - ProPharmacos
Protocolo: PPLB (compatível Argox OS-2140)
Porta: 5001
Instalação: pip install flask flask-cors pywin32
Execução: python agente_impressao.py
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import platform

if platform.system() == 'Windows':
    try:
        import win32print
        PRINTING_AVAILABLE = True
    except ImportError:
        print("ERRO: pywin32 não instalado. Execute: pip install pywin32")
        PRINTING_AVAILABLE = False
else:
    PRINTING_AVAILABLE = False

app = Flask(__name__)
CORS(app)

IMPRESSORA_PADRAO = "AMP PEQUENO"


# ============================================
# PPLB TEXT HELPER
# ============================================
# Formato PPLB texto: 1RFWH[YYYYY][XXXXX]DATA
# R=rotação(1=0°,2=90°,3=180°,4=270°), F=fonte(0-4), W=mult larg, H=mult alt
# YYYYY=posição Y (5 dígitos), XXXXX=posição X (5 dígitos)

def pplb_text(rot, font, wmult, hmult, y, x, data):
    """Gera uma linha de texto PPLB."""
    return f"1{rot}{font}{wmult}{hmult}{y:05d}{x:05d}{data}"


def pplb_label(linhas):
    """
    Monta um label PPLB completo.
    linhas = lista de strings (cada uma é um comando PPLB de texto/barcode)
    """
    partes = [
        "\x02L",       # STX + início do label
        "H10",         # Heat setting
        "D11",         # Density
    ]
    partes.extend(linhas)
    partes.append("E")  # Fim / imprimir
    return "\r\n".join(partes) + "\r\n"


# ============================================
# GERAÇÃO DE COMANDOS PPLB POR LAYOUT
# ============================================
# Argox OS-2140 @ 203dpi: 76mm ≈ 608 dots, 35mm ≈ 280 dots

def gerar_pplb_ampcx(rotulo, farmacia):
    """Layout AMP_CX (76x35mm) - 7 linhas"""
    paciente = (rotulo.get('nomePaciente', '') or '')[:35].upper()
    nr_req = rotulo.get('nrRequisicao', '')
    nr_item = rotulo.get('nrItem', '1')
    nome_medico = (rotulo.get('nomeMedico', '') or '').upper()
    crm = _crm_completo(rotulo)
    composicao = _composicao(rotulo, 50)
    linha_meta = _linha_meta(rotulo)
    aplicacao = (rotulo.get('aplicacao', '') or '')[:30].upper()
    contem = (rotulo.get('contem', '') or '')[:30].upper()
    registro = rotulo.get('numeroRegistro', '')

    return pplb_label([
        pplb_text(1, 2, 1, 1, 10, 10, paciente),
        pplb_text(1, 2, 1, 1, 10, 450, f"REQ:{nr_req}-{nr_item}"),
        pplb_text(1, 2, 1, 1, 50, 10, f"DR. {nome_medico[:25]} CRM {crm}"),
        pplb_text(1, 2, 1, 1, 80, 10, composicao),
        pplb_text(1, 2, 1, 1, 115, 10, linha_meta),
        pplb_text(1, 2, 1, 1, 145, 10, f"APLICACAO: {aplicacao}"),
        pplb_text(1, 2, 1, 1, 175, 10, f"CONTEM: {contem}"),
        pplb_text(1, 2, 1, 1, 205, 10, f"Reg: {registro}"),
    ])


def gerar_pplb_amp10(rotulo, farmacia):
    """Layout AMP10 (76x35mm) - 7 linhas, registro na linha 5"""
    paciente = (rotulo.get('nomePaciente', '') or '')[:35].upper()
    nr_req = rotulo.get('nrRequisicao', '')
    nr_item = rotulo.get('nrItem', '1')
    nome_medico = (rotulo.get('nomeMedico', '') or '').upper()
    crm = _crm_completo(rotulo)
    composicao = _composicao(rotulo, 50)
    linha_meta = _linha_meta(rotulo)
    registro = rotulo.get('numeroRegistro', '')
    aplicacao = (rotulo.get('aplicacao', '') or '')[:30].upper()
    contem = (rotulo.get('contem', '') or '')[:30].upper()

    return pplb_label([
        pplb_text(1, 2, 1, 1, 10, 10, paciente),
        pplb_text(1, 2, 1, 1, 10, 450, f"REQ:{nr_req}-{nr_item}"),
        pplb_text(1, 2, 1, 1, 50, 10, f"DR. {nome_medico[:25]} CRM {crm}"),
        pplb_text(1, 2, 1, 1, 80, 10, composicao),
        pplb_text(1, 2, 1, 1, 115, 10, linha_meta),
        pplb_text(1, 2, 1, 1, 145, 10, f"REG: {registro}  {composicao[:20]}"),
        pplb_text(1, 2, 1, 1, 175, 10, f"APLICACAO: {aplicacao}"),
        pplb_text(1, 2, 1, 1, 205, 10, f"CONTEM: {contem}"),
    ])


def gerar_pplb_a_pac_peq(rotulo, farmacia):
    """Layout A.PAC.PEQ - 3 linhas mínimas"""
    paciente = (rotulo.get('nomePaciente', '') or '')[:35].upper()
    nr_req = rotulo.get('nrRequisicao', '')
    nr_item = rotulo.get('nrItem', '1')
    nome_medico = (rotulo.get('nomeMedico', '') or '').upper()
    crm = _crm_completo(rotulo)
    registro = rotulo.get('numeroRegistro', '')

    return pplb_label([
        pplb_text(1, 2, 1, 1, 20, 10, f"{paciente}  REQ:{nr_req}-{nr_item}"),
        pplb_text(1, 2, 1, 1, 60, 10, f"DR. {nome_medico[:30]} CRM {crm}"),
        pplb_text(1, 2, 1, 1, 100, 10, f"REG: {registro}"),
    ])


def gerar_pplb_a_pac_gran(rotulo, farmacia):
    """Layout A.PAC.GRAN - 2 linhas compactas"""
    paciente = (rotulo.get('nomePaciente', '') or '')[:35].upper()
    nr_req = rotulo.get('nrRequisicao', '')
    nr_item = rotulo.get('nrItem', '1')
    nome_medico = (rotulo.get('nomeMedico', '') or '').upper()
    crm = _crm_completo(rotulo)
    registro = rotulo.get('numeroRegistro', '')

    return pplb_label([
        pplb_text(1, 2, 1, 1, 20, 10, f"{paciente}  REQ:{nr_req}-{nr_item}"),
        pplb_text(1, 2, 1, 1, 60, 10, f"DR. {nome_medico[:25]} CRM {crm}  REG:{registro}"),
    ])


def gerar_pplb_tirz(rotulo, farmacia):
    """Layout TIRZ (Tirzepatida) - 7 linhas com posologia"""
    paciente = (rotulo.get('nomePaciente', '') or '')[:35].upper()
    nr_req = rotulo.get('nrRequisicao', '')
    nr_item = rotulo.get('nrItem', '1')
    nome_medico = (rotulo.get('nomeMedico', '') or '').upper()
    crm = _crm_completo(rotulo)
    composicao = _composicao(rotulo, 50)
    posologia = (rotulo.get('posologia', '') or '')[:50].upper()
    linha_meta = _linha_meta(rotulo)
    aplicacao = (rotulo.get('aplicacao', '') or '')[:30].upper()
    contem = (rotulo.get('contem', '') or '')[:30].upper()
    registro = rotulo.get('numeroRegistro', '')

    return pplb_label([
        pplb_text(1, 2, 1, 1, 10, 10, paciente),
        pplb_text(1, 2, 1, 1, 10, 450, f"REQ:{nr_req}-{nr_item}"),
        pplb_text(1, 2, 1, 1, 50, 10, f"DR. {nome_medico[:25]} CRM {crm}"),
        pplb_text(1, 2, 1, 1, 80, 10, composicao),
        pplb_text(1, 2, 1, 1, 115, 10, posologia),
        pplb_text(1, 2, 1, 1, 145, 10, linha_meta),
        pplb_text(1, 2, 1, 1, 175, 10, f"APLICACAO: {aplicacao}"),
        pplb_text(1, 2, 1, 1, 205, 10, f"CONTEM: {contem}  REG:{registro}"),
    ])


# ============================================
# HELPERS
# ============================================

def _crm_completo(rotulo):
    prefixo = rotulo.get('prefixoCRM', '')
    numero = rotulo.get('numeroCRM', '')
    uf = rotulo.get('ufCRM', '')
    return f"{prefixo}{numero}/{uf}".strip('/')


def _composicao(rotulo, max_len=50):
    comp = rotulo.get('composicao', '') or rotulo.get('formula', '')
    return (comp or '')[:max_len].upper()


def _linha_meta(rotulo):
    parts = []
    ph = rotulo.get('ph', '')
    lote = rotulo.get('lote', '')
    fab = rotulo.get('dataFabricacao', '')
    val = rotulo.get('dataValidade', '')
    if ph: parts.append(f"pH:{ph}")
    if lote: parts.append(f"LT:{lote}")
    if fab: parts.append(f"F:{fab}")
    if val: parts.append(f"V:{val}")
    return " ".join(parts)


# Mapa de geradores
GERADORES_PPLB = {
    'AMP_CX': gerar_pplb_ampcx,
    'AMP10': gerar_pplb_amp10,
    'A_PAC_PEQ': gerar_pplb_a_pac_peq,
    'A_PAC_GRAN': gerar_pplb_a_pac_gran,
    'TIRZ': gerar_pplb_tirz,
}


def enviar_para_impressora(nome_impressora, comandos_pplb):
    """Envia comandos PPLB para a impressora via win32print."""
    if not PRINTING_AVAILABLE:
        return {"success": False, "error": "pywin32 não disponível"}
    try:
        hPrinter = win32print.OpenPrinter(nome_impressora)
        try:
            hJob = win32print.StartDocPrinter(hPrinter, 1, ("Etiqueta", None, "RAW"))
            try:
                win32print.StartPagePrinter(hPrinter)
                dados = comandos_pplb.encode('cp850', errors='replace')
                win32print.WritePrinter(hPrinter, dados)
                win32print.EndPagePrinter(hPrinter)
            finally:
                win32print.EndDocPrinter(hPrinter)
        finally:
            win32print.ClosePrinter(hPrinter)
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}


# ============================================
# ENDPOINTS
# ============================================

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "online",
        "impressora_padrao": IMPRESSORA_PADRAO,
        "sistema": platform.system(),
        "impressao_disponivel": PRINTING_AVAILABLE,
    })


@app.route('/impressoras', methods=['GET'])
def listar_impressoras():
    if not PRINTING_AVAILABLE:
        return jsonify({"impressoras": [], "padrao": ""})
    try:
        printers = []
        for flags, descr, name, comment in win32print.EnumPrinters(
            win32print.PRINTER_ENUM_LOCAL | win32print.PRINTER_ENUM_CONNECTIONS
        ):
            printers.append(name)
        padrao = win32print.GetDefaultPrinter()
        return jsonify({"impressoras": printers, "padrao": padrao})
    except Exception as e:
        return jsonify({"impressoras": [], "padrao": "", "error": str(e)})


@app.route('/teste', methods=['POST'])
def teste_impressao():
    """Imprime etiqueta de teste PPLB."""
    impressora = request.json.get('impressora', IMPRESSORA_PADRAO) if request.json else IMPRESSORA_PADRAO

    comandos = pplb_label([
        pplb_text(1, 3, 1, 1, 30, 10, "*** TESTE DE IMPRESSAO ***"),
        pplb_text(1, 2, 1, 1, 80, 10, "Argox OS-2140 - PPLB"),
        pplb_text(1, 2, 1, 1, 120, 10, "Agente de Impressao OK!"),
        pplb_text(1, 0, 1, 1, 170, 10, f"Impressora: {impressora}"),
    ])

    resultado = enviar_para_impressora(impressora, comandos)
    if resultado["success"]:
        return jsonify({"success": True, "message": "Teste enviado com sucesso"})
    else:
        return jsonify({"success": False, "error": resultado["error"]}), 500


@app.route('/imprimir', methods=['POST'])
def imprimir():
    """Recebe JSON com dados dos rótulos e imprime via PPLB."""
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "Nenhum dado recebido"}), 400

    impressora = data.get('impressora', '') or IMPRESSORA_PADRAO
    layout_tipo = data.get('layout_tipo', 'AMP_CX')
    farmacia = data.get('farmacia', {})
    rotulos = data.get('rotulos', [])

    if not rotulos:
        return jsonify({"success": False, "error": "Nenhum rótulo para imprimir"}), 400

    gerador = GERADORES_PPLB.get(layout_tipo, gerar_pplb_ampcx)
    impressos = 0
    erros = []

    for rotulo in rotulos:
        try:
            comandos = gerador(rotulo, farmacia)
            print(f"[AGENTE] Imprimindo rótulo {rotulo.get('id', '?')} layout={layout_tipo} impressora={impressora}")
            resultado = enviar_para_impressora(impressora, comandos)
            if resultado["success"]:
                impressos += 1
            else:
                erros.append(f"Rótulo {rotulo.get('id', '?')}: {resultado['error']}")
        except Exception as e:
            erros.append(f"Rótulo {rotulo.get('id', '?')}: {str(e)}")

    if impressos == len(rotulos):
        return jsonify({"success": True, "impressos": impressos})
    elif impressos > 0:
        return jsonify({"success": True, "impressos": impressos, "erros": erros})
    else:
        return jsonify({"success": False, "error": "Nenhum rótulo impresso", "erros": erros}), 500


if __name__ == '__main__':
    print("=" * 50)
    print("Agente de Impressão PPLB - ProPharmacos")
    print(f"Porta: 5001")
    print(f"Impressora padrão: {IMPRESSORA_PADRAO}")
    print(f"Impressão disponível: {PRINTING_AVAILABLE}")
    print(f"Teste: http://localhost:5001/health")
    print("=" * 50)
    app.run(host='0.0.0.0', port=5001, debug=True, threaded=True)
