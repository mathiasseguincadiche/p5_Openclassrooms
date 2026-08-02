# 📸 Captures Exercice 2 - OpenSearch (ELK)

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce fichier doit **lister et décrire toutes les captures d'écran** pour l'Exercice 2. Comme les captures d'écran sont des fichiers binaires, ce document sert à :

✅ **Lister** les captures d'écran attendues
✅ **Décrire** ce que chaque capture doit montrer
✅ **Organiser** les captures par étape
✅ **Faciliter la vérification** par l'évaluateur

**Où stocker les captures** : Dans le dossier `captures/exercice-2/`

---

## 📁 **Structure des Captures**

```
captures/
└── exercice-2/
    ├── terraform/
    │   ├── terraform-init.png
    │   ├── terraform-plan.png
    │   ├── terraform-apply.png
    │   └── terraform-output.png
    │
    ├── opensearch/
    │   ├── opensearch-installing.png
    │   ├── opensearch-service-status.png
    │   ├── opensearch-api-test.png
    │   ├── opensearch-dashboard-login.png
    │   └── opensearch-dashboard-home.png
    │
    ├── logstash/
    │   ├── logstash-installing.png
    │   ├── logstash-service-status.png
    │   └── logstash-logs.png
    │
    ├── filebeat/
    │   ├── filebeat-installing.png
    │   ├── filebeat-service-status.png
    │   └── filebeat-logs.png
    │
    ├── data-flow/
    │   ├── opensearch-indices.png
    │   ├── opensearch-documents-count.png
    │   └── kibana-discover.png
    │
    └── visualizations/
        ├── kibana-index-pattern.png
        ├── kibana-visualization-1.png
        └── kibana-dashboard.png
```

---

## 📋 **Captures pour Terraform**

### **1. Initialisation de Terraform**

**Fichier** : `captures/exercice-2/terraform/terraform-init.png`

**Description** : Capture de la commande `terraform init` dans le dossier `terraform/exercice-2/`.

**Ce que la capture doit montrer** :
- Message "Terraform has been successfully initialized!"
- Version du provider AWS téléchargée

**Commande associée** :
```bash
cd terraform/exercice-2
terraform init
```

---

### **2. Planification avec `terraform plan`**

**Fichier** : `captures/exercice-2/terraform/terraform-plan.png`

**Description** : Capture de la commande `terraform plan` montrant les ressources à créer.

**Ce que la capture doit montrer** :
- Liste des ressources à créer (Security Group, EC2 Instance, Elastic IP, etc.)
- Message "Plan: X to add, 0 to change, 0 to destroy."

**Commande associée** :
```bash
terraform plan
```

---

### **3. Application avec `terraform apply`**

**Fichier** : `captures/exercice-2/terraform/terraform-apply.png`

**Description** : Capture de la commande `terraform apply` montrant la création des ressources.

**Ce que la capture doit montrer** :
- Création du Security Group
- Création de l'instance EC2 pour OpenSearch
- Création de l'Elastic IP
- Message "Apply complete! Resources: X added, 0 changed, 0 destroyed."

**Commande associée** :
```bash
terraform apply
```

---

### **4. Sorties Terraform**

**Fichier** : `captures/exercice-2/terraform/terraform-output.png`

**Description** : Capture de la commande `terraform output` montrant les informations de sortie.

**Ce que la capture doit montrer** :
- IP publique de l'instance OpenSearch
- Elastic IP de l'instance OpenSearch
- URL pour OpenSearch Dashboards
- URL pour l'API OpenSearch

**Commande associée** :
```bash
terraform output
```

---

## 📋 **Captures pour OpenSearch**

### **1. Installation d'OpenSearch**

**Fichier** : `captures/exercice-2/opensearch/opensearch-installing.png`

**Description** : Capture montrant l'installation d'OpenSearch via Ansible.

**Ce que la capture doit montrer** :
- Tâches Ansible en cours d'exécution
- Téléchargement de l'archive OpenSearch
- Extraction et configuration

**Commande associée** :
```bash
ansible-playbook -i inventories/exercice-2.ini playbooks/deploy-opensearch.yml
```

---

### **2. Statut du Service OpenSearch**

**Fichier** : `captures/exercice-2/opensearch/opensearch-service-status.png`

**Description** : Capture du statut du service OpenSearch.

**Ce que la capture doit montrer** :
- Service OpenSearch en cours d'exécution (active: running)
- PID du processus
- Temps d'activité

**Commande associée** :
```bash
ssh -i ~/.ssh/p5-key ec2-user@<OPENSEARCH_IP>
sudo systemctl status opensearch
```

---

### **3. Test de l'API OpenSearch**

**Fichier** : `captures/exercice-2/opensearch/opensearch-api-test.png`

**Description** : Capture du test de l'API OpenSearch via curl.

**Ce que la capture doit montrer** :
- Réponse JSON de l'API OpenSearch
- Nom du cluster
- Nom du nœud
- Version d'OpenSearch
- Message "The OpenSearch Project: https://opensearch.org/"

**Commande associée** :
```bash
curl http://<OPENSEARCH_IP>:9200
```

**Sortie attendue** :
```json
{
  "name" : "p5-opensearch-node-1",
  "cluster_name" : "p5-opensearch-cluster",
  "version" : {
    "number" : "2.11.1",
    "build_type" : "tar",
    "build_hash" : "...",
    "build_date" : "...",
    "build_snapshot" : false,
    "lucene_version" : "...",
    "minimum_wire_compatibility_version" : "...",
    "minimum_index_compatibility_version" : "..."
  },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}
```

---

### **4. Accès à OpenSearch Dashboards**

**Fichier** : `captures/exercice-2/opensearch/opensearch-dashboard-login.png`

**Description** : Capture de la page de connexion à OpenSearch Dashboards.

**Ce que la capture doit montrer** :
- Page d'accueil d'OpenSearch Dashboards
- URL : `http://<OPENSEARCH_IP>:9600`
- Interface web moderne

**Commande associée** :
Ouvrir un navigateur et aller sur `http://<OPENSEARCH_IP>:9600`

---

### **5. Page d'Accueil d'OpenSearch Dashboards**

**Fichier** : `captures/exercice-2/opensearch/opensearch-dashboard-home.png`

**Description** : Capture de la page d'accueil après connexion.

**Ce que la capture doit montrer** :
- Interface d'OpenSearch Dashboards
- Menu latéral avec les options (Discover, Visualize, Dashboard, etc.)
- Message de bienvenue

---

## 📋 **Captures pour Logstash**

### **1. Installation de Logstash**

**Fichier** : `captures/exercice-2/logstash/logstash-installing.png`

**Description** : Capture montrant l'installation de Logstash via Ansible.

**Ce que la capture doit montrer** :
- Tâches Ansible pour Logstash
- Téléchargement de l'archive Logstash
- Configuration du pipeline

---

### **2. Statut du Service Logstash**

**Fichier** : `captures/exercice-2/logstash/logstash-service-status.png`

**Description** : Capture du statut du service Logstash.

**Ce que la capture doit montrer** :
- Service Logstash en cours d'exécution (active: running)
- PID du processus
- Temps d'activité

**Commande associée** :
```bash
ssh -i ~/.ssh/p5-key ec2-user@<OPENSEARCH_IP>
sudo systemctl status logstash
```

---

### **3. Logs de Logstash**

**Fichier** : `captures/exercice-2/logstash/logstash-logs.png`

**Description** : Capture des logs de Logstash montrant le traitement des données.

**Ce que la capture doit montrer** :
- Messages de démarrage de Logstash
- Configuration du pipeline
- Messages de traitement des logs
- Absence d'erreurs

**Commande associée** :
```bash
ssh -i ~/.ssh/p5-key ec2-user@<OPENSEARCH_IP>
sudo tail -f /var/log/logstash/logstash-plain.log
```

---

## 📋 **Captures pour Filebeat**

### **1. Installation de Filebeat**

**Fichier** : `captures/exercice-2/filebeat/filebeat-installing.png`

**Description** : Capture montrant l'installation de Filebeat via Ansible.

**Ce que la capture doit montrer** :
- Tâches Ansible pour Filebeat
- Installation du package RPM
- Configuration de Filebeat

**Commande associée** :
```bash
ansible-playbook -i inventories/exercice-2.ini playbooks/deploy-filebeat.yml
```

---

### **2. Statut du Service Filebeat**

**Fichier** : `captures/exercice-2/filebeat/filebeat-service-status.png`

**Description** : Capture du statut du service Filebeat sur les serveurs NGINX.

**Ce que la capture doit montrer** :
- Service Filebeat en cours d'exécution sur nginx-1 et nginx-2
- Messages "active (running)"

**Commande associée** :
```bash
ansible -i inventories/exercice-2.ini nginx_servers -a "systemctl status filebeat"
```

---

### **3. Logs de Filebeat**

**Fichier** : `captures/exercice-2/filebeat/filebeat-logs.png`

**Description** : Capture des logs de Filebeat montrant l'envoi des logs.

**Ce que la capture doit montrer** :
- Messages de collecte des logs
- Connexion à Logstash
- Envoi des événements
- Statistiques de traitement

**Commande associée** :
```bash
ansible -i inventories/exercice-2.ini nginx_servers -a "sudo tail -f /var/log/filebeat/filebeat"
```

---

## 📋 **Captures pour le Flux de Données**

### **1. Liste des Index OpenSearch**

**Fichier** : `captures/exercice-2/data-flow/opensearch-indices.png`

**Description** : Capture de la liste des index dans OpenSearch.

**Ce que la capture doit montrer** :
- Index `logs-nginx-*` présent
- État de l'index (yellow ou green)
- Nombre de documents
- Taille de l'index

**Commande associée** :
```bash
curl -X GET "http://<OPENSEARCH_IP>:9200/_cat/indices?v"
```

**Sortie attendue** :
```
health status index                uuid                   pri rep docs.count docs.deleted store.size pri.store.size
yellow open   logs-nginx-2024.01.01 abc123... 1   0          123            0       123kb           123kb
```

---

### **2. Compte des Documents**

**Fichier** : `captures/exercice-2/data-flow/opensearch-documents-count.png`

**Description** : Capture du nombre de documents dans l'index `logs-nginx-*`.

**Ce que la capture doit montrer** :
- Nombre total de documents > 0
- Réponse JSON avec le compte

**Commande associée** :
```bash
curl -X GET "http://<OPENSEARCH_IP>:9200/logs-nginx-*/_count?pretty"
```

**Sortie attendue** :
```json
{
  "count" : 123,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  }
}
```

---

### **3. Visualisation dans Kibana (Discover)**

**Fichier** : `captures/exercice-2/data-flow/kibana-discover.png`

**Description** : Capture de l'interface Discover de Kibana montrant les logs NGINX.

**Ce que la capture doit montrer** :
- Interface Discover d'OpenSearch Dashboards
- Index pattern `logs-nginx-*` sélectionné
- Liste des logs avec les champs parsés (client_ip, http_method, status, etc.)
- Filtres appliqués (optionnel)

---

## 📋 **Captures pour les Visualisations**

### **1. Création de l'Index Pattern**

**Fichier** : `captures/exercice-2/visualizations/kibana-index-pattern.png`

**Description** : Capture de la création de l'index pattern dans Kibana.

**Ce que la capture doit montrer** :
- Page "Stack Management" → "Index Patterns"
- Index pattern `logs-nginx-*` créé
- Champ `@timestamp` sélectionné comme Time field

---

### **2. Création d'une Visualisation**

**Fichier** : `captures/exercice-2/visualizations/kibana-visualization-1.png`

**Description** : Capture de la création d'une visualisation dans Kibana.

**Ce que la capture doit montrer** :
- Interface de création de visualisation (Lens ou Visual Builder)
- Axes configurés (ex: X = @timestamp, Y = count())
- Filtres appliqués (ex: status: 200)
- Aperçu du graphique

---

### **3. Création d'un Tableau de Bord**

**Fichier** : `captures/exercice-2/visualizations/kibana-dashboard.png`

**Description** : Capture du tableau de bord final dans Kibana.

**Ce que la capture doit montrer** :
- Tableau de bord avec au moins 2 visualisations
- Titre du tableau de bord
- Données affichées correctement
- Période de temps sélectionnée

**Exemple de visualisations à inclure** :
- Nombre de requêtes par jour
- Répartition des codes HTTP (200, 404, 500, etc.)
- Top 10 des IPs clients
- Taux de requêtes par minute

---

## 📊 **Checklist des Captures**

### **Terraform**
- [ ] `terraform init`
- [ ] `terraform plan`
- [ ] `terraform apply`
- [ ] `terraform output`

### **OpenSearch**
- [ ] Installation via Ansible
- [ ] Statut du service
- [ ] Test de l'API
- [ ] Accès à Dashboards
- [ ] Page d'accueil Dashboards

### **Logstash**
- [ ] Installation via Ansible
- [ ] Statut du service
- [ ] Logs de traitement

### **Filebeat**
- [ ] Installation via Ansible
- [ ] Statut du service sur les 2 serveurs NGINX
- [ ] Logs d'envoi

### **Flux de Données**
- [ ] Liste des index OpenSearch
- [ ] Compte des documents
- [ ] Visualisation dans Discover

### **Visualisations**
- [ ] Création de l'index pattern
- [ ] Création d'une visualisation
- [ ] Création d'un tableau de bord

---

## 📌 **Conseils pour les Captures**

1. **Qualité** : Les captures doivent être **lisibles** (pas trop petites)
2. **Pertinence** : Chaque capture doit **prouver un point spécifique**
3. **Organisation** : Nommez les fichiers de manière **claire et descriptive**
4. **Exhaustivité** : Couvrez **toutes les étapes** de l'exercice
5. **Anonymisation** : Masquez les **informations sensibles** (IPs publiques, clés, etc.) si nécessaire

---

## 🎯 **Résumé**

✅ **Captures Terraform** : Preuves du déploiement de l'infrastructure
✅ **Captures OpenSearch** : Preuves de l'installation et du fonctionnement
✅ **Captures Logstash** : Preuves de l'installation et du traitement
✅ **Captures Filebeat** : Preuves de l'installation et de la collecte
✅ **Captures du flux de données** : Preuves de la centralisation des logs
✅ **Captures des visualisations** : Preuves de l'analyse des données

**Toutes les captures pour l'Exercice 2 sont documentées !** 📸

---

> *"Une capture d'écran vaut mille mots d'explication."* — **Adaptation DevOps**
