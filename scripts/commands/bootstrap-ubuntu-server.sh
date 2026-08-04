#!/usr/bin/env bash
# Installe le socle DevOps du lab P5 sur Ubuntu Server 26.04.
# Ne configure aucun secret et ne crée aucune ressource AWS.
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
    printf 'Exécutez ce script avec votre utilisateur habituel, pas avec root.\n' >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Impossible d’identifier le système.\n' >&2
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'Système non pris en charge : Ubuntu Server est requis.\n' >&2
    exit 1
fi

if [[ "${VERSION_ID:-}" != "26.04" ]]; then
    printf 'Avertissement : script prévu pour Ubuntu 26.04, version détectée : %s.\n' \
        "${VERSION_ID:-inconnue}" >&2
fi

export DEBIAN_FRONTEND=noninteractive
ARCH="$(dpkg --print-architecture)"
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"

if [[ -z "$CODENAME" ]]; then
    printf 'Nom de version Ubuntu introuvable dans /etc/os-release.\n' >&2
    exit 1
fi

printf '1/7 — Mise à jour du système\n'
sudo apt-get update
sudo apt-get full-upgrade -y

printf '2/7 — Paquets de base\n'
sudo apt-get install -y \
    ansible-core \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    make \
    nodejs \
    npm \
    openssh-client \
    pipx \
    python3 \
    python3-pip \
    python3-venv \
    shellcheck \
    tree \
    unzip \
    vim \
    wget \
    yamllint \
    zip

printf '3/7 — Terraform depuis HashiCorp\n'
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com %s main\n' \
    "$ARCH" "$CODENAME" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt-get update
sudo apt-get install -y terraform

printf '4/7 — Docker Engine et Compose\n'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$ARCH" "$CODENAME" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

printf '5/7 — AWS CLI v2\n'
case "$ARCH" in
    amd64) AWS_ARCH="x86_64" ;;
    arm64) AWS_ARCH="aarch64" ;;
    *)
        printf 'Architecture AWS CLI non gérée automatiquement : %s.\n' "$ARCH" >&2
        exit 1
        ;;
esac
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
    -o "$TMP_DIR/awscliv2.zip"
unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
if command -v aws >/dev/null 2>&1; then
    sudo "$TMP_DIR/aws/install" --update
else
    sudo "$TMP_DIR/aws/install"
fi

printf '6/7 — Outils Markdown locaux\n'
sudo npm install --global markdownlint-cli2

printf '7/7 — Vérification des versions\n'
printf 'Ubuntu      : %s\n' "${PRETTY_NAME:-inconnu}"
printf 'Git         : %s\n' "$(git --version)"
printf 'Python      : %s\n' "$(python3 --version)"
printf 'Node.js     : %s\n' "$(node --version)"
printf 'npm         : %s\n' "$(npm --version)"
printf 'Terraform   : %s\n' "$(terraform version | head -n 1)"
printf 'Ansible     : %s\n' "$(ansible-playbook --version | head -n 1)"
printf 'AWS CLI     : %s\n' "$(aws --version 2>&1)"
printf 'Docker      : %s\n' "$(docker --version)"
printf 'Compose     : %s\n' "$(docker compose version)"
printf 'ShellCheck  : %s\n' "$(shellcheck --version | awk '/version:/ {print $2}')"

printf '\nSocle installé. Déconnectez-vous puis reconnectez-vous pour utiliser Docker sans sudo.\n'
printf 'Ensuite : ./scripts/commands/setup.sh --check-only\n'
