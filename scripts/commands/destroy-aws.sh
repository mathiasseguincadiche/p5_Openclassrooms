#!/usr/bin/env bash
# Détruit explicitement les ressources Terraform du P5 dans l'ordre sûr.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

command -v terraform >/dev/null 2>&1 || {
    printf 'Terraform est requis pour détruire les ressources.\n' >&2
    exit 1
}

cat <<'WARNING'
ATTENTION : cette commande détruit les ressources AWS suivies par les états
Terraform locaux des exercices 3, 2 puis 1.

L'ordre est volontaire : l'exercice 3 dépend du réseau créé par l'exercice 1.
WARNING
printf 'Tapez exactement DETRUIRE pour continuer : '
read -r confirmation
[[ "$confirmation" == "DETRUIRE" ]] || {
    printf 'Opération annulée.\n'
    exit 0
}

for exercise in 3 2 1; do
    module="terraform/exercice-${exercise}"
    if [[ ! -f "$module/terraform.tfstate" ]]; then
        printf '\nExercice %s : aucun état local, vérification manuelle requise.\n' "$exercise"
        continue
    fi

    printf '\nExercice %s : ressources suivies\n' "$exercise"
    terraform -chdir="$module" state list || true
    printf 'Destruction de l’exercice %s...\n' "$exercise"
    terraform -chdir="$module" destroy -auto-approve

done

cat <<'INFO'

Destruction Terraform terminée.
Vérifiez néanmoins dans la console AWS qu'aucune instance EC2 ni aucun domaine
OpenSearch du projet ne subsiste. Ne supprimez pas manuellement les états avant
cette vérification.
INFO
