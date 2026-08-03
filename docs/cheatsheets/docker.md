# 📋 Cheatsheet Docker

**Bienvenue dans le cheatsheet Docker !**
Cette page regroupe les **commandes Docker les plus utiles** pour les débutants et les utilisateurs avancés.

---

## 📌 Table des Matières

1. [Installation](#-installation)
2. [Commandes de Base](#-commandes-de-base)
3. [Gestion des Images](#-gestion-des-images)
4. [Gestion des Conteneurs](#-gestion-des-conteneurs)
5. [Dockerfile](#-dockerfile)
6. [Docker Compose](#-docker-compose)
7. [Réseau](#-réseau)
8. [Volumes](#-volumes)
9. [Sécurité](#-sécurité)
10. [Dépannage](#-dépannage)

---

## 📥 Installation

### Linux (Ubuntu/Debian)
```bash
# Installer Docker
sudo apt update
sudo apt install -y docker.io docker-compose

# Démarrer et activer Docker
sudo systemctl enable --now docker

# Ajouter l'utilisateur au groupe docker (pour éviter sudo)
sudo usermod -aG docker $USER
newgrp docker  # Recharger les groupes

# Vérifier l'installation
docker --version
docker-compose --version
```

### macOS
```bash
# Installer Docker Desktop
brew install --cask docker

# Démarrer Docker Desktop (via l'application)
open -a Docker

# Vérifier l'installation
docker --version
```

### Windows
1. Téléchargez [Docker Desktop](https://www.docker.com/products/docker-desktop/).
2. Installez et démarrez Docker Desktop.
3. Vérifiez l'installation :
```powershell
docker --version
```

---

## 🚀 Commandes de Base

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker --version` | Vérifier la version de Docker | `docker --version` |
| `docker info` | Afficher les informations sur Docker | `docker info` |
| `docker help` | Afficher l'aide | `docker help` |
| `docker help <commande>` | Afficher l'aide pour une commande | `docker help run` |

---

## 🖼️ Gestion des Images

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker images` | Lister les images locales | `docker images` |
| `docker images -a` | Lister toutes les images (y compris intermédiaires) | `docker images -a` |
| `docker pull <image>` | Télécharger une image | `docker pull nginx:latest` |
| `docker push <image>` | Pousser une image vers un registre | `docker push mon-app:v1` |
| `docker rmi <image>` | Supprimer une image | `docker rmi nginx:latest` |
| `docker rmi $(docker images -q)` | Supprimer toutes les images | `docker rmi $(docker images -q)` |
| `docker build -t <tag> .` | Construire une image à partir d'un Dockerfile | `docker build -t mon-app:v1 .` |
| `docker build -t <tag> -f <Dockerfile> .` | Construire avec un Dockerfile spécifique | `docker build -t mon-app:v1 -f Dockerfile.prod .` |
| `docker build --no-cache -t <tag> .` | Construire sans cache | `docker build --no-cache -t mon-app:v1 .` |
| `docker history <image>` | Afficher l'historique d'une image | `docker history nginx:latest` |
| `docker inspect <image>` | Afficher les détails d'une image | `docker inspect nginx:latest` |
| `docker save -o <file.tar> <image>` | Sauvegarder une image dans un fichier | `docker save -o nginx.tar nginx:latest` |
| `docker load -i <file.tar>` | Charger une image depuis un fichier | `docker load -i nginx.tar` |

---

## 🐳 Gestion des Conteneurs

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker ps` | Lister les conteneurs en cours d'exécution | `docker ps` |
| `docker ps -a` | Lister tous les conteneurs (y compris arrêtés) | `docker ps -a` |
| `docker ps -q` | Lister uniquement les IDs des conteneurs | `docker ps -q` |
| `docker run <image>` | Lancer un conteneur | `docker run nginx:latest` |
| `docker run -d <image>` | Lancer un conteneur en arrière-plan | `docker run -d nginx:latest` |
| `docker run -it <image> /bin/bash` | Lancer un conteneur en mode interactif | `docker run -it ubuntu /bin/bash` |
| `docker run --name <name> <image>` | Lancer un conteneur avec un nom | `docker run --name mon-nginx nginx:latest` |
| `docker run -p <host_port>:<container_port> <image>` | Mapper un port | `docker run -p 8080:80 nginx:latest` |
| `docker run -v <host_path>:<container_path> <image>` | Monter un volume | `docker run -v /data:/app/data nginx:latest` |
| `docker run -e <env_var>=<value> <image>` | Définir une variable d'environnement | `docker run -e NODE_ENV=production node:latest` |
| `docker run --restart=always <image>` | Redémarrer automatiquement | `docker run --restart=always nginx:latest` |
| `docker start <container>` | Démarrer un conteneur arrêté | `docker start mon-nginx` |
| `docker stop <container>` | Arrêter un conteneur | `docker stop mon-nginx` |
| `docker restart <container>` | Redémarrer un conteneur | `docker restart mon-nginx` |
| `docker pause <container>` | Mettre en pause un conteneur | `docker pause mon-nginx` |
| `docker unpause <container>` | Reprendre un conteneur en pause | `docker unpause mon-nginx` |
| `docker rm <container>` | Supprimer un conteneur | `docker rm mon-nginx` |
| `docker rm -f <container>` | Supprimer un conteneur en force | `docker rm -f mon-nginx` |
| `docker rm $(docker ps -aq)` | Supprimer tous les conteneurs | `docker rm $(docker ps -aq)` |
| `docker logs <container>` | Afficher les logs d'un conteneur | `docker logs mon-nginx` |
| `docker logs -f <container>` | Suivre les logs en temps réel | `docker logs -f mon-nginx` |
| `docker logs --tail <n> <container>` | Afficher les dernières lignes des logs | `docker logs --tail 100 mon-nginx` |
| `docker exec -it <container> <command>` | Exécuter une commande dans un conteneur | `docker exec -it mon-nginx bash` |
| `docker cp <container>:<path> <host_path>` | Copier un fichier depuis un conteneur | `docker cp mon-nginx:/app/logs ./logs` |
| `docker cp <host_path> <container>:<path>` | Copier un fichier vers un conteneur | `docker cp ./config.conf mon-nginx:/app/config.conf` |
| `docker inspect <container>` | Afficher les détails d'un conteneur | `docker inspect mon-nginx` |
| `docker top <container>` | Afficher les processus en cours d'exécution | `docker top mon-nginx` |
| `docker stats` | Afficher les statistiques d'utilisation | `docker stats` |

---

## 📜 Dockerfile

### Instructions de Base

| Instruction | Description | Exemple |
|-------------|-------------|---------|
| `FROM` | Image de base | `FROM ubuntu:22.04` |
| `LABEL` | Métadonnées | `LABEL maintainer="email@example.com"` |
| `RUN` | Exécuter une commande | `RUN apt update && apt install -y curl` |
| `COPY` | Copier des fichiers | `COPY . /app` |
| `ADD` | Copier des fichiers (avec décompression) | `ADD file.tar.gz /app/` |
| `ENV` | Définir une variable d'environnement | `ENV NODE_ENV=production` |
| `ARG` | Définir un argument de build | `ARG VERSION=1.0.0` |
| `WORKDIR` | Définir le répertoire de travail | `WORKDIR /app` |
| `EXPOSE` | Exposer un port | `EXPOSE 80` |
| `VOLUME` | Créer un point de montage | `VOLUME ["/app/data"]` |
| `USER` | Définir l'utilisateur | `USER node` |
| `CMD` | Commande par défaut | `CMD ["npm", "start"]` |
| `ENTRYPOINT` | Point d'entrée | `ENTRYPOINT ["/app/start.sh"]` |

### Exemple de Dockerfile
```dockerfile
# Image de base
FROM node:18-alpine

# Métadonnées
LABEL maintainer="votre.email@example.com"

# Répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install --production

# Copier le reste de l'application
COPY . .

# Exposer le port
EXPOSE 3000

# Commande de démarrage
CMD ["node", "index.js"]
```

### Multi-Stage Build
```dockerfile
# Étape 1 : Build de l'application
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Étape 2 : Image finale légère
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm install --production
CMD ["node", "dist/index.js"]
```

---

## 🐙 Docker Compose

### Commandes de Base

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker-compose --version` | Vérifier la version | `docker-compose --version` |
| `docker-compose up` | Démarrer les services | `docker-compose up` |
| `docker-compose up -d` | Démarrer les services en arrière-plan | `docker-compose up -d` |
| `docker-compose down` | Arrêter et supprimer les conteneurs | `docker-compose down` |
| `docker-compose down -v` | Arrêter et supprimer les conteneurs + volumes | `docker-compose down -v` |
| `docker-compose ps` | Lister les conteneurs | `docker-compose ps` |
| `docker-compose logs` | Afficher les logs | `docker-compose logs` |
| `docker-compose logs -f` | Suivre les logs en temps réel | `docker-compose logs -f` |
| `docker-compose logs <service>` | Afficher les logs d'un service | `docker-compose logs web` |
| `docker-compose exec <service> <command>` | Exécuter une commande dans un service | `docker-compose exec web bash` |
| `docker-compose build` | Construire les images | `docker-compose build` |
| `docker-compose pull` | Télécharger les images | `docker-compose pull` |
| `docker-compose push` | Pousser les images | `docker-compose push` |
| `docker-compose restart` | Redémarrer les services | `docker-compose restart` |
| `docker-compose start` | Démarrer les services | `docker-compose start` |
| `docker-compose stop` | Arrêter les services | `docker-compose stop` |
| `docker-compose pause` | Mettre en pause les services | `docker-compose pause` |
| `docker-compose unpause` | Reprendre les services | `docker-compose unpause` |
| `docker-compose config` | Vérifier la configuration | `docker-compose config` |

### Exemple de `docker-compose.yml`
```yaml
version: "3.8"

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=postgres
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  db_data:
```

---

## 🌐 Réseau

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker network ls` | Lister les réseaux | `docker network ls` |
| `docker network create <name>` | Créer un réseau | `docker network create mon-reseau` |
| `docker network inspect <name>` | Afficher les détails d'un réseau | `docker network inspect mon-reseau` |
| `docker network rm <name>` | Supprimer un réseau | `docker network rm mon-reseau` |
| `docker network connect <network> <container>` | Connecter un conteneur à un réseau | `docker network connect mon-reseau mon-nginx` |
| `docker network disconnect <network> <container>` | Déconnecter un conteneur d'un réseau | `docker network disconnect mon-reseau mon-nginx` |

---

## 💾 Volumes

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker volume ls` | Lister les volumes | `docker volume ls` |
| `docker volume create <name>` | Créer un volume | `docker volume create mon-volume` |
| `docker volume inspect <name>` | Afficher les détails d'un volume | `docker volume inspect mon-volume` |
| `docker volume rm <name>` | Supprimer un volume | `docker volume rm mon-volume` |
| `docker volume prune` | Supprimer les volumes inutilisés | `docker volume prune` |

---

## 🔒 Sécurité

| Commande | Description | Exemple |
|----------|-------------|---------|
| `docker scan <image>` | Analyser une image pour les vulnérabilités | `docker scan nginx:latest` |
| `docker trust inspect <image>` | Vérifier la signature d'une image | `docker trust inspect nginx:latest` |
| `docker run --read-only <image>` | Lancer un conteneur en lecture seule | `docker run --read-only nginx:latest` |
| `docker run --user <user> <image>` | Lancer un conteneur avec un utilisateur spécifique | `docker run --user node nginx:latest` |
| `docker run --cap-drop=<capability> <image>` | Supprimer des capabilities | `docker run --cap-drop=ALL nginx:latest` |
| `docker run --security-opt <option> <image>` | Options de sécurité | `docker run --security-opt no-new-privileges nginx:latest` |

---

## 🛠️ Dépannage

| Problème | Solution | Commande |
|----------|----------|----------|
| `Cannot connect to the Docker daemon` | Docker n'est pas démarré | `sudo systemctl start docker` |
| `Permission denied` | L'utilisateur n'est pas dans le groupe docker | `sudo usermod -aG docker $USER` |
| `No such image` | L'image n'existe pas localement | `docker pull <image>` |
| `No such container` | Le conteneur n'existe pas | `docker ps -a` |
| `Port already in use` | Le port est déjà utilisé | `lsof -i :<port>` |
| `Container already running` | Le conteneur est déjà en cours d'exécution | `docker stop <container>` |
| `Image already exists` | L'image existe déjà | `docker rmi <image>` |
| `Error response from daemon: conflict` | Conflit de nom ou de ressource | `docker rm <container>` ou `docker rmi <image>` |

---

## 📚 Ressources

- [Documentation Officielle Docker](https://docs.docker.com)
- [Docker Cheatsheet Officiel](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Hub](https://hub.docker.com)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Bonne utilisation de Docker !** 🚀
