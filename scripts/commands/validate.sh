#!/usr/bin/env bash
# Validation locale complète et non destructive du dépôt P5.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ERRORS=0

run_check() {
    local label="$1"
    shift
    printf '\n▶ %s\n' "$label"
    if "$@"; then
        printf '✅ %s\n' "$label"
    else
        printf '❌ %s\n' "$label"
        ERRORS=$((ERRORS + 1))
    fi
}

validate_scope() {
    [[ ! -d "$PROJECT_ROOT/TEMPLATES" ]] || return 1
    [[ ! -d "$PROJECT_ROOT/docs/exercises" ]] || return 1
    [[ ! -e "$PROJECT_ROOT/scripts/commands/bootstrap-ubuntu-server.sh" ]] || {
        printf 'Ancien wrapper bootstrap Ubuntu réintroduit.\n' >&2
        return 1
    }
    if grep -RIl --include='*.md' '```mermaid' "$PROJECT_ROOT" | grep -q .; then
        printf 'Des blocs Mermaid subsistent.\n' >&2
        return 1
    fi
    [[ "$(find "$PROJECT_ROOT/docs/exercices" -maxdepth 1 -type f -name '*.md' | wc -l)" -eq 3 ]]
}

validate_required_files() {
    local required=(
        docs/00-preparation-environnement.md
        docs/00b-preparation-compte-aws.md
        docs/04-audit-non-regression.md
        environment/versions.env
        environment/wsl2/README.md
        environment/aws-readiness.env.example
        application/angular/angular.json
        application/angular/package.json
        application/angular/package-lock.json
        application/angular/src/main.ts
        application/angular/tests/app-contract.test.mjs
        ansible/files/angular-app/index.html
        ansible/files/nginx-angular.conf
        ansible/playbooks/deploy.yml
        terraform/exercice-2/opensearch/index-template.json
        terraform/exercice-2/samples/nginx-access.log.sample
        scripts/tools/audit_non_regression.py
        scripts/tools/convert-nginx-logs.py
        scripts/tools/generer-haproxy-config.sh
        scripts/commands/sync-terraform-tfvars.sh
        scripts/commands/bootstrap-wsl2.sh
        scripts/lib/p5-platform.sh
        scripts/tests/test-wsl2-platform.sh
        scripts/commands/prepare-angular-artifact.sh
        scripts/commands/verify-angular-deployment.sh
        scripts/commands/generate-nginx-traffic.sh
        scripts/commands/collect-nginx-access-log.sh
        scripts/commands/import-opensearch-data.sh
        scripts/commands/verify-opensearch-data.sh
        scripts/commands/test-haproxy-roundrobin.sh
        scripts/commands/test-haproxy-failover.sh
        scripts/commands/destroy-aws.sh
        scripts/commands/check-aws-cleanup.sh
        scripts/tests/test-nginx-angular.sh
        scripts/tests/test-haproxy-containers.sh
        scripts/tests/test-opensearch-local.sh
    )
    local path
    for path in "${required[@]}"; do
        [[ -e "$PROJECT_ROOT/$path" ]] || {
            printf 'Élément requis absent : %s\n' "$path" >&2
            return 1
        }
    done
}

validate_permissions() {
    local scripts=(
        bootstrap-wsl2.sh
        setup.sh
        validate.sh
        pre-deployment-check.sh
        prepare-angular-artifact.sh
        verify-angular-deployment.sh
        generate-nginx-traffic.sh
        collect-nginx-access-log.sh
        import-opensearch-data.sh
        verify-opensearch-data.sh
        test-haproxy-roundrobin.sh
        test-haproxy-failover.sh
        prepare-livrables.sh
        destroy-aws.sh
        check-aws-cleanup.sh
    )
    local script
    for script in "${scripts[@]}"; do
        [[ -x "$PROJECT_ROOT/scripts/commands/$script" ]] || {
            printf 'Script non exécutable : %s\n' "$script" >&2
            return 1
        }
    done
    [[ -x "$PROJECT_ROOT/scripts/tools/generer-haproxy-config.sh" ]]
}

validate_bash() {
    while IFS= read -r -d '' file; do
        bash -n "$file" || return 1
    done < <(find "$PROJECT_ROOT/scripts" -type f -name '*.sh' -print0)
}

validate_paths() {
    grep -q '../files/angular-app/' "$PROJECT_ROOT/ansible/playbooks/deploy.yml" || return 1
    grep -q '../files/nginx-angular.conf' "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
}

validate_json() {
    python3 -m json.tool "$PROJECT_ROOT/aws/iam/p5-lab-policy.json" >/dev/null
    python3 -m json.tool \
        "$PROJECT_ROOT/aws/budgets/p5-monthly-budget.json.example" >/dev/null
    python3 -m json.tool \
        "$PROJECT_ROOT/terraform/exercice-2/opensearch/index-template.json" >/dev/null
    python3 -m json.tool "$PROJECT_ROOT/application/angular/package.json" >/dev/null
    python3 -m json.tool "$PROJECT_ROOT/application/angular/package-lock.json" >/dev/null
}

validate_non_regression() {
    python3 "$PROJECT_ROOT/scripts/tools/audit_non_regression.py"
}

validate_schemas() {
    python3 "$PROJECT_ROOT/scripts/tools/audit_non_regression.py" --schemas-only
}

validate_angular() {
    npm ci --prefix "$PROJECT_ROOT/application/angular" --no-audit --no-fund
    npm run lint --prefix "$PROJECT_ROOT/application/angular"
    npm test --prefix "$PROJECT_ROOT/application/angular"
    npm run security:dependencies --prefix "$PROJECT_ROOT/application/angular"
    npm run build --prefix "$PROJECT_ROOT/application/angular"

    local build_index build_dir
    build_index="$(find "$PROJECT_ROOT/application/angular/dist" \
        -type f -name index.html -print | head -n 1)"
    [[ -n "$build_index" ]] || return 1
    build_dir="$(dirname -- "$build_index")"
    diff -qr "$build_dir" "$PROJECT_ROOT/ansible/files/angular-app"
}

validate_opensearch_data() {
    local output
    output="$(mktemp)"
    trap 'rm -f "$output"' RETURN
    python3 -m py_compile "$PROJECT_ROOT/scripts/tools/convert-nginx-logs.py"
    python3 "$PROJECT_ROOT/scripts/tools/convert-nginx-logs.py" \
        "$PROJECT_ROOT/terraform/exercice-2/samples/nginx-access.log.sample" \
        --output "$output"
    python3 - "$output" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

lines = Path(sys.argv[1]).read_text(encoding='utf-8').splitlines()
if len(lines) != 128:
    raise SystemExit(f'128 lignes Bulk attendues, {len(lines)} trouvées')
documents = [json.loads(line) for line in lines[1::2]]
if len(documents) != 64:
    raise SystemExit('64 documents attendus')
methods = {doc['http_method'] for doc in documents}
paths = {doc['url_path'] for doc in documents}
buckets = {
    (stamp.date().isoformat(), 0 if stamp.hour < 12 else 12)
    for stamp in (datetime.fromisoformat(doc['@timestamp']) for doc in documents)
}
if len(methods) < 3 or len(paths) < 5 or len(buckets) < 4:
    raise SystemExit('Échantillon insuffisant pour les trois visualisations')
PY
}

validate_terraform() {
    local module
    for module in exercice-1 exercice-2 exercice-3; do
        terraform -chdir="$PROJECT_ROOT/terraform/$module" \
            init -backend=false -input=false -no-color >/dev/null || return 1
        terraform -chdir="$PROJECT_ROOT/terraform/$module" validate -no-color || return 1
    done
}

cd "$PROJECT_ROOT" || exit 1
run_check 'Périmètre : trois exercices et aucun héritage obsolète' validate_scope
run_check 'Fichiers critiques du parcours' validate_required_files
run_check 'Contrat exécutable de non-régression' validate_non_regression
run_check 'Contrat plateforme WSL2' bash "$PROJECT_ROOT/scripts/tests/test-wsl2-platform.sh"
run_check 'Permissions exécutables des scripts actifs' validate_permissions
run_check 'Chemins Ansible' validate_paths
run_check 'JSON du projet' validate_json
run_check 'Six schémas SVG adaptés au README' validate_schemas
run_check 'Syntaxe Bash' validate_bash
run_check 'Données OpenSearch reproductibles' validate_opensearch_data
run_check 'Structure des livrables' "$SCRIPT_DIR/prepare-livrables.sh" --structure-only

if command -v shellcheck >/dev/null 2>&1; then
    run_check 'ShellCheck' bash -c \
        'find scripts -type f -name "*.sh" -print0 | xargs -0 -r shellcheck --severity=error'
fi
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    run_check 'Angular : tests, lint, audit et build reproductible' validate_angular
fi
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    if [[ -d "$PROJECT_ROOT/application/angular/dist" ]]; then
        run_check 'Intégration Angular + NGINX' \
            bash "$PROJECT_ROOT/scripts/tests/test-nginx-angular.sh"
    fi
    run_check 'HAProxy : round-robin, panne et reprise' \
        bash "$PROJECT_ROOT/scripts/tests/test-haproxy-containers.sh"
    if [[ "${P5_FULL_INTEGRATION:-0}" == 1 ]] \
        && command -v terraform >/dev/null 2>&1; then
        run_check 'OpenSearch local complet' \
            bash "$PROJECT_ROOT/scripts/tests/test-opensearch-local.sh"
    fi
fi
if command -v terraform >/dev/null 2>&1; then
    run_check 'Format Terraform' terraform fmt -check -recursive "$PROJECT_ROOT/terraform"
    run_check 'Validation Terraform' validate_terraform
fi
if command -v yamllint >/dev/null 2>&1; then
    run_check 'YAML' yamllint -c "$PROJECT_ROOT/.yamllint.yml" "$PROJECT_ROOT"
fi
if command -v ansible-playbook >/dev/null 2>&1; then
    run_check 'Syntaxe Ansible' ansible-playbook --syntax-check \
        -i "$PROJECT_ROOT/ansible/inventories/hosts_aws.example" \
        "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
fi
if command -v markdownlint-cli2 >/dev/null 2>&1; then
    run_check 'Markdown' markdownlint-cli2 '**/*.md'
fi

printf '\n'
if [[ "$ERRORS" -eq 0 ]]; then
    printf '✅ Tous les contrôles disponibles ont réussi.\n'
    if [[ "${P5_FULL_INTEGRATION:-0}" != 1 ]]; then
        printf 'ℹ️  Utilisez P5_FULL_INTEGRATION=1 pour inclure OpenSearch local.\n'
    fi
    exit 0
fi
printf '❌ %s contrôle(s) en échec.\n' "$ERRORS"
exit 1
