#!/usr/bin/env bash
# Converge ansible/inventories/hosts_aws depuis les outputs Terraform de l'exercice 1.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
INVENTORY_FILE="$PROJECT_ROOT/ansible/inventories/hosts_aws"
SSH_USER="ubuntu"
SSH_KEY_OVERRIDE=""

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "generate-ansible-inventory"

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/generate-ansible-inventory.sh [options]

Options:
  --config CHEMIN     configuration aws-readiness.env
  --output CHEMIN     inventaire Ansible à converger
  --ssh-user NOM      utilisateur SSH (défaut : ubuntu)
  --ssh-key CHEMIN    clé SSH privée existante si la configuration ne la fournit pas
  -h, --help          afficher cette aide

L'adresse de l'EC2 est une donnée d'infrastructure : elle est obligatoirement
lue depuis l'output Terraform web_public_ip et n'est jamais inventée.
HELP
}

while (($# > 0)); do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --config.'; exit 2; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --output.'; exit 2; }
            INVENTORY_FILE="$2"
            shift 2
            ;;
        --ssh-user)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-user.'; exit 2; }
            SSH_USER="$2"
            shift 2
            ;;
        --ssh-key)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-key.'; exit 2; }
            SSH_KEY_OVERRIDE="$2"
            shift 2
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

command -v terraform >/dev/null 2>&1 || {
    p5_error 'Terraform est absent.'
    p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
    exit 1
}
command -v python3 >/dev/null 2>&1 || {
    p5_error 'Python 3 est absent.'
    p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
    exit 1
}
[[ -r "$CONFIG_FILE" ]] || {
    p5_unknown 'Configuration locale AWS' "fichier absent : $CONFIG_FILE" \
        'Lancez : bash scripts/commands/p5.sh prepare'
    exit 1
}

# shellcheck source=/dev/null
source "$CONFIG_FILE"
PUBLIC_KEY_RAW="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
PUBLIC_KEY="${PUBLIC_KEY_RAW/#\~/$HOME}"
PRIVATE_KEY="${P5_SSH_KEY_PATH:-${PUBLIC_KEY%.pub}}"
PRIVATE_KEY="${PRIVATE_KEY/#\~/$HOME}"
if [[ -n "$SSH_KEY_OVERRIDE" ]]; then
    PRIVATE_KEY="${SSH_KEY_OVERRIDE/#\~/$HOME}"
fi

if [[ ! -f "$PRIVATE_KEY" ]]; then
    p5_unknown 'Clé SSH privée Ansible' "fichier absent : $PRIVATE_KEY" \
        'Indiquez une clé existante ; elle doit correspondre à la clé EC2 créée par Terraform.'
    p5_prompt_value PRIVATE_KEY \
        'Chemin de la clé SSH privée' \
        'Ansible en a besoin pour se connecter à l’EC2 de l’exercice 1.' \
        'chemin absolu vers un fichier existant' "$HOME/.ssh/p5-key" '' p5_validate_existing_file \
        "Saisissez-la ici, ou relancez avec : --ssh-key $HOME/.ssh/p5-key"
fi
chmod 600 "$PRIVATE_KEY"

WEB_IP=""
p5_terraform_output WEB_IP "$PROJECT_ROOT/terraform/exercice-1" web_public_ip \
    'Adresse publique de l’EC2 Angular' p5_validate_ipv4 \
    'Relancez : bash scripts/commands/p5.sh ex1 ; si Terraform échoue, envoyez le log tf-ex1-*.'

mkdir -p "$(dirname -- "$INVENTORY_FILE")"
umask 077
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT
cat > "$TMP_FILE" <<EOF_INVENTORY
# Généré automatiquement depuis Terraform. Ne pas committer.
[webservers]
web ansible_host=$WEB_IP ansible_user=$SSH_USER ansible_ssh_private_key_file=$PRIVATE_KEY

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF_INVENTORY

p5_header 'Convergence inventaire Ansible'
if [[ -f "$INVENTORY_FILE" ]] && cmp -s "$TMP_FILE" "$INVENTORY_FILE"; then
    if [[ "$(stat -c '%a' "$INVENTORY_FILE")" != 600 ]]; then
        chmod 600 "$INVENTORY_FILE"
        p5_ok "Inventaire inchangé ; permissions corrigées : $INVENTORY_FILE"
    else
        p5_ok "Inventaire déjà conforme : $INVENTORY_FILE"
    fi
else
    install -m 0600 "$TMP_FILE" "$INVENTORY_FILE"
    p5_ok "Inventaire convergé : $INVENTORY_FILE"
fi

p5_ok "Hôte Terraform vérifié : $WEB_IP"
p5_ok "Clé SSH : $PRIVATE_KEY"
printf '\nCommande de vérification :\n'
printf '  ansible all -i %q -m ping\n' "$INVENTORY_FILE"
p5_latest_log_hint
