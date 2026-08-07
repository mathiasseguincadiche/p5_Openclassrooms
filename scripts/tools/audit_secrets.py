#!/usr/bin/env python3
"""Détecte les secrets et fichiers sensibles suivis par Git."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

SENSITIVE_EXACT_PATHS = {
    ".env",
    "environment/aws-readiness.env",
    "ansible/inventories/hosts_aws",
    ".aws/credentials",
    ".aws/config",
}

SENSITIVE_FILENAMES = {
    "terraform.tfvars",
    "credentials",
    "id_rsa",
    "id_dsa",
    "id_ecdsa",
    "id_ed25519",
}

SENSITIVE_SUFFIXES = {
    ".pem",
    ".p12",
    ".pfx",
    ".tfstate",
    ".tfplan",
}

ALLOWED_SUFFIXES = {
    ".example",
    ".sample",
    ".pub",
}

CONTENT_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "identifiant de clé d’accès AWS",
        re.compile(r"(?<![A-Z0-9])(?:AKIA|ASIA)[0-9A-Z]{16}(?![A-Z0-9])"),
    ),
    (
        "clé privée",
        re.compile(
            r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]+?"
            r"-----END [A-Z0-9 ]*PRIVATE KEY-----"
        ),
    ),
    (
        "jeton GitHub classique",
        re.compile(r"(?<![A-Za-z0-9])gh[pousr]_[A-Za-z0-9]{30,255}"),
    ),
    (
        "jeton GitHub finement granulé",
        re.compile(r"(?<![A-Za-z0-9])github_pat_[A-Za-z0-9_]{60,255}"),
    ),
    (
        "jeton Slack",
        re.compile(r"(?<![A-Za-z0-9])xox[baprs]-[A-Za-z0-9-]{20,255}"),
    ),
    (
        "clé secrète AWS déclarée",
        re.compile(
            r"(?im)^[ \t]*(?:aws_secret_access_key|secret_key)"
            r"[ \t]*[:=][ \t]*[\"']?[A-Za-z0-9/+=]{40}[\"']?[ \t]*$"
        ),
    ),
    (
        "jeton de session AWS déclaré",
        re.compile(
            r"(?im)^[ \t]*aws_session_token[ \t]*[:=][ \t]*"
            r"[\"']?[A-Za-z0-9/+=]{80,}[\"']?[ \t]*$"
        ),
    ),
)


def tracked_files(root: Path) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "-C", str(root), "ls-files", "-z"],
            check=True,
            capture_output=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return sorted(
            path
            for path in root.rglob("*")
            if path.is_file() and ".git" not in path.parts
        )

    return [
        root / item.decode("utf-8", errors="surrogateescape")
        for item in result.stdout.split(b"\0")
        if item
    ]


def is_sensitive_path(relative: PurePosixPath) -> bool:
    path_text = relative.as_posix()
    lower_name = relative.name.lower()

    if path_text in SENSITIVE_EXACT_PATHS:
        return True

    if lower_name in SENSITIVE_FILENAMES:
        return True

    if lower_name.startswith(".env") and not any(
        lower_name.endswith(suffix) for suffix in (".example", ".sample")
    ):
        return True

    if lower_name.startswith("terraform.tfstate"):
        return True

    if any(lower_name.endswith(suffix) for suffix in SENSITIVE_SUFFIXES):
        return not any(lower_name.endswith(suffix) for suffix in ALLOWED_SUFFIXES)

    if lower_name.endswith(".key") and not lower_name.endswith(".pub.key"):
        return True

    return False


def read_text(path: Path) -> str | None:
    try:
        raw = path.read_bytes()
    except OSError:
        return None

    if b"\0" in raw:
        return None

    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return None


def audit(root: Path) -> int:
    errors: list[str] = []
    files = tracked_files(root)

    for path in files:
        if not path.is_file():
            continue

        relative = PurePosixPath(path.relative_to(root).as_posix())
        if is_sensitive_path(relative):
            errors.append(f"fichier sensible suivi : {relative}")

        text = read_text(path)
        if text is None:
            continue

        for label, pattern in CONTENT_PATTERNS:
            match = pattern.search(text)
            if match:
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"{relative}:{line} : {label}")

    if errors:
        unique_errors = sorted(set(errors))
        for error in unique_errors:
            print(f"KO  {error}")
        print()
        print(f"Verdict : DONNÉES SENSIBLES DÉTECTÉES ({len(unique_errors)})")
        return 1

    print(f"OK  {len(files)} fichier(s) suivi(s) contrôlé(s)")
    print("Verdict : AUCUN SECRET OU FICHIER SENSIBLE DÉTECTÉ")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="racine du dépôt à contrôler",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    if not (root / ".gitignore").is_file():
        print(f"Racine de dépôt invalide : {root}", file=sys.stderr)
        return 2
    return audit(root)


if __name__ == "__main__":
    raise SystemExit(main())
