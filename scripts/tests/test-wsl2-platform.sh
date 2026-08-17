#!/usr/bin/env bash
# Tests unitaires du contrat WSL2 sans exiger un runner Windows.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/home/labs/p5_Openclassrooms"
printf '%s\n' '6.6.87.2-microsoft-standard-WSL2' > "$TMP_DIR/osrelease"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/environment/versions.env"
# shellcheck source=../lib/p5-platform.sh
source "$PROJECT_ROOT/scripts/lib/p5-platform.sh"

export P5_PROC_OSRELEASE_FILE="$TMP_DIR/osrelease"
export P5_TEST_WSL_DISTRO_NAME=Ubuntu
export P5_TEST_PID1=systemd
export P5_TEST_FS_TYPE=ext4
export P5_TEST_HOME="$TMP_DIR/home"

ALLOWED="$TMP_DIR/home/labs/p5_Openclassrooms"
p5_platform_is_wsl2
p5_platform_validate "$ALLOWED"
printf 'OK  WSL2, systemd, Ubuntu et EXT4 acceptés.\n'

P5_TEST_WSL_DISTRO_NAME=Debian
! p5_platform_validate "$ALLOWED" >/dev/null 2>&1
P5_TEST_WSL_DISTRO_NAME=Ubuntu

P5_TEST_PID1=init
! p5_platform_validate "$ALLOWED" >/dev/null 2>&1
P5_TEST_PID1=systemd

P5_TEST_FS_TYPE=9p
! p5_platform_validate "$ALLOWED" >/dev/null 2>&1
P5_TEST_FS_TYPE=ext4

! p5_platform_validate "$TMP_DIR/home/Downloads/p5_Openclassrooms" >/dev/null 2>&1
p5_platform_checkout_on_windows_mount /mnt/c/Users/test/p5_Openclassrooms
p5_platform_checkout_on_windows_mount /mnt/d/labs/p5_Openclassrooms

printf 'Verdict : CONTRAT WSL2 P5 RESPECTÉ.\n'
