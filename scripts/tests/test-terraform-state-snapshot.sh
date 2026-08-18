#!/usr/bin/env bash
# Vérifie les sauvegardes locales confidentielles du state Terraform.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/project/terraform/exercice-1"
printf '%s\n' '{"version":4,"serial":7,"resources":[]}' \
    > "$TMP_DIR/project/terraform/exercice-1/terraform.tfstate"
cat > "$TMP_DIR/bin/terraform" <<'FAKE_TERRAFORM'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == -chdir=* ]]
[[ "$2" == state ]]
[[ "$3" == pull ]]
printf '%s\n' '{"version":4,"serial":7,"resources":[]}'
FAKE_TERRAFORM
chmod 700 "$TMP_DIR/bin/terraform"

export PATH="$TMP_DIR/bin:$PATH"
export P5_PROJECT_ROOT="$TMP_DIR/project"
export P5_TERRAFORM_STATE_BACKUP_DIR="$TMP_DIR/backups"
export P5_RUN_ID='state-snapshot-test'

bash "$PROJECT_ROOT/scripts/commands/snapshot-terraform-state.sh" \
    --exercise 1 --label before-apply > "$TMP_DIR/snapshot-1.log"
bash "$PROJECT_ROOT/scripts/commands/snapshot-terraform-state.sh" \
    --exercise 1 --label before-apply > "$TMP_DIR/snapshot-2.log"

backup_dir="$TMP_DIR/backups/$P5_RUN_ID"
manifest="$backup_dir/manifest.tsv"
mapfile -t backup_files < <(
    find "$backup_dir" -maxdepth 1 -type f \
        -name 'exercice-1-before-apply-*.tfstate' | sort
)
[[ "${#backup_files[@]}" -eq 2 ]]
[[ "${backup_files[0]}" != "${backup_files[1]}" ]]
test -s "$manifest"
[[ "$(stat -c '%a' "$backup_dir")" == 700 ]]
[[ "$(stat -c '%a' "$manifest")" == 600 ]]
for backup_file in "${backup_files[@]}"; do
    [[ "$(stat -c '%a' "$backup_file")" == 600 ]]
    grep -Fq "$(sha256sum "$backup_file" | awk '{print $1}')" "$manifest"
done
grep -Fq $'utc\texercise\tlabel\tsha256\tstate_file' "$manifest"
[[ "$(grep -Fc $'\t1\tbefore-apply\t' "$manifest")" -eq 2 ]]
grep -Fq 'Attention : ces fichiers peuvent contenir des données sensibles.' \
    "$TMP_DIR/snapshot-1.log"

bash "$PROJECT_ROOT/scripts/commands/snapshot-terraform-state.sh" \
    --exercise 2 --label before-apply > "$TMP_DIR/no-state.log"
grep -Fq 'aucune sauvegarde nécessaire' "$TMP_DIR/no-state.log"

printf 'Verdict : SAUVEGARDE LOCALE DU STATE TERRAFORM VALIDÉE.\n'
