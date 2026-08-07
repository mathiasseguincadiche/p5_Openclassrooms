# Application du projet P5

Ce dossier porte la partie applicative nécessaire à l'exercice 1. Le projet reste
volontairement orienté infrastructure : l'application est une **SPA Angular réelle,
autonome et compilable**, utilisée pour démontrer le build, le déploiement Ansible
et le service NGINX sur EC2.

La référence fonctionnelle complète de l'exercice se trouve dans
[`docs/exercices/01-terraform-ansible.md`](../docs/exercices/01-terraform-ansible.md).

## Responsabilité du dossier

```text
application/
└── angular/                  # sources Angular et tests
        │
        │ npm ci + lint + tests + build
        ▼
application/angular/dist/    # build local ignoré par Git
        │
        │ prepare-angular-artifact.sh
        ▼
ansible/files/angular-app/   # artefact de production versionné
        │
        │ ansible-playbook
        ▼
EC2 /var/www/p5 → NGINX :80
```

`application/angular/` est la **source applicative**. `ansible/files/angular-app/`
est l'artefact exact déployé. Les deux doivent rester synchronisés.

## Contrat de reproductibilité

Les dépendances sont verrouillées par `package-lock.json`. Le socle du lab fixe
Node.js dans `environment/versions.env` et `package.json` définit les dépendances
Angular ainsi que les commandes de contrôle.

Validation locale ciblée :

```bash
npm ci --prefix application/angular --no-audit --no-fund
npm run lint --prefix application/angular
npm test --prefix application/angular
npm run security:dependencies --prefix application/angular
npm run build --prefix application/angular
```

La validation globale du dépôt exécute également ces contrôles :

```bash
./scripts/commands/validate.sh
```

## Préparer l'artefact Ansible

Depuis la racine :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script :

1. exige `package.json` et `package-lock.json` ;
2. exécute `npm ci` puis le build ;
3. exige un unique artefact navigateur contenant `index.html` ;
4. copie le résultat dans un dossier temporaire ;
5. ne remplace `ansible/files/angular-app/` qu'après un build réussi.

La CI reconstruit Angular et exécute un `diff` entre le build et l'artefact
Ansible. Une modification des sources non répercutée bloque donc la validation.

## Vérifier l'application réellement déployée

Après Terraform et Ansible :

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le script lit par défaut `terraform/exercice-1` → `web_url` et vérifie :

- HTTP 200 sur `/` ;
- présence de `<app-root>` ;
- chargement du bundle JavaScript principal ;
- fallback SPA sur `/parcours-p5` ;
- en-tête `X-Content-Type-Options: nosniff`.

Le verdict attendu est :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Les résultats restent localement sous `proofs/runtime/exercice-1/`.

## Ce que l'application ne fait pas

- pas d'API métier ;
- pas de backend applicatif ;
- pas de base de données ;
- pas d'asset externe indispensable ;
- pas de secret ;
- pas de dépendance à OpenSearch ou HAProxy pour fonctionner.

Ce choix garde l'évaluation centrée sur Terraform, Ansible, NGINX et
l'exploitation de l'infrastructure.

## Documentation associée

- [Détails du projet Angular](angular/README.md)
- [Déploiement Ansible](../ansible/README.md)
- [Architecture et flux](../docs/architecture-et-flux.md)
- [Exercice 1 complet](../docs/exercices/01-terraform-ansible.md)
