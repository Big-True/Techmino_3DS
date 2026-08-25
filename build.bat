@echo off
REM build.bat — Build Techmino 3DS .love package
REM Usage: build.bat

echo === Techmino 3DS Build ===

REM Step 1: Clean
echo [1/4] Cleaning build directory...
if exist build\game rmdir /S /Q build\game
mkdir build\game 2>nul

REM Step 2: Copy upstream Techmino files
echo [2/4] Copying upstream Techmino files...
copy /Y Techmino\version.lua build\game\ >nul
copy /Y Techmino\legals.md build\game\ >nul
copy /Y Techmino\license.txt build\game\ >nul
copy /Y Techmino\updateLog.txt build\game\ >nul

xcopy /E /I /Y Techmino\media build\game\media >nul 2>&1
xcopy /E /I /Y Techmino\parts build\game\parts >nul 2>&1
xcopy /E /I /Y Techmino\Zframework build\game\Zframework >nul 2>&1

REM Step 3: Overlay port/ modifications
echo [3/4] Applying 3DS port modifications...

REM Core files
copy /Y port\conf.lua build\game\conf.lua >nul
copy /Y port\main.lua build\game\main.lua >nul
copy /Y port\compat.lua build\game\compat.lua >nul

REM Stub Discord RPC
copy /Y port\parts\discordRPC.lua build\game\parts\discordRPC.lua >nul

REM Shader stubs: remove original .glsl files (not supported on 3DS)
del /Q build\game\parts\shaders\*.glsl 2>nul

REM Copy any port/parts/scenes/ overrides
if exist port\parts\scenes (
    for %%f in (port\parts\scenes\*.lua) do (
        copy /Y "%%f" build\game\parts\scenes\ >nul
    )
)

REM Copy any port/Zframework/ overrides
if exist port\Zframework (
    for %%f in (port\Zframework\*.lua) do (
        if not "%%~nxf"=="init_3ds_patch.lua" (
            copy /Y "%%f" build\game\Zframework\ >nul
        )
    )
)

REM Copy any port/parts/ overrides (top-level)
if exist port\parts\*.lua (
    for %%f in (port\parts\*.lua) do (
        copy /Y "%%f" build\game\parts\ >nul
    )
)

REM Step 4: Create .love package
echo [4/4] Creating .love package...
if exist build\Techmino_3DS.love del /Q build\Techmino_3DS.love
powershell -Command "Compress-Archive -Path 'build\game\*' -DestinationPath 'build\Techmino_3DS.zip' -Force"
move /Y build\Techmino_3DS.zip build\Techmino_3DS.love >nul 2>&1

echo.
echo === Build complete ===
echo Output: build\Techmino_3DS.love
echo.
echo To create a 3DS .3dsx:
echo   1. Build lovepotion.3dsx: cd lovepotion ^&^& catnip -T 3DS
echo   2. Combine: copy /B lovepotion.3dsx + build\Techmino_3DS.love build\Techmino_3DS.3dsx
