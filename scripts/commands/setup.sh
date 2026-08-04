#!/usr/bin/env bash
# Vérifie le lab sans installer de paquet ni créer de ressource AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

show_help() {
    cat <<'HELP'
Usage: ./scripts/commands/setup.sh [--check-only]

Contrôle non destructif de la VM, des outils et de l'arborescence du P5.
Pour installer le socle sur Ubuntu Server 26.04 :
  ./scripts/commands/bootstrap-ubuntu-server.sh
HELP
}

case "${1:-}" in
    ""|--check-only) ;;
    -h|--help) show_help; exit 0 ;;
    *) printf 'Option inconnue : %s\n' "$1" >&2; show_help >&2; exit 2 ;;
esac

missing=0
printf 'Système\n'
if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    printf '  %s\n' "${PRETTY_NAME:-système inconnu}"
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "26.04" ]]; then
        printf '  --  lab de référence : Ubuntu Server 26.04\n'
    fi
else
    printf '  KO  /etc/os-release absent\n'
    missing=$((missing + 1))
fi

printf '\nOutils obligatoires\n'
for command in git python3 terraform ansible-playbook aws curl jq ssh docker node npm shellcheck yamllint; do
    if command -v "$command" >/dev/null 2>&1; then
        printf '  OK  %s\n' "$command"
    else
        printf '  KO  %s absent\n' "$command"
        missing=$((missing + 1))
    fi
done

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        printf '  OK  moteur Docker accessible\n'
    else
        printf '  KO  moteur Docker inaccessible\n'
        missing=$((missing + 1))
    fi
fi

printf '\nStructure du dépôt\n'
required=(
    docs/00-preparation-environnement.md
    docs/04-audit-non-regression.md
    application/README.md
    application/angular/README.md
    scripts/commands/bootstrap-ubuntu-server.sh
    scripts/commands/pre-deployment-check.sh
    scripts/commands/prepare-angular-artifact.sh
    docs/exercices/01-terraform-ansible.md
    docs/exercices/02-elk-opensearch.md
    docs/exercices/03-haproxy.md
    terraform/exercice-1/main.tf
    terraform/exercice-2/main.tf
    terraform/exercice-3/main.tf
    ansible/playbooks/deploy.yml
    ansible/files/nginx-angular.conf
)
for path in "${required[@]}"; do
    if [[ -e "$path" ]]; then
        printf '  OK  %s\n' "$path"
    else
        printf '  KO  %s absent\n' "$path"
        missing=$((missing + 1))
    fi
done

printf '\nServices et identité\n'
if command -v aws >/dev/null 2>&1 && aws sts get-caller-identity >/dev/null 2>&1; then
    printf '  OK  identité AWS active\n'
else
    printf '  --  AWS CLI présente mais identité non vérifiée\n'
fi

"$SCRIPT_DIR/validate.sh"

if (( missing > 0 )); then
    printf '\n%s élément(s) obligatoire(s) manque(nt).\n' "$missing" >&2
    exit 1
fi
printf '\nLab prêt pour le contrôle pré-déploiement.\n'
