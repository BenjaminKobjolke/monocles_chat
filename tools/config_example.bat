:: upload_config.bat
@echo off
:: Public link base where APKs are served from
set "APK_LINK_DIR=https://yourserver.com/apps"

:: Remote FTP server details
set "FTP_HOST=yourserver"
set "FTP_USER=youruser"
set "FTP_PASS=yourpassword"

:: Local directory containing debug APKs (relative to this config/script)
set "LOCAL_DIR=%~dp0..\build\outputs\apk\monocleschatFree\debug"

:: Remote directory on FTP (root is /)
set "REMOTE_DIR=/"

:: Target filename on FTP
set "TARGET_APK_NAME=monocles-chat-debug.apk"
