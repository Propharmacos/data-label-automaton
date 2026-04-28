@echo off
title ngrok - Agente Vitae (porta 5001)
color 0B
echo =========================================
echo   ngrok tunel para Agente Vitae
echo   Dominio: authentic-unworried-ounce.ngrok-free.dev
echo   Porta local: 5001
echo =========================================
echo.
echo [INFO] Iniciando tunel ngrok...
echo [INFO] Pressione Ctrl+C para encerrar.
echo.
"C:\Users\Administrador.PROCARAIBAS\Desktop\ngrok.exe" http --config="C:\Users\Administrador.PROCARAIBAS\ngrok-vitae.yml" --domain=authentic-unworried-ounce.ngrok-free.dev 5001
pause
