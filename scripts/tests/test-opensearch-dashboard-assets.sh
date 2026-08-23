#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MANIFEST="$PROJECT_ROOT/terraform/exercice-2/opensearch/dashboards/p5-dashboard.json"
INDEX_TEMPLATE="$PROJECT_ROOT/terraform/exercice-2/opensearch/index-template.json"
BUILDER="$PROJECT_ROOT/scripts/tools/build-opensearch-saved-objects.py"
SYNC_SCRIPT="$PROJECT_ROOT/scripts/commands/sync-opensearch-dashboards.sh"
OUTPUT="$TMP_DIR/p5-dashboard.ndjson"

python3 -m json.tool "$MANIFEST" >/dev/null
python3 -m py_compile "$BUILDER"
python3 "$BUILDER" \
    --manifest "$MANIFEST" \
    --index-template "$INDEX_TEMPLATE" \
    --output "$OUTPUT" >/dev/null

[[ "$(wc -l < "$OUTPUT" | tr -d ' ')" == 5 ]]

python3 - "$OUTPUT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    objects = [json.loads(line) for line in stream if line.strip()]
by_id = {obj["id"]: obj for obj in objects}
expected = {
    "p5-nginx-access",
    "p5-nginx-http-methods",
    "p5-nginx-bytes-12h",
    "p5-nginx-top5-url-12h",
    "p5-nginx-observability",
}
assert set(by_id) == expected

index_pattern = by_id["p5-nginx-access"]
assert index_pattern["type"] == "index-pattern"
assert index_pattern["attributes"]["title"] == "nginx-access-*"
assert index_pattern["attributes"]["timeFieldName"] == "@timestamp"

donut = json.loads(by_id["p5-nginx-http-methods"]["attributes"]["visState"])
assert donut["type"] == "pie"
assert donut["params"]["isDonut"] is True
donut_terms = next(agg for agg in donut["aggs"] if agg["type"] == "terms")
assert donut_terms["params"]["field"] == "http_method"

bytes_vis = json.loads(by_id["p5-nginx-bytes-12h"]["attributes"]["visState"])
bytes_sum = next(agg for agg in bytes_vis["aggs"] if agg["type"] == "sum")
bytes_date = next(agg for agg in bytes_vis["aggs"] if agg["type"] == "date_histogram")
assert bytes_sum["params"]["field"] == "bytes_sent"
assert bytes_date["params"]["field"] == "@timestamp"
assert bytes_date["params"]["interval"] == "12h"

top = json.loads(by_id["p5-nginx-top5-url-12h"]["attributes"]["visState"])
top_terms = next(agg for agg in top["aggs"] if agg["type"] == "terms")
top_date = next(agg for agg in top["aggs"] if agg["type"] == "date_histogram")
assert top_terms["params"]["field"] == "url_path"
assert top_terms["params"]["size"] == 5
assert top_date["params"]["interval"] == "12h"

dashboard = by_id["p5-nginx-observability"]
assert dashboard["type"] == "dashboard"
assert dashboard["attributes"]["timeRestore"] is True
panels = json.loads(dashboard["attributes"]["panelsJSON"])
assert len(panels) == 3
assert len(dashboard["references"]) == 3
assert {reference["id"] for reference in dashboard["references"]} == {
    "p5-nginx-http-methods",
    "p5-nginx-bytes-12h",
    "p5-nginx-top5-url-12h",
}
PY

bash -n "$SYNC_SCRIPT"
grep -Fq 'osd-xsrf: true' "$SYNC_SCRIPT"
grep -Fq '/api/saved_objects/_import?overwrite=true' "$SYNC_SCRIPT"
grep -Fq 'OPENSEARCH DASHBOARDS CONVERGÉ ET VÉRIFIÉ' "$SYNC_SCRIPT"

printf 'OK — contrat Dashboard as Code OpenSearch validé.\n'
