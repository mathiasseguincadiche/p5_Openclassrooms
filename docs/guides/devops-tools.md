# 🛠️ Présentation des Outils DevOps

**Ce guide détaille chaque outil DevOps utilisé dans le projet P5.**
Pour chaque outil, vous trouverez :
- Une **description** de son rôle.
- Ses **cas d'usage** typiques.
- Des **liens utiles** vers la documentation.
- Des **exemples concrets** dans le contexte du projet.

---

## 📌 Table des Matières

1. [Docker](#-docker)
2. [Docker Compose](#-docker-compose)
3. [GitHub Actions](#-github-actions)
4. [Ansible](#-ansible)
5. [Terraform](#-terraform)
6. [Kubernetes](#-kubernetes)
7. [Comparatif des Outils](#-comparatif-des-outils)

---

## 🐳 Docker

### 📌 Description
**Docker** est une plateforme open-source qui permet de **conteneuriser** des applications. Un conteneur est une unité légère et portable qui regroupe une application et toutes ses dépendances (bibliothèques, outils système, etc.).

### 🎯 Cas d'Usage
- **Isoler** une application et ses dépendances.
- **Standardiser** les environnements de développement, test, et production.
- **Déployer** rapidement des applications sur n'importe quelle machine.
- **Scaler** horizontalement en lançant plusieurs instances d'un conteneur.

### 🔹 Concepts Clés
| Concept | Description | Exemple |
|---------|-------------|---------|
| **Image** | Modèle immuable pour créer un conteneur. | `node:18-alpine` |
| **Conteneur** | Instance d'une image en cours d'exécution. | `docker run -d nginx` |
| **Dockerfile** | Fichier de configuration pour construire une image. | [Voir template](../../../TEMPLATES/docker/Dockerfile.nodejs) |
| **Docker Hub** | Registre public pour partager des images. | [hub.docker.com](https://hub.docker.com) |
| **Volume** | Stockage persistant pour les conteneurs. | `docker volume create` |
| **Réseau** | Permet aux conteneurs de communiquer. | `docker network create` |

### 📚 Documentation
- [Documentation Officielle](https://docs.docker.com)
- [Docker pour Débutants](https://docker-curriculum.com/)
- [Docker Cheatsheet](../cheatsheets/docker.md)

### 💡 Exemple dans le Projet
```bash
# Construire une image à partir d'un Dockerfile
docker build -t mon-app:v1 .

# Lancer un conteneur à partir de l'image
docker run -d -p 3000:3000 mon-app:v1

# Lister les conteneurs en cours d'exécution
docker ps
```

---

## 🐙 Docker Compose

### 📌 Description
**Docker Compose** est un outil qui permet de définir et gérer des **applications multi-conteneurs** à l'aide d'un fichier YAML (`docker-compose.yml`). Il simplifie le lancement de plusieurs conteneurs qui doivent communiquer entre eux.

### 🎯 Cas d'Usage
- **Développer** des applications qui nécessitent plusieurs services (ex: base de données + backend + frontend).
- **Tester** des environnements complexes localement.
- **Automatiser** le déploiement de stacks multi-conteneurs.

### 🔹 Concepts Clés
| Concept | Description | Exemple |
|---------|-------------|---------|
| **Service** | Un conteneur défini dans le fichier `docker-compose.yml`. | `web`, `db`, `redis` |
| **Fichier `docker-compose.yml`** | Fichier de configuration pour définir les services. | [Voir template](../../../TEMPLATES/docker/docker-compose.yml) |
| **Réseau par défaut** | Réseau créé automatiquement pour les services. | `p5_default` |
| **Volume nommé** | Volume persistant pour les données. | `db_data:/var/lib/mysql` |

### 📚 Documentation
- [Documentation Officielle](https://docs.docker.com/compose/)
- [Exemple de `docker-compose.yml`](https://docs.docker.com/compose/gettingstarted/)

### 💡 Exemple dans le Projet
```yaml
# docker-compose.yml
version: "3.8"

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

```bash
# Démarrer les services
docker-compose up -d

# Arrêter les services
docker-compose down

# Voir les logs
docker-compose logs -f
```

---

## 🚀 GitHub Actions

### 📌 Description
**GitHub Actions** est une plateforme de **CI/CD (Continuous Integration/Continuous Deployment)** intégrée à GitHub. Elle permet d'automatiser des workflows (tests, builds, déploiements) directement depuis votre dépôt GitHub.

### 🎯 Cas d'Usage
- **Exécuter des tests** automatiquement à chaque push ou pull request.
- **Construire et pousser** des images Docker.
- **Déployer** une application sur un serveur ou un cloud.
- **Automatiser** des tâches répétitives (ex: génération de documentation).

### 🔹 Concepts Clés
| Concept | Description | Exemple |
|---------|-------------|---------|
| **Workflow** | Fichier YAML qui définit un processus automatisé. | `.github/workflows/ci.yml` |
| **Job** | Ensemble d'étapes exécutées sur un runner. | `test`, `build`, `deploy` |
| **Step** | Action individuelle dans un job. | `uses: actions/checkout@v4` |
| **Runner** | Machine virtuelle qui exécute les workflows. | `ubuntu-latest`, `windows-latest` |
| **Event** | Déclencheur d'un workflow. | `push`, `pull_request`, `schedule` |
| **Action** | Module réutilisable pour une tâche spécifique. | `actions/checkout`, `actions/setup-node` |

### 📚 Documentation
- [Documentation Officielle](https://docs.github.com/en/actions)
- [Marketplace d'Actions](https://github.com/marketplace?type=actions)
- [Exemples de Workflows](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

### 💡 Exemple dans le Projet
```yaml
# .github/workflows/ci.yml
name: CI - Node.js

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm test
```

```bash
# Les workflows s'exécutent automatiquement sur GitHub.
# Pour voir les résultats :
# 1. Allez dans l'onglet "Actions" de votre dépôt GitHub.
# 2. Sélectionnez le workflow et la run.
```

---

## 🔧 Ansible

### 📌 Description
**Ansible** est un outil d'**automatisation de la configuration** et de **gestion de l'infrastructure**. Il permet de configurer des serveurs, de déployer des applications, et de gérer des tâches répétitives de manière **idempotente** (une tâche exécutée plusieurs fois donne le même résultat).

### 🎯 Cas d'Usage
- **Configurer** des serveurs de manière reproductible.
- **Déployer** des applications sur plusieurs machines.
- **Gérer** des mises à jour de sécurité.
- **Automatiser** des tâches d'administration système.

### 🔹 Concepts Clés
| Concept | Description | Exemple |
|---------|-------------|---------|
| **Playbook** | Fichier YAML qui définit une série de tâches. | `playbook.yml` |
| **Inventory** | Fichier qui liste les machines à configurer. | `inventory.ini` |
| **Module** | Unité de travail réutilisable (ex: `apt`, `yum`, `file`). | `ansible.builtin.apt` |
| **Task** | Action individuelle dans un playbook. | `- name: Install Nginx` |
| **Role** | Collection de playbooks, templates, et variables. | `roles/webserver` |
| **Idempotence** | Une tâche ne change rien si l'état souhaité est déjà atteint. | - |

### 📚 Documentation
- [Documentation Officielle](https://docs.ansible.com)
- [Ansible pour Débutants](https://www.ansible.com/resources/get-started)
- [Galerie de Modules](https://galaxy.ansible.com/)

### 💡 Exemple dans le Projet
```yaml
# playbook.yml
---
- name: Configurer un serveur web
  hosts: webservers
  become: yes

  tasks:
    - name: Mettre à jour les paquets
      apt:
        update_cache: yes
        upgrade: dist

    - name: Installer Nginx
      apt:
        name: nginx
        state: present

    - name: Démarrer et activer Nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

```ini
# inventory.ini
[webservers]
server1 ansible_host=192.168.1.10
server2 ansible_host=192.168.1.11

[webservers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

```bash
# Exécuter le playbook
ansible-playbook -i inventory.ini playbook.yml
```

---

## ☁️ Terraform

### 📌 Description
**Terraform** est un outil d'**Infrastructure as Code (IaC)** qui permet de **provisionner** et de **gérer** une infrastructure cloud (AWS, Azure, GCP, etc.) de manière **déclarative**. Avec Terraform, vous définissez l'état souhaité de votre infrastructure, et l'outil se charge de l'atteindre.

### 🎯 Cas d'Usage
- **Provisionner** des ressources cloud (instances, bases de données, réseaux, etc.).
- **Versionner** votre infrastructure (fichiers `.tf` dans Git).
- **Reproduire** un environnement de manière cohérente.
- **Collaborer** sur l'infrastructure avec une équipe.

### 🔹 Concepts Clés
| Concept | Description | Exemple |
|---------|-------------|---------|
| **Provider** | Plugin pour interagir avec un cloud (AWS, Azure, etc.). | `aws`, `azurerm`, `google` |
| **Resource** | Une unité d'infrastructure (ex: instance, bucket). | `aws_instance`, `aws_s3_bucket` |
| **Module** | Collection de ressources réutilisables. | `module "vpc" { ... }` |
| **Variable** | Paramètre personnalisable. | `variable "instance_type" { ... }` |
| **Output** | Valeur retournée après l'application. | `output "public_ip" { ... }` |
| **State** | Fichier qui stocke l'état actuel de l'infrastructure. | `terraform.tfstate` |

### 📚 Documentation
- [Documentation Officielle](https://developer.hashicorp.com/terraform)
- [Registry de Modules Terraform](https://registry.terraform.io/)
- [Tutoriel Terraform](https://learn.hashicorp.com/terraform)

### 💡 Exemple dans le Projet
```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "p5-openclassrooms-server"
  }
}

output "server_public_ip" {
  value = aws_instance.app_server.public_ip
}
```

```bash
# Initialiser Terraform
tf init

# Voir le plan d'exécution
tf plan

# Appliquer les changements
tf apply

# Détruire l'infrastructure
tf destroy
```

---

## 🐳 Kubernetes

### 📌 Description
**Kubernetes** (ou **K8s**) est une plateforme open-source pour **orchestrer** des conteneurs. Elle permet de **déployer**, **scaler**, et **gérer** des applications conteneurisées de manière automatisée.

### 🎯 Cas d'Usage
- **Déployer** des applications conteneurisées à grande échelle.
- **Scaler** automatiquement en fonction de la charge.
- **Gérer** des mises à jour sans temps d'arrêt (rolling updates).
- **Équilibrer la charge** entre plusieurs instances d'une application.

### 🔹 Concepts Clés
| Concept | Description | Exemple |
|---------|-------------|---------|
| **Cluster** | Ensemble de machines (nœuds) qui exécutent Kubernetes. | - |
| **Node** | Machine physique ou virtuelle dans le cluster. | `Master Node`, `Worker Node` |
| **Pod** | Plus petite unité déployable dans Kubernetes (1 ou plusieurs conteneurs). | `pod-nginx` |
| **Deployment** | Gère le déploiement et la mise à jour des pods. | `deployment.yaml` |
| **Service** | Expose un ensemble de pods comme un service réseau. | `service.yaml` |
| **Ingress** | Gère l'accès HTTP/HTTPS aux services. | `ingress.yaml` |
| **ConfigMap/Secret** | Stocke des configurations ou des secrets. | `configmap.yaml` |
| **kubectl** | CLI pour interagir avec Kubernetes. | `kubectl get pods` |

### 📚 Documentation
- [Documentation Officielle](https://kubernetes.io/docs/home/)
- [Tutoriel Kubernetes](https://kubernetes.io/docs/tutorials/)
- [Kubernetes Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### 💡 Exemple dans le Projet
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

```bash
# Appliquer les configurations
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Voir les pods
kubectl get pods

# Voir les services
kubectl get services

# Accéder au service (si LoadBalancer)
kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 📊 Comparatif des Outils

| Outil | Type | Niveau | Avantages | Inconvénients | Cas d'Usage |
|-------|------|--------|-----------|---------------|-------------|
| **Docker** | Conteneurisation | Débutant | Léger, portable, simple | Pas de scaling natif | Développement, tests |
| **Docker Compose** | Orchestration locale | Débutant | Simple, multi-conteneurs | Pas pour la production | Développement local |
| **GitHub Actions** | CI/CD | Débutant/Intermédiaire | Intégré à GitHub, facile à configurer | Limité à GitHub | Automatisation de workflows |
| **Ansible** | Configuration Management | Intermédiaire | Agentless, idempotent, simple | Lent pour les gros déploiements | Configuration de serveurs |
| **Terraform** | IaC | Intermédiaire | Multi-cloud, déclaratif | Courbe d'apprentissage | Provisionnement d'infrastructure |
| **Kubernetes** | Orchestration | Avancé | Scalable, résilient | Complexe, lourd | Production à grande échelle |

---

## 🎯 Quel Outil Choisir ?

| Besoin | Outil Recommandé |
|--------|------------------|
| Conteneuriser une application | **Docker** |
| Développer une app multi-services localement | **Docker Compose** |
| Automatiser des tests et déploiements | **GitHub Actions** |
| Configurer des serveurs | **Ansible** |
| Provisionner une infrastructure cloud | **Terraform** |
| Déployer une app en production à grande échelle | **Kubernetes** |

---

## 📌 Résumé

| Outil | Rôle | Lien | Niveau |
|-------|------|------|--------|
| **Docker** | Conteneurisation | [docs.docker.com](https://docs.docker.com) | Débutant |
| **Docker Compose** | Orchestration locale | [docs.docker.com/compose](https://docs.docker.com/compose/) | Débutant |
| **GitHub Actions** | CI/CD | [docs.github.com/actions](https://docs.github.com/en/actions) | Débutant/Intermédiaire |
| **Ansible** | Configuration Management | [docs.ansible.com](https://docs.ansible.com) | Intermédiaire |
| **Terraform** | IaC | [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform) | Intermédiaire |
| **Kubernetes** | Orchestration | [kubernetes.io](https://kubernetes.io) | Avancé |

---

**Prochaine étape** : [Faire l'Exercice 1 - Déploiement avec Docker](../exercises/exercise-1/README.md) 🚀
