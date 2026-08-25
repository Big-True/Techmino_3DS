@echo off
chcp 65001 >nul 2>&1
setlocal

set LOVE_EXE=C:\Program Files\LOVE\love.exe
set GAME_DIR=build\sim-test
set TIMEOUT_SEC=15
set OUTPUT=build\test-output.txt

if not exist "%LOVE_EXE%" (
    echo ERROR: LOVE not found at %LOVE_EXE%
    exit /b 1
)

if not exist %GAME_DIR% (
    echo Building sim-test first...
    call build.bat sim
)

echo === Automated 3DS Simulation Test ===
echo Timeout: %TIMEOUT_SEC% seconds
echo Output:  %OUTPUT%
echo.

REM Run LOVE in background, capture output
start "" /B "%LOVE_EXE%" %GAME_DIR% > %OUTPUT% 2>&1
set LOVE_PID=

REM Wait for LOVE to start
timeout /t 2 /nobreak >nul

REM Find the LOVE process PID
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq love.exe" /fo list ^| findstr PID') do set LOVE_PID=%%i

if "%LOVE_PID%"=="" (
    echo LOVE did not start. Check %OUTPUT% for errors.
    type %OUTPUT%
    exit /b 1
)

echo LOVE running (PID: %LOVE_PID%). Waiting %TIMEOUT_SEC%s...
timeout /t %TIMEOUT_SEC% /nobreak >nul

REM Kill LOVE
taskkill /PID %LOVE_PID% /F >nul 2>&1

echo.
echo === Test Output ===
type %OUTPUT%
echo.
echo === Test Complete ===
