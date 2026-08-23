#!/usr/bin/env bash
# Prépare puis converge des logs NGINX dans Amazon OpenSearch.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
INPUT_FILE="$PROJECT_ROOT/terraform/exercice-2/samples/nginx-access.log.sample"
TEMPLATE_FILE="$PROJECT_ROOT/terraform/exercice-2/opensearch/index-template.json"
CONVERTER="$PROJECT_ROOT/scripts/tools/convert-nginx-logs.py"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-2"
ENDPOINT=""
APPLY=false

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "import-opensearch-data"

show_help() {
    cat <<'HELP'
Usage: import-opensearch-data.sh [options]

Options:
  --input CHEMIN      fichier NGINX combined à importer
  --endpoint URL      URL HTTPS AWS ou URL HTTP locale sur localhost
  --proof-dir CHEMIN  dossier local des preuves techniques
  --apply             converger le template et les documents manquants
  -h, --help          afficher cette aide

Sans --apply, le script valide et convertit les données sans contacter OpenSearch.
Avec --apply, l'endpoint est lu depuis Terraform. S'il est indisponible en usage
manuel, le script explique le format autorisé et vous permet de le renseigner.
HELP
}

while (($# > 0)); do
    case "$1" in
        --input)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --input.'; exit 2; }
            INPUT_FILE="$2"
            shift 2
            ;;
        --endpoint)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --endpoint.'; exit 2; }
            ENDPOINT="$2"
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

[[ -f "$INPUT_FILE" ]] || {
    p5_error "Fichier de logs absent : $INPUT_FILE"
    p5_action 'Pour les vrais logs, relancez : bash scripts/commands/p5.sh ex1'
    exit 1
}
[[ -f "$TEMPLATE_FILE" ]] || { p5_error "Template absent : $TEMPLATE_FILE"; exit 1; }
[[ -x "$CONVERTER" || -f "$CONVERTER" ]] || {
    p5_error "Convertisseur absent : $CONVERTER"
    exit 1
}

valid_endpoint() {
    local endpoint="$1"
    [[ "$endpoint" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?$ ]] \
        || [[ "$endpoint" =~ ^http://(127[.]0[.]0[.]1|localhost)(:[0-9]+)?$ ]]
}

normalize_template() {
    jq -S '
      {index_patterns, priority, template, _meta}
      | if .template.settings.number_of_shards != null then
          .template.settings.number_of_shards |= tostring
        else . end
      | if .template.settings.number_of_replicas != null then
          .template.settings.number_of_replicas |= tostring
        else . end
    '
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
BULK_FILE="$TMP_DIR/nginx-access.bulk.ndjson"
IDS_QUERY="$TMP_DIR/ids-query.json"
DESIRED_TEMPLATE="$TMP_DIR/desired-template.json"
REMOTE_TEMPLATE="$TMP_DIR/remote-template.json"

python3 "$CONVERTER" "$INPUT_FILE" --output "$BULK_FILE"
LINE_COUNT="$(wc -l < "$BULK_FILE")"
if ((LINE_COUNT == 0 || LINE_COUNT % 2 != 0)); then
    p5_error "NDJSON Bulk invalide : $LINE_COUNT lignes."
    exit 1
fi
DOCUMENT_COUNT=$((LINE_COUNT / 2))

jq -s '{query:{ids:{values:[.[] | select(.index? != null) | .index._id]}}}' \
    "$BULK_FILE" > "$IDS_QUERY"
normalize_template < "$TEMPLATE_FILE" > "$DESIRED_TEMPLATE"

printf 'Préparation OpenSearch\n'
printf '  Source      : %s\n' "$INPUT_FILE"
printf '  Documents   : %s\n' "$DOCUMENT_COUNT"
printf '  Template    : %s\n' "$TEMPLATE_FILE"

if [[ "$APPLY" != true ]]; then
    printf '\nAucune donnée envoyée. Relancez avec --apply pour converger OpenSearch.\n'
    exit 0
fi

if [[ -z "$ENDPOINT" ]]; then
    ENDPOINT="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-2" \
        output -raw opensearch_endpoint 2>/dev/null || true)"
    if ! valid_endpoint "${ENDPOINT%/}"; then
        p5_unknown 'Endpoint OpenSearch' \
            'la sortie Terraform opensearch_endpoint est absente ou illisible' \
            'Pour le parcours normal, relancez p5.sh ex2. Pour un diagnostic manuel, vous pouvez saisir un endpoint connu.'
        p5_prompt_value ENDPOINT \
            'Endpoint OpenSearch' \
            'Le script doit joindre le domaine dans lequel créer/vérifier le template et les documents.' \
            'https://domaine-opensearch AWS ; HTTP uniquement pour localhost' \
            'https://search-p5-example.us-east-1.es.amazonaws.com' '' valid_endpoint \
            'Saisissez-le ici, ou relancez avec : --endpoint https://votre-endpoint'
    fi
fi
ENDPOINT="${ENDPOINT%/}"
if ! valid_endpoint "$ENDPOINT"; then
    p5_error "Endpoint OpenSearch invalide : $ENDPOINT"
    p5_action 'HTTPS est obligatoire pour AWS ; HTTP est accepté uniquement sur localhost pour les tests.'
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

    printf '\nÉtat du template p5-nginx-access\n'
    TEMPLATE_HTTP="$(curl -sS -o "$REMOTE_TEMPLATE" -w '%{http_code}' \
        "$ENDPOINT/_index_template/p5-nginx-access")"
    TEMPLATE_CHANGED=false
    if [[ "$TEMPLATE_HTTP" == 200 ]] \
        && jq '.index_templates[0].index_template' "$REMOTE_TEMPLATE" \
            | normalize_template > "$TMP_DIR/remote-template-normalized.json" \
        && cmp -s "$DESIRED_TEMPLATE" "$TMP_DIR/remote-template-normalized.json"; then
        cp "$REMOTE_TEMPLATE" "$TEMPLATE_RESPONSE"
        printf '  OK  template déjà conforme — PUT ignoré\n'
    else
        curl -fsS -X PUT \
            -H 'Content-Type: application/json' \
            --data-binary "@$TEMPLATE_FILE" \
            "$ENDPOINT/_index_template/p5-nginx-access" \
            > "$TEMPLATE_RESPONSE"
        jq -e '.acknowledged == true' "$TEMPLATE_RESPONSE" >/dev/null
        TEMPLATE_CHANGED=true
        printf '  CHANGE  template créé ou mis à jour\n'
    fi

    printf '\nÉtat des %s documents déterministes\n' "$DOCUMENT_COUNT"
    curl -fsS -X POST \
        -H 'Content-Type: application/json' \
        --data-binary "@$IDS_QUERY" \
        "$ENDPOINT/nginx-access-*/_count?ignore_unavailable=true&allow_no_indices=true" \
        > "$COUNT_RESPONSE"
    PRESENT_COUNT="$(jq -r '.count // 0' "$COUNT_RESPONSE")"

    if [[ "$PRESENT_COUNT" =~ ^[0-9]+$ ]] && ((PRESENT_COUNT == DOCUMENT_COUNT)); then
        jq -n \
            --argjson expected "$DOCUMENT_COUNT" \
            --argjson present "$PRESENT_COUNT" \
            '{errors:false, skipped:true, reason:"all deterministic document ids already exist", expected:$expected, present:$present}' \
            > "$BULK_RESPONSE"
        printf '  OK  %s/%s documents déjà présents — Bulk ignoré\n' \
            "$PRESENT_COUNT" "$DOCUMENT_COUNT"
    else
        printf '  CHANGE  %s/%s documents présents — convergence Bulk nécessaire\n' \
            "${PRESENT_COUNT:-0}" "$DOCUMENT_COUNT"
        curl -fsS -X POST \
            -H 'Content-Type: application/x-ndjson' \
            --data-binary "@$BULK_FILE" \
            "$ENDPOINT/_bulk?refresh=true" \
            > "$BULK_RESPONSE"
        if ! jq -e '.errors == false' "$BULK_RESPONSE" >/dev/null; then
            jq '[.items[] | select(.index.error != null) | .index.error]' "$BULK_RESPONSE" >&2
            exit 1
        fi
        printf '  OK  aucun document Bulk en erreur\n'
    fi

    curl -fsS "$ENDPOINT/nginx-access-*/_count?ignore_unavailable=true&allow_no_indices=true" \
        > "$COUNT_RESPONSE"
    IMPORTED_COUNT="$(jq -r '.count // 0' "$COUNT_RESPONSE")"
    printf '  OK  documents présents dans nginx-access-* : %s\n' "$IMPORTED_COUNT"

    if [[ "$TEMPLATE_CHANGED" == false ]] && ((PRESENT_COUNT == DOCUMENT_COUNT)); then
        printf '\nVerdict : OPENSEARCH DÉJÀ CONFORME — AUCUNE MUTATION NÉCESSAIRE\n'
    else
        printf '\nVerdict : OPENSEARCH CONVERGÉ\n'
    fi
    printf 'Preuves locales : %s\n' "$PROOF_DIR"
} 2>&1 | tee "$SUMMARY_LOG"
