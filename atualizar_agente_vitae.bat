@echo off
title Atualizar Agente Vitae
color 0B
cd /d C:\ServidorRotulos

:: ─── TOKEN GITHUB ─────────────────────────────────────────────────────────
if not exist "C:\ServidorRotulos\gh_token.txt" (
    echo [ERRO] gh_token.txt nao encontrado em C:\ServidorRotulos\
    echo Crie o arquivo com o token GitHub na primeira linha.
    pause
    exit /b 1
)
set /p GH_TOKEN=<"C:\ServidorRotulos\gh_token.txt"

echo =========================================
echo   Atualizando agente_vitae.py
echo =========================================
echo.

:: ─── Download do GitHub ───────────────────────────────────────────────────
curl -s -L -o agente_vitae.py.tmp ^
     -H "Authorization: token %GH_TOKEN%" ^
     -H "User-Agent: Mozilla/5.0" ^
     "https://raw.githubusercontent.com/marketingpropharmacos/data-label-automaton/main/agente_vitae.py"

if errorlevel 1 (
    echo [ERRO] Falha no download. Verifique a conexao.
    del agente_vitae.py.tmp >nul 2>&1
    pause
    exit /b 1
)

for %%A in (agente_vitae.py.tmp) do set TAMANHO=%%~zA
if %TAMANHO% LSS 1000 (
    echo [ERRO] Arquivo invalido ^(%TAMANHO% bytes^). Token expirado?
    del agente_vitae.py.tmp >nul 2>&1
    pause
    exit /b 1
)

move /Y agente_vitae.py.tmp agente_vitae.py >nul
echo [OK] agente_vitae.py atualizado! ^(%TAMANHO% bytes^)
echo.

:: ─── Encerrar janela do agente (se existir) ───────────────────────────────
echo Encerrando janela do agente...
taskkill /F /FI "WINDOWTITLE eq Agente Vitae*" >nul 2>&1

:: ─── Matar processo Python na porta 5001 (mata o filho que fica rodando) ──
echo Liberando porta 5001...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":5001 "') do (
    echo   Matando PID %%a
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 3 /nobreak >nul

:: ─── Verificar se a porta realmente liberou ───────────────────────────────
netstat -aon 2>nul | findstr ":5001 " >nul 2>&1
if not errorlevel 1 (
    echo [AVISO] Porta 5001 ainda ocupada — aguardando mais 5s...
    timeout /t 5 /nobreak >nul
)

:: ─── Iniciar novo agente ──────────────────────────────────────────────────
echo.
echo Iniciando agente na porta 5001...
start "Agente Vitae - porta 5001" cmd /k "cd /d C:\ServidorRotulos && python agente_vitae.py"
timeout /t 4 /nobreak >nul

echo.
echo =========================================
echo   Agente reiniciado!
echo.
echo   Health:  https://authentic-unworried-ounce.ngrok-free.dev/api/health
echo   Debug:   https://authentic-unworried-ounce.ngrok-free.dev/api/debug/funcionarios?q=Bruno
echo =========================================
echo.
pause
