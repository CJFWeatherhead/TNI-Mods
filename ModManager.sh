#!/usr/bin/env bash
# Linux companion launcher for TNI Mod Manager — NOT a WPF replacement.
# Точка входа Linux companion; не замена Windows ModManager.bat / WPF.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")" && pwd)"
cd "$SCRIPT_DIR"
export PYTHONPATH="$SCRIPT_DIR/linux-mod-manager"
exec python3 -m tni_mod_manager "$@"
