#!/usr/bin/env bash
# Prépare environment/aws-readiness.env avec authentification AWS et détection automatique.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
EXAMPLE_FILE="$PROJECT_ROOT/environment/aws-readiness.env.example"
PROFILE_OVERRIDE=""
REGION_OVERRIDE=""
BUDGET_EMAIL_OVERRIDE=""
AUTH_MODE_OVERRIDE=""
SOURCE_PROFILE_OVERRIDE=""
PUBLIC_IP_OVERRIDE=""
SSH_KEY_OVERRIDE=""
ASSUME_YES=false

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "configure-lab"

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/configure-lab.sh [options]

Options:
  --profile NOM        profil final AWS utilisé par le P5
  --region REGION      région AWS à utiliser
  --budget-email MAIL  adresse de notification du budget
  --auth-mode MODE     auto, console, sso ou existing
  --source-profile NOM profil source pour console/existing
  --public-ip IP       IPv4 publique à utiliser si la détection automatique échoue
  --ssh-key CHEMIN     chemin d'une clé SSH privée existante
  --yes                confirme les actions automatisables
  -h, --help           afficher cette aide

Le script :
  - crée environment/aws-readiness.env s'il manque ;
  - authentifie AWS avec des credentials temporaires ;
  - détecte et vérifie l'identifiant du compte AWS ;
  - refuse l'identité root ;
  - détecte l'IPv4 publique actuelle ou la demande avec un format expliqué ;
  - prépare la clé SSH du lab ou demande le chemin d'une clé existante ;
  - demande explicitement les vérifications de sécurité manuelles ;
  - génère les trois terraform.tfvars.

Les valeurs dérivées de l'état AWS (identité/compte) ne sont jamais inventées :
si AWS ne peut pas les fournir, le script explique comment rétablir la vérification.
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
        --auth-mode)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --auth-mode.'; exit 2; }
            AUTH_MODE_OVERRIDE="$2"
            shift 2
            ;;
        --source-profile)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --source-profile.'; exit 2; }
            SOURCE_PROFILE_OVERRIDE="$2"
            shift 2
            ;;
        --public-ip)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --public-ip.'; exit 2; }
            PUBLIC_IP_OVERRIDE="$2"
            shift 2
            ;;
        --ssh-key)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-key.'; exit 2; }
            SSH_KEY_OVERRIDE="$2"
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
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
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
AUTH_MODE="${AUTH_MODE_OVERRIDE:-${P5_AWS_AUTH_MODE:-auto}}"
SOURCE_PROFILE="${SOURCE_PROFILE_OVERRIDE:-${P5_AWS_LOGIN_PROFILE:-p5-signin}}"

[[ -n "$PROFILE" ]] || p5_prompt_value PROFILE \
    'Nom du profil AWS final' \
    'Le P5 a besoin d’un nom de profil AWS commun à AWS CLI et Terraform.' \
    'nom sans espace' 'p5-lab' 'p5-lab' p5_validate_nonempty \
    'Ou relancez avec : --profile p5-lab'

[[ "$REGION" =~ ^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$ ]] || p5_prompt_value REGION \
    'Région AWS' \
    'Terraform doit savoir dans quelle région créer les ressources du P5.' \
    'région AWS, par exemple us-east-1' 'us-east-1' 'us-east-1' p5_validate_nonempty \
    'Ou relancez avec : --region us-east-1'

AUTH_ARGS=(
    --profile "$PROFILE"
    --region "$REGION"
    --mode "$AUTH_MODE"
    --source-profile "$SOURCE_PROFILE"
)
if [[ "$ASSUME_YES" == true ]]; then
    AUTH_ARGS+=(--yes)
fi
p5_run_step 'aws-auth' 'Authentifier AWS avec une session temporaire' \
    bash "$SCRIPT_DIR/aws-auth.sh" "${AUTH_ARGS[@]}"

PROFILE_REGION="$(aws configure get region --profile "$PROFILE" 2>/dev/null || true)"
if [[ -n "$PROFILE_REGION" ]]; then
    REGION="$PROFILE_REGION"
else
    aws configure set region "$REGION" --profile "$PROFILE"
fi

aws_identity() {
    aws --profile "$PROFILE" --region "$REGION" --no-cli-pager \
        sts get-caller-identity --output json 2>/dev/null
}

IDENTITY_JSON="$(aws_identity || true)"
if [[ -z "$IDENTITY_JSON" ]]; then
    p5_authoritative_unknown \
        'Identité AWS active' \
        "STS ne retourne aucune identité avec le profil '$PROFILE'. Le compte réel ne peut donc pas être vérifié." \
        "Relancez l’authentification : bash scripts/commands/aws-auth.sh --profile '$PROFILE' --region '$REGION'"
    exit 1
fi

ACCOUNT_ID="$(jq -r '.Account // empty' <<<"$IDENTITY_JSON" 2>/dev/null || true)"
CALLER_ARN="$(jq -r '.Arn // empty' <<<"$IDENTITY_JSON" 2>/dev/null || true)"
if [[ ! "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    p5_authoritative_unknown \
        'Identifiant du compte AWS' \
        'STS a répondu mais sans identifiant de compte à 12 chiffres exploitable.' \
        "Vérifiez la session AWS puis relancez : aws sts get-caller-identity --profile '$PROFILE'"
    exit 1
fi
[[ "$CALLER_ARN" != *":root" ]] || {
    p5_error 'Le compte root AWS ne doit pas être utilisé.'
    p5_action 'Reconnectez-vous avec un utilisateur/rôle IAM ou IAM Identity Center.'
    exit 1
}

if ! aws configure export-credentials --profile "$PROFILE" --format process 2>/dev/null \
    | jq -e '.AccessKeyId and .SecretAccessKey and .SessionToken and .Expiration' \
    >/dev/null; then
    p5_authoritative_unknown \
        'Credentials AWS temporaires' \
        "Le profil '$PROFILE' ne fournit pas de SessionToken + Expiration vérifiables." \
        "Relancez : bash scripts/commands/aws-auth.sh --profile '$PROFILE' --mode auto"
    exit 1
fi

SAVED_IP=""
if p5_validate_ipv4_cidr32 "${P5_PUBLIC_IP_CIDR:-}" \
    && [[ "${P5_PUBLIC_IP_CIDR:-}" != '203.0.113.10/32' ]]; then
    SAVED_IP="${P5_PUBLIC_IP_CIDR%/32}"
fi

if [[ -n "$PUBLIC_IP_OVERRIDE" ]]; then
    CURRENT_IP="$PUBLIC_IP_OVERRIDE"
    if ! p5_validate_ipv4 "$CURRENT_IP"; then
        p5_error "--public-ip invalide : $CURRENT_IP"
        p5_action 'Format attendu : IPv4 seule, par exemple 198.51.100.42 (sans /32).'
        exit 2
    fi
    p5_info "IPv4 fournie explicitement : $CURRENT_IP"
else
    CURRENT_IP="$(curl -fsS --max-time 10 https://checkip.amazonaws.com 2>/dev/null \
        | tr -d '[:space:]' || true)"
    if p5_validate_ipv4 "$CURRENT_IP"; then
        p5_ok "IPv4 publique détectée automatiquement : $CURRENT_IP"
    else
        p5_unknown \
            'IPv4 publique actuelle' \
            'le service de détection automatique n’a pas retourné une IPv4 valide' \
            'Vous pouvez la saisir maintenant ; elle sera validée puis stockée automatiquement en /32.'
        p5_prompt_value CURRENT_IP \
            'IPv4 publique actuelle' \
            'Elle sert à limiter SSH et OpenSearch à votre connexion Internet actuelle.' \
            'IPv4 seule, sans /32' '198.51.100.42' "$SAVED_IP" p5_validate_ipv4 \
            'Saisissez-la ici, ou relancez avec : --public-ip 198.51.100.42'
    fi
fi
PUBLIC_IP_CIDR="$CURRENT_IP/32"

BUDGET_EMAIL="${BUDGET_EMAIL_OVERRIDE:-${P5_BUDGET_EMAIL:-}}"
if ! p5_validate_email "$BUDGET_EMAIL" || [[ "$BUDGET_EMAIL" == 'remplacer@example.com' ]]; then
    p5_unknown \
        'Adresse e-mail du budget AWS' \
        'aucune adresse réelle valide n’est disponible dans la configuration locale' \
        'Renseignez l’adresse qui doit recevoir les alertes de coût AWS.'
    p5_prompt_value BUDGET_EMAIL \
        'Adresse e-mail pour les alertes AWS' \
        'AWS Budgets utilisera cette adresse pour les seuils 50 %, 80 % et 100 % prévisionnel.' \
        'adresse e-mail complète' 'prenom.nom@example.com' '' p5_validate_email \
        'Saisissez-la ici, ou relancez avec : --budget-email prenom.nom@example.com'
fi

PUBLIC_KEY_RAW="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
PUBLIC_KEY="${PUBLIC_KEY_RAW/#\~/$HOME}"
PRIVATE_KEY="${P5_SSH_KEY_PATH:-${PUBLIC_KEY%.pub}}"
PRIVATE_KEY="${PRIVATE_KEY/#\~/$HOME}"
if [[ -n "$SSH_KEY_OVERRIDE" ]]; then
    PRIVATE_KEY="${SSH_KEY_OVERRIDE/#\~/$HOME}"
    PUBLIC_KEY="${PRIVATE_KEY}.pub"
fi
mkdir -p "$(dirname -- "$PRIVATE_KEY")"

if [[ ! -f "$PRIVATE_KEY" ]]; then
    p5_unknown \
        'Clé SSH privée du lab' \
        "aucune clé privée n’existe à l’emplacement attendu : $PRIVATE_KEY" \
        'Le script peut créer une clé dédiée ou utiliser une clé privée existante que vous lui indiquez.'
    if p5_confirm "Créer une nouvelle clé SSH dédiée dans $PRIVATE_KEY ?"; then
        ssh-keygen -t ed25519 -a 64 -f "$PRIVATE_KEY" -N '' -C 'p5-openclassrooms'
        p5_ok 'Clé SSH du lab créée.'
    else
        p5_prompt_value PRIVATE_KEY \
            'Chemin de la clé SSH privée existante' \
            'Ansible et les scripts de collecte doivent pouvoir se connecter aux EC2 du P5.' \
            'chemin absolu vers un fichier de clé privée existant' "$HOME/.ssh/id_ed25519" '' p5_validate_existing_file \
            "Saisissez le chemin ici, ou relancez avec : --ssh-key $HOME/.ssh/id_ed25519"
        PRIVATE_KEY="${PRIVATE_KEY/#\~/$HOME}"
        PUBLIC_KEY="${PRIVATE_KEY}.pub"
    fi
fi
chmod 600 "$PRIVATE_KEY"
if [[ ! -f "$PUBLIC_KEY" ]]; then
    ssh-keygen -y -f "$PRIVATE_KEY" > "$PUBLIC_KEY"
    p5_info "Clé publique dérivée depuis la clé privée : $PUBLIC_KEY"
fi
chmod 644 "$PUBLIC_KEY"

manual_confirmation() {
    local target_variable="$1"
    local current_value="$2"
    local label="$3"
    local why="$4"
    local how_to_verify="$5"
    local result=no

    if [[ "${current_value,,}" == yes || "${current_value,,}" == oui ]]; then
        result=yes
    else
        p5_header "VÉRIFICATION HUMAINE — $label"
        p5_info "$why"
        p5_action "$how_to_verify"
        if p5_require_exact 'Après avoir réellement effectué cette vérification, confirmez-la.' 'OUI'; then
            result=yes
        fi
    fi
    printf -v "$target_variable" '%s' "$result"
}

ROOT_MFA=no
ROOT_KEYS=no
IAM_POLICY=no
BILLING_CONTACTS=no
manual_confirmation ROOT_MFA "${P5_ROOT_MFA_CONFIRMED:-no}" \
    'MFA du compte root' \
    'Le compte root doit être protégé même s’il n’est pas utilisé par le lab.' \
    'Dans la console AWS : Compte/Security credentials → vérifiez qu’un MFA root est activé.'
manual_confirmation ROOT_KEYS "${P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED:-no}" \
    'Absence de clés d’accès root' \
    'Une clé d’accès root permanente créerait un risque inutile et ne doit pas être utilisée.' \
    'Dans les Security credentials du compte root, vérifiez qu’aucune Access Key root n’existe.'
manual_confirmation IAM_POLICY "${P5_IAM_POLICY_ATTACHED_CONFIRMED:-no}" \
    'Permissions de l’identité P5' \
    'L’identité quotidienne doit pouvoir créer uniquement les ressources requises par le projet.' \
    'Vérifiez que l’identité/rôle utilisé possède SignInLocalDevelopmentAccess et la politique P5 documentée dans aws/iam/p5-lab-policy.json.'
manual_confirmation BILLING_CONTACTS "${P5_BILLING_CONTACTS_CONFIRMED:-no}" \
    'Contacts de facturation' \
    'Les alertes de coût doivent pouvoir être reçues et les informations de facturation doivent être à jour.' \
    'Dans la console AWS, vérifiez les contacts du compte et les informations de facturation.'

python3 - "$CONFIG_FILE" \
    "AWS_PROFILE=$PROFILE" \
    "AWS_REGION=$REGION" \
    "P5_AWS_AUTH_MODE=$AUTH_MODE" \
    "P5_AWS_LOGIN_PROFILE=$SOURCE_PROFILE" \
    "P5_EXPECTED_ACCOUNT_ID=$ACCOUNT_ID" \
    "P5_PUBLIC_IP_CIDR=$PUBLIC_IP_CIDR" \
    "P5_SSH_KEY_PATH=$PRIVATE_KEY" \
    "P5_SSH_PUBLIC_KEY_PATH=$PUBLIC_KEY" \
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

p5_ok "Compte AWS vérifié depuis STS : $ACCOUNT_ID"
p5_ok "Identité AWS : ${CALLER_ARN:-non affichée}"
p5_ok "IPv4 d'administration : $PUBLIC_IP_CIDR"
p5_ok "Profil/région : $PROFILE / $REGION"
p5_ok 'Credentials temporaires exportables : OK'
p5_ok "Clé SSH privée : $PRIVATE_KEY"

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
    p5_info 'Mode --yes utilisé pour les actions automatisables ; les informations inconnues et validations humaines restent explicites.'
fi

p5_header 'Configuration terminée'
p5_ok 'AWS, la source de vérité locale et les tfvars sont synchronisés.'
p5_latest_log_hint
