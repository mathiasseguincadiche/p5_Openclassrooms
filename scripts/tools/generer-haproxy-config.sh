#!/usr/bin/env bash
# Génère la configuration HAProxy minimale demandée dans l'exercice 3.
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    printf 'Usage : %s <BACKEND_1> <BACKEND_2> [FICHIER_SORTIE]\n' "$0" >&2
    exit 2
fi

backend_1="$1"
backend_2="$2"
output_file="${3:-haproxy.cfg}"

cat > "$output_file" <<EOF_CONFIG
global
    log /dev/log local0
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    timeout connect 5s
    timeout client 50s
    timeout server 50s

frontend http-in
    bind *:80
    default_backend hello-servers

backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 ${backend_1}:80 check inter 3s fall 3 rise 2
    server hello-2 ${backend_2}:80 check inter 3s fall 3 rise 2
EOF_CONFIG

printf 'Configuration créée : %s\n' "$output_file"
printf 'Validez-la sur le serveur avec : haproxy -c -f %s\n' "$output_file"
