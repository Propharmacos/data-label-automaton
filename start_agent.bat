@echo off
title ProPharmacos - Agente de Impressao
color 0A
cd /d "C:\servidor_rotulos"

:INICIO
echo.
echo ============================================
echo  ProPharmacos - Agente de Impressao PPLA
echo  Pasta: C:\servidor_rotulos
echo ============================================
echo.

REM Tentar encontrar o Python
set PYTHON=
for %%p in (python python3 py) do (
    if not defined PYTHON (
        %%p --version >nul 2>&1 && set PYTHON=%%p
    )
)

if not defined PYTHON (
    echo [ERRO] Python nao encontrado no sistema.
    echo Instale o Python em python.org e marque "Add to PATH"
    echo.
    pause
    exit /b 1
)

echo Python encontrado: %PYTHON%
echo.

REM Verificar update no GitHub
echo Verificando atualizacoes...
%PYTHON% -c "
import urllib.request, os, hashlib

url = 'https://raw.githubusercontent.com/marketingpropharmacos/data-label-automaton/main/agente_impressao.py'
caminho = r'C:\servidor_rotulos\agente_impressao.py'

try:
    req = urllib.request.Request(url, headers={'Cache-Control': 'no-cache'})
    with urllib.request.urlopen(req, timeout=15) as r:
        novo = r.read().decode('utf-8')

    atual = ''
    if os.path.exists(caminho):
        with open(caminho, 'r', encoding='utf-8') as f:
            atual = f.read()

    h = lambda x: hashlib.md5(x.encode()).hexdigest()
    if h(novo) != h(atual):
        with open(caminho + '.bak', 'w', encoding='utf-8') as f:
            f.write(atual)
        with open(caminho, 'w', encoding='utf-8') as f:
            f.write(novo)
        print('ATUALIZADO - nova versao baixada do GitHub!')
    else:
        print('Ja esta na versao mais recente.')
except Exception as e:
    print(f'Sem update (offline ou erro): {e}')
"

echo.
echo Iniciando agente... (nao feche esta janela)
echo.

%PYTHON% "C:\servidor_rotulos\agente_impressao.py"

echo.
echo [AVISO] Agente encerrado. Reiniciando em 5 segundos...
timeout /t 5 /nobreak >nul
goto INICIO
