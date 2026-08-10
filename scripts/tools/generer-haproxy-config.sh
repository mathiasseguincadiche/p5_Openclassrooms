#!/usr/bin/env bash
# Génère la configuration HAProxy minimale demandée dans l'exercice 3.
set -euo pipefail

show_help() {
    cat <<'HELP'
Usage : generer-haproxy-config.sh <BACKEND_1> <BACKEND_2> [FICHIER_SORTIE]

Informations requises :
  BACKEND_1  adresse IPv4 privée ou nom DNS du premier serveur HTTP
  BACKEND_2  adresse IPv4 privée ou nom DNS du second serveur HTTP

Pourquoi : HAProxy doit savoir vers quelles cibles envoyer le trafic.
Format   : IPv4 (ex. 10.0.1.10) ou nom DNS sans http:// et sans :80.
Exemple  :
  bash scripts/tools/generer-haproxy-config.sh 10.0.1.10 10.0.2.10 haproxy.cfg

Dans le parcours automatisé, ces valeurs sont générées depuis l'infrastructure
Terraform. Ce script est surtout un outil manuel de compréhension/diagnostic.
HELP
}

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
    show_help
    exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
    printf '[INCONNU] adresses des deux backends HAProxy non fournies.\n' >&2
    show_help >&2
    exit 2
fi

valid_backend() {
    [[ "$1" =~ ^([A-Za-z0-9][A-Za-z0-9.-]*|[0-9]{1,3}(\.[0-9]{1,3}){3})$ ]]
}

backend_1="$1"
backend_2="$2"
output_file="${3:-haproxy.cfg}"

for backend in "$backend_1" "$backend_2"; do
    valid_backend "$backend" || {
        printf 'Valeur backend invalide : %s\n' "$backend" >&2
        printf 'Format attendu : IPv4 ou nom DNS, sans schéma ni port. Exemple : 10.0.1.10\n' >&2
        exit 2
    }
done

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
