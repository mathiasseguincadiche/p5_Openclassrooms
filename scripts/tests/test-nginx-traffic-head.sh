#!/usr/bin/env bash
# Vérifie que le générateur de trafic utilise le vrai mode HEAD de curl.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
GENERATOR="$PROJECT_ROOT/scripts/commands/generate-nginx-traffic.sh"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
CURL_LOG="$TMP_DIR/curl-args.log"
OUTPUT_FILE="$TMP_DIR/output.log"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/terraform" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$FAKE_BIN/terraform"

cat > "$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%q ' "$@" >> "$P5_TEST_CURL_LOG"
printf '\n' >> "$P5_TEST_CURL_LOG"
for ((i = 1; i <= $#; i++)); do
    if [[ "${!i}" == "-X" ]]; then
        next=$((i + 1))
        if ((next <= $#)) && [[ "${!next}" == "HEAD" ]]; then
            printf 'KO  -X HEAD ne doit jamais être utilisé.\n' >&2
            exit 97
        fi
    fi
done
printf '200'
EOF
chmod +x "$FAKE_BIN/curl"

export PATH="$FAKE_BIN:/usr/bin:/bin"
export P5_TEST_CURL_LOG="$CURL_LOG"

bash "$GENERATOR" \
    --url http://127.0.0.1:18080 \
    --requests 4 \
    --proof-dir "$TMP_DIR/proofs" >"$OUTPUT_FILE"

grep -Fq '04  HEAD' "$OUTPUT_FILE"
grep -Fq 'Verdict : TRAFIC NGINX GÉNÉRÉ' "$OUTPUT_FILE"
grep -Fq -- '--head' "$CURL_LOG"
if grep -Fq -- '-X HEAD' "$CURL_LOG"; then
    printf 'KO  le trafic HEAD est encore forcé avec -X HEAD.\n' >&2
    exit 1
fi

bash -n "$GENERATOR"

printf 'OK  le trafic HEAD utilise curl --head sans attendre de corps HTTP.\n'
