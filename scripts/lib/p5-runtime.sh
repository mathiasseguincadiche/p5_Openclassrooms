#!/usr/bin/env bash
# Fonctions communes pour l'orchestration terminal du projet P5.

p5_runtime_project_root() {
    if [[ -n "${P5_PROJECT_ROOT:-}" ]]; then
        printf '%s\n' "$P5_PROJECT_ROOT"
        return
    fi
    local source_dir
    source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    cd -- "$source_dir/../.." && pwd
}

p5_session_start() {
    local session_name="${1:-p5}"
    P5_PROJECT_ROOT="$(p5_runtime_project_root)"
    export P5_PROJECT_ROOT

    if [[ -z "${P5_RUN_ID:-}" ]]; then
        P5_RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
        export P5_RUN_ID
    fi

    P5_LOG_DIR="${P5_LOG_DIR:-$P5_PROJECT_ROOT/logs/$P5_RUN_ID}"
    export P5_LOG_DIR
    umask 077
    mkdir -p "$P5_LOG_DIR"

    if [[ "${P5_SESSION_ACTIVE:-0}" != 1 ]]; then
        P5_MASTER_LOG="$P5_LOG_DIR/${session_name}.log"
        export P5_MASTER_LOG P5_SESSION_ACTIVE=1
        exec > >(tee -a "$P5_MASTER_LOG") 2>&1
    fi
}

p5_rule() {
    printf '%s\n' '──────────────────────────────────────────────────────────────────────────────'
}

p5_header() {
    local title="$1"
    printf '\n'
    p5_rule
    printf 'P5  %s\n' "$title"
    p5_rule
}

p5_info() {
    printf '[INFO] %s\n' "$1"
}

p5_ok() {
    printf '[ OK ] %s\n' "$1"
}

p5_warn() {
    printf '[WARN] %s\n' "$1"
}

p5_error() {
    printf '[ KO ] %s\n' "$1" >&2
}

p5_action() {
    printf '[ACTION REQUISE] %s\n' "$1"
}

p5_command_preview() {
    printf '       Commande :'
    printf ' %q' "$@"
    printf '\n'
}

p5_slug() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' /:' '---' \
        | tr -cd 'a-z0-9._-'
}

p5_run_step() {
    local key="$1"
    local label="$2"
    shift 2

    P5_STEP_NUMBER="${P5_STEP_NUMBER:-0}"
    P5_STEP_NUMBER=$((P5_STEP_NUMBER + 1))
    export P5_STEP_NUMBER

    local number slug log_file start_time end_time rc
    printf -v number '%02d' "$P5_STEP_NUMBER"
    slug="$(p5_slug "$key")"
    log_file="$P5_LOG_DIR/${number}-${slug}.log"

    p5_header "$number — $label"
    p5_command_preview "$@"
    printf '       Log      : %s\n\n' "$log_file"

    start_time="$(date +%s)"
    set +e
    "$@" > >(tee "$log_file") 2>&1
    rc=$?
    set -e
    end_time="$(date +%s)"

    if ((rc == 0)); then
        p5_ok "$label — $((end_time - start_time)) s"
    else
        p5_error "$label — code retour $rc — voir $log_file"
    fi
    return "$rc"
}

p5_confirm() {
    local message="$1"
    if [[ "${P5_ASSUME_YES:-0}" == 1 ]]; then
        p5_info "$message → confirmation automatique (--yes)."
        return 0
    fi

    if [[ ! -t 0 ]]; then
        p5_error "Une confirmation interactive est requise : $message"
        return 1
    fi

    local answer
    printf '%s [o/N] : ' "$message"
    read -r answer
    case "${answer,,}" in
        o|oui|y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

p5_require_exact() {
    local message="$1"
    local expected="$2"

    if [[ ! -t 0 ]]; then
        p5_error "Saisie interactive requise : $expected"
        return 1
    fi

    local answer
    printf '%s\n' "$message"
    printf 'Tapez exactement %s : ' "$expected"
    read -r answer
    [[ "$answer" == "$expected" ]]
}

p5_prompt() {
    local variable_name="$1"
    local message="$2"
    local default_value="${3:-}"
    local value

    if [[ ! -t 0 ]]; then
        p5_error "Saisie interactive requise pour $variable_name."
        return 1
    fi

    if [[ -n "$default_value" ]]; then
        printf '%s [%s] : ' "$message" "$default_value"
    else
        printf '%s : ' "$message"
    fi
    read -r value
    value="${value:-$default_value}"
    printf -v "$variable_name" '%s' "$value"
}

p5_manual_checkpoint() {
    local title="$1"
    shift

    p5_header "ACTION MANUELLE — $title"
    local line
    for line in "$@"; do
        printf '  - %s\n' "$line"
    done

    if [[ "${P5_ASSUME_YES:-0}" == 1 ]]; then
        p5_warn "Le mode --yes ne valide pas une preuve manuelle à votre place."
    fi

    p5_require_exact "Confirmez uniquement lorsque cette action est réellement terminée." "OK"
}

p5_latest_log_hint() {
    printf '\nLogs de cette exécution : %s\n' "$P5_LOG_DIR"
    if [[ -n "${P5_MASTER_LOG:-}" ]]; then
        printf 'Journal principal       : %s\n' "$P5_MASTER_LOG"
    fi
}
