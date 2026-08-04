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
    if "$@"; then
        printf '✅ %s\n' "$label"
    else
        printf '❌ %s\n' "$label"
        ERRORS=$((ERRORS + 1))
    fi
}

validate_bash() {
    local script_file
    while IFS= read -r -d '' script_file; do
        bash -n "$script_file" || return 1
    done < <(find "$PROJECT_ROOT" -type f -name '*.sh' -print0)
}

validate_shellcheck() {
    local script_file
    while IFS= read -r -d '' script_file; do
        shellcheck --severity=error --external-sources --source-path=SCRIPTDIR \
            "$script_file" || return 1
    done < <(find "$PROJECT_ROOT/scripts" -type f -name '*.sh' -print0)
}

validate_terraform() {
    local module_dir
    for module_dir in \
        "$PROJECT_ROOT/terraform/exercice-1" \
        "$PROJECT_ROOT/terraform/exercice-2" \
        "$PROJECT_ROOT/terraform/exercice-3" \
        "$PROJECT_ROOT/TEMPLATES/terraform"; do
        terraform -chdir="$module_dir" init -backend=false -input=false -no-color >/dev/null || return 1
        terraform -chdir="$module_dir" validate -no-color || return 1
    done
}

validate_terraform_format() {
    terraform fmt -check -recursive "$PROJECT_ROOT/terraform" || return 1
    terraform fmt -check -recursive "$PROJECT_ROOT/TEMPLATES/terraform"
}

cd "$PROJECT_ROOT" || exit 1

run_check "Syntaxe Bash" validate_bash

if command -v shellcheck >/dev/null 2>&1; then
    run_check "ShellCheck" validate_shellcheck
fi

if command -v terraform >/dev/null 2>&1; then
    run_check "Format Terraform" validate_terraform_format
    run_check "Validation Terraform" validate_terraform
fi

if command -v yamllint >/dev/null 2>&1; then
    run_check "YAML" yamllint -c "$PROJECT_ROOT/.yamllint.yml" "$PROJECT_ROOT"
fi

if command -v ansible-playbook >/dev/null 2>&1; then
    run_check "Syntaxe Ansible" ansible-playbook --syntax-check \
        -i "$PROJECT_ROOT/ansible/inventories/hosts_aws.example" \
        "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
fi

if command -v markdownlint-cli2 >/dev/null 2>&1; then
    run_check "Markdown" markdownlint-cli2 "$PROJECT_ROOT/**/*.md"
fi

printf '\n'
if [ "$ERRORS" -eq 0 ]; then
    printf '✅ Tous les contrôles disponibles ont réussi.\n'
    exit 0
fi

printf '❌ %s contrôle(s) en échec.\n' "$ERRORS"
exit 1
