# 🏗️ Architecture du Projet - Infrastructure-as-Code

**P5 OpenClassrooms - Déploiement Terraform, Ansible, ELK**

---

## 📐 **Schéma Global d'Architecture**

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS CLOUD - Region: eu-west-3 (Paris)                            │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                VPC (Virtual Private Cloud)                                    │  │
│  │  CIDR: 10.0.0.0/16                                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │  │
│  │  │  Public Subnet   │  │  Public Subnet   │  │  Private Subnet  │  │  Private Subnet  │    │  │
│  │  │  10.0.1.0/24    │  │  10.0.2.0/24    │  │  10.0.3.0/24    │  │  10.0.4.0/24    │    │  │
│  │  │  (AZ: a)        │  │  (AZ: b)        │  │  (AZ: a)        │  │  (AZ: b)        │    │  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘    │  │
│  │           │                  │                  │                  │             │  │
│  │  ┌────────▼────────┐  ┌────────▼────────┐  ┌────────▼────────┐  ┌────────▼────────┐  │  │
│  │  │   HAProxy LB    │  │   NGINX-1       │  │   NGINX-2       │  │   OpenSearch    │  │  │
│  │  │   (t2.micro)    │  │   (t2.micro)    │  │   (t2.micro)    │  │   (t3.medium)   │  │  │
│  │  │   Port: 80/443  │  │   Port: 80      │  │   Port: 80      │  │   Port: 9200    │  │  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │  │
│  │           │                  │                  │                  │             │  │
│  │           └──────────────────┬──────────────────┘                  │             │  │
│  │                              │                                      │             │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐             │  │
│  │  │                    Internet Gateway (IGW)                          │             │  │
│  │  │  ┌────────────────────────────────────────────────────────────┐  │             │  │
│  │  │  │  Route Table: 0.0.0.0/0 → IGW (Public Subnets)                │  │             │  │
│  │  │  └────────────────────────────────────────────────────────────┘  │             │  │
│  │  └──────────────────────────────────────────────────────────────────┘             │  │
│  │                                                                          │             │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐             │  │
│  │  │                    NAT Gateway (NGW)                               │             │  │
│  │  │  ┌────────────────────────────────────────────────────────────┐  │             │  │
│  │  │  │  Route Table: 0.0.0.0/0 → NGW (Private Subnets)                │  │             │  │
│  │  │  └────────────────────────────────────────────────────────────┘  │             │  │
│  │  └──────────────────────────────────────────────────────────────────┘             │  │
│  │                                                                                      │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                SERVICES EXTERNES                                        │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │  │
│  │  │   Utilisateur   │  │   GitHub        │  │   DNS Public    │  │   Monitoring    │    │  │
│  │  │   (Navigateur)  │  │   (Code)        │  │   (Route 53)    │  │   (CloudWatch)  │    │  │
│  │  └────────┬────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘    │  │
│  │            │                                                                              │  │
│  │            └──────────────────────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 **Légende Détaillée**

### **🌐 Composants Réseau**

| Composant | Description | CIDR/Type | Coût Estimé (par mois) |
|-----------|-------------|-----------|------------------------|
| **VPC** | Virtual Private Cloud - Isoler les ressources | 10.0.0.0/16 | Gratuit |
| **Public Subnet A** | Sous-réseau public pour HAProxy | 10.0.1.0/24 | Gratuit |
| **Public Subnet B** | Sous-réseau public pour NGINX-1 | 10.0.2.0/24 | Gratuit |
| **Private Subnet A** | Sous-réseau privé pour NGINX-2 | 10.0.3.0/24 | Gratuit |
| **Private Subnet B** | Sous-réseau privé pour OpenSearch | 10.0.4.0/24 | Gratuit |
| **Internet Gateway** | Permet l'accès internet aux subnets publics | - | Gratuit |
| **NAT Gateway** | Permet l'accès internet aux subnets privés | - | ~$36/mois |
| **Route Tables** | Tables de routage pour diriger le trafic | - | Gratuit |

### **🖥️ Composants Serveurs**

| Serveur | Type | Rôle | Ports Ouverts | Coût Estimé (par mois) |
|---------|------|------|---------------|------------------------|
| **HAProxy** | t2.micro | Load Balancer | 80 (HTTP), 443 (HTTPS) | ~$10/mois |
| **NGINX-1** | t2.micro | Serveur Web | 80 (HTTP), 22 (SSH) | ~$10/mois |
| **NGINX-2** | t2.micro | Serveur Web | 80 (HTTP), 22 (SSH) | ~$10/mois |
| **OpenSearch** | t3.medium | Moteur de recherche/logs | 9200 (API), 9600 (Dashboards) | ~$45/mois |

### **🔧 Composants Logiciels**

| Logiciel | Version | Rôle | Port | Installation |
|----------|---------|------|------|-------------|
| **HAProxy** | 2.6+ | Load Balancer | 80, 443 | Package OS |
| **NGINX** | 1.23+ | Serveur Web | 80 | Package OS |
| **OpenSearch** | 2.x | Moteur de recherche | 9200 | Docker/VM |
| **Logstash** | 8.x | Collecte de logs | 5044 | Package/VM |
| **Filebeat** | 8.x | Agent de collecte | - | Package |
| **Kibana** | 2.x | Visualisation | 5601 | Intégré OpenSearch |

---

## 🔄 **Flux de Travail (Workflow)**

### **1️⃣ Exercice 1 : Terraform + Ansible + NGINX**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Terraform │────▶│   AWS EC2   │────▶│   Ansible   │────▶│   NGINX     │
│  (IaC)      │     │  (2x t2.micro)│    │  (Config)   │     │  (Web Server)│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

**Étapes :**
1. Terraform crée **2 instances EC2** (NGINX-1 et NGINX-2)
2. Ansible **configure NGINX** sur chaque instance
3. NGINX **sert une page web statique**

---

### **2️⃣ Exercice 2 : OpenSearch (Stack ELK)**

```
┌─────────────┐     ┌─────────────────────────────────────────────────┐
│   NGINX     │────▶│                   OpenSearch Cluster               │
│  (Logs)     │     │  ┌─────────────┐    ┌─────────────────────────┐  │
└─────────────┘     │  │ OpenSearch  │    │         Logstash          │  │
                    │  │  (Master)   │    │   (Collecte & Traitement) │  │
                    │  └─────────────┘    └─────────────────────────┘  │
                    │         │                                         │
                    │  ┌─────────────┐    ┌─────────────────────────┐  │
                    │  │ OpenSearch  │◀───│         Filebeat          │  │
                    │  │  (Node)     │    │   (Agent sur NGINX)       │  │
                    │  └─────────────┘    └─────────────────────────┘  │
                    │                                                 │
                    │  ┌─────────────────────────────────────────────┐  │
                    │  │            Kibana (Visualisation)            │  │
                    │  └─────────────────────────────────────────────┘  │
                    └─────────────────────────────────────────────────┘
```

**Étapes :**
1. Terraform crée **1 instance OpenSearch** (t3.medium)
2. Ansible **configure OpenSearch + Logstash + Kibana**
3. Filebeat (sur NGINX) **envoie les logs** à Logstash
4. Logstash **traite et indexe** dans OpenSearch
5. Kibana **affiche les logs** via une interface web

---

### **3️⃣ Exercice 3 : HAProxy (Load Balancer)**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐
│   Client    │────▶│  HAProxy    │────▶│       NGINX Servers         │
│ (Browser)   │     │ (Load       │     │   ┌─────────────┐              │
└─────────────┘     │  Balancer)   │────▶│   │  NGINX-1    │              │
                    └─────────────┘     │   └─────────────┘              │
                                           └─────────────┬─────────────┘
                                                         │
                                                         ▼
                                                   ┌─────────────┐
                                                   │  NGINX-2    │
                                                   └─────────────┘
```

**Étapes :**
1. Terraform crée **1 instance HAProxy** (t2.micro)
2. Ansible **configure HAProxy** comme Load Balancer
3. HAProxy **répartit la charge** entre NGINX-1 et NGINX-2
4. **Round Robin** par défaut (autres algorithmes possibles)

---

## 💰 **Coût Estimé Total**

### **📊 Détail des Coûts (Region: eu-west-3)**

| Ressource | Type | Quantité | Coût Unitaire | Coût Total (par mois) |
|----------|------|----------|---------------|------------------------|
| **EC2 - HAProxy** | t2.micro | 1 | ~$0.0116/heure | ~$8.40 |
| **EC2 - NGINX-1** | t2.micro | 1 | ~$0.0116/heure | ~$8.40 |
| **EC2 - NGINX-2** | t2.micro | 1 | ~$0.0116/heure | ~$8.40 |
| **EC2 - OpenSearch** | t3.medium | 1 | ~$0.0416/heure | ~$30.24 |
| **NAT Gateway** | - | 1 | ~$0.045/heure | ~$32.40 |
| **EBS - HAProxy** | 8 Go GP2 | 1 | ~$0.80/mois | ~$0.80 |
| **EBS - NGINX-1** | 8 Go GP2 | 1 | ~$0.80/mois | ~$0.80 |
| **EBS - NGINX-2** | 8 Go GP2 | 1 | ~$0.80/mois | ~$0.80 |
| **EBS - OpenSearch** | 20 Go GP2 | 1 | ~$2.00/mois | ~$2.00 |
| **Elastic IP** | - | 1 | Gratuit (si attachée) | ~$0.00 |
| **Trafic Sortant** | - | - | ~$0.09/Go | ~$5.00 (estimation) |
| **Total** | | | | **~$94.84/mois** |

### **⚠️ Optimisation des Coûts**

1. **Utiliser le Free Tier** :
   - 750 heures/mois de t2.micro **gratuites** pendant 12 mois
   - **Économie possible** : ~$25.20/mois (3 instances t2.micro)

2. **Réduire la durée d'utilisation** :
   - **Ne pas laisser tourner 24/7** pendant le développement
   - **Économie possible** : ~50% si utilisé 12h/jour

3. **Choisir des instances plus petites** :
   - OpenSearch peut tourner sur **t2.micro** pour les tests
   - **Économie possible** : ~$20/mois

4. **Supprimer les ressources inutilisées** :
   - **NAT Gateway** peut être supprimé si pas besoin d'accès internet depuis les subnets privés
   - **Économie possible** : ~$32.40/mois

### **💡 Coût Réel Estimé (avec optimisations)**

| Scénario | Durée | Coût Estimé |
|----------|-------|--------------|
| **Développement** (Free Tier + 12h/jour) | 1 mois | **~$20-30** |
| **Production** (24/7, sans Free Tier) | 1 mois | **~$95** |
| **Examen** (2-3 jours intensifs) | 1 semaine | **~$25-40** |

---

## 🔗 **Topologie Réseau Complète**

### **🌐 VPC Configuration**

```yaml
VPC:
  CIDR: 10.0.0.0/16
  Enable DNS Support: true
  Enable DNS Hostnames: true

Subnets:
  Public Subnet A:
    CIDR: 10.0.1.0/24
    AZ: eu-west-3a
    Map Public IP: true
    
  Public Subnet B:
    CIDR: 10.0.2.0/24
    AZ: eu-west-3b
    Map Public IP: true
    
  Private Subnet A:
    CIDR: 10.0.3.0/24
    AZ: eu-west-3a
    Map Public IP: false
    
  Private Subnet B:
    CIDR: 10.0.4.0/24
    AZ: eu-west-3b
    Map Public IP: false

Route Tables:
  Public RT:
    Destination: 0.0.0.0/0
    Target: Internet Gateway
    
  Private RT:
    Destination: 0.0.0.0/0
    Target: NAT Gateway

Security Groups:
  HAProxy-SG:
    Inbound:
      - Port 80 (HTTP) from 0.0.0.0/0
      - Port 443 (HTTPS) from 0.0.0.0/0
      - Port 22 (SSH) from [Votre IP]
    Outbound: All traffic
    
  NGINX-SG:
    Inbound:
      - Port 80 (HTTP) from HAProxy-SG
      - Port 22 (SSH) from [Votre IP]
    Outbound: All traffic
    
  OpenSearch-SG:
    Inbound:
      - Port 9200 from NGINX-SG (Filebeat)
      - Port 9600 from [Votre IP] (Kibana)
      - Port 22 (SSH) from [Votre IP]
    Outbound: All traffic
```

---

## 📊 **Schéma de Déploiement**

### **🎯 Exercice 1 : Déploiement NGINX**

```
Phase 1: Infrastructure (Terraform)
├── Créer VPC + Subnets
├── Créer Security Groups
├── Lancer 2 instances EC2 (NGINX-1, NGINX-2)
└── Configurer les clés SSH

Phase 2: Configuration (Ansible)
├── Installer NGINX sur les 2 instances
├── Déployer une page web statique
├── Configurer le service NGINX
└── Vérifier l'accès HTTP

Phase 3: Vérification
├── Tester l'accès à NGINX-1: http://<IP-NGINX-1>
├── Tester l'accès à NGINX-2: http://<IP-NGINX-2>
└── Vérifier les logs NGINX
```

### **🎯 Exercice 2 : Déploiement OpenSearch**

```
Phase 1: Infrastructure (Terraform)
├── Créer une instance EC2 (OpenSearch)
├── Configurer le Security Group
└── Attacher un volume EBS (20 Go)

Phase 2: Configuration (Ansible)
├── Installer OpenSearch
├── Installer Logstash
├── Installer Kibana (OpenSearch Dashboards)
├── Configurer Logstash pour recevoir les logs
└── Configurer Filebeat sur les instances NGINX

Phase 3: Intégration
├── Filebeat (NGINX) → Logstash (Port 5044)
├── Logstash → OpenSearch (Port 9200)
└── Kibana → OpenSearch (Port 9600)

Phase 4: Vérification
├── Accéder à Kibana: http://<IP-OpenSearch>:5601
├── Vérifier l'indexation des logs NGINX
└── Créer des visualisations dans Kibana
```

### **🎯 Exercice 3 : Déploiement HAProxy**

```
Phase 1: Infrastructure (Terraform)
├── Créer une instance EC2 (HAProxy)
├── Configurer le Security Group
└── Associer une Elastic IP

Phase 2: Configuration (Ansible)
├── Installer HAProxy
├── Configurer le frontend (Port 80)
├── Configurer le backend (NGINX-1, NGINX-2)
└── Configurer l'algorithme de Load Balancing

Phase 3: Vérification
├── Tester l'accès via HAProxy: http://<IP-HAProxy>
├── Vérifier la répartition de charge
├── Tester la tolérance aux pannes (arrêter NGINX-1)
└── Vérifier les statistiques HAProxy
```

---

## 🔐 **Sécurité et Bonnes Pratiques**

### **🛡️ Règles de Sécurité**

1. **Accès SSH restreint** :
   - Autoriser uniquement **votre IP publique** sur le port 22
   - Utiliser des **clés SSH** plutôt que des mots de passe

2. **Ports ouverts minimaux** :
   - **HAProxy** : 80 (HTTP), 443 (HTTPS)
   - **NGINX** : 80 (HTTP) - uniquement depuis HAProxy
   - **OpenSearch** : 9200 (API), 9600 (Kibana) - uniquement depuis NGINX et votre IP

3. **IAM Roles** :
   - Créer un **rôle IAM** pour les instances EC2
   - Permissions minimales requises :
     - `ec2:Describe*` (pour Ansible)
     - `s3:GetObject` (si utilisation de S3)
     - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` (pour CloudWatch)

4. **Chiffrement** :
   - **EBS** : Chiffrement au repos activé
   - **HTTPS** : Certificat SSL/TLS pour HAProxy (optionnel pour ce projet)

### **📋 Checklist Sécurité**

- [ ] VPC avec DNS Support activé
- [ ] Security Groups configurés avec le principe du **moindre privilège**
- [ ] Pas de clés AWS dans le code (utiliser `terraform.tfvars` + `.gitignore`)
- [ ] Instances EC2 avec **IMDSv2** (Instance Metadata Service v2)
- [ ] **CloudTrail** activé pour l'audit (optionnel mais recommandé)
- [ ] **CloudWatch** pour la surveillance (optionnel)

---

## 📈 **Monitoring et Observabilité**

### **🔍 Outils de Monitoring**

| Outil | Utilisation | Configuration |
|-------|-------------|---------------|
| **CloudWatch** | Métriques AWS (CPU, RAM, etc.) | Intégré à AWS |
| **OpenSearch Dashboards** | Visualisation des logs | Port 5601 |
| **HAProxy Stats** | Statistiques du Load Balancer | Port 8404 |
| **NGINX Logs** | Logs d'accès et d'erreur | `/var/log/nginx/` |

### **📊 Métriques à Surveiller**

1. **HAProxy** :
   - Nombre de requêtes par seconde
   - Temps de réponse
   - Répartition entre les backends
   - Erreurs 5xx

2. **NGINX** :
   - Nombre de requêtes
   - Codes HTTP (200, 404, 500, etc.)
   - Temps de réponse
   - Bande passante

3. **OpenSearch** :
   - Nombre de documents indexés
   - Taille des index
   - Temps de recherche
   - Erreurs d'indexation

---

## 🎯 **Résumé des Adresses et Ports**

| Service | Adresse | Port | Protocole | Accès |
|---------|---------|------|-----------|-------|
| HAProxy | `<Elastic-IP>` | 80 | HTTP | Public |
| HAProxy | `<Elastic-IP>` | 443 | HTTPS | Public (optionnel) |
| HAProxy Stats | `<Elastic-IP>` | 8404 | HTTP | Restreint |
| NGINX-1 | `<Private-IP>` | 80 | HTTP | Privé (via HAProxy) |
| NGINX-2 | `<Private-IP>` | 80 | HTTP | Privé (via HAProxy) |
| OpenSearch API | `<Private-IP>` | 9200 | HTTP | Privé |
| OpenSearch Dashboards | `<Elastic-IP>` | 5601 | HTTP | Public (restreint) |
| Logstash | `<Private-IP>` | 5044 | TCP | Privé (Filebeat) |
| SSH (Tous) | `<IP>` | 22 | SSH | Restreint à votre IP |

---

## 📌 **Prochaines Étapes**

1. **Lire** [Exercice 1 - Terraform + Ansible + NGINX](./exercices/exercice-1-terraform-ansible-nginx.md)
2. **Déployer** l'infrastructure de base avec Terraform
3. **Configurer** NGINX avec Ansible
4. **Passer** à l'Exercice 2 pour ajouter OpenSearch
5. **Finaliser** avec l'Exercice 3 pour ajouter HAProxy

---

**✅ Architecture validée et prête pour le déploiement !**

> *"Une bonne architecture est comme une bonne blague : tout le monde la comprend."* — **Anonyme**
