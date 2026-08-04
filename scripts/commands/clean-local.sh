#!/usr/bin/env bash
# Supprime uniquement les artefacts locaux reproductibles du projet.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

modules=(
    "$PROJECT_ROOT/terraform/exercice-1"
    "$PROJECT_ROOT/terraform/exercice-2"
    "$PROJECT_ROOT/terraform/exercice-3"
    "$PROJECT_ROOT/TEMPLATES/terraform"
)

printf 'Nettoyage des artefacts locaux reproductibles...\n'

for module in "${modules[@]}"; do
    if [ -d "$module" ]; then
        rm -rf -- "$module/.terraform"
        rm -f -- "$module/tfplan" "$module"/*.tfplan
    fi
done

rm -f -- "$PROJECT_ROOT/scripts/haproxy.cfg"

printf '✅ Artefacts locaux supprimés. Les states et tfvars ont été conservés.\n'
