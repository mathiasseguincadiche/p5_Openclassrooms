#!/usr/bin/env bash
# Reproduit une session AWS expirée sans appeler de vraie API AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
SESSION_CHECK="$PROJECT_ROOT/scripts/commands/check-aws-session.sh"
PRECHECK="$PROJECT_ROOT/scripts/commands/pre-deployment-check.sh"
TMP_DIR="$(mktemp -d)"
CONFIG_FILE="$TMP_DIR/aws-readiness.env"
FAKE_BIN="$TMP_DIR/bin"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN"
cat > "$CONFIG_FILE" <<'EOF'
AWS_PROFILE=p5-lab
AWS_REGION=us-east-1
P5_EXPECTED_ACCOUNT_ID=123456789012
P5_AWS_LOGIN_PROFILE=p5-signin
EOF

cat > "$FAKE_BIN/aws" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${P5_TEST_AWS_STATE:-expired}" == valid ]]; then
    cat <<'JSON'
{"UserId":"AIDATEST","Account":"123456789012","Arn":"arn:aws:iam::123456789012:user/p5-lab-user"}
JSON
    exit 0
fi
printf 'An error occurred (ExpiredToken) when calling the GetCallerIdentity operation: The security token included in the request is expired\n' >&2
exit 255
EOF
chmod +x "$FAKE_BIN/aws"

export PATH="$FAKE_BIN:/usr/bin:/bin"

set +e
EXPIRED_OUTPUT="$(P5_TEST_AWS_STATE=expired bash "$SESSION_CHECK" --config "$CONFIG_FILE" 2>&1)"
EXPIRED_RC=$?
set -e
if ((EXPIRED_RC == 0)); then
    printf 'KO  une session AWS expirée a été acceptée.\n' >&2
    exit 1
fi
grep -Fq 'session AWS du profil p5-lab invalide, expirée ou illisible' <<<"$EXPIRED_OUTPUT"
grep -Fq 'credentials temporaires doivent être renouvelés' <<<"$EXPIRED_OUTPUT"
grep -Fq 'aws-auth.sh --profile p5-lab --source-profile p5-signin --region us-east-1 --mode auto' <<<"$EXPIRED_OUTPUT"
grep -Fq 'Aucun état EC2/VPC/OpenSearch/quota/Budget n’est déduit' <<<"$EXPIRED_OUTPUT"

VALID_OUTPUT="$(P5_TEST_AWS_STATE=valid bash "$SESSION_CHECK" --config "$CONFIG_FILE")"
grep -Fq 'session AWS active : arn:aws:iam::123456789012:user/p5-lab-user' <<<"$VALID_OUTPUT"
grep -Fq 'compte AWS vérifié : 123456789012' <<<"$VALID_OUTPUT"

# Le précontrôle doit toujours passer par le gate STS avant le readiness détaillé.
python3 - "$PRECHECK" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
gate = '"$SCRIPT_DIR/check-aws-session.sh" --config "$CONFIG_FILE"'
readiness = '"$SCRIPT_DIR/check-aws-readiness.sh" --config "$CONFIG_FILE" --stage "$STAGE"'
if gate not in text or readiness not in text:
    raise SystemExit("gate/readiness AWS absent du précontrôle")
if text.index(gate) > text.index(readiness):
    raise SystemExit("le readiness AWS est exécuté avant le gate STS")
if 'contrôles AWS détaillés ignorés pour éviter les faux positifs' not in text:
    raise SystemExit("message anti-faux-positifs absent")
PY

bash -n "$SESSION_CHECK"
bash -n "$PRECHECK"

printf 'OK  session AWS expirée : arrêt avant les contrôles détaillés et action de renouvellement explicite.\n'
