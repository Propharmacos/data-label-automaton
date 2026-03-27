@echo off
title ProPharmacos - Setup Autostart (PC do Daniel)
color 0B

echo.
echo ============================================================
echo  ProPharmacos - Setup Autostart - PC DO DANIEL
echo  Execute como Administrador (botao direito, Executar como admin)
echo ============================================================
echo.

REM Verificar admin
net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este arquivo como Administrador!
    pause
    exit /b 1
)

set PASTA=C:\servidor_rotulos
set AGENTE_ID=daniel

REM Verificar se a pasta existe
if not exist "%PASTA%" (
    echo [ERRO] Pasta %PASTA% nao encontrada!
    echo Verifique se o agente esta instalado corretamente.
    pause
    exit /b 1
)

REM Criar arquivo de identificacao do agente
echo %AGENTE_ID%> "%PASTA%\agente_id.txt"
echo [OK] Agente identificado como: %AGENTE_ID%

REM Copiar start_agent.bat para a pasta do agente
if exist "%~dp0..\start_agent.bat" (
    copy /Y "%~dp0..\start_agent.bat" "%PASTA%\start_agent.bat" >nul
    echo [OK] start_agent.bat copiado para %PASTA%
)

REM Criar atalho na pasta Startup do usuario
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
echo [1/3] Criando atalho na pasta Startup...

del "%STARTUP%\ProPharmacos_Agente.bat" >nul 2>&1
del "%STARTUP%\ProPharmacos_Agente.lnk" >nul 2>&1

(
    echo @echo off
    echo cd /d "%PASTA%"
    echo start "" "%PASTA%\start_agent.bat"
) > "%STARTUP%\ProPharmacos_Agente.bat"

echo [OK] Atalho criado em: %STARTUP%\ProPharmacos_Agente.bat

REM Task Scheduler como backup
echo [2/3] Registrando no Agendador de Tarefas (backup)...
schtasks /delete /tn "ProPharmacos_Agente" /f >nul 2>&1
schtasks /create /tn "ProPharmacos_Agente" ^
    /tr "\"%PASTA%\start_agent.bat\"" ^
    /sc onlogon ^
    /delay 0000:30 ^
    /rl HIGHEST ^
    /f >nul 2>&1
if errorlevel 1 (
    echo [AVISO] Task Scheduler nao configurado, mas a pasta Startup deve funcionar.
) else (
    echo [OK] Task Scheduler configurado como backup.
)

REM Verificar ngrok
echo [3/3] Verificando ngrok...
set NGROK_FOUND=0
if exist "%PASTA%\ngrok.exe" (
    set NGROK_FOUND=1
    set NGROK_PATH=%PASTA%\ngrok.exe
)
if exist "C:\ngrok\ngrok.exe" (
    set NGROK_FOUND=1
    set NGROK_PATH=C:\ngrok\ngrok.exe
)

if %NGROK_FOUND%==0 (
    echo [AVISO] ngrok.exe nao encontrado!
    echo Baixe em https://ngrok.com/download e coloque em %PASTA%\
    echo Depois execute: ngrok config add-authtoken SEU_TOKEN
) else (
    echo [OK] ngrok encontrado em %NGROK_PATH%
    echo [INFO] Certifique-se que o authtoken esta configurado:
    echo        %NGROK_PATH% config add-authtoken SEU_TOKEN
)

echo.
echo ============================================================
echo  CONFIGURACAO CONCLUIDA - PC DO DANIEL
echo.
echo  Pasta:    %PASTA%
echo  Agente:   %AGENTE_ID%
echo  Startup:  %STARTUP%\ProPharmacos_Agente.bat
echo.
echo  No proximo login, o agente iniciara automaticamente.
echo  Para testar agora, execute: %PASTA%\start_agent.bat
echo ============================================================
echo.
pause
