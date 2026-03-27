@echo off
cd /d "%~dp0"

call "%~dp0build_debug.bat"
if %errorlevel% neq 0 (
    echo BUILD FAILED
    pause
    exit /b %errorlevel%
)

call "%~dp0upload_debug-apk-to-ftp.bat"
call "%~dp0notification.bat"
