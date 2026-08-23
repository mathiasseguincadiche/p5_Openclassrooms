#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
MAIN_TF="$ROOT/terraform/exercice-3/main.tf"

fail() {
    printf 'KO  %s\n' "$1" >&2
    exit 1
}

[[ -f "$MAIN_TF" ]] || fail "terraform/exercice-3/main.tf absent"

grep -Fq 'haproxy -c -f /etc/haproxy/haproxy.cfg' "$MAIN_TF" \
    || fail "validation de haproxy.cfg absente du user_data"
grep -Fq 'systemctl enable haproxy' "$MAIN_TF" \
    || fail "activation persistante du service HAProxy absente"
grep -Fq 'systemctl restart haproxy' "$MAIN_TF" \
    || fail "redémarrage explicite de HAProxy absent"
grep -Fq 'systemctl is-active --quiet haproxy' "$MAIN_TF" \
    || fail "contrôle d'état HAProxy absent"
grep -Fq "ss -ltn | grep -Eq '(^|[[:space:]])[^[:space:]]*:80([[:space:]]|$)'" "$MAIN_TF" \
    || fail "contrôle du listener TCP/80 absent"

if grep -Fq 'systemctl enable --now haproxy' "$MAIN_TF"; then
    fail "enable --now ne doit pas remplacer le restart après écriture de haproxy.cfg"
fi

validate_line="$(grep -nF 'haproxy -c -f /etc/haproxy/haproxy.cfg' "$MAIN_TF" | tail -1 | cut -d: -f1)"
restart_line="$(grep -nF 'systemctl restart haproxy' "$MAIN_TF" | tail -1 | cut -d: -f1)"
listener_line="$(grep -nF "ss -ltn | grep -Eq '(^|[[:space:]])[^[:space:]]*:80([[:space:]]|$)'" "$MAIN_TF" | tail -1 | cut -d: -f1)"

((restart_line > validate_line)) \
    || fail "HAProxy doit être redémarré après validation de la configuration"
((listener_line > restart_line)) \
    || fail "le listener TCP/80 doit être contrôlé après le redémarrage"

printf 'OK  HAProxy recharge explicitement la configuration P5 et écoute sur TCP/80.\n'
