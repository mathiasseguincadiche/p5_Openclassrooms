#!/usr/bin/env bash
# Teste le round-robin, la panne et la réintégration HAProxy avec des conteneurs.
set -euo pipefail

# Reproduit volontairement un shell local restrictif. Les fichiers temporaires
# destinés aux conteneurs sont ensuite rendus explicitement lisibles.
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/environment/versions.env"

for command_name in docker curl awk grep sort chmod; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done

docker info >/dev/null 2>&1 || {
    printf 'Le moteur Docker est inaccessible.\n' >&2
    exit 1
}

suffix="${RANDOM}-${RANDOM}"
network="p5-haproxy-test-${suffix}"
backend_1="p5-hello-1-${suffix}"
backend_2="p5-hello-2-${suffix}"
haproxy_container="p5-haproxy-${suffix}"
tmp_dir="$(mktemp -d)"

cleanup() {
    docker rm -f "$haproxy_container" "$backend_1" "$backend_2" \
        >/dev/null 2>&1 || true
    docker network rm "$network" >/dev/null 2>&1 || true
    rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

mkdir -p "$tmp_dir/backend-1" "$tmp_dir/backend-2"
printf 'Server name: p5-hello-1\n' > "$tmp_dir/backend-1/index.html"
printf 'Server name: p5-hello-2\n' > "$tmp_dir/backend-2/index.html"

# Les workers nginx n'utilisent pas l'UID de l'opérateur WSL. Normaliser les
# permissions de cette copie éphémère évite les 403 sous un umask 077.
chmod 0755 "$tmp_dir" "$tmp_dir/backend-1" "$tmp_dir/backend-2"
chmod 0644 "$tmp_dir/backend-1/index.html" "$tmp_dir/backend-2/index.html"

docker network create "$network" >/dev/null
for backend in 1 2; do
    name_variable="backend_${backend}"
    container_name="${!name_variable}"
    docker run -d \
        --name "$container_name" \
        --network "$network" \
        --volume "$tmp_dir/backend-${backend}:/usr/share/nginx/html:ro" \
        "$NGINX_DOCKER_IMAGE" >/dev/null
done

backend_1_ip="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$backend_1")"
backend_2_ip="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$backend_2")"
bash "$PROJECT_ROOT/scripts/tools/generer-haproxy-config.sh" \
    "$backend_1_ip" "$backend_2_ip" "$tmp_dir/haproxy.cfg"
chmod 0644 "$tmp_dir/haproxy.cfg"

docker run --rm \
    --volume "$tmp_dir/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro" \
    "$HAPROXY_DOCKER_IMAGE" \
    haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg >/dev/null

docker run --rm -d \
    --name "$haproxy_container" \
    --network "$network" \
    --publish 127.0.0.1::80 \
    --volume "$tmp_dir/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro" \
    "$HAPROXY_DOCKER_IMAGE" >/dev/null

port_mapping="$(docker port "$haproxy_container" 80/tcp)"
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
    docker logs "$haproxy_container" >&2 || true
    printf 'HAProxy n’est pas devenu disponible.\n' >&2
    exit 1
}

collect_servers() {
    local requests="$1"
    local response server_name
    local -A servers=()

    for ((request_number = 1; request_number <= requests; request_number++)); do
        response="$(curl -fsS --max-time 5 "$base_url/")" || return 1
        server_name="$(awk -F': ' '/^Server name:/ {print $2; exit}' <<< "$response")"
        [[ -n "$server_name" ]] || return 1
        servers["$server_name"]=1
        sleep 0.15
    done
    printf '%s\n' "${!servers[@]}" | sort
}

servers_before="$(collect_servers 10)"
grep -Fxq 'p5-hello-1' <<< "$servers_before"
grep -Fxq 'p5-hello-2' <<< "$servers_before"
printf 'OK  round-robin : deux backends observés.\n'

docker stop "$backend_1" >/dev/null
backend_removed=false
for _ in {1..30}; do
    if servers_during="$(collect_servers 6 2>/dev/null)" \
        && [[ "$servers_during" == p5-hello-2 ]]; then
        backend_removed=true
        break
    fi
    sleep 1
done
[[ "$backend_removed" == true ]] || {
    printf 'HAProxy n’a pas retiré le backend arrêté dans le délai attendu.\n' >&2
    exit 1
}
printf 'OK  panne : service continu uniquement sur p5-hello-2.\n'

docker start "$backend_1" >/dev/null
backend_restored=false
for _ in {1..30}; do
    if servers_after="$(collect_servers 10 2>/dev/null)" \
        && grep -Fxq 'p5-hello-1' <<< "$servers_after" \
        && grep -Fxq 'p5-hello-2' <<< "$servers_after"; then
        backend_restored=true
        break
    fi
    sleep 1
done
[[ "$backend_restored" == true ]] || {
    printf 'HAProxy n’a pas réintégré le backend redémarré.\n' >&2
    exit 1
}
printf 'OK  reprise : les deux backends sont réintégrés.\n'
printf 'Verdict : ROUND-ROBIN, PANNE ET REPRISE HAPROXY VALIDÉS.\n'
