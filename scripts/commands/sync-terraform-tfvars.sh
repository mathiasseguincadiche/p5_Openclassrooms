#!/usr/bin/env bash
# Génère ou vérifie les terraform.tfvars depuis environment/aws-readiness.env.
# Réexécutable : --apply n'écrit que les fichiers réellement différents.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
MODE=preview

show_help() {
    cat <<'HELP'
Usage: sync-terraform-tfvars.sh [options]

Options:
  --config CHEMIN   fichier aws-readiness.env à utiliser
  --check           vérifier que les trois terraform.tfvars sont synchronisés
  --apply           converger les trois terraform.tfvars (écriture uniquement si nécessaire)
  -h, --help        afficher cette aide

Sans option de mode, le script affiche uniquement les fichiers qui seraient écrits.
HELP
}

while (($# > 0)); do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --config.\n' >&2; exit 2; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --check)
            [[ "$MODE" == preview ]] || { printf 'Choisissez un seul mode.\n' >&2; exit 2; }
            MODE=check
            shift
            ;;
        --apply)
            [[ "$MODE" == preview ]] || { printf 'Choisissez un seul mode.\n' >&2; exit 2; }
            MODE=apply
            shift
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

[[ -f "$CONFIG_FILE" ]] || {
    printf 'Configuration absente : %s\n' "$CONFIG_FILE" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$CONFIG_FILE"

required=(
    AWS_REGION
    P5_EXPECTED_ACCOUNT_ID
    P5_PUBLIC_IP_CIDR
    P5_EC2_INSTANCE_TYPE
    P5_KEY_NAME
    P5_SSH_PUBLIC_KEY_PATH
    P5_OPENSEARCH_INSTANCE_TYPE
    P5_OPENSEARCH_ENGINE
    P5_OPENSEARCH_DOMAIN
    P5_OPENSEARCH_VOLUME_SIZE_GB
)
for variable in "${required[@]}"; do
    [[ -n "${!variable:-}" ]] || {
        printf '%s est absent ou vide dans %s.\n' "$variable" "$CONFIG_FILE" >&2
        exit 1
    }
done

[[ "$P5_EXPECTED_ACCOUNT_ID" =~ ^[0-9]{12}$ ]] \
    && [[ "$P5_EXPECTED_ACCOUNT_ID" != 000000000000 ]] || {
    printf 'P5_EXPECTED_ACCOUNT_ID doit contenir le véritable compte AWS.\n' >&2
    exit 1
}
[[ "$P5_PUBLIC_IP_CIDR" != 203.0.113.10/32 ]] || {
    printf 'P5_PUBLIC_IP_CIDR contient encore la valeur d’exemple.\n' >&2
    exit 1
}
[[ "$P5_OPENSEARCH_VOLUME_SIZE_GB" =~ ^[0-9]+$ ]] || {
    printf 'P5_OPENSEARCH_VOLUME_SIZE_GB doit être un entier.\n' >&2
    exit 1
}

hcl_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}

hcl_string() {
    printf '"%s"' "$(hcl_escape "$1")"
}

AMI_LITERAL=null
if [[ -n "${P5_AMI_ID:-}" ]]; then
    AMI_LITERAL="$(hcl_string "$P5_AMI_ID")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/exercice-1.tfvars" <<EOF_EX1
# Généré depuis environment/aws-readiness.env. Ne pas committer.
aws_region              = $(hcl_string "$AWS_REGION")
expected_aws_account_id = $(hcl_string "$P5_EXPECTED_ACCOUNT_ID")
ami_id                  = $AMI_LITERAL
instance_type           = $(hcl_string "$P5_EC2_INSTANCE_TYPE")
your_ip_cidr            = $(hcl_string "$P5_PUBLIC_IP_CIDR")
key_name                = $(hcl_string "$P5_KEY_NAME")
ssh_public_key_path     = $(hcl_string "$P5_SSH_PUBLIC_KEY_PATH")
EOF_EX1

cat > "$TMP_DIR/exercice-2.tfvars" <<EOF_EX2
# Généré depuis environment/aws-readiness.env. Ne pas committer.
aws_region                  = $(hcl_string "$AWS_REGION")
expected_aws_account_id     = $(hcl_string "$P5_EXPECTED_ACCOUNT_ID")
your_ip_cidr                = $(hcl_string "$P5_PUBLIC_IP_CIDR")
opensearch_domain_name      = $(hcl_string "$P5_OPENSEARCH_DOMAIN")
opensearch_engine_version   = $(hcl_string "$P5_OPENSEARCH_ENGINE")
opensearch_instance_type    = $(hcl_string "$P5_OPENSEARCH_INSTANCE_TYPE")
opensearch_volume_size_gb   = $P5_OPENSEARCH_VOLUME_SIZE_GB
EOF_EX2

cat > "$TMP_DIR/exercice-3.tfvars" <<EOF_EX3
# Généré depuis environment/aws-readiness.env. Ne pas committer.
aws_region              = $(hcl_string "$AWS_REGION")
expected_aws_account_id = $(hcl_string "$P5_EXPECTED_ACCOUNT_ID")
ami_id                  = $AMI_LITERAL
instance_type           = $(hcl_string "$P5_EC2_INSTANCE_TYPE")
key_name                = $(hcl_string "$P5_KEY_NAME")
your_ip_cidr            = $(hcl_string "$P5_PUBLIC_IP_CIDR")
EOF_EX3

if command -v terraform >/dev/null 2>&1; then
    terraform fmt "$TMP_DIR"/*.tfvars >/dev/null
fi

case "$MODE" in
    preview)
        for exercise in 1 2 3; do
            printf '\n--- terraform/exercice-%s/terraform.tfvars ---\n' "$exercise"
            cat "$TMP_DIR/exercice-${exercise}.tfvars"
        done
        printf '\nMode aperçu : relancez avec --apply pour converger les fichiers.\n'
        ;;
    check)
        errors=0
        for exercise in 1 2 3; do
            target="$PROJECT_ROOT/terraform/exercice-${exercise}/terraform.tfvars"
            if [[ ! -f "$target" ]]; then
                printf 'KO  %s absent.\n' "$target" >&2
                errors=$((errors + 1))
            elif ! cmp -s "$TMP_DIR/exercice-${exercise}.tfvars" "$target"; then
                printf 'KO  %s n’est pas synchronisé avec %s.\n' \
                    "$target" "$CONFIG_FILE" >&2
                errors=$((errors + 1))
            elif [[ "$(stat -c '%a' "$target")" != 600 ]]; then
                printf 'KO  %s doit être en mode 600.\n' "$target" >&2
                errors=$((errors + 1))
            else
                printf 'OK  exercice %s synchronisé.\n' "$exercise"
            fi
        done
        ((errors == 0)) || exit 1
        printf 'Verdict : VARIABLES TERRAFORM SYNCHRONISÉES.\n'
        ;;
    apply)
        umask 077
        changed=0
        unchanged=0
        for exercise in 1 2 3; do
            target="$PROJECT_ROOT/terraform/exercice-${exercise}/terraform.tfvars"
            if [[ -f "$target" ]] && cmp -s "$TMP_DIR/exercice-${exercise}.tfvars" "$target"; then
                if [[ "$(stat -c '%a' "$target")" != 600 ]]; then
                    chmod 600 "$target"
                    printf 'Corrigé (permissions) : %s\n' "$target"
                    changed=$((changed + 1))
                else
                    printf 'Déjà synchronisé      : %s\n' "$target"
                    unchanged=$((unchanged + 1))
                fi
                continue
            fi
            install -m 0600 "$TMP_DIR/exercice-${exercise}.tfvars" "$target"
            printf 'Convergé               : %s\n' "$target"
            changed=$((changed + 1))
        done
        printf 'Résumé : modifications=%s | déjà conformes=%s\n' "$changed" "$unchanged"
        printf 'Verdict : TERRAFORM.TFVARS CONVERGÉS DEPUIS AWS-READINESS.ENV.\n'
        ;;
esac
