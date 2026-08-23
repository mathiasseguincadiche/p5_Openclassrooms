#!/usr/bin/env bash
# Vérifie uniquement que la session AWS du P5 est encore exploitable.
# Ce contrôle ne crée, ne modifie et ne supprime aucune ressource AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"

show_help() {
    cat <<'HELP'
Usage: check-aws-session.sh [options]

Options:
  --config CHEMIN   fichier aws-readiness.env à utiliser
  -h, --help        afficher cette aide

Le contrôle vérifie STS avant les tests AWS détaillés. Si la session temporaire
est expirée ou illisible, il s'arrête sans extrapoler l'état EC2, VPC,
OpenSearch, quotas ou Budgets.
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

[[ -r "$CONFIG_FILE" ]] || {
    printf '  KO  configuration AWS locale absente ou illisible : %s\n' "$CONFIG_FILE" >&2
    exit 1
}
command -v aws >/dev/null 2>&1 || {
    printf '  KO  AWS CLI absente\n' >&2
    exit 1
}
command -v jq >/dev/null 2>&1 || {
    printf '  KO  jq absent\n' >&2
    exit 1
}

# shellcheck source=/dev/null
source "$CONFIG_FILE"

PROFILE="${AWS_PROFILE:-}"
REGION="${AWS_REGION:-}"
EXPECTED_ACCOUNT="${P5_EXPECTED_ACCOUNT_ID:-}"
SOURCE_PROFILE="${P5_AWS_LOGIN_PROFILE:-p5-signin}"

if [[ -z "$PROFILE" || -z "$REGION" ]]; then
    printf '  KO  AWS_PROFILE/AWS_REGION absents de la configuration locale\n' >&2
    exit 1
fi

ERROR_FILE="$(mktemp)"
trap 'rm -f "$ERROR_FILE"' EXIT
IDENTITY_JSON=""
if IDENTITY_JSON="$(aws --profile "$PROFILE" --region "$REGION" --no-cli-pager \
    sts get-caller-identity --output json 2>"$ERROR_FILE")"; then
    :
else
    ERROR_TEXT="$(cat "$ERROR_FILE")"
    printf '  KO  session AWS du profil %s invalide, expirée ou illisible\n' "$PROFILE" >&2
    if grep -Eqi 'expired|ExpiredToken|TOKEN_EXPIRED|security token|credential_process|Unable to locate credentials|login' <<<"$ERROR_TEXT"; then
        printf '      DIAGNOSTIC : les credentials temporaires doivent être renouvelés.\n' >&2
    else
        printf '      DIAGNOSTIC : STS ne peut pas confirmer l’identité AWS active.\n' >&2
    fi
    printf '      ACTION : bash scripts/commands/aws-auth.sh --profile %q --source-profile %q --region %q --mode auto\n' \
        "$PROFILE" "$SOURCE_PROFILE" "$REGION" >&2
    printf '      Aucun état EC2/VPC/OpenSearch/quota/Budget n’est déduit tant que STS est indisponible.\n' >&2
    exit 1
fi

ACCOUNT_ID="$(jq -r '.Account // empty' <<<"$IDENTITY_JSON")"
CALLER_ARN="$(jq -r '.Arn // empty' <<<"$IDENTITY_JSON")"

if [[ ! "$ACCOUNT_ID" =~ ^[0-9]{12}$ || -z "$CALLER_ARN" ]]; then
    printf '  KO  réponse STS incomplète ; identité AWS non vérifiable\n' >&2
    exit 1
fi
if [[ -n "$EXPECTED_ACCOUNT" && "$ACCOUNT_ID" != "$EXPECTED_ACCOUNT" ]]; then
    printf '  KO  compte AWS actif %s différent du compte attendu %s\n' \
        "$ACCOUNT_ID" "$EXPECTED_ACCOUNT" >&2
    exit 1
fi
if [[ "$CALLER_ARN" == *":root" ]]; then
    printf '  KO  le compte root AWS est interdit pour le projet\n' >&2
    exit 1
fi

printf '  OK  session AWS active : %s\n' "$CALLER_ARN"
printf '  OK  compte AWS vérifié : %s\n' "$ACCOUNT_ID"
