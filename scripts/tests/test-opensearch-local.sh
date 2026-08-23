#!/usr/bin/env bash
# Lance OpenSearch localement puis teste template, Bulk, mappings, agrégations et Dashboard as Code.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/environment/versions.env"

for command_name in docker curl jq terraform; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done

docker info >/dev/null 2>&1 || {
    printf 'Le moteur Docker est inaccessible.\n' >&2
    exit 1
}

container_name="p5-opensearch-test-${RANDOM}-${RANDOM}"
tmp_dir="$(mktemp -d)"
cleanup() {
    docker rm -f "$container_name" >/dev/null 2>&1 || true
    rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

docker run --rm -d \
    --name "$container_name" \
    --publish 127.0.0.1::9200 \
    --env discovery.type=single-node \
    --env DISABLE_INSTALL_DEMO_CONFIG=true \
    --env DISABLE_SECURITY_PLUGIN=true \
    --env 'OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m' \
    --ulimit nofile=65536:65536 \
    "opensearchproject/opensearch:${OPENSEARCH_DOCKER_VERSION}" >/dev/null

port_mapping="$(docker port "$container_name" 9200/tcp)"
host_port="${port_mapping##*:}"
endpoint="http://127.0.0.1:${host_port}"

ready=false
for _ in {1..90}; do
    if curl -fsS --max-time 3 "$endpoint/_cluster/health" >/dev/null 2>&1; then
        ready=true
        break
    fi
    if [[ "$(docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null || true)" != true ]]; then
        docker logs "$container_name" >&2 || true
        printf 'Le conteneur OpenSearch s’est arrêté prématurément.\n' >&2
        exit 1
    fi
    sleep 2
done
[[ "$ready" == true ]] || {
    docker logs "$container_name" >&2 || true
    printf 'OpenSearch n’est pas devenu disponible dans le délai attendu.\n' >&2
    exit 1
}

proof_dir="$tmp_dir/proofs"
import_data() {
    bash "$PROJECT_ROOT/scripts/commands/import-opensearch-data.sh" \
        --endpoint "$endpoint" \
        --proof-dir "$proof_dir" \
        --apply
}

import_data
count_after_first="$(curl -fsS "$endpoint/nginx-access-*/_count" | jq -r '.count')"
[[ "$count_after_first" == 64 ]] || {
    printf '64 documents attendus après le premier import, %s trouvés.\n' \
        "$count_after_first" >&2
    exit 1
}

import_data
count_after_second="$(curl -fsS "$endpoint/nginx-access-*/_count" | jq -r '.count')"
[[ "$count_after_second" == "$count_after_first" ]] || {
    printf 'Import non idempotent : %s puis %s documents.\n' \
        "$count_after_first" "$count_after_second" >&2
    exit 1
}
printf 'OK  second import sans duplication : %s documents.\n' "$count_after_second"

bash "$PROJECT_ROOT/scripts/commands/verify-opensearch-data.sh" \
    --endpoint "$endpoint" \
    --proof-dir "$proof_dir" \
    --min-documents 64

version="$(curl -fsS "$endpoint/" | jq -r '.version.number')"
[[ "$version" == "$OPENSEARCH_DOCKER_VERSION" ]] || {
    printf 'Version OpenSearch inattendue : %s\n' "$version" >&2
    exit 1
}

printf 'OK  OpenSearch %s exécuté en conteneur éphémère.\n' "$version"

bash "$PROJECT_ROOT/scripts/tests/test-opensearch-dashboard-assets.sh"

printf 'Verdict : TEMPLATE, BULK, MAPPINGS, AGRÉGATIONS, IDÉMPOTENCE ET DASHBOARD AS CODE VALIDÉS.\n'
