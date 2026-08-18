#!/usr/bin/env python3
"""Audit non destructif du contrat de non-régression du projet P5."""

from __future__ import annotations

import argparse
import json
import re
import stat
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path, PurePosixPath

BASELINE_COMMIT = "2e0600fbf573815077cf541e30a0d9d01591a180"
MAX_SVG_BYTES = 8 * 1024
MAX_SVG_WIDTH = 1200
MAX_SVG_HEIGHT = 650

CAPABILITIES: dict[str, tuple[str, ...]] = {
    "pilotage et documentation": (
        "README.md",
        "docs/00-cadre-officiel.md",
        "docs/00-preparation-environnement.md",
        "docs/00b-preparation-compte-aws.md",
        "docs/01-parcours-debutant.md",
        "docs/02-correspondance-consignes-depot.md",
        "docs/03-audit-structurel.md",
        "docs/04-audit-non-regression.md",
        "docs/suivi/decisions-techniques.md",
        "docs/suivi/journal-de-session.md",
    ),
    "préparation et garde-fous AWS": (
        "environment/versions.env",
        "environment/wsl2/README.md",
        "environment/aws-readiness.env.example",
        "aws/README.md",
        "aws/iam/p5-lab-policy.json",
        "aws/budgets/p5-monthly-budget.json.example",
        "scripts/lib/p5-platform.sh",
        "scripts/commands/bootstrap-wsl2.sh",
        "scripts/commands/bootstrap-ubuntu-server.sh",
        "scripts/commands/setup.sh",
        "scripts/commands/setup-aws-guardrails.sh",
        "scripts/commands/check-aws-readiness.sh",
        "scripts/commands/pre-deployment-check.sh",
    ),
    "application Angular et déploiement Ansible": (
        "application/angular/angular.json",
        "application/angular/package.json",
        "application/angular/package-lock.json",
        "application/angular/src/main.ts",
        "application/angular/src/app/app.component.ts",
        "application/angular/src/app/app.component.html",
        "ansible/files/angular-app/index.html",
        "ansible/files/nginx-angular.conf",
        "ansible/inventories/hosts_aws.example",
        "ansible/playbooks/deploy.yml",
        "scripts/commands/prepare-angular-artifact.sh",
        "scripts/commands/verify-angular-deployment.sh",
        "scripts/commands/generate-nginx-traffic.sh",
        "scripts/commands/collect-nginx-access-log.sh",
    ),
    "OpenSearch reproductible": (
        "terraform/exercice-2/opensearch/index-template.json",
        "terraform/exercice-2/samples/nginx-access.log.sample",
        "scripts/tools/convert-nginx-logs.py",
        "scripts/commands/import-opensearch-data.sh",
        "scripts/commands/verify-opensearch-data.sh",
    ),
    "HAProxy et reprise": (
        "terraform/exercice-3/haproxy.cfg.tpl",
        "scripts/tools/generer-haproxy-config.sh",
        "scripts/commands/test-haproxy-roundrobin.sh",
        "scripts/commands/test-haproxy-failover.sh",
    ),
    "preuves, livrables et nettoyage": (
        "proofs/README.md",
        "docs/livrables/README.md",
        "scripts/commands/prepare-livrables.sh",
        "scripts/commands/destroy-aws.sh",
        "scripts/commands/check-aws-cleanup.sh",
    ),
    "validation continue": (
        ".github/workflows/ci.yml",
        ".github/workflows/non-regression.yml",
        ".github/workflows/wsl2-devops-contract.yml",
        "scripts/commands/validate.sh",
        "scripts/tools/audit_non_regression.py",
    ),
}

SHELL_SCRIPTS = (
    "scripts/lib/p5-platform.sh",
    "scripts/commands/bootstrap-wsl2.sh",
    "scripts/commands/bootstrap-ubuntu-server.sh",
    "scripts/commands/setup.sh",
    "scripts/commands/setup-aws-guardrails.sh",
    "scripts/commands/check-aws-readiness.sh",
    "scripts/commands/pre-deployment-check.sh",
    "scripts/commands/validate.sh",
    "scripts/commands/prepare-angular-artifact.sh",
    "scripts/commands/verify-angular-deployment.sh",
    "scripts/commands/generate-nginx-traffic.sh",
    "scripts/commands/collect-nginx-access-log.sh",
    "scripts/commands/import-opensearch-data.sh",
    "scripts/commands/verify-opensearch-data.sh",
    "scripts/commands/test-haproxy-roundrobin.sh",
    "scripts/commands/test-haproxy-failover.sh",
    "scripts/commands/prepare-livrables.sh",
    "scripts/commands/destroy-aws.sh",
    "scripts/commands/check-aws-cleanup.sh",
    "scripts/tools/generer-haproxy-config.sh",
)

SCHEMAS = (
    "docs/schemas/vue-ensemble.svg",
    "docs/schemas/etape-0.svg",
    "docs/schemas/exercice-1.svg",
    "docs/schemas/exercice-2.svg",
    "docs/schemas/exercice-3.svg",
    "docs/schemas/finalisation/finalisation.svg",
)

STALE_CLAIMS = (
    "ne contient pas le projet angular source",
    "support statique temporaire",
    "ne peut pas contenir le véritable starter angular",
    "page html témoin sans sources structurées",
)

FORBIDDEN_TRACKED_PATTERNS = (
    "**/terraform.tfstate",
    "**/terraform.tfstate.*",
    "**/terraform.tfvars",
    "environment/aws-readiness.env",
    "ansible/inventories/hosts_aws",
)


class Audit:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.errors: list[str] = []
        self.successes: list[str] = []

    def ok(self, message: str) -> None:
        self.successes.append(message)
        print(f"OK  {message}")

    def fail(self, message: str) -> None:
        self.errors.append(message)
        print(f"KO  {message}")

    def path(self, relative: str) -> Path:
        return self.root / relative

    def require_file(self, relative: str) -> bool:
        file = self.path(relative)
        if not file.is_file():
            self.fail(f"fichier requis absent : {relative}")
            return False
        if file.stat().st_size == 0:
            self.fail(f"fichier requis vide : {relative}")
            return False
        return True

    def require_text(self, relative: str, needles: tuple[str, ...]) -> None:
        file = self.path(relative)
        if not self.require_file(relative):
            return
        content = file.read_text(encoding="utf-8").lower()
        missing = [needle for needle in needles if needle.lower() not in content]
        if missing:
            self.fail(f"marqueurs absents dans {relative} : {', '.join(missing)}")
        else:
            self.ok(f"sémantique vérifiée : {relative}")

    def tracked_files(self) -> tuple[str, ...]:
        try:
            result = subprocess.run(
                ["git", "-C", str(self.root), "ls-files", "-z"],
                check=True,
                capture_output=True,
            )
        except (FileNotFoundError, subprocess.CalledProcessError) as exc:
            self.fail(f"impossible de lire les fichiers suivis par Git : {exc}")
            return ()
        return tuple(
            item.decode("utf-8", errors="surrogateescape")
            for item in result.stdout.split(b"\0")
            if item
        )

    def audit_scope(self) -> None:
        if self.path("TEMPLATES").exists():
            self.fail("le dossier générique TEMPLATES a été réintroduit")
        if self.path("docs/exercises").exists():
            self.fail("les anciens exercices génériques ont été réintroduits")

        exercise_docs = sorted(self.path("docs/exercices").glob("*.md"))
        terraform_modules = sorted(self.path("terraform").glob("exercice-[123]"))
        if len(exercise_docs) != 3:
            self.fail(f"3 guides d'exercice attendus, {len(exercise_docs)} trouvés")
        else:
            self.ok("trois guides d'exercice présents")
        if len(terraform_modules) != 3:
            self.fail(f"3 modules Terraform attendus, {len(terraform_modules)} trouvés")
        else:
            self.ok("trois modules Terraform présents")

        mermaid_files: list[str] = []
        for markdown in self.root.rglob("*.md"):
            try:
                text = markdown.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if "```mermaid" in text.lower():
                mermaid_files.append(str(markdown.relative_to(self.root)))
        if mermaid_files:
            self.fail("blocs Mermaid présents : " + ", ".join(mermaid_files))
        else:
            self.ok("aucun bloc Mermaid")

    def audit_capabilities(self) -> None:
        for capability, paths in CAPABILITIES.items():
            missing = [path for path in paths if not self.require_file(path)]
            if not missing:
                self.ok(f"capacité conservée : {capability}")

        deliverables = sorted(self.path("docs/livrables").glob("SEGUIN-CADICHE_Mathias_[123]_*.md"))
        if len(deliverables) != 3:
            self.fail(f"3 livrables d'exercice attendus, {len(deliverables)} trouvés")
        else:
            self.ok("trois livrables d'exercice présents")

    def audit_shell_permissions(self) -> None:
        failed = False
        for relative in SHELL_SCRIPTS:
            file = self.path(relative)
            if not self.require_file(relative):
                failed = True
                continue
            mode = file.stat().st_mode
            if not mode & stat.S_IXUSR:
                self.fail(f"script non exécutable : {relative}")
                failed = True
            elif file.stat().st_size < 100:
                self.fail(f"script anormalement court : {relative}")
                failed = True
        if not failed:
            self.ok("permissions exécutables des scripts critiques")

    def audit_no_tracked_sensitive_files(self) -> None:
        found: list[str] = []
        for relative in self.tracked_files():
            posix_path = PurePosixPath(relative)
            if any(posix_path.match(pattern) for pattern in FORBIDDEN_TRACKED_PATTERNS):
                found.append(relative)
        if found:
            self.fail("fichiers locaux ou sensibles suivis par Git : " + ", ".join(sorted(set(found))))
        else:
            self.ok("aucun state, tfvars réel, inventaire réel ou configuration AWS locale suivi par Git")

    def audit_angular(self) -> None:
        package_file = self.path("application/angular/package.json")
        if not self.require_file("application/angular/package.json"):
            return
        try:
            package = json.loads(package_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            self.fail(f"package.json Angular invalide : {exc}")
            return
        dependencies = {**package.get("dependencies", {}), **package.get("devDependencies", {})}
        if "@angular/core" not in dependencies:
            self.fail("@angular/core absent du projet Angular")
        elif "build" not in package.get("scripts", {}):
            self.fail("script npm build absent du projet Angular")
        else:
            self.ok("sources Angular compilables présentes")

        component_files = (
            "application/angular/src/app/app.component.ts",
            "application/angular/src/app/app.component.html",
        )
        stale_runtime_labels = ("vm de lab", "construite sur la vm de lab", "ubuntu server 26.04")
        stale_locations: list[str] = []
        for relative in component_files:
            if not self.require_file(relative):
                continue
            text = self.path(relative).read_text(encoding="utf-8").lower()
            for label in stale_runtime_labels:
                if label in text:
                    stale_locations.append(f"{relative} : {label}")
        if stale_locations:
            self.fail("ancienne identité VM encore visible dans Angular : " + " | ".join(stale_locations))
        else:
            self.ok("application Angular alignée sur le runtime Windows 11 + WSL2")

        artifact_dir = self.path("ansible/files/angular-app")
        index = artifact_dir / "index.html"
        javascript = list(artifact_dir.glob("*.js"))
        if not index.is_file() or "<app-root" not in index.read_text(encoding="utf-8"):
            self.fail("artefact Angular Ansible invalide ou remplacé par une page témoin")
        elif not javascript:
            self.fail("bundle JavaScript Angular absent de l'artefact Ansible")
        else:
            self.ok("artefact Angular réel présent côté Ansible")

        self.require_text(
            "ansible/playbooks/deploy.yml",
            ("../files/angular-app/", "../files/nginx-angular.conf"),
        )

    def audit_terraform(self) -> None:
        for exercise in (1, 2, 3):
            main = f"terraform/exercice-{exercise}/main.tf"
            variables = f"terraform/exercice-{exercise}/variables.tf"
            tfvars = f"terraform/exercice-{exercise}/terraform.tfvars.example"
            self.require_text(main, ("allowed_account_ids", "default_tags", "p5-openclassrooms"))
            self.require_text(variables, ("expected_aws_account_id", "/32"))
            self.require_text(tfvars, ("expected_aws_account_id", "203.0.113.10/32"))

        self.require_text(
            "terraform/exercice-2/main.tf",
            ("opensearch_2.19", "encrypt_at_rest", "node_to_node_encryption", "enforce_https"),
        )
        self.require_text(
            "terraform/exercice-3/main.tf",
            ("count                       = 2", 'data "aws_vpc"', "haproxy.cfg.tpl"),
        )
        self.require_text(
            "terraform/exercice-3/haproxy.cfg.tpl",
            ("balance roundrobin", "option httpchk get /", "fall 3 rise 2"),
        )

    def audit_destructive_controls(self) -> None:
        self.require_text("scripts/commands/destroy-aws.sh", ("tapez exactement detruire", "3 2 1"))
        self.require_text("scripts/commands/test-haproxy-failover.sh", ("--apply", "trap"))
        self.require_text("scripts/commands/import-opensearch-data.sh", ("--apply",))
        self.require_text("scripts/commands/setup-aws-guardrails.sh", ("--apply",))

    def audit_documentation_consistency(self) -> None:
        markdown_files = list(self.root.rglob("*.md"))
        stale_locations: list[str] = []
        for markdown in markdown_files:
            try:
                content = markdown.read_text(encoding="utf-8").lower()
            except UnicodeDecodeError:
                continue
            for claim in STALE_CLAIMS:
                if claim in content:
                    stale_locations.append(f"{markdown.relative_to(self.root)} : {claim}")
        if stale_locations:
            self.fail("affirmations obsolètes : " + " | ".join(stale_locations))
        else:
            self.ok("aucune affirmation obsolète sur l'application Angular")

        self.require_text("README.md", ("go terraform", "nettoyage aws complet"))
        self.require_text("docs/04-audit-non-regression.md", (BASELINE_COMMIT, "contrat exécutable"))
        self.require_text(
            "docs/suivi/decisions-techniques.md",
            ("application angular", "t3.micro", "t3.small.search", "roundrobin"),
        )

    def audit_schemas(self) -> None:
        actual = sorted(
            str(path.relative_to(self.root))
            for path in self.path("docs/schemas").rglob("*.svg")
        )
        expected = sorted(SCHEMAS)
        if actual != expected:
            self.fail(f"schémas attendus : {expected}; trouvés : {actual}")
            return

        titles: list[str] = []
        canvas_sizes: list[tuple[int, int]] = []
        forbidden_tags = {"script", "foreignObject", "filter", "image"}
        for relative in SCHEMAS:
            file = self.path(relative)
            if file.stat().st_size > MAX_SVG_BYTES:
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
            if width > MAX_SVG_WIDTH or height > MAX_SVG_HEIGHT:
                self.fail(f"canevas trop grand pour README/Markdown : {relative} ({width}x{height})")
            if not root.attrib.get("viewBox"):
                self.fail(f"viewBox absent : {relative}")
            if width / height < 1.7:
                self.fail(f"ratio trop vertical pour intégration Markdown : {relative}")
            canvas_sizes.append((width, height))

            tags = Counter(element.tag.rsplit("}", 1)[-1] for element in root.iter())
            present_forbidden = sorted(tag for tag in forbidden_tags if tags[tag])
            if present_forbidden:
                self.fail(f"éléments SVG interdits dans {relative} : {', '.join(present_forbidden)}")
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
            self.fail("les titres accessibles des schémas ne sont pas uniques")
        else:
            self.ok("six schémas accessibles avec des titres uniques")
        if len(set(canvas_sizes)) < 3:
            self.fail("identités graphiques insuffisantes : moins de trois canevas distincts")
        else:
            self.ok("compositions spécialisées avec plusieurs canevas adaptés")

        readme = self.path("README.md").read_text(encoding="utf-8")
        missing_links = [schema for schema in SCHEMAS if schema not in readme]
        if missing_links:
            self.fail("schémas non intégrés au README : " + ", ".join(missing_links))
        else:
            self.ok("six schémas intégrés au README")

    def run(self, schemas_only: bool = False) -> int:
        if schemas_only:
            self.audit_schemas()
        else:
            self.audit_scope()
            self.audit_capabilities()
            self.audit_shell_permissions()
            self.audit_no_tracked_sensitive_files()
            self.audit_angular()
            self.audit_terraform()
            self.audit_destructive_controls()
            self.audit_documentation_consistency()
            self.audit_schemas()

        print()
        print(f"Synthèse : OK={len(self.successes)} | KO={len(self.errors)}")
        if self.errors:
            print("Verdict : RÉGRESSION DÉTECTÉE")
            return 1
        print("Verdict : CONTRAT DE NON-RÉGRESSION RESPECTÉ")
        return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="racine du dépôt à auditer",
    )
    parser.add_argument(
        "--schemas-only",
        action="store_true",
        help="ne contrôler que les six schémas et leur intégration",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    if not (root / ".github" / "workflows" / "ci.yml").is_file():
        print(f"Racine de dépôt invalide : {root}", file=sys.stderr)
        return 2
    return Audit(root).run(schemas_only=args.schemas_only)


if __name__ == "__main__":
    raise SystemExit(main())
