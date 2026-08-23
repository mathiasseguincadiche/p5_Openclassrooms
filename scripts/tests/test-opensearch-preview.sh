#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
IMPORT_SCRIPT="$PROJECT_ROOT/scripts/commands/import-opensearch-data.sh"
OUTPUT="$(mktemp)"
trap 'rm -f "$OUTPUT"' EXIT

set +e
timeout 10 bash "$IMPORT_SCRIPT" >"$OUTPUT" 2>&1
rc=$?
set -e

if ((rc == 124)); then
    printf 'KO  le preview OpenSearch reste bloqué en attente de stdin.\n' >&2
    cat "$OUTPUT" >&2
    exit 1
fi
if ((rc != 0)); then
    printf 'KO  le preview OpenSearch échoue avec le code %s.\n' "$rc" >&2
    cat "$OUTPUT" >&2
    exit "$rc"
fi

grep -Fq 'Documents valides : 64' "$OUTPUT"
grep -Fq 'Préparation OpenSearch' "$OUTPUT"
grep -Fq 'Documents   : 64' "$OUTPUT"
grep -Fq 'Aucune donnée envoyée. Relancez avec --apply pour converger OpenSearch.' "$OUTPUT"

grep -Fq 'normalize_template < "$TEMPLATE_FILE" > "$DESIRED_TEMPLATE"' "$IMPORT_SCRIPT"

printf 'OK  preview OpenSearch local non bloquant et sans mutation.\n'
