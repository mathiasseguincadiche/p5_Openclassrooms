#!/usr/bin/env bash
# Construit l'application Angular et normalise l'artefact déployé par Ansible.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="${1:-$PROJECT_ROOT/application/angular}"
TARGET_DIR="$PROJECT_ROOT/ansible/files/angular-app"

if [[ ! -f "$SOURCE_DIR/package.json" ]]; then
    printf 'package.json absent dans %s.\n' "$SOURCE_DIR" >&2
    printf 'Copiez d’abord le starter Angular dans application/angular/.\n' >&2
    exit 1
fi

if [[ ! -f "$SOURCE_DIR/package-lock.json" ]]; then
    printf 'package-lock.json absent : npm ci ne peut pas garantir un build reproductible.\n' >&2
    exit 1
fi

command -v node >/dev/null 2>&1 || { printf 'Node.js est absent.\n' >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { printf 'npm est absent.\n' >&2; exit 1; }

printf 'Installation reproductible des dépendances Angular\n'
(
    cd "$SOURCE_DIR"
    npm ci
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
    printf 'Indiquez un projet Angular ne produisant qu’un artefact navigateur.\n' >&2
    exit 1
fi

BUILD_DIR="$(dirname -- "${INDEX_FILES[0]}")"
TMP_TARGET="$(mktemp -d)"
trap 'rm -rf "$TMP_TARGET"' EXIT
cp -a "$BUILD_DIR/." "$TMP_TARGET/"

if [[ ! -f "$TMP_TARGET/index.html" ]]; then
    printf 'Artefact invalide : index.html absent après copie.\n' >&2
    exit 1
fi

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp -a "$TMP_TARGET/." "$TARGET_DIR/"

printf 'Artefact Angular préparé dans %s\n' "$TARGET_DIR"
printf 'Vérifiez-le puis exécutez le playbook Ansible.\n'
