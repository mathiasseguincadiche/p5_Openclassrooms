#!/usr/bin/env bash
# Vérifie le déploiement HTTP de l'application Angular derrière NGINX.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-1"
URL=""

show_help() {
    cat <<'HELP'
Usage: verify-angular-deployment.sh [options]

Options:
  --url URL            URL HTTP de l'application
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Sans --url, le script lit la sortie Terraform web_url de l'exercice 1.
HELP
}

while (($# > 0)); do
    case "$1" in
        --url)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --url.\n' >&2; exit 2; }
            URL="$2"
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

for command_name in terraform curl grep; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done

if [[ -z "$URL" ]]; then
    URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
        output -raw web_url 2>/dev/null || true)"
fi
URL="${URL%/}"
if [[ ! "$URL" =~ ^http://[A-Za-z0-9.-]+(:[0-9]+)?$ ]]; then
    printf 'URL HTTP invalide ou absente : %s\n' "$URL" >&2
    exit 1
fi

mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
HEADERS_FILE="$PROOF_DIR/${TIMESTAMP}-headers.txt"
INDEX_FILE="$PROOF_DIR/${TIMESTAMP}-index.html"
FALLBACK_FILE="$PROOF_DIR/${TIMESTAMP}-fallback.html"
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-verification.log"

{
    printf 'Vérification de l’application Angular\n'
    printf '  URL : %s\n' "$URL"

    HTTP_CODE="$(curl -sS --max-time 15 \
        -D "$HEADERS_FILE" -o "$INDEX_FILE" -w '%{http_code}' "$URL/")"
    [[ "$HTTP_CODE" == "200" ]] || {
        printf '  KO  réponse HTTP %s sur /\n' "$HTTP_CODE" >&2
        exit 1
    }
    printf '  OK  réponse HTTP 200\n'

    grep -q '<app-root' "$INDEX_FILE" || {
        printf '  KO  balise Angular app-root absente\n' >&2
        exit 1
    }
    grep -q 'P5 — Infrastructure as Code' "$INDEX_FILE" || {
        printf '  KO  titre de l’application P5 absent\n' >&2
        exit 1
    }
    printf '  OK  document Angular identifié\n'

    MAIN_BUNDLE="$(grep -oE 'src="[^"]*main[^"]*\.js"' "$INDEX_FILE" \
        | head -n 1 | cut -d '"' -f 2)"
    [[ -n "$MAIN_BUNDLE" ]] || {
        printf '  KO  bundle Angular principal introuvable\n' >&2
        exit 1
    }
    curl -fsS --max-time 20 "$URL/${MAIN_BUNDLE#/}" >/dev/null
    printf '  OK  bundle principal accessible : %s\n' "$MAIN_BUNDLE"

    FALLBACK_CODE="$(curl -sS --max-time 15 \
        -o "$FALLBACK_FILE" -w '%{http_code}' "$URL/parcours-p5")"
    [[ "$FALLBACK_CODE" == "200" ]] || {
        printf '  KO  fallback SPA en erreur : HTTP %s\n' "$FALLBACK_CODE" >&2
        exit 1
    }
    grep -q '<app-root' "$FALLBACK_FILE" || {
        printf '  KO  fallback NGINX ne renvoie pas index.html\n' >&2
        exit 1
    }
    printf '  OK  fallback SPA NGINX opérationnel\n'

    grep -qi '^X-Content-Type-Options: nosniff' "$HEADERS_FILE" || {
        printf '  KO  en-tête X-Content-Type-Options absent\n' >&2
        exit 1
    }
    printf '  OK  en-tête de sécurité nosniff\n'

    printf '\nVerdict : APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX\n'
    printf 'Preuves locales : %s\n' "$PROOF_DIR"
} 2>&1 | tee "$SUMMARY_LOG"
