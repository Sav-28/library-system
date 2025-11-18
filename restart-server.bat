@echo off
echo Stopping any existing Node processes on port 3000...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do taskkill /F /PID %%a 2>nul
timeout /t 2 /nobreak >nul
echo Starting server...
cd /d "%~dp0"
node server.js

