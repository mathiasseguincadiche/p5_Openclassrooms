#!/usr/bin/env bash
# Prépare environment/aws-readiness.env avec détection automatique du compte et de l'IP.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
EXAMPLE_FILE="$PROJECT_ROOT/environment/aws-readiness.env.example"
PROFILE_OVERRIDE=""
REGION_OVERRIDE=""
BUDGET_EMAIL_OVERRIDE=""
ASSUME_YES=false

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "configure-lab"

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/configure-lab.sh [options]

Options:
  --profile NOM       profil AWS à utiliser
  --region REGION     région AWS à utiliser
  --budget-email MAIL adresse de notification du budget
  --yes               confirme les actions automatisables
  -h, --help          afficher cette aide

Le script :
  - crée environment/aws-readiness.env s'il manque ;
  - détecte l'identifiant du compte AWS ;
  - détecte l'IPv4 publique actuelle en /32 ;
  - prépare la clé SSH du lab si nécessaire ;
  - demande explicitement les vérifications de sécurité manuelles ;
  - génère les trois terraform.tfvars.
HELP
}

while (($# > 0)); do
    case "$1" in
        --profile)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --profile.'; exit 2; }
            PROFILE_OVERRIDE="$2"
            shift 2
            ;;
        --region)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --region.'; exit 2; }
            REGION_OVERRIDE="$2"
            shift 2
            ;;
        --budget-email)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --budget-email.'; exit 2; }
            BUDGET_EMAIL_OVERRIDE="$2"
            shift 2
            ;;
        --yes)
            ASSUME_YES=true
            export P5_ASSUME_YES=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            p5_error "Option inconnue : $1"
            show_help >&2
            exit 2
            ;;
    esac
done

for command_name in aws curl jq python3 ssh-keygen; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        exit 1
    }
done

[[ -r "$EXAMPLE_FILE" ]] || {
    p5_error "Fichier modèle absent : $EXAMPLE_FILE"
    exit 1
}

p5_header 'Configuration locale du lab'
if [[ ! -f "$CONFIG_FILE" ]]; then
    install -m 0600 "$EXAMPLE_FILE" "$CONFIG_FILE"
    p5_ok "Configuration créée : $CONFIG_FILE"
else
    chmod 600 "$CONFIG_FILE"
    p5_info "Configuration existante conservée et complétée : $CONFIG_FILE"
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

PROFILE="${PROFILE_OVERRIDE:-${AWS_PROFILE:-p5-lab}}"
REGION="${REGION_OVERRIDE:-${AWS_REGION:-us-east-1}}"

if ! aws configure list-profiles | grep -Fxq "$PROFILE"; then
    p5_warn "Le profil AWS '$PROFILE' n'existe pas encore."
    EXISTING_PROFILES="$(aws configure list-profiles || true)"
    if [[ -n "$EXISTING_PROFILES" ]]; then
        printf 'Profils disponibles :\n%s\n' "$EXISTING_PROFILES"
        p5_prompt PROFILE 'Profil AWS à utiliser ou à créer' "$PROFILE"
    fi
fi

if ! aws configure list-profiles | grep -Fxq "$PROFILE"; then
    p5_action "Le profil '$PROFILE' doit être configuré."
    if p5_confirm "Lancer maintenant 'aws configure sso --profile $PROFILE' ?"; then
        aws configure sso --profile "$PROFILE"
    else
        p5_error "Configurez un profil AWS temporaire puis relancez le script."
        exit 1
    fi
fi

PROFILE_REGION="$(aws configure get region --profile "$PROFILE" 2>/dev/null || true)"
if [[ -z "$REGION_OVERRIDE" && -n "$PROFILE_REGION" ]]; then
    REGION="$PROFILE_REGION"
fi
if [[ -z "$PROFILE_REGION" || "$PROFILE_REGION" != "$REGION" ]]; then
    aws configure set region "$REGION" --profile "$PROFILE"
    p5_ok "Région du profil réglée sur $REGION"
fi

aws_identity() {
    aws --profile "$PROFILE" --region "$REGION" --no-cli-pager \
        sts get-caller-identity --output json 2>/dev/null
}

IDENTITY_JSON="$(aws_identity || true)"
if [[ -z "$IDENTITY_JSON" ]]; then
    SSO_SESSION="$(aws configure get sso_session --profile "$PROFILE" 2>/dev/null || true)"
    SSO_START_URL="$(aws configure get sso_start_url --profile "$PROFILE" 2>/dev/null || true)"
    if [[ -n "$SSO_SESSION" || -n "$SSO_START_URL" ]]; then
        p5_action "La session SSO du profil '$PROFILE' n'est pas active."
        if p5_confirm "Lancer 'aws sso login --profile $PROFILE' ?"; then
            aws sso login --profile "$PROFILE"
            IDENTITY_JSON="$(aws_identity || true)"
        fi
    fi
fi

if [[ -z "$IDENTITY_JSON" ]]; then
    p5_error "Impossible d'obtenir une identité AWS valide avec le profil '$PROFILE'."
    exit 1
fi

ACCOUNT_ID="$(jq -r '.Account // empty' <<<"$IDENTITY_JSON" 2>/dev/null || true)"
CALLER_ARN="$(jq -r '.Arn // empty' <<<"$IDENTITY_JSON" 2>/dev/null || true)"
if [[ ! "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    ACCOUNT_ID="$(aws --profile "$PROFILE" --region "$REGION" --no-cli-pager \
        sts get-caller-identity --query Account --output text)"
fi
[[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]] || {
    p5_error 'Identifiant de compte AWS invalide.'
    exit 1
}
[[ "$CALLER_ARN" != *":root" ]] || {
    p5_error 'Le compte root AWS ne doit pas être utilisé.'
    exit 1
}

CURRENT_IP="$(curl -fsS --max-time 10 https://checkip.amazonaws.com \
    | tr -d '[:space:]')"
python3 - "$CURRENT_IP" <<'PY'
import ipaddress
import sys
ipaddress.IPv4Address(sys.argv[1])
PY
PUBLIC_IP_CIDR="$CURRENT_IP/32"

BUDGET_EMAIL="${BUDGET_EMAIL_OVERRIDE:-${P5_BUDGET_EMAIL:-remplacer@example.com}}"
if [[ "$BUDGET_EMAIL" == 'remplacer@example.com' || "$BUDGET_EMAIL" != *"@"* ]]; then
    p5_prompt BUDGET_EMAIL 'Adresse e-mail pour les alertes de budget AWS' ''
fi
[[ "$BUDGET_EMAIL" == *"@"* ]] || {
    p5_error 'Adresse e-mail de budget invalide.'
    exit 1
}

PUBLIC_KEY_RAW="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
PUBLIC_KEY="${PUBLIC_KEY_RAW/#\~/$HOME}"
PRIVATE_KEY="${PUBLIC_KEY%.pub}"
mkdir -p "$(dirname -- "$PRIVATE_KEY")"

if [[ ! -f "$PRIVATE_KEY" ]]; then
    if p5_confirm "Créer la clé SSH du lab dans $PRIVATE_KEY ?"; then
        ssh-keygen -t ed25519 -a 64 -f "$PRIVATE_KEY" -N '' -C 'p5-openclassrooms'
        p5_ok 'Clé SSH du lab créée.'
    else
        p5_error "Clé SSH requise : $PRIVATE_KEY"
        exit 1
    fi
fi
chmod 600 "$PRIVATE_KEY"
if [[ ! -f "$PUBLIC_KEY" ]]; then
    ssh-keygen -y -f "$PRIVATE_KEY" > "$PUBLIC_KEY"
fi
chmod 644 "$PUBLIC_KEY"

manual_confirmation() {
    local target_variable="$1"
    local current_value="$2"
    local question="$3"
    local result=no

    if [[ "${current_value,,}" == yes || "${current_value,,}" == oui ]]; then
        result=yes
    elif p5_require_exact "$question" 'OUI'; then
        result=yes
    fi
    printf -v "$target_variable" '%s' "$result"
}

ROOT_MFA=no
ROOT_KEYS=no
IAM_POLICY=no
BILLING_CONTACTS=no
manual_confirmation ROOT_MFA "${P5_ROOT_MFA_CONFIRMED:-no}" \
    'MFA activé sur le compte root AWS et vérifié dans la console ?'
manual_confirmation ROOT_KEYS "${P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED:-no}" \
    'Aucune clé d’accès root AWS et vérification effectuée ?'
manual_confirmation IAM_POLICY "${P5_IAM_POLICY_ATTACHED_CONFIRMED:-no}" \
    'Politique IAM P5 attachée à l’identité utilisée et vérifiée ?'
manual_confirmation BILLING_CONTACTS "${P5_BILLING_CONTACTS_CONFIRMED:-no}" \
    'Contacts de facturation AWS vérifiés dans la console ?'

python3 - "$CONFIG_FILE" \
    "AWS_PROFILE=$PROFILE" \
    "AWS_REGION=$REGION" \
    "P5_EXPECTED_ACCOUNT_ID=$ACCOUNT_ID" \
    "P5_PUBLIC_IP_CIDR=$PUBLIC_IP_CIDR" \
    "P5_BUDGET_EMAIL=$BUDGET_EMAIL" \
    "P5_ROOT_MFA_CONFIRMED=$ROOT_MFA" \
    "P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED=$ROOT_KEYS" \
    "P5_IAM_POLICY_ATTACHED_CONFIRMED=$IAM_POLICY" \
    "P5_BILLING_CONTACTS_CONFIRMED=$BILLING_CONTACTS" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
updates = dict(item.split("=", 1) for item in sys.argv[2:])
lines = path.read_text(encoding="utf-8").splitlines()
seen = set()
out = []
for line in lines:
    if "=" in line and not line.lstrip().startswith("#"):
        key = line.split("=", 1)[0].strip()
        if key in updates:
            out.append(f"{key}={updates[key]}")
            seen.add(key)
            continue
    out.append(line)
for key, value in updates.items():
    if key not in seen:
        out.append(f"{key}={value}")
path.write_text("\n".join(out) + "\n", encoding="utf-8")
PY
chmod 600 "$CONFIG_FILE"

p5_ok "Compte AWS détecté : $ACCOUNT_ID"
p5_ok "Identité AWS : ${CALLER_ARN:-non affichée}"
p5_ok "IPv4 d'administration : $PUBLIC_IP_CIDR"
p5_ok "Profil/région : $PROFILE / $REGION"

p5_run_step 'sync-tfvars' 'Générer les trois terraform.tfvars' \
    bash "$SCRIPT_DIR/sync-terraform-tfvars.sh" --config "$CONFIG_FILE" --apply
p5_run_step 'check-tfvars' 'Vérifier la synchronisation des terraform.tfvars' \
    bash "$SCRIPT_DIR/sync-terraform-tfvars.sh" --config "$CONFIG_FILE" --check

if [[ "$ROOT_MFA" != yes || "$ROOT_KEYS" != yes || "$IAM_POLICY" != yes \
    || "$BILLING_CONTACTS" != yes ]]; then
    p5_warn 'Une ou plusieurs confirmations de sécurité restent à no.'
    p5_action 'Le contrôle AWS Ready restera bloquant tant que ces vérifications ne seront pas faites.'
fi

if [[ "$ASSUME_YES" == true ]]; then
    p5_info 'Mode --yes utilisé pour les actions automatisables ; les validations manuelles restent explicites.'
fi

p5_header 'Configuration terminée'
p5_ok 'La source de vérité locale et les tfvars sont synchronisés.'
p5_latest_log_hint
