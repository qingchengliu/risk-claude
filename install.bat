@echo off
setlocal enabledelayedexpansion

rem risk-claude installer for Windows
rem Usage: install.bat [--install-dir "path"] [--force]

set "REPO=qingchengliu/risk-claude"
set "INSTALL_DIR=%USERPROFILE%\.claude"
set "FORCE=0"
set "EXIT_CODE=0"

rem Parse arguments
:parse_args
if "%~1"=="" goto :start_install
if /I "%~1"=="--install-dir" (
    set "INSTALL_DIR=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--force" (
    set "FORCE=1"
    shift
    goto :parse_args
)
echo Unknown option: %~1
set "EXIT_CODE=1"
goto :end

:start_install
echo Installing risk-claude workflow to %INSTALL_DIR%...
echo.

rem Get script directory
set "SCRIPT_DIR=%~dp0"
rem Remove trailing backslash
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

rem Create install directory
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" >nul 2>nul
    if errorlevel 1 (
        echo ERROR: Failed to create install directory: %INSTALL_DIR%
        set "EXIT_CODE=1"
        goto :end
    )
)

rem Install commands
if exist "%SCRIPT_DIR%\commands" (
    echo Installing commands...
    if not exist "%INSTALL_DIR%\commands" mkdir "%INSTALL_DIR%\commands" >nul 2>nul
    if "!FORCE!"=="1" (
        xcopy /E /Y /Q "%SCRIPT_DIR%\commands\*" "%INSTALL_DIR%\commands\" >nul 2>nul
    ) else (
        xcopy /E /D /Q "%SCRIPT_DIR%\commands\*" "%INSTALL_DIR%\commands\" >nul 2>nul
    )
    if errorlevel 1 (
        echo WARNING: Some files in commands may not have been copied.
    )
)

rem Install agents
if exist "%SCRIPT_DIR%\agents" (
    echo Installing agents...
    if not exist "%INSTALL_DIR%\agents" mkdir "%INSTALL_DIR%\agents" >nul 2>nul
    if "!FORCE!"=="1" (
        xcopy /E /Y /Q "%SCRIPT_DIR%\agents\*" "%INSTALL_DIR%\agents\" >nul 2>nul
    ) else (
        xcopy /E /D /Q "%SCRIPT_DIR%\agents\*" "%INSTALL_DIR%\agents\" >nul 2>nul
    )
    if errorlevel 1 (
        echo WARNING: Some files in agents may not have been copied.
    )
)

rem Install skills
if exist "%SCRIPT_DIR%\skills" (
    echo Installing skills...
    if not exist "%INSTALL_DIR%\skills" mkdir "%INSTALL_DIR%\skills" >nul 2>nul
    if "!FORCE!"=="1" (
        xcopy /E /Y /Q "%SCRIPT_DIR%\skills\*" "%INSTALL_DIR%\skills\" >nul 2>nul
    ) else (
        xcopy /E /D /Q "%SCRIPT_DIR%\skills\*" "%INSTALL_DIR%\skills\" >nul 2>nul
    )
    if errorlevel 1 (
        echo WARNING: Some files in skills may not have been copied.
    )
)

rem Download codeagent-wrapper from GitHub releases
echo.
echo Downloading codeagent-wrapper...

call :detect_arch
if errorlevel 1 goto :skip_download

set "VERSION=latest"
set "BINARY_NAME=codeagent-wrapper-windows-%ARCH%.exe"
set "URL=https://github.com/%REPO%/releases/%VERSION%/download/%BINARY_NAME%"
set "TEMP_FILE=%TEMP%\codeagent-wrapper-%RANDOM%.exe"
set "DEST_DIR=%USERPROFILE%\bin"
set "DEST=%DEST_DIR%\codeagent-wrapper.exe"

echo Downloading from %URL%...
call :download
if errorlevel 1 goto :skip_download

if not exist "%TEMP_FILE%" (
    echo WARNING: Download failed, skipping codeagent-wrapper installation...
    goto :skip_download
)

echo Installing to "%DEST%"...
if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%" >nul 2>nul || goto :skip_download
)

move /y "%TEMP_FILE%" "%DEST%" >nul 2>nul
if errorlevel 1 (
    echo WARNING: Unable to install codeagent-wrapper.
    goto :skip_download
)

"%DEST%" --version >nul 2>nul
if errorlevel 1 (
    echo WARNING: codeagent-wrapper installation verification failed.
) else (
    echo codeagent-wrapper installed successfully to %DEST%
)

rem Check if %USERPROFILE%\bin is in PATH and add if not
set "USER_PATH_RAW="
set "USER_PATH_TYPE="
for /f "tokens=1,2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul ^| findstr /I /R "^ *Path  *REG_"') do (
    set "USER_PATH_TYPE=%%B"
    set "USER_PATH_RAW=%%C"
)
rem Trim leading spaces
for /f "tokens=* delims= " %%D in ("!USER_PATH_RAW!") do set "USER_PATH_RAW=%%D"

rem Normalize DEST_DIR
if "!DEST_DIR:~-1!"=="\" set "DEST_DIR=!DEST_DIR:~0,-1!"

rem Build search patterns
set "PCT=%%"
set "SEARCH_EXP=;!DEST_DIR!;"
set "SEARCH_EXP2=;!DEST_DIR!\;"
set "SEARCH_LIT=;!PCT!USERPROFILE!PCT!\bin;"
set "SEARCH_LIT2=;!PCT!USERPROFILE!PCT!\bin\;"

rem Check user PATH
set "CHECK_RAW=;!USER_PATH_RAW!;"
set "USER_PATH_EXP=!USER_PATH_RAW!"
if defined USER_PATH_EXP call set "USER_PATH_EXP=%%USER_PATH_EXP%%"
set "CHECK_EXP=;!USER_PATH_EXP!;"

rem Check if already present
set "ALREADY_IN_PATH=0"
echo !CHECK_RAW! | findstr /I /C:"!SEARCH_LIT!" /C:"!SEARCH_LIT2!" >nul && set "ALREADY_IN_PATH=1"
if "!ALREADY_IN_PATH!"=="0" (
    echo !CHECK_EXP! | findstr /I /C:"!SEARCH_EXP!" /C:"!SEARCH_EXP2!" >nul && set "ALREADY_IN_PATH=1"
)

if "!ALREADY_IN_PATH!"=="1" (
    echo User PATH already includes %%USERPROFILE%%\bin.
) else (
    echo Adding %%USERPROFILE%%\bin to user PATH...
    if defined USER_PATH_RAW (
        set "USER_PATH_NEW=!USER_PATH_RAW!"
        if not "!USER_PATH_NEW:~-1!"==";" set "USER_PATH_NEW=!USER_PATH_NEW!;"
        set "USER_PATH_NEW=!USER_PATH_NEW!!PCT!USERPROFILE!PCT!\bin"
    ) else (
        set "USER_PATH_NEW=!PCT!USERPROFILE!PCT!\bin"
    )
    setx PATH "!USER_PATH_NEW!" >nul
    if errorlevel 1 (
        echo WARNING: Failed to add %%USERPROFILE%%\bin to user PATH.
    ) else (
        echo Added %%USERPROFILE%%\bin to user PATH.
        echo Please restart your terminal for changes to take effect.
    )
)

rem Update current session PATH
set "CURPATH=;%PATH%;"
echo !CURPATH! | findstr /I /C:"!SEARCH_EXP!" /C:"!SEARCH_EXP2!" /C:"!SEARCH_LIT!" /C:"!SEARCH_LIT2!" >nul
if errorlevel 1 set "PATH=!DEST_DIR!;!PATH!"

:skip_download

echo.
echo Installation completed successfully!
echo Installed to: %INSTALL_DIR%
echo.
echo Components installed:
if exist "%INSTALL_DIR%\commands" echo   - commands\
if exist "%INSTALL_DIR%\agents" echo   - agents\
if exist "%INSTALL_DIR%\skills" echo   - skills\
if exist "%DEST%" echo   - %DEST%

rem Install global npm packages
echo.
echo Installing global npm packages...
call npm install -g @openai/codex
if errorlevel 1 echo WARNING: Failed to install @openai/codex
call npm install -g @anthropic-ai/claude-code
if errorlevel 1 echo WARNING: Failed to install @anthropic-ai/claude-code
echo Global npm packages installation completed.

goto :cleanup

:detect_arch
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "ARCH=%PROCESSOR_ARCHITEW6432%"

if /I "%ARCH%"=="AMD64" (
    set "ARCH=amd64"
    exit /b 0
) else if /I "%ARCH%"=="ARM64" (
    set "ARCH=arm64"
    exit /b 0
) else (
    echo WARNING: Unsupported architecture "%ARCH%", skipping codeagent-wrapper download.
    exit /b 1
)

:download
where curl >nul 2>nul
if %errorlevel%==0 (
    echo Using curl...
    curl -fL --retry 3 --connect-timeout 10 "%URL%" -o "%TEMP_FILE%"
    if errorlevel 1 (
        echo WARNING: curl download failed.
        exit /b 1
    )
    exit /b 0
)

where powershell >nul 2>nul
if %errorlevel%==0 (
    echo Using PowerShell...
    powershell -NoLogo -NoProfile -Command " $ErrorActionPreference='Stop'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 -bor 768 -bor 192 } catch {} ; $wc = New-Object System.Net.WebClient; $wc.DownloadFile('%URL%','%TEMP_FILE%') "
    if errorlevel 1 (
        echo WARNING: PowerShell download failed.
        exit /b 1
    )
    exit /b 0
)

echo WARNING: Neither curl nor PowerShell is available to download.
exit /b 1

:cleanup
if exist "%TEMP_FILE%" del /f /q "%TEMP_FILE%" >nul 2>nul

:end
set "CODE=%EXIT_CODE%"
endlocal & exit /b %CODE%
