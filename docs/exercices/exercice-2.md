# [34mExercice 2 : OPENSEARCH + KIBANA (ELK Stack)[0m

---

## [35m📌 OBJECTIFS (Aligné 100% avec OpenClassrooms)[0m

**But principal** : Déployer un **cluster OpenSearch + Kibana** dans AWS, charger les logs NGINX, et créer un **dashboard Kibana avec 3 diagrammes obligatoires**.

**Compétences visées** :
- [32m✅[0m Déployer une base de données NoSQL (OpenSearch).
- [32m✅[0m Configurer Kibana pour visualiser les logs.
- [32m✅[0m Charger et indexer des logs NGINX.
- [32m✅[0m Créer des visualisations et un dashboard complet.
- [32m✅[0m Générer les **4 captures d'écran** requises.

**Résultat attendu** :
- [32m✅[0m 1 cluster OpenSearch déployé dans AWS (avec Kibana activé).
- [32m✅[0m Fichier `nginx-access.log` chargé et indexé.
- [32m✅[0m **3 diagrammes obligatoires** dans Kibana :
  - Diagramme **"donut"** : Répartition des verbes HTTP (GET, POST, etc.).
  - Diagramme **"histogramme"** : Quantité cumulée de données envoyées par tranche de 12h.
  - Diagramme **"histogramme cumulé"** : Top 5 des requêtes par tranche de 12h.
- [32m✅[0m **4 captures d'écran** livrées (dashboard complet + 3 diagrammes individuels).

---

## [36m📚 CONCEPTS CLÉS À COMPRENDRE[0m

### [33m🔹 1. OpenSearch / Elasticsearch[0m

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **OpenSearch** | Moteur de recherche et d'analyse open source (fork d'Elasticsearch). | Permet de stocker, rechercher et analyser des logs à grande échelle | Système de rangement intelligent |
| **Cluster** | Ensemble de nœuds OpenSearch travaillant ensemble. | Permet de répartir la charge et d'assurer la haute disponibilité | Équipe de travailleurs |
| **Node** | Serveur individuel dans un cluster. | Stocke les données et exécute les requêtes | Membre de l'équipe |
| **Index** | Ensemble de documents similaires. | Permet d'organiser les logs par type (ex : `nginx-access-2026.08.02`) | Dossier dans un classeur |
| **Document** | Unité de base de stockage (format JSON). | Représente un log ou un événement | Feuille dans un dossier |
| **Kibana** | Interface de visualisation pour OpenSearch/Elasticsearch. | Permet de créer des dashboards et graphiques | Tableau de bord |

---

### [33m🔹 2. Kibana et Visualisations[0m

| Concept | Explication | Utilisation dans ce projet |
|---------|-------------|-----------------------------|
| **Index Pattern** | Configuration pour accéder à un index dans Kibana. | Permet de lier Kibana à l'index `nginx-access-*` |
| **Discover** | Outil pour explorer les données brutes. | Vérifier que les logs NGINX sont bien chargés |
| **Visualize** | Outil pour créer des graphiques. | Créer les 3 diagrammes obligatoires |
| **Dashboard** | Tableau de bord regroupant plusieurs visualisations. | Regrouper les 3 diagrammes dans un seul dashboard |
| **Donut Chart** | Diagramme circulaire montrant des proportions. | Répartition des verbes HTTP (GET, POST, etc.) |
| **Histogram** | Graphique en barres pour des données temporelles. | Quantité de données par tranche de 12h |
| **Cumulative Histogram** | Histogramme avec cumul. | Top 5 des requêtes par tranche de 12h |

---

### [33m🔹 3. Fichier `nginx-access.log`[0m

**Format du fichier** (exemple) :
```log
192.168.1.1 - - [02/Aug/2026:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
192.168.1.2 - - [02/Aug/2026:10:00:01 +0000] "POST /api/data HTTP/1.1" 200 5678 "-" "Mozilla/5.0"
```

**Champs importants** :
- **IP du client** (`192.168.1.1`)
- **Date/Heure** (`[02/Aug/2026:10:00:00 +0000]`)
- **Verbe HTTP** (`GET`, `POST`)
- **URL demandée** (`/index.html`)
- **Code HTTP** (`200`)
- **Taille de la réponse** (`1234` octets)

---

## [35m🛠️ PRÉPARATION[0m

### [32m✅[0m Prérequis pour l'Exercice 2

- [32m✅[0m Exercice 1 terminé avec succès (2 VMs NGINX déployées **avec l'application Angular**).
- [32m✅[0m VM **vm-devops** accessible en SSH.
- [32m✅[0m Terraform, Ansible, AWS CLI installés et configurés.
- [32m✅[0m **Fichier `nginx-access.log`** disponible (fournis dans le starter-kit OpenClassrooms ou [téléchargeable ici](#)).
- [32m✅[0m Pack P5 disponible dans `/home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/`.

---

### [36m📁 Fichiers nécessaires[0m

1. **Télécharger `nginx-access.log`** (si non fourni) :
   ```bash
   # Créer un dossier pour les données
   mkdir -p /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/data/
   
   # Télécharger un exemple de fichier (si le starter-kit n'est pas disponible)
   wget https://raw.githubusercontent.com/OpenClassrooms-P5/starter-kit/main/nginx-access.log -O /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/data/nginx-access.log
   ```

2. **Vérifier le fichier** :
   ```bash
   head -n 5 /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/data/nginx-access.log
   ```
   **Résultat attendu** :
   ```log
   192.168.1.1 - - [02/Aug/2026:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
   192.168.1.2 - - [02/Aug/2026:10:00:01 +0000] "POST /api/data HTTP/1.1" 200 5678 "-" "Mozilla/5.0"
   ...
   ```

---

### [36m🔍 Commandes de vérification[0m

```bash
# 1. Vérifiez que vous êtes sur la VM vm-devops
hostname
# [32m✅[0m Doit afficher : vm-devops

# 2. Vérifiez que Terraform est installé
terraform -version
# [32m✅[0m Doit afficher : Terraform v1.15.8 (ou supérieur)

# 3. Vérifiez que AWS CLI est configuré
aws sts get-caller-identity
# [32m✅[0m Doit afficher votre UserId et Account

# 4. Vérifiez que le fichier nginx-access.log existe
ls -lh /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/data/nginx-access.log
# [32m✅[0m Doit afficher le fichier avec une taille > 0
```

---

## [34m🚀 ÉTAPES D'EXÉCUTION[0m

---

### [32m✅ Étape 1 : Déployer le cluster OpenSearch avec Kibana activé[0m

> **⚠️ IMPORTANT** : AWS OpenSearch Service inclut **Kibana par défaut** (appelé "OpenSearch Dashboards").
> L'URL de Kibana est la même que celle d'OpenSearch, avec le chemin `/_dashboards`.

1. **Aller dans le dossier de l'Exercice 2** :
   ```bash
   cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/
   ```

2. **Vérifier le fichier `main.tf`** (Kibana doit être activé) :
   ```bash
   cat main.tf | grep -A 5 "advanced_options"
   ```
   **Si Kibana n'est pas activé**, modifiez le fichier `main.tf` pour ajouter :
   ```hcl
   resource "aws_elasticsearch_domain" "p5_opensearch" {
     domain_name           = "p5-opensearch"
     elasticsearch_version = "7.10"
     
     # Activer Kibana (OpenSearch Dashboards)
     advanced_options {
       dashboards_enabled = true
     }
     
     # ... (autres configurations)
   }
   ```

3. **Initialiser Terraform** :
   ```bash
   terraform init
   ```
   **Résultat attendu** :
   ```
   Terraform has been successfully initialized!
   ```

4. **Vérifier le plan** :
   ```bash
   terraform plan
   ```
   **Ce que vous devriez voir** :
   - Création d'un **domain OpenSearch** (avec Kibana activé).
   - Message : `Plan: X to add, 0 to change, 0 to destroy.`

5. **Appliquer le plan** :
   ```bash
   terraform apply -auto-approve
   ```
   **⚠️ Attention** : Cette étape peut prendre **5-10 minutes** (création du cluster).
   
   **Résultat attendu** :
   ```
   Apply complete! Resources: X added, 0 changed, 0 destroyed.
   ```

6. **Récupérer l'endpoint du cluster et l'URL de Kibana** :
   ```bash
   # Endpoint OpenSearch (pour les requêtes API)
   OPENSEARCH_ENDPOINT=$(terraform output -raw opensearch_endpoint)
   echo "OpenSearch Endpoint: $OPENSEARCH_ENDPOINT"
   
   # URL Kibana (OpenSearch Dashboards)
   KIBANA_URL="https://$OPENSEARCH_ENDPOINT/_dashboards"
   echo "Kibana URL: $KIBANA_URL"
   ```
   **Notez ces URLs** pour les étapes suivantes.

---

### [32m✅ Étape 2 : Vérifier le cluster OpenSearch et Kibana[0m

1. **Vérifier l'état du domaine** :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status" --output text
   ```
   **Résultat attendu** :
   ```
   Active
   ```
   **⚠️ Important** : Attendez que le statut soit **"Active"** avant de continuer (peut prendre 5-10 min).

2. **Vérifier que Kibana est accessible** :
   ```bash
   curl -k -I "$KIBANA_URL"
   ```
   **Résultat attendu** :
   ```
   HTTP/1.1 200 OK
   ```

3. **Accéder à Kibana via navigateur** :
   - Ouvrez un navigateur et allez sur :
     **`https://<votre-endpoint>/_dashboards`**
     (ex: `https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_dashboards`)
   - **⚠️ Si vous avez une erreur de certificat** : Utilisez le mode navigation privée ou acceptez le risque.
   - **⚠️ Si vous avez une erreur d'accès** : Configurez l'[access policy](#étape-3-configurer-laccès-sécurisé-obligatoire).

---

### [32m✅ Étape 3 : Configurer l'accès sécurisé (OBLIGATOIRE)[0m

> **⚠️ Sans cette étape, vous ne pourrez pas accéder à Kibana !**

1. **Récupérer votre IP publique** :
   ```bash
   MY_IP=$(curl -s ifconfig.me)
   echo "Votre IP publique : $MY_IP"
   ```

2. **Créer le fichier `access-policy.json`** :
   ```bash
   cat > access-policy.json <<EOF
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
         "Resource": "arn:aws:es:us-east-1:$(aws sts get-caller-identity --query Account --output text):domain/p5-opensearch/*",
         "Condition": {
           "IpAddress": {
             "aws:SourceIp": ["$MY_IP/32"]
           }
         }
       }
     ]
   }
   EOF
   ```

3. **Appliquer l'access policy** :
   ```bash
   aws es update-domain-config --domain-name p5-opensearch --access-policies file://access-policy.json
   ```

4. **Attendre la mise à jour** (peut prendre 1-2 min) :
   ```bash
   sleep 60
   ```

5. **Tester l'accès à Kibana** :
   ```bash
   curl -k -I "$KIBANA_URL"
   ```
   **Résultat attendu** : `HTTP/1.1 200 OK`

---

### [32m✅ Étape 4 : Charger le fichier `nginx-access.log` dans OpenSearch[0m

> **⚠️ Cette étape est CRUCIALE pour créer les diagrammes dans Kibana.**

#### **Option 1 : Utiliser `curl` pour envoyer les logs (Recommandé)**

1. **Créer un index `nginx-access`** :
   ```bash
   curl -k -X PUT "$OPENSEARCH_ENDPOINT/nginx-access-$(date +%Y.%m.%d)" -H "Content-Type: application/json" -d '{
     "settings": {
       "number_of_shards": 1,
       "number_of_replicas": 0
     }
   }'
   ```

2. **Envoyer le fichier `nginx-access.log`** (format brut) :
   > **⚠️ Problème** : OpenSearch attend du JSON, mais `nginx-access.log` est en format brut.
   > **Solution** : Utiliser **Logstash** ou un script pour convertir les logs en JSON.
   
   **Méthode simple (avec `jq`)** :
   ```bash
   # Installer jq (si non installé)
   sudo apt install -y jq
   
   # Convertir nginx-access.log en JSON et l'envoyer à OpenSearch
   while IFS= read -r line; do
     # Extraire les champs du log NGINX (format standard)
     ip=$(echo "$line" | awk '{print $1}')
     date_time=$(echo "$line" | awk '{print $4,$5}')
     method=$(echo "$line" | awk -F'"' '{print $2}')
     url=$(echo "$line" | awk -F'"' '{print $3}')
     status=$(echo "$line" | awk '{print $9}')
     size=$(echo "$line" | awk '{print $10}')
     
     # Créer un document JSON
     json_doc=$(jq -n \
       --arg ip "$ip" \
       --arg timestamp "$date_time" \
       --arg method "$method" \
       --arg url "$url" \
       --arg status "$status" \
       --arg size "$size" \
       '{
         "@timestamp": $timestamp,
         "client_ip": $ip,
         "method": $method,
         "url": $url,
         "status": $status,
         "size": $size
       }')
     
     # Envoyer à OpenSearch
     curl -k -X POST "$OPENSEARCH_ENDPOINT/nginx-access-$(date +%Y.%m.%d)/_doc" -H "Content-Type: application/json" -d "$json_doc"
   done < /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/data/nginx-access.log
   ```
   **⚠️ Cette méthode est lente pour de gros fichiers.**

#### **Option 2 : Utiliser Filebeat (Recommandé pour la production)**

1. **Installer Filebeat sur la VM vm-devops** :
   ```bash
   sudo apt update
   sudo apt install -y filebeat
   ```

2. **Configurer Filebeat pour OpenSearch** :
   ```bash
   sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOF
   filebeat.inputs:
   - type: log
     enabled: true
     paths:
       - /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/data/nginx-access.log
     json.keys_under_root: true
     json.add_error_key: true
     
   output.opensearch:
     hosts: ["$OPENSEARCH_ENDPOINT"]
     index: "nginx-access-%{+yyyy.MM.dd}"
     
   setup.ilm.enabled: false
   EOF
   ```

3. **Démarrer Filebeat** :
   ```bash
   sudo filebeat -e
   ```
   **⚠️ Laissez Filebeat tourner en arrière-plan.**

4. **Vérifier que les données sont bien envoyées** :
   ```bash
   curl -k -X GET "$OPENSEARCH_ENDPOINT/nginx-access-$(date +%Y.%m.%d)/_search?pretty" -H "Content-Type: application/json"
   ```
   **Résultat attendu** : Une liste de documents JSON.

---

### [32m✅ Étape 5 : Configurer Kibana pour visualiser les logs[0m

> **⚠️ À faire dans l'interface Kibana (via navigateur).**

1. **Accéder à Kibana** :
   - Ouvrez : **`https://<votre-endpoint>/_dashboards`**
   - Exemple : `https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_dashboards`

2. **Créer un Index Pattern** :
   - Allez dans **"Stack Management"** (⚙️ en bas à gauche).
   - Cliquez sur **"Index Patterns"** > **"Create index pattern"**.
   - **Nom** : `nginx-access*`
   - **Next step** : Sélectionnez `@timestamp` comme champ de temps.
   - **Create index pattern**.

3. **Vérifier les données dans "Discover"** :
   - Allez dans **"Discover"** (🔍 en haut).
   - Sélectionnez l'index pattern `nginx-access*`.
   - **✅ Vous devriez voir vos logs NGINX.**

---

### [32m✅ Étape 6 : Créer les 3 diagrammes obligatoires dans Kibana[0m

> **⚠️ Ces diagrammes sont OBLIGATOIRES pour le livrable.**

#### **📊 Diagramme 1 : Répartition des verbes HTTP (Donut Chart)**

1. **Aller dans "Visualize"** :
   - Cliquez sur **"Visualize"** (📊 en haut).
   - **"Create visualization"** > **"Pie"** (ou "Donut").

2. **Configurer le diagramme** :
   - **Index Pattern** : `nginx-access*`
   - **Metrics** :
     - **Aggregation** : `Count`
   - **Buckets** :
     - **Split Slices** :
       - **Aggregation** : `Terms`
       - **Field** : `method`
       - **Size** : `5` (pour afficher GET, POST, etc.)

3. **Enregistrer le diagramme** :
   - **Title** : `Répartition des verbes HTTP`
   - **Save Visualization**.

---

#### **📈 Diagramme 2 : Quantité cumulée de données envoyées par tranche de 12h (Histogram)**

1. **Créer un nouvel histogramme** :
   - **"Create visualization"** > **"Area"** ou **"Bar"** (Histogram).

2. **Configurer le diagramme** :
   - **Index Pattern** : `nginx-access*`
   - **Metrics** :
     - **Aggregation** : `Sum`
     - **Field** : `size`
   - **Buckets** :
     - **X-Axis** :
       - **Aggregation** : `Date Histogram`
       - **Field** : `@timestamp`
       - **Interval** : `12h` (tranche de 12 heures)

3. **Enregistrer le diagramme** :
   - **Title** : `Quantité cumulée de données par tranche de 12h`
   - **Save Visualization**.

---

#### **📉 Diagramme 3 : Top 5 des requêtes par tranche de 12h (Cumulative Histogram)**

1. **Créer un nouvel histogramme cumulé** :
   - **"Create visualization"** > **"Area"** (pour le cumul).

2. **Configurer le diagramme** :
   - **Index Pattern** : `nginx-access*`
   - **Metrics** :
     - **Aggregation** : `Count`
   - **Buckets** :
     - **X-Axis** :
       - **Aggregation** : `Date Histogram`
       - **Field** : `@timestamp`
       - **Interval** : `12h`
     - **Split Series** :
       - **Sub Aggregation** : `Terms`
       - **Field** : `url`
       - **Size** : `5` (Top 5 des URLs)
       - **Order** : `Descending`

3. **Activer le cumul** :
   - Dans l'onglet **"Metrics"**, cochez **"Cumulative"**.

4. **Enregistrer le diagramme** :
   - **Title** : `Top 5 des requêtes par tranche de 12h (cumul)`
   - **Save Visualization**.

---

### [32m✅ Étape 7 : Créer le Dashboard Kibana[0m

1. **Aller dans "Dashboard"** :
   - Cliquez sur **"Dashboard"** (📑 en haut).
   - **"Create Dashboard"**.

2. **Ajouter les 3 diagrammes** :
   - Cliquez sur **"Add"** > Sélectionnez les 3 visualisations créées précédemment.
   - Organisez-les comme vous le souhaitez (ex : en ligne ou en colonne).

3. **Enregistrer le dashboard** :
   - **Title** : `Dashboard NGINX - Analyse des logs`
   - **Save Dashboard**.

---

### [32m✅ Étape 8 : Générer les 4 captures d'écran[0m

> **⚠️ OBLIGATOIRE pour le livrable.**

**Captures à fournir** (au format PNG ou JPG) :

| N° | Capture | Description | Nom du fichier |
|---|---------|-------------|----------------|
| 1 | **Dashboard complet** | Dashboard avec les 3 diagrammes | `SEGUIN-CADICHE_Mathias_2_dashboard_complet_<date>.png` |
| 2 | **Diagramme Donut** | Répartition des verbes HTTP (seul) | `SEGUIN-CADICHE_Mathias_2_diagramme_donut_<date>.png` |
| 3 | **Diagramme Histogramme** | Quantité cumulée de données par tranche de 12h (seul) | `SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_<date>.png` |
| 4 | **Diagramme Histogramme cumulé** | Top 5 des requêtes par tranche de 12h (seul) | `SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_cumule_<date>.png` |

**Comment faire les captures** :
1. **Sur Windows** : `Win + Maj + S` (Outil de capture) ou `PrtScn`.
2. **Sur Linux** : `FlameShot` ou `gnome-screenshot`.
3. **Sur Mac** : `Cmd + Maj + 4`.

**Où les stocker** :
```bash
mkdir -p /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/05_LIVRABLES/Exercice_2/
```

---

## [32m✅ VÉRIFICATIONS FINALES[0m

### **Checklist de Vérification (OpenClassrooms)**

- [ ] **Cluster OpenSearch déployé** avec Terraform.
- [ ] **Kibana accessible** via l'URL `/_dashboards`.
- [ ] **Fichier `nginx-access.log` chargé** dans OpenSearch.
- [ ] **Index `nginx-access-*` créé** et visible dans Kibana.
- [ ] **Index Pattern `nginx-access*` configuré** dans Kibana.
- [ ] **3 diagrammes créés** :
  - [ ] Diagramme "donut" (répartition des verbes HTTP).
  - [ ] Diagramme "histogramme" (quantité cumulée de données par tranche de 12h).
  - [ ] Diagramme "histogramme cumulé" (Top 5 des requêtes par tranche de 12h).
- [ ] **Dashboard Kibana créé** avec les 3 diagrammes.
- [ ] **4 captures d'écran générées** (dashboard + 3 diagrammes).

---

## [31m⚠️ DÉPANNAGE[0m

### **Problèmes Courants et Solutions**

#### **1. Erreur : "Domain already exists" (Terraform)**
**Symptômes** :
```
Error: Error creating Elasticsearch domain: DomainAlreadyExistsException
```
**Solutions** :
1. Supprimez le domaine existant :
   ```bash
   aws es delete-domain --domain-name p5-opensearch
   ```
2. Attendez que la suppression soit terminée (peut prendre 10-15 min) :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status"
   ```
3. Réessayez `terraform apply`.

---

#### **2. Erreur : "Access Denied" (Kibana)**
**Symptômes** :
```
{"Message":"User: anonymous is not authorized to perform: es:ESHttpGet"
```
**Solutions** :
1. Vérifiez que l'[access policy](#étape-3-configurer-laccès-sécurisé-obligatoire) est bien configurée.
2. Vérifiez votre IP publique :
   ```bash
   curl ifconfig.me
   ```
3. Mettez à jour l'access policy avec la bonne IP.

---

#### **3. Erreur : "No data" dans Kibana**
**Symptômes** :
- Le dashboard ou "Discover" n'affiche aucune donnée.

**Solutions** :
1. Vérifiez que les logs ont bien été envoyés :
   ```bash
   curl -k -X GET "$OPENSEARCH_ENDPOINT/_cat/indices?v" -H "Content-Type: application/json"
   ```
   **Résultat attendu** : L'index `nginx-access-*` doit apparaître.

2. Vérifiez que l'index pattern est correct :
   - Allez dans **"Stack Management" > "Index Patterns"**.
   - Vérifiez que `nginx-access*` existe.

3. Si vous avez utilisé Filebeat, vérifiez les logs :
   ```bash
   sudo journalctl -u filebeat -f
   ```

---

#### **4. Erreur : "Invalid JSON" lors de l'envoi des logs**
**Symptômes** :
```
{"error":{"root_cause":[{"type":"mapper_parsing_exception","reason":"failed to parse"}]
```
**Solutions** :
1. Vérifiez que votre script de conversion génère du **JSON valide** :
   ```bash
   echo '{"test": "value"}' | jq .
   ```
2. Utilisez **Filebeat** pour éviter les erreurs de format.

---

#### **5. Kibana ne s'affiche pas**
**Symptômes** :
- La page Kibana reste blanche ou affiche une erreur.

**Solutions** :
1. Vérifiez que le cluster est **"Active"** :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status"
   ```
2. Vérifiez que Kibana est activé :
   ```bash
   aws es describe-domain --domain-name p5-opensearch --query "DomainConfig.AdvancedOptions.DashboardsEnabled"
   ```
   **Résultat attendu** : `true`

3. Essayez d'accéder à Kibana via un **navigateur en mode privé**.

---

## [36m📚 RESSOURCES UTILES[0m

- [Documentation AWS OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html)
- [Documentation Kibana](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Tutoriel : Charger des logs dans OpenSearch](https://opensearch.org/docs/latest/opensearch/rest-api/index/)
- [Tutoriel : Créer un dashboard Kibana](https://www.elastic.co/guide/en/kibana/current/dashboard.html)
- [Format des logs NGINX](https://docs.nginx.com/nginx/admin-guide/logging-and-monitoring/log-format/)

---

## [35m📌 RÉSUMÉ DES LIVRABLES (Format OpenClassrooms)[0m

### **📁 Dossier à livrer** :
```
P5_4091_Deployez_et_suivez_l_IaC_Mathias_SEGUIN-CADICHE/
└── Exercice_2/
    ├── SEGUIN-CADICHE_Mathias_2_dashboard_complet_<date>.png
    ├── SEGUIN-CADICHE_Mathias_2_diagramme_donut_<date>.png
    ├── SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_<date>.png
    └── SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_cumule_<date>.png
```

### **📋 Contenu du livrable** :
| Fichier | Description | Format |
|---------|-------------|--------|
| `dashboard_complet_<date>.png` | Dashboard Kibana avec les 3 diagrammes | PNG |
| `diagramme_donut_<date>.png` | Diagramme "donut" (répartition des verbes HTTP) | PNG |
| `diagramme_histogramme_<date>.png` | Diagramme "histogramme" (quantité cumulée de données) | PNG |
| `diagramme_histogramme_cumule_<date>.png` | Diagramme "histogramme cumulé" (Top 5 des requêtes) | PNG |

---

## [32m✅ EXERCICE 2 TERMINÉ AVEC SUCCÈS ![0m

[32m✅[0m Cluster OpenSearch + Kibana déployé
[32m✅[0m Fichier `nginx-access.log` chargé et indexé
[32m✅[0m **3 diagrammes obligatoires** créés dans Kibana
[32m✅[0m **4 captures d'écran** générées
[32m✅[0m Toutes les vérifications passées

**Prochaine étape** : [Exercice 3 - HAProxy (Load Balancer)](exercice-3.md)

---

**⚠️ Rappel** :
- **Nettoyez vos ressources AWS** après l'exercice pour éviter des coûts inutiles :
  ```bash
  cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/
  terraform destroy -auto-approve
  ```
- **Sauvegardez vos captures d'écran** dans le dossier des livrables.
