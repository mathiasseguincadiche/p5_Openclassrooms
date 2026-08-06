#!/usr/bin/env bash
# Collecte un diagnostic horodaté et partageable de la VM Ubuntu du projet P5.
set -uo pipefail

umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
DIAGNOSTIC_ROOT="$PROJECT_ROOT/proofs/runtime/diagnostics"
MODE="standard"
INCLUDE_PROOFS=0
CUSTOM_OUTPUT=""
OK_COUNT=0
WARNING_COUNT=0
KO_COUNT=0
AWS_READY=0

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/collect-diagnostics.sh [options]

Options:
  --complet          ajoute l'intégration locale OpenSearch complète
  --avec-preuves     ajoute les preuves runtime des trois exercices à l'archive
  --output CHEMIN    dossier racine des diagnostics
  -h, --help         affiche cette aide

Le script ne crée, ne modifie et ne détruit aucune ressource AWS.
Il produit un résumé, un journal complet local, un journal nettoyé pour partage
et une archive .tar.gz à transmettre pour analyse.
HELP
}

while (($# > 0)); do
    case "$1" in
        --complet)
            MODE="complet"
            shift
            ;;
        --avec-preuves)
            INCLUDE_PROOFS=1
            shift
            ;;
        --output)
            [[ $# -ge 2 ]] || {
                printf 'Valeur manquante pour --output.\n' >&2
                exit 2
            }
            CUSTOM_OUTPUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            printf 'Option inconnue : %s\n' "$1" >&2
            show_help >&2
            exit 2
            ;;
    esac
done

if [[ -n "$CUSTOM_OUTPUT" ]]; then
    DIAGNOSTIC_ROOT="$CUSTOM_OUTPUT"
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SESSION_DIR="$DIAGNOSTIC_ROOT/p5-diagnostic-$TIMESTAMP"
FULL_LOG="$SESSION_DIR/diagnostic-complet.log"
SHARE_LOG="$SESSION_DIR/diagnostic-partage.log"
SUMMARY_LOG="$SESSION_DIR/resume.txt"
MANIFEST_FILE="$SESSION_DIR/manifest-preuves.txt"
ARCHIVE="$DIAGNOSTIC_ROOT/p5-diagnostic-$TIMESTAMP.tar.gz"
STAGING_DIR=""

mkdir -p "$SESSION_DIR"
chmod 700 "$SESSION_DIR"
: >"$FULL_LOG"
: >"$SUMMARY_LOG"
: >"$MANIFEST_FILE"
chmod 600 "$FULL_LOG" "$SUMMARY_LOG" "$MANIFEST_FILE"

cleanup() {
    if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
        rm -rf -- "$STAGING_DIR"
    fi
}
trap cleanup EXIT

append_summary() {
    printf '%s\n' "$1" | tee -a "$SUMMARY_LOG" >/dev/null
}

record_warning() {
    local message="$1"
    WARNING_COUNT=$((WARNING_COUNT + 1))
    printf '\n⚠️  %s\n' "$message" | tee -a "$FULL_LOG"
    append_summary "AVERTISSEMENT | $message"
}

run_logged() {
    local severity="$1"
    local label="$2"
    shift 2

    printf '\n================================================================\n' | tee -a "$FULL_LOG"
    printf '▶ %s\n' "$label" | tee -a "$FULL_LOG"
    printf '================================================================\n' | tee -a "$FULL_LOG"

    "$@" 2>&1 | tee -a "$FULL_LOG"
    local status="${PIPESTATUS[0]}"

    if [[ "$status" -eq 0 ]]; then
        OK_COUNT=$((OK_COUNT + 1))
        append_summary "OK | $label"
        printf '✅ %s\n' "$label" | tee -a "$FULL_LOG"
        return 0
    fi

    if [[ "$severity" == "required" ]]; then
        KO_COUNT=$((KO_COUNT + 1))
        append_summary "KO | $label | code=$status"
        printf '❌ %s (code %s)\n' "$label" "$status" | tee -a "$FULL_LOG"
    else
        WARNING_COUNT=$((WARNING_COUNT + 1))
        append_summary "AVERTISSEMENT | $label | code=$status"
        printf '⚠️  %s (code %s)\n' "$label" "$status" | tee -a "$FULL_LOG"
    fi
    return 0
}

print_version() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf '%-20s absent\n' "$command_name"
        return 0
    fi

    case "$command_name" in
        ansible-playbook) ansible-playbook --version 2>&1 | sed -n '1p' ;;
        aws) aws --version 2>&1 ;;
        docker) docker --version 2>&1 ;;
        git) git --version 2>&1 ;;
        node) node --version 2>&1 ;;
        npm) npm --version 2>&1 ;;
        python3) python3 --version 2>&1 ;;
        shellcheck) shellcheck --version 2>&1 | grep -E '^(version:|ShellCheck)' || true ;;
        terraform) terraform version 2>&1 | sed -n '1p' ;;
        yamllint) yamllint --version 2>&1 ;;
        *) "$command_name" --version 2>&1 | sed -n '1p' ;;
    esac
}

collect_system_snapshot() {
    printf 'Diagnostic UTC : %s\n' "$(date -u --iso-8601=seconds)"
    printf 'Projet         : %s\n' "$PROJECT_ROOT"
    printf 'Mode           : %s\n' "$MODE"
    printf 'Utilisateur    : %s\n' "$(id -un)"
    printf 'Noyau          : %s\n' "$(uname -srmo)"

    if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        printf 'Système        : %s\n' "${PRETTY_NAME:-inconnu}"
    fi

    printf '\nGit\n'
    git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true
    git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || true
    git -C "$PROJECT_ROOT" status --short 2>/dev/null || true

    printf '\nRessources\n'
    command -v nproc >/dev/null 2>&1 && printf 'CPU logiques : %s\n' "$(nproc)"
    command -v free >/dev/null 2>&1 && free -h
    df -h "$PROJECT_ROOT"

    printf '\nVersions\n'
    local command_name
    for command_name in git python3 terraform ansible-playbook aws docker node npm shellcheck yamllint; do
        printf '%-20s ' "$command_name"
        print_version "$command_name"
    done

    printf '\nDocker\n'
    if command -v docker >/dev/null 2>&1; then
        docker info --format 'Server={{.ServerVersion}} Driver={{.Driver}} Cgroup={{.CgroupVersion}}' 2>&1 || true
        docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1 || true
    else
        printf 'Docker absent.\n'
    fi
}

collect_runtime_manifest() {
    printf 'Fichiers runtime présents au %s\n\n' "$(date -u --iso-8601=seconds)"
    if [[ ! -d "$PROJECT_ROOT/proofs/runtime" ]]; then
        printf 'Aucun dossier proofs/runtime.\n'
        return 0
    fi

    find "$PROJECT_ROOT/proofs/runtime" \
        -path "$DIAGNOSTIC_ROOT" -prune -o \
        -type f -printf '%P | %s octets | %TY-%Tm-%TdT%TH:%TM:%TSZ\n' \
        | sort
}

sanitize_log() {
    python3 - "$FULL_LOG" "$SHARE_LOG" <<'PY'
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
patterns = [
    (r"AKIA[0-9A-Z]{16}", "[AWS_ACCESS_KEY_REDACTED]"),
    (r"(?im)^(\s*aws_secret_access_key\s*[=:]\s*).+$", r"\1[REDACTED]"),
    (r"(?im)^(\s*aws_session_token\s*[=:]\s*).+$", r"\1[REDACTED]"),
    (r"(?im)^(\s*authorization\s*:\s*).+$", r"\1[REDACTED]"),
    (
        r"-----BEGIN [^-]+ PRIVATE KEY-----.*?-----END [^-]+ PRIVATE KEY-----",
        "[PRIVATE_KEY_REDACTED]",
    ),
]
for pattern, replacement in patterns:
    source = re.sub(
        pattern,
        replacement,
        source,
        flags=re.DOTALL if "PRIVATE KEY" in pattern else 0,
    )
Path(sys.argv[2]).write_text(source, encoding="utf-8")
PY
    chmod 600 "$SHARE_LOG"
}

create_archive() {
    STAGING_DIR="$(mktemp -d "$DIAGNOSTIC_ROOT/.partage-$TIMESTAMP.XXXXXX")"
    install -m 0600 "$SUMMARY_LOG" "$STAGING_DIR/resume.txt"
    install -m 0600 "$SHARE_LOG" "$STAGING_DIR/diagnostic-partage.log"
    install -m 0600 "$MANIFEST_FILE" "$STAGING_DIR/manifest-preuves.txt"
    cat >"$STAGING_DIR/A_LIRE.txt" <<'TXT'
Cette archive est destinée au diagnostic privé du projet P5.
Les clés AWS, jetons, en-têtes Authorization et blocs de clé privée détectables
ont été masqués dans diagnostic-partage.log.
Relire néanmoins l'archive avant toute publication publique.
TXT
    chmod 600 "$STAGING_DIR/A_LIRE.txt"

    if [[ "$INCLUDE_PROOFS" -eq 1 ]]; then
        local proof_dir
        for proof_dir in exercice-1 exercice-2 exercice-3; do
            if [[ -d "$PROJECT_ROOT/proofs/runtime/$proof_dir" ]]; then
                cp -a "$PROJECT_ROOT/proofs/runtime/$proof_dir" "$STAGING_DIR/"
            fi
        done
    fi

    tar -czf "$ARCHIVE" -C "$STAGING_DIR" .
    chmod 600 "$ARCHIVE"
}

append_summary "P5 - DIAGNOSTIC VM"
append_summary "UTC | $(date -u --iso-8601=seconds)"
append_summary "MODE | $MODE"

run_logged required "État de la VM et versions" collect_system_snapshot
run_logged required "Contrôle du socle et du dépôt" "$SCRIPT_DIR/setup.sh" --check-only

CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
if [[ -r "$CONFIG_FILE" ]]; then
    BEFORE_WARNINGS="$WARNING_COUNT"
    run_logged optional "Précontrôle AWS non destructif" \
        "$SCRIPT_DIR/pre-deployment-check.sh" --stage initial
    if [[ "$WARNING_COUNT" -eq "$BEFORE_WARNINGS" ]]; then
        AWS_READY=1
    fi
else
    record_warning "environment/aws-readiness.env absent : précontrôle AWS non exécuté"
fi

if [[ "$MODE" == "complet" ]]; then
    run_logged required "Validation locale complète avec OpenSearch" \
        env P5_FULL_INTEGRATION=1 "$SCRIPT_DIR/validate.sh"
fi

collect_runtime_manifest >"$MANIFEST_FILE"
sanitize_log

{
    printf '\nSYNTHÈSE\n'
    printf 'OK=%s | AVERTISSEMENTS=%s | KO=%s\n' \
        "$OK_COUNT" "$WARNING_COUNT" "$KO_COUNT"
    if [[ "$KO_COUNT" -gt 0 ]]; then
        printf 'Verdict : CORRECTIONS NÉCESSAIRES\n'
    elif [[ "$AWS_READY" -eq 1 ]]; then
        printf 'Verdict : VM VALIDÉE ET PRÉCONTRÔLE AWS RÉUSSI\n'
    elif [[ "$WARNING_COUNT" -gt 0 ]]; then
        printf 'Verdict : DIAGNOSTIC EXPLOITABLE AVEC AVERTISSEMENTS\n'
    else
        printf 'Verdict : VM VALIDÉE\n'
    fi
} | tee -a "$SUMMARY_LOG" "$FULL_LOG"

create_archive

printf '\nDiagnostic local complet : %s\n' "$FULL_LOG"
printf 'Archive à transmettre    : %s\n' "$ARCHIVE"
printf 'Ne publiez pas proofs/runtime/ sans relecture.\n'

if [[ "$KO_COUNT" -gt 0 ]]; then
    exit 1
fi
exit 0
