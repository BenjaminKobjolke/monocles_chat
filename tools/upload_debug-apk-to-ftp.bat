@echo off
setlocal

:: Path to shared config
set "CONFIG=%~dp0config.bat"

:: Ensure config exists
if not exist "%CONFIG%" (
    echo ERROR: Config file "%CONFIG%" not found.
    pause
    exit /b
)

:: Load config
call "%CONFIG%"

:: Ensure rclone exists
set "RCLONE=%~dp0rclone.exe"
if not exist "%RCLONE%" (
    echo ERROR: rclone.exe not found at "%RCLONE%".
    echo Download from https://rclone.org/downloads/ and place it in the tools folder.
    pause
    exit /b
)

cd /d "%~dp0"

:: Require at least one .apk file in LOCAL_DIR
if not exist "%LOCAL_DIR%\*.apk" (
    echo(
    echo No .apk file found in "%LOCAL_DIR%"
    echo(
    pause
    exit /b
)

:: Use the first .apk file found
for /f "delims=" %%i in ('dir /b "%LOCAL_DIR%\*.apk"') do (
    set "APK_FILENAME=%%i"
    goto found_apk
)
:found_apk

:: Setup Rclone FTP remote
"%RCLONE%" config create ftp-remote ftp host "%FTP_HOST%" user "%FTP_USER%" pass "%FTP_PASS%" >nul 2>&1

:: Upload and rename to fixed target name
"%RCLONE%" copyto "%LOCAL_DIR%\%APK_FILENAME%" "ftp-remote:%REMOTE_DIR%%TARGET_APK_NAME%" --progress

:: Get last modified date of the apk file
for %%i in ("%LOCAL_DIR%\%APK_FILENAME%") do set "APK_DATE=%%~ti"

echo(
echo Last modified: %APK_DATE%
echo Uploaded to: %APK_LINK_DIR%/%TARGET_APK_NAME%
echo(

endlocal
