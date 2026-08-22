#!/usr/bin/env bash
# Verrouille les régressions observées pendant le premier prepare AWS réel.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
VALIDATE="$PROJECT_ROOT/scripts/commands/validate.sh"
READINESS="$PROJECT_ROOT/scripts/commands/check-aws-readiness.sh"
POLICY="$PROJECT_ROOT/aws/iam/p5-lab-policy.json"

# Régression 1 : `trap ... RETURN` ne doit plus référencer une variable locale
# après la sortie de validate_opensearch_data sous `set -u`.
if grep -Fq "trap 'rm -f \"\$output\"' RETURN" "$VALIDATE"; then
    printf 'KO  validate.sh réintroduit le trap RETURN qui provoquait output: unbound variable.\n' >&2
    exit 1
fi
grep -Fq 'local output rc=0' "$VALIDATE"
grep -Fq 'rm -f "$output"' "$VALIDATE"

# Régression 2 : la politique IAM doit couvrir les API OpenSearch actuelles.
python3 - "$POLICY" <<'PY'
import json
import sys
from pathlib import Path

policy = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
actions = {
    action
    for statement in policy.get("Statement", [])
    for action in (
        statement.get("Action", [])
        if isinstance(statement.get("Action", []), list)
        else [statement.get("Action")]
    )
    if action
}
required = {
    "es:CreateDomain",
    "es:DeleteDomain",
    "es:DescribeDomain",
    "es:DescribeDomainConfig",
    "es:DescribeInstanceTypeLimits",
    "es:ListInstanceTypeDetails",
    "es:ListVersions",
    "es:UpdateDomainConfig",
}
missing = sorted(required - actions)
if missing:
    raise SystemExit("Actions OpenSearch modernes absentes : " + ", ".join(missing))
PY

# Régression 3 : le quota global de l'exercice 3 ne doit plus bloquer l'étape
# initiale si celle-ci dispose des vCPU nécessaires à sa seule EC2.
grep -Fq 'STAGE_REQUIRED_VCPUS="$INSTANCE_VCPUS"' "$READINESS"
grep -Fq 'STAGE_REQUIRED_VCPUS="$P5_REQUIRED_STANDARD_VCPUS"' "$READINESS"
grep -Fq 'quota actuel suffisant pour $STAGE' "$READINESS"
grep -Fq 'L-1216C47A' "$READINESS"

# Régression 4 : un AccessDenied OpenSearch doit identifier la permission
# exacte et ne plus être confondu avec une indisponibilité du service.
grep -Fq 'permission IAM es:ListInstanceTypeDetails absente' "$READINESS"
grep -Fq 'P5LabPolicy' "$READINESS"
grep -Fq 'DOMAIN_STATUS=unknown' "$READINESS"

bash -n "$VALIDATE"
bash -n "$READINESS"
python3 -m json.tool "$POLICY" >/dev/null

printf 'OK  précontrôle AWS : nettoyage local, quota par étape et IAM OpenSearch verrouillés.\n'
