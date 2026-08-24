#!/usr/bin/env python3
"""Entrée canonique de l'audit de non-régression du projet P5.

Le cœur historique est conservé dans ``audit_non_regression_core.py``. Cette
couche adapte uniquement le contrat des schémas afin de distinguer :

- les six schémas techniques historiques ;
- les trois schémas détaillés de préparation à la soutenance ;
- les quatre nouveaux masters SVG officiels haute qualité.

L'ajout d'un support visuel ne doit plus être interprété comme une régression,
tout en conservant les contrôles stricts historiques sur les six schémas de
référence et des contrôles de pureté vectorielle sur les masters officiels.
"""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

import audit_non_regression_core as core

REFERENCE_SCHEMAS = core.SCHEMAS

SOUTENANCE_SCHEMAS = (
    "docs/schemas/soutenance/exercice-1-detaille.svg",
    "docs/schemas/soutenance/exercice-2-detaille.svg",
    "docs/schemas/soutenance/exercice-3-detaille.svg",
)

OFFICIAL_SCHEMAS = (
    "docs/schemas/officiels/vue-ensemble.svg",
    "docs/schemas/officiels/exercice-1.svg",
    "docs/schemas/officiels/exercice-2.svg",
    "docs/schemas/officiels/exercice-3.svg",
)

REQUIRED_SCHEMAS = REFERENCE_SCHEMAS + SOUTENANCE_SCHEMAS + OFFICIAL_SCHEMAS


class Audit(core.Audit):
    """Audit P5 avec contrat de schémas extensible et masters HQ contrôlés."""

    def _audit_reference_schemas(self) -> None:
        """Conserve les contraintes historiques des six schémas techniques."""
        titles: list[str] = []
        canvas_sizes: list[tuple[int, int]] = []
        forbidden_tags = {"script", "foreignObject", "filter", "image"}

        for relative in REFERENCE_SCHEMAS:
            file = self.path(relative)
            if not self.require_file(relative):
                continue
            if file.stat().st_size > core.MAX_SVG_BYTES:
                self.fail(f"SVG trop lourd ({file.stat().st_size} octets) : {relative}")
                continue
            try:
                root = ET.parse(file).getroot()
            except ET.ParseError as exc:
                self.fail(f"SVG XML invalide {relative} : {exc}")
                continue

            local_name = root.tag.rsplit("}", 1)[-1]
            if local_name != "svg":
                self.fail(f"racine SVG invalide : {relative}")
                continue
            if root.attrib.get("role") != "img":
                self.fail(f"role=img absent : {relative}")
            aria_labelledby = root.attrib.get("aria-labelledby", "")
            if "title" not in aria_labelledby or "desc" not in aria_labelledby:
                self.fail(f"aria-labelledby incomplet : {relative}")

            try:
                width = int(float(root.attrib["width"]))
                height = int(float(root.attrib["height"]))
            except (KeyError, ValueError):
                self.fail(f"dimensions explicites invalides : {relative}")
                continue
            if width > core.MAX_SVG_WIDTH or height > core.MAX_SVG_HEIGHT:
                self.fail(
                    f"canevas trop grand pour README/Markdown : {relative} "
                    f"({width}x{height})"
                )
            if not root.attrib.get("viewBox"):
                self.fail(f"viewBox absent : {relative}")
            if width / height < 1.7:
                self.fail(f"ratio trop vertical pour intégration Markdown : {relative}")
            canvas_sizes.append((width, height))

            tags = Counter(element.tag.rsplit("}", 1)[-1] for element in root.iter())
            present_forbidden = sorted(tag for tag in forbidden_tags if tags[tag])
            if present_forbidden:
                self.fail(
                    f"éléments SVG interdits dans {relative} : "
                    + ", ".join(present_forbidden)
                )
            if tags["text"] > 35:
                self.fail(f"trop de blocs texte dans {relative} : {tags['text']}")

            title = next(
                (
                    (element.text or "").strip()
                    for element in root.iter()
                    if element.tag.rsplit("}", 1)[-1] == "title"
                ),
                "",
            )
            desc = next(
                (
                    (element.text or "").strip()
                    for element in root.iter()
                    if element.tag.rsplit("}", 1)[-1] == "desc"
                ),
                "",
            )
            if not title or not desc:
                self.fail(f"title ou desc accessible absent : {relative}")
            titles.append(title)

            text = file.read_text(encoding="utf-8")
            external = r"(?:href|xlink:href)\s*=\s*[\"'](?:https?:|data:)"
            if re.search(external, text, re.IGNORECASE):
                self.fail(f"dépendance externe ou image encodée dans {relative}")

        if len(set(titles)) != len(titles):
            self.fail("les titres accessibles des schémas techniques ne sont pas uniques")
        else:
            self.ok("six schémas techniques accessibles avec des titres uniques")
        if len(set(canvas_sizes)) < 3:
            self.fail("identités graphiques insuffisantes : moins de trois canevas distincts")
        else:
            self.ok("compositions techniques spécialisées avec plusieurs canevas adaptés")

        readme = self.path("README.md").read_text(encoding="utf-8")
        missing_links = [schema for schema in REFERENCE_SCHEMAS if schema not in readme]
        if missing_links:
            self.fail("schémas techniques non intégrés au README : " + ", ".join(missing_links))
        else:
            self.ok("six schémas techniques intégrés au README")

    def _audit_official_schemas(self) -> None:
        """Vérifie que les quatre masters officiels restent de vrais SVG vectoriels."""
        forbidden_tags = {"script", "foreignObject", "filter", "image"}
        titles: list[str] = []

        for relative in OFFICIAL_SCHEMAS:
            file = self.path(relative)
            if not self.require_file(relative):
                continue
            try:
                root = ET.parse(file).getroot()
            except ET.ParseError as exc:
                self.fail(f"master SVG officiel invalide {relative} : {exc}")
                continue

            if root.tag.rsplit("}", 1)[-1] != "svg":
                self.fail(f"racine SVG officielle invalide : {relative}")
                continue
            if root.attrib.get("role") != "img":
                self.fail(f"role=img absent du master officiel : {relative}")
            aria_labelledby = root.attrib.get("aria-labelledby", "")
            if "title" not in aria_labelledby or "desc" not in aria_labelledby:
                self.fail(f"aria-labelledby incomplet sur le master officiel : {relative}")
            if not root.attrib.get("viewBox"):
                self.fail(f"viewBox absent du master officiel : {relative}")

            try:
                width = float(root.attrib["width"])
                height = float(root.attrib["height"])
            except (KeyError, ValueError):
                self.fail(f"dimensions explicites invalides : {relative}")
                continue
            if width <= 0 or height <= 0:
                self.fail(f"dimensions non positives : {relative}")

            tags = Counter(element.tag.rsplit("}", 1)[-1] for element in root.iter())
            present_forbidden = sorted(tag for tag in forbidden_tags if tags[tag])
            if present_forbidden:
                self.fail(
                    f"master officiel non vectoriel ou non sûr {relative} : "
                    + ", ".join(present_forbidden)
                )

            title = next(
                (
                    (element.text or "").strip()
                    for element in root.iter()
                    if element.tag.rsplit("}", 1)[-1] == "title"
                ),
                "",
            )
            desc = next(
                (
                    (element.text or "").strip()
                    for element in root.iter()
                    if element.tag.rsplit("}", 1)[-1] == "desc"
                ),
                "",
            )
            if not title or not desc:
                self.fail(f"title ou desc accessible absent du master officiel : {relative}")
            titles.append(title)

            text = file.read_text(encoding="utf-8")
            external = r"(?:href|xlink:href)\s*=\s*[\"'](?:https?:|data:)"
            if re.search(external, text, re.IGNORECASE):
                self.fail(f"dépendance externe ou raster encodé dans le master : {relative}")

            fallback = file.with_suffix(".webp")
            if not fallback.is_file() or fallback.stat().st_size == 0:
                self.fail(f"fallback WebP officiel absent : {fallback.relative_to(self.root)}")

        if len(titles) == len(OFFICIAL_SCHEMAS) and len(set(titles)) == len(titles):
            self.ok("quatre masters officiels HQ accessibles, vectoriels et autonomes")
        elif len(titles) == len(OFFICIAL_SCHEMAS):
            self.fail("les titres accessibles des masters officiels ne sont pas uniques")

        link_targets = tuple(relative.removeprefix("docs/") for relative in OFFICIAL_SCHEMAS)
        canonical_docs = (
            "docs/README.md",
            "docs/RUNBOOK_SOUTENANCE.md",
            "docs/RUNBOOK_EXECUTION_GUIDEE.md",
        )
        for document in canonical_docs:
            content = self.path(document).read_text(encoding="utf-8")
            missing = [target for target in link_targets if target not in content]
            if missing:
                self.fail(f"masters officiels absents de {document} : {', '.join(missing)}")
            else:
                self.ok(f"quatre masters officiels intégrés à {document}")

    def audit_schemas(self) -> None:
        missing = [relative for relative in REQUIRED_SCHEMAS if not self.path(relative).is_file()]
        if missing:
            self.fail("schémas requis absents : " + ", ".join(missing))
            return
        self.ok(
            "schémas requis présents : 6 techniques + 3 détaillés + 4 masters officiels HQ"
        )

        self._audit_reference_schemas()
        self._audit_official_schemas()

        soutenance_index = self.path("docs/soutenance/README.md").read_text(encoding="utf-8")
        missing_detailed = [
            "../" + relative.removeprefix("docs/")
            for relative in SOUTENANCE_SCHEMAS
            if "../" + relative.removeprefix("docs/") not in soutenance_index
        ]
        if missing_detailed:
            self.fail(
                "schémas détaillés non référencés dans docs/soutenance/README.md : "
                + ", ".join(missing_detailed)
            )
        else:
            self.ok("trois schémas détaillés référencés dans le portail de soutenance")


def main() -> int:
    args = core.parse_args()
    root: Path = args.root.resolve()
    if not (root / ".github" / "workflows" / "ci.yml").is_file():
        print(f"Racine de dépôt invalide : {root}", file=sys.stderr)
        return 2
    return Audit(root).run(schemas_only=args.schemas_only)


if __name__ == "__main__":
    raise SystemExit(main())
