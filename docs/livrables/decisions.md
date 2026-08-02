# Décisions techniques - Projet P5 OpenClassrooms

---

## 🏗️ Architecture

| **Décision** | **Choix** | **Justification** |
|--------------|-----------|-------------------|
| **Région AWS** | `us-east-1` | Région **obligatoire** pour le projet (compatible avec les AMIs et ressources fournies). |
| **Type d'instances (NGINX)** | `t2.micro` | Suffisant pour le projet (**gratuit** dans le free tier AWS). |
| **Type d'instances (OpenSearch)** | `t3.medium.search` | **Minimum requis** pour OpenSearch (2 vCPU, 4 Go RAM). |
| **Type d'instances (HAProxy)** | `t2.micro` | Suffisant pour un load balancer de test. |
| **Stockage (OpenSearch)** | `gp3` (10 Go) | **Bon marché et performant** (recommandé par AWS). |
| **Algorithme HAProxy** | `roundrobin` | **Équilibrage simple** (1 requête par serveur à tour de rôle). |

---

## 🔧 Outils

| **Outil** | **Version** | **Justification** |
|-----------|-------------|-------------------|
| **Terraform** | v1.15.8 | Version **stable et compatible** avec le projet. |
| **Ansible** | 2.15.x | Version **moderne** avec support complet des modules. |
| **AWS CLI** | 2.x.x | Version **récente** avec toutes les commandes nécessaires. |
| **Ubuntu** | 26.04 | Version **LTS** (Long Term Support) = stable et maintenue. |

---

## 📊 Méthodologie

- **Infrastructure as Code (IaC)** : Utilisation de **Terraform** pour décrire l'infrastructure dans du code.
- **Configuration Management** : Utilisation de **Ansible** pour configurer automatiquement les serveurs.
- **Load Balancing** : Utilisation de **HAProxy** pour répartir la charge entre plusieurs serveurs.

---

## 📝 Décisions Personnelles

| **Décision** | **Choix** | **Justification** | **Alternatives envisagées** |
|--------------|-----------|-------------------|---------------------------|
| [Votre décision] | [Votre choix] | [Pourquoi ?] | [Autres options] |
| Exemple : Utilisation de t2.micro | t2.micro | Gratuit avec Free Tier | t3.micro (moins cher mais moins performant) |

---

**Conseil** : Documentez **toutes vos décisions techniques** ici pour justifier vos choix lors de l'évaluation.
