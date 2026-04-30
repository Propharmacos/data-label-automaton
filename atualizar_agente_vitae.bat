@echo off
title Atualizar Agente Vitae
color 0B
cd /d "%~dp0"

echo =========================================
echo   Atualizando agente_vitae.py
echo   Repositorio: data-label-automaton
echo =========================================
echo.

:: Baixa o arquivo mais recente do GitHub via PowerShell
echo [INFO] Baixando agente_vitae.py do GitHub...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^
   try { ^
     Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/marketingpropharmacos/data-label-automaton/main/agente_vitae.py' ^
       -OutFile '%~dp0agente_vitae.py' -UseBasicParsing; ^
     Write-Host '[OK] Arquivo atualizado com sucesso!' -ForegroundColor Green ^
   } catch { ^
     Write-Host '[ERRO] Falha ao baixar:' $_.Exception.Message -ForegroundColor Red; ^
     exit 1 ^
   }"

if errorlevel 1 (
    echo.
    echo [ERRO] Nao foi possivel atualizar. Verifique a conexao com a internet.
    pause
    exit /b 1
)

echo.
echo [INFO] Arquivo atualizado! Reinicie o agente_vitae manualmente se estiver rodando.
echo.
pause
