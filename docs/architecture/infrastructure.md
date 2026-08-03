# 🏗️ Schéma d'Infrastructure - P5 OpenClassrooms

**Ce document présente l'architecture globale du projet P5**, avec des **schémas détaillés** pour chaque composant. Les schémas sont générés en **Mermaid** pour une visualisation claire et intégrée directement dans la documentation.

---

## 📌 Table des Matières

1. [Schéma Global du Projet](#-schéma-global-du-projet)
2. [Schéma de l'Environnement Local](#-schéma-de-lenvironnement-local)
3. [Schéma de l'Environnement GitHub](#-schéma-de-lenvironnement-github)
4. [Schéma de l'Environnement de Production](#-schéma-de-lenvironnement-de-production)
5. [Schéma par Exercice](#-schéma-par-exercice)
6. [Légende](#-légende)

---

## 🌍 Schéma Global du Projet

Ce schéma montre **l'architecture complète** du projet, de l'environnement local au déploiement en production.

```mermaid
graph TD
    subgraph "💻 Environnement Local"
        A[Développeur] -->|git clone| B[Dépôt GitHub]
        A -->|Édite le code| C[Code Source]
        C -->|Dockerfile| D[Build Image Docker]
        D --> E[Docker Hub]
        D -->|docker run| F[Conteneur Local]
        F -->|Expose Port| G[Application en Local]
        
        C -->|docker-compose.yml| H[Docker Compose]
        H --> I[Multi-Conteneurs]
        I --> J[Base de Données]
        I --> K[Backend]
        I --> L[Frontend]
        
        C -->|minikube/kind| M[Cluster K8s Local]
        M --> N[Pods]
        N --> O[Services]
    end

    subgraph "☁️ GitHub"
        B -->|push| P[GitHub Actions]
        P --> Q[Workflow CI]
        Q --> R[Tests Automatiques]
        Q --> S[Linting]
        P --> T[Workflow CD]
        T --> U[Déploiement]
    end

    subgraph "🚀 Environnement de Production"
        U --> V[Terraform]
        V --> W[AWS/Azure/GCP]
        W --> X[Réseau VPC]
        W --> Y[Load Balancer]
        W --> Z[Cluster Kubernetes]
        Z --> AA[Nodes Master]
        Z --> AB[Nodes Worker]
        AB --> AC[Pods]
        AC --> AD[Conteneurs]
        AD --> AE[Applications]
        AE --> AF[Base de Données]
        Y --> AE
    end

    subgraph "🔧 Outils de Configuration"
        W -->|Provisionnement| V
        Z -->|Orchestration| AA
        AB -->|Configuration| AG[Ansible]
        AG -->|Playbooks| AH[Serveurs]
    end

    style A fill:#f9f,stroke:#333
    style B fill:#bbf,stroke:#333
    style D fill:#9f9,stroke:#333
    style P fill:#ff9,stroke:#333
    style V fill:#99f,stroke:#333
    style Z fill:#f96,stroke:#333
```

---

## 💻 Schéma de l'Environnement Local

Ce schéma détaille **l'environnement de développement local**, avec Docker, Docker Compose, et Kubernetes.

### Avec Docker
```mermaid
graph LR
    A[Code Source] -->|Dockerfile| B[Image Docker]
    B -->|docker build| C[Docker Daemon]
    C -->|docker run| D[Conteneur]
    D -->|Expose Port| E[Application]
    E -->|http://localhost:3000| F[Navigateur]
    
    style A fill:#9f9,stroke:#333
    style B fill:#ff9,stroke:#333
    style D fill:#f96,stroke:#333
```

### Avec Docker Compose
```mermaid
graph TD
    A[docker-compose.yml] --> B[Docker Compose]
    B --> C[Crée un Réseau]
    B --> D[Lance les Services]
    
    D --> E[Service: web]
    D --> F[Service: db]
    D --> G[Service: redis]
    
    E -->|Port 80| H[Navigateur]
    F -->|Port 5432| E
    G -->|Port 6379| E
    
    style A fill:#bbf,stroke:#333
    style D fill:#9f9,stroke:#333
    style E fill:#ff9,stroke:#333
    style F fill:#f96,stroke:#333
```

### Avec Kubernetes (Minikube/Kind)
```mermaid
graph TD
    A[Cluster K8s Local] --> B[Node Master]
    A --> C[Node Worker]
    
    B --> D[API Server]
    B --> E[Scheduler]
    B --> F[Controller Manager]
    B --> G[Etcd]
    
    C --> H[Pod 1]
    C --> I[Pod 2]
    C --> J[Pod 3]
    
    H --> K[Conteneur App]
    H --> L[Conteneur Sidecar]
    K --> M[Service]
    M --> N[Ingress]
    N --> O[http://localhost:8080]
    
    style A fill:#f96,stroke:#333
    style B fill:#ff9,stroke:#333
    style C fill:#9f9,stroke:#333
    style H fill:#bbf,stroke:#333
```

---

## ☁️ Schéma de l'Environnement GitHub

Ce schéma montre comment **GitHub Actions** automatise les tests et les déploiements.

```mermaid
graph TD
    A[Push sur main] --> B[GitHub Actions]
    A --> C[Pull Request]
    C --> B
    
    B --> D[Workflow CI]
    D --> E[Checkout Code]
    E --> F[Setup Node.js]
    F --> G[Install Dependencies]
    G --> H[Run Tests]
    H --> I[Run Linter]
    I --> J[Build Docker Image]
    J --> K[Push to Docker Hub]
    
    D -->|Succès| L[Workflow CD]
    L --> M[Déploiement en Staging]
    M --> N[Tests en Staging]
    N -->|Succès| O[Déploiement en Production]
    
    I -->|Échec| P[Notification Slack]
    N -->|Échec| P
    
    style A fill:#bbf,stroke:#333
    style D fill:#9f9,stroke:#333
    style L fill:#ff9,stroke:#333
    style O fill:#f96,stroke:#333
    style P fill:#f99,stroke:#333
```

---

## 🚀 Schéma de l'Environnement de Production

Ce schéma détaille **l'infrastructure en production**, avec Terraform, Kubernetes, et Ansible.

### Infrastructure as Code avec Terraform
```mermaid
graph TD
    A[Fichiers Terraform] --> B[terraform init]
    B --> C[terraform plan]
    C --> D[terraform apply]
    D --> E[AWS/Azure/GCP]
    
    E --> F[VPC]
    E --> G[Subnets]
    E --> H[Security Groups]
    E --> I[Load Balancer]
    E --> J[Cluster Kubernetes]
    E --> K[Base de Données]
    
    style A fill:#99f,stroke:#333
    style D fill:#ff9,stroke:#333
    style E fill:#f96,stroke:#333
```

### Cluster Kubernetes en Production
```mermaid
graph TD
    A[Cluster Kubernetes] --> B[Node Master x3]
    A --> C[Node Worker xN]
    
    B --> D[API Server]
    B --> E[Scheduler]
    B --> F[Controller Manager]
    B --> G[Etcd Cluster]
    
    C --> H[Pods]
    H --> I[Conteneurs]
    I --> J[Applications]
    
    A --> K[Service Mesh]
    K -->|Istio/Linkerd| H
    
    A --> L[Ingress Controller]
    L --> M[Load Balancer]
    M -->|HTTP/HTTPS| N[Utilisateurs]
    
    A --> O[Monitoring]
    O --> P[Prometheus]
    O --> Q[Grafana]
    
    style A fill:#f96,stroke:#333
    style B fill:#ff9,stroke:#333
    style C fill:#9f9,stroke:#333
    style L fill:#bbf,stroke:#333
```

### Configuration avec Ansible
```mermaid
graph TD
    A[Playbook Ansible] --> B[Inventory]
    B --> C[Serveurs Cibles]
    A --> D[Variables]
    A --> E[Rôles]
    
    C --> F[Serveur 1]
    C --> G[Serveur 2]
    C --> H[Serveur N]
    
    A -->|ansible-playbook| I[Exécution]
    I --> F
    I --> G
    I --> H
    
    F -->|Installe| J[Docker]
    F -->|Configure| K[Kubernetes]
    F -->|Déploie| L[Applications]
    
    style A fill:#9f9,stroke:#333
    style I fill:#ff9,stroke:#333
    style F fill:#f96,stroke:#333
```

---

## 🎯 Schéma par Exercice

### Exercice 1 : Déploiement avec Docker
```mermaid
graph LR
    A[Code Source] -->|Dockerfile| B[Image Docker]
    B -->|docker build| C[Docker Daemon]
    C -->|docker run| D[Conteneur]
    D -->|Expose Port 3000| E[Application]
    E -->|http://localhost:3000| F[Navigateur]
    
    style A fill:#9f9,stroke:#333
    style B fill:#ff9,stroke:#333
    style D fill:#f96,stroke:#333
```

### Exercice 2 : CI/CD avec GitHub Actions
```mermaid
graph TD
    A[Push sur GitHub] --> B[Workflow CI]
    B --> C[Checkout Code]
    C --> D[Setup Node.js]
    D --> E[Install Dependencies]
    E --> F[Run Tests]
    F --> G[Run Linter]
    G -->|Succès| H[Build Docker Image]
    H --> I[Push to Docker Hub]
    
    style A fill:#bbf,stroke:#333
    style B fill:#9f9,stroke:#333
    style H fill:#ff9,stroke:#333
```

### Exercice 3 : Configuration avec Ansible
```mermaid
graph TD
    A[Playbook Ansible] --> B[Inventory]
    B --> C[Serveurs]
    A --> D[Variables]
    A --> E[Tasks]
    
    E -->|ansible-playbook| F[Exécution]
    F --> C
    C --> G[Installe Nginx]
    C --> H[Configure Nginx]
    C --> I[Démarre Nginx]
    
    style A fill:#9f9,stroke:#333
    style F fill:#ff9,stroke:#333
    style C fill:#f96,stroke:#333
```

### Exercice 4 : Infrastructure as Code avec Terraform
```mermaid
graph TD
    A[Fichiers .tf] --> B[terraform init]
    B --> C[terraform plan]
    C --> D[terraform apply]
    D --> E[AWS]
    E --> F[Crée VPC]
    E --> G[Crée EC2 Instance]
    E --> H[Crée Security Group]
    
    style A fill:#99f,stroke:#333
    style D fill:#ff9,stroke:#333
    style E fill:#f96,stroke:#333
```

### Exercice 5 : Orchestration avec Kubernetes
```mermaid
graph TD
    A[Manifests K8s] --> B[kubectl apply]
    B --> C[Cluster Kubernetes]
    C --> D[Deployment]
    D --> E[Pods]
    E --> F[Conteneurs]
    F --> G[Application]
    
    C --> H[Service]
    H --> I[Load Balancer]
    I -->|HTTP| J[Utilisateur]
    
    style A fill:#bbf,stroke:#333
    style B fill:#ff9,stroke:#333
    style E fill:#f96,stroke:#333
```

---

## 📌 Légende

| Couleur | Signification | Exemple |
|---------|---------------|---------|
| 🟢 Vert (`#9f9`) | **Code Source / Fichiers de Configuration** | Dockerfile, playbook.yml |
| 🟡 Jaune (`#ff9`) | **Outils / Processus** | Docker, Ansible, Terraform |
| 🔴 Rouge (`#f96`) | **Environnements / Conteneurs** | Conteneur Docker, Pod Kubernetes |
| 🔵 Bleu (`#bbf`) | **Dépôts / Stockage** | GitHub, Docker Hub |
| 🟣 Violet (`#99f`) | **Infrastructure Cloud** | AWS, Azure, GCP |
| 🟠 Orange (`#f99`) | **Erreurs / Notifications** | Notification Slack |

---

## 💡 Conseils pour Comprendre les Schémas

1. **Lisez de haut en bas** : Les schémas sont conçus pour être lus dans l'ordre du flux de travail.
2. **Suivez les flèches** : Elles indiquent le sens des interactions.
3. **Consultez les légendes** : Chaque couleur a une signification.
4. **Testez en pratique** : Reproduisez les schémas dans votre environnement pour mieux les comprendre.

---

## 📚 Pour Aller Plus Loin

- **[Mermaid Live Editor](https://mermaid.live/)** : Pour créer et tester vos propres schémas.
- **[Diagrams as Code](https://diagrams.mingrammer.com/)** : Alternative à Mermaid pour des schémas plus complexes.
- **[Draw.io](https://app.diagrams.net/)** : Outil graphique pour créer des schémas.

---

**Prochaine étape** : [Découvrir les outils DevOps en détail](../guides/devops-tools.md) 🚀
