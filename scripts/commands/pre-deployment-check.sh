#!/usr/bin/env bash
# Contrôle non destructif à exécuter avant chaque étape Terraform.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"
STAGE="initial"
ERRORS=0
WARNINGS=0

show_help() {
    cat <<'HELP'
Usage: pre-deployment-check.sh [options]

Options:
  --stage ETAPE     initial, exercice-2 ou exercice-3
  --config CHEMIN   fichier aws-readiness.env à utiliser
  -h, --help        afficher cette aide

Le contrôle ne crée et ne modifie aucune ressource AWS.
HELP
}

while (($# > 0)); do
    case "$1" in
        --stage)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --stage.\n' >&2; exit 2; }
            STAGE="$2"
            shift 2
            ;;
        --config)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --config.\n' >&2; exit 2; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            printf 'Option inconnue : %s\n' "$1" >&2
            show_help >&2
            exit 2
            ;;
    esac
done

case "$STAGE" in
    initial|exercice-2|exercice-3) ;;
    *) printf 'Étape inconnue : %s\n' "$STAGE" >&2; exit 2 ;;
esac

ok() { printf '  OK  %s\n' "$1"; }
warn() { printf '  AVERTISSEMENT  %s\n' "$1"; WARNINGS=$((WARNINGS + 1)); }
ko() { printf '  KO  %s\n' "$1" >&2; ERRORS=$((ERRORS + 1)); }

cd "$PROJECT_ROOT" || exit 1
if [[ ! -r "$VERSIONS_FILE" ]]; then
    printf 'Fichier de versions absent : %s\n' "$VERSIONS_FILE" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$VERSIONS_FILE"

printf 'Contrôle pré-déploiement P5 — %s\n\n' "$STAGE"

printf 'Système et versions\n'
if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "$P5_UBUNTU_VERSION_ID" ]]; then
        ok "Ubuntu Server $P5_UBUNTU_VERSION_ID"
    else
        ko "Ubuntu Server $P5_UBUNTU_VERSION_ID attendu ; ${PRETTY_NAME:-inconnu} détecté"
    fi
else
    ko "/etc/os-release absent"
fi

for command in git python3 terraform ansible-playbook aws curl jq ssh docker node npm shellcheck yamllint; do
    if command -v "$command" >/dev/null 2>&1; then
        ok "$command"
    else
        ko "$command absent"
    fi
done

if command -v node >/dev/null 2>&1; then
    [[ "$(node --version)" == "v${NODE_VERSION}" ]] \
        && ok "Node.js ${NODE_VERSION}" \
        || ko "Node.js ${NODE_VERSION} attendu ; $(node --version) détecté"
fi

if command -v docker >/dev/null 2>&1; then
    docker info >/dev/null 2>&1 \
        && ok "moteur Docker accessible" \
        || ko "Docker inaccessible ; reconnectez-vous après ajout au groupe docker"
fi

printf '\nClé SSH du lab\n'
KEY_PATH="${P5_SSH_KEY_PATH:-$HOME/.ssh/p5-key}"
if [[ -f "$KEY_PATH" && -f "${KEY_PATH}.pub" ]]; then
    KEY_MODE="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || true)"
    [[ "$KEY_MODE" == "600" ]] \
        && ok "$KEY_PATH protégé en 600" \
        || ko "$KEY_PATH doit être protégé avec chmod 600"
else
    ko "paire ${KEY_PATH} et ${KEY_PATH}.pub absente"
fi

printf '\nVariables Terraform locales\n'
for module in exercice-1 exercice-2 exercice-3; do
    [[ -f "terraform/${module}/terraform.tfvars" ]] \
        && ok "terraform/${module}/terraform.tfvars" \
        || ko "créez terraform/${module}/terraform.tfvars depuis le fichier .example"
done

printf '\nApplication Angular et NGINX\n'
angular_files=(
    application/angular/angular.json
    application/angular/package.json
    application/angular/package-lock.json
    application/angular/src/main.ts
    ansible/files/angular-app/index.html
    ansible/files/nginx-angular.conf
)
for path in "${angular_files[@]}"; do
    [[ -f "$path" ]] && ok "$path" || ko "$path absent"
done
if grep -q 'main-' ansible/files/angular-app/index.html \
    && find ansible/files/angular-app -maxdepth 1 -type f -name 'main-*.js' | grep -q .; then
    ok "build Angular réel prêt pour Ansible"
else
    ko "build Angular versionné incomplet"
fi

if [[ "$STAGE" == "exercice-2" ]]; then
    printf '\nChaîne OpenSearch\n'
    for path in \
        terraform/exercice-2/opensearch/index-template.json \
        terraform/exercice-2/samples/nginx-access.log.sample \
        scripts/tools/convert-nginx-logs.py \
        scripts/commands/generate-nginx-traffic.sh \
        scripts/commands/collect-nginx-access-log.sh \
        scripts/commands/import-opensearch-data.sh \
        scripts/commands/verify-opensearch-data.sh; do
        [[ -f "$path" ]] && ok "$path" || ko "$path absent"
    done
    python3 -m py_compile scripts/tools/convert-nginx-logs.py \
        && ok "convertisseur NGINX compilable" \
        || ko "convertisseur NGINX invalide"
fi

if [[ "$STAGE" == "exercice-3" ]]; then
    printf '\nChaîne HAProxy\n'
    for path in \
        scripts/tools/generer-haproxy-config.sh \
        scripts/commands/test-haproxy-roundrobin.sh \
        scripts/commands/test-haproxy-failover.sh; do
        [[ -f "$path" ]] && ok "$path" || ko "$path absent"
    done
fi

printf '\nValidation du dépôt\n'
if "$SCRIPT_DIR/validate.sh"; then
    ok "contrôles locaux disponibles réussis"
else
    ko "au moins un contrôle local a échoué"
fi

printf '\nValidation AWS Ready\n'
if "$SCRIPT_DIR/check-aws-readiness.sh" --config "$CONFIG_FILE" --stage "$STAGE"; then
    ok "verdict GO AWS obtenu"
else
    ko "contrôle AWS Ready en échec"
fi

printf '\nSynthèse : %s erreur(s), %s avertissement(s).\n' "$ERRORS" "$WARNINGS"
if ((ERRORS > 0)); then
    printf 'Verdict : environnement non prêt pour Terraform.\n' >&2
    exit 1
fi

printf 'Verdict : GO TERRAFORM — relisez le plan et les coûts avant apply.\n'
