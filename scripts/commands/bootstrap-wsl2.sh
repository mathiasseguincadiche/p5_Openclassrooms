#!/usr/bin/env bash
# Converge les dépendances propres au P5 dans Ubuntu 26.04 sous WSL2.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"
APT_PACKAGES_FILE="$PROJECT_ROOT/environment/apt-packages.txt"
PLATFORM_LIB="$PROJECT_ROOT/scripts/lib/p5-platform.sh"
CHECK_ONLY=false
UPGRADE_SYSTEM=false
APT_UPDATED=false
CHANGED=0
OK_COUNT=0

show_help() {
    cat <<'HELP'
Usage: bash scripts/commands/bootstrap-wsl2.sh [options]

Options:
  --check-only      inspecter WSL2 et le runtime P5 sans modification
  --upgrade-system  autoriser apt full-upgrade en plus de la convergence P5
  -h, --help        afficher cette aide

Windows_11_Pro_Custom possède WSL2, Docker, Terraform et AWS CLI.
Ce bootstrap qualifie cette plateforme et converge uniquement les dépendances
propres au P5 : paquets CLI, Ansible, Node.js, markdownlint et le réglage
OpenSearch local. NVM est récupéré par Git puis verrouillé sur le commit de
release défini dans environment/versions.env ; aucun script distant n'est pipé
directement vers Bash.
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

if [[ "$EUID" -eq 0 ]]; then
    printf 'Exécutez ce script avec votre utilisateur WSL, pas avec root.\n' >&2
    exit 1
fi
[[ -r /etc/os-release && -r "$VERSIONS_FILE" && -r "$APT_PACKAGES_FILE" \
    && -r "$PLATFORM_LIB" ]] || {
    printf 'Impossible de lire le contrat système P5.\n' >&2
    exit 1
}

# shellcheck source=/dev/null
source /etc/os-release
# shellcheck source=/dev/null
source "$VERSIONS_FILE"
# shellcheck source=/dev/null
source "$PLATFORM_LIB"
export PATH="$HOME/.local/bin:$PATH"

if [[ "${ID:-}" != ubuntu || "${VERSION_ID:-}" != "$P5_UBUNTU_VERSION_ID" \
    || "${VERSION_CODENAME:-}" != "$P5_UBUNTU_CODENAME" ]]; then
    printf 'KO  Ubuntu %s/%s attendu ; %s/%s détecté.\n' \
        "$P5_UBUNTU_VERSION_ID" "$P5_UBUNTU_CODENAME" \
        "${VERSION_ID:-inconnu}" "${VERSION_CODENAME:-inconnu}" >&2
    exit 1
fi
p5_platform_validate "$PROJECT_ROOT" || {
    printf 'ACTION  Validez/réparez WSL avec %s avant de relancer P5.\n' "$P5_PLATFORM_REPOSITORY" >&2
    exit 1
}

ok() { OK_COUNT=$((OK_COUNT + 1)); printf '  OK      %s\n' "$1"; }
need() { printf '  MANQUE  %s\n' "$1"; }
change() { CHANGED=$((CHANGED + 1)); printf '  CHANGE  %s\n' "$1"; }
package_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -Fq 'install ok installed'; }
apt_update_once() { if [[ "$APT_UPDATED" != true ]]; then sudo apt-get update; APT_UPDATED=true; fi; }
version_at_least() {
    python3 - "$1" "$2" <<'PY'
import sys
def version(value):
    parts = [int(part) for part in value.split('.')[:3]]
    return tuple(parts + [0] * (3 - len(parts)))
raise SystemExit(0 if version(sys.argv[1]) >= version(sys.argv[2]) else 1)
PY
}
terraform_current() { terraform version -json 2>/dev/null | jq -r '.terraform_version'; }
aws_current() { aws --version 2>&1 | sed -n 's/^aws-cli\/\([0-9][0-9.]*\).*/\1/p'; }
ansible_current() { ansible-playbook --version 2>/dev/null | sed -n '1s/.*core \([^]]*\).*/\1/p'; }
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] || return 1
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
}
nvm_current_commit() {
    export NVM_DIR="$HOME/.nvm"
    [[ -d "$NVM_DIR/.git" ]] || return 1
    git -C "$NVM_DIR" rev-parse HEAD 2>/dev/null
}
nvm_is_pinned() {
    local current_commit current_version
    load_nvm || return 1
    current_version="$(nvm --version 2>/dev/null || true)"
    current_commit="$(nvm_current_commit 2>/dev/null || true)"
    [[ "$current_version" == "${NVM_VERSION#v}" && "$current_commit" == "$NVM_COMMIT" ]]
}
install_pinned_nvm() {
    export NVM_DIR="$HOME/.nvm"
    local expected_origin='https://github.com/nvm-sh/nvm.git'
    local current_origin=''

    if [[ -e "$NVM_DIR" && ! -d "$NVM_DIR/.git" ]]; then
        printf 'KO  %s existe mais n’est pas un dépôt Git NVM vérifiable.\n' "$NVM_DIR" >&2
        printf 'ACTION  Déplacez ce dossier après inspection ; le bootstrap ne le supprimera pas automatiquement.\n' >&2
        return 1
    fi

    if [[ ! -d "$NVM_DIR/.git" ]]; then
        mkdir -p "$NVM_DIR"
        git -C "$NVM_DIR" init -q
        git -C "$NVM_DIR" remote add origin "$expected_origin"
    else
        current_origin="$(git -C "$NVM_DIR" remote get-url origin 2>/dev/null || true)"
        if [[ -z "$current_origin" ]]; then
            git -C "$NVM_DIR" remote add origin "$expected_origin"
        elif [[ "$current_origin" != "$expected_origin" \
            && "$current_origin" != 'https://github.com/nvm-sh/nvm' \
            && "$current_origin" != 'git@github.com:nvm-sh/nvm.git' ]]; then
            printf 'KO  origine NVM inattendue : %s\n' "$current_origin" >&2
            printf 'ACTION  Vérifiez manuellement %s avant toute modification.\n' "$NVM_DIR" >&2
            return 1
        fi
    fi

    git -C "$NVM_DIR" fetch --depth 1 origin "$NVM_COMMIT"
    git -C "$NVM_DIR" checkout --detach --force FETCH_HEAD >/dev/null
    [[ "$(git -C "$NVM_DIR" rev-parse HEAD)" == "$NVM_COMMIT" ]] || {
        printf 'KO  le commit NVM vérifié n’a pas été obtenu.\n' >&2
        return 1
    }
    [[ -s "$NVM_DIR/nvm.sh" ]] || {
        printf 'KO  nvm.sh absent après checkout du commit NVM.\n' >&2
        return 1
    }
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
}

p5_platform_print_summary "$PROJECT_ROOT"
printf 'Ubuntu             : %s (%s)\n' "$VERSION_ID" "$VERSION_CODENAME"

PLATFORM_ERRORS=0
TF_VERSION="$(terraform_current 2>/dev/null || true)"
if [[ "$TF_VERSION" == "$TERRAFORM_VERSION" ]]; then ok "Terraform $TF_VERSION"; else
    printf '  KO      Terraform %s requis, détecté=%s\n' "$TERRAFORM_VERSION" "${TF_VERSION:-absent}" >&2
    PLATFORM_ERRORS=$((PLATFORM_ERRORS + 1))
fi
AWS_VERSION="$(aws_current 2>/dev/null || true)"
if [[ -n "$AWS_VERSION" ]] && version_at_least "$AWS_VERSION" "$AWS_CLI_MIN_VERSION"; then ok "AWS CLI $AWS_VERSION"; else
    printf '  KO      AWS CLI >= %s requise, détectée=%s\n' "$AWS_CLI_MIN_VERSION" "${AWS_VERSION:-absente}" >&2
    PLATFORM_ERRORS=$((PLATFORM_ERRORS + 1))
fi
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    ok 'Docker Engine + Compose présents'
else
    printf '  KO      Docker Engine + Compose doivent être fournis par Windows_11_Pro_Custom.\n' >&2
    PLATFORM_ERRORS=$((PLATFORM_ERRORS + 1))
fi
if ! systemctl is-active --quiet docker 2>/dev/null; then
    if [[ "$CHECK_ONLY" == true ]]; then
        printf '  KO      service Docker inactif sous systemd.\n' >&2
        PLATFORM_ERRORS=$((PLATFORM_ERRORS + 1))
    else
        sudo systemctl start docker
        change 'service Docker démarré sans modifier sa configuration'
    fi
fi
if ! docker info >/dev/null 2>&1; then
    printf '  KO      Docker inaccessible pour %s ; nouvelle session WSL requise après ajout au groupe docker.\n' "$USER" >&2
    PLATFORM_ERRORS=$((PLATFORM_ERRORS + 1))
fi
if ((PLATFORM_ERRORS > 0)); then
    printf '\nVerdict : PLATEFORME WSL2 NON CONFORME — relancez la validation Windows_11_Pro_Custom.\n' >&2
    exit 1
fi

mapfile -t BASE_PACKAGES < <(grep -vE '^($|#)' "$APT_PACKAGES_FILE")
MISSING_PACKAGES=()
for package in "${BASE_PACKAGES[@]}"; do
    package_installed "$package" && ok "paquet $package" || { need "paquet $package"; MISSING_PACKAGES+=("$package"); }
done

ANSIBLE_VERSION="$(ansible_current 2>/dev/null || true)"
[[ "$ANSIBLE_VERSION" == "$ANSIBLE_CORE_VERSION" ]] && ok "Ansible Core $ANSIBLE_VERSION" || need "Ansible Core $ANSIBLE_CORE_VERSION"
NVM_READY=false
if nvm_is_pinned; then
    NVM_READY=true
    ok "NVM $NVM_VERSION @ ${NVM_COMMIT:0:12}"
else
    need "NVM $NVM_VERSION @ ${NVM_COMMIT:0:12}"
fi
NODE_CURRENT=''
if load_nvm; then NODE_CURRENT="$(node --version 2>/dev/null || true)"; fi
[[ "$NODE_CURRENT" == "v$NODE_VERSION" ]] && ok "Node.js $NODE_VERSION" || need "Node.js $NODE_VERSION via NVM"
command -v markdownlint-cli2 >/dev/null 2>&1 && ok markdownlint-cli2 || need markdownlint-cli2
MAP_COUNT="$(sysctl -n vm.max_map_count 2>/dev/null || printf 0)"
[[ "$MAP_COUNT" -ge "$P5_OPENSEARCH_MAX_MAP_COUNT" ]] && ok "vm.max_map_count=$MAP_COUNT" || need "vm.max_map_count=$P5_OPENSEARCH_MAX_MAP_COUNT"

if [[ "$CHECK_ONLY" == true ]]; then
    if ((${#MISSING_PACKAGES[@]} > 0)) || [[ "$ANSIBLE_VERSION" != "$ANSIBLE_CORE_VERSION" ]] \
        || [[ "$NVM_READY" != true ]] || [[ "$NODE_CURRENT" != "v$NODE_VERSION" ]] \
        || ! command -v markdownlint-cli2 >/dev/null 2>&1 \
        || [[ "$MAP_COUNT" -lt "$P5_OPENSEARCH_MAX_MAP_COUNT" ]]; then
        printf '\nVerdict : RUNTIME P5 NON CONVERGÉ DANS WSL2 — bootstrap requis.\n' >&2
        exit 1
    fi
    printf '\nVerdict : RUNTIME P5 CONVERGÉ DANS WSL2 — aucune installation nécessaire.\n'
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive
if ((${#MISSING_PACKAGES[@]} > 0)); then
    apt_update_once
    sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    change "${#MISSING_PACKAGES[@]} paquet(s) P5 installé(s)"
fi
if [[ "$UPGRADE_SYSTEM" == true ]]; then apt_update_once; sudo apt-get full-upgrade -y; change 'mise à niveau Ubuntu exécutée'; fi

if [[ "$ANSIBLE_VERSION" != "$ANSIBLE_CORE_VERSION" ]]; then
    pipx install --force "$ANSIBLE_CORE_SPEC"
    change "Ansible Core $ANSIBLE_CORE_VERSION installé via pipx"
fi
export NVM_DIR="$HOME/.nvm"
if ! nvm_is_pinned; then
    install_pinned_nvm
    change "NVM $NVM_VERSION verrouillé sur ${NVM_COMMIT:0:12}"
fi
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"
if [[ "$(nvm version "$NODE_VERSION" 2>/dev/null || true)" != "v$NODE_VERSION" ]]; then
    nvm install "$NODE_VERSION"
    change "Node.js $NODE_VERSION installé"
fi
nvm alias default "$NODE_VERSION" >/dev/null
nvm use "$NODE_VERSION" >/dev/null
if ! command -v markdownlint-cli2 >/dev/null 2>&1; then npm install --global markdownlint-cli2; change 'markdownlint-cli2 installé'; fi

SYSCTL_FILE=/etc/sysctl.d/99-p5-opensearch.conf
EXPECTED_SYSCTL="vm.max_map_count=$P5_OPENSEARCH_MAX_MAP_COUNT"
if [[ ! -r "$SYSCTL_FILE" ]] || ! grep -Fxq "$EXPECTED_SYSCTL" "$SYSCTL_FILE"; then
    printf '%s\n' "$EXPECTED_SYSCTL" | sudo tee "$SYSCTL_FILE" >/dev/null
    change 'réglage OpenSearch persistant installé'
fi
sudo sysctl -w "$EXPECTED_SYSCTL" >/dev/null

bash "$SCRIPT_DIR/bootstrap-wsl2.sh" --check-only
printf '\nRésumé : déjà conformes=%s | modifications=%s\n' "$OK_COUNT" "$CHANGED"
printf 'Verdict : RUNTIME P5 CONVERGÉ DANS WSL2.\n'
