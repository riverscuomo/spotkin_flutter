@echo off
echo This script is for local development only. Not suitable for production use.
echo.

cd /d %~dp0

@REM echo Ensuring Flutter dependencies are up to date...
@REM flutter pub get

@REM if %errorlevel% neq 0 (
@REM     echo Error: Flutter pub get failed. Exiting.
@REM     pause
@REM     exit /b %errorlevel%
@REM )

echo.
echo Starting Chrome and VS Code...
start chrome http://localhost:8888
start code .

echo.
echo IMPORTANT: This is a basic setup for local testing only.
echo Do NOT use this for production deployments.
echo.

echo Your Flutter web app should now be running on http://localhost:8888
echo Use the VS Code debugger to start/stop the app and for hot reload functionality.
echo.

echo Press any key to exit this script. Your VS Code and Chrome windows will remain open.
pause >nul