#!/usr/bin/env bash
# Vérifie les mappings et agrégations nécessaires au dashboard OpenSearch.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-2"
ENDPOINT=""
MIN_DOCUMENTS=64

show_help() {
    cat <<'HELP'
Usage: verify-opensearch-data.sh [options]

Options:
  --endpoint URL       URL HTTPS du domaine OpenSearch
  --min-documents N    nombre minimal de documents attendu (défaut : 64)
  --proof-dir CHEMIN   dossier local des preuves techniques
  -h, --help           afficher cette aide

Le script est strictement non destructif.
HELP
}

while (($# > 0)); do
    case "$1" in
        --endpoint)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --endpoint.\n' >&2; exit 2; }
            ENDPOINT="$2"
            shift 2
            ;;
        --min-documents)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --min-documents.\n' >&2; exit 2; }
            MIN_DOCUMENTS="$2"
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

for command_name in terraform curl jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done
[[ "$MIN_DOCUMENTS" =~ ^[1-9][0-9]*$ ]] || {
    printf '%s\n' '--min-documents doit être un entier positif.' >&2
    exit 2
}

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
MAPPING_RESPONSE="$PROOF_DIR/${TIMESTAMP}-mapping.json"
AGG_RESPONSE="$PROOF_DIR/${TIMESTAMP}-aggregations.json"
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-verification.log"

TMP_QUERY="$(mktemp)"
trap 'rm -f "$TMP_QUERY"' EXIT
cat > "$TMP_QUERY" <<'JSON'
{
  "size": 0,
  "aggs": {
    "methods": {
      "terms": {
        "field": "http_method",
        "size": 10
      }
    },
    "bytes_by_12h": {
      "date_histogram": {
        "field": "@timestamp",
        "fixed_interval": "12h",
        "min_doc_count": 1
      },
      "aggs": {
        "bytes_total": {
          "sum": {
            "field": "bytes_sent"
          }
        }
      }
    },
    "requests_by_12h": {
      "date_histogram": {
        "field": "@timestamp",
        "fixed_interval": "12h",
        "min_doc_count": 1
      },
      "aggs": {
        "top_paths": {
          "terms": {
            "field": "url_path",
            "size": 5
          }
        }
      }
    }
  }
}
JSON

{
    printf 'Vérification OpenSearch\n'

    curl -fsS "$ENDPOINT/nginx-access-*/_mapping" > "$MAPPING_RESPONSE"
    jq -e '
      [to_entries[].value.mappings.properties] |
      all(
        has("@timestamp") and
        has("http_method") and
        has("url_path") and
        has("bytes_sent")
      )
    ' "$MAPPING_RESPONSE" >/dev/null
    printf '  OK  mappings @timestamp, http_method, url_path et bytes_sent\n'

    curl -fsS -X POST \
        -H 'Content-Type: application/json' \
        --data-binary "@$TMP_QUERY" \
        "$ENDPOINT/nginx-access-*/_search" \
        > "$AGG_RESPONSE"

    DOCUMENT_COUNT="$(jq -r '.hits.total.value' "$AGG_RESPONSE")"
    METHOD_COUNT="$(jq -r '.aggregations.methods.buckets | length' "$AGG_RESPONSE")"
    TIME_BUCKET_COUNT="$(jq -r '.aggregations.requests_by_12h.buckets | length' "$AGG_RESPONSE")"
    PATH_COUNT="$(jq -r '[.aggregations.requests_by_12h.buckets[].top_paths.buckets[].key] | unique | length' "$AGG_RESPONSE")"

    ((DOCUMENT_COUNT >= MIN_DOCUMENTS)) || {
        printf '  KO  %s documents, minimum attendu : %s\n' "$DOCUMENT_COUNT" "$MIN_DOCUMENTS" >&2
        exit 1
    }
    ((METHOD_COUNT >= 3)) || {
        printf '  KO  moins de trois méthodes HTTP distinctes\n' >&2
        exit 1
    }
    ((TIME_BUCKET_COUNT >= 4)) || {
        printf '  KO  moins de quatre tranches temporelles de 12 heures\n' >&2
        exit 1
    }
    ((PATH_COUNT >= 5)) || {
        printf '  KO  moins de cinq chemins HTTP distincts\n' >&2
        exit 1
    }

    printf '  OK  documents : %s\n' "$DOCUMENT_COUNT"
    printf '  OK  méthodes HTTP : %s\n' "$METHOD_COUNT"
    printf '  OK  tranches de 12 heures : %s\n' "$TIME_BUCKET_COUNT"
    printf '  OK  chemins exploitables : %s\n' "$PATH_COUNT"

    printf '\nAgrégations utiles au dashboard\n'
    jq -r '
      "  Méthodes : " +
      ([.aggregations.methods.buckets[] | "\(.key)=\(.doc_count)"] | join(", ")),
      "  Octets par 12 h : " +
      ([.aggregations.bytes_by_12h.buckets[] |
        "\(.key_as_string)=\(.bytes_total.value | floor)"] | join(", "))
    ' "$AGG_RESPONSE"

    printf '\nVerdict : DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD\n'
    printf 'Preuves locales : %s\n' "$PROOF_DIR"
} 2>&1 | tee "$SUMMARY_LOG"
