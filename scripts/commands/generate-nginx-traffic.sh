#!/usr/bin/env bash
# Génère un trafic HTTP contrôlé afin d'alimenter le journal NGINX.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-1"
URL=""
REQUESTS=64

show_help() {
    cat <<'HELP'
Usage: generate-nginx-traffic.sh [options]

Options:
  --url URL            URL HTTP de l'application
  --requests N         nombre de requêtes à générer (défaut : 64)
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Le script ne modifie aucune ressource ; il produit uniquement des requêtes HTTP.
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

for command_name in terraform curl; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done
if [[ ! "$REQUESTS" =~ ^[0-9]+$ ]] || ((REQUESTS < 1)); then
    printf '%s\n' '--requests doit être un entier positif.' >&2
    exit 2
fi

if [[ -z "$URL" ]]; then
    URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
        output -raw web_url 2>/dev/null || true)"
fi
URL="${URL%/}"
if [[ ! "$URL" =~ ^http://[A-Za-z0-9.-]+(:[0-9]+)?$ ]]; then
    printf 'URL HTTP invalide ou absente : %s\n' "$URL" >&2
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
            -X "$method"
        )
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
