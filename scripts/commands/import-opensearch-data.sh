#!/usr/bin/env bash
# Prépare puis importe des logs NGINX dans Amazon OpenSearch.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
INPUT_FILE="$PROJECT_ROOT/terraform/exercice-2/samples/nginx-access.log.sample"
TEMPLATE_FILE="$PROJECT_ROOT/terraform/exercice-2/opensearch/index-template.json"
CONVERTER="$PROJECT_ROOT/scripts/tools/convert-nginx-logs.py"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-2"
ENDPOINT=""
APPLY=false

show_help() {
    cat <<'HELP'
Usage: import-opensearch-data.sh [options]

Options:
  --input CHEMIN      fichier NGINX combined à importer
  --endpoint URL      URL HTTPS du domaine OpenSearch
  --proof-dir CHEMIN  dossier local des preuves techniques
  --apply             créer le template et importer les documents
  -h, --help          afficher cette aide

Sans --apply, le script valide et convertit les données sans contacter OpenSearch.
HELP
}

while (($# > 0)); do
    case "$1" in
        --input)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --input.\n' >&2; exit 2; }
            INPUT_FILE="$2"
            shift 2
            ;;
        --endpoint)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --endpoint.\n' >&2; exit 2; }
            ENDPOINT="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --proof-dir.\n' >&2; exit 2; }
            PROOF_DIR="$2"
            shift 2
            ;;
        --apply)
            APPLY=true
            shift
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

for command_name in python3 curl jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done

[[ -f "$INPUT_FILE" ]] || { printf 'Fichier de logs absent : %s\n' "$INPUT_FILE" >&2; exit 1; }
[[ -f "$TEMPLATE_FILE" ]] || { printf 'Template absent : %s\n' "$TEMPLATE_FILE" >&2; exit 1; }
[[ -x "$CONVERTER" || -f "$CONVERTER" ]] || {
    printf 'Convertisseur absent : %s\n' "$CONVERTER" >&2
    exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
BULK_FILE="$TMP_DIR/nginx-access.bulk.ndjson"

python3 "$CONVERTER" "$INPUT_FILE" --output "$BULK_FILE"
LINE_COUNT="$(wc -l < "$BULK_FILE")"
if ((LINE_COUNT == 0 || LINE_COUNT % 2 != 0)); then
    printf 'NDJSON Bulk invalide : %s lignes.\n' "$LINE_COUNT" >&2
    exit 1
fi
DOCUMENT_COUNT=$((LINE_COUNT / 2))

printf 'Préparation OpenSearch\n'
printf '  Source      : %s\n' "$INPUT_FILE"
printf '  Documents   : %s\n' "$DOCUMENT_COUNT"
printf '  Template    : %s\n' "$TEMPLATE_FILE"

if [[ "$APPLY" != true ]]; then
    printf '\nAucune donnée envoyée. Relancez avec --apply après vérification.\n'
    exit 0
fi

if [[ -z "$ENDPOINT" ]]; then
    ENDPOINT="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-2" \
        output -raw opensearch_endpoint 2>/dev/null || true)"
fi
ENDPOINT="${ENDPOINT%/}"
if [[ ! "$ENDPOINT" =~ ^https://[A-Za-z0-9.-]+$ ]]; then
    printf 'Endpoint OpenSearch HTTPS invalide ou absent : %s\n' "$ENDPOINT" >&2
    exit 1
fi

mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TEMPLATE_RESPONSE="$PROOF_DIR/${TIMESTAMP}-template.json"
BULK_RESPONSE="$PROOF_DIR/${TIMESTAMP}-bulk.json"
COUNT_RESPONSE="$PROOF_DIR/${TIMESTAMP}-count.json"
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-import.log"

{
    printf '\nConnexion au domaine OpenSearch\n'
    curl -fsS "$ENDPOINT/" >/dev/null
    printf '  OK  domaine accessible\n'

    printf '\nCréation ou mise à jour du template p5-nginx-access\n'
    curl -fsS -X PUT \
        -H 'Content-Type: application/json' \
        --data-binary "@$TEMPLATE_FILE" \
        "$ENDPOINT/_index_template/p5-nginx-access" \
        > "$TEMPLATE_RESPONSE"
    jq -e '.acknowledged == true' "$TEMPLATE_RESPONSE" >/dev/null
    printf '  OK  template reconnu\n'

    printf '\nImport Bulk de %s documents\n' "$DOCUMENT_COUNT"
    curl -fsS -X POST \
        -H 'Content-Type: application/x-ndjson' \
        --data-binary "@$BULK_FILE" \
        "$ENDPOINT/_bulk?refresh=true" \
        > "$BULK_RESPONSE"
    if ! jq -e '.errors == false' "$BULK_RESPONSE" >/dev/null; then
        jq '[.items[] | select(.index.error != null) | .index.error]' "$BULK_RESPONSE" >&2
        exit 1
    fi
    printf '  OK  aucun document en erreur\n'

    curl -fsS "$ENDPOINT/nginx-access-*/_count" > "$COUNT_RESPONSE"
    IMPORTED_COUNT="$(jq -r '.count' "$COUNT_RESPONSE")"
    printf '  OK  documents présents dans nginx-access-* : %s\n' "$IMPORTED_COUNT"

    printf '\nVerdict : IMPORT OPENSEARCH RÉUSSI\n'
    printf 'Preuves locales : %s\n' "$PROOF_DIR"
} 2>&1 | tee "$SUMMARY_LOG"
