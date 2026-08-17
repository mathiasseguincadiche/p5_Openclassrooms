#!/usr/bin/env bash
# Vérifie le lab P5 dans Ubuntu WSL2 sans créer de ressource AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
cd "$PROJECT_ROOT"

show_help() {
    cat <<'HELP'
Usage: ./scripts/commands/setup.sh [--check-only]

Contrôle non destructif du runtime P5 dans Ubuntu 26.04 sous WSL2,
des outils et de l'arborescence du projet.

Windows, WSL2, son stockage et son réseau restent gérés par
mathiasseguincadiche/Windows_11_Pro_Custom.

Pour aligner uniquement les dépendances propres au P5 dans WSL2 :
  ./scripts/commands/bootstrap-wsl2.sh

Ce contrôle valide l'étape 0A. Pour le compte AWS, utilisez ensuite :
  ./scripts/commands/pre-deployment-check.sh --stage initial
HELP
}

case "${1:-}" in
    ""|--check-only) ;;
    -h|--help) show_help; exit 0 ;;
    *) printf 'Option inconnue : %s\n' "$1" >&2; show_help >&2; exit 2 ;;
esac

if [[ ! -r "$VERSIONS_FILE" ]]; then
    printf 'KO  %s absent\n' "$VERSIONS_FILE" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$VERSIONS_FILE"

AWS_PROFILE_NAME=p5-lab
if [[ -r "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    AWS_PROFILE_NAME="${AWS_PROFILE:-$AWS_PROFILE_NAME}"
fi

missing=0
ok() { printf '  OK  %s\n' "$1"; }
ko() { printf '  KO  %s\n' "$1" >&2; missing=$((missing + 1)); }

printf 'Runtime WSL2 P5\n'
set +e
bash "$SCRIPT_DIR/bootstrap-wsl2.sh" --check-only
RUNTIME_RC=$?
set -e
case "$RUNTIME_RC" in
    0) ok "runtime P5 conforme dans ${P5_EXPECTED_WSL_DISTRO:-Ubuntu} sous WSL2" ;;
    *) ko "runtime P5 non conforme dans WSL2" ;;
esac

printf '\nOutils obligatoires\n'
for command in git python3 terraform ansible-playbook aws curl jq ssh docker node npm shellcheck yamllint; do
    if command -v "$command" >/dev/null 2>&1; then
        ok "$command"
    else
        ko "$command absent"
    fi
done

if command -v node >/dev/null 2>&1; then
    if [[ "$(node --version)" == "v${NODE_VERSION}" ]]; then
        ok "Node.js ${NODE_VERSION}"
    else
        ko "Node.js ${NODE_VERSION} attendu ; $(node --version) détecté"
    fi
fi

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        ok "moteur Docker accessible dans WSL2"
    else
        ko "moteur Docker inaccessible ; terminez puis rouvrez la distribution après ajout au groupe docker"
    fi
fi

printf '\nStructure complète du dépôt\n'
required=(
    docs/00-preparation-environnement.md
    docs/00b-preparation-compte-aws.md
    docs/04-audit-non-regression.md
    docs/05-soutenance.md
    environment/aws-readiness.env.example
    environment/versions.env
    environment/wsl2/README.md
    aws/README.md
    aws/iam/p5-lab-policy.json
    aws/budgets/p5-monthly-budget.json.example
    application/angular/angular.json
    application/angular/package.json
    application/angular/package-lock.json
    application/angular/src/main.ts
    ansible/files/angular-app/index.html
    ansible/files/nginx-angular.conf
    ansible/playbooks/deploy.yml
    terraform/exercice-2/opensearch/index-template.json
    terraform/exercice-2/samples/nginx-access.log.sample
    scripts/commands/prepare-angular-artifact.sh
    scripts/commands/verify-angular-deployment.sh
    scripts/commands/generate-nginx-traffic.sh
    scripts/commands/collect-nginx-access-log.sh
    scripts/commands/import-opensearch-data.sh
    scripts/commands/verify-opensearch-data.sh
    scripts/commands/test-haproxy-roundrobin.sh
    scripts/commands/test-haproxy-failover.sh
    scripts/tools/convert-nginx-logs.py
    docs/exercices/01-terraform-ansible.md
    docs/exercices/02-opensearch.md
    docs/exercices/03-haproxy.md
    terraform/exercice-1/main.tf
    terraform/exercice-2/main.tf
    terraform/exercice-3/main.tf
)
for path in "${required[@]}"; do
    if [[ -e "$path" ]]; then
        ok "$path"
    else
        ko "$path absent"
    fi
done

printf '\nArtefact Angular\n'
if grep -q 'main-' ansible/files/angular-app/index.html \
    && find ansible/files/angular-app -maxdepth 1 -type f -name 'main-*.js' | grep -q .; then
    ok "build Angular de production versionné pour Ansible"
else
    ko "artefact Angular incomplet ou page témoin encore présente"
fi

printf '\nAWS CLI\n'
if command -v aws >/dev/null 2>&1 \
    && aws --profile "$AWS_PROFILE_NAME" sts get-caller-identity >/dev/null 2>&1; then
    ok "identité du profil $AWS_PROFILE_NAME active ; AWS Ready reste obligatoire"
else
    printf '  --  profil %s non actif ; connectez-vous avant AWS Ready\n' \
        "$AWS_PROFILE_NAME"
fi

if ! "$SCRIPT_DIR/validate.sh"; then
    missing=$((missing + 1))
fi

if ((missing > 0)); then
    printf '\n%s anomalie(s) obligatoire(s) détectée(s).\n' "$missing" >&2
    exit 1
fi
printf '\nÉtape 0A validée dans WSL2. Poursuivez avec le contrôle AWS Ready.\n'
