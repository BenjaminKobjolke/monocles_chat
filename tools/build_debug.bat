@echo off
cd /d "%~dp0.."
call gradlew.bat assembleMonocleschatFreeDebug
echo.
echo APK output directory: %cd%\build\outputs\apk\monocleschatFree\debug\
