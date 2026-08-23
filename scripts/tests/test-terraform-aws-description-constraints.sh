#!/usr/bin/env bash
# Vérifie les descriptions littérales envoyées aux Security Groups AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

python3 - "$PROJECT_ROOT" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
allowed = re.compile(r'^[0-9A-Za-z_ .:/()#,@\[\]+=&;{}!$*-]*$')
resource_start = re.compile(
    r'^\s*resource\s+"aws_security_group(?:_rule)?"\s+"[^"]+"\s*\{\s*$'
)
assignment = re.compile(r'^\s*description\s*=\s*"([^"]*)"\s*$')
violations = []

for path in sorted((root / "terraform").glob("exercice-*/*.tf")):
    depth = 0
    in_security_group = False
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not in_security_group and resource_start.match(line):
            in_security_group = True
            depth = line.count("{") - line.count("}")
            continue

        if not in_security_group:
            continue

        match = assignment.match(line)
        if match:
            value = match.group(1)
            if not allowed.fullmatch(value):
                violations.append(f"{path.relative_to(root)}:{lineno}: {value!r}")

        depth += line.count("{") - line.count("}")
        if depth <= 0:
            in_security_group = False
            depth = 0

if violations:
    raise SystemExit(
        "Descriptions Security Group incompatibles avec les contraintes AWS:\n"
        + "\n".join(violations)
    )
PY

printf 'OK  descriptions Terraform Security Group compatibles avec les contraintes AWS.\n'
