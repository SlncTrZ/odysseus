@echo off
setlocal enabledelayedexpansion
title Odysseus - Native Windows Launcher
pushd "%~dp0" >nul

echo =========================================
echo     Odysseus - Native Windows Launcher
echo =========================================
echo.

set PORT=7000
set BIND_HOST=127.0.0.1
if not "%1"=="" set PORT=%1
if not "%2"=="" set BIND_HOST=%2

:: 1. Check Python 3.11+
set PY_EXE=
set PY_VER=

where py >nul 2>nul
if not errorlevel 1 (
    for %%v in (3.13 3.12 3.11) do (
        py -%%v -c "exit()" >nul 2>nul
        if not errorlevel 1 (
            set PY_EXE=py
            set PY_VER=-%%v
            goto :found_py
        )
    )
)

:found_py
if "%PY_EXE%"=="" (
    where python >nul 2>nul
    if errorlevel 1 (
        echo [FAIL] Python not found. Install 3.11+ from https://www.python.org/downloads/
        goto :fail
    )
    python --version 2>&1 | findstr /R "3\.1[1-9] 3\.[2-9][0-9]" >nul
    if errorlevel 1 (
        echo [FAIL] Python ^< 3.11 detected. Install Python 3.11+.
        goto :fail
    )
    set PY_EXE=python
    set PY_VER=
)

echo [OK] Using:
%PY_EXE% %PY_VER% --version

:: 2. Create venv
if not exist "venv\Scripts\python.exe" (
    echo.
    echo [+] Creating virtual environment...
    %PY_EXE% %PY_VER% -m venv venv
    if errorlevel 1 (
        echo [FAIL] Failed to create venv.
        goto :fail
    )
) else (
    echo [OK] venv already exists.
)

:: 3. Install dependencies
echo.
echo [+] Installing dependencies (may take a while on first run)...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo [FAIL] Failed to activate venv.
    goto :fail
)

python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo [FAIL] pip install failed.
    goto :fail
)

:: 4. First-time setup
echo.
echo [+] Running first-time setup...
python setup.py
if errorlevel 1 (
    echo [FAIL] setup.py failed.
    goto :fail
)

:: 5. Start server
echo.
echo =========================================
echo     Starting at http://%BIND_HOST%:%PORT%
echo     Press Ctrl+C to stop.
echo =========================================
echo.

start http://%BIND_HOST%:%PORT%
python -m uvicorn app:app --host %BIND_HOST% --port %PORT%

goto :done

:fail
echo.
echo [FAIL] Launch failed. Check messages above.
pause
goto :done

:done
popd >nul
pause
