@echo off
title ProPharmacos - Agente de Impressao
color 0A

:INICIO
echo.
echo ============================================
echo  ProPharmacos - Agente de Impressao PPLA
echo ============================================
echo.

REM Ir para a pasta do script
cd /d "%~dp0"

REM Verificar se Python esta disponivel
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado. Instale o Python e tente novamente.
    pause
    exit /b 1
)

REM Verificar conexao com internet para update automatico
echo Verificando atualizacoes no GitHub...
python -c "import urllib.request; urllib.request.urlopen('https://github.com', timeout=5)" >nul 2>&1
if not errorlevel 1 (
    echo Baixando versao mais recente do agente...
    python -c "
import urllib.request, os, sys
url = 'https://raw.githubusercontent.com/marketingpropharmacos/data-label-automaton/main/agente_impressao.py'
try:
    req = urllib.request.Request(url, headers={'Cache-Control': 'no-cache'})
    with urllib.request.urlopen(req, timeout=15) as r:
        novo = r.read().decode('utf-8')
    with open('agente_impressao.py', 'r', encoding='utf-8') as f:
        atual = f.read()
    if novo != atual:
        with open('agente_impressao.py.bak', 'w', encoding='utf-8') as f:
            f.write(atual)
        with open('agente_impressao.py', 'w', encoding='utf-8') as f:
            f.write(novo)
        print('ATUALIZADO - nova versao baixada do GitHub')
    else:
        print('Ja esta na versao mais recente')
except Exception as e:
    print(f'Nao foi possivel atualizar: {e}')
"
) else (
    echo Sem conexao com internet - usando versao local
)

echo.
echo Iniciando agente de impressao...
echo Para parar: feche esta janela ou pressione Ctrl+C
echo.

REM Iniciar o agente
python agente_impressao.py

REM Se o agente parar, aguarda 3 segundos e reinicia
echo.
echo Agente encerrado. Reiniciando em 3 segundos...
timeout /t 3 /nobreak >nul
goto INICIO
