# Application Angular du P5

Ce dossier contient la SPA utilisée comme charge applicative de l'exercice 1.
Elle doit rester **simple, autonome et reproductible** : le but du projet est de
démontrer l'infrastructure et le déploiement, pas de développer un backend métier.

## Structure

```text
application/angular/
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
```

## Commandes locales

Depuis la racine du dépôt :

```bash
npm ci --prefix application/angular --no-audit --no-fund
npm run typecheck --prefix application/angular
npm run lint --prefix application/angular
npm run test:contract --prefix application/angular
npm run test:unit --prefix application/angular
npm test --prefix application/angular
npm run security:dependencies --prefix application/angular
npm run build --prefix application/angular
```

`npm test` conserve les deux couches de tests et déclenche automatiquement le
`typecheck` via le hook npm `pretest`. La CI existante exécute donc le vrai lint
ESLint puis l'ensemble typecheck + tests sans confondre les scripts entre eux.

Pour lancer le serveur de développement :

```bash
npm start --prefix application/angular
```

L'application est alors disponible sur `http://localhost:4200`.

## Versions et dépendances

La version Node.js de référence est définie dans `environment/versions.env`.
`package-lock.json` est obligatoire : le pipeline utilise `npm ci` afin de
reproduire exactement l'arbre des dépendances validé.

Le dépôt contrôle :

- la vérification des types TypeScript ;
- le lint TypeScript et templates Angular avec ESLint ;
- le contrat fonctionnel minimal du dépôt ;
- le rendu réel du composant racine avec Vitest et jsdom ;
- les dépendances de production avec `npm audit` ;
- le build de production ;
- la synchronisation du build avec Ansible.

## Build destiné à Ansible

Ne copiez pas manuellement `dist/` vers Ansible. Utilisez :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le flux attendu est :

```text
sources Angular
  → npm ci
  → npm run build
  → application/angular/dist/
  → copie contrôlée
  → ansible/files/angular-app/
```

Le dossier `dist/` est local et ignoré par Git. L'artefact dans
`ansible/files/angular-app/` est versionné parce qu'il constitue le contenu
exact copié sur l'EC2 pendant la démonstration.

## Contrat de synchronisation

La CI reconstruit l'application puis compare le build à
`ansible/files/angular-app/`. Toute divergence signifie que les sources et
l'artefact déployable ne correspondent plus.

Après une modification applicative :

```bash
./scripts/commands/prepare-angular-artifact.sh
./scripts/commands/validate.sh
```

## Vérification sur AWS

Après le déploiement Ansible :

```bash
./scripts/commands/verify-angular-deployment.sh
```

Ce contrôle prouve de manière reproductible :

- le document Angular ;
- le bundle principal ;
- le fallback SPA NGINX ;
- l'accessibilité HTTP ;
- un en-tête de sécurité attendu.

L'ouverture dans un navigateur et la capture destinée au livrable restent une
validation humaine complémentaire.

## Références

- [Application et chaîne de build](../README.md)
- [Exercice 1 complet](../../docs/exercices/01-terraform-ansible.md)
- [Déploiement Ansible](../../ansible/README.md)
