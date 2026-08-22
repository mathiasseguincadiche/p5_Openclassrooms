#!/usr/bin/env bash
# Vérifie que les artefacts locaux/non suivis ne polluent pas les audits P5.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
FAKE_DIR="$PROJECT_ROOT/application/angular/node_modules/p5-untracked-regression"
FAKE_FILE="$FAKE_DIR/README.md"
OUTPUT="$(mktemp)"

cleanup() {
    rm -rf "$FAKE_DIR"
    rm -f "$OUTPUT"
}
trap cleanup EXIT INT TERM

mkdir -p "$FAKE_DIR"
cat > "$FAKE_FILE" <<'EOF'
# Dépendance tierce simulée

```mermaid
graph TD
  A --> B
```

ne contient pas le projet angular source
EOF

relative="${FAKE_FILE#"$PROJECT_ROOT/"}"
if git -C "$PROJECT_ROOT" ls-files --error-unmatch "$relative" >/dev/null 2>&1; then
    printf 'Le fichier de test devrait rester non suivi : %s\n' "$relative" >&2
    exit 1
fi

python3 "$PROJECT_ROOT/scripts/tools/audit_non_regression.py" > "$OUTPUT"
grep -Fq 'OK  aucun bloc Mermaid' "$OUTPUT"
grep -Fq "OK  aucune affirmation obsolète sur l'application Angular" "$OUTPUT"
if grep -Fq "$relative" "$OUTPUT"; then
    printf 'Un artefact non suivi a pollué le résultat de l’audit : %s\n' "$relative" >&2
    exit 1
fi

if git -C "$PROJECT_ROOT" grep -Iil -e '```mermaid' -- '*.md' | grep -Fq "$relative"; then
    printf 'git grep a inclus à tort un fichier non suivi.\n' >&2
    exit 1
fi

grep -Fq 'git -C "$PROJECT_ROOT" grep -Iil' \
    "$PROJECT_ROOT/scripts/commands/validate.sh"

printf 'OK  les artefacts Markdown non suivis sont ignorés par les audits P5.\n'
printf 'Verdict : PÉRIMÈTRE VERSIONNÉ ISOLÉ DES ARTEFACTS LOCAUX.\n'
