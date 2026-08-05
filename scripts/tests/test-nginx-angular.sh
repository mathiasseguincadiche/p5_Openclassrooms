#!/usr/bin/env bash
# Teste réellement le build Angular derrière la configuration NGINX du projet.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/environment/versions.env"

for command_name in docker curl grep find; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done

docker info >/dev/null 2>&1 || {
    printf 'Le moteur Docker est inaccessible.\n' >&2
    exit 1
}

mapfile -t build_indexes < <(
    find "$PROJECT_ROOT/application/angular/dist" -type f -name index.html | sort
)
[[ "${#build_indexes[@]}" -eq 1 ]] || {
    printf 'Un unique build Angular est attendu dans application/angular/dist.\n' >&2
    exit 1
}
build_dir="$(dirname -- "${build_indexes[0]}")"
container_name="p5-nginx-angular-test-${RANDOM}-${RANDOM}"
tmp_dir="$(mktemp -d)"

cleanup() {
    docker rm -f "$container_name" >/dev/null 2>&1 || true
    rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

docker run --rm -d \
    --name "$container_name" \
    --publish 127.0.0.1::80 \
    --volume "$build_dir:/var/www/p5:ro" \
    --volume "$PROJECT_ROOT/ansible/files/nginx-angular.conf:/etc/nginx/conf.d/default.conf:ro" \
    "$NGINX_DOCKER_IMAGE" >/dev/null

port_mapping="$(docker port "$container_name" 80/tcp)"
host_port="${port_mapping##*:}"
base_url="http://127.0.0.1:${host_port}"

ready=false
for _ in {1..30}; do
    if curl -fsS --max-time 2 "$base_url/" >/dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 1
done
[[ "$ready" == true ]] || {
    docker logs "$container_name" >&2 || true
    printf 'NGINX n’est pas devenu disponible.\n' >&2
    exit 1
}

curl -fsS -D "$tmp_dir/index.headers" -o "$tmp_dir/index.html" "$base_url/"
grep -q '<app-root' "$tmp_dir/index.html"
grep -q 'P5 — Infrastructure as Code' "$tmp_dir/index.html"
grep -qi '^X-Content-Type-Options: nosniff' "$tmp_dir/index.headers"
grep -qi '^X-Frame-Options: SAMEORIGIN' "$tmp_dir/index.headers"
grep -qi '^Referrer-Policy: strict-origin-when-cross-origin' "$tmp_dir/index.headers"

main_bundle="$(grep -oE 'src="[^"]*main[^"]*[.]js"' "$tmp_dir/index.html" \
    | head -n 1 | cut -d '"' -f 2)"
[[ -n "$main_bundle" ]] || {
    printf 'Bundle Angular principal introuvable.\n' >&2
    exit 1
}
curl -fsS -D "$tmp_dir/bundle.headers" -o /dev/null \
    "$base_url/${main_bundle#/}"
grep -qi '^Cache-Control: public, immutable' "$tmp_dir/bundle.headers"
grep -qi '^X-Content-Type-Options: nosniff' "$tmp_dir/bundle.headers"
grep -qi '^X-Frame-Options: SAMEORIGIN' "$tmp_dir/bundle.headers"
grep -qi '^Referrer-Policy: strict-origin-when-cross-origin' "$tmp_dir/bundle.headers"

curl -fsS -o "$tmp_dir/fallback.html" "$base_url/parcours-p5"
grep -q '<app-root' "$tmp_dir/fallback.html"
cmp -s "$tmp_dir/index.html" "$tmp_dir/fallback.html"

printf 'OK  page Angular servie par NGINX.\n'
printf 'OK  bundle principal accessible avec cache et en-têtes de sécurité.\n'
printf 'OK  fallback SPA opérationnel.\n'
printf 'Verdict : INTÉGRATION ANGULAR + NGINX VALIDÉE.\n'
