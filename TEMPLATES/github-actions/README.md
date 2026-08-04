# 📁 Templates GitHub Actions

**Bienvenue dans la section des templates GitHub Actions !**
Ici, vous trouverez des **fichiers de workflow prêts à l'emploi** pour GitHub Actions, **commentés et expliqués** pour automatiser vos processus CI/CD.

---

## 📌 Table des Matières

1. [Workflow CI pour Node.js](#-workflow-ci-pour-nodejs)
2. [Workflow CD pour AWS](#-workflow-cd-pour-aws)
3. [Bonnes Pratiques](#-bonnes-pratiques)

---

## 📄 Workflow CI pour Node.js

**Fichier** : [`ci-nodejs.yml`](ci-nodejs.yml)

**Description** : Workflow pour **exécuter des tests automatiquement** à chaque push ou pull request sur la branche `main`. Il inclut :

- Checkout du code.
- Configuration de Node.js.
- Installation des dépendances.
- Exécution des tests.
- Linting avec ESLint.

**Cas d'Usage** :

- Vérifier que le code fonctionne avant de merger.
- Automatiser les tests unitaires et d'intégration.
- Vérifier la qualité du code avec un linter.

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre dépôt
mkdir -p .github/workflows
cp TEMPLATES/github-actions/ci-nodejs.yml .github/workflows/ci-nodejs.yml

# 2. Personnalisez le workflow (ex: changez la version de Node.js, ajoutez des étapes)

# 3. Commitez et poussez vers GitHub
 git add .github/workflows/ci-nodejs.yml
 git commit -m "feat: add CI workflow for Node.js"
 git push origin main
```

---

## 📄 Workflow CD pour AWS

**Fichier** : [`cd-aws.yml`](cd-aws.yml)

**Description** : Workflow pour **déployer une application sur AWS** après un push réussi sur la branche `main`. Il inclut :

- Checkout du code.
- Configuration de Docker Buildx.
- Connexion à Docker Hub.
- Construction et poussée d'une image Docker.
- Déploiement sur AWS ECS (optionnel).

**Cas d'Usage** :

- Déployer automatiquement une application après un push.
- Pousser une image Docker vers Docker Hub ou ECR.
- Déployer sur AWS ECS, EKS, ou EC2.

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre dépôt
cp TEMPLATES/github-actions/cd-aws.yml .github/workflows/cd-aws.yml

# 2. Configurez DOCKER_USERNAME, DOCKER_PASSWORD et AWS_ROLE_ARN dans les secrets GitHub

# 3. Personnalisez le workflow (ex: changez le nom de l'image, ajoutez des étapes de déploiement)

# 4. Commitez et poussez vers GitHub
 git add .github/workflows/cd-aws.yml
 git commit -m "feat: add CD workflow for AWS"
 git push origin main
```

---

## 🌟 Bonnes Pratiques

### 1. Nommez vos Workflows de Manière Claire

- Utilisez des noms **descriptifs** (ex: `CI - Node.js`, `CD - AWS`).
- Évitez les noms génériques comme `main.yml`.

### 2. Utilisez des Déclencheurs Appropriés

- **`push`** : Pour exécuter le workflow à chaque commit.
- **`pull_request`** : Pour exécuter le workflow à chaque pull request.
- **`schedule`** : Pour exécuter le workflow à une heure planifiée (ex: tous les jours à minuit).

Exemple :

```yaml
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: "0 0 * * *"  # Tous les jours à minuit
```

### 3. Cachez les Dépendances

- Utilisez le **cache** pour accélérer les builds (ex: `npm`, `pip`, `maven`).

Exemple :

```yaml
- uses: actions/setup-node@v7
  with:
    node-version: 24
    cache: 'npm'  # Cache les dépendances npm
```

### 4. Parallélisez les Jobs

- Utilisez des **jobs parallèles** pour accélérer le workflow.

Exemple :

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npx eslint .
```

### 5. Utilisez des Secrets pour les Informations Sensibles

- **Ne jamais stocker** de secrets dans le code ou les fichiers de workflow.
- Utilisez les **secrets GitHub** pour les mots de passe, clés API, etc.

Exemple :

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### 6. Ajoutez des Notifications

- Configurez des **notifications** pour les échecs de workflow (Slack, email, etc.).

Exemple :

```yaml
- name: Notify Slack on Failure
  if: failure()
  uses: rtCamp/action-slack-notify@v2
  env:
    SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
    SLACK_COLOR: danger
    SLACK_TITLE: "Workflow Failed"
```

### 7. Utilisez des Matrices pour Tester Plusieurs Versions

- Utilisez des **matrices** pour tester votre code avec plusieurs versions d'un langage ou d'une bibliothèque.

Exemple :

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [22.x, 24.x]
    steps:
      - uses: actions/setup-node@v7
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

### 8. Documentez vos Workflows

- Ajoutez des **commentaires** dans vos fichiers de workflow pour expliquer chaque étape.
- Utilisez des **descriptions** pour les jobs et les étapes.

Exemple :

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code  # Étape 1 : Récupérer le code
        uses: actions/checkout@v7

      - name: Setup Node.js  # Étape 2 : Configurer Node.js
        uses: actions/setup-node@v7
        with:
          node-version: 24
```

---

## 📚 Ressources

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Marketplace GitHub Actions](https://github.com/marketplace?type=actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

**Bonne utilisation des templates GitHub Actions !** 🚀
