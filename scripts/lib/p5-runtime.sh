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
    P5_STEP_PROOF_DIR="${P5_STEP_PROOF_DIR:-$P5_PROJECT_ROOT/proofs/runtime/steps/$P5_RUN_ID}"
    P5_STEP_PROOF_MANIFEST="$P5_STEP_PROOF_DIR/manifest.tsv"
    export P5_LOG_DIR P5_STEP_PROOF_DIR P5_STEP_PROOF_MANIFEST

    P5_STABLE_LOG_ROOT="${P5_STABLE_LOG_ROOT:-$P5_PROJECT_ROOT/logs/scripts}"
    P5_EVENT_LOG="${P5_EVENT_LOG:-$P5_LOG_DIR/events.log}"
    P5_SUMMARY_LOG="${P5_SUMMARY_LOG:-$P5_LOG_DIR/summary.log}"
    export P5_STABLE_LOG_ROOT P5_EVENT_LOG P5_SUMMARY_LOG

    umask 077
    mkdir -p "$P5_LOG_DIR" "$P5_STEP_PROOF_DIR" "$P5_STABLE_LOG_ROOT"
    touch "$P5_EVENT_LOG"
    chmod 600 "$P5_EVENT_LOG"
    if [[ ! -f "$P5_STEP_PROOF_MANIFEST" ]]; then
        printf 'utc\tstep\tkey\tstatus\trc\tduration_s\tsha256\tproof_log\tlabel\n' \
            > "$P5_STEP_PROOF_MANIFEST"
        chmod 600 "$P5_STEP_PROOF_MANIFEST"
    fi

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

p5_sensitive_name() {
    local name="${1,,}"
    [[ "$name" == *password* \
        || "$name" == *passwd* \
        || "$name" == *secret* \
        || "$name" == *token* \
        || "$name" == *credential* \
        || "$name" == *api-key* \
        || "$name" == *apikey* ]]
}

p5_redact_stream() {
    # GNU sed est explicitement non-bufferisé ici : les étapes interactives
    # (AWS login, confirmations, saisies opérateur) doivent rester visibles en
    # temps réel même lorsque leur sortie traverse le filtre de redaction.
    sed -u -E \
        -e 's/(AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN|OPENROUTER_API_KEY|GITHUB_TOKEN|GH_TOKEN)=([^[:space:]]+)/\1=<REDACTED>/g' \
        -e 's/(AKIA|ASIA)[0-9A-Z]{16}/<REDACTED>/g' \
        -e 's/(sk-or-[A-Za-z0-9_-]{12,}|github_pat_[A-Za-z0-9_]{12,}|glpat-[A-Za-z0-9_-]{12,})/<REDACTED>/g' \
        -e 's/([Bb]earer[[:space:]]+)[A-Za-z0-9._~+\/-]{12,}/\1<REDACTED>/g'
}

p5_command_preview() {
    local arg key redact_next=0
    printf '       Commande :'
    for arg in "$@"; do
        if ((redact_next)); then
            printf ' %q' '<REDACTED>'
            redact_next=0
            continue
        fi
        if [[ "$arg" == *=* ]]; then
            key="${arg%%=*}"
            if p5_sensitive_name "$key"; then
                arg="${key}=<REDACTED>"
            fi
        elif [[ "$arg" == --* ]] && p5_sensitive_name "$arg"; then
            redact_next=1
        fi
        printf ' %q' "$arg"
    done
    printf '\n'
}
p5_slug() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' /:' '---' \
        | tr -cd 'a-z0-9._-'
}

p5_stable_log_for_command() {
    local key="$1"
    shift
    local candidate rel safe_key
    for candidate in "$@"; do
        if [[ "$candidate" == "$P5_PROJECT_ROOT/"* && -f "$candidate" ]]; then
            rel="${candidate#"$P5_PROJECT_ROOT/"}"
        elif [[ "$candidate" == scripts/* && -f "$P5_PROJECT_ROOT/$candidate" ]]; then
            rel="$candidate"
        else
            continue
        fi
        case "$rel" in
            *.sh|*.py)
                rel="${rel#scripts/}"
                rel="${rel%.*}"
                mkdir -p "$P5_STABLE_LOG_ROOT/$(dirname -- "$rel")"
                printf '%s/%s.log\n' "$P5_STABLE_LOG_ROOT/$rel"
                return 0
                ;;
        esac
    done
    safe_key="$(p5_slug "$key")"
    mkdir -p "$P5_STABLE_LOG_ROOT/external"
    printf '%s/external/%s.log\n' "$P5_STABLE_LOG_ROOT" "$safe_key"
}

p5_refresh_summary() {
    local validated failed
    validated="$(awk -F '\t' '$2 == "VALIDE" {count++} END {print count+0}' "$P5_EVENT_LOG" 2>/dev/null || printf 0)"
    failed="$(awk -F '\t' '$2 == "ECHEC" {count++} END {print count+0}' "$P5_EVENT_LOG" 2>/dev/null || printf 0)"
    {
        printf 'run_id=%s\n' "$P5_RUN_ID"
        printf 'validated_steps=%s\n' "$validated"
        printf 'failed_steps=%s\n' "$failed"
        printf 'result=%s\n' "$(if ((failed == 0)); then printf OK; else printf KO; fi)"
        printf 'updated_at=%s\n' "$(date -u --iso-8601=seconds)"
    } > "$P5_SUMMARY_LOG"
    chmod 600 "$P5_SUMMARY_LOG"
}

p5_finalize_step_observability() {
    local key="$1" status="$2" rc="$3" duration="$4" step_log="$5" stable_log="$6"
    local utc
    utc="$(date -u --iso-8601=seconds)"
    mkdir -p "$(dirname -- "$stable_log")"
    {
        printf '\n===============================================================================\n'
        printf '[RUN] %s | step=%s | status=%s | rc=%s | duration_s=%s\n' \
            "$P5_RUN_ID" "$key" "$status" "$rc" "$duration"
        cat "$step_log"
    } | p5_redact_stream >> "$stable_log"
    chmod 600 "$stable_log"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$utc" "$status" "$key" "$rc" "$duration" "$stable_log" >> "$P5_EVENT_LOG"
    chmod 600 "$P5_EVENT_LOG"
    p5_refresh_summary
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

p5_record_step_proof() {
    local key="$1"
    local label="$2"
    local status="$3"
    local rc="$4"
    local log_file="$5"
    local start_time="$6"
    local end_time="$7"
    local proof_log sha clean_label utc

    [[ -f "$log_file" ]] || return 0
    mkdir -p "$P5_STEP_PROOF_DIR"
    proof_log="$P5_STEP_PROOF_DIR/$(basename -- "$log_file")"
    cp -- "$log_file" "$proof_log"
    chmod 600 "$proof_log"

    if command -v sha256sum >/dev/null 2>&1; then
        sha="$(sha256sum "$proof_log" | awk '{print $1}')"
    else
        sha="indisponible"
    fi
    clean_label="${label//$'\t'/ }"
    clean_label="${clean_label//$'\n'/ }"
    utc="$(date -u --iso-8601=seconds)"

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$utc" "$P5_CURRENT_STEP_NUMBER" "$key" "$status" "$rc" \
        "$((end_time - start_time))" "$sha" "$(basename -- "$proof_log")" "$clean_label" \
        >> "$P5_STEP_PROOF_MANIFEST"
    chmod 600 "$P5_STEP_PROOF_MANIFEST"
    printf '[PREUVE] %s — %s — %s\n' "$P5_CURRENT_STEP_NUMBER" "$status" "$proof_log"
}

p5_run_step() {
    local key="$1"
    local label="$2"
    shift 2

    local log_file stable_log start_time end_time rc status
    p5_prepare_step_file "$key"
    log_file="$P5_CURRENT_STEP_LOG"
    stable_log="$(p5_stable_log_for_command "$key" "$@")"

    p5_header "$P5_CURRENT_STEP_NUMBER — $label"
    p5_command_preview "$@"
    printf '       Log      : %s\n\n' "$log_file"

    start_time="$(date +%s)"
    set +e
    "$@" 2>&1 | p5_redact_stream | tee "$log_file"
    rc=${PIPESTATUS[0]}
    set -e
    end_time="$(date +%s)"

    P5_LAST_STEP_RC="$rc"
    P5_LAST_STEP_LOG="$log_file"
    export P5_LAST_STEP_RC P5_LAST_STEP_LOG

    if ((rc == 0)); then
        status='VALIDE'
        p5_record_step_proof "$key" "$label" "$status" "$rc" "$log_file" "$start_time" "$end_time"
        p5_finalize_step_observability "$key" "$status" "$rc" "$((end_time - start_time))" "$log_file" "$stable_log"
        p5_ok "$label — $((end_time - start_time)) s"
    else
        status='ECHEC'
        p5_record_step_proof "$key" "$label" "$status" "$rc" "$log_file" "$start_time" "$end_time"
        p5_finalize_step_observability "$key" "$status" "$rc" "$((end_time - start_time))" "$log_file" "$stable_log"
        p5_error "$label — code retour $rc — voir $log_file"
    fi
    return "$rc"
}

p5_run_step_allow() {
    local accepted_codes="$1"
    local key="$2"
    local label="$3"
    shift 3

    local log_file stable_log start_time end_time rc status
    p5_prepare_step_file "$key"
    log_file="$P5_CURRENT_STEP_LOG"
    stable_log="$(p5_stable_log_for_command "$key" "$@")"

    p5_header "$P5_CURRENT_STEP_NUMBER — $label"
    p5_command_preview "$@"
    printf '       Log      : %s\n\n' "$log_file"

    start_time="$(date +%s)"
    set +e
    "$@" 2>&1 | p5_redact_stream | tee "$log_file"
    rc=${PIPESTATUS[0]}
    set -e
    end_time="$(date +%s)"

    P5_LAST_STEP_RC="$rc"
    P5_LAST_STEP_LOG="$log_file"
    export P5_LAST_STEP_RC P5_LAST_STEP_LOG

    if [[ " $accepted_codes " == *" $rc "* ]]; then
        status='VALIDE'
        p5_record_step_proof "$key" "$label" "$status" "$rc" "$log_file" "$start_time" "$end_time"
        p5_finalize_step_observability "$key" "$status" "$rc" "$((end_time - start_time))" "$log_file" "$stable_log"
        if ((rc == 0)); then
            p5_ok "$label — $((end_time - start_time)) s"
        else
            p5_info "$label — état attendu code $rc — $((end_time - start_time)) s"
        fi
        return 0
    fi

    status='ECHEC'
    p5_record_step_proof "$key" "$label" "$status" "$rc" "$log_file" "$start_time" "$end_time"
    p5_finalize_step_observability "$key" "$status" "$rc" "$((end_time - start_time))" "$log_file" "$stable_log"
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
    [[ "$1" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[^[:space:]]*)?$ ]]
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
    printf 'Preuves par étape        : %s\n' "$P5_STEP_PROOF_DIR"
    printf 'Manifeste des preuves    : %s\n' "$P5_STEP_PROOF_MANIFEST"
    printf 'Journaux par script      : %s\n' "$P5_STABLE_LOG_ROOT"
    printf 'Résumé factuel du run    : %s\n' "$P5_SUMMARY_LOG"
    if [[ -n "${P5_MASTER_LOG:-}" ]]; then
        printf 'Journal principal       : %s\n' "$P5_MASTER_LOG"
    fi
}
