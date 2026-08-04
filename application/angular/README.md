# Application Angular du P5

Ce dossier contient l'application utilisée dans l'exercice 1. Elle est conçue
comme une SPA légère, sans API ni ressource externe, afin que la démonstration
reste centrée sur l'infrastructure et le déploiement.

## Structure

```text
application/angular/
├── angular.json
├── package.json
├── package-lock.json
├── tsconfig.json
├── tsconfig.app.json
├── public/
│   └── favicon.svg
└── src/
    ├── index.html
    ├── main.ts
    ├── styles.css
    └── app/
        ├── app.component.ts
        ├── app.component.html
        └── app.component.css
```

## Exécution locale

```bash
cd application/angular
npm ci
npm start
```

L'application est alors disponible sur `http://localhost:4200`.

## Build de production

Depuis la racine du dépôt :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Cette commande :

1. installe exactement les dépendances du fichier `package-lock.json` ;
2. lance le build Angular de production ;
3. vérifie qu'un seul artefact navigateur contient `index.html` ;
4. copie cet artefact dans `ansible/files/angular-app/` ;
5. laisse le dossier `dist/` local ignoré par Git.

## Contrat de synchronisation

Le code source et l'artefact Ansible doivent toujours correspondre. La CI
reconstruit l'application puis compare le résultat avec
`ansible/files/angular-app/`. Une différence signifie qu'il faut relancer le
script de préparation et examiner le nouveau build avant de le versionner.

## Vérification sur AWS

Après le playbook Ansible :

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le contrôle HTTP ne remplace pas l'ouverture de l'application dans un
navigateur. Il fournit cependant une preuve reproductible du document Angular,
du bundle principal, du fallback SPA et de la configuration NGINX.
