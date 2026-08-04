#!/usr/bin/env bash
# Contrôle les trois livrables sans inventer de preuve d'exécution.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
MODE="strict"

show_help() {
    cat <<'HELP'
Usage: prepare-livrables.sh [--structure-only]

Sans option, le contrôle échoue tant que des marqueurs de preuve à compléter
subsistent. --structure-only vérifie uniquement les fichiers, sections et
garde-fous ; ce mode est utilisé par la CI avant l'exécution réelle du lab.
HELP
}

case "${1:-}" in
    "") ;;
    --structure-only) MODE="structure" ;;
    -h|--help) show_help; exit 0 ;;
    *) printf 'Option inconnue : %s\n' "$1" >&2; show_help >&2; exit 2 ;;
esac

cd "$PROJECT_ROOT"

livrable_1="docs/livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md"
livrable_2="docs/livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md"
livrable_3="docs/livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md"
files=("$livrable_1" "$livrable_2" "$livrable_3")
errors=0

ok() { printf '  OK  %s\n' "$1"; }
ko() { printf '  KO  %s\n' "$1" >&2; errors=$((errors + 1)); }

printf 'Checklist des livrables P5 — mode %s\n\n' "$MODE"
for file in "${files[@]}"; do
    [[ -f "$file" ]] && ok "$file" || ko "$file absent"
done

check_headings() {
    local file="$1"
    shift
    local heading
    for heading in "$@"; do
        grep -Fqx "$heading" "$file" \
            && ok "$(basename "$file") : $heading" \
            || ko "$(basename "$file") : section absente $heading"
    done
}

if ((errors == 0)); then
    check_headings "$livrable_1" \
        '# Livrable 1 — Terraform, Ansible, NGINX et application Angular' \
        '## 3. Preuves Terraform' \
        '## 4. Preuves Ansible' \
        "## 5. Preuve de l'application" \
        '## 6. Nettoyage'
    check_headings "$livrable_2" \
        '# Livrable 2 — Dashboard ELK / OpenSearch' \
        '## 3. Visualisation 1 — Donut des verbes HTTP' \
        '## 4. Visualisation 2 — Octets par tranches de 12 heures' \
        '## 5. Visualisation 3 — Top 5 des requêtes par 12 heures' \
        '## 6. Dashboard complet' \
        '## 7. Nettoyage'
    check_headings "$livrable_3" \
        '# Livrable 3 — HAProxy et `nginxdemos/hello`' \
        '## 2. Fichier `haproxy.cfg`' \
        '## 3. Validation de la configuration' \
        '## 4. Répartition de charge' \
        '## 5. Panne et continuité de service' \
        '## 6. Nettoyage'
fi

printf '\nComposants associés aux preuves\n'
required=(
    application/angular/package-lock.json
    ansible/files/angular-app/index.html
    scripts/commands/verify-angular-deployment.sh
    scripts/commands/generate-nginx-traffic.sh
    scripts/commands/collect-nginx-access-log.sh
    scripts/commands/import-opensearch-data.sh
    scripts/commands/verify-opensearch-data.sh
    scripts/commands/test-haproxy-roundrobin.sh
    scripts/commands/test-haproxy-failover.sh
    scripts/commands/check-aws-cleanup.sh
    proofs/README.md
)
for path in "${required[@]}"; do
    [[ -e "$path" ]] && ok "$path" || ko "$path absent"
done

printf '\nRecherche de secrets\n'
if grep -REn \
    '(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|BEGIN ([A-Z ]+ )?PRIVATE KEY)' \
    docs/livrables proofs/README.md; then
    ko 'secret ou clé privée potentielle détecté dans les livrables'
else
    ok 'aucune clé AWS ou clé privée détectée'
fi

if [[ "$MODE" == "strict" ]]; then
    printf '\nComplétude des preuves\n'
    placeholder_pattern='(Gabarit à compléter|[Pp]reuve(s)? (réelle(s)? )?à insérer|[Cc]apture réelle à insérer|À joindre)'
    for file in "${files[@]}"; do
        if grep -Eq "$placeholder_pattern" "$file"; then
            ko "$(basename "$file") contient encore des marqueurs de preuve"
        else
            ok "$(basename "$file") ne contient plus de marqueur de preuve"
        fi
    done
fi

printf '\n'
if ((errors > 0)); then
    printf 'Verdict : LIVRABLES INCOMPLETS — %s anomalie(s).\n' "$errors" >&2
    exit 1
fi

if [[ "$MODE" == "structure" ]]; then
    printf 'Verdict : STRUCTURE DES LIVRABLES VALIDE.\n'
else
    printf 'Verdict : LIVRABLES PRÊTS POUR RELECTURE FINALE.\n'
fi
