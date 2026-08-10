#!/usr/bin/env bash
# Verrouille le contrat opérateur : aucune valeur inconnue ne doit être masquée.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
RUNTIME="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"

fail() {
    printf 'KO  %s\n' "$1" >&2
    exit 1
}

ok() {
    printf 'OK  %s\n' "$1"
}

# shellcheck source=../lib/p5-runtime.sh
source "$RUNTIME"

for function_name in \
    p5_unknown \
    p5_authoritative_unknown \
    p5_prompt_value \
    p5_validate_email \
    p5_validate_ipv4 \
    p5_validate_ipv4_cidr32 \
    p5_validate_http_url \
    p5_validate_existing_file \
    p5_terraform_output; do
    declare -F "$function_name" >/dev/null || fail "fonction commune absente : $function_name"
done
ok 'moteur commun des informations requises présent'

p5_validate_email 'mathias@example.com' || fail 'validation e-mail valide refusée'
! p5_validate_email 'adresse-invalide' || fail 'validation e-mail invalide acceptée'
p5_validate_ipv4 '198.51.100.42' || fail 'IPv4 valide refusée'
! p5_validate_ipv4 '999.1.2.3' || fail 'IPv4 invalide acceptée'
p5_validate_ipv4_cidr32 '198.51.100.42/32' || fail 'CIDR /32 valide refusé'
! p5_validate_ipv4_cidr32 '198.51.100.0/24' || fail 'CIDR non /32 accepté'
p5_validate_http_url 'http://198.51.100.42' || fail 'URL HTTP valide refusée'
ok 'validateurs communs opérationnels'

set +e
PROMPT_OUTPUT="$(p5_prompt_value TEST_VALUE \
    'Valeur de test' \
    'Cette valeur sert à tester le contrat opérateur.' \
    'texte non vide' \
    'exemple-test' \
    '' p5_validate_nonempty \
    'Relancez avec : --test exemple-test' 2>&1)"
PROMPT_RC=$?
set -e
((PROMPT_RC != 0)) || fail 'une saisie interactive a été simulée à tort en CI'
grep -Fq 'INFORMATION REQUISE — Valeur de test' <<<"$PROMPT_OUTPUT" || fail 'titre de saisie absent'
grep -Fq 'Format attendu : texte non vide' <<<"$PROMPT_OUTPUT" || fail 'format attendu absent'
grep -Fq 'Exemple        : exemple-test' <<<"$PROMPT_OUTPUT" || fail 'exemple absent'
grep -Fq 'Transmission   : Relancez avec : --test exemple-test' <<<"$PROMPT_OUTPUT" || fail 'mode de transmission absent'
grep -Fq '[INCONNU] Valeur de test' <<<"$PROMPT_OUTPUT" || fail 'état INCONNU absent en non-interactif'
ok 'saisie non interactive = inconnue + format + exemple + action'

CONFIGURE="$PROJECT_ROOT/scripts/commands/configure-lab.sh"
for marker in \
    '--public-ip' \
    '--ssh-key' \
    'p5_prompt_value CURRENT_IP' \
    'p5_prompt_value BUDGET_EMAIL' \
    'p5_prompt_value PRIVATE_KEY' \
    'p5_authoritative_unknown' \
    'P5_SSH_KEY_PATH='; do
    grep -Fq -- "$marker" "$CONFIGURE" || fail "configure-lab ne respecte pas le contrat : $marker"
done
ok 'configure-lab collecte les valeurs opérateur manquantes'

# Les cibles de test acceptent un override explicite et expliquent le fallback.
declare -A module_markers=(
    [verify-angular-deployment.sh]='--url'
    [generate-nginx-traffic.sh]='--url'
    [collect-nginx-access-log.sh]='--host'
    [import-opensearch-data.sh]='--endpoint'
    [verify-opensearch-data.sh]='--endpoint'
    [test-haproxy-roundrobin.sh]='--url'
    [test-haproxy-failover.sh]='--backend-host'
    [generate-ansible-inventory.sh]='--ssh-key'
)
for script_name in "${!module_markers[@]}"; do
    path="$PROJECT_ROOT/scripts/commands/$script_name"
    marker="${module_markers[$script_name]}"
    grep -Fq -- "$marker" "$path" || fail "$script_name : override $marker absent"
    grep -Fq 'p5_' "$path" || fail "$script_name : moteur commun non utilisé"
done
ok 'Angular, NGINX, OpenSearch, HAProxy et Ansible utilisent le contrat opérateur'

grep -Fq 'p5_terraform_output WEB_IP' \
    "$PROJECT_ROOT/scripts/commands/generate-ansible-inventory.sh" \
    || fail 'inventaire Ansible : output Terraform non protégé'
ok 'valeur d’infrastructure authoritative non inventée dans Ansible'

# Les commandes d'observation restent non mutantes : elles signalent, prepare collecte.
grep -Fq 'aucune mutation' "$PROJECT_ROOT/scripts/commands/inspect-state.sh" \
    || fail 'inspect-state ne documente plus son caractère non mutant'
grep -Fq 'configure-lab.sh' "$PROJECT_ROOT/scripts/commands/p5.sh" \
    || fail 'p5.sh ne passe plus par la collecte centralisée du lab'
ok 'observation séparée de la collecte interactive'

printf '\nVerdict : CONTRAT DES INFORMATIONS REQUISES VALIDÉ.\n'
