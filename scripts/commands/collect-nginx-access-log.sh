#!/usr/bin/env bash
# Récupère les vrais logs NGINX de l'EC2 de l'exercice 1.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-2"
SSH_KEY=""
SSH_USER="ubuntu"
LINES=500
WEB_IP=""
OUTPUT_FILE=""

show_help() {
    cat <<'HELP'
Usage: collect-nginx-access-log.sh [options]

Options:
  --host IP            adresse publique de la cible NGINX
  --lines N            nombre maximal de lignes (défaut : 500)
  --ssh-key CHEMIN     clé SSH privée ; sinon configuration locale du lab
  --ssh-user NOM       utilisateur SSH (défaut : ubuntu)
  --output CHEMIN      fichier local de destination
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Sans --host, le script lit la sortie Terraform web_public_ip de l'exercice 1.
HELP
}

while (($# > 0)); do
    case "$1" in
        --host)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --host.\n' >&2; exit 2; }
            WEB_IP="$2"
            shift 2
            ;;
        --lines)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --lines.\n' >&2; exit 2; }
            LINES="$2"
            shift 2
            ;;
        --ssh-key)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --ssh-key.\n' >&2; exit 2; }
            SSH_KEY="$2"
            shift 2
            ;;
        --ssh-user)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --ssh-user.\n' >&2; exit 2; }
            SSH_USER="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --output.\n' >&2; exit 2; }
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --proof-dir.\n' >&2; exit 2; }
            PROOF_DIR="$2"
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

for command_name in terraform ssh python3; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done
if [[ ! "$LINES" =~ ^[1-9][0-9]*$ ]]; then
    printf '%s\n' '--lines doit être un entier positif.' >&2
    exit 2
fi

if [[ -z "$SSH_KEY" && -r "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    SSH_KEY="${P5_SSH_KEY_PATH:-}"
    if [[ -z "$SSH_KEY" ]]; then
        PUBLIC_KEY_PATH="${P5_SSH_PUBLIC_KEY_PATH:-$HOME/.ssh/p5-key.pub}"
        SSH_KEY="${PUBLIC_KEY_PATH%.pub}"
    fi
fi
SSH_KEY="${SSH_KEY:-$HOME/.ssh/p5-key}"
[[ -f "$SSH_KEY" ]] || { printf 'Clé SSH absente : %s\n' "$SSH_KEY" >&2; exit 1; }

if [[ -z "$WEB_IP" ]]; then
    WEB_IP="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
        output -raw web_public_ip 2>/dev/null || true)"
fi
if [[ ! "$WEB_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    printf 'Adresse publique NGINX invalide ou absente.\n' >&2
    exit 1
fi

umask 077
mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="$PROOF_DIR/${TIMESTAMP}-nginx-access-real.log"
else
    mkdir -p "$(dirname "$OUTPUT_FILE")"
fi
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-collect.log"
TMP_LOG="$(mktemp "$PROOF_DIR/.nginx-access.XXXXXX")"
cleanup() {
    rm -f "$TMP_LOG"
}
trap cleanup EXIT INT TERM
SSH_OPTIONS=(
    -i "$SSH_KEY"
    -o BatchMode=yes
    -o ConnectTimeout=10
    -o StrictHostKeyChecking=accept-new
)

{
    printf 'Collecte des logs NGINX réels\n'
    printf '  Hôte       : %s\n' "$WEB_IP"
    printf '  Lignes max : %s\n' "$LINES"

    ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$WEB_IP" \
        "sudo tail -n $LINES /var/log/nginx/access.log" \
        > "$TMP_LOG"

    [[ -s "$TMP_LOG" ]] || {
        printf '  KO  aucun log NGINX récupéré\n' >&2
        exit 1
    }

    python3 "$PROJECT_ROOT/scripts/tools/convert-nginx-logs.py" \
        "$TMP_LOG" --validate-only >/dev/null
    install -m 0600 "$TMP_LOG" "$OUTPUT_FILE"
    printf '  OK  format NGINX combined validé\n'
    printf '  OK  fichier local : %s\n' "$OUTPUT_FILE"

    printf '\nPour importer ces logs :\n'
    printf '  ./scripts/commands/import-opensearch-data.sh --input %q --apply\n' \
        "$OUTPUT_FILE"
    printf '\nVerdict : LOGS NGINX RÉELS COLLECTÉS\n'
} 2>&1 | tee "$SUMMARY_LOG"
