# 🔥 Exercice 2 : Déploiement OpenSearch (Stack ELK) - Partie 1

**Centralisation et Analyse des Logs avec OpenSearch, Logstash et Kibana**

---

## 🎯 **Objectifs de l'Exercice**

À la fin de cet exercice, vous serez capable de :

✅ **Comprendre** l'architecture d'une **stack ELK/OpenSearch**
✅ **Déployer** un cluster **OpenSearch** avec Terraform
✅ **Configurer** **Logstash** pour la collecte et le traitement des logs
✅ **Installer** **Filebeat** sur vos serveurs NGINX pour envoyer les logs
✅ **Visualiser** les logs avec **Kibana (OpenSearch Dashboards)**
✅ **Créer** des index, des visualisations et des tableaux de bord
✅ **Dépanner** les problèmes courants de la stack ELK

---

## 📚 **Concepts Clés à Maîtriser**

### **🔍 Pourquoi une Stack ELK/OpenSearch ?**

Dans un environnement de production, vous avez besoin de :
- **Centraliser** les logs de toutes vos applications et serveurs
- **Analyser** les logs pour détecter des problèmes ou des tendances
- **Visualiser** les données de manière intuitive
- **Alerter** en cas d'anomalies

**Exemple concret** :
> Vous avez 10 serveurs NGINX qui génèrent chacun des logs. Sans centralisation, vous devriez :
> - Vous connecter à chaque serveur pour voir les logs
> - Chercher manuellement des erreurs dans chaque fichier
> - Ne pas avoir de vue d'ensemble
>
> Avec OpenSearch/ELK, vous pouvez :
> - Voir **tous les logs au même endroit**
> - **Rechercher** des erreurs spécifiques dans tous les logs
> - **Créer des graphiques** pour visualiser le trafic, les erreurs, etc.
> - **Configurer des alertes** automatiques

---

### **🌐 Stack ELK vs OpenSearch**

#### **ELK Stack (Elasticsearch, Logstash, Kibana)**
- **Elasticsearch** : Moteur de recherche et d'analyse distribué
- **Logstash** : Outil de collecte, transformation et envoi de données
- **Kibana** : Interface de visualisation

**Histoire** :
- Créé par **Elastic** en 2010
- Licence **Apache 2.0** (open source) jusqu'en 2021
- En 2021, Elastic change la licence de Elasticsearch et Kibana en **SSPL**

#### **OpenSearch**
- **Fork** d'Elasticsearch 7.10.2 et Kibana 7.10.2
- Créé par **Amazon** en 2021 en réponse au changement de licence
- **100% open source** (licence Apache 2.0)
- Compatible avec les outils existants (Logstash, Beats, etc.)

**Comparaison** :

| Fonctionnalité | Elasticsearch | OpenSearch |
|---------------|---------------|------------|
| Licence | SSPL | Apache 2.0 |
| Open Source | ❌ (depuis 2021) | ✅ |
| Compatible avec Kibana | ✅ | ✅ (OpenSearch Dashboards) |
| Compatible avec Logstash | ✅ | ✅ |
| Compatible avec Beats | ✅ | ✅ |
| Fonctionnalités avancées | ✅ (payantes) | ✅ (gratuites) |
| Support AWS | ✅ | ✅ (meilleur) |

**Pour ce projet** : Nous utiliserons **OpenSearch** car :
- 100% open source
- Compatible avec tous les outils ELK
- Support natif par AWS

---

### **🏗️ Architecture OpenSearch**

#### **1. OpenSearch (Moteur de Recherche)**

**C'est quoi ?**
> OpenSearch est un **moteur de recherche et d'analyse distribué** basé sur Apache Lucene. Il permet de :
> - **Indexer** des données (logs, documents, etc.)
> - **Rechercher** dans ces données très rapidement
> - **Analyser** les données avec des agrégations
> - **Scaler** horizontalement (ajouter des nœuds)

**Concepts clés** :

| Concept | Description | Analogie |
|---------|-------------|----------|
| **Index** | Ensemble de documents similaires | Table dans une base de données |
| **Document** | Unité de base de stockage (JSON) | Ligne dans une table |
| **Shard** | Partition d'un index | Partition d'une table |
| **Node** | Serveur OpenSearch | Serveur dans un cluster |
| **Cluster** | Ensemble de nodes OpenSearch | Cluster de serveurs |
| **Replica** | Copie d'un shard pour la redondance | Réplica d'une partition |

**Architecture d'un Cluster OpenSearch** :
```
┌─────────────────────────────────────────────────────────────────────────┐
│                        OPENSEARCH CLUSTER                                  │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                  │
│  │  Master Node │    │  Data Node  │    │  Data Node  │                  │
│  │  (Gère le    │    │  (Stocke    │    │  (Stocke    │                  │
│  │   cluster)   │    │   les données)│   │   les données)│                  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                  │
│         │                  │                  │                         │
│         └──────────────────┬──────────────────┘                         │
│                            │                                          │
│                    ┌───────▼───────┐                                   │
│                    │    Index      │                                   │
│                    │  (logs-2024)  │                                   │
│                    │  ┌─────────┐  │                                   │
│                    │  │ Shard 1 │  │                                   │
│                    │  └─────────┘  │                                   │
│                    │  ┌─────────┐  │                                   │
│                    │  │ Shard 2 │  │                                   │
│                    │  └─────────┘  │                                   │
│                    └───────────────┘                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

**Types de Nœuds** :

| Type | Rôle | Configuration | Nombre Recommandé |
|------|------|---------------|-------------------|
| **Master** | Gère le cluster, les métadonnées | CPU modéré, RAM modérée | 3 (pour la HA) |
| **Data** | Stocke les données, exécute les requêtes | CPU élevé, RAM élevée, Disque rapide | 2+ |
| **Ingest** | Traite les données avant indexation | CPU élevé | Optionnel |
| **Coordinating** | Gère les requêtes des clients | CPU modéré | Optionnel |

**Pour ce projet** :
- **1 nœud** (Master + Data) sur une instance `t3.medium`
- Suffisant pour un environnement de test/démonstration

---

#### **2. Logstash**

**C'est quoi ?**
> Logstash est un **pipeline de traitement de données** qui permet de :
> - **Collecter** des données de différentes sources
> - **Transformer** les données (parser, filtrer, enrichir)
> - **Envoyer** les données vers une destination (OpenSearch, etc.)

**Architecture Logstash** :
```
┌─────────────────────────────────────────────────────────────┐
│                        LOGSTASH PIPELINE                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   Input     │───▶│   Filter    │───▶│   Output    │      │
│  │ (Collecte)  │    │ (Traitement)│    │ (Envoi)     │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

**Exemple de Pipeline** :
```
Input : Filebeat (logs NGINX) → Filter : Parse JSON, Ajouter champs → Output : OpenSearch
```

**Plugins populaires** :
- **Input** : `file`, `beats`, `syslog`, `kafka`, `http`
- **Filter** : `grok`, `json`, `date`, `mutate`, `geoip`
- **Output** : `elasticsearch`, `opensearch`, `file`, `kafka`

---

#### **3. Kibana / OpenSearch Dashboards**

**C'est quoi ?**
> Kibana (ou OpenSearch Dashboards) est une **interface web** pour :
> - **Visualiser** les données dans OpenSearch
> - **Créer des tableaux de bord** (dashboards)
> - **Explorer les données** avec Discover
> - **Analyser les logs** avec Logs UI
> - **Créer des alertes**

**Fonctionnalités clés** :
- **Discover** : Explorer les données de manière interactive
- **Visualize** : Créer des graphiques (barres, camembert, lignes, etc.)
- **Dashboard** : Combiner plusieurs visualisations
- **Logs** : Interface dédiée pour l'analyse des logs
- **Dev Tools** : Console pour exécuter des requêtes OpenSearch

---

#### **4. Beats (Filebeat)**

**C'est quoi ?**
> Les **Beats** sont des **agents légers** pour collecter des données et les envoyer à Logstash ou OpenSearch.

| Beat | Utilisation |
|------|-------------|
| **Filebeat** | Collecte des **fichiers de logs** |
| **Metricbeat** | Collecte des **métriques système** |
| **Packetbeat** | Collecte des **paquets réseau** |
| **Winlogbeat** | Collecte des **logs Windows** |
| **Auditbeat** | Collecte des **logs d'audit** |

**Pour ce projet** : Nous utiliserons **Filebeat** pour :
- Collecter les logs **NGINX** (`/var/log/nginx/access.log` et `/var/log/nginx/error.log`)
- Envoyer les logs à **Logstash** pour traitement

**Architecture Filebeat** :
```
┌─────────────────────────────────────────────────────────────┐
│                        FILEBEAT ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   NGINX     │    │   Filebeat  │    │  Logstash   │      │
│  │  (Server)   │───▶│  (Agent)    │───▶│  (Pipeline) │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

#### **5. NoSQL et OpenSearch**

**NoSQL vs SQL** :

| Caractéristique | SQL (MySQL, PostgreSQL) | NoSQL (OpenSearch, MongoDB) |
|----------------|--------------------------|-----------------------------|
| **Structure** | Tables, lignes, colonnes | Documents JSON |
| **Schéma** | Fixe (définition requise) | Dynamique (flexible) |
| **Requêtes** | SQL (`SELECT * FROM table`) | DSL (Domain Specific Language) |
| **Scalabilité** | Verticale | Horizontale |
| **Transactions** | ACID | BASE |
| **Utilisation** | Données relationnelles | Logs, recherche, analytics |

**Exemple de Document OpenSearch** :
```json
{
  "_index": "logs-nginx-2024.01.01",
  "_id": "abc123",
  "_source": {
    "@timestamp": "2024-01-01T12:00:00Z",
    "host": "52.47.123.45",
    "source": "/var/log/nginx/access.log",
    "request": "GET / HTTP/1.1",
    "status": 200,
    "response_time": 45,
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
  }
}
```

---

## 📁 **Structure des Fichiers**

Pour l'Exercice 2, voici la structure recommandée :

```bash
p5_Openclassrooms/
├── terraform/
│   └── exercice-2/
│       ├── main.tf          # Configuration Terraform pour OpenSearch
│       ├── variables.tf     # Variables
│       ├── outputs.tf       # Outputs
│       └── terraform.tfvars # Valeurs des variables
│
└── ansible/
    ├── inventories/
    │   └── exercice-2.ini    # Inventaire (OpenSearch + NGINX)
    ├── playbooks/
    │   ├── deploy-opensearch.yml  # Playbook OpenSearch + Logstash
    │   └── deploy-filebeat.yml    # Playbook Filebeat
    └── roles/
        ├── opensearch/       # Rôle OpenSearch
        │   ├── tasks/
        │   │   └── main.yml
        │   ├── handlers/
        │   │   └── main.yml
        │   ├── templates/
        │   │   ├── opensearch.yml.j2
        │   │   └── jvm.options.j2
        │   └── vars/
        │       └── main.yml
        │
        ├── logstash/         # Rôle Logstash
        │   ├── tasks/
        │   │   └── main.yml
        │   ├── templates/
        │   │   └── logstash.conf.j2
        │   └── vars/
        │       └── main.yml
        │
        └── filebeat/         # Rôle Filebeat
            ├── tasks/
            │   └── main.yml
            ├── templates/
            │   └── filebeat.yml.j2
            └── vars/
                └── main.yml
```

---

## 🚀 **Étapes d'Exécution (Résumé)**

1. **Déployer l'infrastructure avec Terraform** (`terraform/exercice-2/`)
2. **Configurer l'inventaire Ansible** (`ansible/inventories/exercice-2.ini`)
3. **Déployer OpenSearch et Logstash** (`ansible/playbooks/deploy-opensearch.yml`)
4. **Déployer Filebeat sur les serveurs NGINX** (`ansible/playbooks/deploy-filebeat.yml`)
5. **Vérifier le flux de données** (logs → Filebeat → Logstash → OpenSearch)
6. **Configurer OpenSearch Dashboards** (créer index pattern, visualisations, etc.)

---

**La suite dans [Partie 2](exercice-2-opensearch-part2.md) avec les fichiers Terraform et Ansible complets !**

---

## 📌 **Résumé des Concepts**

✅ **OpenSearch** : Moteur de recherche NoSQL pour indexer et rechercher des logs
✅ **Logstash** : Pipeline pour collecter, transformer et envoyer des données
✅ **Filebeat** : Agent léger pour collecter des logs de fichiers
✅ **Kibana** : Interface web pour visualiser et analyser les données
✅ **Stack ELK/OpenSearch** : Architecture complète pour la centralisation des logs
