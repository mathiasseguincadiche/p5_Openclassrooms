#!/usr/bin/env bash
# Teste le contrat de l'orchestrateur P5 sans créer de ressource AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
P5_SCRIPT="$PROJECT_ROOT/scripts/commands/p5.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
COMMAND_CENTER_DOC="$PROJECT_ROOT/docs/CENTRE_DE_COMMANDE.md"
SCRIPTS_README="$PROJECT_ROOT/scripts/README.md"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
TRACE_FILE="$TMP_DIR/trace.log"

cleanup() {
    rm -f "$CONFIG_FILE"
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

[[ ! -e "$CONFIG_FILE" ]] || {
    printf "Le test refuse d'écraser une configuration AWS locale existante.\n" >&2
    exit 1
}

[[ -f "$COMMAND_CENTER_DOC" ]] || {
    printf 'Documentation du centre de commande absente : %s\n' "$COMMAND_CENTER_DOC" >&2
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
#!/usr/bin/bash
set -euo pipefail
printf 'bash' >> "${P5_TEST_TRACE:?}"
printf ' %q' "$@" >> "$P5_TEST_TRACE"
printf '\n' >> "$P5_TEST_TRACE"
exit 0
EOF

cat > "$FAKE_BIN/terraform" <<'EOF'
#!/usr/bin/bash
set -euo pipefail
args="$*"
if [[ "$args" == *" state list"* ]]; then
    exit 0
fi
if [[ "$args" == *"output -raw web_public_ip"* ]]; then
    printf '%s\n' '198.51.100.10'
elif [[ "$args" == *"output -raw web_url"* ]]; then
    printf '%s\n' 'http://198.51.100.10'
elif [[ "$args" == *"output -raw opensearch_endpoint"* ]]; then
    printf '%s\n' 'https://search.example.invalid'
elif [[ "$args" == *"output -raw opensearch_dashboards_endpoint"* ]]; then
    printf '%s\n' 'https://search.example.invalid/_dashboards/'
elif [[ "$args" == *"output -raw haproxy_url"* ]]; then
    printf '%s\n' 'http://198.51.100.20'
elif [[ "$args" == *"output -raw hello_1_public_ip"* ]]; then
    printf '%s\n' '198.51.100.21'
elif [[ "$args" == *" output"* ]]; then
    printf '%s\n' 'stub-output'
fi
exit 0
EOF

cat > "$FAKE_BIN/ansible-playbook" <<'EOF'
#!/usr/bin/bash
set -euo pipefail
cat <<'OUT'
PLAY RECAP *********************************************************************
p5-web : ok=12 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
OUT
EOF

for command_name in ansible aws curl jq ssh docker node npm shellcheck yamllint; do
    cat > "$FAKE_BIN/$command_name" <<'EOF'
#!/usr/bin/bash
exit 0
EOF
done
chmod +x "$FAKE_BIN"/*

export PATH="$FAKE_BIN:/usr/bin:/bin"
export HOME="$TMP_DIR/home"
export P5_LOG_DIR="$TMP_DIR/logs"
export P5_TEST_TRACE="$TRACE_FILE"

HELP_OUTPUT="$(/usr/bin/bash "$P5_SCRIPT" help)"
grep -Fq 'all          exécuter prepare + ex1 + ex2 + ex3 + diagnostics' <<<"$HELP_OUTPUT"
grep -Fq 'diagnostics  collecter diagnostics et structure des preuves/livrables' <<<"$HELP_OUTPUT"
grep -Fq "cleanup      détruire AWS dans l'ordre prévu puis auditer le nettoyage" <<<"$HELP_OUTPUT"
grep -Fq 'guide        expliquer quel parcours choisir selon votre situation' <<<"$HELP_OUTPUT"
grep -Fq 'docs         afficher la carte de la documentation P5' <<<"$HELP_OUTPUT"

DOCS_OUTPUT="$(/usr/bin/bash "$P5_SCRIPT" docs)"
grep -Fq 'JE DÉBUTE' <<<"$DOCS_OUTPUT"
grep -Fq 'docs/CENTRE_DE_COMMANDE.md' <<<"$DOCS_OUTPUT"
grep -Fq 'docs/troubleshooting.md' <<<"$DOCS_OUTPUT"

MENU_OUTPUT="$(printf '0\n' | /usr/bin/bash "$P5_SCRIPT" menu)"
grep -Fq 'P5 OPENCLASSROOMS — CENTRE DE COMMANDE' <<<"$MENU_OUTPUT"
grep -Fq '12  Que dois-je faire maintenant ?' <<<"$MENU_OUTPUT"
grep -Fq '15  Nettoyer les ressources AWS' <<<"$MENU_OUTPUT"
grep -Fq '0  Quitter' <<<"$MENU_OUTPUT"

# La documentation opérateur doit rester synchronisée avec les choix critiques.
grep -Fq '15  Nettoyer les ressources AWS' "$SCRIPTS_README"
grep -Fq '0  Quitter' "$SCRIPTS_README"
if grep -Fq '0  Nettoyer AWS' "$SCRIPTS_README"; then
    printf 'KO  scripts/README.md documente encore un ancien menu destructif en option 0.\n' >&2
    exit 1
fi

/usr/bin/bash "$P5_SCRIPT" status --full-validation
/usr/bin/bash "$P5_SCRIPT" ex1 --yes
/usr/bin/bash "$P5_SCRIPT" ex3 --yes
/usr/bin/bash "$P5_SCRIPT" diagnostics

grep -Fq 'prepare-angular-artifact.sh' "$TRACE_FILE"
grep -Fq 'generate-ansible-inventory.sh' "$TRACE_FILE"
grep -Fq 'test-haproxy-failover.sh --url http://198.51.100.20 --backend-host 198.51.100.21 --apply' "$TRACE_FILE"
grep -Fq 'collect-diagnostics.sh --complet --avec-preuves' "$TRACE_FILE"
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

printf "OK  contrat de l'orchestrateur et du centre de commande P5 validé sans mutation AWS.\n"
