# 🐳 Exercice 1 : Déploiement d'une Application avec Docker

**Bienvenue dans le premier exercice du projet P5 !**
Ici, vous allez apprendre à **conteneuriser une application** avec Docker, à la **construire**, à la **lancer**, et à la **déployer localement**. Cet exercice est conçu pour les **débutants** et couvre toutes les bases de Docker.

---

## 📌 Table des Matières

1. [🎯 Objectifs](#-objectifs)
2. [🛠️ Prérequis](#prerequis)
3. [📥 Préparation de l'Environnement](#-préparation-de-lenvironnement)
4. [📝 Étape 1 : Créer un Dockerfile](#-étape-1--créer-un-dockerfile)
5. [📝 Étape 2 : Construire l'Image Docker](#-étape-2--construire-limage-docker)
6. [📝 Étape 3 : Lancer le Conteneur](#-étape-3--lancer-le-conteneur)
7. [📝 Étape 4 : Utiliser Docker Compose (Bonus)](#-étape-4--utiliser-docker-compose-bonus)
8. [📝 Étape 5 : Gérer les Volumes (Bonus)](#-étape-5--gérer-les-volumes-bonus)
9. [✅ Vérification](#-vérification)
10. [🔍 Résolution des Problèmes](#-résolution-des-problèmes)
11. [📚 Pour Aller Plus Loin](#-pour-aller-plus-loin)

---

## 🎯 Objectifs

À la fin de cet exercice, vous serez capable de :
✅ **Comprendre** les concepts de base de Docker (image, conteneur, Dockerfile).
✅ **Créer** un `Dockerfile` pour conteneuriser une application.
✅ **Construire** une image Docker à partir d'un `Dockerfile`.
✅ **Lancer** un conteneur à partir d'une image.
✅ **Exposer** un port pour accéder à l'application.
✅ **Utiliser** Docker Compose pour gérer des applications multi-conteneurs.
✅ **Gérer** des volumes pour persister des données.

---

<a id="prerequis"></a>

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir :

| Outil | Version | Vérification | Lien d'Installation |
|-------|---------|--------------|---------------------|
| **Git** | 2.x | `git --version` | [git-scm.com](https://git-scm.com/) |
| **Docker** | 24.x | `docker --version` | [docker.com](https://www.docker.com/) |
| **Docker Compose** | 2.x | `docker-compose --version` | Inclus avec Docker |
| **Éditeur de texte** | - | - | VS Code, Sublime Text, etc. |

> **⚠️ Important** : Si vous utilisez **Windows**, assurez-vous que Docker Desktop est en cours d'exécution.

---

## 📥 Préparation de l'Environnement

### 1. Cloner le Dépôt

Ouvrez un terminal et exécutez :

```bash
# Cloner le dépôt du projet
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 2. Créer un Projet d'Exemple

Pour cet exercice, nous allons utiliser une **application Node.js simple** qui affiche "Hello, Docker !".

```bash
# Créer un dossier pour l'exercice
mkdir -p ~/p5-exercise-1 && cd ~/p5-exercise-1

# Initialiser un projet Node.js
npm init -y

# Installer Express (framework Node.js)
npm install express

# Créer un fichier index.js
cat > index.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello, Docker ! 🐳');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
EOF
```

> **💡 Explication** :
>
> - `npm init -y` : Initialise un projet Node.js avec des valeurs par défaut.
> - `npm install express` : Installe le framework Express pour créer un serveur web.
> - `index.js` : Fichier principal de l'application qui écoute sur le port 3000.

### 3. Tester l'Application Localement

```bash
# Démarrer l'application
node index.js
```

Ouvrez votre navigateur et accédez à `http://localhost:3000`. Vous devriez voir :

```
Hello, Docker ! 🐳
```

> **✅ Résultat attendu** : L'application s'affiche correctement dans le navigateur.

Arrêtez l'application avec `Ctrl + C` dans le terminal.

---

## 📝 Étape 1 : Créer un Dockerfile

Un **Dockerfile** est un fichier texte qui contient les instructions pour **construire une image Docker**. Chaque instruction crée une nouvelle couche dans l'image.

### 1. Créer le Fichier `Dockerfile`

Dans le dossier `~/p5-exercise-1`, créez un fichier nommé `Dockerfile` (sans extension) :

```bash
# Créer le Dockerfile
nano Dockerfile
```

> **⚠️ Attention** : Le nom du fichier doit être **exactement `Dockerfile`** (majuscule D, sans extension).

### 2. Ajouter le Contenu

Copiez le contenu suivant dans le `Dockerfile` :

```dockerfile
# =============================================
# Dockerfile pour une application Node.js
# =============================================

# --- Étape 1 : Image de base ---
# Utilise une image officielle Node.js (version 18) basée sur Alpine Linux.
# Alpine est légère et sécurisée, idéale pour la production.
FROM node:24-alpine

# --- Étape 2 : Métadonnées (optionnel) ---
# Ajoute des métadonnées pour documenter l'image (auteur, description, etc.).
LABEL maintainer="votre.email@example.com"
LABEL description="Application Node.js conteneurisée avec Docker"

# --- Étape 3 : Répertoire de travail ---
# Définit le répertoire de travail dans le conteneur.
# Tous les fichiers copiés plus tard seront placés ici.
WORKDIR /app

# --- Étape 4 : Copie des fichiers de dépendances ---
# Copie uniquement les fichiers package.json et package-lock.json.
# Cela permet de profiter du cache Docker pour les dépendances.
COPY package*.json ./

# --- Étape 5 : Installation des dépendances ---
# Exécute `npm install` pour installer les dépendances listées dans package.json.
# Utilise `--production` pour éviter d'installer les dépendances de développement.
RUN npm install --production

# --- Étape 6 : Copie du reste de l'application ---
# Copie tous les fichiers du projet (sauf ceux ignorés par .dockerignore).
COPY . .

# --- Étape 7 : Exposition du port ---
# Indique que le conteneur écoutera sur le port 3000.
# Cela ne publie pas automatiquement le port (voir `docker run -p`).
EXPOSE 3000

# --- Étape 8 : Commande de démarrage ---
# Définit la commande à exécuter lorsque le conteneur démarre.
# Ici, on lance l'application avec `node index.js`.
CMD ["node", "index.js"]

# =============================================
# Explications supplémentaires :
# - FROM : Image de base à utiliser.
# - LABEL : Métadonnées pour documenter l'image.
# - WORKDIR : Répertoire de travail dans le conteneur.
# - COPY : Copie des fichiers locaux dans le conteneur.
# - RUN : Exécute une commande pendant la construction.
# - EXPOSE : Indique le port à exposer (pour la documentation).
# - CMD : Commande à exécuter au démarrage du conteneur.
# =============================================
```

> **💡 Explication des Instructions** :
>
> | Instruction | Description | Exemple |
> |-------------|-------------|---------|
> | `FROM` | Définit l'image de base. | `FROM node:24-alpine` |
> | `LABEL` | Ajoute des métadonnées à l'image. | `LABEL maintainer="email@example.com"` |
> | `WORKDIR` | Définit le répertoire de travail. | `WORKDIR /app` |
> | `COPY` | Copie des fichiers locaux dans le conteneur. | `COPY . .` |
> | `RUN` | Exécute une commande pendant la construction. | `RUN npm install` |
> | `EXPOSE` | Indique le port à exposer. | `EXPOSE 3000` |
> | `CMD` | Définit la commande par défaut au démarrage. | `CMD ["node", "index.js"]` |

### 3. Créer un `.dockerignore`

Pour **optimiser le build** et **éviter de copier des fichiers inutiles**, créez un fichier `.dockerignore` :

```bash
nano .dockerignore
```

Ajoutez le contenu suivant :

```dockerignore
# Ignorer les dépendances locales (seront réinstallées dans le conteneur)
node_modules/

# Ignorer les fichiers de log
*.log

# Ignorer les fichiers temporaires
*.tmp
*.temp

# Ignorer les fichiers de configuration locaux
.env
.env.local

# Ignorer les fichiers de documentation
*.md

# Ignorer les fichiers IDE
.idea/
.vscode/
.DS_Store

# Ignorer le dossier .git
.git/
.gitignore
```

> **💡 Pourquoi un `.dockerignore` ?**
>
> - **Réduit la taille de l'image** : Évite de copier des fichiers inutiles.
> - **Accélère le build** : Moins de fichiers à copier = build plus rapide.
> - **Sécurité** : Évite de copier des fichiers sensibles (ex: `.env`).

---

## 📝 Étape 2 : Construire l'Image Docker

Maintenant que le `Dockerfile` est prêt, nous allons **construire l'image Docker**.

### 1. Vérifier le Contexte de Build

Assurez-vous d'être dans le bon dossier :

```bash
cd ~/p5-exercise-1
ls -la
```

> **✅ Résultat attendu** : Vous devriez voir les fichiers suivants :
>
> ```
> Dockerfile
> .dockerignore
> index.js
> package.json
> package-lock.json
> node_modules/
> ```

### 2. Construire l'Image

Exécutez la commande suivante pour construire l'image :

```bash
# Construire l'image avec le nom "p5-exercise-1" et le tag "v1"
docker build -t p5-exercise-1:v1 .
```

> **💡 Explication de la commande** :
>
> - `docker build` : Commande pour construire une image.
> - `-t p5-exercise-1:v1` : Donne un **nom** (`p5-exercise-1`) et un **tag** (`v1`) à l'image.
> - `.` : Indique que le `Dockerfile` est dans le **répertoire courant**.

> **✅ Résultat attendu** :
>
> ```
> [+] Building 5.2s (10/10) FINISHED
>  => [internal] load build definition from Dockerfile                       0.1s
>  => => transferring dockerfile: 32B                                         0.0s
>  => [internal] load .dockerignore                                          0.1s
>  => => transferring context: 2B                                           0.0s
>  => [1/5] FROM docker.io/library/node:24-alpine@sha256:...               4.2s
>  => => resolve docker.io/library/node:24-alpine@sha256:...              0.1s
>  => => sha256:... 1.2kB / 1.2kB                                             0.0s
>  => => sha256:... 1.2kB / 1.2kB                                             0.0s
>  => => sha256:... 1.2kB / 1.2kB                                             0.0s
>  => => extracting sha256:...                                                0.8s
>  => [2/5] WORKDIR /app                                                     0.1s
>  => [3/5] COPY package*.json ./                                          0.1s
>  => [4/5] RUN npm install --production                                   2.5s
>  => [5/5] COPY . .                                                        0.1s
>  => exporting to image                                                     0.2s
>  => => exporting layers                                                    0.1s
>  => => writing image sha256:...                                           0.1s
>  => => naming to docker.io/library/p5-exercise-1:v1                       0.0s
> ```

### 3. Vérifier que l'Image a été Créée

```bash
# Lister toutes les images Docker locales
docker images
```

> **✅ Résultat attendu** : Vous devriez voir votre image dans la liste :
>
> ```
> REPOSITORY          TAG       IMAGE ID       CREATED         SIZE
> p5-exercise-1       v1        abc123def456   1 minute ago   120MB
> node                18-alpine  xyz789uvw012   2 weeks ago    100MB
> ```

---

## 📝 Étape 3 : Lancer le Conteneur

Maintenant que l'image est construite, nous allons **lancer un conteneur** à partir de cette image.

### 1. Lancer le Conteneur

Exécutez la commande suivante :

```bash
# Lancer un conteneur à partir de l'image "p5-exercise-1:v1"
docker run -d -p 3000:3000 --name p5-container p5-exercise-1:v1
```

> **💡 Explication de la commande** :
>
> - `docker run` : Commande pour lancer un conteneur.
> - `-d` : Lance le conteneur en **arrière-plan** (mode "detached").
> - `-p 3000:3000` : **Mappe le port 3000 du conteneur au port 3000 de l'hôte**.
>   - Le premier `3000` est le port de l'hôte (votre machine).
>   - Le second `3000` est le port du conteneur.
> - `--name p5-container` : Donne un **nom** au conteneur (`p5-container`).
> - `p5-exercise-1:v1` : Nom et tag de l'image à utiliser.

> **✅ Résultat attendu** :
>
> ```
> abc123def4567890
> ```
>
> (L'ID du conteneur est affiché.)

### 2. Vérifier que le Conteneur est en Cours d'Exécution

```bash
# Lister les conteneurs en cours d'exécution
docker ps
```

> **✅ Résultat attendu** : Vous devriez voir votre conteneur dans la liste :
>
> ```
> CONTAINER ID   IMAGE               COMMAND                  CREATED         STATUS         PORTS                    NAMES
> abc123def456   p5-exercise-1:v1   "node index.js"          5 seconds ago   Up 3 seconds   0.0.0.0:3000->3000/tcp   p5-container
> ```

### 3. Accéder à l'Application

Ouvrez votre navigateur et accédez à `http://localhost:3000`.

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> Hello, Docker ! 🐳
> ```

### 4. Voir les Logs du Conteneur

```bash
# Afficher les logs du conteneur
docker logs p5-container
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> Server running at http://localhost:3000
> ```

### 5. Arrêter le Conteneur

```bash
# Arrêter le conteneur
docker stop p5-container
```

> **✅ Résultat attendu** : Le conteneur s'arrête.

### 6. Redémarrer le Conteneur

```bash
# Redémarrer le conteneur
docker start p5-container
```

> **✅ Résultat attendu** : Le conteneur redémarre et l'application est de nouveau accessible.

### 7. Supprimer le Conteneur

```bash
# Supprimer le conteneur (doit être arrêté)
docker rm p5-container
```

---

## 📝 Étape 4 : Utiliser Docker Compose (Bonus)

**Docker Compose** permet de gérer des **applications multi-conteneurs** de manière simplifiée. Dans cette étape, nous allons ajouter une **base de données Redis** à notre application.

### 1. Modifier l'Application pour Utiliser Redis

Modifiez le fichier `index.js` pour utiliser Redis :

```bash
nano index.js
```

Remplacez le contenu par :

```javascript
const express = require('express');
const redis = require('redis');
const app = express();
const port = 3000;

// Créer un client Redis
const redisClient = redis.createClient({
  host: 'redis', // Nom du service dans Docker Compose
  port: 6379
});

// Gérer les erreurs de connexion Redis
redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

// Middleware pour compter les visites
app.use(async (req, res, next) => {
  try {
    await redisClient.connect();
    await redisClient.incr('visits');
    const visits = await redisClient.get('visits');
    res.locals.visits = visits;
  } catch (err) {
    console.error('Redis middleware error:', err);
    res.locals.visits = 'Redis non disponible';
  }
  next();
});

app.get('/', (req, res) => {
  res.send(`Hello, Docker ! 🐳 (Visites: ${res.locals.visits})`);
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
```

### 2. Installer le Client Redis

```bash
npm install redis
```

### 3. Créer le Fichier `docker-compose.yml`

```bash
nano docker-compose.yml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# docker-compose.yml pour une application Node.js + Redis
# =============================================

# Version du schéma Docker Compose
version: "3.8"

# Définition des services
services:
  # Service 1 : Application Node.js
  app:
    # Construire l'image à partir du Dockerfile dans le répertoire courant
    build: .
    # Nom du conteneur
    container_name: p5-app
    # Mapper le port 3000 du conteneur au port 3000 de l'hôte
    ports:
      - "3000:3000"
    # Dépendre du service Redis (attendre que Redis soit prêt)
    depends_on:
      - redis
    # Variables d'environnement (optionnel)
    environment:
      - NODE_ENV=production
    # Redémarrer automatiquement en cas d'erreur
    restart: unless-stopped

  # Service 2 : Base de données Redis
  redis:
    # Utiliser une image Redis officielle
    image: redis:8-alpine
    # Nom du conteneur
    container_name: p5-redis
    # Mapper le port 6379 du conteneur au port 6379 de l'hôte (optionnel)
    ports:
      - "6379:6379"
    # Persister les données Redis dans un volume
    volumes:
      - redis_data:/data
    # Redémarrer automatiquement en cas d'erreur
    restart: unless-stopped

# Définition des volumes
volumes:
  # Volume pour persister les données Redis
  redis_data:

# =============================================
# Explications supplémentaires :
# - version : Version du schéma Docker Compose.
# - services : Liste des services à lancer.
#   - build : Construire une image à partir d'un Dockerfile.
#   - image : Utiliser une image existante.
#   - ports : Mapper les ports (hôte:conteneur).
#   - depends_on : Attendre que d'autres services soient prêts.
#   - environment : Variables d'environnement.
#   - volumes : Persister des données dans des volumes.
# - volumes : Définition des volumes nommés.
# =============================================
```

> **💡 Explication du `docker-compose.yml`** :
>
> - **`version`** : Version du schéma Docker Compose (ici, 3.8).
> - **`services`** : Liste des services à lancer (ici, `app` et `redis`).
> - **`build`** : Construire une image à partir du `Dockerfile` dans le répertoire courant.
> - **`image`** : Utiliser une image existante (ici, `redis:8-alpine`).
> - **`ports`** : Mapper les ports (format : `hôte:conteneur`).
> - **`depends_on`** : Attendre que d'autres services soient prêts avant de démarrer.
> - **`volumes`** : Persister des données dans des volumes nommés.

### 4. Lancer les Services avec Docker Compose

```bash
# Démarrer les services en arrière-plan
docker-compose up -d
```

> **💡 Explication de la commande** :
>
> - `docker-compose up` : Démarre les services définis dans `docker-compose.yml`.
> - `-d` : Lance les conteneurs en **arrière-plan** (mode "detached").

> **✅ Résultat attendu** :
>
> ```
> [+] Running 2/2
>  ✔ Container p5-redis  Created                                              0.1s
>  ✔ Container p5-app    Created                                              0.1s
> ```

### 5. Vérifier que les Services sont en Cours d'Exécution

```bash
# Lister les conteneurs
docker-compose ps
```

> **✅ Résultat attendu** :
>
> ```
> NAME        COMMAND                  SERVICE   CREATED         STATUS         PORTS
> p5-app     "node index.js"          app       5 seconds ago   Up 3 seconds   0.0.0.0:3000->3000/tcp
> p5-redis   "docker-entrypoint.sh"   redis     5 seconds ago   Up 3 seconds   0.0.0.0:6379->6379/tcp
> ```

### 6. Accéder à l'Application

Ouvrez votre navigateur et accédez à `http://localhost:3000`.

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> Hello, Docker ! 🐳 (Visites: 1)
> ```
>
> (Le nombre de visites augmente à chaque rafraîchissement.)

### 7. Voir les Logs

```bash
# Afficher les logs de l'application
docker-compose logs app

# Afficher les logs de Redis
docker-compose logs redis
```

### 8. Arrêter les Services

```bash
# Arrêter tous les services
docker-compose down
```

> **⚠️ Attention** : Cette commande **supprime les conteneurs**, mais **conserve les volumes** (données Redis).

### 9. Supprimer les Volumes (Optionnel)

Si vous voulez **supprimer les données Redis** :

```bash
# Arrêter et supprimer les conteneurs + volumes
docker-compose down -v
```

---

## 📝 Étape 5 : Gérer les Volumes (Bonus)

Les **volumes Docker** permettent de **persister des données** même après la suppression d'un conteneur. Dans cette étape, nous allons explorer comment les utiliser.

### 1. Lister les Volumes

```bash
# Lister tous les volumes Docker
docker volume ls
```

> **✅ Résultat attendu** : Vous devriez voir le volume `p5-exercise-1_redis_data` (créé par Docker Compose) :
>
> ```
> DRIVER    VOLUME NAME
> local     p5-exercise-1_redis_data
> ```

### 2. Inspecter un Volume

```bash
# Inspecter le volume Redis
docker volume inspect p5-exercise-1_redis_data
```

> **✅ Résultat attendu** : Vous verrez des informations comme le **point de montage** du volume.

### 3. Créer un Volume Manuellement

```bash
# Créer un volume nommé "mon_volume"
docker volume create mon_volume
```

### 4. Utiliser un Volume dans un Conteneur

```bash
# Lancer un conteneur avec un volume monté
docker run -d -p 3000:3000 --name p5-app-volume -v mon_volume:/app/data p5-exercise-1:v1
```

> **💡 Explication** :
>
> - `-v mon_volume:/app/data` : Monte le volume `mon_volume` dans `/app/data` dans le conteneur.

### 5. Supprimer un Volume

```bash
# Supprimer un volume (doit être déconnecté de tous les conteneurs)
docker volume rm mon_volume
```

---

## ✅ Vérification

Pour vérifier que vous avez **bien compris** cet exercice, répondez aux questions suivantes :

### 1. Qu'est-ce qu'un `Dockerfile` ?

<details>
<summary>💡 Réponse</summary>
Un `Dockerfile` est un fichier texte qui contient les instructions pour construire une image Docker. Chaque instruction crée une nouvelle couche dans l'image.
</details>

### 2. Quelle est la différence entre une **image** et un **conteneur** ?

<details>
<summary>💡 Réponse</summary>
- **Image** : Modèle immuable utilisé pour créer un conteneur (ex: `node:24-alpine`).
- **Conteneur** : Instance d'une image en cours d'exécution (ex: un conteneur lancé avec `docker run`).
</details>

### 3. À quoi sert la commande `docker build` ?

<details>
<summary>💡 Réponse</summary>
La commande `docker build` permet de **construire une image Docker** à partir d'un `Dockerfile`.
</details>

### 4. À quoi sert la commande `docker run` ?

<details>
<summary>💡 Réponse</summary>
La commande `docker run` permet de **lancer un conteneur** à partir d'une image Docker.
</details>

### 5. À quoi sert le flag `-p` dans `docker run` ?

<details>
<summary>💡 Réponse</summary>
Le flag `-p` (ou `--publish`) permet de **mapper un port du conteneur à un port de l'hôte** (ex: `-p 3000:3000` mappe le port 3000 du conteneur au port 3000 de l'hôte).
</details>

### 6. À quoi sert Docker Compose ?

<details>
<summary>💡 Réponse</summary>
Docker Compose permet de **gérer des applications multi-conteneurs** de manière simplifiée, en définissant tous les services dans un fichier `docker-compose.yml`.
</details>

### 7. À quoi sert un volume Docker ?

<details>
<summary>💡 Réponse</summary>
Un volume Docker permet de **persister des données** même après la suppression d'un conteneur. Il est utile pour les bases de données, les fichiers de configuration, etc.
</details>

---

## 🔍 Résolution des Problèmes

Voici les **problèmes courants** et leurs solutions :

| **Problème** | **Cause Possible** | **Solution** |
|--------------|-------------------|--------------|
| `Cannot connect to the Docker daemon` | Docker Desktop n'est pas lancé. | Démarrez Docker Desktop. |
| `No such file or directory` (Dockerfile) | Le `Dockerfile` n'existe pas ou le chemin est incorrect. | Vérifiez que vous êtes dans le bon dossier (`cd ~/p5-exercise-1`). |
| `Port already in use` | Le port 3000 est déjà utilisé par une autre application. | Changez le port avec `-p 3001:3000` ou arrêtez l'autre application. |
| `Error: No such image: p5-exercise-1:v1` | L'image n'a pas été construite ou le tag est incorrect. | Vérifiez avec `docker images` et reconstruisez l'image si nécessaire. |
| `Error: Redis connection refused` | Redis n'est pas démarré ou le nom du service est incorrect. | Vérifiez que Redis est en cours d'exécution (`docker-compose ps`). |
| `Module not found: redis` | Le package `redis` n'est pas installé. | Exécutez `npm install redis`. |
| `Permission denied` (Docker) | L'utilisateur n'a pas les permissions pour Docker. | Ajoutez votre utilisateur au groupe `docker` ou utilisez `sudo`. |

---

## 📚 Pour Aller Plus Loin

### Ressources Officielles

- [Documentation Docker](https://docs.docker.com)
- [Docker pour Débutants](https://docker-curriculum.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

### Tutoriels

- [Docker Get Started](https://docs.docker.com/get-started/)
- [Docker Compose Tutorial](https://docs.docker.com/compose/gettingstarted/)

### Livres

- *Docker Deep Dive* (Nigel Poulton)
- *The Docker Book* (James Turnbull)

### Prochains Exercices

- **[Exercice 2 : CI/CD avec GitHub Actions](../exercise-2/README.md)** : Automatisez les tests et le déploiement de votre application.
- **[Exercice 3 : Configuration avec Ansible](../exercise-3/README.md)** : Automatisez la configuration de serveurs.

---

## 🎉 Félicitations

Vous avez **terminé l'Exercice 1** ! 🎉
Vous savez maintenant :
✅ Créer un `Dockerfile` pour conteneuriser une application.
✅ Construire une image Docker.
✅ Lancer un conteneur et exposer un port.
✅ Utiliser Docker Compose pour gérer des applications multi-conteneurs.
✅ Gérer des volumes pour persister des données.

**Passez à l'[Exercice 2](../exercise-2/README.md) pour apprendre à automatiser vos déploiements avec GitHub Actions !** 🚀
