#!/usr/bin/env bash
# Vérifie la présence des trois gabarits sans inventer de preuves.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
files=(
  docs/livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md
  docs/livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md
  docs/livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md
)
printf 'Checklist des livrables P5\n\n'
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        printf '✅ %s\n' "$file"
    else
        printf '❌ %s\n' "$file"
        exit 1
    fi
done
cat <<'INFO'

À vérifier avant la remise :
- toutes les zones « preuve à insérer » sont remplacées par des preuves réelles ;
- aucun secret, identifiant AWS ou inventaire réel n'est visible ;
- l'exercice 1 montre la véritable application Angular ;
- l'exercice 2 contient exactement les trois visualisations demandées ;
- l'exercice 3 contient haproxy.cfg et la preuve de bascule ;
- le nom du ZIP et le canal GitLab/GitHub sont confirmés sur la plateforme.

Guide : docs/livrables/README.md
INFO
