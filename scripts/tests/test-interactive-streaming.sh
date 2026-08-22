#!/usr/bin/env bash
# Vérifie que le filtre de redaction conserve un affichage interactif immédiat.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/p5-runtime.sh
source "$PROJECT_ROOT/scripts/lib/p5-runtime.sh"

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

printf 'OK  streaming interactif immédiat et redaction des secrets validés.\n'
