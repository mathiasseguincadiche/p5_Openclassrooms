#!/usr/bin/env bash
# Récupère les vrais logs NGINX de l'EC2 de l'exercice 1.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-2"
SSH_KEY=""
SSH_USER="ubuntu"
LINES=500
WEB_IP=""
OUTPUT_FILE=""

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "collect-nginx-access-log"

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

Sans --host, le script lit la sortie Terraform web_public_ip. Si cette sortie
n'est pas disponible en usage manuel, le script explique le format et demande
l'IPv4 à utiliser. La clé SSH est traitée de la même manière.
HELP
}

while (($# > 0)); do
    case "$1" in
        --host)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --host.'; exit 2; }
            WEB_IP="$2"
            shift 2
            ;;
        --lines)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --lines.'; exit 2; }
            LINES="$2"
            shift 2
            ;;
        --ssh-key)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-key.'; exit 2; }
            SSH_KEY="$2"
            shift 2
            ;;
        --ssh-user)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-user.'; exit 2; }
            SSH_USER="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --output.'; exit 2; }
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --proof-dir.'; exit 2; }
            PROOF_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            p5_error "Option inconnue : $1"
            show_help >&2
            exit 2
            ;;
    esac
done

for command_name in terraform ssh python3; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
done
if [[ ! "$LINES" =~ ^[1-9][0-9]*$ ]]; then
    p5_error '--lines doit être un entier positif.'
    p5_action 'Exemple : --lines 500'
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
SSH_KEY="${SSH_KEY/#\~/$HOME}"
if [[ ! -f "$SSH_KEY" ]]; then
    p5_unknown 'Clé SSH privée pour la collecte NGINX' "fichier absent : $SSH_KEY" \
        'Indiquez la clé privée correspondant à la paire EC2 de l’exercice 1.'
    p5_prompt_value SSH_KEY \
        'Chemin de la clé SSH privée' \
        'La collecte doit ouvrir une session SSH sur l’EC2 NGINX.' \
        'chemin absolu vers un fichier existant' "$HOME/.ssh/p5-key" '' p5_validate_existing_file \
        "Saisissez-la ici, ou relancez avec : --ssh-key $HOME/.ssh/p5-key"
fi

if [[ -z "$WEB_IP" ]]; then
    WEB_IP="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
        output -raw web_public_ip 2>/dev/null || true)"
    if ! p5_validate_ipv4 "$WEB_IP"; then
        p5_unknown 'Adresse publique de la cible NGINX' \
            'la sortie Terraform web_public_ip n’est pas disponible' \
            'Pour le parcours normal, relancez p5.sh ex1. Pour une cible que vous connaissez et voulez diagnostiquer, saisissez son IPv4.'
        p5_prompt_value WEB_IP \
            'IPv4 publique de la cible NGINX' \
            'Elle désigne l’EC2 dont /var/log/nginx/access.log doit être collecté.' \
            'IPv4 seule' '198.51.100.42' '' p5_validate_ipv4 \
            'Saisissez-la ici, ou relancez avec : --host 198.51.100.42'
    fi
fi
if ! p5_validate_ipv4 "$WEB_IP"; then
    p5_error "Adresse publique NGINX invalide : $WEB_IP"
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
    printf '  Clé SSH    : %s\n' "$SSH_KEY"

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

if [[ "${P5_ORCHESTRATED:-0}" == 1 ]]; then
    bash "$SCRIPT_DIR/verify-aws-exercise-state.sh" --exercise 1
fi
