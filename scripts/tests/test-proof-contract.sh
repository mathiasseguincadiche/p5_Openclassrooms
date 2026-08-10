#!/usr/bin/env bash
# Vérifie le contrat : chaque étape journalisée produit une preuve traçable.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

export P5_PROJECT_ROOT="$PROJECT_ROOT"
export P5_RUN_ID="proof-contract-test"
export P5_LOG_DIR="$TMP_DIR/logs"
export P5_STEP_PROOF_DIR="$TMP_DIR/proofs"
export P5_SESSION_ACTIVE=1

# shellcheck source=../lib/p5-runtime.sh
source "$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
p5_session_start 'proof-contract'

printf 'Test étape réussie\n'
p5_run_step 'success-step' 'Étape de preuve réussie' bash -c 'printf "preuve-ok\\n"'
[[ -f "$P5_LOG_DIR/01-success-step.log" ]]
[[ -f "$P5_STEP_PROOF_DIR/01-success-step.log" ]]
grep -Fq 'preuve-ok' "$P5_STEP_PROOF_DIR/01-success-step.log"
grep -Fq $'01\tsuccess-step\tVALIDE\t0' "$P5_STEP_PROOF_MANIFEST"

printf 'Test étape en échec\n'
set +e
(
    p5_run_step 'failure-step' 'Étape de preuve en échec' \
        bash -c 'printf "preuve-ko\\n"; exit 7'
)
RC=$?
set -e
[[ "$RC" -eq 7 ]]
[[ -f "$P5_STEP_PROOF_DIR/02-failure-step.log" ]]
grep -Fq 'preuve-ko' "$P5_STEP_PROOF_DIR/02-failure-step.log"
grep -Fq $'02\tfailure-step\tECHEC\t7' "$P5_STEP_PROOF_MANIFEST"

grep -Eq $'^[^\t]+\t01\tsuccess-step\tVALIDE\t0\t[0-9]+\t[0-9a-f]{64}\t01-success-step.log\t' \
    "$P5_STEP_PROOF_MANIFEST"

printf 'Vérification des preuves AWS automatiques\n'
AWS_PROOF="$PROJECT_ROOT/scripts/commands/verify-aws-exercise-state.sh"
[[ -f "$AWS_PROOF" ]] || {
    printf 'KO  verify-aws-exercise-state.sh est absent.\n' >&2
    exit 1
}
bash -n "$AWS_PROOF"
grep -Fq -- '--exercise 1' "$PROJECT_ROOT/scripts/commands/collect-nginx-access-log.sh"
grep -Fq -- '--exercise 2' "$PROJECT_ROOT/scripts/commands/verify-opensearch-data.sh"
grep -Fq -- '--exercise 3' "$PROJECT_ROOT/scripts/commands/test-haproxy-failover.sh"
grep -Fq 'ÉTAT AWS EXERCICE 1 VALIDÉ — EC2 RUNNING' "$AWS_PROOF"
grep -Fq 'ÉTAT AWS EXERCICE 2 VALIDÉ — OPENSEARCH ACTIF' "$AWS_PROOF"
grep -Fq 'ÉTAT AWS EXERCICE 3 VALIDÉ — 3 EC2 RUNNING' "$AWS_PROOF"

printf '\nVerdict : CONTRAT DE PREUVES AUTOMATIQUES VALIDÉ.\n'
