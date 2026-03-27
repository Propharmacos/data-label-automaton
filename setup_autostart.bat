@echo off
title ProPharmacos - Configuracao Inicial
color 0B

echo.
echo ============================================================
echo  ProPharmacos - Setup de Inicializacao Automatica
echo  Execute como Administrador
echo ============================================================
echo.

REM Verificar se esta rodando como Administrador
net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este arquivo como Administrador!
    echo Clique com botao direito - Executar como administrador
    pause
    exit /b 1
)

set PASTA=C:\servidor_rotulos
set SCRIPT="%PASTA%\start_agent.bat"

REM Verificar se o start_agent.bat existe
if not exist %SCRIPT% (
    echo [ERRO] Arquivo nao encontrado: %SCRIPT%
    echo Verifique se a pasta C:\servidor_rotulos existe e tem o start_agent.bat
    pause
    exit /b 1
)

echo [1/3] Removendo tarefa antiga (se existir)...
schtasks /delete /tn "ProPharmacos_Agente" /f >nul 2>&1
echo [OK] Tarefa antiga removida.

echo.
echo [2/3] Criando nova tarefa no Agendador do Windows...
schtasks /create /tn "ProPharmacos_Agente" /tr "cmd.exe /c start \"\" \"%PASTA%\start_agent.bat\"" /sc onlogon /delay 00:01 /rl HIGHEST /ru "%USERNAME%" /f
if errorlevel 1 (
    echo [ERRO] Falha ao criar tarefa. Verifique se esta como Administrador.
    pause
    exit /b 1
)
echo [OK] Tarefa criada: inicia 1 minuto apos o login automatico.

echo.
echo [3/3] Adicionando atalho na pasta Startup (backup)...
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

(
echo Set oWS = WScript.CreateObject^("WScript.Shell"^)
echo sLinkFile = "%STARTUP%\ProPharmacos_Agente.lnk"
echo Set oLink = oWS.CreateShortcut^(sLinkFile^)
echo oLink.TargetPath = "cmd.exe"
echo oLink.Arguments = "/c start """" ""%PASTA%\start_agent.bat"""
echo oLink.WorkingDirectory = "%PASTA%"
echo oLink.WindowStyle = 7
echo oLink.Description = "ProPharmacos Agente de Impressao"
echo oLink.Save
) > "%TEMP%\atalho.vbs"

cscript //nologo "%TEMP%\atalho.vbs"
del "%TEMP%\atalho.vbs" >nul 2>&1
echo [OK] Atalho criado em: %STARTUP%

echo.
echo ============================================================
echo  CONFIGURACAO CONCLUIDA!
echo.
echo  O agente vai iniciar automaticamente em dois modos:
echo    1. Agendador de Tarefas - 1 min apos o login
echo    2. Pasta Startup - backup imediato no login
echo.
echo  Para testar agora sem reiniciar:
echo    Execute manualmente: %PASTA%\start_agent.bat
echo ============================================================
echo.
pause
