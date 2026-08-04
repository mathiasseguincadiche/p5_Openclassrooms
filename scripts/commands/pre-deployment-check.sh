#!/usr/bin/env bash
# Contrôle non destructif à exécuter avant le premier terraform apply.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ERRORS=0
WARNINGS=0

ok() { printf '  OK  %s\n' "$1"; }
warn() { printf '  AVERTISSEMENT  %s\n' "$1"; WARNINGS=$((WARNINGS + 1)); }
ko() { printf '  KO  %s\n' "$1" >&2; ERRORS=$((ERRORS + 1)); }

cd "$PROJECT_ROOT" || exit 1
printf 'Contrôle pré-déploiement P5 AWS\n\n'

printf 'Système\n'
if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "26.04" ]]; then
        ok "Ubuntu Server 26.04 détecté"
    else
        warn "environnement prévu pour Ubuntu Server 26.04, détecté : ${PRETTY_NAME:-inconnu}"
    fi
else
    ko "/etc/os-release absent"
fi

printf '\nOutils obligatoires\n'
for command in git python3 terraform ansible-playbook aws curl jq ssh; do
    if command -v "$command" >/dev/null 2>&1; then
        ok "$command"
    else
        ko "$command absent"
    fi
done

printf '\nOutils du lab\n'
for command in docker node npm shellcheck yamllint; do
    if command -v "$command" >/dev/null 2>&1; then
        ok "$command"
    else
        ko "$command absent"
    fi
done

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        ok "moteur Docker accessible"
    else
        ko "Docker installé mais inaccessible ; reconnectez-vous après ajout au groupe docker"
    fi
fi

printf '\nIdentité AWS\n'
if command -v aws >/dev/null 2>&1 && aws sts get-caller-identity >/dev/null 2>&1; then
    AWS_ACCOUNT="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
    AWS_ARN="$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)"
    ok "compte ${AWS_ACCOUNT}, identité ${AWS_ARN}"
else
    ko "aucune identité AWS active ; définissez AWS_PROFILE ou configurez un profil"
fi

printf '\nClé SSH du lab\n'
KEY_PATH="${P5_SSH_KEY_PATH:-$HOME/.ssh/p5-key}"
if [[ -f "$KEY_PATH" && -f "${KEY_PATH}.pub" ]]; then
    KEY_MODE="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || true)"
    if [[ "$KEY_MODE" == "600" ]]; then
        ok "$KEY_PATH protégé en 600"
    else
        ko "$KEY_PATH doit être protégé avec chmod 600"
    fi
else
    ko "paire ${KEY_PATH} et ${KEY_PATH}.pub absente"
fi

printf '\nVariables Terraform locales\n'
for module in exercice-1 exercice-2 exercice-3; do
    if [[ -f "terraform/${module}/terraform.tfvars" ]]; then
        ok "terraform/${module}/terraform.tfvars"
    else
        warn "créez terraform/${module}/terraform.tfvars depuis le fichier .example"
    fi
done

printf '\nApplication Angular\n'
if [[ -f application/angular/package.json ]]; then
    ok "source Angular présente dans application/angular"
else
    warn "starter Angular absent ; copiez-le dans application/angular avant la preuve finale"
fi
if [[ -f ansible/files/angular-app/index.html ]]; then
    ok "artefact déployable présent pour Ansible"
else
    ko "ansible/files/angular-app/index.html absent"
fi

printf '\nValidation du dépôt\n'
if "$SCRIPT_DIR/validate.sh"; then
    ok "contrôles locaux disponibles réussis"
else
    ko "au moins un contrôle local a échoué"
fi

printf '\nSynthèse : %s erreur(s), %s avertissement(s).\n' "$ERRORS" "$WARNINGS"
if (( ERRORS > 0 )); then
    printf 'Verdict : environnement non prêt pour terraform apply.\n' >&2
    exit 1
fi
printf 'Verdict : environnement techniquement prêt. Relisez le plan et les coûts avant apply.\n'
