#!/usr/bin/env bash
# Génère un trafic HTTP contrôlé afin d'alimenter le journal NGINX.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-1"
URL=""
REQUESTS=64

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "generate-nginx-traffic"

show_help() {
    cat <<'HELP'
Usage: generate-nginx-traffic.sh [options]

Options:
  --url URL            URL HTTP de l'application
  --requests N         nombre de requêtes à générer (défaut : 64)
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Sans --url, le script lit la sortie Terraform web_url. Si elle n'est pas lisible
en usage manuel, il explique le format attendu et demande l'URL de la cible.
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

for command_name in terraform curl; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
done
if [[ ! "$REQUESTS" =~ ^[0-9]+$ ]] || ((REQUESTS < 1)); then
    p5_error '--requests doit être un entier positif.'
    p5_action 'Exemple : --requests 96'
    exit 2
fi

if [[ -z "$URL" ]]; then
    URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
        output -raw web_url 2>/dev/null || true)"
    if ! p5_validate_http_url "${URL%/}"; then
        p5_unknown 'URL NGINX/Angular' \
            'la sortie Terraform web_url n’est pas disponible' \
            'Pour le parcours normal, relancez p5.sh ex1. Pour une cible connue, saisissez son URL HTTP.'
        p5_prompt_value URL \
            'URL HTTP NGINX/Angular' \
            'Cette URL recevra les requêtes contrôlées destinées à produire le vrai access.log.' \
            'URL HTTP complète sans chemin' 'http://198.51.100.42' '' p5_validate_http_url \
            'Saisissez-la ici, ou relancez avec : --url http://198.51.100.42'
    fi
fi
URL="${URL%/}"
if ! p5_validate_http_url "$URL"; then
    p5_error "URL HTTP invalide : $URL"
    p5_action 'Format attendu : http://hote ou http://hote:port'
    exit 1
fi

METHODS=(GET GET GET HEAD POST OPTIONS)
PATHS=(
    /
    /parcours-p5
    /architecture
    /assets/main.js
    /health
    /api/demo
    /documentation
    /preuves
)

mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-traffic.log"

{
    printf 'Génération de trafic NGINX\n'
    printf '  URL       : %s\n' "$URL"
    printf '  Requêtes  : %s\n\n' "$REQUESTS"

    for ((request_number = 0; request_number < REQUESTS; request_number++)); do
        method="${METHODS[request_number % ${#METHODS[@]}]}"
        path="${PATHS[(request_number * 3) % ${#PATHS[@]}]}"
        curl_options=(
            -sS
            --max-time 10
            -o /dev/null
            -w '%{http_code}'
        )
        if [[ "$method" == HEAD ]]; then
            # --head active le comportement HEAD natif de curl : curl ne doit pas
            # attendre un corps de réponse que le serveur HTTP n'enverra pas.
            curl_options+=(--head)
        else
            curl_options+=(-X "$method")
        fi
        if [[ "$method" == POST ]]; then
            curl_options+=(--data 'source=p5-lab')
        fi
        status="$(curl "${curl_options[@]}" "$URL$path")"
        [[ "$status" =~ ^[0-9]{3}$ ]] || {
            printf '  KO  réponse invalide pour %s %s\n' "$method" "$path" >&2
            exit 1
        }
        printf '  %02d  %-7s %-20s HTTP %s\n' \
            "$((request_number + 1))" "$method" "$path" "$status"
        sleep 0.05
    done

    printf '\nVerdict : TRAFIC NGINX GÉNÉRÉ\n'
    printf 'Preuve locale : %s\n' "$SUMMARY_LOG"
} 2>&1 | tee "$SUMMARY_LOG"
