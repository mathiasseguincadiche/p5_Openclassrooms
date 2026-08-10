#!/usr/bin/env bash
# Inspecte puis converge le budget AWS du lab sans toucher aux ressources des exercices.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
MODE=preview

show_help() {
    cat <<'HELP'
Usage: setup-aws-guardrails.sh [options]

Options:
  --config CHEMIN  configuration locale AWS
  --check          vérifier sans modifier ; succès uniquement si le budget est conforme
  --apply          corriger uniquement les écarts détectés
  -h, --help       afficher cette aide

État attendu : budget mensuel P5, montant configuré et trois alertes e-mail
(50 % réel, 80 % réel, 100 % prévisionnel). Les alertes supplémentaires ne sont
pas supprimées automatiquement.
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
        -h|--help) show_help; exit 0 ;;
        *) printf 'Option inconnue : %s\n' "$1" >&2; show_help >&2; exit 2 ;;
    esac
done

[[ -f "$CONFIG_FILE" ]] || { printf 'Configuration absente : %s\n' "$CONFIG_FILE" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG_FILE"

required=(AWS_PROFILE P5_EXPECTED_ACCOUNT_ID P5_BUDGET_NAME P5_BUDGET_LIMIT_USD P5_BUDGET_EMAIL)
for variable in "${required[@]}"; do
    [[ -n "${!variable:-}" ]] || { printf '%s absent ou vide.\n' "$variable" >&2; exit 1; }
done
[[ "$P5_BUDGET_EMAIL" == *"@"* && "$P5_BUDGET_EMAIL" != remplacer@example.com ]] || {
    printf 'P5_BUDGET_EMAIL doit contenir une adresse réelle.\n' >&2
    exit 1
}
[[ "$P5_BUDGET_LIMIT_USD" =~ ^[0-9]+([.][0-9]{1,2})?$ ]] || {
    printf 'P5_BUDGET_LIMIT_USD doit être un montant positif.\n' >&2
    exit 1
}

aws_budget() {
    aws --profile "$AWS_PROFILE" --region us-east-1 --no-cli-pager budgets "$@"
}
ACTIVE_ACCOUNT="$(aws --profile "$AWS_PROFILE" --region us-east-1 --no-cli-pager \
    sts get-caller-identity --query Account --output text)"
[[ "$ACTIVE_ACCOUNT" == "$P5_EXPECTED_ACCOUNT_ID" ]] || {
    printf 'Compte actif %s différent du compte autorisé %s.\n' \
        "$ACTIVE_ACCOUNT" "$P5_EXPECTED_ACCOUNT_ID" >&2
    exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
BUDGET_JSON="$TMP_DIR/budget.json"
NOTIFICATIONS_JSON="$TMP_DIR/notifications.json"

write_new_budget() {
    cat > "$BUDGET_JSON" <<JSON
{
  "BudgetName": "$P5_BUDGET_NAME",
  "BudgetLimit": {"Amount": "$P5_BUDGET_LIMIT_USD", "Unit": "USD"},
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
}
write_notifications_create() {
    cat > "$NOTIFICATIONS_JSON" <<JSON
[
  {"Notification":{"NotificationType":"ACTUAL","ComparisonOperator":"GREATER_THAN","Threshold":50,"ThresholdType":"PERCENTAGE"},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"$P5_BUDGET_EMAIL"}]},
  {"Notification":{"NotificationType":"ACTUAL","ComparisonOperator":"GREATER_THAN","Threshold":80,"ThresholdType":"PERCENTAGE"},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"$P5_BUDGET_EMAIL"}]},
  {"Notification":{"NotificationType":"FORECASTED","ComparisonOperator":"GREATER_THAN","Threshold":100,"ThresholdType":"PERCENTAGE"},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"$P5_BUDGET_EMAIL"}]}
]
JSON
}
write_new_budget
write_notifications_create

budget_exists() {
    aws_budget describe-budget --account-id "$ACTIVE_ACCOUNT" --budget-name "$P5_BUDGET_NAME" \
        --output json > "$TMP_DIR/current-budget.json" 2>/dev/null
}
read_notifications() {
    aws_budget describe-notifications-for-budget \
        --account-id "$ACTIVE_ACCOUNT" --budget-name "$P5_BUDGET_NAME" \
        --output json > "$TMP_DIR/current-notifications.json"
}
notification_spec() {
    local type="$1" threshold="$2"
    printf 'NotificationType=%s,ComparisonOperator=GREATER_THAN,Threshold=%s,ThresholdType=PERCENTAGE' \
        "$type" "$threshold"
}
notification_exists() {
    local type="$1" threshold="$2"
    jq -e --arg type "$type" --argjson threshold "$threshold" '
      any(.Notifications[]?;
        .NotificationType == $type and
        .ComparisonOperator == "GREATER_THAN" and
        (.Threshold | tonumber) == $threshold and
        ((.ThresholdType // "PERCENTAGE") == "PERCENTAGE"))
    ' "$TMP_DIR/current-notifications.json" >/dev/null
}
subscriber_exists() {
    local type="$1" threshold="$2" spec
    spec="$(notification_spec "$type" "$threshold")"
    aws_budget describe-subscribers-for-notification \
        --account-id "$ACTIVE_ACCOUNT" --budget-name "$P5_BUDGET_NAME" \
        --notification "$spec" --output json 2>/dev/null \
        | jq -e --arg email "$P5_BUDGET_EMAIL" \
            'any(.Subscribers[]?; .SubscriptionType == "EMAIL" and .Address == $email)' \
            >/dev/null
}

printf 'État attendu du garde-fou AWS\n'
printf '  Compte : %s\n' "$ACTIVE_ACCOUNT"
printf '  Budget : %s\n' "$P5_BUDGET_NAME"
printf '  Limite : %s USD / mois\n' "$P5_BUDGET_LIMIT_USD"
printf '  E-mail : %s\n' "$P5_BUDGET_EMAIL"
printf '  Alertes: ACTUAL 50, ACTUAL 80, FORECASTED 100\n\n'

if ! budget_exists; then
    printf 'MANQUE  budget %s\n' "$P5_BUDGET_NAME"
    if [[ "$MODE" == check ]]; then
        exit 1
    fi
    if [[ "$MODE" == preview ]]; then
        printf 'Mode aperçu : le budget et ses trois alertes seraient créés.\n'
        exit 0
    fi
    aws_budget create-budget \
        --account-id "$ACTIVE_ACCOUNT" \
        --budget "file://$BUDGET_JSON" \
        --notifications-with-subscribers "file://$NOTIFICATIONS_JSON"
    printf 'CHANGE  budget et alertes créés.\n'
    budget_exists
fi

CURRENT_AMOUNT="$(jq -r '.Budget.BudgetLimit.Amount // empty' "$TMP_DIR/current-budget.json")"
AMOUNT_OK=false
if jq -e --arg wanted "$P5_BUDGET_LIMIT_USD" \
    '(.Budget.BudgetLimit.Amount | tonumber) == ($wanted | tonumber)' \
    "$TMP_DIR/current-budget.json" >/dev/null; then
    AMOUNT_OK=true
    printf 'OK      montant déjà conforme : %s USD\n' "$CURRENT_AMOUNT"
else
    printf 'ÉCART   montant actuel=%s USD, attendu=%s USD\n' \
        "${CURRENT_AMOUNT:-inconnu}" "$P5_BUDGET_LIMIT_USD"
fi

read_notifications
MISSING_NOTIFICATIONS=()
MISSING_SUBSCRIBERS=()
for pair in 'ACTUAL 50' 'ACTUAL 80' 'FORECASTED 100'; do
    read -r type threshold <<<"$pair"
    if notification_exists "$type" "$threshold"; then
        printf 'OK      alerte %s %s %% présente\n' "$type" "$threshold"
        if subscriber_exists "$type" "$threshold"; then
            printf 'OK      destinataire %s présent pour %s %s %%\n' \
                "$P5_BUDGET_EMAIL" "$type" "$threshold"
        else
            printf 'ÉCART   destinataire manquant pour %s %s %%\n' "$type" "$threshold"
            MISSING_SUBSCRIBERS+=("$type:$threshold")
        fi
    else
        printf 'ÉCART   alerte %s %s %% absente\n' "$type" "$threshold"
        MISSING_NOTIFICATIONS+=("$type:$threshold")
    fi
done

if [[ "$AMOUNT_OK" == true ]] \
    && ((${#MISSING_NOTIFICATIONS[@]} == 0)) \
    && ((${#MISSING_SUBSCRIBERS[@]} == 0)); then
    printf '\nVerdict : GARDE-FOU AWS DÉJÀ CONFORME — AUCUNE MUTATION NÉCESSAIRE.\n'
    exit 0
fi

if [[ "$MODE" == check ]]; then
    printf '\nVerdict : GARDE-FOU AWS NON CONFORME.\n' >&2
    exit 1
fi
if [[ "$MODE" == preview ]]; then
    printf '\nMode aperçu : seuls les écarts ci-dessus seraient corrigés avec --apply.\n'
    exit 0
fi

if [[ "$AMOUNT_OK" != true ]]; then
    jq --arg amount "$P5_BUDGET_LIMIT_USD" '
      .Budget
      | .BudgetLimit.Amount = $amount
      | del(.CalculatedSpend, .LastUpdatedTime, .HealthStatus)
    ' "$TMP_DIR/current-budget.json" > "$TMP_DIR/update-budget.json"
    aws_budget update-budget \
        --account-id "$ACTIVE_ACCOUNT" \
        --new-budget "file://$TMP_DIR/update-budget.json"
    printf 'CHANGE  montant du budget convergé vers %s USD.\n' "$P5_BUDGET_LIMIT_USD"
fi

for item in "${MISSING_NOTIFICATIONS[@]}"; do
    type="${item%%:*}"
    threshold="${item##*:}"
    spec="$(notification_spec "$type" "$threshold")"
    aws_budget create-notification \
        --account-id "$ACTIVE_ACCOUNT" \
        --budget-name "$P5_BUDGET_NAME" \
        --notification "$spec" \
        --subscribers "SubscriptionType=EMAIL,Address=$P5_BUDGET_EMAIL"
    printf 'CHANGE  alerte %s %s %% + destinataire créés.\n' "$type" "$threshold"
done

for item in "${MISSING_SUBSCRIBERS[@]}"; do
    type="${item%%:*}"
    threshold="${item##*:}"
    spec="$(notification_spec "$type" "$threshold")"
    aws_budget create-subscriber \
        --account-id "$ACTIVE_ACCOUNT" \
        --budget-name "$P5_BUDGET_NAME" \
        --notification "$spec" \
        --subscriber "SubscriptionType=EMAIL,Address=$P5_BUDGET_EMAIL"
    printf 'CHANGE  destinataire ajouté pour %s %s %%.\n' "$type" "$threshold"
done

printf '\nRelecture de l’état après convergence...\n'
exec "$0" --config "$CONFIG_FILE" --check
