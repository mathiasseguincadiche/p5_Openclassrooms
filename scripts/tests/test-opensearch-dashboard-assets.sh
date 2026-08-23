#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
SERVER_PID=""
cleanup() {
    if [[ -n "$SERVER_PID" ]]; then
        kill "$SERVER_PID" >/dev/null 2>&1 || true
        wait "$SERVER_PID" >/dev/null 2>&1 || true
    fi
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

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

cat > "$TMP_DIR/mock_dashboards_api.py" <<'PY'
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

PORT_FILE = sys.argv[1]
TITLES = {
    ("index-pattern", "p5-nginx-access"): "nginx-access-*",
    ("visualization", "p5-nginx-http-methods"): "P5 — Répartition des méthodes HTTP",
    ("visualization", "p5-nginx-bytes-12h"): "P5 — Octets envoyés par tranche de 12 h",
    ("visualization", "p5-nginx-top5-url-12h"): "P5 — Top 5 des URL par tranche de 12 h",
    ("dashboard", "p5-nginx-observability"): "P5 — Observabilité NGINX",
}

class Handler(BaseHTTPRequestHandler):
    def send_json(self, payload, status=200):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = unquote(urlparse(self.path).path)
        if path.endswith("/_field_caps"):
            self.send_json({
                "fields": {
                    "@timestamp": {"date": {"aggregatable": True, "searchable": True}},
                    "http_method": {"keyword": {"aggregatable": True, "searchable": True}},
                    "bytes_sent": {"long": {"aggregatable": True, "searchable": True}},
                    "url_path": {"keyword": {"aggregatable": True, "searchable": True}},
                }
            })
            return
        if path == "/api/status":
            self.send_json({"status": {"overall": {"state": "green"}}})
            return
        prefix = "/api/saved_objects/"
        if path.startswith(prefix):
            rest = path[len(prefix):]
            object_type, object_id = rest.split("/", 1)
            title = TITLES.get((object_type, object_id))
            if title is None:
                self.send_json({"error": "not found"}, 404)
                return
            self.send_json({"type": object_type, "id": object_id, "attributes": {"title": title}})
            return
        self.send_json({"error": "unexpected GET", "path": path}, 404)

    def do_POST(self):
        path = unquote(urlparse(self.path).path)
        length = int(self.headers.get("Content-Length", "0"))
        if length:
            self.rfile.read(length)
        if path == "/api/saved_objects/_import":
            if self.headers.get("osd-xsrf") != "true":
                self.send_json({"success": False, "error": "missing xsrf"}, 400)
                return
            self.send_json({"success": True, "successCount": 5, "successResults": []})
            return
        self.send_json({"error": "unexpected POST", "path": path}, 404)

    def log_message(self, *_args):
        pass

server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
with open(PORT_FILE, "w", encoding="utf-8") as stream:
    stream.write(str(server.server_address[1]))
server.serve_forever()
PY

PORT_FILE="$TMP_DIR/mock-port"
python3 "$TMP_DIR/mock_dashboards_api.py" "$PORT_FILE" &
SERVER_PID=$!
for _ in $(seq 1 50); do
    [[ -s "$PORT_FILE" ]] && break
    sleep 0.1
done
[[ -s "$PORT_FILE" ]]
PORT="$(cat "$PORT_FILE")"
MOCK_URL="http://127.0.0.1:$PORT"
PROOF_DIR="$TMP_DIR/proofs"
SYNC_OUTPUT="$TMP_DIR/sync-output.log"

P5_LOG_DIR="$TMP_DIR/p5-logs" \
P5_STABLE_LOG_ROOT="$TMP_DIR/stable-logs" \
P5_STEP_PROOF_DIR="$TMP_DIR/step-proofs" \
bash "$SYNC_SCRIPT" \
    --endpoint "$MOCK_URL" \
    --dashboards-url "$MOCK_URL" \
    --proof-dir "$PROOF_DIR" \
    --apply > "$SYNC_OUTPUT"

grep -Fq 'OK  5 Saved Objects importés/réconciliés.' "$SYNC_OUTPUT"
grep -Fq 'OPENSEARCH DASHBOARDS CONVERGÉ ET VÉRIFIÉ' "$SYNC_OUTPUT"
grep -Fq "$MOCK_URL/app/dashboards#/view/p5-nginx-observability" "$SYNC_OUTPUT"
[[ "$(find "$PROOF_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')" -eq 3 ]]

printf 'OK — contrat Dashboard as Code OpenSearch et cycle API simulé validés.\n'
