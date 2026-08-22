#!/usr/bin/env bash
# Vérifie que le filtre de redaction conserve un affichage interactif immédiat.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
RUNTIME_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
AWS_AUTH_FILE="$PROJECT_ROOT/scripts/commands/aws-auth.sh"
TMP_DIR="$(mktemp -d)"

# shellcheck source=../lib/p5-runtime.sh
source "$RUNTIME_FILE"

coproc P5_STREAM_TEST {
    {
        printf 'PREMIERE_LIGNE_INTERACTIVE\n'
        sleep 3
        printf 'SECONDE_LIGNE_INTERACTIVE\n'
    } | p5_redact_stream
}

STREAM_PID="$P5_STREAM_TEST_PID"
STREAM_FD="${P5_STREAM_TEST[0]}"

cleanup() {
    kill "$STREAM_PID" 2>/dev/null || true
    wait "$STREAM_PID" 2>/dev/null || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

FIRST_LINE=''
if ! IFS= read -r -t 1 FIRST_LINE <&"$STREAM_FD"; then
    printf 'KO  le filtre de redaction bufferise la sortie interactive au lieu de la transmettre immédiatement.\n' >&2
    exit 1
fi

if [[ "$FIRST_LINE" != 'PREMIERE_LIGNE_INTERACTIVE' ]]; then
    printf 'KO  première ligne interactive inattendue : %s\n' "$FIRST_LINE" >&2
    exit 1
fi

REDACTED="$(printf '%s\n' \
    'AWS_SESSION_TOKEN=secret-temporaire' \
    'GITHUB_TOKEN=github_pat_EXEMPLE123456789' \
    | p5_redact_stream)"

grep -Fq 'AWS_SESSION_TOKEN=<REDACTED>' <<<"$REDACTED"
if grep -Fq 'secret-temporaire' <<<"$REDACTED"; then
    printf 'KO  le filtre laisse apparaître un secret AWS.\n' >&2
    exit 1
fi

# Les invites exécutées derrière p5_run_step doivent terminer leur ligne avant
# read, sinon un filtre ligne-par-ligne peut encore masquer le prompt.
grep -Fq "printf '%s [%s] :\\n'" "$RUNTIME_FILE"
grep -Fq "printf '%s [o/N] :\\n'" "$RUNTIME_FILE"
grep -Fq "printf 'Tapez exactement %s :\\n'" "$RUNTIME_FILE"
grep -Fq "printf 'Votre choix [1] :\\n'" "$AWS_AUTH_FILE"

# Le flux cross-device AWS lit son code d'autorisation sur stdin. p5_run_step
# ne doit jamais consommer ni remplacer stdin lorsqu'il journalise stdout/stderr.
cat > "$TMP_DIR/read-stdin.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
IFS= read -r value
printf 'STDIN_RECU=%s\n' "$value"
EOF
chmod +x "$TMP_DIR/read-stdin.sh"
mkdir -p "$TMP_DIR/project"

STDIN_OUTPUT="$(
    printf 'CODE_TEST_CROSS_DEVICE\n' \
        | env P5_PROJECT_ROOT="$TMP_DIR/project" bash -c '
            set -euo pipefail
            source "$1"
            p5_session_start "stdin-contract"
            p5_run_step "stdin-cross-device" "Préserver stdin interactif" bash "$2"
        ' _ "$RUNTIME_FILE" "$TMP_DIR/read-stdin.sh"
)"

grep -Fq 'STDIN_RECU=CODE_TEST_CROSS_DEVICE' <<<"$STDIN_OUTPUT"
grep -Fq '[ OK ] Préserver stdin interactif' <<<"$STDIN_OUTPUT"

printf 'OK  streaming interactif immédiat, stdin cross-device, invites visibles et redaction des secrets validés.\n'
