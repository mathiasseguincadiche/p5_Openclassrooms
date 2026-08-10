#!/usr/bin/env bash
# Produit une preuve locale horodatée de l'état AWS réel d'un exercice P5.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
EXERCISE=""
PROOF_DIR=""

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"

show_help() {
    cat <<'HELP'
Usage: verify-aws-exercise-state.sh --exercise 1|2|3 [--proof-dir CHEMIN]

Vérifie l'état réel AWS après convergence Terraform et écrit une preuve locale
horodatée sous proofs/runtime/exercice-N/. La commande est non destructive.

Exercice 1 : vérifie que l'EC2 Angular/NGINX est réellement running.
Exercice 2 : vérifie que le domaine Amazon OpenSearch est créé, actif et stable.
Exercice 3 : vérifie que HAProxy et les deux backends EC2 sont réellement running.
HELP
}

while (($# > 0)); do
    case "$1" in
        --exercise)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --exercise.\n' >&2; exit 2; }
            EXERCISE="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --proof-dir.\n' >&2; exit 2; }
            PROOF_DIR="$2"
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

[[ "$EXERCISE" =~ ^[123]$ ]] || {
    printf '%s\n' '--exercise doit valoir 1, 2 ou 3.' >&2
    exit 2
}
[[ -r "$CONFIG_FILE" ]] || {
    p5_authoritative_unknown 'Configuration AWS locale' \
        "le fichier $CONFIG_FILE est absent ou illisible" \
        'Lancez : bash scripts/commands/p5.sh prepare'
    exit 1
}

for command_name in aws terraform jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        exit 1
    }
done

# shellcheck source=/dev/null
source "$CONFIG_FILE"
: "${AWS_PROFILE:?AWS_PROFILE absent de la configuration}"
: "${AWS_REGION:?AWS_REGION absent de la configuration}"
: "${P5_EXPECTED_ACCOUNT_ID:?P5_EXPECTED_ACCOUNT_ID absent de la configuration}"

aws_cli() {
    aws --profile "$AWS_PROFILE" --region "$AWS_REGION" --no-cli-pager "$@"
}

ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text 2>/dev/null || true)"
if [[ "$ACCOUNT_ID" != "$P5_EXPECTED_ACCOUNT_ID" ]]; then
    p5_authoritative_unknown 'Compte AWS actif' \
        "compte obtenu '${ACCOUNT_ID:-inconnu}', compte attendu '$P5_EXPECTED_ACCOUNT_ID'" \
        "Réauthentifiez le profil '$AWS_PROFILE' avant de produire une preuve."
    exit 1
fi

PROOF_DIR="${PROOF_DIR:-$PROJECT_ROOT/proofs/runtime/exercice-$EXERCISE}"
umask 077
mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
PROOF_FILE="$PROOF_DIR/${TIMESTAMP}-etat-aws-exercice-${EXERCISE}.log"

terraform_raw() {
    local name="$1"
    terraform -chdir="$PROJECT_ROOT/terraform/exercice-$EXERCISE" output -raw "$name" 2>/dev/null || true
}

verify_ec2_by_public_ip() {
    local label="$1" public_ip="$2"
    local result state instance_id instance_type

    p5_validate_ipv4 "$public_ip" || {
        p5_authoritative_unknown "$label" \
            "l'IPv4 Terraform est absente ou invalide : ${public_ip:-vide}" \
            "Relancez Terraform exercice $EXERCISE et consultez tf-ex${EXERCISE}-output."
        return 1
    }

    result="$(aws_cli ec2 describe-instances \
        --filters "Name=ip-address,Values=$public_ip" \
        --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,PublicIpAddress]' \
        --output json 2>/dev/null || true)"

    [[ -n "$result" ]] || {
        p5_authoritative_unknown "$label" \
            "AWS n'a retourné aucune instance pour l'IP $public_ip" \
            'Vérifiez le state Terraform et la session AWS.'
        return 1
    }

    instance_id="$(jq -r '.[0][0] // empty' <<<"$result")"
    state="$(jq -r '.[0][1] // empty' <<<"$result")"
    instance_type="$(jq -r '.[0][2] // empty' <<<"$result")"
    [[ -n "$instance_id" && "$state" == running ]] || {
        printf '  KO  %s : id=%s état=%s type=%s ip=%s\n' \
            "$label" "${instance_id:-inconnu}" "${state:-inconnu}" \
            "${instance_type:-inconnu}" "$public_ip" >&2
        return 1
    }
    printf '  OK  %s : id=%s état=running type=%s ip=%s\n' \
        "$label" "$instance_id" "$instance_type" "$public_ip"
}

{
    printf 'Preuve d’état AWS — exercice %s\n' "$EXERCISE"
    printf 'UTC     : %s\n' "$(date -u --iso-8601=seconds)"
    printf 'Compte  : %s\n' "$ACCOUNT_ID"
    printf 'Région  : %s\n\n' "$AWS_REGION"

    printf 'État Terraform suivi\n'
    terraform -chdir="$PROJECT_ROOT/terraform/exercice-$EXERCISE" state list
    printf '\n'

    case "$EXERCISE" in
        1)
            WEB_IP="$(terraform_raw web_public_ip)"
            verify_ec2_by_public_ip 'EC2 Angular/NGINX' "$WEB_IP"
            printf '\nVerdict : ÉTAT AWS EXERCICE 1 VALIDÉ — EC2 RUNNING\n'
            ;;
        2)
            DOMAIN_NAME="$(terraform_raw opensearch_domain_name)"
            [[ -n "$DOMAIN_NAME" ]] || {
                p5_authoritative_unknown 'Nom du domaine OpenSearch' \
                    'la sortie Terraform opensearch_domain_name est absente' \
                    'Relancez Terraform exercice 2 et consultez tf-ex2-output.'
                exit 1
            }
            DOMAIN_JSON="$(aws_cli opensearch describe-domain \
                --domain-name "$DOMAIN_NAME" \
                --query 'DomainStatus.{DomainName:DomainName,Created:Created,Deleted:Deleted,Processing:Processing,UpgradeProcessing:UpgradeProcessing,EngineVersion:EngineVersion,Endpoint:Endpoint}' \
                --output json 2>/dev/null || true)"
            [[ -n "$DOMAIN_JSON" ]] || {
                p5_authoritative_unknown 'État Amazon OpenSearch' \
                    "AWS ne retourne pas le domaine '$DOMAIN_NAME'" \
                    'Vérifiez Terraform exercice 2 et la session AWS.'
                exit 1
            }
            printf '%s\n' "$DOMAIN_JSON" | jq .
            jq -e '.Created == true and (.Deleted != true) and .Processing == false and (.UpgradeProcessing != true)' \
                <<<"$DOMAIN_JSON" >/dev/null || {
                    printf '  KO  domaine OpenSearch non stable ou non actif.\n' >&2
                    exit 1
                }
            printf '  OK  domaine OpenSearch créé, actif et stable.\n'
            printf '\nVerdict : ÉTAT AWS EXERCICE 2 VALIDÉ — OPENSEARCH ACTIF\n'
            ;;
        3)
            HAPROXY_IP="$(terraform_raw haproxy_public_ip)"
            HELLO_1_IP="$(terraform_raw hello_1_public_ip)"
            HELLO_2_IP="$(terraform_raw hello_2_public_ip)"
            verify_ec2_by_public_ip 'EC2 HAProxy' "$HAPROXY_IP"
            verify_ec2_by_public_ip 'EC2 backend hello-1' "$HELLO_1_IP"
            verify_ec2_by_public_ip 'EC2 backend hello-2' "$HELLO_2_IP"
            printf '\nVerdict : ÉTAT AWS EXERCICE 3 VALIDÉ — 3 EC2 RUNNING\n'
            ;;
    esac

    printf 'Preuve locale : %s\n' "$PROOF_FILE"
} 2>&1 | tee "$PROOF_FILE"
