#!/usr/bin/env bash
# Recherche les ressources P5 restantes après terraform destroy.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
ERRORS=0
LEFTOVERS=0

show_help() {
    cat <<'HELP'
Usage: check-aws-cleanup.sh [--config CHEMIN]

Contrôle non destructif des ressources AWS du projet portant le tag
Project=p5-openclassrooms ou les noms réservés du lab.
HELP
}

while (($# > 0)); do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --config.\n' >&2; exit 2; }
            CONFIG_FILE="$2"
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

ok() {
    printf '  OK  %s\n' "$1"
}

ko() {
    printf '  KO  %s\n' "$1" >&2
    ERRORS=$((ERRORS + 1))
}

report_count() {
    local label="$1"
    local count="$2"

    if [[ ! "$count" =~ ^[0-9]+$ ]]; then
        ko "$label : contrôle impossible"
    elif ((count == 0)); then
        ok "$label : 0"
    else
        printf '  RESTE  %s : %s\n' "$label" "$count" >&2
        LEFTOVERS=$((LEFTOVERS + count))
    fi
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    printf 'Configuration absente : %s\n' "$CONFIG_FILE" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

required=(AWS_PROFILE AWS_REGION P5_EXPECTED_ACCOUNT_ID P5_KEY_NAME P5_OPENSEARCH_DOMAIN)
for variable in "${required[@]}"; do
    [[ -n "${!variable:-}" ]] || {
        printf '%s est absent ou vide dans %s.\n' "$variable" "$CONFIG_FILE" >&2
        exit 1
    }
done

aws_cli() {
    aws --profile "$AWS_PROFILE" --region "$AWS_REGION" --no-cli-pager "$@"
}

ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text 2>/dev/null || true)"
if [[ "$ACCOUNT_ID" != "$P5_EXPECTED_ACCOUNT_ID" ]]; then
    printf 'Compte actif %s différent du compte autorisé %s.\n' \
        "${ACCOUNT_ID:-inconnu}" "$P5_EXPECTED_ACCOUNT_ID" >&2
    exit 1
fi

printf 'Contrôle du nettoyage AWS — compte %s, région %s\n\n' \
    "$ACCOUNT_ID" "$AWS_REGION"

INSTANCE_COUNT="$(aws_cli ec2 describe-instances \
    --filters \
    Name=tag:Project,Values=p5-openclassrooms \
    Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped \
    --query 'length(Reservations[].Instances[])' --output text 2>/dev/null || true)"
report_count "instances EC2" "$INSTANCE_COUNT"

VOLUME_COUNT="$(aws_cli ec2 describe-volumes \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(Volumes)' --output text 2>/dev/null || true)"
report_count "volumes EBS" "$VOLUME_COUNT"

ENI_COUNT="$(aws_cli ec2 describe-network-interfaces \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(NetworkInterfaces)' --output text 2>/dev/null || true)"
report_count "interfaces réseau" "$ENI_COUNT"

EIP_COUNT="$(aws_cli ec2 describe-addresses \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(Addresses)' --output text 2>/dev/null || true)"
report_count "adresses Elastic IP" "$EIP_COUNT"

SG_COUNT="$(aws_cli ec2 describe-security-groups \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(SecurityGroups)' --output text 2>/dev/null || true)"
report_count "groupes de sécurité" "$SG_COUNT"

SUBNET_COUNT="$(aws_cli ec2 describe-subnets \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(Subnets)' --output text 2>/dev/null || true)"
report_count "sous-réseaux" "$SUBNET_COUNT"

ROUTE_TABLE_COUNT="$(aws_cli ec2 describe-route-tables \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(RouteTables)' --output text 2>/dev/null || true)"
report_count "tables de routage" "$ROUTE_TABLE_COUNT"

IGW_COUNT="$(aws_cli ec2 describe-internet-gateways \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(InternetGateways)' --output text 2>/dev/null || true)"
report_count "passerelles Internet" "$IGW_COUNT"

VPC_COUNT="$(aws_cli ec2 describe-vpcs \
    --filters Name=tag:Project,Values=p5-openclassrooms \
    --query 'length(Vpcs)' --output text 2>/dev/null || true)"
report_count "VPC" "$VPC_COUNT"

KEY_COUNT="$(aws_cli ec2 describe-key-pairs \
    --filters "Name=key-name,Values=$P5_KEY_NAME" \
    --query 'length(KeyPairs)' --output text 2>/dev/null || true)"
report_count "paires de clés EC2 $P5_KEY_NAME" "$KEY_COUNT"

DOMAIN_COUNT="$(aws_cli opensearch list-domain-names \
    --query "length(DomainNames[?DomainName=='$P5_OPENSEARCH_DOMAIN'])" \
    --output text 2>/dev/null || true)"
report_count "domaines OpenSearch $P5_OPENSEARCH_DOMAIN" "$DOMAIN_COUNT"

printf '\nSynthèse : %s ressource(s) restante(s), %s contrôle(s) en erreur.\n' \
    "$LEFTOVERS" "$ERRORS"
if ((LEFTOVERS > 0 || ERRORS > 0)); then
    printf 'Verdict : NETTOYAGE INCOMPLET — ne supprimez pas les états Terraform.\n' >&2
    exit 1
fi

printf 'Verdict : NETTOYAGE AWS COMPLET. Le budget reste volontairement actif.\n'
