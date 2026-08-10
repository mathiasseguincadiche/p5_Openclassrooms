#!/usr/bin/env bash
# Converge le socle DevOps du lab P5 vers l'état attendu.
# Réexécutable : inspecte d'abord, puis n'installe/corrige que ce qui est nécessaire.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"
CHECK_ONLY=false
UPGRADE_SYSTEM=false
CHANGED=0
OK_COUNT=0
RECONNECT_REQUIRED=false
APT_UPDATED=false

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/bootstrap-ubuntu-server.sh [options]

Options:
  --check-only      inspecter la VM sans aucune modification
  --upgrade-system  autoriser apt full-upgrade en plus de la convergence P5
  -h, --help        afficher cette aide

Principe :
  inspecter -> comparer -> corriger uniquement l'écart -> vérifier.

Sans --upgrade-system, le script ne lance jamais de mise à niveau globale du
système. Il installe uniquement les paquets/outils manquants ou non conformes.
HELP
}

while (($# > 0)); do
    case "$1" in
        --check-only) CHECK_ONLY=true; shift ;;
        --upgrade-system) UPGRADE_SYSTEM=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) printf 'Option inconnue : %s\n' "$1" >&2; show_help >&2; exit 2 ;;
    esac
done

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

if [[ "${ID:-}" != ubuntu ]]; then
    printf 'KO  Système non pris en charge : Ubuntu Server est requis.\n' >&2
    exit 1
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
[[ -n "$CODENAME" ]] || { printf 'KO  Nom de version Ubuntu introuvable.\n' >&2; exit 1; }

ok() {
    OK_COUNT=$((OK_COUNT + 1))
    printf '  OK      %s\n' "$1"
}
change() {
    CHANGED=$((CHANGED + 1))
    printf '  CHANGE  %s\n' "$1"
}
need() {
    printf '  MANQUE  %s\n' "$1"
}
version_at_least() {
    python3 - "$1" "$2" <<'PY'
import sys
def parse(v):
    parts = [int(x) for x in v.split('.')[:3]]
    return tuple(parts + [0] * (3 - len(parts)))
raise SystemExit(0 if parse(sys.argv[1]) >= parse(sys.argv[2]) else 1)
PY
}
package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -Fq 'install ok installed'
}
apt_update_once() {
    if [[ "$APT_UPDATED" != true ]]; then
        sudo apt-get update
        APT_UPDATED=true
    fi
}
terraform_current() {
    command -v terraform >/dev/null 2>&1 || return 1
    terraform version -json 2>/dev/null | jq -r '.terraform_version'
}
aws_current() {
    command -v aws >/dev/null 2>&1 || return 1
    aws --version 2>&1 | sed -n 's/^aws-cli\/\([0-9][0-9.]*\).*/\1/p'
}
ansible_current() {
    command -v ansible-playbook >/dev/null 2>&1 || return 1
    ansible-playbook --version 2>/dev/null | sed -n '1s/.*core \([^]]*\).*/\1/p'
}
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
        return 0
    fi
    return 1
}
docker_group_persistent() {
    getent group docker 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n' | grep -Fxq "$USER"
}

printf 'État cible P5 — Ubuntu %s, Terraform %s, Ansible %s, Node %s, AWS CLI >= %s\n' \
    "$P5_UBUNTU_VERSION_ID" "$TERRAFORM_VERSION" "$ANSIBLE_CORE_VERSION" \
    "$NODE_VERSION" "$AWS_CLI_MIN_VERSION"

ERRORS=0
printf '\nSystème\n'
if [[ "${VERSION_ID:-}" == "$P5_UBUNTU_VERSION_ID" ]]; then
    ok "${PRETTY_NAME:-Ubuntu $P5_UBUNTU_VERSION_ID}"
else
    printf '  KO      Ubuntu %s attendu ; %s détecté\n' \
        "$P5_UBUNTU_VERSION_ID" "${PRETTY_NAME:-inconnu}" >&2
    ERRORS=$((ERRORS + 1))
fi

BASE_PACKAGES=(
    bash-completion build-essential ca-certificates curl git gnupg jq make
    openssh-client pipx python3 python3-pip python3-venv shellcheck tree unzip
    vim wget yamllint zip
)
MISSING_PACKAGES=()
for package in "${BASE_PACKAGES[@]}"; do
    if package_installed "$package"; then
        ok "paquet $package"
    else
        need "paquet $package"
        MISSING_PACKAGES+=("$package")
    fi
done

TF_VERSION="$(terraform_current 2>/dev/null || true)"
if [[ "$TF_VERSION" == "$TERRAFORM_VERSION" ]]; then
    ok "Terraform $TF_VERSION"
else
    need "Terraform $TERRAFORM_VERSION (détecté : ${TF_VERSION:-absent})"
fi

DOCKER_READY=true
command -v docker >/dev/null 2>&1 || DOCKER_READY=false
if [[ "$DOCKER_READY" == true ]] && docker compose version >/dev/null 2>&1; then
    ok "Docker Engine + Compose présents"
else
    need "Docker Engine + Compose"
    DOCKER_READY=false
fi

AWS_VERSION="$(aws_current 2>/dev/null || true)"
if [[ -n "$AWS_VERSION" ]] && version_at_least "$AWS_VERSION" "$AWS_CLI_MIN_VERSION"; then
    ok "AWS CLI $AWS_VERSION"
else
    need "AWS CLI >= $AWS_CLI_MIN_VERSION (détectée : ${AWS_VERSION:-absente})"
fi

ANSIBLE_VERSION="$(ansible_current 2>/dev/null || true)"
if [[ "$ANSIBLE_VERSION" == "$ANSIBLE_CORE_VERSION" ]]; then
    ok "Ansible Core $ANSIBLE_VERSION"
else
    need "Ansible Core $ANSIBLE_CORE_VERSION (détecté : ${ANSIBLE_VERSION:-absent})"
fi

NODE_VERSION_CURRENT=""
if load_nvm; then
    NODE_VERSION_CURRENT="$(node --version 2>/dev/null || true)"
fi
if [[ "$NODE_VERSION_CURRENT" == "v${NODE_VERSION}" ]]; then
    ok "Node.js $NODE_VERSION via NVM"
else
    need "Node.js $NODE_VERSION via NVM (détecté : ${NODE_VERSION_CURRENT:-absent})"
fi

if command -v markdownlint-cli2 >/dev/null 2>&1; then
    ok "markdownlint-cli2"
else
    need "markdownlint-cli2"
fi

if [[ "$CHECK_ONLY" == true ]]; then
    if ((${#MISSING_PACKAGES[@]} > 0)) \
        || [[ "$TF_VERSION" != "$TERRAFORM_VERSION" ]] \
        || [[ "$DOCKER_READY" != true ]] \
        || [[ -z "$AWS_VERSION" ]] \
        || ! version_at_least "${AWS_VERSION:-0.0.0}" "$AWS_CLI_MIN_VERSION" \
        || [[ "$ANSIBLE_VERSION" != "$ANSIBLE_CORE_VERSION" ]] \
        || [[ "$NODE_VERSION_CURRENT" != "v${NODE_VERSION}" ]] \
        || ! command -v markdownlint-cli2 >/dev/null 2>&1 \
        || ((ERRORS > 0)); then
        printf '\nVerdict : VM NON CONVERGÉE — bootstrap requis.\n' >&2
        exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        printf '\nVerdict : OUTILS INSTALLÉS, mais Docker n’est pas accessible dans ce shell.\n' >&2
        exit 90
    fi
    printf '\nVerdict : VM CONVERGÉE — aucune installation nécessaire.\n'
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ((${#MISSING_PACKAGES[@]} > 0)); then
    printf '\nConvergence des paquets de base\n'
    apt_update_once
    sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    change "${#MISSING_PACKAGES[@]} paquet(s) de base installé(s)"
else
    ok "aucun paquet de base à installer"
fi

if [[ "$UPGRADE_SYSTEM" == true ]]; then
    printf '\nMise à niveau globale explicitement demandée\n'
    apt_update_once
    sudo apt-get full-upgrade -y
    change "mise à niveau globale Ubuntu exécutée"
else
    ok "apt full-upgrade non exécuté (non nécessaire au P5)"
fi

if [[ "$TF_VERSION" != "$TERRAFORM_VERSION" ]]; then
    printf '\nConvergence Terraform %s\n' "$TERRAFORM_VERSION"
    case "$ARCH" in
        amd64) TERRAFORM_ARCH=amd64 ;;
        arm64) TERRAFORM_ARCH=arm64 ;;
        *) printf 'Architecture Terraform non gérée : %s\n' "$ARCH" >&2; exit 1 ;;
    esac
    TERRAFORM_ARCHIVE="terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip"
    TERRAFORM_BASE_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"
    curl -fsSL "$TERRAFORM_BASE_URL/$TERRAFORM_ARCHIVE" -o "$TMP_DIR/$TERRAFORM_ARCHIVE"
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
    change "Terraform convergé vers $TERRAFORM_VERSION"
else
    ok "Terraform déjà conforme"
fi

if [[ "$DOCKER_READY" != true ]]; then
    printf '\nConvergence Docker Engine + Compose\n'
    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -s /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi
    DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
    EXPECTED_DOCKER_REPO="deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable"
    if [[ ! -r "$DOCKER_LIST" ]] || ! grep -Fxq "$EXPECTED_DOCKER_REPO" "$DOCKER_LIST"; then
        printf '%s\n' "$EXPECTED_DOCKER_REPO" | sudo tee "$DOCKER_LIST" >/dev/null
    fi
    apt_update_once
    sudo apt-get install -y containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-compose-plugin
    change "Docker Engine + Compose installés"
else
    ok "Docker déjà installé"
fi
sudo systemctl enable --now docker >/dev/null
if ! docker_group_persistent; then
    sudo usermod -aG docker "$USER"
    RECONNECT_REQUIRED=true
    change "utilisateur ajouté au groupe docker"
else
    ok "utilisateur déjà membre persistant du groupe docker"
fi

AWS_VERSION="$(aws_current 2>/dev/null || true)"
if [[ -z "$AWS_VERSION" ]] || ! version_at_least "$AWS_VERSION" "$AWS_CLI_MIN_VERSION"; then
    printf '\nConvergence AWS CLI v2\n'
    case "$ARCH" in
        amd64) AWS_ARCH=x86_64 ;;
        arm64) AWS_ARCH=aarch64 ;;
        *) printf 'Architecture AWS CLI non gérée : %s\n' "$ARCH" >&2; exit 1 ;;
    esac
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
        -o "$TMP_DIR/awscliv2.zip"
    unzip -q -o "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR/awscli"
    if command -v aws >/dev/null 2>&1; then
        sudo "$TMP_DIR/awscli/aws/install" --update
    else
        sudo "$TMP_DIR/awscli/aws/install"
    fi
    change "AWS CLI mise à niveau"
else
    ok "AWS CLI déjà compatible avec aws login"
fi

ANSIBLE_VERSION="$(ansible_current 2>/dev/null || true)"
if [[ "$ANSIBLE_VERSION" != "$ANSIBLE_CORE_VERSION" ]]; then
    printf '\nConvergence Ansible Core %s\n' "$ANSIBLE_CORE_VERSION"
    pipx install --force "$ANSIBLE_CORE_SPEC"
    change "Ansible Core convergé vers $ANSIBLE_CORE_VERSION"
else
    ok "Ansible Core déjà conforme"
fi
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
NVM_EXPECTED="${NVM_VERSION#v}"
NVM_CURRENT=""
if load_nvm; then
    NVM_CURRENT="$(nvm --version 2>/dev/null || true)"
fi
if [[ "$NVM_CURRENT" != "$NVM_EXPECTED" ]]; then
    printf '\nConvergence NVM %s\n' "$NVM_VERSION"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
    change "NVM convergé vers $NVM_VERSION"
else
    ok "NVM déjà conforme"
fi
if [[ "$(nvm version "$NODE_VERSION" 2>/dev/null || true)" != "v${NODE_VERSION}" ]]; then
    nvm install "$NODE_VERSION"
    change "Node.js $NODE_VERSION installé"
else
    ok "Node.js $NODE_VERSION déjà installé"
fi
if [[ "$(nvm alias default 2>/dev/null | sed -n 's/.*-> \(v[0-9.]*\).*/\1/p')" != "v${NODE_VERSION}" ]]; then
    nvm alias default "$NODE_VERSION"
    change "Node.js $NODE_VERSION défini comme version par défaut"
fi
nvm use "$NODE_VERSION" >/dev/null

if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
    npm install --global markdownlint-cli2
    change "markdownlint-cli2 installé"
else
    ok "markdownlint-cli2 déjà installé"
fi

printf '\nVérification finale\n'
hash -r
FINAL_ERRORS=0
[[ "$(terraform version -json | jq -r '.terraform_version')" == "$TERRAFORM_VERSION" ]] || FINAL_ERRORS=$((FINAL_ERRORS + 1))
ansible-playbook --version | head -n 1 | grep -Fq "core ${ANSIBLE_CORE_VERSION}" || FINAL_ERRORS=$((FINAL_ERRORS + 1))
[[ "$(node --version)" == "v${NODE_VERSION}" ]] || FINAL_ERRORS=$((FINAL_ERRORS + 1))
AWS_VERSION="$(aws_current 2>/dev/null || true)"
[[ -n "$AWS_VERSION" ]] && version_at_least "$AWS_VERSION" "$AWS_CLI_MIN_VERSION" || FINAL_ERRORS=$((FINAL_ERRORS + 1))
docker compose version >/dev/null 2>&1 || FINAL_ERRORS=$((FINAL_ERRORS + 1))

if ((FINAL_ERRORS > 0)); then
    printf 'KO  La convergence VM a laissé %s anomalie(s).\n' "$FINAL_ERRORS" >&2
    exit 1
fi

printf '\nRésumé : déjà conformes=%s | modifications=%s\n' "$OK_COUNT" "$CHANGED"
if [[ "$RECONNECT_REQUIRED" == true ]] || ! docker info >/dev/null 2>&1; then
    printf 'Verdict : VM CONVERGÉE — reconnexion requise pour le groupe Docker.\n'
    exit 90
fi
printf 'Verdict : VM CONVERGÉE — aucune reconnexion nécessaire.\n'
