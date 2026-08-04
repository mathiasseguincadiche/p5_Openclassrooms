#!/usr/bin/env bash
# Vérifie l'alternance des deux backends HAProxy.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-3"
URL=""
REQUESTS=10

show_help() {
    cat <<'HELP'
Usage: test-haproxy-roundrobin.sh [options]

Options:
  --url URL            URL HTTP publique de HAProxy
  --requests N         nombre de requêtes (défaut : 10)
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Sans --url, le script lit la sortie Terraform haproxy_url de l'exercice 3.
HELP
}

while (($# > 0)); do
    case "$1" in
        --url)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --url.\n' >&2; exit 2; }
            URL="$2"
            shift 2
            ;;
        --requests)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --requests.\n' >&2; exit 2; }
            REQUESTS="$2"
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

for command_name in terraform curl awk; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done
if [[ ! "$REQUESTS" =~ ^[0-9]+$ ]] || ((REQUESTS < 2)); then
    printf '%s\n' '--requests doit être un entier supérieur ou égal à 2.' >&2
    exit 2
fi

if [[ -z "$URL" ]]; then
    URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-3" \
        output -raw haproxy_url 2>/dev/null || true)"
fi
URL="${URL%/}"
if [[ ! "$URL" =~ ^http://[A-Za-z0-9.-]+(:[0-9]+)?$ ]]; then
    printf 'URL HAProxy invalide ou absente : %s\n' "$URL" >&2
    exit 1
fi

mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-roundrobin.log"

declare -A SERVERS=()
{
    printf 'Test HAProxy round-robin\n'
    printf '  URL       : %s\n' "$URL"
    printf '  Requêtes  : %s\n\n' "$REQUESTS"

    for ((request_number = 1; request_number <= REQUESTS; request_number++)); do
        RESPONSE="$(curl -fsS --max-time 10 "$URL/")"
        SERVER_NAME="$(awk -F': ' '/^Server name:/ {print $2; exit}' <<< "$RESPONSE")"
        [[ -n "$SERVER_NAME" ]] || {
            printf '  KO  réponse %s sans champ Server name\n' "$request_number" >&2
            exit 1
        }
        SERVERS["$SERVER_NAME"]=1
        printf '  %02d  %s\n' "$request_number" "$SERVER_NAME"
        sleep 0.2
    done

    UNIQUE_COUNT="${#SERVERS[@]}"
    ((UNIQUE_COUNT >= 2)) || {
        printf '\n  KO  un seul backend observé\n' >&2
        exit 1
    }
    printf '\n  OK  %s backends distincts observés\n' "$UNIQUE_COUNT"
    printf 'Verdict : ROUND-ROBIN OPÉRATIONNEL\n'
    printf 'Preuve locale : %s\n' "$SUMMARY_LOG"
} 2>&1 | tee "$SUMMARY_LOG"
