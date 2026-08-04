#!/usr/bin/env bash
# Assistant d'entrée du projet P5.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

show_help() {
    cat <<'HELP'
Usage: ./scripts/commands/setup.sh [--check-only] [--auto]

  --check-only  Vérifie l'environnement et le dépôt sans déployer.
  --auto        Transmet le mode automatique à la phase de préparation.
  --help        Affiche cette aide.

Ce script ne crée aucune ressource AWS. Le déploiement reste une action
explicite depuis le runbook afin que le coût et le plan soient relus.
HELP
}

phase_args=()
check_only=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check-only)
            check_only=true
            phase_args+=(--check-only)
            ;;
        --auto)
            phase_args+=(--auto)
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            printf 'Option inconnue : %s\n' "$1" >&2
            show_help >&2
            exit 1
            ;;
    esac
    shift
done

if [ "$(id -u)" -eq 0 ]; then
    printf 'Exécutez ce script avec un utilisateur normal ; sudo sera demandé au besoin.\n' >&2
    exit 1
fi

./scripts/phases/phase-0-preparation.sh "${phase_args[@]}"
./scripts/commands/validate.sh

if [ "$check_only" = true ]; then
    printf '\n✅ Environnement et dépôt vérifiés.\n'
    exit 0
fi

printf '\n✅ Préparation terminée. Ouverture du runbook interactif.\n'
exec ./scripts/runbook.sh
