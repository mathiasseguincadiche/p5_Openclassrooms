#!/usr/bin/env bash
# Activation déterministe du runtime Node.js P5 dans les shells non interactifs.

p5_node_runtime_activate() {
    local expected_version="${1:-${NODE_VERSION:-}}"

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$NVM_DIR/nvm.sh" ]] || return 1

    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"

    if [[ -n "$expected_version" ]]; then
        nvm use "$expected_version" >/dev/null 2>&1 || return 1
    fi

    command -v node >/dev/null 2>&1 || return 1
    command -v npm >/dev/null 2>&1 || return 1

    if [[ -n "$expected_version" ]]; then
        [[ "$(node --version 2>/dev/null)" == "v${expected_version}" ]] || return 1
    fi
}
