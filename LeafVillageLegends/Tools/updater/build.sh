#!/usr/bin/env bash
# Cross-compiles the portable Windows updater from Linux/macOS.
# Requires Go 1.21+ (https://go.dev/dl/). No other dependencies for the
# build itself (github.com/lxn/walk is pure Go, no CGO needed).
set -euo pipefail
cd "$(dirname "$0")"

# Regenerate rsrc.syso (the embedded manifest requesting themed common
# controls + DPI awareness, plus the exe's file/taskbar icon) if the rsrc
# tool is available. If not, the already-committed rsrc.syso is used as-is -
# only re-run this if you changed updater.manifest or assets/icon.ico.
if command -v rsrc >/dev/null 2>&1; then
  rsrc -manifest updater.manifest -ico assets/icon.ico -o rsrc.syso
elif [ ! -f rsrc.syso ]; then
  echo "rsrc tool not found and no rsrc.syso present - install it with:"
  echo "  go install github.com/akavel/rsrc@latest"
  exit 1
fi

GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w -H=windowsgui" -o AshenBannerUpdater.exe .

echo "Built AshenBannerUpdater.exe"
