#!/usr/bin/env bash
# Détection et qualification de la plateforme WSL2 du P5.

p5_platform_project_root() {
    if [[ -n "${P5_PROJECT_ROOT:-}" ]]; then printf '%s\n' "$P5_PROJECT_ROOT"; return; fi
    local source_dir
    source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    cd -- "$source_dir/../.." && pwd
}

p5_platform_osrelease_file() { printf '%s\n' "${P5_PROC_OSRELEASE_FILE:-/proc/sys/kernel/osrelease}"; }

p5_platform_is_wsl2() {
    local release_file release
    release_file="$(p5_platform_osrelease_file)"
    [[ -r "$release_file" ]] || return 1
    release="$(tr '[:upper:]' '[:lower:]' < "$release_file")"
    [[ "$release" == *microsoft* && "$release" == *wsl2* ]]
}

p5_platform_pid1() {
    if [[ -n "${P5_TEST_PID1:-}" ]]; then printf '%s\n' "$P5_TEST_PID1"; return; fi
    ps -p 1 -o comm= 2>/dev/null | xargs
}

p5_platform_fs_type() {
    local path="$1"
    if [[ -n "${P5_TEST_FS_TYPE:-}" ]]; then printf '%s\n' "$P5_TEST_FS_TYPE"; return; fi
    findmnt -T "$path" -n -o FSTYPE 2>/dev/null || true
}

p5_platform_checkout_root_allowed() {
    local project_root="$1" home_root="${P5_TEST_HOME:-$HOME}" item allowed_root
    project_root="$(realpath -m "$project_root")"
    home_root="$(realpath -m "$home_root")"
    for item in ${P5_ALLOWED_WORK_ROOTS:-projects labs repositories}; do
        allowed_root="$home_root/$item"
        [[ "$project_root" == "$allowed_root" || "$project_root" == "$allowed_root/"* ]] && return 0
    done
    return 1
}

p5_platform_checkout_on_windows_mount() {
    local project_root="$1" prefix
    project_root="$(realpath -m "$project_root")"
    for prefix in ${P5_FORBIDDEN_MOUNT_PREFIXES:-/mnt/c /mnt/d}; do
        [[ "$project_root" == "$prefix" || "$project_root" == "$prefix/"* ]] && return 0
    done
    return 1
}

p5_platform_validate() {
    local project_root="${1:-$(p5_platform_project_root)}" failures=0 fs_type distro pid1
    p5_platform_is_wsl2 || { printf 'KO  WSL2 microsoft-standard-WSL2 est requis.\n' >&2; failures=$((failures + 1)); }
    distro="${P5_TEST_WSL_DISTRO_NAME:-${WSL_DISTRO_NAME:-}}"
    if [[ -n "${P5_EXPECTED_WSL_DISTRO:-}" && "$distro" != "$P5_EXPECTED_WSL_DISTRO" ]]; then
        printf 'KO  Distribution WSL attendue=%s, détectée=%s.\n' "$P5_EXPECTED_WSL_DISTRO" "${distro:-inconnue}" >&2
        failures=$((failures + 1))
    fi
    pid1="$(p5_platform_pid1)"
    if [[ "${P5_REQUIRE_SYSTEMD:-true}" == true && "$pid1" != systemd ]]; then
        printf 'KO  systemd doit être PID 1 ; détecté=%s.\n' "${pid1:-inconnu}" >&2
        failures=$((failures + 1))
    fi
    if p5_platform_checkout_on_windows_mount "$project_root"; then
        printf 'KO  Checkout interdit sur un montage Windows : %s.\n' "$project_root" >&2
        failures=$((failures + 1))
    fi
    if ! p5_platform_checkout_root_allowed "$project_root"; then
        printf 'KO  Checkout hors des racines Linux autorisées : %s.\n' "$project_root" >&2
        failures=$((failures + 1))
    fi
    fs_type="$(p5_platform_fs_type "$project_root")"
    case "$fs_type" in ext4|xfs|btrfs) ;; *)
        printf 'KO  Filesystem Linux local attendu ; détecté=%s pour %s.\n' "${fs_type:-inconnu}" "$project_root" >&2
        failures=$((failures + 1)) ;;
    esac
    ((failures == 0))
}

p5_platform_print_summary() {
    local project_root="${1:-$(p5_platform_project_root)}"
    printf 'Plateforme        : %s\n' "${P5_EXECUTION_MODEL:-windows11-wsl2-ubuntu-26.04}"
    printf 'Distribution WSL : %s\n' "${WSL_DISTRO_NAME:-inconnue}"
    printf 'Noyau             : %s\n' "$(uname -r 2>/dev/null || printf inconnu)"
    printf 'PID 1             : %s\n' "$(p5_platform_pid1)"
    printf 'Checkout          : %s\n' "$project_root"
    printf 'Filesystem        : %s\n' "$(p5_platform_fs_type "$project_root")"
}
