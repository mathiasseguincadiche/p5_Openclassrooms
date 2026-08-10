#!/usr/bin/env bash
# Observe l'état actuel du P5 sans modifier la VM ni AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
INVENTORY_FILE="$PROJECT_ROOT/ansible/inventories/hosts_aws"

cd "$PROJECT_ROOT"
printf 'P5 — ÉTAT ACTUEL OBSERVÉ (aucune mutation)\n'
printf '%s\n' '============================================================'

printf '\nVM et outils\n'
set +e
bash "$SCRIPT_DIR/bootstrap-ubuntu-server.sh" --check-only
VM_RC=$?
set -e
case "$VM_RC" in
    0) printf '  OK  VM convergée et utilisable dans ce shell.\n' ;;
    90) printf '  --  Outils convergés ; reconnexion du shell requise pour Docker.\n' ;;
    *) printf '  --  VM non convergée ; prepare installera/corrigera uniquement les écarts.\n' ;;
esac

printf '\nConfiguration locale\n'
if [[ -r "$CONFIG_FILE" ]]; then
    printf '  OK  environment/aws-readiness.env présent.\n'
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    set +e
    TFVARS_OUTPUT="$(bash "$SCRIPT_DIR/sync-terraform-tfvars.sh" --config "$CONFIG_FILE" --check 2>&1)"
    TFVARS_RC=$?
    set -e
    if ((TFVARS_RC == 0)); then
        printf '  OK  terraform.tfvars déjà synchronisés.\n'
    else
        printf '  --  terraform.tfvars absents ou différents ; ils seront convergés.\n'
    fi

    PUBLIC_KEY_RAW="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
    PUBLIC_KEY="${PUBLIC_KEY_RAW/#\~/$HOME}"
    PRIVATE_KEY="${P5_SSH_KEY_PATH:-${PUBLIC_KEY%.pub}}"
    PRIVATE_KEY="${PRIVATE_KEY/#\~/$HOME}"
    if [[ -f "$PRIVATE_KEY" && -f "$PUBLIC_KEY" ]]; then
        printf '  OK  paire de clés SSH locale présente.\n'
    else
        printf '  --  paire SSH incomplète ; prepare créera uniquement ce qui manque.\n'
    fi
else
    printf '  --  environment/aws-readiness.env absent ; prepare le créera.\n'
fi

printf '\nAWS\n'
if command -v aws >/dev/null 2>&1 && [[ -r "$CONFIG_FILE" ]]; then
    PROFILE="${AWS_PROFILE:-p5-lab}"
    REGION="${AWS_REGION:-us-east-1}"
    set +e
    IDENTITY="$(aws --profile "$PROFILE" --region "$REGION" --no-cli-pager \
        sts get-caller-identity --output json 2>/dev/null)"
    AWS_RC=$?
    set -e
    if ((AWS_RC == 0)) && [[ -n "$IDENTITY" ]]; then
        ACCOUNT="$(jq -r '.Account // "?"' <<<"$IDENTITY" 2>/dev/null || printf '?')"
        ARN="$(jq -r '.Arn // "?"' <<<"$IDENTITY" 2>/dev/null || printf '?')"
        printf '  OK  session active — compte %s\n' "$ACCOUNT"
        printf '      identité : %s\n' "$ARN"
    else
        printf '  --  aucune session AWS active ; prepare tentera d’abord une réutilisation/renouvellement.\n'
    fi
else
    printf '  --  AWS non inspectable tant que CLI/configuration ne sont pas disponibles.\n'
fi

printf '\nTerraform — état local connu\n'
if command -v terraform >/dev/null 2>&1; then
    for exercise in 1 2 3; do
        module="$PROJECT_ROOT/terraform/exercice-$exercise"
        if [[ ! -f "$module/terraform.tfstate" ]]; then
            printf '  EX%s  aucun état local.\n' "$exercise"
            continue
        fi
        set +e
        RESOURCE_COUNT="$(terraform -chdir="$module" state list 2>/dev/null | sed '/^$/d' | wc -l)"
        STATE_RC=${PIPESTATUS[0]}
        set -e
        if ((STATE_RC == 0)) && [[ "$RESOURCE_COUNT" =~ ^[0-9]+$ ]]; then
            printf '  EX%s  état présent — %s ressource(s) suivie(s).\n' "$exercise" "$RESOURCE_COUNT"
        else
            printf '  EX%s  état présent mais non lisible.\n' "$exercise"
        fi
    done
    printf '  INFO Le prochain `terraform plan` rafraîchira les objets AWS réels et calculera le delta.\n'
else
    printf '  --  Terraform absent : état distant non inspectable depuis cette VM.\n'
fi

printf '\nAnsible / artefact\n'
if [[ -f "$INVENTORY_FILE" ]]; then
    printf '  OK  inventaire Ansible réel présent ; il sera comparé aux outputs Terraform avant écriture.\n'
else
    printf '  --  inventaire réel absent ; il sera généré après l’exercice 1.\n'
fi
if [[ -f "$PROJECT_ROOT/ansible/files/angular-app/index.html" ]] \
    && find "$PROJECT_ROOT/ansible/files/angular-app" -maxdepth 1 -type f -name 'main-*.js' | grep -q .; then
    printf '  OK  artefact Angular présent ; son empreinte sera comparée avant reconstruction.\n'
else
    printf '  --  artefact Angular incomplet ; une reconstruction sera nécessaire.\n'
fi

printf '\nPreuves et logs\n'
if [[ -d "$PROJECT_ROOT/proofs/runtime" ]]; then
    PROOF_FILES="$(find "$PROJECT_ROOT/proofs/runtime" -type f 2>/dev/null | wc -l)"
    printf '  INFO %s fichier(s) de preuve runtime déjà présent(s).\n' "$PROOF_FILES"
else
    printf '  INFO aucune preuve runtime locale pour le moment.\n'
fi
if [[ -d "$PROJECT_ROOT/logs" ]]; then
    LOG_FILES="$(find "$PROJECT_ROOT/logs" -type f -name '*.log' 2>/dev/null | wc -l)"
    printf '  INFO %s journal/journaux opérateur déjà présent(s).\n' "$LOG_FILES"
fi

printf '\nVerdict : ÉTAT OBSERVÉ — aucune installation, création ou destruction effectuée.\n'
