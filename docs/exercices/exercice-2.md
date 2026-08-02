# 🔥 Exercice 2 : OPENSEARCH (ELK)

---

## 🎯 OBJECTIFS

**But principal** : Déployer un **cluster OpenSearch** dans AWS pour stocker et analyser des logs.

**Compétences visées** :
- ✅ Déployer une base de données NoSQL (OpenSearch).
- ✅ Configurer un cluster pour la centralisation des logs.
- ✅ Comprendre l'architecture ELK/OpenSearch.
- ✅ Savoir utiliser AWS Elasticsearch Service.

**Résultat attendu** :
- ✅ 1 cluster OpenSearch déployé dans AWS.
- ✅ OpenSearch accessible et fonctionnel.
- ✅ Configuration de base pour l'indexation des logs.

---

## 🧠 CONCEPTS CLÉS À COMPRENDRE

### 🔹 1. OpenSearch / Elasticsearch

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **OpenSearch** | Moteur de recherche et d'analyse open source (fork d'Elasticsearch). | Permet de stocker, rechercher et analyser des logs à grande échelle | Système de rangement intelligent |
| **Cluster** | Ensemble de nœuds OpenSearch travaillant ensemble. | Permet de répartir la charge et d'assurer la haute disponibilité | Équipe de travailleurs |
| **Node** | Serveur individuel dans un cluster. | Stocke les données et exécute les requêtes | Membre de l'équipe |
| **Index** | Ensemble de documents similaires. | Permet d'organiser les logs par type (ex : logs-nginx-2026.08.02) | Dossier dans un classeur |
| **Document** | Unité de base de stockage (format JSON). | Représente un log ou un événement | Feuille dans un dossier |
| **Shard** | Partition d'un index. | Permet de répartir les données sur plusieurs nœuds | Section d'un dossier |
| **Replica** | Copie d'un shard pour la redondance. | Assure la haute disponibilité des données | Copie de sécurité |

---

### 🔹 2. AWS Elasticsearch Service

| Concept | Explication | Pourquoi c'est utile ? |
|---------|-------------|------------------------|
| **Domain** | Cluster OpenSearch managé par AWS. | Simplifie le déploiement et la gestion | Service clé en main |
| **Endpoint** | URL pour accéder au cluster. | Permet de se connecter à OpenSearch | Adresse d'un service |
| **Access Policies** | Règles de sécurité pour le cluster. | Contrôle qui peut accéder au cluster | Liste de contrôle d'accès |

---

## 🛠️ PRÉPARATION

### ✅ Prérequis pour l'Exercice 2

- Exercice 1 terminé avec succès (2 VMs NGINX déployées).
- VM **vm-devops** accessible en SSH.
- Terraform, Ansible, AWS CLI installés et configurés.
- Pack P5 disponible dans `/home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/`.

---

### 📌 Commandes de vérification

```bash
# 1. Vérifiez que vous êtes sur la VM vm-devops
hostname
# → Doit afficher : vm-devops

# 2. Vérifiez que Terraform est installé
terraform -version
# → Doit afficher : Terraform v1.15.8 (ou supérieur)

# 3. Vérifiez que AWS CLI est configuré
aws sts get-caller-identity
# → Doit afficher votre UserId et Account

# 4. Vérifiez que les instances NGINX de l'Exercice 1 sont toujours en cours d'exécution
aws ec2 describe-instances --query "Reservations[].Instances[?Tags[?Key=='Project' && Value=='p5-openclassrooms']].[InstanceId, PublicIpAddress, State.Name]" --output table
```

---

## 🚀 ÉTAPES D'EXÉCUTION

### Étape 1 : Déployer le cluster OpenSearch avec Terraform

1. **Aller dans le dossier de l'Exercice 2** :
   ```bash
   cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/
   ```

2. **Initialiser Terraform** :
   ```bash
   terraform init
   ```

3. **Vérifier le plan** :
   ```bash
   terraform plan
   ```
   **Ce que vous devriez voir** :
   - Création d'un **domain OpenSearch** (cluster managé).
   - Message : `Plan: X to add, 0 to change, 0 to destroy.`

4. **Appliquer le plan** :
   ```bash
   terraform apply -auto-approve
   ```
   **⚠️ Attention** : Cette étape peut prendre **5-10 minutes** (création du cluster).
   
   **Résultat attendu** :
   ```
   Apply complete! Resources: X added, 0 changed, 0 destroyed.
   ```

5. **Récupérer l'endpoint du cluster** :
   ```bash
   terraform output opensearch_endpoint
   ```
   **Notez l'endpoint** (ex: `vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com`).

---

### Étape 2 : Vérifier le cluster OpenSearch

1. **Vérifier l'état du domaine** :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status" --output text
   ```
   **Résultat attendu** :
   ```
   Active
   ```
   **⚠️ Important** : Attendez que le statut soit **"Active"** avant de continuer (peut prendre 5-10 min).

2. **Vérifier les détails du domaine** :
   ```bash
   aws es describe-domain --domain-name p5-opensearch
   ```
   **Ce que vous devriez voir** :
   - **DomainName** : `p5-opensearch`
   - **Endpoint** : `vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com`
   - **ElasticsearchVersion** : `7.10` (ou supérieur)
   - **NodeType** : `t3.medium.search`

---

### Étape 3 : Tester le cluster OpenSearch

1. **Tester l'API OpenSearch** :
   ```bash
   curl -k -X GET "https://$(terraform output -raw opensearch_endpoint)" -H "Content-Type: application/json"
   ```
   **Résultat attendu** :
   ```json
   {
     "name" : "p5-opensearch",
     "cluster_name" : "p5-opensearch",
     "version" : {
       "number" : "7.10.2",
       "build_type" : "tar",
       "build_hash" : "...",
       "build_date" : "...",
       "build_snapshot" : false,
       "lucene_version" : "...",
       "minimum_wire_compatibility_version" : "...",
       "minimum_index_compatibility_version" : "..."
     },
     "tagline" : "You Know, for Search"
   }
   ```

2. **Vérifier l'état du cluster** :
   ```bash
   curl -k -X GET "https://$(terraform output -raw opensearch_endpoint)/_cat/health?pretty" -H "Content-Type: application/json"
   ```
   **Résultat attendu** :
   ```json
   {
     "cluster_name" : "p5-opensearch",
     "status" : "yellow",
     "timed_out" : false,
     "number_of_nodes" : 1,
     "number_of_data_nodes" : 1,
     "active_primary_shards" : 0,
     "active_shards" : 0,
     "relocating_shards" : 0,
     "initializing_shards" : 0,
     "unassigned_shards" : 0,
     "delayed_unassigned_shards" : 0,
     "number_of_pending_tasks" : 0,
     "number_of_in_flight_fetch" : 0,
     "task_max_waiting_in_queue_millis" : 0,
     "active_shards_percent_as_number" : 100.0
   }
   ```
   **Note** : Le statut peut être **"yellow"** (normal pour un cluster à 1 nœud).

---

### Étape 4 : Configurer l'accès sécurisé (Optionnel)

1. **Configurer l'access policy** pour autoriser l'accès depuis votre IP :
   ```bash
   aws es update-domain-config --domain-name p5-opensearch --access-policies file://access-policy.json
   ```
   **Fichier `access-policy.json`** :
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "*"
         },
         "Action": [
           "es:*"
         ],
         "Resource": "arn:aws:es:us-east-1:123456789012:domain/p5-opensearch/*",
         "Condition": {
           "IpAddress": {
             "aws:SourceIp": ["VOTRE_IP_PUBLIQUE/32"]
           }
         }
       }
     ]
   }
   ```
   Remplacez `VOTRE_IP_PUBLIQUE` par votre IP (trouvez-la avec `curl ifconfig.me`).

---

## ✅ VÉRIFICATIONS

### Checklist de Vérification

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès
  - [ ] `terraform plan` affiche la création du domaine OpenSearch
  - [ ] `terraform apply` crée le cluster avec succès
  - [ ] Endpoint du cluster récupéré

- [ ] **AWS** :
  - [ ] Domaine OpenSearch visible dans la console AWS
  - [ ] Statut du domaine est **"Active"**
  - [ ] Endpoint accessible via `curl`

- [ ] **OpenSearch** :
  - [ ] API OpenSearch répond avec succès
  - [ ] État du cluster est **"yellow"** ou **"green"**

---

## 🛠️ DÉPANNAGE

### Problèmes Courants et Solutions

#### 1. Erreur : "Domain already exists" (Terraform)
**Symptômes** :
```
Error: Error creating Elasticsearch domain: DomainAlreadyExistsException
```
**Solutions** :
1. Supprimez le domaine existant :
   ```bash
   aws es delete-domain --domain-name p5-opensearch
   ```
2. Attendez que la suppression soit terminée (peut prendre 10-15 min).
3. Réessayez `terraform apply`.

---

#### 2. Erreur : "Domain creation timed out" (Terraform)
**Symptômes** :
```
Error: Wait for domain to be created: timeout while waiting for state to become 'Active'
```
**Solutions** :
1. Vérifiez l'état du domaine :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status"
   ```
2. Si le domaine est dans l'état **"Processing"**, attendez quelques minutes.
3. Si le domaine est dans l'état **"Failed"**, supprimez-le et recréez-le.

---

#### 3. Erreur : "Access Denied" (OpenSearch API)
**Symptômes** :
```
{"Message":"User: anonymous is not authorized to perform: es:ESHttpGet"
```
**Solutions** :
1. Configurez l'access policy (voir [Étape 4](#étape-4--configurer-laccès-sécurisé-optionnel)).
2. Utilisez les bonnes credentials AWS :
   ```bash
   aws sts get-caller-identity
   ```
3. Vérifiez que votre utilisateur IAM a les permissions **AmazonESFullAccess**.

---

#### 4. Erreur : "Connection refused" (curl)
**Symptômes** :
```
curl: (7) Failed to connect to ... port 443: Connection refused
```
**Solutions** :
1. Vérifiez que le domaine est dans l'état **"Active"** :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status"
   ```
2. Vérifiez que l'endpoint est correct :
   ```bash
   terraform output opensearch_endpoint
   ```
3. Vérifiez que votre IP est autorisée dans l'access policy.

---

## 📚 RESSOURCES UTILES

- [Documentation AWS Elasticsearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html)
- [Documentation OpenSearch](https://opensearch.org/docs/)
- [Documentation Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🎯 RÉSUMÉ

✅ **Cluster OpenSearch déployé** avec Terraform
✅ **Domaine accessible** et fonctionnel
✅ **API OpenSearch testée** avec succès
✅ **Toutes les vérifications** passées avec succès

**Exercice 2 terminé avec succès !** 🎉

---

**Prochaine étape** : [Exercice 3 - HAProxy (Load Balancer)](exercice-3.md)
