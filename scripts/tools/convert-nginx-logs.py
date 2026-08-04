#!/usr/bin/env python3
"""Convertit des logs NGINX combined en NDJSON compatible avec l'API Bulk."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import TextIO

LOG_PATTERN = re.compile(
    r'^(?P<remote_addr>\S+)\s+-\s+(?P<remote_user>\S+)\s+'
    r'\[(?P<time_local>[^\]]+)\]\s+'
    r'"(?P<http_method>[A-Z]+)\s+(?P<url_path>\S+)\s+'
    r'(?P<http_protocol>[^"]+)"\s+'
    r'(?P<status>\d{3})\s+(?P<bytes_sent>\d+|-)\s+'
    r'"(?P<referrer>[^"]*)"\s+"(?P<user_agent>[^"]*)"$'
)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convertit un fichier NGINX au format combined en paires "
            "action/document NDJSON pour OpenSearch."
        )
    )
    parser.add_argument("input", type=Path, help="fichier de logs NGINX")
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        help="fichier NDJSON de sortie ; stdout si omis",
    )
    parser.add_argument(
        "--index-prefix",
        default="nginx-access",
        help="préfixe d'index OpenSearch (défaut : nginx-access)",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="valide toutes les lignes sans produire de NDJSON",
    )
    return parser.parse_args()


def parse_line(
    line: str,
    line_number: int,
    source: Path,
    index_prefix: str,
) -> tuple[str, dict[str, object]]:
    match = LOG_PATTERN.fullmatch(line)
    if match is None:
        raise ValueError(
            f"{source}:{line_number}: ligne incompatible avec le format NGINX combined"
        )

    fields = match.groupdict()
    timestamp = datetime.strptime(fields["time_local"], "%d/%b/%Y:%H:%M:%S %z")
    index_name = f"{index_prefix}-{timestamp:%Y.%m.%d}"

    document: dict[str, object] = {
        "@timestamp": timestamp.isoformat(),
        "remote_addr": fields["remote_addr"],
        "remote_user": fields["remote_user"],
        "http_method": fields["http_method"],
        "url_path": fields["url_path"],
        "http_protocol": fields["http_protocol"],
        "status": int(fields["status"]),
        "bytes_sent": 0 if fields["bytes_sent"] == "-" else int(fields["bytes_sent"]),
        "referrer": fields["referrer"],
        "user_agent": fields["user_agent"],
        "request": (
            f'{fields["http_method"]} {fields["url_path"]} '
            f'{fields["http_protocol"]}'
        ),
        "source_file": source.name,
        "line_number": line_number,
    }
    return index_name, document


def write_json(stream: TextIO, payload: dict[str, object]) -> None:
    stream.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    stream.write("\n")


def main() -> int:
    args = parse_arguments()

    if not args.input.is_file():
        print(f"Fichier introuvable : {args.input}", file=sys.stderr)
        return 2
    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", args.index_prefix):
        print("Le préfixe d'index contient un caractère interdit.", file=sys.stderr)
        return 2

    output_stream: TextIO
    output_file: TextIO | None = None
    if args.validate_only or args.output is None:
        output_stream = sys.stdout
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        output_file = args.output.open("w", encoding="utf-8", newline="\n")
        output_stream = output_file

    document_count = 0
    first_timestamp: str | None = None
    last_timestamp: str | None = None

    try:
        with args.input.open(encoding="utf-8") as source_stream:
            for line_number, raw_line in enumerate(source_stream, start=1):
                line = raw_line.rstrip("\n")
                if not line.strip():
                    continue

                index_name, document = parse_line(
                    line,
                    line_number,
                    args.input,
                    args.index_prefix,
                )
                timestamp = str(document["@timestamp"])
                first_timestamp = first_timestamp or timestamp
                last_timestamp = timestamp
                document_count += 1

                if not args.validate_only:
                    write_json(output_stream, {"index": {"_index": index_name}})
                    write_json(output_stream, document)
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    finally:
        if output_file is not None:
            output_file.close()

    if document_count == 0:
        print("Le fichier ne contient aucun document exploitable.", file=sys.stderr)
        return 1

    print(
        (
            f"Documents valides : {document_count} | "
            f"période : {first_timestamp} → {last_timestamp}"
        ),
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
