@echo off
REM run-sim.bat — Launch the 3DS simulation test
REM Usage: run-sim.bat
REM Requires: LÖVE 11.5 installed at C:\Program Files\LOVE\love.exe

set LOVE_EXE=C:\Program Files\LOVE\love.exe

if not exist "%LOVE_EXE%" (
    echo ERROR: LÖVE not found at %LOVE_EXE%
    echo Install LÖVE 11.5 from https://love2d.org
    exit /b 1
)

if not exist build\sim-test (
    echo Building simulation test first...
    call build.bat sim
)

echo Launching 3DS simulation test...
echo Controls:
echo   Arrow keys = D-Pad
echo   Z/X/A/S    = A/B/X/Y
echo   Q/W        = L/R shoulders
echo   Enter      = Start
echo   Backspace  = Select
echo   Mouse click on bottom screen = Touch
echo   Scroll wheel = 3D depth slider
echo.
start "" "%LOVE_EXE%" build\sim-test
