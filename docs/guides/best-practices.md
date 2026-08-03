# 🌟 Bonnes Pratiques DevOps

**Ce guide regroupe les meilleures pratiques à adopter** pour travailler efficacement avec les outils DevOps. Que vous soyez débutant ou expérimenté, ces conseils vous aideront à **éviter les erreurs courantes**, **optimiser vos workflows**, et **collaborer efficacement**.

---

## 📌 Table des Matières

1. [Bonnes Pratiques Git](#-bonnes-pratiques-git)
2. [Bonnes Pratiques Docker](#-bonnes-pratiques-docker)
3. [Bonnes Pratiques CI/CD](#-bonnes-pratiques-cicd)
4. [Bonnes Pratiques Ansible](#-bonnes-pratiques-ansible)
5. [Bonnes Pratiques Terraform](#-bonnes-pratiques-terraform)
6. [Bonnes Pratiques Kubernetes](#-bonnes-pratiques-kubernetes)
7. [Sécurité](#-sécurité)
8. [Collaboration](#-collaboration)

---

## 🔀 Bonnes Pratiques Git

### 1. **Commits Atomiques**
Un commit doit représenter **une seule modification logique**. Évitez les commits géants qui mélangent plusieurs fonctionnalités.

✅ **Bon** :
```bash
# Un commit par fonctionnalité
git commit -m "fix: corrige le bug de connexion"
git commit -m "feat: ajoute un bouton de partage"
```

❌ **Mauvais** :
```bash
# Un commit qui fait trop de choses
git commit -m "fix bug + ajoute bouton + mise à jour README"
```

### 2. **Messages de Commit Clairs**
Utilisez des messages **descriptifs** et **structurés**. Adoptez la convention [Conventional Commits](https://www.conventionalcommits.org/) :
- `feat:` : Nouvelle fonctionnalité.
- `fix:` : Correction de bug.
- `docs:` : Modification de la documentation.
- `style:` : Changements de style (indentation, etc.).
- `refactor:` : Refactorisation du code.
- `test:` : Ajout ou modification de tests.
- `chore:` : Tâches de maintenance.

✅ **Bon** :
```bash
git commit -m "feat: ajoute un endpoint /api/users"
git commit -m "fix: corrige l'erreur 500 sur /login"
```

❌ **Mauvais** :
```bash
git commit -m "fix"
git commit -m "truc"
```

### 3. **Branches Courtes et Descriptives**
- Utilisez des noms de branches **courts et explicites**.
- Évitez les branches `master` ou `main` pour le développement (utilisez des branches de feature).
- Supprimez les branches après fusion.

✅ **Bon** :
```bash
# Pour une nouvelle fonctionnalité
git checkout -b feat/user-authentication

# Pour un bug
git checkout -b fix/login-error
```

❌ **Mauvais** :
```bash
git checkout -b patch-1
git checkout -b temp
```

### 4. **Pull Requests (PR) de Qualité**
- **Description claire** : Expliquez **pourquoi** ce changement est nécessaire.
- **Commits propres** : Rebasez ou squashez vos commits avant de merger.
- **Tests passés** : Assurez-vous que tous les tests passent.
- **Revue par les pairs** : Demandez une revue avant de merger.

✅ **Bon** :
```markdown
# Description de la PR

## Pourquoi ?
- Corrige le bug #123 où les utilisateurs ne pouvaient pas se connecter.

## Changements
- Modification du middleware d'authentification.
- Ajout de tests pour couvrir le cas d'erreur.

## Comment tester ?
1. Lancer l'application.
2. Essayer de se connecter avec un utilisateur invalide.
3. Vérifier que le message d'erreur est affiché.
```

### 5. **`.gitignore` Bien Configuré**
Excluez les fichiers **inutiles** ou **sensibles** :
- `node_modules/`
- `.env`
- `*.log`
- `dist/` ou `build/`
- Fichiers IDE (`.vscode/`, `.idea/`)

Exemple de `.gitignore` :
```gitignore
# Node.js
node_modules/
npm-debug.log*

# Environnement
.env
.env.local

# Logs
*.log

# Build
build/
dist/

# IDE
.vscode/
.idea/
```

---

## 🐳 Bonnes Pratiques Docker

### 1. **Images Légères**
- Utilisez des **images officielles** et **légères** (ex: `alpine` au lieu de `ubuntu`).
- Évitez d'installer des paquets inutiles.

✅ **Bon** :
```dockerfile
FROM node:18-alpine  # Alpine est plus léger qu'ubuntu
```

❌ **Mauvais** :
```dockerfile
FROM ubuntu:latest  # Plus lourd et moins sécurisé
```

### 2. **Multi-Stage Builds**
Utilisez des **multi-stage builds** pour réduire la taille de l'image finale.

✅ **Bon** :
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

### 3. **Utilisez `.dockerignore`**
Excluez les fichiers inutiles pour **accélérer le build** et **réduire la taille de l'image**.

Exemple de `.dockerignore` :
```dockerignore
node_modules/
.git/
Dockerfile
docker-compose.yml
*.md
```

### 4. **Variables d'Environnement**
- **Ne jamais hardcoder** des secrets dans le `Dockerfile`.
- Utilisez des **variables d'environnement** ou des **secrets Docker**.

✅ **Bon** :
```dockerfile
# Utilise ARG pour les valeurs de build
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Les secrets sont passés à l'exécution
env_file: .env
```

❌ **Mauvais** :
```dockerfile
# ❌ Ne jamais faire ça !
ENV DB_PASSWORD=monmotdepasse123
```

### 5. **Tags Immuables**
- Utilisez des **tags immuables** (ex: `v1.0.0`) pour les images en production.
- Évitez `latest` en production (il peut changer sans préavis).

✅ **Bon** :
```bash
docker build -t mon-app:v1.0.0 .
docker push mon-app:v1.0.0
```

❌ **Mauvais** :
```bash
docker build -t mon-app:latest .  # ❌ Évitez en production
```

### 6. **Sécurité**
- **Exécutez en tant qu'utilisateur non-root** dans le conteneur.
- **Mettez à jour** régulièrement vos images de base.

✅ **Bon** :
```dockerfile
FROM node:18-alpine

# Crée un utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app
COPY --chown=appuser:appgroup . .
```

---

## 🚀 Bonnes Pratiques CI/CD

### 1. **Workflows Rapides**
- **Parallélisez** les jobs quand c'est possible.
- **Cachez** les dépendances pour accélérer les builds.

✅ **Bon** :
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'  # Cache les dépendances npm
      - run: npm ci
      - run: npm test
```

### 2. **Tests à Chaque Commit**
- Exécutez **au moins les tests unitaires** à chaque push.
- Ajoutez des **tests d'intégration** pour les branches principales.

### 3. **Déploiement Progressif**
- **Déployez d'abord en staging** avant la production.
- Utilisez des **stratégies de déploiement** (rolling, blue-green, canary).

✅ **Bon** :
```yaml
# Déploiement en staging puis en production
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: ./deploy.sh staging

  deploy-production:
    needs: deploy-staging  # Attend que staging soit déployé
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: ./deploy.sh production
```

### 4. **Notifications**
- Configurez des **notifications** pour les échecs de déploiement (Slack, email, etc.).

### 5. **Rollback Facile**
- **Versionnez vos déploiements** pour pouvoir revenir en arrière.
- **Testez le rollback** régulièrement.

---

## 🔧 Bonnes Pratiques Ansible

### 1. **Idempotence**
- Chaque tâche doit être **idempotente** (exécutée plusieurs fois sans changer le résultat).

✅ **Bon** :
```yaml
- name: Installer Nginx
  apt:
    name: nginx
    state: present  # Idempotent : installe seulement si absent
```

### 2. **Utilisez des Rôles**
- Organisez votre code en **rôles** pour une meilleure réutilisabilité.

```bash
ansible-galaxy init roles/webserver
```

Structure d'un rôle :
```bash
roles/
  webserver/
    ├── tasks/          # Tâches principales
    ├── handlers/       # Handlers (ex: redémarrer un service)
    ├── templates/      # Fichiers de template (Jinja2)
    ├── files/          # Fichiers statiques
    ├── vars/           # Variables
    └── defaults/       # Variables par défaut
```

### 3. **Variables dans `group_vars` et `host_vars`**
- **Évitez de hardcoder** des valeurs dans les playbooks.
- Utilisez `group_vars/` et `host_vars/` pour les configurations spécifiques.

✅ **Bon** :
```bash
# group_vars/webservers.yml
nginx_version: "1.18.0"
```

```yaml
# playbook.yml
- name: Installer Nginx
  apt:
    name: "nginx={{ nginx_version }}"
    state: present
```

### 4. **Utilisez des Tags**
- Ajoutez des **tags** aux tâches pour exécuter seulement certaines parties.

✅ **Bon** :
```yaml
- name: Installer Nginx
  apt:
    name: nginx
    state: present
  tags: install

- name: Configurer Nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags: config
```

```bash
# Exécuter seulement les tâches avec le tag 'install'
ansible-playbook playbook.yml --tags "install"
```

### 5. **Vérifiez avec `--check`**
- Utilisez `--check` pour simuler l'exécution sans appliquer les changements.

```bash
ansible-playbook playbook.yml --check
```

---

## ☁️ Bonnes Pratiques Terraform

### 1. **Modularisez Votre Code**
- Utilisez des **modules** pour réutiliser du code.

✅ **Bon** :
```hcl
# modules/vpc/main.tf
variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
}

# main.tf
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}
```

### 2. **Versionnez Votre État**
- **Ne jamais modifier manuellement** le fichier `terraform.tfstate`.
- Utilisez un **backend distant** (S3, Azure Blob Storage, etc.) pour stocker l'état.

✅ **Bon** :
```hcl
terraform {
  backend "s3" {
    bucket = "mon-bucket-terraform"
    key    = "p5-openclassrooms/terraform.tfstate"
    region = "eu-west-3"
  }
}
```

### 3. **Utilisez des Variables**
- **Ne hardcodez pas** les valeurs dans les fichiers `.tf`.
- Utilisez des **variables** avec des valeurs par défaut.

✅ **Bon** :
```hcl
# variables.tf
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

# main.tf
resource "aws_instance" "app" {
  instance_type = var.instance_type
}
```

### 4. **Planifiez les Changements**
- **Toujours exécuter `terraform plan`** avant `terraform apply`.
- Utilisez `-out` pour sauvegarder le plan.

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### 5. **Verrouillez les Versions des Providers**
- Spécifiez les **versions des providers** pour éviter les surprises.

✅ **Bon** :
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Verrouille la version
    }
  }
}
```

---

## 🐳 Bonnes Pratiques Kubernetes

### 1. **Utilisez des Manifestes Déclaratifs**
- Définissez l'**état souhaité** de votre application dans des fichiers YAML.
- Évitez d'utiliser `kubectl create` ou `kubectl run` en production.

✅ **Bon** :
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
```

```bash
kubectl apply -f deployment.yaml
```

### 2. **Gérez les Configurations avec ConfigMaps et Secrets**
- **Ne hardcodez pas** les configurations dans les manifests.
- Utilisez des **ConfigMaps** pour les configurations non sensibles.
- Utilisez des **Secrets** pour les données sensibles (mots de passe, clés API).

✅ **Bon** :
```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
Data:
  DB_HOST: "postgres"
  DB_PORT: "5432"
```

```yaml
# secret.yaml (à créer avec kubectl create secret)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
Data:
  DB_PASSWORD: <base64-encoded-password>
```

### 3. **Utilisez des Liveness et Readiness Probes**
- **Liveness Probe** : Vérifie si le conteneur est **en vie** (redémarre si échec).
- **Readiness Probe** : Vérifie si le conteneur est **prêt à recevoir du trafic**.

✅ **Bon** :
```yaml
containers:
- name: nginx
  image: nginx:1.25
  livenessProbe:
    httpGet:
      path: /healthz
      port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /ready
      port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
```

### 4. **Limitez les Ressources**
- Définissez des **limites de CPU et mémoire** pour éviter qu'un conteneur ne consomme toutes les ressources.

✅ **Bon** :
```yaml
containers:
- name: nginx
  image: nginx:1.25
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

### 5. **Utilisez des Namespaces**
- **Isolez** les applications dans des **namespaces** (ex: `dev`, `staging`, `prod`).

✅ **Bon** :
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```bash
kubectl create -f namespace.yaml
kubectl apply -f deployment.yaml -n dev
```

### 6. **Surveillez Votre Cluster**
- Utilisez des outils comme **Prometheus + Grafana** pour surveiller votre cluster.
- Configurez des **alertes** pour les problèmes (CPU, mémoire, etc.).

---

## 🔒 Sécurité

### 1. **Ne Stockez Pas de Secrets dans le Code**
- **❌ Jamais** dans Git, Dockerfiles, ou manifests Kubernetes.
- Utilisez :
  - **Variables d'environnement** (`.env` + `.gitignore`).
  - **Secrets Kubernetes** (`kubectl create secret`).
  - **Vaults** (HashiCorp Vault, AWS Secrets Manager).

### 2. **Mettez à Jour Régulièrement**
- **Images Docker** : Utilisez des images officielles et mettez-les à jour.
- **Dépendances** : Utilisez `npm audit`, `pip-audit`, etc.
- **Outils** : Mettez à jour Docker, Kubernetes, Terraform, etc.

### 3. **Principle of Least Privilege**
- Donnez **le minimum de permissions** nécessaires.
- Exemple :
  - Un conteneur n'a pas besoin de tourner en `root`.
  - Un utilisateur Ansible n'a pas besoin d'être `sudo` par défaut.

### 4. **Audit et Logs**
- **Activez les logs** pour tous vos outils (Docker, Kubernetes, etc.).
- **Centralisez les logs** (ELK Stack, Loki, etc.).
- **Auditez** régulièrement vos configurations.

### 5. **Réseau Sécurisé**
- **Docker** : Utilisez des réseaux privés pour les conteneurs.
- **Kubernetes** : Utilisez des **NetworkPolicies** pour restreindre le trafic.
- **Cloud** : Configurez des **Security Groups** et **Firewalls**.

---

## 🤝 Collaboration

### 1. **Documentation**
- **Documentez** chaque projet avec un `README.md`.
- **Expliquez** les étapes pour :
  - Configurer l'environnement.
  - Exécuter les tests.
  - Déployer l'application.

### 2. **Revue de Code**
- **Faites relire** vos PR par au moins une autre personne.
- **Soyez constructif** dans vos commentaires.

### 3. **Conventions de Nommage**
- Utilisez des **noms cohérents** pour :
  - Les branches (`feat/`, `fix/`, `docs/`).
  - Les ressources (ex: `p5-app-server`, `p5-db`).
  - Les variables (ex: `DB_HOST`, `API_KEY`).

### 4. **Automatisez ce qui peut l'être**
- Utilisez des **scripts** pour les tâches répétitives.
- Automatisez les **tests** et les **déploiements**.

---

## 📌 Résumé des Bonnes Pratiques

| Catégorie | Bonne Pratique | Outil Concerné |
|-----------|----------------|----------------|
| Git | Commits atomiques | Git |
| Git | Messages de commit clairs | Git |
| Git | Branches courtes et descriptives | Git |
| Docker | Images légères | Docker |
| Docker | Multi-stage builds | Docker |
| Docker | `.dockerignore` | Docker |
| CI/CD | Workflows rapides | GitHub Actions |
| CI/CD | Tests à chaque commit | GitHub Actions |
| Ansible | Idempotence | Ansible |
| Ansible | Utilisez des rôles | Ansible |
| Terraform | Modularisez votre code | Terraform |
| Terraform | Versionnez votre état | Terraform |
| Kubernetes | Manifestes déclaratifs | Kubernetes |
| Kubernetes | ConfigMaps et Secrets | Kubernetes |
| Sécurité | Ne stockez pas de secrets dans le code | Tous |
| Sécurité | Mettez à jour régulièrement | Tous |

---

**Prochaine étape** : [Faire l'Exercice 1 - Déploiement avec Docker](../exercises/exercise-1/README.md) 🚀
