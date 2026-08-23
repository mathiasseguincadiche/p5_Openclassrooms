#!/usr/bin/env bash
# Vérifie les descriptions littérales utilisées par les Security Groups AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

python3 - "$PROJECT_ROOT" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
allowed = re.compile(r'^[0-9A-Za-z_ .:/()#,@\[\]+=&;{}!$*-]*$')
assignment = re.compile(r'^\s*description\s*=\s*"([^"]*)"\s*$')
violations = []

for path in sorted((root / "terraform").glob("exercice-*/*.tf")):
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = assignment.match(line)
        if not match:
            continue
        value = match.group(1)
        if not allowed.fullmatch(value):
            violations.append(f"{path.relative_to(root)}:{lineno}: {value!r}")

if violations:
    raise SystemExit(
        "Descriptions Terraform incompatibles avec les contraintes AWS:\n"
        + "\n".join(violations)
    )
PY

printf 'OK  descriptions Terraform compatibles avec les contraintes AWS Security Group.\n'
