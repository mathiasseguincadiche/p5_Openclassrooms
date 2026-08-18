#!/usr/bin/env bash
# Crée une copie locale confidentielle du state Terraform avant/après mutation.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${P5_PROJECT_ROOT:-$(cd -- "$SCRIPT_DIR/../.." && pwd)}"
BACKUP_ROOT="${P5_TERRAFORM_STATE_BACKUP_DIR:-$PROJECT_ROOT/.p5/terraform-state-backups}"
EXERCISE=""
LABEL="manual"

show_help() {
    cat <<'HELP'
Usage: snapshot-terraform-state.sh [options]

Options:
  --exercise 1|2|3  limiter la sauvegarde à un exercice
  --label NOM       étiquette sûre ajoutée au nom de la sauvegarde
  -h, --help        afficher cette aide

Sans --exercise, les trois states présents sont sauvegardés. Les copies restent
locales sous .p5/, avec des permissions 0600, et ne sont jamais versionnées.
Chaque capture reçoit un identifiant temporel unique afin qu'une réexécution dans
le même run ne puisse jamais écraser une sauvegarde précédente.
HELP
}

while (($# > 0)); do
    case "$1" in
        --exercise)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --exercise.\n' >&2; exit 2; }
            EXERCISE="$2"
            shift 2
            ;;
        --label)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --label.\n' >&2; exit 2; }
            LABEL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            printf 'Option inconnue : %s\n' "$1" >&2
            show_help >&2
            exit 2
            ;;
    esac
done

[[ -z "$EXERCISE" || "$EXERCISE" =~ ^[123]$ ]] || {
    printf -- '--exercise doit valoir 1, 2 ou 3.\n' >&2
    exit 2
}
[[ "$LABEL" =~ ^[A-Za-z0-9._-]+$ ]] || {
    printf -- '--label accepte uniquement lettres, chiffres, point, tiret et underscore.\n' >&2
    exit 2
}
command -v terraform >/dev/null 2>&1 || {
    printf 'Terraform est requis pour sauvegarder le state.\n' >&2
    exit 1
}

if [[ -n "$EXERCISE" ]]; then
    exercises=("$EXERCISE")
else
    exercises=(1 2 3)
fi

snapshot_id="${P5_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$}"
destination="$BACKUP_ROOT/$snapshot_id"
manifest="$destination/manifest.tsv"
captured=0

umask 077
mkdir -p "$destination"
chmod 700 "$BACKUP_ROOT" "$destination"
if [[ ! -f "$manifest" ]]; then
    printf 'utc\texercise\tlabel\tsha256\tstate_file\n' > "$manifest"
    chmod 600 "$manifest"
fi

for exercise in "${exercises[@]}"; do
    module_dir="$PROJECT_ROOT/terraform/exercice-$exercise"
    state_file="$module_dir/terraform.tfstate"
    if [[ ! -s "$state_file" ]]; then
        printf 'SKIP  exercice %s : aucun state local présent.\n' "$exercise"
        continue
    fi

    capture_id="$(date -u +%Y%m%dT%H%M%S%N)-$$-$RANDOM"
    backup_file="$destination/exercice-${exercise}-${LABEL}-${capture_id}.tfstate"
    temporary_file="$(mktemp "$destination/.exercice-${exercise}-${LABEL}.XXXXXX")"
    if ! terraform -chdir="$module_dir" state pull > "$temporary_file"; then
        rm -f "$temporary_file"
        printf 'KO  exercice %s : lecture du state impossible.\n' "$exercise" >&2
        exit 1
    fi
    if [[ ! -s "$temporary_file" ]]; then
        rm -f "$temporary_file"
        printf 'KO  exercice %s : Terraform a retourné un state vide.\n' "$exercise" >&2
        exit 1
    fi

    chmod 600 "$temporary_file"
    mv -- "$temporary_file" "$backup_file"
    sha="$(sha256sum "$backup_file" | awk '{print $1}')"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u --iso-8601=seconds)" "$exercise" "$LABEL" "$sha" \
        "$(basename -- "$backup_file")" >> "$manifest"
    printf 'OK  exercice %s : state sauvegardé localement (%s, sha256=%s).\n' \
        "$exercise" "$backup_file" "$sha"
    captured=$((captured + 1))
done

if ((captured == 0)); then
    printf 'Aucun state Terraform présent : aucune sauvegarde nécessaire.\n'
else
    printf 'Sauvegardes locales : %s\n' "$destination"
    printf 'Attention : ces fichiers peuvent contenir des données sensibles.\n'
fi
