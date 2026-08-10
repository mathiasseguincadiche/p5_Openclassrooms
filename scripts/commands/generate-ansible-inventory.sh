#!/usr/bin/env bash
# Converge ansible/inventories/hosts_aws depuis les outputs Terraform de l'exercice 1.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
INVENTORY_FILE="$PROJECT_ROOT/ansible/inventories/hosts_aws"
SSH_USER="ubuntu"

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
  -h, --help          afficher cette aide

Le fichier n'est réécrit que si l'IP Terraform, l'utilisateur ou la clé ont changé.
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

command -v terraform >/dev/null 2>&1 || { p5_error 'Terraform est absent.'; exit 1; }
command -v python3 >/dev/null 2>&1 || { p5_error 'Python 3 est absent.'; exit 1; }
[[ -r "$CONFIG_FILE" ]] || { p5_error "Configuration absente : $CONFIG_FILE"; exit 1; }

# shellcheck source=/dev/null
source "$CONFIG_FILE"
PUBLIC_KEY_RAW="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
PUBLIC_KEY="${PUBLIC_KEY_RAW/#\~/$HOME}"
PRIVATE_KEY="${P5_SSH_KEY_PATH:-${PUBLIC_KEY%.pub}}"
PRIVATE_KEY="${PRIVATE_KEY/#\~/$HOME}"
[[ -f "$PRIVATE_KEY" ]] || { p5_error "Clé SSH privée absente : $PRIVATE_KEY"; exit 1; }

WEB_IP="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
    output -raw web_public_ip 2>/dev/null || true)"
python3 - "$WEB_IP" <<'PY'
import ipaddress
import sys
ipaddress.IPv4Address(sys.argv[1])
PY

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

p5_ok "Hôte Terraform : $WEB_IP"
p5_ok "Clé SSH : $PRIVATE_KEY"
printf '\nCommande de vérification :\n'
printf '  ansible all -i %q -m ping\n' "$INVENTORY_FILE"
p5_latest_log_hint
