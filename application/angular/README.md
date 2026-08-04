# Sources Angular

Copiez ici l’application Angular fournie pour le projet, avec au minimum :

```text
application/angular/
├── angular.json
├── package.json
├── package-lock.json
├── src/
└── tsconfig.json
```

Puis exécutez depuis la racine du dépôt :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script installe les dépendances avec `npm ci`, lance le build défini par le
projet, détecte le dossier contenant `index.html` sous `dist/` et remplace
l’artefact de démonstration dans `ansible/files/angular-app/`.

Le dossier `dist/` local reste ignoré par Git. L’artefact Ansible peut être
versionné pour démontrer exactement ce qui a été déployé.
