@echo off
chcp 65001 >nul 2>&1
setlocal
cd /d "%~dp0"

REM deploy-citra.bat - Deploy Techmino 3DS to 3DS emulators (Citra/Azahar)
REM Uses Game Folder method: sdmc:/3ds/lovepotion/game/

set DEPLOYED=0

REM === Azahar ===
set AZ_SD=%APPDATA%\Azahar\sdmc
if exist "%AZ_SD%" (
    echo [Azahar] Deploying to %AZ_SD%\3ds\lovepotion\...
    if not exist "%AZ_SD%\3ds\lovepotion" mkdir "%AZ_SD%\3ds\lovepotion"
    if not exist build\lovepotion-release\lovepotion.3dsx call :download_lovepotion
    copy /Y build\lovepotion-release\lovepotion.3dsx "%AZ_SD%\3ds\lovepotion\lovepotion.3dsx" >nul
    if exist "%AZ_SD%\3ds\lovepotion\game" rmdir /S /Q "%AZ_SD%\3ds\lovepotion\game"
    xcopy /E /I /Y build\game "%AZ_SD%\3ds\lovepotion\game" >nul
    echo [Azahar] Done.
    set DEPLOYED=1
)

REM === Citra ===
set CT_SD=%APPDATA%\Citra\sdmc
if exist "%CT_SD%" (
    echo [Citra] Deploying to %CT_SD%\3ds\lovepotion\...
    if not exist "%CT_SD%\3ds\lovepotion" mkdir "%CT_SD%\3ds\lovepotion"
    if not exist build\lovepotion-release\lovepotion.3dsx call :download_lovepotion
    copy /Y build\lovepotion-release\lovepotion.3dsx "%CT_SD%\3ds\lovepotion\lovepotion.3dsx" >nul
    if exist "%CT_SD%\3ds\lovepotion\game" rmdir /S /Q "%CT_SD%\3ds\lovepotion\game"
    xcopy /E /I /Y build\game "%CT_SD%\3ds\lovepotion\game" >nul
    echo [Citra] Done.
    set DEPLOYED=1
)

if %DEPLOYED%==0 (
    echo ERROR: No emulator SD card found.
    echo Run Citra or Azahar at least once to create the SD card directory.
    exit /b 1
)

echo.
echo === Deploy complete ===
echo.

REM Try to launch Azahar first, then Citra
if exist "C:\Program Files\Azahar\azahar.exe" (
    echo Launching Azahar...
    start "" "C:\Program Files\Azahar\azahar.exe" "%AZ_SD%\3ds\lovepotion\lovepotion.3dsx"
    exit /b 0
)
if exist "D:\Software\citra-windows-msvc-20240303-0ff3440\citra-qt.exe" (
    echo Launching Citra...
    start "" "D:\Software\citra-windows-msvc-20240303-0ff3440\citra-qt.exe" "%CT_SD%\3ds\lovepotion\lovepotion.3dsx"
    exit /b 0
)

echo No emulator auto-detected. Open manually:
echo   lovepotion.3dsx at sdmc:/3ds/lovepotion/
exit /b 0

:download_lovepotion
echo   Downloading LovePotion release...
curl -L -o build\lovepotion-3ds.zip "https://github.com/lovebrew/lovepotion/releases/download/3.0.2/Nintendo.3DS-8c7140b.zip"
powershell -Command "Expand-Archive -Path 'build\lovepotion-3ds.zip' -DestinationPath 'build\lovepotion-release' -Force"
exit /b 0
