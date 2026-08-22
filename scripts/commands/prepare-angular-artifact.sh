#!/usr/bin/env bash
# Construit l'application Angular uniquement si les sources/dépendances ont changé.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
VERSIONS_FILE="$PROJECT_ROOT/environment/versions.env"
NODE_RUNTIME_LIB="$PROJECT_ROOT/scripts/lib/p5-node-runtime.sh"
SOURCE_DIR="${1:-$PROJECT_ROOT/application/angular}"
TARGET_DIR="$PROJECT_ROOT/ansible/files/angular-app"
STATE_DIR="$PROJECT_ROOT/.p5/state"
DEPS_STATE="$STATE_DIR/angular-deps.sha256"
ARTIFACT_STATE="$STATE_DIR/angular-artifact.env"

[[ -r "$VERSIONS_FILE" && -r "$NODE_RUNTIME_LIB" ]] || {
    printf 'Contrat Node P5 absent ou illisible.\n' >&2
    exit 1
}
# shellcheck source=/dev/null
source "$VERSIONS_FILE"
# shellcheck source=/dev/null
source "$NODE_RUNTIME_LIB"
if ! p5_node_runtime_activate "$NODE_VERSION"; then
    printf 'Node.js %s via NVM est indisponible dans ce shell.\n' "$NODE_VERSION" >&2
    printf 'Relancez : bash scripts/commands/p5.sh prepare\n' >&2
    exit 1
fi

if [[ ! -f "$SOURCE_DIR/package.json" ]]; then
    printf 'Projet Angular invalide : package.json absent dans %s.\n' "$SOURCE_DIR" >&2
    exit 1
fi
if [[ ! -f "$SOURCE_DIR/package-lock.json" ]]; then
    printf 'package-lock.json absent : npm ci ne peut pas garantir un build reproductible.\n' >&2
    exit 1
fi
command -v node >/dev/null 2>&1 || { printf 'Node.js est absent.\n' >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { printf 'npm est absent.\n' >&2; exit 1; }

hash_files() {
    local root="$1"
    shift
    (
        cd "$root"
        printf '%s\0' "$@" \
            | sort -z \
            | xargs -0 -r sha256sum \
            | sha256sum \
            | awk '{print $1}'
    )
}

mapfile -d '' SOURCE_FILES < <(
    cd "$SOURCE_DIR"
    find src -type f -print0
    for file in angular.json package.json package-lock.json tsconfig.json tsconfig.app.json; do
        [[ -f "$file" ]] && printf '%s\0' "$file"
    done
)
DEPS_HASH="$(
    {
        sha256sum "$SOURCE_DIR/package.json" "$SOURCE_DIR/package-lock.json"
        printf 'node=%s\n' "$(node --version)"
        printf 'npm=%s\n' "$(npm --version)"
    } | sha256sum | awk '{print $1}'
)"
SOURCE_HASH="$(hash_files "$SOURCE_DIR" "${SOURCE_FILES[@]}")"
BUILD_KEY="$(
    printf 'deps=%s\nsource=%s\n' "$DEPS_HASH" "$SOURCE_HASH" \
        | sha256sum | awk '{print $1}'
)"

artifact_hash() {
    [[ -d "$TARGET_DIR" ]] || return 1
    (
        cd "$TARGET_DIR"
        find . -type f -print0 \
            | sort -z \
            | xargs -0 -r sha256sum \
            | sha256sum \
            | awk '{print $1}'
    )
}

artifact_valid() {
    [[ -f "$TARGET_DIR/index.html" ]] \
        && find "$TARGET_DIR" -maxdepth 1 -type f -name 'main-*.js' | grep -q .
}

mkdir -p "$STATE_DIR"
CURRENT_ARTIFACT_HASH="$(artifact_hash 2>/dev/null || true)"
SAVED_BUILD_KEY=""
SAVED_ARTIFACT_HASH=""
if [[ -r "$ARTIFACT_STATE" ]]; then
    # shellcheck source=/dev/null
    source "$ARTIFACT_STATE"
    SAVED_BUILD_KEY="${BUILD_KEY_SAVED:-}"
    SAVED_ARTIFACT_HASH="${ARTIFACT_HASH_SAVED:-}"
fi

if artifact_valid \
    && [[ "$BUILD_KEY" == "$SAVED_BUILD_KEY" ]] \
    && [[ -n "$CURRENT_ARTIFACT_HASH" ]] \
    && [[ "$CURRENT_ARTIFACT_HASH" == "$SAVED_ARTIFACT_HASH" ]]; then
    printf 'Artefact Angular déjà conforme : aucune installation npm ni reconstruction nécessaire.\n'
    printf 'Source hash : %s\n' "$SOURCE_HASH"
    exit 0
fi

CURRENT_DEPS_STATE="$(cat "$DEPS_STATE" 2>/dev/null || true)"
if [[ -d "$SOURCE_DIR/node_modules" && "$CURRENT_DEPS_STATE" == "$DEPS_HASH" ]]; then
    printf 'Dépendances Angular déjà conformes : npm ci ignoré.\n'
else
    printf 'Dépendances Angular absentes ou différentes : npm ci.\n'
    (
        cd "$SOURCE_DIR"
        npm ci
    )
    printf '%s\n' "$DEPS_HASH" > "$DEPS_STATE"
fi

printf 'Sources/artefact différents : construction Angular.\n'
(
    cd "$SOURCE_DIR"
    npm run build
)

mapfile -t INDEX_FILES < <(find "$SOURCE_DIR/dist" -type f -name index.html -print | sort)
if [[ "${#INDEX_FILES[@]}" -eq 0 ]]; then
    printf 'Aucun index.html trouvé sous %s/dist après le build.\n' "$SOURCE_DIR" >&2
    exit 1
fi
if [[ "${#INDEX_FILES[@]}" -gt 1 ]]; then
    printf 'Plusieurs artefacts Angular ont été détectés :\n' >&2
    printf '  %s\n' "${INDEX_FILES[@]}" >&2
    exit 1
fi

BUILD_DIR="$(dirname -- "${INDEX_FILES[0]}")"
TMP_TARGET="$(mktemp -d)"
trap 'rm -rf "$TMP_TARGET"' EXIT
cp -a "$BUILD_DIR/." "$TMP_TARGET/"
[[ -f "$TMP_TARGET/index.html" ]] || {
    printf 'Artefact invalide : index.html absent après copie.\n' >&2
    exit 1
}

NEW_ARTIFACT_HASH="$(
    cd "$TMP_TARGET"
    find . -type f -print0 \
        | sort -z \
        | xargs -0 -r sha256sum \
        | sha256sum \
        | awk '{print $1}'
)"
if [[ -d "$TARGET_DIR" ]] && [[ "$NEW_ARTIFACT_HASH" == "$CURRENT_ARTIFACT_HASH" ]]; then
    printf 'Build identique à l’artefact Ansible existant : aucune réécriture.\n'
else
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cp -a "$TMP_TARGET/." "$TARGET_DIR/"
    printf 'Artefact Angular convergé dans %s\n' "$TARGET_DIR"
fi

cat > "$ARTIFACT_STATE" <<EOF_STATE
BUILD_KEY_SAVED=$BUILD_KEY
ARTIFACT_HASH_SAVED=$NEW_ARTIFACT_HASH
EOF_STATE
printf 'Verdict : ARTEFACT ANGULAR CONVERGÉ.\n'
