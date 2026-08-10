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

p5_unknown() {
    local label="$1"
    local reason="$2"
    local action="${3:-}"
    printf '[INCONNU] %s\n' "$label" >&2
    printf '          Raison : %s\n' "$reason" >&2
    if [[ -n "$action" ]]; then
        p5_action "$action"
    fi
}

p5_authoritative_unknown() {
    local label="$1"
    local reason="$2"
    local action="$3"
    p5_header "INFORMATION NON VÉRIFIABLE — $label"
    p5_unknown "$label" "$reason" "$action"
    p5_warn 'Cette valeur provient de l’état réel (AWS/Terraform) et ne doit pas être inventée ou remplacée silencieusement.'
    return 1
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

p5_prepare_step_file() {
    local key="$1"
    local number slug

    P5_STEP_NUMBER="${P5_STEP_NUMBER:-0}"
    P5_STEP_NUMBER=$((P5_STEP_NUMBER + 1))
    export P5_STEP_NUMBER

    printf -v number '%02d' "$P5_STEP_NUMBER"
    slug="$(p5_slug "$key")"
    P5_CURRENT_STEP_NUMBER="$number"
    P5_CURRENT_STEP_LOG="$P5_LOG_DIR/${number}-${slug}.log"
    export P5_CURRENT_STEP_NUMBER P5_CURRENT_STEP_LOG
}

p5_run_step() {
    local key="$1"
    local label="$2"
    shift 2

    local log_file start_time end_time rc
    p5_prepare_step_file "$key"
    log_file="$P5_CURRENT_STEP_LOG"

    p5_header "$P5_CURRENT_STEP_NUMBER — $label"
    p5_command_preview "$@"
    printf '       Log      : %s\n\n' "$log_file"

    start_time="$(date +%s)"
    set +e
    "$@" > >(tee "$log_file") 2>&1
    rc=$?
    set -e
    end_time="$(date +%s)"

    P5_LAST_STEP_RC="$rc"
    P5_LAST_STEP_LOG="$log_file"
    export P5_LAST_STEP_RC P5_LAST_STEP_LOG

    if ((rc == 0)); then
        p5_ok "$label — $((end_time - start_time)) s"
    else
        p5_error "$label — code retour $rc — voir $log_file"
    fi
    return "$rc"
}

p5_run_step_allow() {
    local accepted_codes="$1"
    local key="$2"
    local label="$3"
    shift 3

    local log_file start_time end_time rc
    p5_prepare_step_file "$key"
    log_file="$P5_CURRENT_STEP_LOG"

    p5_header "$P5_CURRENT_STEP_NUMBER — $label"
    p5_command_preview "$@"
    printf '       Log      : %s\n\n' "$log_file"

    start_time="$(date +%s)"
    set +e
    "$@" > >(tee "$log_file") 2>&1
    rc=$?
    set -e
    end_time="$(date +%s)"

    P5_LAST_STEP_RC="$rc"
    P5_LAST_STEP_LOG="$log_file"
    export P5_LAST_STEP_RC P5_LAST_STEP_LOG

    if [[ " $accepted_codes " == *" $rc "* ]]; then
        if ((rc == 0)); then
            p5_ok "$label — $((end_time - start_time)) s"
        else
            p5_info "$label — état attendu code $rc — $((end_time - start_time)) s"
        fi
        return 0
    fi

    p5_error "$label — code retour $rc — voir $log_file"
    return "$rc"
}

p5_validate_nonempty() {
    [[ -n "$1" ]]
}

p5_validate_email() {
    [[ "$1" =~ ^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$ ]]
}

p5_validate_aws_region() {
    [[ "$1" =~ ^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$ ]]
}

p5_validate_ipv4() {
    local value="$1"
    python3 - "$value" <<'PY' >/dev/null 2>&1
import ipaddress
import sys
ipaddress.IPv4Address(sys.argv[1])
PY
}

p5_validate_ipv4_cidr32() {
    local value="$1"
    python3 - "$value" <<'PY' >/dev/null 2>&1
import ipaddress
import sys
network = ipaddress.ip_network(sys.argv[1], strict=False)
raise SystemExit(0 if network.version == 4 and network.prefixlen == 32 else 1)
PY
}

p5_validate_http_url() {
    [[ "$1" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?$ ]]
}

p5_validate_existing_file() {
    [[ -f "$1" ]]
}

p5_prompt_value() {
    local variable_name="$1"
    local label="$2"
    local why="$3"
    local expected_format="$4"
    local example="$5"
    local default_value="${6:-}"
    local validator="${7:-p5_validate_nonempty}"
    local how_to_supply="${8:-}"
    local value

    p5_header "INFORMATION REQUISE — $label"
    p5_info "$why"
    printf '       Format attendu : %s\n' "$expected_format"
    printf '       Exemple        : %s\n' "$example"
    if [[ -n "$how_to_supply" ]]; then
        printf '       Transmission   : %s\n' "$how_to_supply"
    fi

    if [[ ! -t 0 ]]; then
        p5_unknown "$label" 'la détection automatique n’a pas fourni de valeur et le terminal n’est pas interactif' \
            "Relancez dans un terminal interactif. ${how_to_supply:-}"
        return 1
    fi

    while true; do
        if [[ -n "$default_value" ]]; then
            printf '%s [%s] : ' "$label" "$default_value"
        else
            printf '%s : ' "$label"
        fi
        read -r value
        value="${value:-$default_value}"
        if "$validator" "$value"; then
            printf -v "$variable_name" '%s' "$value"
            p5_ok "$label renseigné et format validé."
            return 0
        fi
        p5_warn "Valeur refusée : '$value'. Format attendu : $expected_format."
    done
}

p5_terraform_output() {
    local variable_name="$1"
    local module_dir="$2"
    local output_name="$3"
    local label="$4"
    local validator="${5:-p5_validate_nonempty}"
    local recovery="${6:-Relancez la convergence Terraform du module concerné.}"
    local value

    value="$(terraform -chdir="$module_dir" output -raw "$output_name" 2>/dev/null || true)"
    if [[ -z "$value" ]] || ! "$validator" "$value"; then
        p5_authoritative_unknown "$label" \
            "la sortie Terraform '$output_name' est absente, illisible ou invalide dans $module_dir" \
            "$recovery"
        return 1
    fi
    printf -v "$variable_name" '%s' "$value"
    p5_info "$label obtenu depuis Terraform : $value"
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
    p5_prompt_value "$variable_name" "$message" \
        'Cette information n’a pas pu être déterminée automatiquement.' \
        'texte non vide' 'valeur-attendue' "$default_value" p5_validate_nonempty \
        'Saisissez la valeur demandée directement dans ce terminal.'
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
