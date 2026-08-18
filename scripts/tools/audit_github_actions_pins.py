#!/usr/bin/env python3
"""Refuse les GitHub Actions externes qui ne sont pas verrouillées par SHA."""

from __future__ import annotations

import re
import sys
from pathlib import Path

USE_PATTERN = re.compile(r"^\s*uses:\s*([^\s#]+)", re.MULTILINE)
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    workflow_dir = root / ".github" / "workflows"
    errors: list[str] = []
    checked = 0

    for workflow in sorted(workflow_dir.glob("*.yml")):
        text = workflow.read_text(encoding="utf-8")
        for match in USE_PATTERN.finditer(text):
            value = match.group(1)
            if value.startswith("./"):
                continue
            checked += 1
            if "@" not in value:
                errors.append(f"{workflow.relative_to(root)} : référence sans @ : {value}")
                continue
            action, ref = value.rsplit("@", 1)
            if not action or not SHA_PATTERN.fullmatch(ref):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{workflow.relative_to(root)}:{line} : action non SHA-pinnée : {value}"
                )

    if errors:
        for error in errors:
            print(f"KO  {error}")
        print(f"Verdict : ACTIONS NON VERROUILLÉES ({len(errors)})")
        return 1

    print(f"OK  {checked} utilisation(s) d'Actions externes verrouillée(s) par SHA")
    print("Verdict : GITHUB ACTIONS SHA-PINNÉES")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
