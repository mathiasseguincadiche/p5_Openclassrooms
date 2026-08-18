from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"Bloc attendu introuvable: {label}")
    path.write_text(text.replace(old, new, 1))


ci_path = Path('.github/workflows/ci.yml')
replace_once(
    ci_path,
    """            application/angular/package-lock.json
            application/angular/src/main.ts
            application/angular/tests/app-contract.test.mjs
""",
    """            application/angular/package-lock.json
            application/angular/eslint.config.js
            application/angular/tsconfig.spec.json
            application/angular/src/main.ts
            application/angular/src/app/app.component.spec.ts
            application/angular/tests/app-contract.test.mjs
""",
    'contrat des fichiers Angular dans ci.yml',
)
replace_once(
    ci_path,
    """      - name: Vérifier TypeScript et le contrat applicatif
        run: |
          npm run lint --prefix application/angular
          npm test --prefix application/angular
""",
    """      - name: Vérifier TypeScript, ESLint et les tests
        run: |
          npm run typecheck --prefix application/angular
          npm run lint --prefix application/angular
          npm test --prefix application/angular
""",
    'étape Angular dans ci.yml',
)

readme_path = Path('application/angular/README.md')
replace_once(
    readme_path,
    """application/angular/
├── angular.json
├── package.json
├── package-lock.json
├── tsconfig.json
├── tsconfig.app.json
├── public/
│   └── favicon.svg
├── tests/
│   └── app-contract.test.mjs
└── src/
    ├── index.html
    ├── main.ts
    ├── styles.css
    └── app/
        ├── app.component.ts
        ├── app.component.html
        └── app.component.css
""",
    """application/angular/
├── angular.json
├── eslint.config.js
├── package.json
├── package-lock.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.spec.json
├── public/
│   └── favicon.svg
├── tests/
│   └── app-contract.test.mjs
└── src/
    ├── index.html
    ├── main.ts
    ├── styles.css
    └── app/
        ├── app.component.ts
        ├── app.component.html
        ├── app.component.css
        └── app.component.spec.ts
""",
    'arborescence Angular dans le README',
)
replace_once(
    readme_path,
    """npm ci --prefix application/angular --no-audit --no-fund
npm run lint --prefix application/angular
npm test --prefix application/angular
npm run security:dependencies --prefix application/angular
npm run build --prefix application/angular
""",
    """npm ci --prefix application/angular --no-audit --no-fund
npm run typecheck --prefix application/angular
npm run lint --prefix application/angular
npm run test:contract --prefix application/angular
npm run test:unit --prefix application/angular
npm test --prefix application/angular
npm run security:dependencies --prefix application/angular
npm run build --prefix application/angular
""",
    'commandes Angular dans le README',
)
replace_once(
    readme_path,
    """- la compilation TypeScript ;
- le contrat fonctionnel minimal de l'application ;
- les dépendances de production avec `npm audit` ;
- le build de production ;
- la synchronisation du build avec Ansible.
""",
    """- la vérification des types TypeScript ;
- le lint TypeScript et templates Angular avec ESLint ;
- le contrat fonctionnel minimal du dépôt ;
- le rendu réel du composant racine avec Vitest et jsdom ;
- les dépendances de production avec `npm audit` ;
- le build de production ;
- la synchronisation du build avec Ansible.
""",
    'contrôles Angular dans le README',
)
