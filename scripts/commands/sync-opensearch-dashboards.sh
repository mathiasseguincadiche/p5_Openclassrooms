#!/usr/bin/env bash
# Construit, synchronise et vérifie les Saved Objects OpenSearch Dashboards du P5.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
MANIFEST="$PROJECT_ROOT/terraform/exercice-2/opensearch/dashboards/p5-dashboard.json"
INDEX_TEMPLATE="$PROJECT_ROOT/terraform/exercice-2/opensearch/index-template.json"
BUILDER="$PROJECT_ROOT/scripts/tools/build-opensearch-saved-objects.py"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-2"
ENDPOINT=""
DASHBOARDS_URL=""
APPLY=false

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "sync-opensearch-dashboards"

show_help() {
    cat <<'HELP'
Usage: sync-opensearch-dashboards.sh [options]

Options:
  --endpoint URL         endpoint HTTPS Amazon OpenSearch
  --dashboards-url URL   URL OpenSearch Dashboards fournie par Terraform
  --proof-dir CHEMIN     dossier des preuves runtime
  --apply                importer/réconcilier les Saved Objects puis les vérifier
  -h, --help             afficher cette aide

Sans --apply, le script génère et valide le bundle NDJSON sans mutation distante.
Avec --apply, il vérifie le contrat de champs réel puis importe avec overwrite=true.
HELP
}

while (($# > 0)); do
    case "$1" in
        --endpoint)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --endpoint.'; exit 2; }
            ENDPOINT="$2"
            shift 2
            ;;
        --dashboards-url)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --dashboards-url.'; exit 2; }
            DASHBOARDS_URL="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --proof-dir.'; exit 2; }
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
            p5_error "Option inconnue : $1"
            show_help >&2
            exit 2
            ;;
    esac
done

for command_name in python3 curl jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
done

[[ -f "$MANIFEST" ]] || { p5_error "Manifest Dashboards absent : $MANIFEST"; exit 1; }
[[ -f "$INDEX_TEMPLATE" ]] || { p5_error "Template OpenSearch absent : $INDEX_TEMPLATE"; exit 1; }
[[ -f "$BUILDER" ]] || { p5_error "Générateur Saved Objects absent : $BUILDER"; exit 1; }

valid_https_url() {
    [[ "$1" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?(/[^[:space:]]*)?$ ]]
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
BUNDLE="$TMP_DIR/p5-opensearch-dashboards.ndjson"
FIELD_CAPS="$TMP_DIR/field-caps.json"
IMPORT_RESPONSE="$TMP_DIR/import-response.json"
VERIFY_RESPONSE="$TMP_DIR/verify-response.json"

python3 "$BUILDER" \
    --manifest "$MANIFEST" \
    --index-template "$INDEX_TEMPLATE" \
    --output "$BUNDLE"

EXPECTED_OBJECTS="$(jq -r '1 + (.visualizations | length) + 1' "$MANIFEST")"
ACTUAL_OBJECTS="$(wc -l < "$BUNDLE" | tr -d ' ')"
[[ "$ACTUAL_OBJECTS" == "$EXPECTED_OBJECTS" ]] || {
    p5_error "Bundle Saved Objects incomplet : $ACTUAL_OBJECTS/$EXPECTED_OBJECTS objets."
    exit 1
}

printf 'Bundle OpenSearch Dashboards\n'
printf '  Source      : %s\n' "$MANIFEST"
printf '  Objets      : %s\n' "$ACTUAL_OBJECTS"
printf '  Index       : %s\n' "$(jq -r '.index_pattern.title' "$MANIFEST")"
printf '  Dashboard   : %s\n' "$(jq -r '.dashboard.title' "$MANIFEST")"

if [[ "$APPLY" != true ]]; then
    printf '\nAucune mutation distante. Bundle généré et validé avec succès.\n'
    exit 0
fi

if [[ -z "$ENDPOINT" ]]; then
    ENDPOINT="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-2" \
        output -raw opensearch_endpoint 2>/dev/null || true)"
fi
if [[ -z "$DASHBOARDS_URL" ]]; then
    DASHBOARDS_URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-2" \
        output -raw opensearch_dashboards_endpoint 2>/dev/null || true)"
fi
ENDPOINT="${ENDPOINT%/}"
DASHBOARDS_URL="${DASHBOARDS_URL%/}"

valid_https_url "$ENDPOINT" || {
    p5_error "Endpoint OpenSearch invalide : ${ENDPOINT:-<vide>}"
    exit 1
}
valid_https_url "$DASHBOARDS_URL" || {
    p5_error "URL OpenSearch Dashboards invalide : ${DASHBOARDS_URL:-<vide>}"
    exit 1
}

printf '\nContrat de champs OpenSearch\n'
curl -fsS \
    "$ENDPOINT/nginx-access-*/_field_caps?fields=%40timestamp,http_method,bytes_sent,url_path&ignore_unavailable=false" \
    > "$FIELD_CAPS"
python3 - "$FIELD_CAPS" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    caps = json.load(stream).get("fields", {})
expected = {
    "@timestamp": {"date"},
    "http_method": {"keyword"},
    "bytes_sent": {"long", "integer", "short", "double", "float", "scaled_float"},
    "url_path": {"keyword"},
}
for field, allowed in expected.items():
    entries = caps.get(field)
    if not entries:
        raise SystemExit(f"Champ requis absent du field_caps : {field}")
    types = set(entries)
    if not types.intersection(allowed):
        raise SystemExit(f"Type inattendu pour {field} : {sorted(types)}")
    for info in entries.values():
        if info.get("aggregatable") is not True:
            raise SystemExit(f"Champ non agrégable : {field}")
print("  OK  @timestamp, http_method, bytes_sent et url_path sont présents et agrégables.")
PY

printf '\nDisponibilité de l’API OpenSearch Dashboards\n'
READY=false
for attempt in $(seq 1 60); do
    if curl -fsS --max-time 10 -H 'osd-xsrf: true' \
        "$DASHBOARDS_URL/api/status" >/dev/null 2>&1; then
        printf '  OK  API Dashboards disponible après %s tentative(s).\n' "$attempt"
        READY=true
        break
    fi
    printf '  tentative %02d/60 : Dashboards pas encore prêt\n' "$attempt"
    sleep 5
done
[[ "$READY" == true ]] || {
    p5_error "OpenSearch Dashboards n'est pas devenu accessible : $DASHBOARDS_URL"
    p5_action 'Vérifiez l’état du domaine, l’IP /32 autorisée et l’endpoint Terraform.'
    exit 1
}

mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BUNDLE_PROOF="$PROOF_DIR/${TIMESTAMP}-dashboards-saved-objects.ndjson"
IMPORT_PROOF="$PROOF_DIR/${TIMESTAMP}-dashboards-import.json"
VERIFY_PROOF="$PROOF_DIR/${TIMESTAMP}-dashboards-verify.json"
cp "$BUNDLE" "$BUNDLE_PROOF"

printf '\nSynchronisation des Saved Objects\n'
curl -fsS -X POST \
    -H 'osd-xsrf: true' \
    -F "file=@$BUNDLE;type=application/x-ndjson" \
    "$DASHBOARDS_URL/api/saved_objects/_import?overwrite=true" \
    > "$IMPORT_RESPONSE"
cp "$IMPORT_RESPONSE" "$IMPORT_PROOF"

jq -e --argjson expected "$EXPECTED_OBJECTS" \
    '.success == true and (.successCount // 0) >= $expected' \
    "$IMPORT_RESPONSE" >/dev/null || {
        p5_error 'OpenSearch Dashboards a refusé un ou plusieurs Saved Objects.'
        jq . "$IMPORT_RESPONSE" >&2
        exit 1
    }
printf '  OK  %s Saved Objects importés/réconciliés.\n' "$EXPECTED_OBJECTS"

printf '\nVérification des objets de présentation\n'
: > "$VERIFY_RESPONSE"
while IFS=$'\t' read -r object_type object_id object_title; do
    response="$TMP_DIR/${object_type}-${object_id}.json"
    curl -fsS -H 'osd-xsrf: true' \
        "$DASHBOARDS_URL/api/saved_objects/$object_type/$object_id" > "$response"
    jq -e --arg type "$object_type" --arg id "$object_id" \
        '.type == $type and .id == $id' "$response" >/dev/null
    jq -c '{type,id,attributes:{title:.attributes.title}}' "$response" >> "$VERIFY_RESPONSE"
    printf '  OK  %-14s %s\n' "$object_type" "$object_title"
done < <(jq -r '[.type,.id,.attributes.title] | @tsv' "$BUNDLE")
cp "$VERIFY_RESPONSE" "$VERIFY_PROOF"

DASHBOARD_ID="$(jq -r '.dashboard.id' "$MANIFEST")"
DIRECT_URL="$DASHBOARDS_URL/app/dashboards#/view/$DASHBOARD_ID"

printf '\nVerdict : OPENSEARCH DASHBOARDS CONVERGÉ ET VÉRIFIÉ\n'
printf 'Dashboard : %s\n' "$DIRECT_URL"
printf 'Preuves   : %s\n' "$PROOF_DIR"
