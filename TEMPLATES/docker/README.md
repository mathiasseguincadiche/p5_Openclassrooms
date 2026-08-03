# 📁 Templates Docker

**Bienvenue dans la section des templates Docker !**
Ici, vous trouverez des **fichiers de configuration prêts à l'emploi** pour Docker et Docker Compose, **commentés et expliqués** pour vous aider à démarrer rapidement.

---

## 📌 Table des Matières

1. [Dockerfile pour Node.js](#-dockerfile-pour-nodejs)
2. [Dockerfile pour Python](#-dockerfile-pour-python)
3. [Docker Compose pour une Application Multi-Conteneurs](#-docker-compose-pour-une-application-multi-conteneurs)
4. [.dockerignore](#-dockerignore)
5. [Bonnes Pratiques](#-bonnes-pratiques)

---

## 📄 Dockerfile pour Node.js

**Fichier** : [`Dockerfile.nodejs`](Dockerfile.nodejs)

**Description** : Template pour conteneuriser une **application Node.js** avec une image légère (Alpine Linux) et des bonnes pratiques (multi-stage build, utilisateur non-root).

**Cas d'Usage** :
- Développement et production d'applications Node.js.
- Déploiement sur Kubernetes, AWS ECS, etc.

**Exemple d'utilisation** :
```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/docker/Dockerfile.nodejs ./Dockerfile

# 2. Personnalisez le Dockerfile (ex: changez l'image de base, ajoutez des dépendances)

# 3. Construisez l'image
docker build -t mon-app-nodejs .

# 4. Lancez le conteneur
docker run -d -p 3000:3000 mon-app-nodejs
```

---

## 📄 Dockerfile pour Python

**Fichier** : [`Dockerfile.python`](Dockerfile.python)

**Description** : Template pour conteneuriser une **application Python** (Flask, Django, FastAPI, etc.) avec une image légère et des bonnes pratiques.

**Cas d'Usage** :
- Développement et production d'applications Python.
- Déploiement d'APIs ou de scripts Python.

**Exemple d'utilisation** :
```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/docker/Dockerfile.python ./Dockerfile

# 2. Personnalisez le Dockerfile (ex: installez des dépendances spécifiques)

# 3. Construisez l'image
docker build -t mon-app-python .

# 4. Lancez le conteneur
docker run -d -p 5000:5000 mon-app-python
```

---

## 📄 Docker Compose pour une Application Multi-Conteneurs

**Fichier** : [`docker-compose.yml`](docker-compose.yml)

**Description** : Template pour déployer une **application multi-conteneurs** (ex: backend + base de données + Redis) avec Docker Compose.

**Cas d'Usage** :
- Développement local d'applications complexes.
- Tests d'intégration.
- Déploiement de stacks complètes (ex: LAMP, MEAN, etc.).

**Exemple d'utilisation** :
```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/docker/docker-compose.yml ./docker-compose.yml

# 2. Personnalisez le fichier (ex: changez les images, ajoutez des services)

# 3. Démarrez les conteneurs
docker-compose up -d

# 4. Arrêtez les conteneurs
docker-compose down
```

---

## 📄 .dockerignore

**Fichier** : [`.dockerignore`](.dockerignore)

**Description** : Fichier pour **exclure des fichiers et dossiers** lors de la construction d'une image Docker. Cela permet de :
- Réduire la taille de l'image.
- Accélérer le build.
- Éviter de copier des fichiers sensibles (ex: `.env`).

**Cas d'Usage** :
- Tous les projets Docker.

**Exemple d'utilisation** :
```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/docker/.dockerignore ./.dockerignore

# 2. Personnalisez le fichier (ex: ajoutez des fichiers à ignorer)

# 3. Construisez l'image (les fichiers ignorés ne seront pas copiés)
docker build -t mon-app .
```

---

## 🌟 Bonnes Pratiques

### 1. Utilisez des Images Légères
- Préférez les images **Alpine Linux** (`node:18-alpine`, `python:3.10-alpine`) pour réduire la taille.
- Évitez les images comme `ubuntu:latest` (trop lourdes).

### 2. Multi-Stage Builds
- Utilisez des **multi-stage builds** pour réduire la taille de l'image finale.
- Exemple : Construisez l'application dans une première étape, puis copiez uniquement les fichiers nécessaires dans l'image finale.

### 3. Utilisez un Utilisateur Non-Root
- **Ne jamais exécuter** un conteneur en tant que `root` (sauf si nécessaire).
- Créez un utilisateur dédié dans le `Dockerfile`.

### 4. Minimisez les Couches
- Regroupez les commandes `RUN` pour réduire le nombre de couches.
- Exemple : `RUN apt-get update && apt-get install -y package1 package2` au lieu de deux commandes `RUN` séparées.

### 5. Utilisez `.dockerignore`
- Excluez les fichiers inutiles (`node_modules/`, `.git/`, `*.log`, etc.).

### 6. Tags Immuables
- Utilisez des **tags immuables** (ex: `v1.0.0`) pour les images en production.
- Évitez `latest` en production (il peut changer sans préavis).

### 7. Variables d'Environnement
- **Ne jamais hardcoder** des secrets dans le `Dockerfile`.
- Utilisez des **variables d'environnement** ou des **secrets Docker**.

---

## 📚 Ressources

- [Documentation Docker](https://docs.docker.com)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Bonne utilisation des templates Docker !** 🚀
