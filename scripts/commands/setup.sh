#!/usr/bin/env bash
# Vérifie l'environnement sans installer de paquet ni créer de ressource.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

show_help() {
    cat <<'HELP'
Usage: ./scripts/commands/setup.sh [--check-only]

Vérifie les outils et la structure du dépôt. Cette commande :
- n'installe aucun paquet ;
- ne lance aucun terraform apply ;
- ne crée aucune ressource AWS.
HELP
}

case "${1:-}" in
    ""|--check-only) ;;
    -h|--help) show_help; exit 0 ;;
    *) printf 'Option inconnue : %s\n' "$1" >&2; show_help >&2; exit 2 ;;
esac

missing=0
printf 'Outils obligatoires\n'
for command in git terraform ansible-playbook aws; do
    if command -v "$command" >/dev/null 2>&1; then
        printf '  OK  %s\n' "$command"
    else
        printf '  KO  %s absent\n' "$command"
        missing=$((missing + 1))
    fi
done

printf '\nOutils utiles selon le mode choisi\n'
for command in docker curl jq; do
    if command -v "$command" >/dev/null 2>&1; then
        printf '  OK  %s\n' "$command"
    else
        printf '  --  %s absent ou non requis pour le mode AWS\n' "$command"
    fi
done

printf '\nStructure du dépôt\n'
required=(
    docs/exercices/01-terraform-ansible.md
    docs/exercices/02-elk-opensearch.md
    docs/exercices/03-haproxy.md
    terraform/exercice-1/main.tf
    terraform/exercice-2/main.tf
    terraform/exercice-3/main.tf
    ansible/playbooks/deploy.yml
)
for path in "${required[@]}"; do
    if [[ -e "$path" ]]; then
        printf '  OK  %s\n' "$path"
    else
        printf '  KO  %s absent\n' "$path"
        missing=$((missing + 1))
    fi
done

if command -v aws >/dev/null 2>&1; then
    if aws sts get-caller-identity >/dev/null 2>&1; then
        printf '\nAWS : identité active.\n'
    else
        printf '\nAWS : CLI présente, mais identité non vérifiée.\n'
    fi
fi

"$SCRIPT_DIR/validate.sh"

if (( missing > 0 )); then
    printf '\n%s élément(s) obligatoire(s) manque(nt).\n' "$missing" >&2
    exit 1
fi
printf '\nEnvironnement prêt pour suivre les fiches du wiki.\n'
