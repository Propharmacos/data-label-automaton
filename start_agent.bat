@echo off
title ProPharmacos - Agente de Impressao
color 0A
cd /d "C:\servidor_rotulos"

if not exist "C:\servidor_rotulos" (
    echo ERRO: Pasta C:\servidor_rotulos nao encontrada!
    pause
    exit /b 1
)

REM Definir ID do agente (edi ou daniel) — lido do arquivo agente_id.txt se existir
REM Para configurar: crie C:\servidor_rotulos\agente_id.txt contendo apenas: edi  (ou daniel)
if not defined AGENTE_ID (
    if exist "C:\servidor_rotulos\agente_id.txt" (
        set /p AGENTE_ID=<"C:\servidor_rotulos\agente_id.txt"
    )
)
if defined AGENTE_ID (
    echo Agente ID: %AGENTE_ID%
)

:LOOP
echo.
echo [%date% %time%] ============================================
echo  ProPharmacos - Agente de Impressao PPLA
echo ============================================

REM Iniciar ngrok em background se existir e nao estiver rodando
tasklist /FI "IMAGENAME eq ngrok.exe" 2>nul | find /I "ngrok.exe" >nul
if errorlevel 1 (
    if exist "C:\servidor_rotulos\ngrok.exe" (
        echo Iniciando ngrok...
        start "" /B "C:\servidor_rotulos\ngrok.exe" http 5002
        timeout /t 3 /nobreak >nul
    ) else if exist "C:\ngrok\ngrok.exe" (
        echo Iniciando ngrok...
        start "" /B "C:\ngrok\ngrok.exe" http 5002
        timeout /t 3 /nobreak >nul
    ) else if exist "C:\Users\%USERNAME%\ngrok.exe" (
        echo Iniciando ngrok...
        start "" /B "C:\Users\%USERNAME%\ngrok.exe" http 5002
        timeout /t 3 /nobreak >nul
    ) else (
        echo ngrok nao encontrado - pulando.
    )
) else (
    echo ngrok ja esta rodando.
)

echo Iniciando agente de impressao...
python agente_impressao.py

echo.
echo [%date% %time%] Agente parou. Reiniciando em 5 segundos...
timeout /t 5 /nobreak >nul
goto LOOP
