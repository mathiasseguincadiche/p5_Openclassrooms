#!/usr/bin/env bash
# Contrôle non destructif à exécuter avant un déploiement AWS.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

printf '==========================================\n'
printf '  TEST PRÉ-DÉPLOIEMENT - P5\n'
printf '==========================================\n\n'

required_files=(
    terraform/exercice-1/main.tf
    terraform/exercice-2/main.tf
    terraform/exercice-3/main.tf
    ansible/playbooks/deploy.yml
    scripts/validate.sh
    scripts/runbook.sh
    scripts/phase-5-nettoyage.sh
)

for required_file in "${required_files[@]}"; do
    if [ ! -f "$required_file" ]; then
        printf '❌ Fichier requis absent : %s\n' "$required_file" >&2
        exit 1
    fi
done

if [ ! -f "$HOME/.ssh/p5-key" ] || [ ! -f "$HOME/.ssh/p5-key.pub" ]; then
    printf '❌ La paire de clés ~/.ssh/p5-key est absente.\n' >&2
    printf '   Créez-la avec : ssh-keygen -t ed25519 -f ~/.ssh/p5-key\n' >&2
    exit 1
fi

if [ "$(stat -c %a "$HOME/.ssh/p5-key")" != "600" ]; then
    printf '❌ La clé privée doit avoir le mode 600.\n' >&2
    exit 1
fi

./scripts/phase-0-preparation.sh --check-only
./scripts/validate.sh

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    printf '❌ AWS CLI ne peut pas vérifier l’identité active. Utilisez aws configure ou un profil/SSO.\n' >&2
    exit 1
fi

for module in exercice-1 exercice-2 exercice-3; do
    if [ ! -f "terraform/$module/terraform.tfvars" ]; then
        printf '⚠️  terraform/%s/terraform.tfvars reste à créer depuis le fichier .example.\n' "$module"
    fi
done

if [ -z "${HAPROXY_STATS_PASSWORD:-}" ]; then
    printf '⚠️  Définissez HAPROXY_STATS_PASSWORD avant la Phase 3.\n'
fi

printf '\n✅ Les contrôles préalables non destructifs ont réussi.\n'
printf 'Relisez chaque terraform plan et les coûts AWS avant apply.\n'
