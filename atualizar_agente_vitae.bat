@echo off
title Atualizar Agente Vitae
color 0B
cd /d "%~dp0"

echo =========================================
echo   Atualizando agente_vitae.py
echo =========================================
echo.

curl -k -o agente_vitae.py "https://raw.githubusercontent.com/marketingpropharmacos/data-label-automaton/main/agente_vitae.py"

if errorlevel 1 (
    echo.
    echo [ERRO] Falha ao baixar. Verifique a conexao com a internet.
    pause
    exit /b 1
)

echo.
echo [OK] Arquivo atualizado! Reinicie o agente_vitae.
echo.
pause
