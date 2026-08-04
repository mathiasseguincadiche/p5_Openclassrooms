#!/usr/bin/env bash
# Assistant d'entrée du projet P5.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    cat <<'EOF'
Usage: ./setup-and-run.sh [--check-only] [--auto]

  --check-only  Vérifie l'environnement et le dépôt sans installer ni déployer.
  --auto        Transmet le mode automatique à la phase de préparation.
  --help        Affiche cette aide.

Ce script ne déploie aucune ressource AWS. Le déploiement reste une action
explicite depuis le runbook afin que le coût et le plan Terraform soient relus.
EOF
}

PHASE_ARGS=()
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check-only)
            CHECK_ONLY=true
            PHASE_ARGS+=(--check-only)
            ;;
        --auto)
            PHASE_ARGS+=(--auto)
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
    printf 'Erreur : exécutez ce script avec un utilisateur normal ; sudo sera demandé au besoin.\n' >&2
    exit 1
fi

./scripts/phase-0-preparation.sh "${PHASE_ARGS[@]}"
./scripts/validate.sh

if [ "$CHECK_ONLY" = true ]; then
    printf '\n✅ Environnement et dépôt vérifiés.\n'
    exit 0
fi

printf '\n✅ Préparation terminée. Ouverture du runbook interactif.\n'
exec ./scripts/runbook.sh
