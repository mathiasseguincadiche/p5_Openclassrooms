#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
SOURCE_MD="$PROJECT_ROOT/docs/RUNBOOK_SOUTENANCE.md"
OUTPUT_PDF="$PROJECT_ROOT/docs/RUNBOOK_SOUTENANCE.pdf"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

require_command() {
    local command_name="$1"
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
}

require_command pandoc
require_command xelatex
require_command python3

mkdir -p "$WORKDIR/schemas/officiels"

convert_svg_to_pdf() {
    local source_svg="$1"
    local target_pdf="$2"

    if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -f pdf -o "$target_pdf" "$source_svg"
    elif command -v inkscape >/dev/null 2>&1; then
        inkscape "$source_svg" --export-type=pdf --export-filename="$target_pdf" >/dev/null
    else
        printf 'Installez rsvg-convert (librsvg2-bin) ou Inkscape pour convertir les SVG.\n' >&2
        exit 1
    fi
}

for schema in vue-ensemble exercice-1 exercice-2 exercice-3; do
    convert_svg_to_pdf \
        "$PROJECT_ROOT/docs/schemas/officiels/${schema}.svg" \
        "$WORKDIR/schemas/officiels/${schema}.pdf"
done

python3 - "$SOURCE_MD" "$WORKDIR/RUNBOOK_SOUTENANCE_PDF.md" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
for schema in ("vue-ensemble", "exercice-1", "exercice-2", "exercice-3"):
    source = source.replace(
        f"schemas/officiels/{schema}.svg",
        f"schemas/officiels/{schema}.pdf",
    )

lines = source.splitlines()
out = []
first_h1_seen = False
in_fence = False
for line in lines:
    if line.startswith("```"):
        in_fence = not in_fence
    if not in_fence and line.startswith("# "):
        if first_h1_seen:
            out.extend(["", r"\newpage", ""])
        else:
            first_h1_seen = True
    out.append(line)

Path(sys.argv[2]).write_text("\n".join(out) + "\n", encoding="utf-8")
PY

pandoc "$WORKDIR/RUNBOOK_SOUTENANCE_PDF.md" \
    -o "$OUTPUT_PDF" \
    --pdf-engine=xelatex \
    --resource-path="$WORKDIR" \
    -V papersize:a4 \
    -V geometry:margin=14mm \
    -V mainfont='DejaVu Sans' \
    -V monofont='DejaVu Sans Mono' \
    -V fontsize=10pt

if command -v pdfinfo >/dev/null 2>&1; then
    pdfinfo "$OUTPUT_PDF" | grep -E '^(Pages|Page size):'
fi

printf 'PDF généré : %s\n' "$OUTPUT_PDF"
