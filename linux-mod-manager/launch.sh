#!/usr/bin/env bash
# Thin wrapper — main entry point is ../ModManager.sh
# Обёртка; основная точка входа — ../ModManager.sh
set -euo pipefail
exec "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")/../ModManager.sh" "$@"
