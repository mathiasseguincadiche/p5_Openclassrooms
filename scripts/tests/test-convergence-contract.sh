#!/usr/bin/env bash
# Vérifie que les composants persistants du P5 observent avant de modifier.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
CONFIG_FILE="$TMP_DIR/aws-readiness.env"

cleanup() {
    rm -rf "$TMP_DIR"
    rm -f \
        "$PROJECT_ROOT/terraform/exercice-1/terraform.tfvars" \
        "$PROJECT_ROOT/terraform/exercice-2/terraform.tfvars" \
        "$PROJECT_ROOT/terraform/exercice-3/terraform.tfvars"
}
trap cleanup EXIT
cd "$PROJECT_ROOT"

printf 'Contrat statique de convergence\n'
grep -Fq -- '--check-only' scripts/commands/bootstrap-ubuntu-server.sh
grep -Fq 'apt full-upgrade non exécuté' scripts/commands/bootstrap-ubuntu-server.sh
grep -Fq 'systemd-detect-virt' scripts/commands/bootstrap-ubuntu-server.sh
grep -Fq 'P5_EXPECTED_VM_NAME' scripts/commands/bootstrap-ubuntu-server.sh
grep -Fq 'P5_EXPECTED_VM_NAME=ubuntu-devops' environment/versions.env
test -s environment/vm-devops/README.md
test ! -e environment/wsl2
grep -Fq -- '-detailed-exitcode' scripts/commands/p5.sh
grep -Fq 'infrastructure déjà conforme — aucun apply' scripts/commands/p5.sh
grep -Fq 'Déjà synchronisé' scripts/commands/sync-terraform-tfvars.sh
grep -Fq 'Inventaire déjà conforme' scripts/commands/generate-ansible-inventory.sh
grep -Fq 'Artefact Angular déjà conforme' scripts/commands/prepare-angular-artifact.sh
grep -Fq 'Bulk ignoré' scripts/commands/import-opensearch-data.sh
grep -Fq 'GARDE-FOU AWS DÉJÀ CONFORME' scripts/commands/setup-aws-guardrails.sh
grep -Fq 'état déjà vide — destroy ignoré' scripts/commands/destroy-aws.sh
grep -Fq 'ÉTAT P5 OBSERVÉ DANS LA VM' scripts/commands/inspect-state.sh
grep -Fq '.p5/' .gitignore
printf '  OK  branches de non-mutation et frontière VM/P5 présentes.\n'

printf '\nRéexécution réelle de la convergence tfvars\n'
cp environment/aws-readiness.env.example "$CONFIG_FILE"
sed -i \
    -e 's/P5_EXPECTED_ACCOUNT_ID=000000000000/P5_EXPECTED_ACCOUNT_ID=123456789012/' \
    -e 's#P5_PUBLIC_IP_CIDR=203.0.113.10/32#P5_PUBLIC_IP_CIDR=198.51.100.42/32#' \
    -e 's/P5_BUDGET_EMAIL=remplacer@example.com/P5_BUDGET_EMAIL=p5@example.com/' \
    "$CONFIG_FILE"

bash scripts/commands/sync-terraform-tfvars.sh --config "$CONFIG_FILE" --apply \
    > "$TMP_DIR/first.log"
for exercise in 1 2 3; do
    stat -c '%Y:%s' "terraform/exercice-$exercise/terraform.tfvars" \
        > "$TMP_DIR/ex$exercise.before"
done
sleep 1
bash scripts/commands/sync-terraform-tfvars.sh --config "$CONFIG_FILE" --apply \
    > "$TMP_DIR/second.log"
[[ "$(grep -c 'Déjà synchronisé' "$TMP_DIR/second.log")" -eq 3 ]]
for exercise in 1 2 3; do
    [[ "$(stat -c '%Y:%s' "terraform/exercice-$exercise/terraform.tfvars")" \
        == "$(cat "$TMP_DIR/ex$exercise.before")" ]]
    [[ "$(stat -c '%a' "terraform/exercice-$exercise/terraform.tfvars")" == 600 ]]
done
printf '  OK  deuxième passage tfvars : zéro réécriture.\n'

chmod 644 terraform/exercice-1/terraform.tfvars
bash scripts/commands/sync-terraform-tfvars.sh --config "$CONFIG_FILE" --apply \
    > "$TMP_DIR/permissions.log"
grep -Fq 'Corrigé (permissions)' "$TMP_DIR/permissions.log"
[[ "$(stat -c '%a' terraform/exercice-1/terraform.tfvars)" == 600 ]]
printf '  OK  dérive de permissions corrigée sans réécrire les autres fichiers.\n'

printf '\nNumérotation du runtime avec codes contrôlés\n'
export P5_PROJECT_ROOT="$PROJECT_ROOT"
export P5_RUN_ID="convergence-contract-test"
export P5_LOG_DIR="$TMP_DIR/runtime-logs"
export P5_STEP_PROOF_DIR="$TMP_DIR/runtime-proofs"
export P5_STABLE_LOG_ROOT="$TMP_DIR/stable-logs"
export P5_SESSION_ACTIVE=1
# shellcheck source=../lib/p5-runtime.sh
source scripts/lib/p5-runtime.sh
p5_session_start 'convergence-contract'
p5_run_step 'first' 'première étape' true >/dev/null
p5_run_step_allow '0 2' 'second' 'deuxième étape' true >/dev/null
[[ -f "$P5_LOG_DIR/01-first.log" ]]
[[ -f "$P5_LOG_DIR/02-second.log" ]]
[[ -f "$P5_STEP_PROOF_DIR/01-first.log" ]]
[[ -f "$P5_STEP_PROOF_DIR/02-second.log" ]]
printf '  OK  journaux et preuves numérotés de manière stable.\n'
[[ -f "$P5_STABLE_LOG_ROOT/external/first.log" ]]
[[ -f "$P5_EVENT_LOG" ]]
[[ -f "$P5_SUMMARY_LOG" ]]
grep -Fq 'validated_steps=2' "$P5_SUMMARY_LOG"
printf '  OK  journal persistant et résumé factuel du run présents.\n'

PREVIEW="$(p5_command_preview command --api-token supersecret-value)"
! grep -Fq 'supersecret-value' <<<"$PREVIEW"
grep -Fq 'REDACTED' <<<"$PREVIEW"
p5_run_step 'secret-output' 'sortie sensible' \
    bash -c 'printf "AWS_SECRET_ACCESS_KEY=supersecret-value\\n"' >/dev/null
! grep -Fq 'supersecret-value' "$P5_LAST_STEP_LOG"
grep -Fq '<REDACTED>' "$P5_LAST_STEP_LOG"
printf '  OK  aperçu de commande et sorties sensibles nettoyés avant journalisation.\n'

grep -Fq "CLASSIFICATION='FIRST_RUN'" scripts/commands/inspect-state.sh
grep -Fq "CLASSIFICATION='PARTIAL'" scripts/commands/inspect-state.sh
grep -Fq "CLASSIFICATION='READY_CANDIDATE'" scripts/commands/inspect-state.sh
printf '  OK  classification machine-first explicite.\n'

printf '\nVerdict : CONTRAT DE CONVERGENCE P5 RESPECTÉ.\n'
