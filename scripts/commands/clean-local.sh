#!/usr/bin/env bash
# Supprime uniquement les artefacts locaux régénérables du dépôt.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

find terraform TEMPLATES/terraform -type d -name .terraform -prune -exec rm -rf {} +
find terraform TEMPLATES/terraform -type f \
    \( -name '*.tfstate' -o -name '*.tfstate.*' -o -name '*.tfplan' -o -name 'tfplan' \) \
    -delete
find . -type d -name '__pycache__' -prune -exec rm -rf {} +
find . -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete
rm -f scripts/haproxy.cfg

printf '✅ Artefacts locaux supprimés. Aucune ressource AWS n’a été modifiée.\n'
