#!/usr/bin/env bash
# Observe l'état actuel du P5 dans la VM Ubuntu DevOps sans modifier la VM ni AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
INVENTORY_FILE="$PROJECT_ROOT/ansible/inventories/hosts_aws"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"
TFVARS_RC=1
AWS_RC=1
SSH_PAIR_READY=0

# shellcheck source=/dev/null
source "$VERSIONS_FILE"

unknown() {
    local label="$1" reason="$2" action="$3"
    printf '  INCONNU  %s\n' "$label"
    printf '           raison : %s\n' "$reason"
    printf '           action : %s\n' "$action"
}

cd "$PROJECT_ROOT"
printf 'P5 — ÉTAT ACTUEL OBSERVÉ DANS LA VM (aucune mutation)\n'
printf '%s\n' '============================================================'
printf '  plateforme attendue : %s\n' "${P5_PLATFORM_REPOSITORY:-mathiasseguincadiche/Ubuntu-desktops-custom}"
printf '  VM attendue         : %s\n' "${P5_EXPECTED_VM_NAME:-ubuntu-devops}"

printf '\nRuntime P5 dans la VM\n'
set +e
bash "$SCRIPT_DIR/bootstrap-ubuntu-server.sh" --check-only
VM_RC=$?
set -e
case "$VM_RC" in
    0) printf '  OK  runtime P5 convergé et utilisable dans ce shell de la VM.\n' ;;
    90) printf '  --  outils convergés ; reconnexion SSH requise pour Docker.\n' ;;
    *) printf '  --  runtime P5 non convergé ; prepare corrigera uniquement les dépendances P5.\n' ;;
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
        printf '  --  terraform.tfvars absents ou différents ; ils seront convergés par prepare.\n'
    fi

    PUBLIC_KEY_RAW="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
    PUBLIC_KEY="${PUBLIC_KEY_RAW/#\~/$HOME}"
    PRIVATE_KEY="${P5_SSH_KEY_PATH:-${PUBLIC_KEY%.pub}}"
    PRIVATE_KEY="${PRIVATE_KEY/#\~/$HOME}"
    if [[ -f "$PRIVATE_KEY" && -f "$PUBLIC_KEY" ]]; then
        SSH_PAIR_READY=1
        printf '  OK  paire de clés SSH locale présente dans la VM.\n'
    else
        unknown 'paire SSH locale' \
            "clé privée/publique incomplète autour de $PRIVATE_KEY" \
            'bash scripts/commands/p5.sh prepare expliquera s’il faut créer une clé ou fournir le chemin d’une clé existante.'
    fi
else
    unknown 'configuration locale AWS' \
        "fichier absent : $CONFIG_FILE" \
        'bash scripts/commands/p5.sh prepare créera le fichier et demandera uniquement les informations non détectables.'
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
        unknown 'identité AWS active' \
            "STS n’est pas lisible avec le profil $PROFILE" \
            'bash scripts/commands/p5.sh prepare tentera de réutiliser/renouveler la session et expliquera le mode de connexion si nécessaire.'
    fi
else
    unknown 'état AWS' \
        'AWS CLI ou configuration locale indisponible' \
        'bash scripts/commands/p5.sh prepare convergera d’abord les prérequis P5 puis l’authentification.'
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
            unknown "état Terraform exercice $exercise" \
                'terraform state list ne peut pas lire l’état local présent' \
                "ne supprimez pas le state ; envoyez le log et relancez terraform -chdir=terraform/exercice-$exercise state list."
        fi
    done
    printf '  INFO Le prochain `terraform plan` rafraîchira les objets AWS réels et calculera le delta.\n'
else
    unknown 'état Terraform' \
        'Terraform est absent du runtime P5 dans la VM' \
        'bash scripts/commands/p5.sh prepare installera/corrigera Terraform si nécessaire.'
fi

printf '\nAnsible / artefact\n'
if [[ -f "$INVENTORY_FILE" ]]; then
    printf '  OK  inventaire Ansible réel présent ; il sera comparé aux outputs Terraform avant écriture.\n'
else
    printf '  --  inventaire réel absent ; il sera généré après l’exercice 1 depuis Terraform.\n'
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

STATE_FILES="$(find "$PROJECT_ROOT/terraform" -maxdepth 2 -type f -name 'terraform.tfstate' 2>/dev/null | wc -l)"
RUNTIME_PROOFS=0
if [[ -d "$PROJECT_ROOT/proofs/runtime" ]]; then
    RUNTIME_PROOFS="$(find "$PROJECT_ROOT/proofs/runtime" -type f 2>/dev/null | wc -l)"
fi
if ((VM_RC == 0 && TFVARS_RC == 0 && AWS_RC == 0 && SSH_PAIR_READY == 1)); then
    CLASSIFICATION='READY_CANDIDATE'
elif ((VM_RC != 0 && STATE_FILES == 0 && RUNTIME_PROOFS == 0)) && [[ ! -r "$CONFIG_FILE" ]]; then
    CLASSIFICATION='FIRST_RUN'
else
    CLASSIFICATION='PARTIAL'
fi
printf '\nClassification : %s\n' "$CLASSIFICATION"
case "$CLASSIFICATION" in
    FIRST_RUN)
        printf '  Première préparation P5 détectée : aucun état P5 persistant exploitable n’a été trouvé.\n'
        printf '  Prochaine action : bash scripts/commands/p5.sh prepare\n'
        ;;
    PARTIAL)
        printf '  État P5 partiel détecté : les éléments déjà conformes seront conservés et seuls les écarts seront convergés.\n'
        printf '  Prochaine action : bash scripts/commands/p5.sh prepare\n'
        ;;
    READY_CANDIDATE)
        printf '  Runtime P5 prêt candidat : outils, configuration, SSH et identité AWS sont actuellement vérifiables.\n'
        printf '  Prochaine action : bash scripts/commands/p5.sh status pour revalider sans mutation.\n'
        ;;
esac
printf '\nVerdict : ÉTAT P5 OBSERVÉ DANS LA VM — aucune mutation, aucune valeur inventée.\n'
