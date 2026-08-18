#!/usr/bin/env bash
# Rend la configuration HAProxy canonique de l'exercice 3 avec deux backends.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_FILE="$PROJECT_ROOT/terraform/exercice-3/haproxy.cfg.tpl"

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

Le fichier terraform/exercice-3/haproxy.cfg.tpl est la source canonique commune
au déploiement Terraform et aux tests locaux. Ce script ne duplique pas la
configuration HAProxy : il remplace uniquement les deux cibles.
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

[[ -f "$TEMPLATE_FILE" ]] || {
    printf 'Template HAProxy canonique absent : %s\n' "$TEMPLATE_FILE" >&2
    exit 1
}

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

sed \
    -e "s|@@BACKEND_1@@|$backend_1|g" \
    -e "s|@@BACKEND_2@@|$backend_2|g" \
    "$TEMPLATE_FILE" > "$output_file"

if grep -q '@@BACKEND_[12]@@' "$output_file"; then
    printf 'Le rendu HAProxy contient encore un placeholder non résolu.\n' >&2
    exit 1
fi

printf 'Configuration créée depuis le template canonique : %s\n' "$output_file"
printf 'Validez-la sur le serveur avec : haproxy -c -f %s\n' "$output_file"
