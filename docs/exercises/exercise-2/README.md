# 🚀 Exercice 2 : CI/CD avec GitHub Actions

**Bienvenue dans l'Exercice 2 !**
Ici, vous allez apprendre à **automatiser les tests et le déploiement** de votre application avec **GitHub Actions**. Cet exercice est conçu pour les **débutants en CI/CD** et couvre les bases de l'automatisation des workflows.

---

## 📌 Table des Matières

1. [🎯 Objectifs](#-objectifs)
2. [🛠️ Prérequis](#-prérequis)
3. [📥 Préparation de l'Environnement](#-préparation-de-lenvironnement)
4. [📝 Étape 1 : Créer un Dépôt GitHub](#-étape-1-créer-un-dépôt-github)
5. [📝 Étape 2 : Configurer un Workflow CI](#-étape-2-configurer-un-workflow-ci)
6. [📝 Étape 3 : Ajouter des Tests](#-étape-3-ajouter-des-tests)
7. [📝 Étape 4 : Configurer un Workflow CD](#-étape-4-configurer-un-workflow-cd)
8. [📝 Étape 5 : Utiliser des Secrets](#-étape-5-utiliser-des-secrets)
9. [✅ Vérification](#-vérification)
10. [🔍 Résolution des Problèmes](#-résolution-des-problèmes)
11. [📚 Pour Aller Plus Loin](#-pour-aller-plus-loin)

---

## 🎯 Objectifs

À la fin de cet exercice, vous serez capable de :
✅ **Comprendre** les concepts de base de la CI/CD.
✅ **Créer** un workflow GitHub Actions pour exécuter des tests automatiquement.
✅ **Configurer** un workflow pour construire et pousser une image Docker.
✅ **Déployer** une application automatiquement après un push.
✅ **Utiliser** des secrets pour sécuriser vos workflows.

---

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir :

| Outil | Version | Vérification | Lien d'Installation |
|-------|---------|--------------|---------------------|
| **Git** | 2.x | `git --version` | [git-scm.com](https://git-scm.com/) |
| **GitHub CLI** | 2.x | `gh --version` | [cli.github.com](https://cli.github.com/) |
| **Docker** | 24.x | `docker --version` | [docker.com](https://www.docker.com/) |
| **Docker Hub Account** | - | - | [hub.docker.com](https://hub.docker.com/) |
| **Node.js** | 18.x | `node --version` | [nodejs.org](https://nodejs.org/) |

> **⚠️ Important** : Vous devez avoir un **compte GitHub** et un **compte Docker Hub** pour cet exercice.

---

## 📥 Préparation de l'Environnement

### 1. Cloner le Dépôt du Projet P5
Si ce n'est pas déjà fait, clonez le dépôt :
```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 2. Créer un Dossier pour l'Exercice
```bash
mkdir -p ~/p5-exercise-2 && cd ~/p5-exercise-2
```

### 3. Initialiser un Projet Node.js
```bash
# Initialiser un projet Node.js
npm init -y

# Installer Express et un framework de test (Jest)
npm install express jest supertest

# Installer les dépendances de développement
npm install --save-dev jest supertest
```

### 4. Créer une Application Simple
Créez un fichier `app.js` :
```bash
nano app.js
```

Ajoutez le contenu suivant :
```javascript
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello, GitHub Actions! 🚀');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

module.exports = app;

// Démarrer le serveur seulement si le fichier est exécuté directement
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
  });
}
```

### 5. Créer un Test Unitaire
Créez un fichier `app.test.js` :
```bash
nano app.test.js
```

Ajoutez le contenu suivant :
```javascript
const request = require('supertest');
const app = require('./app');

describe('GET /', () => {
  it('responds with Hello, GitHub Actions! 🚀', async () => {
    const response = await request(app).get('/');
    expect(response.text).toBe('Hello, GitHub Actions! 🚀');
    expect(response.statusCode).toBe(200);
  });
});

describe('GET /health', () => {
  it('responds with status OK', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toEqual({ status: 'OK' });
    expect(response.statusCode).toBe(200);
  });
});
```

### 6. Mettre à Jour le `package.json`
Modifiez le `package.json` pour ajouter un script de test :
```bash
nano package.json
```

Remplacez la section `"scripts"` par :
```json
"scripts": {
  "start": "node app.js",
  "test": "jest"
}
```

### 7. Tester Localement
```bash
# Exécuter les tests
npm test
```

> **✅ Résultat attendu** : Vous devriez voir :
> ```
> PASS  ./app.test.js
>   GET /
>     ✓ responds with Hello, GitHub Actions! 🚀 (20 ms)
>   GET /health
>     ✓ responds with status OK (10 ms)
> 
> Test Suites: 1 passed, 1 total
> Tests:       2 passed, 2 total
> ```

---

## 📝 Étape 1 : Créer un Dépôt GitHub

### 1. Créer un Nouveau Dépôt
1. Allez sur [GitHub](https://github.com) et connectez-vous.
2. Cliquez sur le bouton **+** (en haut à droite) et sélectionnez **New repository**.
3. Remplissez les champs :
   - **Repository name** : `p5-exercise-2`
   - **Description** : `Exercice 2 - CI/CD avec GitHub Actions`
   - **Public/Private** : Public (ou Private si vous préférez)
   - **Initialize this repository with a README** : ❌ Non
   - **Add .gitignore** : Node
   - **Add a license** : MIT
4. Cliquez sur **Create repository**.

### 2. Lier le Dépôt Local au Dépôt GitHub
```bash
# Initialiser Git dans votre projet
cd ~/p5-exercise-2
git init

# Ajouter le dépôt distant
git remote add origin https://github.com/VOTRE_NOM_UTILISATEUR/p5-exercise-2.git

# Ajouter les fichiers et commiter
git add .
git commit -m "feat: initial commit with Node.js app and tests"

# Pousser vers GitHub
git branch -M main
git push -u origin main
```

> **✅ Résultat attendu** : Votre code est maintenant sur GitHub.

---

## 📝 Étape 2 : Configurer un Workflow CI

Un **workflow CI** (Continuous Integration) permet d'**exécuter automatiquement des tests** à chaque push ou pull request.

### 1. Créer le Dossier `.github/workflows`
```bash
mkdir -p .github/workflows
```

### 2. Créer un Fichier de Workflow CI
Créez un fichier `.github/workflows/ci.yml` :
```bash
nano .github/workflows/ci.yml
```

Ajoutez le contenu suivant :
```yaml
# =============================================
# Workflow CI pour Node.js
# Ce workflow s'exécute à chaque push ou pull request sur la branche main.
# =============================================

# Nom du workflow (affiché dans l'onglet Actions de GitHub)
name: CI - Node.js

# Déclencheurs : push ou pull request sur la branche main
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

# Jobs à exécuter
jobs:
  # Job 1 : Exécuter les tests
  test:
    # Utilise un runner Ubuntu (machine virtuelle fournie par GitHub)
    runs-on: ubuntu-latest

    # Étapes du job
    steps:
      # --- Étape 1 : Checkout du code ---
      # Récupère le code du dépôt dans le runner.
      - name: Checkout code
        uses: actions/checkout@v4

      # --- Étape 2 : Configuration de Node.js ---
      # Installe Node.js 18 sur le runner.
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18

      # --- Étape 3 : Installation des dépendances ---
      # Exécute `npm ci` pour installer les dépendances de manière déterministe.
      - name: Install dependencies
        run: npm ci

      # --- Étape 4 : Exécution des tests ---
      # Lance les tests avec `npm test`.
      - name: Run tests
        run: npm test

# =============================================
# Explications supplémentaires :
# - name : Nom de l'étape (affiché dans les logs).
# - uses : Utilise une action préexistante (ex: actions/checkout@v4).
# - run : Exécute une commande shell.
# - with : Passe des paramètres à une action.
# - runs-on : Spécifie le système d'exploitation du runner.
# =============================================
```

> **💡 Explication du Workflow** :
> | Étape | Description | Commande/Action |
> |-------|-------------|-----------------|
> | Checkout code | Récupère le code du dépôt. | `actions/checkout@v4` |
> | Setup Node.js | Installe Node.js 18. | `actions/setup-node@v4` |
> | Install dependencies | Installe les dépendances avec `npm ci`. | `npm ci` |
> | Run tests | Exécute les tests avec `npm test`. | `npm test` |

### 3. Commiter et Pousser le Workflow
```bash
# Ajouter le fichier de workflow
git add .github/workflows/ci.yml

# Commiter
git commit -m "feat: add CI workflow for Node.js"

# Pousser vers GitHub
git push origin main
```

### 4. Vérifier le Workflow sur GitHub
1. Allez sur votre dépôt GitHub : `https://github.com/VOTRE_NOM_UTILISATEUR/p5-exercise-2`.
2. Cliquez sur l'onglet **Actions**.
3. Vous devriez voir votre workflow **CI - Node.js** en cours d'exécution.
4. Cliquez sur le workflow pour voir les détails.

> **✅ Résultat attendu** : Le workflow devrait **réussir** (✅) et afficher :
> ```
> All tests passed!
> ```

---

## 📝 Étape 3 : Ajouter des Tests

Dans cette étape, nous allons **améliorer les tests** et ajouter un **linter** (ESLint) pour vérifier la qualité du code.

### 1. Installer ESLint
```bash
npm install --save-dev eslint eslint-config-airbnb-base eslint-plugin-import
```

### 2. Initialiser ESLint
```bash
npx eslint --init
```

> **Répondez aux questions comme suit** :
> ```
> ? How would you like to use ESLint? To check syntax, find problems, and enforce code style
> ? What type of modules does your project use? JavaScript modules (import/export)
> ? Which framework does your project use? None of these
> ? Does your project use TypeScript? No
> ? Where does your code run? Node
> ? How would you like to define a style for your project? Use a popular style guide
> ? Which style guide do you want to follow? Airbnb
> ? What format do you want your config file to be in? JavaScript
> ? Would you like to install them now? Yes
> ```

### 3. Modifier le Workflow CI pour Inclure ESLint
Modifiez le fichier `.github/workflows/ci.yml` :
```bash
nano .github/workflows/ci.yml
```

Remplacez le contenu par :
```yaml
name: CI - Node.js

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  test-and-lint:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          # Cache les dépendances npm pour accélérer les builds
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      # --- Nouvelle étape : Linting ---
      - name: Run linter
        run: npx eslint .
```

> **💡 Explication** :
> - `cache: 'npm'` : Active le cache pour les dépendances npm (accélère les builds).
> - `npx eslint .` : Exécute ESLint pour vérifier la qualité du code.

### 4. Commiter et Pousser les Changements
```bash
# Ajouter les fichiers modifiés
git add .

# Commiter
git commit -m "feat: add ESLint and update CI workflow"

# Pousser vers GitHub
git push origin main
```

### 5. Vérifier le Workflow sur GitHub
1. Allez dans l'onglet **Actions** de votre dépôt.
2. Vérifiez que le workflow **CI - Node.js** s'exécute avec succès.

> **✅ Résultat attendu** : Le workflow devrait réussir avec les étapes **Run tests** et **Run linter**.

---

## 📝 Étape 4 : Configurer un Workflow CD

Un **workflow CD** (Continuous Deployment) permet de **déployer automatiquement** votre application après un push réussi.

### 1. Créer un Fichier de Workflow CD
Créez un fichier `.github/workflows/cd.yml` :
```bash
nano .github/workflows/cd.yml
```

Ajoutez le contenu suivant :
```yaml
# =============================================
# Workflow CD pour déployer une image Docker sur Docker Hub
# Ce workflow s'exécute après un push réussi sur la branche main.
# =============================================

name: CD - Docker Hub

# Déclencheur : après un push réussi sur main
on:
  push:
    branches: [ "main" ]

# Jobs à exécuter
jobs:
  build-and-push:
    # Ce job dépend du succès du workflow CI
    needs: test-and-lint
    runs-on: ubuntu-latest

    steps:
      # --- Étape 1 : Checkout du code ---
      - name: Checkout code
        uses: actions/checkout@v4

      # --- Étape 2 : Configuration de Docker Buildx ---
      # Docker Buildx permet de construire des images multi-architectures.
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      # --- Étape 3 : Connexion à Docker Hub ---
      # Utilise les secrets DOCKER_USERNAME et DOCKER_PASSWORD.
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # --- Étape 4 : Construire et Pousser l'Image ---
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          # Contexte de build (répertoire courant)
          context: .
          # Fichier Dockerfile à utiliser
          file: ./Dockerfile
          # Nom et tag de l'image (ex: votre-nom/p5-exercise-2:latest)
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/p5-exercise-2:latest,${{ secrets.DOCKER_USERNAME }}/p5-exercise-2:${{ github.sha }}

# =============================================
# Explications supplémentaires :
# - needs : Ce job dépend du succès du job "test-and-lint" (du workflow CI).
# - secrets : Variables sécurisées stockées dans les secrets GitHub.
# - github.sha : Commit SHA unique pour chaque build.
# =============================================
```

> **⚠️ Problème** : Le workflow CD dépend du workflow CI, mais ils sont dans des fichiers séparés. Pour résoudre cela, nous allons **fusionner les deux workflows** dans un seul fichier.

### 2. Fusionner les Workflows CI et CD
Modifiez le fichier `.github/workflows/ci.yml` pour inclure le CD :
```bash
nano .github/workflows/ci.yml
```

Remplacez le contenu par :
```yaml
# =============================================
# Workflow CI/CD pour Node.js
# Ce workflow exécute des tests, du linting, et déploie une image Docker.
# =============================================

name: CI/CD - Node.js

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  # Job 1 : Tests et Linting
  test-and-lint:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linter
        run: npx eslint .

  # Job 2 : Build et Push de l'Image Docker (uniquement sur push vers main)
  build-and-push:
    # Ce job ne s'exécute que si le job "test-and-lint" réussit ET que c'est un push (pas une PR)
    needs: test-and-lint
    if: github.event_name == 'push'
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/p5-exercise-2:latest,${{ secrets.DOCKER_USERNAME }}/p5-exercise-2:${{ github.sha }}
```

> **💡 Explications des Modifications** :
> - `needs: test-and-lint` : Le job `build-and-push` dépend du succès du job `test-and-lint`.
> - `if: github.event_name == 'push'` : Le job `build-and-push` ne s'exécute que sur un **push** (pas sur une pull request).
> - `tags` : Deux tags sont utilisés : `latest` et le **SHA du commit** (pour une traçabilité unique).

### 3. Supprimer le Fichier `cd.yml`
```bash
rm .github/workflows/cd.yml
```

### 4. Créer un Dockerfile
Pour que le workflow CD fonctionne, nous avons besoin d'un `Dockerfile`. Créez-le :
```bash
nano Dockerfile
```

Ajoutez le contenu suivant :
```dockerfile
# =============================================
# Dockerfile pour l'application Node.js
# =============================================

# Image de base : Node.js 18 sur Alpine Linux
FROM node:18-alpine

# Répertoire de travail
WORKDIR /app

# Copie des fichiers de dépendances
COPY package*.json ./

# Installation des dépendances (y compris devDependencies pour le build)
RUN npm install

# Copie du reste de l'application
COPY . .

# Exposition du port
EXPOSE 3000

# Commande de démarrage
CMD ["node", "app.js"]
```

### 5. Commiter et Pousser les Changements
```bash
# Ajouter les fichiers modifiés
git add .

# Commiter
git commit -m "feat: add CI/CD workflow with Docker Hub deployment"

# Pousser vers GitHub
git push origin main
```

---

## 📝 Étape 5 : Utiliser des Secrets

Les **secrets GitHub** permettent de stocker des **informations sensibles** (mots de passe, clés API, etc.) de manière sécurisée.

### 1. Récupérer vos Identifiants Docker Hub
1. Allez sur [Docker Hub](https://hub.docker.com/) et connectez-vous.
2. Cliquez sur votre **nom d'utilisateur** (en haut à droite) puis sur **Account Settings**.
3. Allez dans l'onglet **Security**.
4. Créez un **Access Token** (si vous n'en avez pas) :
   - Cliquez sur **New Access Token**.
   - Donnez-lui un nom (ex: `p5-exercise-2`).
   - Cochez **Read, Write, Delete** pour les permissions.
   - Copiez le **token** (vous ne pourrez plus le voir après).

### 2. Ajouter les Secrets à GitHub
1. Allez sur votre dépôt GitHub : `https://github.com/VOTRE_NOM_UTILISATEUR/p5-exercise-2`.
2. Cliquez sur **Settings** (en haut à droite).
3. Dans le menu de gauche, cliquez sur **Secrets and variables** > **Actions**.
4. Cliquez sur **New repository secret**.
5. Ajoutez les deux secrets suivants :
   - **Name** : `DOCKER_USERNAME`
     **Value** : Votre nom d'utilisateur Docker Hub.
   - **Name** : `DOCKER_PASSWORD`
     **Value** : Le **Access Token** que vous avez créé.

> **⚠️ Important** : Ne **jamais** stocker de secrets dans le code ou dans les fichiers de configuration !

### 3. Vérifier le Workflow CD
1. Allez dans l'onglet **Actions** de votre dépôt.
2. Attendez que le workflow **CI/CD - Node.js** se termine.
3. Cliquez sur le workflow pour voir les détails.
4. Vérifiez que le job **build-and-push** a réussi.

> **✅ Résultat attendu** : Le workflow devrait **réussir** et pousser l'image vers Docker Hub.

### 4. Vérifier l'Image sur Docker Hub
1. Allez sur [Docker Hub](https://hub.docker.com/).
2. Cliquez sur votre **nom d'utilisateur** puis sur **Repositories**.
3. Vous devriez voir un dépôt nommé `p5-exercise-2` avec les tags `latest` et le SHA du commit.

---

## ✅ Vérification

Pour vérifier que vous avez **bien compris** cet exercice, répondez aux questions suivantes :

### 1. Qu'est-ce que la CI/CD ?
<details>
<summary>💡 Réponse</summary>
- **CI (Continuous Integration)** : Pratique qui consiste à **fusionner régulièrement** le code dans une branche principale et à **exécuter des tests automatiquement**.
- **CD (Continuous Deployment/Delivery)** : Pratique qui consiste à **déployer automatiquement** le code en production après un push réussi.
</details>

### 2. À quoi sert GitHub Actions ?
<details>
<summary>💡 Réponse</summary>
GitHub Actions est une plateforme de **CI/CD intégrée à GitHub** qui permet d'**automatiser des workflows** (tests, builds, déploiements) directement depuis votre dépôt.
</details>

### 3. Quelle est la différence entre `push` et `pull_request` dans les déclencheurs ?
<details>
<summary>💡 Réponse</summary>
- `push` : Le workflow s'exécute **après un commit poussé** vers la branche spécifiée.
- `pull_request` : Le workflow s'exécute **quand une pull request est ouverte ou mise à jour** vers la branche spécifiée.
</details>

### 4. À quoi sert `actions/checkout@v4` ?
<details>
<summary>💡 Réponse</summary>
`actions/checkout@v4` est une **action GitHub** qui **récupère le code de votre dépôt** dans le runner, afin que les étapes suivantes puissent y accéder.
</details>

### 5. À quoi sert `actions/setup-node@v4` ?
<details>
<summary>💡 Réponse</summary>
`actions/setup-node@v4` est une **action GitHub** qui **installe Node.js** (et npm/yarn) sur le runner, avec la version spécifiée.
</details>

### 6. Pourquoi utiliser `npm ci` au lieu de `npm install` ?
<details>
<summary>💡 Réponse</summary>
`npm ci` (Clean Install) est **déterministe** : il installe **exactement** les versions des dépendances spécifiées dans le `package-lock.json`, ce qui garantit une **reproductibilité** entre les environnements. `npm install` peut mettre à jour les dépendances si de nouvelles versions sont disponibles.
</details>

### 7. À quoi servent les secrets GitHub ?
<details>
<summary>💡 Réponse</summary>
Les **secrets GitHub** permettent de stocker des **informations sensibles** (mots de passe, clés API, tokens) de manière **sécurisée**, afin qu'elles ne soient pas exposées dans le code ou les logs.
</details>

### 8. Pourquoi utiliser deux tags pour l'image Docker (`latest` et `SHA`) ?
<details>
<summary>💡 Réponse</summary>
- **`latest`** : Tag générique qui pointe toujours vers la dernière version de l'image. Utile pour les environnements de développement.
- **`SHA`** : Tag unique pour chaque commit, ce qui permet de **retracer** exactement quelle version du code a été déployée. Utile pour la production et le débogage.
</details>

---

## 🔍 Résolution des Problèmes

Voici les **problèmes courants** et leurs solutions :

| **Problème** | **Cause Possible** | **Solution** |
|--------------|-------------------|--------------|
| Workflow bloqué sur "Waiting for status to be reported" | Problème temporaire avec GitHub Actions. | Attendez quelques minutes et rafraîchissez la page. |
| `Error: Unable to find image 'node:18-alpine'` | L'image Docker n'existe pas ou Docker Hub est inaccessible. | Vérifiez votre connexion Internet ou essayez une autre image (ex: `node:18`). |
| `Error: ENOENT: no such file or directory` | Le fichier ou dossier n'existe pas. | Vérifiez que le chemin est correct dans le workflow. |
| `Error: Authentication is required` (Docker Hub) | Les secrets Docker Hub ne sont pas configurés. | Vérifiez que `DOCKER_USERNAME` et `DOCKER_PASSWORD` sont corrects. |
| `Error: denied: requested access to the resource is denied` (Docker Hub) | Le token Docker Hub n'a pas les permissions nécessaires. | Régénérez un token avec les permissions **Read, Write, Delete**. |
| `Error: No such file or directory` (Dockerfile) | Le Dockerfile n'existe pas ou le chemin est incorrect. | Vérifiez que le `Dockerfile` est dans le bon dossier. |
| `Error: Process completed with exit code 1` (ESLint) | Le linter a trouvé des erreurs dans le code. | Exécutez `npx eslint .` localement pour voir les erreurs. |
| `Error: Tests failed` | Les tests ont échoué. | Exécutez `npm test` localement pour déboguer. |

---

## 📚 Pour Aller Plus Loin

### Ressources Officielles
- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Marketplace GitHub Actions](https://github.com/marketplace?type=actions)
- [Docker Hub](https://hub.docker.com/)

### Tutoriels
- [GitHub Actions Get Started](https://docs.github.com/en/actions/quickstart)
- [Dockerizing a Node.js Web App](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)

### Bonnes Pratiques
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/using-workflows/workflow-best-practices)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Prochains Exercices
- **[Exercice 1 : Déploiement avec Docker](../exercise-1/README.md)** : Si vous ne l'avez pas encore fait.
- **[Exercice 3 : Configuration avec Ansible](../exercise-3/README.md)** : Automatisez la configuration de serveurs.

---

## 🎉 Félicitations !

Vous avez **terminé l'Exercice 2** ! 🎉
Vous savez maintenant :
✅ Créer un **workflow CI** pour exécuter des tests automatiquement.
✅ Configurer un **workflow CD** pour déployer une image Docker.
✅ Utiliser des **secrets GitHub** pour sécuriser vos workflows.
✅ Combiner **CI et CD** dans un seul workflow.

**Passez à l'[Exercice 3](../exercise-3/README.md) pour apprendre à configurer des serveurs avec Ansible !** 🚀
