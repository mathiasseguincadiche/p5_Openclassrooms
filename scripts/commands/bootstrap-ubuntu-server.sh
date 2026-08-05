#!/usr/bin/env bash
# Installe le socle DevOps du lab P5 sur Ubuntu Server 26.04.
# Ne configure aucun secret et ne crée aucune ressource AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"

if [[ "${EUID}" -eq 0 ]]; then
    printf 'Exécutez ce script avec votre utilisateur habituel, pas avec root.\n' >&2
    exit 1
fi

if [[ ! -r /etc/os-release || ! -r "$VERSIONS_FILE" ]]; then
    printf 'Impossible de lire le système ou environment/versions.env.\n' >&2
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
# shellcheck source=/dev/null
source "$VERSIONS_FILE"

if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'Système non pris en charge : Ubuntu Server est requis.\n' >&2
    exit 1
fi

if [[ "${VERSION_ID:-}" != "$P5_UBUNTU_VERSION_ID" ]]; then
    printf 'Avertissement : Ubuntu %s attendu, version détectée : %s.\n' \
        "$P5_UBUNTU_VERSION_ID" "${VERSION_ID:-inconnue}" >&2
fi

export DEBIAN_FRONTEND=noninteractive
ARCH="$(dpkg --print-architecture)"
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ -z "$CODENAME" ]]; then
    printf 'Nom de version Ubuntu introuvable dans /etc/os-release.\n' >&2
    exit 1
fi

printf '1/9 — Mise à jour du système\n'
sudo apt-get update
sudo apt-get full-upgrade -y

printf '2/9 — Paquets de base\n'
sudo apt-get install -y \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    make \
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

printf '3/9 — Terraform %s depuis l’archive officielle\n' "$TERRAFORM_VERSION"
case "$ARCH" in
    amd64) TERRAFORM_ARCH="amd64" ;;
    arm64) TERRAFORM_ARCH="arm64" ;;
    *)
        printf 'Architecture Terraform non gérée automatiquement : %s.\n' "$ARCH" >&2
        exit 1
        ;;
esac
TERRAFORM_ARCHIVE="terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip"
TERRAFORM_BASE_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"
curl -fsSL "$TERRAFORM_BASE_URL/$TERRAFORM_ARCHIVE" \
    -o "$TMP_DIR/$TERRAFORM_ARCHIVE"
curl -fsSL "$TERRAFORM_BASE_URL/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
    -o "$TMP_DIR/terraform_${TERRAFORM_VERSION}_SHA256SUMS"
(
    cd "$TMP_DIR"
    grep " ${TERRAFORM_ARCHIVE}$" "terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
        | sha256sum -c -
)
mkdir -p "$TMP_DIR/terraform"
unzip -q -o "$TMP_DIR/$TERRAFORM_ARCHIVE" -d "$TMP_DIR/terraform"
sudo install -m 0755 "$TMP_DIR/terraform/terraform" /usr/local/bin/terraform

printf '4/9 — Docker Engine et Compose\n'
sudo install -m 0755 -d /etc/apt/keyrings
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

printf '5/9 — AWS CLI v2\n'
case "$ARCH" in
    amd64) AWS_ARCH="x86_64" ;;
    arm64) AWS_ARCH="aarch64" ;;
    *)
        printf 'Architecture AWS CLI non gérée automatiquement : %s.\n' "$ARCH" >&2
        exit 1
        ;;
esac
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
    -o "$TMP_DIR/awscliv2.zip"
unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
if command -v aws >/dev/null 2>&1; then
    sudo "$TMP_DIR/aws/install" --update
else
    sudo "$TMP_DIR/aws/install"
fi

printf '6/9 — Ansible Core %s avec pipx\n' "$ANSIBLE_CORE_VERSION"
pipx install --force "$ANSIBLE_CORE_SPEC"
export PATH="$HOME/.local/bin:$PATH"

printf '7/9 — Node.js %s avec NVM\n' "$NODE_VERSION"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
nvm use "$NODE_VERSION"

printf '8/9 — Outils de qualité Markdown\n'
npm install --global markdownlint-cli2

printf '9/9 — Vérification des versions\n'
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

if [[ "$(node --version)" != "v${NODE_VERSION}" ]]; then
    printf 'La version Node.js installée ne correspond pas à %s.\n' "$NODE_VERSION" >&2
    exit 1
fi
if [[ "$(terraform version -json | jq -r '.terraform_version')" != "$TERRAFORM_VERSION" ]]; then
    printf 'La version Terraform installée ne correspond pas à %s.\n' "$TERRAFORM_VERSION" >&2
    exit 1
fi
if ! ansible-playbook --version | head -n 1 | grep -Fq "core ${ANSIBLE_CORE_VERSION}"; then
    printf 'La version Ansible Core installée ne correspond pas à %s.\n' \
        "$ANSIBLE_CORE_VERSION" >&2
    exit 1
fi

printf '\nSocle installé. Déconnectez-vous puis reconnectez-vous pour Docker.\n'
printf 'NVM chargera Node.js %s dans les nouveaux shells.\n' "$NODE_VERSION"
printf 'Ensuite : ./scripts/commands/setup.sh --check-only\n'
