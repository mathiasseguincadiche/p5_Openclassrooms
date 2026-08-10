#!/usr/bin/env bash
# Teste le contrat de l'orchestrateur P5 sans créer de ressource AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
P5_SCRIPT="$PROJECT_ROOT/scripts/commands/p5.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
TRACE_FILE="$TMP_DIR/trace.log"

cleanup() {
    rm -f "$CONFIG_FILE"
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

[[ ! -e "$CONFIG_FILE" ]] || {
    printf 'Le test refuse d\047écraser une configuration AWS locale existante.\n' >&2
    exit 1
}

mkdir -p "$FAKE_BIN" "$TMP_DIR/home/.ssh" "$TMP_DIR/logs"
cat > "$CONFIG_FILE" <<EOF
AWS_PROFILE=p5-test
AWS_REGION=us-east-1
P5_EXPECTED_ACCOUNT_ID=123456789012
P5_PUBLIC_IP_CIDR=198.51.100.42/32
P5_SSH_PUBLIC_KEY_PATH=$TMP_DIR/home/.ssh/p5-key.pub
P5_BUDGET_NAME=p5-test-budget
EOF
chmod 600 "$CONFIG_FILE"
: > "$TMP_DIR/home/.ssh/p5-key"
: > "$TMP_DIR/home/.ssh/p5-key.pub"
chmod 600 "$TMP_DIR/home/.ssh/p5-key"
chmod 644 "$TMP_DIR/home/.ssh/p5-key.pub"

cat > "$FAKE_BIN/bash" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'bash' >> "${P5_TEST_TRACE:?}"
printf ' %q' "$@" >> "$P5_TEST_TRACE"
printf '\n' >> "$P5_TEST_TRACE"
exit 0
EOF

cat > "$FAKE_BIN/terraform" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
if [[ "$args" == *" state list"* ]]; then
    exit 0
fi
if [[ "$args" == *"output -raw web_public_ip"* ]]; then
    printf '%s\n' '198.51.100.10'
elif [[ "$args" == *"output -raw opensearch_dashboards_endpoint"* ]]; then
    printf '%s\n' 'https://search.example.invalid/_dashboards'
elif [[ "$args" == *"output -raw haproxy_url"* ]]; then
    printf '%s\n' 'http://198.51.100.20'
elif [[ "$args" == *" output"* ]]; then
    printf '%s\n' 'stub-output'
fi
exit 0
EOF

cat > "$FAKE_BIN/ansible-playbook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat <<'OUT'
PLAY RECAP *********************************************************************
p5-web : ok=12 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
OUT
EOF

for command_name in ansible aws curl jq ssh docker node npm shellcheck yamllint; do
    cat > "$FAKE_BIN/$command_name" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
done
chmod +x "$FAKE_BIN"/*

export PATH="$FAKE_BIN:/usr/bin:/bin"
export HOME="$TMP_DIR/home"
export P5_LOG_DIR="$TMP_DIR/logs"
export P5_TEST_TRACE="$TRACE_FILE"

HELP_OUTPUT="$(/usr/bin/bash "$P5_SCRIPT" help)"
grep -Fq 'all        exécuter prepare + ex1 + ex2 + ex3 + diagnostics' <<<"$HELP_OUTPUT"
grep -Fq 'cleanup    détruire AWS dans l'ordre prévu puis auditer le nettoyage' <<<"$HELP_OUTPUT"

/usr/bin/bash "$P5_SCRIPT" status --full-validation
/usr/bin/bash "$P5_SCRIPT" ex1 --yes
/usr/bin/bash "$P5_SCRIPT" ex3 --yes

grep -Fq 'prepare-angular-artifact.sh' "$TRACE_FILE"
grep -Fq 'generate-ansible-inventory.sh' "$TRACE_FILE"
grep -Fq 'test-haproxy-failover.sh --apply' "$TRACE_FILE"
grep -Fq 'Idempotence Ansible confirmée' "$TMP_DIR/logs/p5.log"

set +e
EX2_OUTPUT="$(/usr/bin/bash "$P5_SCRIPT" ex2 --yes 2>&1)"
EX2_RC=$?
set -e
if ((EX2_RC == 0)); then
    printf 'KO  le checkpoint manuel OpenSearch a été contourné en mode non interactif.\n' >&2
    exit 1
fi
grep -Fq 'Le mode --yes ne valide pas une preuve manuelle à votre place.' <<<"$EX2_OUTPUT"
grep -Fq 'Saisie interactive requise : OK' <<<"$EX2_OUTPUT"

printf 'OK  contrat de l\047orchestrateur P5 validé sans mutation AWS.\n'
