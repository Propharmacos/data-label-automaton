@echo off
title ProPharmacos - Agente de Impressao
color 0A

REM Detectar pasta correta automaticamente
if exist "C:\ServidorRotulos\agente_impressao.py" (
    set PASTA=C:\ServidorRotulos
) else if exist "C:\servidor_rotulos\agente_impressao.py" (
    set PASTA=C:\servidor_rotulos
) else (
    echo ERRO: Pasta do agente nao encontrada!
    echo Verifique se existe C:\ServidorRotulos ou C:\servidor_rotulos
    pause
    exit /b 1
)

cd /d "%PASTA%"

REM Ler ID do agente
if not defined AGENTE_ID (
    if exist "%PASTA%\agente_id.txt" (
        set /p AGENTE_ID=<"%PASTA%\agente_id.txt"
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

REM Iniciar ngrok em janela propria se nao estiver rodando
tasklist /FI "IMAGENAME eq ngrok.exe" 2>nul | find /I "ngrok.exe" >nul
if errorlevel 1 (
    if exist "%PASTA%\ngrok.exe" (
        echo Iniciando ngrok...
        start "ngrok - ProPharmacos" "%PASTA%\ngrok.exe" http 5002
        timeout /t 5 /nobreak >nul
    ) else if exist "C:\ngrok\ngrok.exe" (
        echo Iniciando ngrok...
        start "ngrok - ProPharmacos" "C:\ngrok\ngrok.exe" http 5002
        timeout /t 5 /nobreak >nul
    ) else if exist "C:\Users\%USERNAME%\ngrok.exe" (
        echo Iniciando ngrok...
        start "ngrok - ProPharmacos" "C:\Users\%USERNAME%\ngrok.exe" http 5002
        timeout /t 5 /nobreak >nul
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
