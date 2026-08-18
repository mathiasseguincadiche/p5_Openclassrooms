#!/usr/bin/env bash
# Vérifie que l'audit accepte les fichiers sensibles locaux ignorés et refuse leur suivi Git.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TEST_REPO="$TMP_DIR/repo"
mkdir -p "$TEST_REPO"

# Une copie issue de Git garantit que les éventuels vrais fichiers locaux de
# l'opérateur ne sont jamais lus, modifiés ou supprimés par ce test.
git -C "$PROJECT_ROOT" archive HEAD | tar -x -C "$TEST_REPO"
git -C "$TEST_REPO" init -q
git -C "$TEST_REPO" config user.name 'P5 CI'
git -C "$TEST_REPO" config user.email 'p5-ci@example.invalid'
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -qm 'fixture'

cp "$TEST_REPO/environment/aws-readiness.env.example" \
    "$TEST_REPO/environment/aws-readiness.env"
for exercise in 1 2 3; do
    cp "$TEST_REPO/terraform/exercice-$exercise/terraform.tfvars.example" \
        "$TEST_REPO/terraform/exercice-$exercise/terraform.tfvars"
done

# Ces fichiers doivent exister localement pendant un vrai lab, mais rester
# ignorés par Git. Leur présence seule ne doit donc jamais casser l'audit.
for path in \
    environment/aws-readiness.env \
    terraform/exercice-1/terraform.tfvars \
    terraform/exercice-2/terraform.tfvars \
    terraform/exercice-3/terraform.tfvars; do
    git -C "$TEST_REPO" check-ignore -q "$path"
done

python3 "$TEST_REPO/scripts/tools/audit_non_regression.py" \
    --root "$TEST_REPO" > "$TMP_DIR/untracked.log"
grep -Fq 'CONTRAT DE NON-RÉGRESSION RESPECTÉ' "$TMP_DIR/untracked.log"

# Le même fichier devient une régression dès qu'il est forcé dans l'index Git.
git -C "$TEST_REPO" add -f terraform/exercice-1/terraform.tfvars
if python3 "$TEST_REPO/scripts/tools/audit_non_regression.py" \
    --root "$TEST_REPO" > "$TMP_DIR/tracked.log" 2>&1; then
    printf 'KO  un terraform.tfvars suivi par Git n’a pas été refusé.\n' >&2
    exit 1
fi
grep -Fq 'fichiers locaux ou sensibles suivis par Git' "$TMP_DIR/tracked.log"
grep -Fq 'terraform/exercice-1/terraform.tfvars' "$TMP_DIR/tracked.log"

printf 'Verdict : FICHIERS SENSIBLES LOCAUX / GIT VALIDÉS.\n'
