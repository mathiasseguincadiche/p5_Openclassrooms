#!/usr/bin/env bash
# Vérifie l'alternance des deux backends HAProxy.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-3"
URL=""
REQUESTS=10

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "test-haproxy-roundrobin"

show_help() {
    cat <<'HELP'
Usage: test-haproxy-roundrobin.sh [options]

Options:
  --url URL            URL HTTP publique de HAProxy
  --requests N         nombre de requêtes (défaut : 10)
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Sans --url, le script lit la sortie Terraform haproxy_url. Si elle est absente
en usage manuel, le script explique le format attendu et demande la cible.
HELP
}

while (($# > 0)); do
    case "$1" in
        --url)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --url.'; exit 2; }
            URL="$2"
            shift 2
            ;;
        --requests)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --requests.'; exit 2; }
            REQUESTS="$2"
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

for command_name in terraform curl awk; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
done
if [[ ! "$REQUESTS" =~ ^[0-9]+$ ]] || ((REQUESTS < 2)); then
    p5_error '--requests doit être un entier supérieur ou égal à 2.'
    p5_action 'Exemple : --requests 12'
    exit 2
fi

if [[ -z "$URL" ]]; then
    URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-3" \
        output -raw haproxy_url 2>/dev/null || true)"
    if ! p5_validate_http_url "${URL%/}"; then
        p5_unknown 'URL publique HAProxy' \
            'la sortie Terraform haproxy_url est absente ou illisible' \
            'Pour le parcours normal, relancez p5.sh ex3. Pour une cible connue, saisissez son URL HTTP.'
        p5_prompt_value URL \
            'URL HTTP de HAProxy' \
            'Le test doit envoyer plusieurs requêtes au load balancer pour observer les deux backends.' \
            'URL HTTP complète sans chemin' 'http://198.51.100.60' '' p5_validate_http_url \
            'Saisissez-la ici, ou relancez avec : --url http://198.51.100.60'
    fi
fi
URL="${URL%/}"
if ! p5_validate_http_url "$URL"; then
    p5_error "URL HAProxy invalide : $URL"
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
