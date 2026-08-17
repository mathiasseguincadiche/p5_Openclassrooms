#!/usr/bin/env bash
# Compatibilité transitoire : le runtime canonique est désormais WSL2.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf '[DEPRECATED] bootstrap-ubuntu-server.sh délègue à bootstrap-wsl2.sh.\n' >&2
exec bash "$SCRIPT_DIR/bootstrap-wsl2.sh" "$@"
