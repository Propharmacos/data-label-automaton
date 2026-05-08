@echo off
title Ativar Agente Completo
color 0A
cd /d C:\ServidorRotulos

echo =========================================
echo   Iniciando Agente Vitae + Ngrok
echo =========================================
echo.

:: Encerra processos anteriores se estiverem rodando
echo Encerrando processos anteriores...
taskkill /F /IM python.exe /T >nul 2>&1
taskkill /F /IM python3.exe /T >nul 2>&1
taskkill /F /IM ngrok.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul

:: Inicia o agente Python
echo Iniciando agente na porta 5001...
start "Agente Vitae - porta 5001" cmd /k "cd /d C:\ServidorRotulos && python agente_vitae.py"
timeout /t 3 /nobreak >nul
echo [OK] Agente iniciado

:: Inicia o ngrok
echo Iniciando ngrok...
start "Ngrok - Tunnel" cmd /k "ngrok http --domain=authentic-unworried-ounce.ngrok-free.dev 5001"
timeout /t 3 /nobreak >nul
echo [OK] Ngrok iniciado

echo.
echo =========================================
echo   Tudo rodando!
echo.
echo   Health:     https://authentic-unworried-ounce.ngrok-free.dev/api/health
echo   Atendentes: https://authentic-unworried-ounce.ngrok-free.dev/api/atendentes
echo =========================================
echo.
pause
