#!/usr/bin/env bash
# Vérifie le compte AWS du P5 sans créer, modifier ni supprimer de ressource.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
STAGE="initial"
ERRORS=0
WARNINGS=0

show_help() {
    cat <<'HELP'
Usage: check-aws-readiness.sh [options]

Options:
  --config CHEMIN       fichier de configuration local
  --stage ETAPE         initial, exercice-2 ou exercice-3
  -h, --help            afficher cette aide

Le contrôle est strictement non destructif.
HELP
}

while (($# > 0)); do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --config.\n' >&2; exit 2; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --stage)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --stage.\n' >&2; exit 2; }
            STAGE="$2"
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

case "$STAGE" in
    initial|exercice-2|exercice-3) ;;
    *) printf 'Étape inconnue : %s\n' "$STAGE" >&2; exit 2 ;;
esac

ok() {
    printf '  OK  %s\n' "$1"
}

warn() {
    printf '  AVERTISSEMENT  %s\n' "$1"
    WARNINGS=$((WARNINGS + 1))
}

ko() {
    printf '  KO  %s\n' "$1" >&2
    ERRORS=$((ERRORS + 1))
}

is_yes() {
    [[ "${1,,}" == "yes" || "${1,,}" == "oui" ]]
}

valid_ipv4_cidr32() {
    python3 - "$1" <<'PY' >/dev/null 2>&1
import ipaddress
import sys

network = ipaddress.ip_network(sys.argv[1], strict=False)
if network.version != 4 or network.prefixlen != 32:
    raise SystemExit(1)
PY
}

aws_cli() {
    aws --profile "$AWS_PROFILE" --region "$AWS_REGION" --no-cli-pager "$@"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    printf 'Configuration absente : %s\n' "$CONFIG_FILE" >&2
    printf 'Copiez environment/aws-readiness.env.example puis complétez-la.\n' >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

required_variables=(
    AWS_PROFILE
    AWS_REGION
    P5_EXPECTED_ACCOUNT_ID
    P5_PUBLIC_IP_CIDR
    P5_EC2_INSTANCE_TYPE
    P5_OPENSEARCH_INSTANCE_TYPE
    P5_OPENSEARCH_ENGINE
    P5_KEY_NAME
    P5_OPENSEARCH_DOMAIN
    P5_REQUIRED_STANDARD_VCPUS
    P5_BUDGET_NAME
    P5_BUDGET_LIMIT_USD
    P5_BUDGET_EMAIL
    P5_REQUIRE_TEMPORARY_CREDENTIALS
    P5_ROOT_MFA_CONFIRMED
    P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED
    P5_IAM_POLICY_ATTACHED_CONFIRMED
    P5_BILLING_CONTACTS_CONFIRMED
)

printf 'Contrôle AWS Ready — étape %s\n\n' "$STAGE"
printf 'Configuration locale\n'
for variable in "${required_variables[@]}"; do
    if [[ -n "${!variable:-}" ]]; then
        ok "$variable"
    else
        ko "$variable absent ou vide"
    fi
done

if [[ "${P5_EXPECTED_ACCOUNT_ID:-}" =~ ^[0-9]{12}$ ]] \
    && [[ "$P5_EXPECTED_ACCOUNT_ID" != "000000000000" ]]; then
    ok "identifiant de compte au format attendu"
else
    ko "P5_EXPECTED_ACCOUNT_ID doit contenir le véritable identifiant à 12 chiffres"
fi

if valid_ipv4_cidr32 "${P5_PUBLIC_IP_CIDR:-invalide}" \
    && [[ "$P5_PUBLIC_IP_CIDR" != "203.0.113.10/32" ]]; then
    ok "adresse d'administration valide en /32"
else
    ko "P5_PUBLIC_IP_CIDR est invalide ou contient encore l'adresse d'exemple"
fi

if [[ "${P5_BUDGET_EMAIL:-}" == *"@"* ]] \
    && [[ "$P5_BUDGET_EMAIL" != "remplacer@example.com" ]]; then
    ok "adresse de notification budgétaire renseignée"
else
    ko "P5_BUDGET_EMAIL doit être remplacée par une adresse réelle"
fi

printf '\nCompte et authentification\n'
if ! command -v aws >/dev/null 2>&1; then
    ko "AWS CLI absente"
else
    if aws configure list-profiles | grep -Fxq "$AWS_PROFILE"; then
        ok "profil $AWS_PROFILE présent"
    else
        ko "profil $AWS_PROFILE absent"
    fi
fi

PROFILE_REGION="$(aws configure get region --profile "$AWS_PROFILE" 2>/dev/null || true)"
if [[ "$PROFILE_REGION" == "$AWS_REGION" ]]; then
    ok "région du profil : $AWS_REGION"
elif [[ -z "$PROFILE_REGION" ]]; then
    ko "aucune région définie dans le profil $AWS_PROFILE"
else
    ko "région du profil ($PROFILE_REGION) différente de $AWS_REGION"
fi

ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text 2>/dev/null || true)"
CALLER_ARN="$(aws_cli sts get-caller-identity --query Arn --output text 2>/dev/null || true)"
if [[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    ok "identité AWS active : $CALLER_ARN"
else
    ko "impossible de lire l'identité AWS ; renouvelez la session du profil"
fi

if [[ -n "$ACCOUNT_ID" && "$ACCOUNT_ID" == "$P5_EXPECTED_ACCOUNT_ID" ]]; then
    ok "compte AWS autorisé : $ACCOUNT_ID"
else
    ko "compte actif différent de P5_EXPECTED_ACCOUNT_ID"
fi

if [[ "$CALLER_ARN" == *":root" ]]; then
    ko "le compte root ne doit pas être utilisé pour le projet"
elif [[ -n "$CALLER_ARN" ]]; then
    ok "identité quotidienne non root"
fi

TEMPORARY_SOURCE=""
for config_key in sso_session sso_start_url role_arn credential_process; do
    config_value="$(aws configure get "$config_key" --profile "$AWS_PROFILE" 2>/dev/null || true)"
    if [[ -n "$config_value" ]]; then
        TEMPORARY_SOURCE="$config_key"
        break
    fi
done
if [[ -z "$TEMPORARY_SOURCE" && -n "${AWS_SESSION_TOKEN:-}" ]]; then
    TEMPORARY_SOURCE="AWS_SESSION_TOKEN"
fi

if [[ -n "$TEMPORARY_SOURCE" ]]; then
    ok "profil basé sur une session temporaire ou un rôle ($TEMPORARY_SOURCE)"
elif is_yes "$P5_REQUIRE_TEMPORARY_CREDENTIALS"; then
    ko "aucune source de session temporaire détectée pour le profil"
else
    warn "profil probablement basé sur une clé d'accès longue durée"
fi

printf '\nConfirmations de sécurité\n'
manual_checks=(
    P5_ROOT_MFA_CONFIRMED
    P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED
    P5_IAM_POLICY_ATTACHED_CONFIRMED
    P5_BILLING_CONTACTS_CONFIRMED
)
for variable in "${manual_checks[@]}"; do
    if is_yes "${!variable:-no}"; then
        ok "$variable"
    else
        ko "$variable doit être confirmé dans la console AWS"
    fi
done

printf '\nRéseau du poste de lab\n'
CURRENT_IP="$(curl -fsS --max-time 10 https://checkip.amazonaws.com 2>/dev/null \
    | tr -d '[:space:]' || true)"
if [[ -n "$CURRENT_IP" && "${CURRENT_IP}/32" == "$P5_PUBLIC_IP_CIDR" ]]; then
    ok "adresse publique actuelle : ${CURRENT_IP}/32"
elif [[ -n "$CURRENT_IP" ]]; then
    ko "adresse publique actuelle ${CURRENT_IP}/32 différente de $P5_PUBLIC_IP_CIDR"
else
    ko "impossible de déterminer l'adresse IPv4 publique actuelle"
fi

printf '\nRégion, EC2 et quotas\n'
AZ_COUNT="$(aws_cli ec2 describe-availability-zones \
    --filters Name=state,Values=available \
    --query 'length(AvailabilityZones)' --output text 2>/dev/null || true)"
if [[ "$AZ_COUNT" =~ ^[0-9]+$ ]] && ((AZ_COUNT >= 2)); then
    ok "$AZ_COUNT zones de disponibilité accessibles"
else
    ko "moins de deux zones disponibles ou permission EC2 insuffisante"
fi

EC2_OFFERING_COUNT="$(aws_cli ec2 describe-instance-type-offerings \
    --location-type region \
    --filters "Name=instance-type,Values=$P5_EC2_INSTANCE_TYPE" \
    --query 'length(InstanceTypeOfferings)' --output text 2>/dev/null || true)"
if [[ "$EC2_OFFERING_COUNT" =~ ^[0-9]+$ ]] && ((EC2_OFFERING_COUNT > 0)); then
    ok "$P5_EC2_INSTANCE_TYPE proposé dans $AWS_REGION"
else
    ko "$P5_EC2_INSTANCE_TYPE indisponible ou non vérifiable dans $AWS_REGION"
fi

UBUNTU_AMI="$(aws_cli ec2 describe-images --owners 099720109477 \
    --filters \
    'Name=name,Values=ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*' \
    'Name=state,Values=available' \
    --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
    --output text 2>/dev/null || true)"
if [[ "$UBUNTU_AMI" =~ ^ami-[a-zA-Z0-9]+$ ]]; then
    ok "AMI Ubuntu Canonical disponible : $UBUNTU_AMI"
else
    ko "AMI Ubuntu 24.04 Canonical introuvable ou non vérifiable"
fi

EC2_QUOTA="$(aws_cli service-quotas get-service-quota \
    --service-code ec2 --quota-code L-1216C47A \
    --query 'Quota.Value' --output text 2>/dev/null || true)"
if [[ "$EC2_QUOTA" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    if awk -v quota="$EC2_QUOTA" -v required="$P5_REQUIRED_STANDARD_VCPUS" \
        'BEGIN { exit !(quota >= required) }'; then
        ok "quota EC2 Standard : $EC2_QUOTA vCPU"
    else
        ko "quota EC2 $EC2_QUOTA vCPU inférieur aux $P5_REQUIRED_STANDARD_VCPUS requis"
    fi
else
    ko "quota EC2 Standard impossible à lire"
fi

printf '\nAmazon OpenSearch\n'
OPENSEARCH_COUNT="$(aws_cli opensearch list-instance-type-details \
    --engine-version "$P5_OPENSEARCH_ENGINE" \
    --instance-type "$P5_OPENSEARCH_INSTANCE_TYPE" \
    --query 'length(InstanceTypeDetails)' --output text 2>/dev/null || true)"
if [[ "$OPENSEARCH_COUNT" =~ ^[0-9]+$ ]] && ((OPENSEARCH_COUNT > 0)); then
    ok "$P5_OPENSEARCH_ENGINE avec $P5_OPENSEARCH_INSTANCE_TYPE disponible"
else
    ko "combinaison OpenSearch non disponible ou permission insuffisante"
fi

if aws_cli opensearch describe-instance-type-limits \
    --engine-version "$P5_OPENSEARCH_ENGINE" \
    --instance-type "$P5_OPENSEARCH_INSTANCE_TYPE" >/dev/null 2>&1; then
    ok "limites OpenSearch accessibles"
else
    ko "limites OpenSearch non accessibles"
fi

printf '\nBudget et coûts\n'
if [[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    BUDGET_COUNT="$(aws --profile "$AWS_PROFILE" --region us-east-1 --no-cli-pager \
        budgets describe-budgets --account-id "$ACCOUNT_ID" \
        --query "length(Budgets[?BudgetName=='$P5_BUDGET_NAME'])" \
        --output text 2>/dev/null || true)"
    if [[ "$BUDGET_COUNT" =~ ^[0-9]+$ ]] && ((BUDGET_COUNT > 0)); then
        ok "budget $P5_BUDGET_NAME présent"
    else
        ko "budget $P5_BUDGET_NAME absent ou non accessible"
    fi
else
    ko "budget non vérifiable sans identifiant de compte"
fi

printf '\nCohérence Terraform\n'
for module in exercice-1 exercice-2 exercice-3; do
    tfvars="$PROJECT_ROOT/terraform/$module/terraform.tfvars"
    if [[ ! -f "$tfvars" ]]; then
        ko "$tfvars absent"
        continue
    fi

    if grep -Eq "aws_region[[:space:]]*=[[:space:]]*\"$AWS_REGION\"" "$tfvars"; then
        ok "$module : région cohérente"
    else
        ko "$module : aws_region différente de $AWS_REGION"
    fi

    if grep -Eq "expected_aws_account_id[[:space:]]*=[[:space:]]*\"$P5_EXPECTED_ACCOUNT_ID\"" "$tfvars"; then
        ok "$module : compte AWS verrouillé"
    else
        ko "$module : expected_aws_account_id absent ou différent"
    fi

    if grep -Eq "your_ip_cidr[[:space:]]*=[[:space:]]*\"$P5_PUBLIC_IP_CIDR\"" "$tfvars"; then
        ok "$module : adresse /32 cohérente"
    else
        ko "$module : your_ip_cidr absente ou différente"
    fi
done

printf '\nÉtat préalable des ressources\n'
VPC_COUNT="$(aws_cli ec2 describe-vpcs \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(Vpcs)' --output text 2>/dev/null || true)"
KEY_EXISTS=no
if aws_cli ec2 describe-key-pairs --key-names "$P5_KEY_NAME" >/dev/null 2>&1; then
    KEY_EXISTS=yes
fi
DOMAIN_EXISTS=no
if aws_cli opensearch describe-domain \
    --domain-name "$P5_OPENSEARCH_DOMAIN" >/dev/null 2>&1; then
    DOMAIN_EXISTS=yes
fi

case "$STAGE" in
    initial)
        [[ "$VPC_COUNT" == "0" ]] && ok "aucun VPC P5 conflictuel" \
            || ko "un VPC P5 existe déjà ; vérifiez l'état Terraform"
        [[ "$KEY_EXISTS" == no ]] && ok "aucune paire EC2 conflictuelle" \
            || ko "la paire $P5_KEY_NAME existe déjà"
        [[ "$DOMAIN_EXISTS" == no ]] && ok "aucun domaine OpenSearch conflictuel" \
            || ko "le domaine $P5_OPENSEARCH_DOMAIN existe déjà"
        ;;
    exercice-2)
        [[ "$DOMAIN_EXISTS" == no ]] && ok "OpenSearch prêt pour l'exercice 2" \
            || ko "le domaine $P5_OPENSEARCH_DOMAIN existe déjà"
        ;;
    exercice-3)
        [[ "$VPC_COUNT" =~ ^[0-9]+$ ]] && ((VPC_COUNT > 0)) \
            && ok "VPC de l'exercice 1 présent" \
            || ko "VPC de l'exercice 1 absent"
        [[ "$KEY_EXISTS" == yes ]] && ok "paire EC2 de l'exercice 1 présente" \
            || ko "paire $P5_KEY_NAME absente"
        ;;
esac

printf '\nSynthèse : %s erreur(s), %s avertissement(s).\n' "$ERRORS" "$WARNINGS"
if ((ERRORS > 0)); then
    printf 'Verdict : STOP AWS — corrigez les points KO avant Terraform.\n' >&2
    exit 1
fi

printf 'Verdict : GO AWS — compte, région, capacité et coûts contrôlés.\n'
