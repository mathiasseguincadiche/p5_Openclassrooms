#!/usr/bin/env bash
# Crée volontairement le budget du lab. Ne crée aucune ressource des exercices.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
APPLY=no

show_help() {
    cat <<'HELP'
Usage: setup-aws-guardrails.sh [--config CHEMIN] --apply

Sans --apply, le script affiche uniquement ce qu'il ferait. La seule mutation
prise en charge est la création du budget AWS du lab avec trois alertes e-mail.
HELP
}

while (($# > 0)); do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --config.\n' >&2; exit 2; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --apply)
            APPLY=yes
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

if [[ ! -f "$CONFIG_FILE" ]]; then
    printf 'Configuration absente : %s\n' "$CONFIG_FILE" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

required=(
    AWS_PROFILE
    P5_EXPECTED_ACCOUNT_ID
    P5_BUDGET_NAME
    P5_BUDGET_LIMIT_USD
    P5_BUDGET_EMAIL
)
for variable in "${required[@]}"; do
    [[ -n "${!variable:-}" ]] || {
        printf '%s est absent ou vide dans %s.\n' "$variable" "$CONFIG_FILE" >&2
        exit 1
    }
done

ACTIVE_ACCOUNT="$(aws --profile "$AWS_PROFILE" --region us-east-1 --no-cli-pager \
    sts get-caller-identity --query Account --output text)"
if [[ "$ACTIVE_ACCOUNT" != "$P5_EXPECTED_ACCOUNT_ID" ]]; then
    printf 'Compte actif %s différent du compte autorisé %s.\n' \
        "$ACTIVE_ACCOUNT" "$P5_EXPECTED_ACCOUNT_ID" >&2
    exit 1
fi

if [[ "$P5_BUDGET_EMAIL" == "remplacer@example.com" || "$P5_BUDGET_EMAIL" != *"@"* ]]; then
    printf 'P5_BUDGET_EMAIL doit contenir une adresse réelle.\n' >&2
    exit 1
fi

if ! [[ "$P5_BUDGET_LIMIT_USD" =~ ^[0-9]+([.][0-9]{1,2})?$ ]]; then
    printf 'P5_BUDGET_LIMIT_USD doit être un montant positif.\n' >&2
    exit 1
fi

printf 'Budget prévu\n'
printf '  Compte : %s\n' "$ACTIVE_ACCOUNT"
printf '  Nom    : %s\n' "$P5_BUDGET_NAME"
printf '  Limite : %s USD par mois\n' "$P5_BUDGET_LIMIT_USD"
printf '  E-mail : %s\n' "$P5_BUDGET_EMAIL"
printf '  Alertes: 50 %% réel, 80 %% réel, 100 %% prévisionnel\n'

EXISTING="$(aws --profile "$AWS_PROFILE" --region us-east-1 --no-cli-pager \
    budgets describe-budgets --account-id "$ACTIVE_ACCOUNT" \
    --query "length(Budgets[?BudgetName=='$P5_BUDGET_NAME'])" \
    --output text)"
if [[ "$EXISTING" != "0" ]]; then
    printf '\nLe budget existe déjà. Aucune modification automatique n’est appliquée.\n'
    printf 'Vérifiez son montant et ses destinataires dans la console AWS.\n'
    exit 0
fi

if [[ "$APPLY" != yes ]]; then
    printf '\nMode aperçu : relancez avec --apply pour créer ce budget.\n'
    exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/budget.json" <<JSON
{
  "BudgetName": "$P5_BUDGET_NAME",
  "BudgetLimit": {
    "Amount": "$P5_BUDGET_LIMIT_USD",
    "Unit": "USD"
  },
  "CostTypes": {
    "IncludeTax": true,
    "IncludeSubscription": true,
    "UseBlended": false,
    "IncludeRefund": false,
    "IncludeCredit": false,
    "IncludeUpfront": true,
    "IncludeRecurring": true,
    "IncludeOtherSubscription": true,
    "IncludeSupport": true,
    "IncludeDiscount": true,
    "UseAmortized": false
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
JSON

cat > "$TMP_DIR/notifications.json" <<JSON
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 50,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "$P5_BUDGET_EMAIL"
      }
    ]
  },
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "$P5_BUDGET_EMAIL"
      }
    ]
  },
  {
    "Notification": {
      "NotificationType": "FORECASTED",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 100,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "$P5_BUDGET_EMAIL"
      }
    ]
  }
]
JSON

printf '\nCréation du budget AWS...\n'
aws --profile "$AWS_PROFILE" --region us-east-1 --no-cli-pager \
    budgets create-budget \
    --account-id "$ACTIVE_ACCOUNT" \
    --budget "file://$TMP_DIR/budget.json" \
    --notifications-with-subscribers "file://$TMP_DIR/notifications.json"

printf 'Budget créé. Confirmez la réception des notifications lorsqu’AWS les envoie.\n'
