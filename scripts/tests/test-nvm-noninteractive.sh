#!/usr/bin/env bash
# Vérifie que le runtime P5 rend Node/npm disponibles sans dépendre du shell interactif.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
RUNTIME_LIB="$PROJECT_ROOT/scripts/lib/p5-node-runtime.sh"
TMP_DIR="$(mktemp -d)"
FAKE_HOME="$TMP_DIR/home"
FAKE_BIN="$FAKE_HOME/.nvm/versions/node/v22.22.0/bin"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_HOME/.nvm" "$FAKE_BIN"

cat > "$FAKE_HOME/.nvm/nvm.sh" <<'EOF_NVM'
nvm() {
    if [[ "${1:-}" == use && "${2:-}" == 22.22.0 ]]; then
        export PATH="$NVM_DIR/versions/node/v22.22.0/bin:$PATH"
        return 0
    fi
    return 1
}
EOF_NVM

cat > "$FAKE_BIN/node" <<'EOF_NODE'
#!/usr/bin/env bash
printf 'v22.22.0\n'
EOF_NODE
cat > "$FAKE_BIN/npm" <<'EOF_NPM'
#!/usr/bin/env bash
printf '10.9.4\n'
EOF_NPM
chmod +x "$FAKE_BIN/node" "$FAKE_BIN/npm"

(
    export HOME="$FAKE_HOME"
    unset NVM_DIR
    export PATH="/usr/bin:/bin"
    # shellcheck source=/dev/null
    source "$RUNTIME_LIB"

    p5_node_runtime_activate 22.22.0

    [[ "$(command -v node)" == "$FAKE_BIN/node" ]]
    [[ "$(command -v npm)" == "$FAKE_BIN/npm" ]]
    [[ "$(node --version)" == v22.22.0 ]]
)

(
    export HOME="$TMP_DIR/home-without-nvm"
    unset NVM_DIR
    export PATH="/usr/bin:/bin"
    # shellcheck source=/dev/null
    source "$RUNTIME_LIB"
    if p5_node_runtime_activate 22.22.0; then
        printf 'KO  le runtime Node ne doit pas réussir sans installation NVM.\n' >&2
        exit 1
    fi
)

printf 'OK  Node.js et npm sont activables via NVM dans un shell non interactif.\n'
