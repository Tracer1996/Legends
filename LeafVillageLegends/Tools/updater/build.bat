@echo off
REM Builds the portable Windows updater on Windows.
REM Requires Go 1.21+ (https://go.dev/dl/). No other dependencies for the
REM build itself (github.com/lxn/walk is pure Go, no CGO needed).
cd /d "%~dp0"

where rsrc >nul 2>nul
if %errorlevel%==0 (
    rsrc -manifest updater.manifest -ico assets\icon.ico -o rsrc.syso
) else (
    if not exist rsrc.syso (
        echo rsrc tool not found and no rsrc.syso present - install it with:
        echo   go install github.com/akavel/rsrc@latest
        exit /b 1
    )
)

go build -ldflags="-s -w -H=windowsgui" -o AshenBannerUpdater.exe .
echo Built AshenBannerUpdater.exe
