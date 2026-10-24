@echo off
title RTL-SecCheck service - KEEP THIS WINDOW OPEN
cd /d "%~dp0backend"

rem Prefer the project venv (created per README quick start); fall back to system python
set "PY=%~dp0backend\.venv\Scripts\python.exe"
if not exist "%PY%" set "PY=python"
set "LOG=%~dp0backend\service.log"

rem If port 8321 is already listening, the service is up - do not start twice
netstat -ano | findstr :8321 | findstr LISTENING >nul
if %errorlevel%==0 (
    echo [INFO] Service is ALREADY RUNNING on port 8321. Nothing to start.
    echo [INFO] You can use the tool right away, or close this window.
    pause
    exit /b 0
)

echo [INFO] Starting RTL-SecCheck backend API at http://127.0.0.1:8321
echo [INFO] KEEP THIS WINDOW OPEN - closing it stops the service.
echo [INFO] Full log file: %LOG%
echo %date% %time%  [START] launching service >> "%LOG%"

rem Run uvicorn with output shown in this window AND appended to the log file
rem (stderr is merged at the cmd layer so PowerShell does not wrap log lines in red NativeCommandError)
powershell -NoProfile -Command "cmd /c '%PY% -u -m uvicorn main:app --host 127.0.0.1 --port 8321 2>&1' | Tee-Object -FilePath '%LOG%' -Append"

echo.
echo %date% %time%  [STOP] service exited >> "%LOG%"
echo [INFO] Service stopped. Details in log: %LOG%
pause
