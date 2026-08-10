#!/usr/bin/env bash
# Détruit explicitement les ressources Terraform encore suivies, dans l'ordre sûr.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

command -v terraform >/dev/null 2>&1 || {
    printf 'Terraform est requis pour détruire les ressources.\n' >&2
    exit 1
}

ACTIVE_EXERCISES=()
printf 'Inspection des états Terraform avant destruction\n'
for exercise in 3 2 1; do
    module="terraform/exercice-${exercise}"
    if [[ ! -f "$module/terraform.tfstate" ]]; then
        printf '  EX%s  aucun état local.\n' "$exercise"
        continue
    fi
    mapfile -t resources < <(terraform -chdir="$module" state list 2>/dev/null || true)
    if ((${#resources[@]} == 0)); then
        printf '  EX%s  état déjà vide — aucune destruction nécessaire.\n' "$exercise"
        continue
    fi
    printf '  EX%s  %s ressource(s) encore suivie(s).\n' "$exercise" "${#resources[@]}"
    ACTIVE_EXERCISES+=("$exercise")
done

if ((${#ACTIVE_EXERCISES[@]} == 0)); then
    printf '\nAucune ressource Terraform suivie à détruire.\n'
    printf 'Verdict : DESTRUCTION DÉJÀ CONVERGÉE — lancez seulement l’audit AWS final.\n'
    exit 0
fi

cat <<'WARNING'

ATTENTION : cette commande va détruire uniquement les ressources encore suivies
par Terraform. L'ordre 3 → 2 → 1 protège la dépendance réseau de l'exercice 3.
WARNING
printf 'Tapez exactement DETRUIRE pour continuer : '
read -r confirmation
[[ "$confirmation" == "DETRUIRE" ]] || {
    printf 'Opération annulée.\n'
    exit 0
}

printf '\nDestruction confirmée. Démarrage dans :\n'
for second in 3 2 1; do
    printf '  %s\n' "$second"
    sleep 1
done

for exercise in 3 2 1; do
    module="terraform/exercice-${exercise}"
    if [[ ! -f "$module/terraform.tfstate" ]]; then
        printf '\nExercice %s : aucun état local — ignoré.\n' "$exercise"
        continue
    fi
    mapfile -t resources < <(terraform -chdir="$module" state list 2>/dev/null || true)
    if ((${#resources[@]} == 0)); then
        printf '\nExercice %s : état déjà vide — destroy ignoré.\n' "$exercise"
        continue
    fi

    printf '\nExercice %s : ressources suivies avant destruction\n' "$exercise"
    printf '  %s\n' "${resources[@]}"
    terraform -chdir="$module" destroy -auto-approve

    mapfile -t remaining < <(terraform -chdir="$module" state list 2>/dev/null || true)
    if ((${#remaining[@]} > 0)); then
        printf 'KO  Exercice %s : %s ressource(s) encore suivie(s) après destroy.\n' \
            "$exercise" "${#remaining[@]}" >&2
        exit 1
    fi
    printf 'OK  Exercice %s : état Terraform vide après destruction.\n' "$exercise"
done

cat <<'INFO'

Destruction Terraform convergée.
L'audit AWS global reste obligatoire pour détecter une ressource hors état ou
orpheline. Ne supprimez jamais manuellement un état pour masquer une ressource.
INFO
