#!/usr/bin/env bash
# Vérifie le contrat statique du diagnostic final sans accéder à AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
DIAGNOSTICS="$PROJECT_ROOT/scripts/commands/collect-diagnostics.sh"

[[ -f "$DIAGNOSTICS" ]]
grep -Fq 'detect_aws_check_stage()' "$DIAGNOSTICS"
grep -Fq 'terraform_state_has_resources 1' "$DIAGNOSTICS"
grep -Fq "printf 'exercice-3" "$DIAGNOSTICS"
grep -Fq 'AWS_CHECK_STAGE="$(detect_aws_check_stage)"' "$DIAGNOSTICS"
grep -Fq -- '--stage "$AWS_CHECK_STAGE"' "$DIAGNOSTICS"
grep -Fq '(?:AKIA|ASIA)' "$DIAGNOSTICS"

# Le diagnostic ne doit plus imposer le contrôle d'un environnement vierge
# lorsque le lab possède déjà un state Terraform de l'exercice 1.
if grep -Fq 'pre-deployment-check.sh" --stage initial' "$DIAGNOSTICS"; then
    printf 'KO  collect-diagnostics force encore --stage initial.\n' >&2
    exit 1
fi

printf 'Verdict : CONTRAT DE DIAGNOSTIC ADAPTATIF VALIDÉ.\n'
