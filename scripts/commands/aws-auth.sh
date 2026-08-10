#!/usr/bin/env bash
# Prépare une authentification AWS temporaire compatible AWS CLI et Terraform.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
TARGET_PROFILE="p5-lab"
SOURCE_PROFILE="p5-signin"
REGION="us-east-1"
MODE="auto"
ASSUME_YES=false

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "aws-auth"

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/aws-auth.sh [options]

Options:
  --profile NOM         profil final utilisé par le P5 (défaut : p5-lab)
  --source-profile NOM  profil source pour console/existant (défaut : p5-signin)
  --region REGION       région AWS (défaut : us-east-1)
  --mode MODE           auto, console, sso ou existing
  --yes                 choisit console si auto doit initialiser un nouveau profil
  -h, --help            afficher cette aide

Modes :
  auto      réutilise/renouvelle le profil si possible, sinon propose un mode
  console   utilise `aws login --remote` et des identifiants temporaires
  sso       utilise IAM Identity Center (`aws configure sso` + `aws sso login`)
  existing  encapsule un profil temporaire existant via credential_process

Le script ne demande, ne lit et ne stocke jamais votre mot de passe AWS.
Lorsqu'un nom de profil ne peut pas être déduit, les profils disponibles sont
affichés et le format exact attendu est expliqué.
HELP
}

while (($# > 0)); do
    case "$1" in
        --profile)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --profile.'; exit 2; }
            TARGET_PROFILE="$2"
            shift 2
            ;;
        --source-profile)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --source-profile.'; exit 2; }
            SOURCE_PROFILE="$2"
            shift 2
            ;;
        --region)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --region.'; exit 2; }
            REGION="$2"
            shift 2
            ;;
        --mode)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --mode.'; exit 2; }
            MODE="$2"
            shift 2
            ;;
        --yes)
            ASSUME_YES=true
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

case "$MODE" in
    auto|console|sso|existing) ;;
    *) p5_error "Mode AWS inconnu : $MODE"; p5_action 'Valeurs autorisées : auto, console, sso, existing.'; exit 2 ;;
esac

for command_name in aws jq python3; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
done

aws_version_number() {
    aws --version 2>&1 | sed -n 's/^aws-cli\/\([0-9][0-9.]*\).*/\1/p'
}

version_at_least() {
    python3 - "$1" "$2" <<'PY'
import sys

def parse(value: str) -> tuple[int, ...]:
    parts = value.split('.')
    return tuple(int(part) for part in parts[:3])

actual = parse(sys.argv[1])
minimum = parse(sys.argv[2])
actual += (0,) * (3 - len(actual))
minimum += (0,) * (3 - len(minimum))
raise SystemExit(0 if actual >= minimum else 1)
PY
}

profile_exists() {
    aws configure list-profiles 2>/dev/null | grep -Fxq "$1"
}

profile_get() {
    aws configure get "$2" --profile "$1" 2>/dev/null || true
}

aws_identity() {
    local profile="$1"
    aws --profile "$profile" --region "$REGION" --no-cli-pager \
        sts get-caller-identity --output json 2>/dev/null
}

credentials_are_temporary() {
    local profile="$1"
    aws configure export-credentials --profile "$profile" --format process 2>/dev/null \
        | jq -e '.AccessKeyId and .SecretAccessKey and .SessionToken and .Expiration' \
        >/dev/null 2>&1
}

reject_root() {
    local identity_json="$1"
    local arn
    arn="$(jq -r '.Arn // empty' <<<"$identity_json")"
    if [[ "$arn" == *":root" ]]; then
        p5_error 'Le projet refuse volontairement une session AWS root.'
        p5_action 'Utilisez un utilisateur/rôle IAM ou IAM Identity Center pour le travail quotidien.'
        return 1
    fi
}

validate_profile() {
    local profile="$1" identity_json account_id arn
    identity_json="$(aws_identity "$profile" || true)"
    [[ -n "$identity_json" ]] || return 1
    reject_root "$identity_json" || return 1
    credentials_are_temporary "$profile" || {
        p5_warn "Le profil '$profile' fonctionne mais ne fournit pas de credentials temporaires avec expiration."
        return 1
    }
    account_id="$(jq -r '.Account // empty' <<<"$identity_json")"
    arn="$(jq -r '.Arn // empty' <<<"$identity_json")"
    p5_ok "Session AWS temporaire valide : $profile"
    p5_ok "Compte : $account_id"
    p5_ok "Identité : $arn"
    return 0
}

renew_known_profile() {
    local profile="$1"
    local login_session sso_session sso_start_url
    login_session="$(profile_get "$profile" login_session)"
    sso_session="$(profile_get "$profile" sso_session)"
    sso_start_url="$(profile_get "$profile" sso_start_url)"

    if [[ -n "$login_session" ]]; then
        p5_action "Renouvellement de la session console AWS du profil '$profile'."
        aws login --remote --profile "$profile" --region "$REGION"
        return
    fi
    if [[ -n "$sso_session" || -n "$sso_start_url" ]]; then
        p5_action "Renouvellement de la session IAM Identity Center '$profile'."
        aws sso login --profile "$profile"
        return
    fi
    return 1
}

configure_process_profile() {
    local source="$1"
    if [[ "$source" == "$TARGET_PROFILE" ]]; then
        return 0
    fi
    aws configure set region "$REGION" --profile "$TARGET_PROFILE"
    aws configure set credential_process \
        "aws configure export-credentials --profile $source --format process" \
        --profile "$TARGET_PROFILE"
    p5_ok "Profil Terraform '$TARGET_PROFILE' relié à '$source' via credential_process."
}

console_login() {
    local version identity_json
    version="$(aws_version_number)"
    if [[ -z "$version" ]] || ! version_at_least "$version" '2.32.0'; then
        p5_error "AWS CLI >= 2.32.0 requise pour aws login (détectée : ${version:-inconnue})."
        p5_action 'Relancez le bootstrap du projet pour mettre AWS CLI v2 à jour.'
        return 1
    fi

    aws configure set region "$REGION" --profile "$SOURCE_PROFILE"
    p5_header 'CONNEXION AWS — navigateur externe'
    p5_info 'La VM va afficher une URL/code AWS. Ouvrez cette URL dans votre navigateur habituel.'
    p5_info 'Saisissez vos identifiants directement chez AWS ; le script ne les voit jamais.'
    p5_info 'AWS remet ensuite à la CLI des credentials temporaires renouvelables.'

    if ! aws login --remote --profile "$SOURCE_PROFILE" --region "$REGION"; then
        p5_error 'La connexion AWS via aws login a échoué.'
        p5_action 'Vérifiez que votre identité possède la politique AWS gérée SignInLocalDevelopmentAccess.'
        p5_action 'La politique métier P5 doit également être attachée à votre identité/rôle.'
        return 1
    fi

    identity_json="$(aws_identity "$SOURCE_PROFILE" || true)"
    [[ -n "$identity_json" ]] || {
        p5_authoritative_unknown 'Identité AWS après aws login' \
            'la commande de connexion a terminé mais STS ne retourne aucune identité' \
            "Testez : aws sts get-caller-identity --profile '$SOURCE_PROFILE'"
        return 1
    }
    reject_root "$identity_json" || return 1
    credentials_are_temporary "$SOURCE_PROFILE" || {
        p5_authoritative_unknown 'Credentials temporaires de la session AWS' \
            'la session créée ne fournit pas SessionToken + Expiration' \
            'Vérifiez la version AWS CLI et les permissions SignInLocalDevelopmentAccess.'
        return 1
    }

    configure_process_profile "$SOURCE_PROFILE"
}

sso_login() {
    local sso_session sso_start_url
    sso_session="$(profile_get "$TARGET_PROFILE" sso_session)"
    sso_start_url="$(profile_get "$TARGET_PROFILE" sso_start_url)"
    if [[ -z "$sso_session" && -z "$sso_start_url" ]]; then
        p5_action "Configuration IAM Identity Center du profil '$TARGET_PROFILE'."
        p5_info 'AWS CLI va vous demander les informations de votre portail IAM Identity Center.'
        aws configure sso --profile "$TARGET_PROFILE"
    fi
    aws configure set region "$REGION" --profile "$TARGET_PROFILE"
    aws sso login --profile "$TARGET_PROFILE"
}

source_profile_exists() {
    profile_exists "$1"
}

existing_profile() {
    local profiles identity_json first_profile
    profiles="$(aws configure list-profiles 2>/dev/null || true)"
    [[ -n "$profiles" ]] || {
        p5_unknown 'Profil AWS temporaire existant' \
            'AWS CLI ne retourne aucun profil configuré sur cette VM' \
            'Choisissez plutôt le mode console ou SSO, ou configurez d’abord un profil temporaire.'
        p5_action 'Exemple : bash scripts/commands/aws-auth.sh --mode console'
        return 1
    }
    printf 'Profils AWS disponibles :\n%s\n' "$profiles"
    first_profile="$(head -n 1 <<<"$profiles")"
    if [[ "$SOURCE_PROFILE" == 'p5-signin' ]] || ! profile_exists "$SOURCE_PROFILE"; then
        p5_prompt_value SOURCE_PROFILE \
            'Nom du profil AWS temporaire source' \
            'Le mode existing doit réutiliser un profil déjà présent dans `aws configure list-profiles`.' \
            'nom exact d’un profil affiché ci-dessus, sans crochets' "$first_profile" '' source_profile_exists \
            "Saisissez-le ici, ou relancez avec : --source-profile $first_profile"
    fi

    identity_json="$(aws_identity "$SOURCE_PROFILE" || true)"
    if [[ -z "$identity_json" ]]; then
        renew_known_profile "$SOURCE_PROFILE" || {
            p5_authoritative_unknown "Session AWS du profil '$SOURCE_PROFILE'" \
                'la session est invalide et aucun mécanisme de renouvellement connu n’est configuré' \
                'Utilisez --mode console, --mode sso, ou renouvelez explicitement ce profil.'
            return 1
        }
        identity_json="$(aws_identity "$SOURCE_PROFILE" || true)"
    fi
    [[ -n "$identity_json" ]] || {
        p5_authoritative_unknown "Identité AWS du profil '$SOURCE_PROFILE'" \
            'STS ne retourne toujours aucune identité après le renouvellement' \
            "Testez : aws sts get-caller-identity --profile '$SOURCE_PROFILE'"
        return 1
    }
    reject_root "$identity_json" || return 1
    credentials_are_temporary "$SOURCE_PROFILE" || {
        p5_error "Le profil '$SOURCE_PROFILE' n'utilise pas de credentials temporaires avec expiration."
        p5_action 'Le P5 n’utilise pas de clés d’accès longue durée par défaut.'
        return 1
    }
    configure_process_profile "$SOURCE_PROFILE"
}

choose_mode() {
    if [[ "$ASSUME_YES" == true ]]; then
        MODE=console
        return
    fi
    if [[ ! -t 0 ]]; then
        p5_unknown 'Méthode d’authentification AWS' \
            'aucune méthode réutilisable n’a été détectée et le terminal n’est pas interactif' \
            'Relancez avec --mode console, --mode sso ou --mode existing.'
        return 1
    fi

    cat <<'MENU'

Méthode d'authentification AWS :
  1  Compte console AWS — aws login --remote (recommandé)
  2  IAM Identity Center / SSO
  3  Réutiliser un profil temporaire existant
MENU
    printf 'Votre choix [1] : '
    local choice
    read -r choice
    case "${choice:-1}" in
        1) MODE=console ;;
        2) MODE=sso ;;
        3) MODE=existing ;;
        *) p5_error 'Choix AWS inconnu.'; p5_action 'Tapez 1, 2 ou 3.'; return 1 ;;
    esac
}

p5_header 'AUTHENTIFICATION AWS'
p5_info "Profil P5 : $TARGET_PROFILE"
p5_info "Région     : $REGION"

if [[ "$MODE" == auto ]]; then
    if validate_profile "$TARGET_PROFILE"; then
        p5_ok 'Aucune reconnexion AWS nécessaire.'
        p5_latest_log_hint
        exit 0
    fi

    if profile_exists "$TARGET_PROFILE" && renew_known_profile "$TARGET_PROFILE"; then
        if validate_profile "$TARGET_PROFILE"; then
            p5_latest_log_hint
            exit 0
        fi
    fi

    process_value="$(profile_get "$TARGET_PROFILE" credential_process)"
    if [[ "$process_value" =~ --profile[[:space:]]+([^[:space:]]+) ]]; then
        detected_source="${BASH_REMATCH[1]}"
        if profile_exists "$detected_source" && renew_known_profile "$detected_source"; then
            if validate_profile "$TARGET_PROFILE"; then
                p5_latest_log_hint
                exit 0
            fi
        fi
    fi

    choose_mode
fi

case "$MODE" in
    console) console_login ;;
    sso) sso_login ;;
    existing) existing_profile ;;
esac

validate_profile "$TARGET_PROFILE" || {
    p5_authoritative_unknown "Profil final AWS '$TARGET_PROFILE'" \
        'AWS CLI ne peut pas vérifier une identité non-root avec credentials temporaires exploitables' \
        "Relancez : bash scripts/commands/aws-auth.sh --profile '$TARGET_PROFILE' --mode auto"
    exit 1
}

p5_header 'AWS PRÊT'
p5_ok "Le profil '$TARGET_PROFILE' est authentifié sans clé longue durée dans le dépôt."
p5_ok 'AWS CLI, Terraform et les scripts P5 peuvent utiliser la même session.'
p5_latest_log_hint
