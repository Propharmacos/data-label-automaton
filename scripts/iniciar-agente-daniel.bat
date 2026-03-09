@echo off
title Agente de Impressao - PC do Daniel
echo ============================================
echo   Iniciando Agente de Impressao (Daniel)
echo ============================================
echo.

cd /d C:\ServidorRotulos

:: Inicia o agente Python em background
start "Agente Impressao" python agente_impressao.py

:: Aguarda 3 segundos para o agente subir
timeout /t 3 /nobreak >nul

:: Inicia o tunel ngrok na porta do agente
echo Iniciando tunel ngrok...
start "Ngrok Tunnel" ngrok http 5001

echo.
echo Agente e ngrok iniciados!
echo Copie a URL HTTPS do ngrok e configure no sistema.
echo NAO feche estas janelas!
pause
