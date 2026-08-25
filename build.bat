@echo off
REM build.bat — Build Techmino 3DS packages
REM Usage: build.bat [sim|love|3dsx|all]
REM   sim   — Build simulation test (runs on desktop LÖVE with nest)
REM   love  — Build .love package (for 3DS hardware)
REM   3dsx  — Build .3dsx package (requires devkitPro)
REM   all   — Build everything (default)

setlocal enabledelayedexpansion

if "%1"=="" set TARGET=all
if "%1"=="sim" set TARGET=sim
if "%1"=="love" set TARGET=love
if "%1"=="3dsx" set TARGET=3dsx
if "%1"=="all" set TARGET=all

echo === Techmino 3DS Build [%TARGET%] ===

REM === Shared: Build merged game directory ===
echo.
echo [MERGE] Building merged game directory...
if exist build\game rmdir /S /Q build\game
mkdir build\game 2>nul

echo   Copying upstream Techmino files...
copy /Y Techmino\version.lua build\game\ >nul
copy /Y Techmino\legals.md build\game\ >nul
copy /Y Techmino\license.txt build\game\ >nul
copy /Y Techmino\updateLog.txt build\game\ >nul
xcopy /E /I /Y Techmino\media build\game\media >nul 2>&1
xcopy /E /I /Y Techmino\parts build\game\parts >nul 2>&1
xcopy /E /I /Y Techmino\Zframework build\game\Zframework >nul 2>&1

echo   Applying 3DS port modifications...
copy /Y port\conf.lua build\game\conf.lua >nul
copy /Y port\main.lua build\game\main.lua >nul
copy /Y port\compat.lua build\game\compat.lua >nul
copy /Y port\parts\discordRPC.lua build\game\parts\discordRPC.lua >nul
del /Q build\game\parts\shaders\*.glsl 2>nul

if exist port\parts\scenes (
    for %%f in (port\parts\scenes\*.lua) do copy /Y "%%f" build\game\parts\scenes\ >nul
)
if exist port\Zframework (
    for %%f in (port\Zframework\*.lua) do (
        if not "%%~nxf"=="init_3ds_patch.lua" copy /Y "%%f" build\game\Zframework\ >nul
    )
)
if exist port\parts\*.lua (
    for %%f in (port\parts\*.lua) do copy /Y "%%f" build\game\parts\ >nul
)
echo   Merge complete.

REM === SIM: Build simulation test ===
if "%TARGET%"=="sim" goto :build_sim
if "%TARGET%"=="all" goto :build_sim
goto :skip_sim

:build_sim
echo.
echo [SIM] Building simulation test...
if exist build\sim-test rmdir /S /Q build\sim-test
mkdir build\sim-test 2>nul

echo   Copying merged game files...
xcopy /E /I /Y build\game build\sim-test >nul 2>&1

echo   Copying nest library...
xcopy /E /I /Y nest\nest build\sim-test\nest >nul 2>&1

echo   Installing sim-test wrapper files...
copy /Y sim-test\conf.lua build\sim-test\conf.lua >nul
copy /Y sim-test\main.lua build\sim-test\main.lua >nul

echo   SIM build complete: build\sim-test\
echo   Run with: "C:\Program Files\LOVE\love.exe" build\sim-test
:skip_sim

REM === LOVE: Build .love package ===
if "%TARGET%"=="love" goto :build_love
if "%TARGET%"=="all" goto :build_love
goto :skip_love

:build_love
echo.
echo [LOVE] Creating .love package...
if exist build\Techmino_3DS.love del /Q build\Techmino_3DS.love
powershell -Command "Compress-Archive -Path 'build\game\*' -DestinationPath 'build\Techmino_3DS.zip' -Force"
move /Y build\Techmino_3DS.zip build\Techmino_3DS.love >nul 2>&1
echo   LOVE build complete: build\Techmino_3DS.love
:skip_love

REM === 3DSX: Build .3dsx package ===
if "%TARGET%"=="3dsx" goto :build_3dsx
if "%TARGET%"=="all" goto :build_3dsx
goto :skip_3dsx

:build_3dsx
echo.
echo [3DSX] Building .3dsx package...

REM Create .love if not already built
if not exist build\Techmino_3DS.love (
    powershell -Command "Compress-Archive -Path 'build\game\*' -DestinationPath 'build\Techmino_3DS.zip' -Force"
    move /Y build\Techmino_3DS.zip build\Techmino_3DS.love >nul 2>&1
)

REM Try local build first, then pre-built release
set LOVEPOTION_3DSX=
if exist lovepotion\build\lovepotion.3dsx set LOVEPOTION_3DSX=lovepotion\build\lovepotion.3dsx
if "%LOVEPOTION_3DSX%"=="" if exist build\lovepotion-release\lovepotion.3dsx set LOVEPOTION_3DSX=build\lovepotion-release\lovepotion.3dsx

if "%LOVEPOTION_3DSX%"=="" (
    REM Try to build from source
    where catnip >nul 2>&1
    if errorlevel 1 (
        echo   No lovepotion.3dsx found and catnip not available.
        echo   Downloading pre-built release...
        curl -L -o build\lovepotion-3ds.zip "https://github.com/lovebrew/lovepotion/releases/download/3.0.2/Nintendo.3DS-8c7140b.zip"
        powershell -Command "Expand-Archive -Path 'build\lovepotion-3ds.zip' -DestinationPath 'build\lovepotion-release' -Force"
        set LOVEPOTION_3DSX=build\lovepotion-release\lovepotion.3dsx
    ) else (
        echo   Building LovePotion for 3DS from source...
        cd lovepotion
        catnip -T 3DS -DLIBRARY_LOADER='linktime' -DUSE_CURL_BACKEND=ON
        cd ..
        set LOVEPOTION_3DSX=lovepotion\build\lovepotion.3dsx
    )
)

if not exist %LOVEPOTION_3DSX% (
    echo   ERROR: lovepotion.3dsx not found.
    goto :skip_3dsx
)

echo   Combining %LOVEPOTION_3DSX% + game.love...
copy /B %LOVEPOTION_3DSX% + build\Techmino_3DS.love build\Techmino_3DS.3dsx >nul
echo   3DSX build complete: build\Techmino_3DS.3dsx
echo   Copy to SD card and launch with homebrew launcher!
:skip_3dsx

echo.
echo === Build finished ===
