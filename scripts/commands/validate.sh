#!/usr/bin/env bash
# Validation locale complète du dépôt P5.
set -uo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ERRORS=0
run_check() {
    local label="$1"
    shift
    printf '\n▶ %s\n' "$label"
    if "$@"; then printf '✅ %s\n' "$label"; else printf '❌ %s\n' "$label"; ERRORS=$((ERRORS + 1)); fi
}
validate_bash() {
    while IFS= read -r -d '' file; do bash -n "$file" || return 1; done < <(find "$PROJECT_ROOT/scripts" -type f -name '*.sh' -print0)
}
validate_scope() {
    [[ ! -d "$PROJECT_ROOT/TEMPLATES" ]] || return 1
    [[ ! -d "$PROJECT_ROOT/docs/exercises" ]] || return 1
    if grep -RIl --include='*.md' '```mermaid' "$PROJECT_ROOT" | grep -q .; then
        printf 'Des blocs Mermaid subsistent.\n' >&2
        return 1
    fi
    [[ "$(find "$PROJECT_ROOT/docs/exercices" -maxdepth 1 -type f -name '*.md' | wc -l)" -eq 3 ]]
}
validate_paths() {
    [[ -d "$PROJECT_ROOT/ansible/files/angular-app" ]] || return 1
    [[ -f "$PROJECT_ROOT/ansible/files/nginx-angular.conf" ]] || return 1
    grep -q '../files/angular-app/' "$PROJECT_ROOT/ansible/playbooks/deploy.yml" || return 1
    grep -q '../files/nginx-angular.conf' "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
}
validate_svg() {
    python3 - "$PROJECT_ROOT" <<'PYXML'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
root = Path(sys.argv[1])
files = sorted((root / 'docs/schemas').glob('*.svg'))
if len(files) != 4:
    raise SystemExit(f'4 schémas SVG attendus, {len(files)} trouvés')
for file in files:
    ET.parse(file)
PYXML
}
validate_terraform() {
    local module
    for module in exercice-1 exercice-2 exercice-3; do
        terraform -chdir="$PROJECT_ROOT/terraform/$module" init -backend=false -input=false -no-color >/dev/null || return 1
        terraform -chdir="$PROJECT_ROOT/terraform/$module" validate -no-color || return 1
    done
}
cd "$PROJECT_ROOT" || exit 1
run_check 'Périmètre : trois exercices et aucun Mermaid' validate_scope
run_check 'Chemins Ansible' validate_paths
run_check 'Syntaxe des schémas SVG' validate_svg
run_check 'Syntaxe Bash' validate_bash
if command -v shellcheck >/dev/null 2>&1; then
    run_check 'ShellCheck' bash -c 'find scripts -type f -name "*.sh" -print0 | xargs -0 -r shellcheck --severity=error'
fi
if command -v terraform >/dev/null 2>&1; then
    run_check 'Format Terraform' terraform fmt -check -recursive "$PROJECT_ROOT/terraform"
    run_check 'Validation Terraform' validate_terraform
fi
if command -v yamllint >/dev/null 2>&1; then run_check 'YAML' yamllint -c "$PROJECT_ROOT/.yamllint.yml" "$PROJECT_ROOT"; fi
if command -v ansible-playbook >/dev/null 2>&1; then
    run_check 'Syntaxe Ansible' ansible-playbook --syntax-check -i "$PROJECT_ROOT/ansible/inventories/hosts_aws.example" "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
fi
if command -v markdownlint-cli2 >/dev/null 2>&1; then run_check 'Markdown' markdownlint-cli2 '**/*.md'; fi
printf '\n'
if [[ "$ERRORS" -eq 0 ]]; then printf '✅ Tous les contrôles disponibles ont réussi.\n'; exit 0; fi
printf '❌ %s contrôle(s) en échec.\n' "$ERRORS"
exit 1
