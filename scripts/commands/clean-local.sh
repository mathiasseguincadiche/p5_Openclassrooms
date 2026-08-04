#!/usr/bin/env bash
# Nettoyage local prudent ; conserve les états Terraform nécessaires au destroy.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

find terraform -type d -name .terraform -prune -exec rm -rf {} +
find terraform -type f \
    \( -name 'tfplan' -o -name '*.tfplan' \) -delete
rm -f ansible/inventories/hosts_aws
rm -f /tmp/p5-haproxy.cfg /tmp/opensearch_endpoint.txt /tmp/kibana_url.txt

cat <<'INFO'
✅ Artefacts reproductibles supprimés. Aucune ressource AWS n’a été détruite.

Les fichiers terraform.tfstate sont volontairement conservés : ils sont
nécessaires pour exécuter terraform destroy sans orpheliner les ressources.
INFO
