# ✅ Décisions Techniques

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce fichier doit **documenter toutes les décisions techniques** que vous avez prises pendant le projet. Il sert à :

✅ **Expliquer vos choix** d'architecture et de configuration
✅ **Justifier** les solutions retenues
✅ **Comparer** les alternatives envisagées
✅ **Faciliter la compréhension** de votre travail par l'évaluateur

**Format recommandé** :
- **1 section par décision majeure**
- **Structure claire** avec contexte, décision, justification, alternatives
- **Détails techniques** quand nécessaire

---

## 🏗️ **Décisions d'Architecture**

### **1. Choix de la Région AWS**

**Contexte** : Le projet nécessite de déployer des ressources AWS. Le choix de la région impacte :
- Les coûts
- Les performances (latence)
- La disponibilité des services

**Décision** : Utiliser la région **`eu-west-3` (Paris)**

**Justification** :
- ✅ **Proximité géographique** : Réduction de la latence pour les utilisateurs en Europe
- ✅ **Coûts** : Pas de différence significative avec d'autres régions
- ✅ **Disponibilité** : Tous les services nécessaires sont disponibles
- ✅ **Free Tier** : Éligible au Free Tier comme toutes les autres régions

**Alternatives envisagées** :
- `us-east-1` (Virginie) : Moins de latence pour les utilisateurs américains, mais plus éloignée de la France
- `eu-central-1` (Francfort) : Proche, mais légèrement plus chère

**Impact** : Aucune modification nécessaire dans le code pour changer de région.

---

### **2. Choix du Type d'Instance pour NGINX**

**Contexte** : Les serveurs NGINX doivent servir des pages web statiques. Le choix du type d'instance impacte :
- Les performances
- Les coûts
- L'éligibilité au Free Tier

**Décision** : Utiliser des instances **`t2.micro`**

**Justification** :
- ✅ **Coût** : ~$0.0116/heure (éligible au Free Tier)
- ✅ **Performances** : Suffisant pour des pages statiques et un trafic modéré
- ✅ **Free Tier** : 750 heures/mois gratuites pendant 12 mois
- ✅ **Mémoire** : 1 vCPU, 1 GiB RAM (suffisant pour NGINX)

**Alternatives envisagées** :
- `t3.micro` : Légèrement moins cher, mais performances variables
- `t2.small` : 2 vCPU, 2 GiB RAM (surdimensionné pour ce projet)

**Impact** : Si le trafic augmente, il faudra passer à un type d'instance plus puissant.

---

### **3. Choix du Type d'Instance pour OpenSearch**

**Contexte** : OpenSearch nécessite plus de ressources que NGINX pour fonctionner correctement.

**Décision** : Utiliser une instance **`t3.medium`**

**Justification** :
- ✅ **Mémoire** : 4 GiB RAM (minimum recommandé pour OpenSearch)
- ✅ **CPU** : 2 vCPU (suffisant pour un nœud unique)
- ✅ **Coût** : ~$0.0416/heure (acceptable pour un projet de test)
- ✅ **Performances** : Permet de gérer un volume de logs raisonnable

**Alternatives envisagées** :
- `t2.medium` : 2 vCPU, 4 GiB RAM (similaire, mais pas de CPU burstable)
- `t3.large` : 2 vCPU, 8 GiB RAM (meilleur pour la production)
- `r5.large` : 2 vCPU, 16 GiB RAM (idéal pour la production, mais plus cher)

**Impact** : Pour un environnement de production, il faudrait utiliser au moins `t3.large` ou `r5.large`.

---

### **4. Architecture du VPC**

**Contexte** : Le VPC doit héberger toutes les ressources du projet.

**Décision** : Utiliser une architecture avec :
- **1 VPC** avec CIDR `10.0.0.0/16`
- **2 Public Subnets** (10.0.1.0/24 et 10.0.2.0/24) dans des AZ différentes
- **1 Internet Gateway** pour l'accès internet
- **Pas de NAT Gateway** (pour réduire les coûts)

**Justification** :
- ✅ **Simplicité** : Architecture simple et facile à comprendre
- ✅ **Redondance** : 2 subnets publics dans des AZ différentes pour la haute disponibilité
- ✅ **Coût** : Pas de NAT Gateway (économie de ~$36/mois)
- ✅ **Sécurité** : Isolation des ressources dans un VPC dédié

**Alternatives envisagées** :
- Ajouter des **Private Subnets** pour les bases de données (non nécessaire pour ce projet)
- Ajouter un **NAT Gateway** pour permettre l'accès internet aux instances privées

**Impact** : Si on ajoute des ressources privées (comme une base de données), il faudra ajouter un NAT Gateway.

---

### **5. Architecture de la Stack ELK/OpenSearch**

**Contexte** : Choix entre Elasticsearch (propriétaire) et OpenSearch (open source).

**Décision** : Utiliser **OpenSearch** au lieu d'Elasticsearch

**Justification** :
- ✅ **Open Source** : 100% open source (licence Apache 2.0)
- ✅ **Gratuité** : Pas de limitations de fonctionnalités
- ✅ **Compatibilité** : Compatible avec Logstash et Beats
- ✅ **Support AWS** : Meilleur support natif par AWS
- ✅ **Éthique** : Respect de la philosophie open source

**Alternatives envisagées** :
- **Elasticsearch** : Plus mature, mais licence SSPL (non open source)
- **Elastic Cloud** : Solution managée, mais payante

**Impact** : Aucune différence fonctionnelle pour ce projet.

---

### **6. Architecture du Pipeline de Logs**

**Contexte** : Plusieurs options pour collecter et traiter les logs NGINX.

**Décision** : Utiliser **Filebeat → Logstash → OpenSearch**

**Justification** :
- ✅ **Flexibilité** : Logstash permet de transformer les logs avant indexation
- ✅ **Robustesse** : Filebeat est un agent léger et fiable
- ✅ **Centralisation** : Tous les logs passent par Logstash avant d'être indexés
- ✅ **Extensibilité** : Facile d'ajouter d'autres sources de logs

**Alternatives envisagées** :
- **Filebeat → OpenSearch** : Plus simple, mais moins flexible (pas de transformation)
- **Fluentd → OpenSearch** : Alternative à Logstash, mais moins intégré avec l'écosystème Elastic
- **Logstash → Elasticsearch** : Solution classique, mais Elasticsearch n'est plus open source

**Impact** : L'architecture choisie permet une grande flexibilité pour le traitement des logs.

---

## 🛠️ **Décisions de Configuration**

### **1. Configuration des Security Groups**

**Contexte** : Les Security Groups doivent autoriser le trafic nécessaire tout en restant sécurisés.

**Décision** : 
- **NGINX** : Autoriser HTTP (80) depuis n'importe où, SSH (22) depuis mon IP
- **OpenSearch** : Autoriser OpenSearch API (9200) et Dashboards (9600) depuis mon IP, Logstash (5044) depuis NGINX
- **HAProxy** : Autoriser HTTP (80) et HTTPS (443) depuis n'importe où, SSH (22) depuis mon IP

**Justification** :
- ✅ **Sécurité** : Accès SSH restreint à mon IP
- ✅ **Fonctionnalité** : Tous les ports nécessaires sont ouverts
- ✅ **Minimalisme** : Pas de ports inutiles ouverts

**Alternatives envisagées** :
- Autoriser SSH depuis n'importe où (moins sécurisé)
- Utiliser des VPC Peering pour la communication interne (plus complexe)

**Impact** : Si votre IP change, il faudra mettre à jour les Security Groups.

---

### **2. Configuration de NGINX**

**Contexte** : NGINX doit servir une page web statique.

**Décision** : 
- **Page statique** : Simple page HTML avec des informations sur le serveur
- **Configuration de base** : Fichier de configuration standard avec optimisations
- **Gzip** : Activation de la compression Gzip
- **Cache** : Configuration du cache pour les fichiers statiques

**Justification** :
- ✅ **Simplicité** : Une page statique suffit pour démontrer le fonctionnement
- ✅ **Performances** : Gzip et cache améliorent les performances
- ✅ **Pédagogie** : Permet de comprendre la configuration de NGINX

**Alternatives envisagées** :
- **Page dynamique** : Utiliser PHP ou Node.js (plus complexe, non nécessaire)
- **Reverse Proxy** : Configurer NGINX comme reverse proxy (pour l'Exercice 3)

**Impact** : La configuration peut être étendue pour des cas d'usage plus avancés.

---

### **3. Configuration d'OpenSearch**

**Contexte** : OpenSearch doit être configuré pour un environnement de test.

**Décision** : 
- **Single-node** : Un seul nœud (Master + Data)
- **Sécurité désactivée** : Pas d'authentification ni de chiffrement
- **Index par jour** : Un index par jour pour les logs (`logs-nginx-%{+YYYY.MM.dd}`)

**Justification** :
- ✅ **Simplicité** : Un seul nœud suffit pour un environnement de test
- ✅ **Facilité** : Pas de configuration complexe de sécurité
- ✅ **Organisation** : Un index par jour permet une bonne gestion des logs

**Alternatives envisagées** :
- **Multi-nodes** : 3 nœuds (1 Master, 2 Data) pour la haute disponibilité
- **Sécurité activée** : Avec authentification et chiffrement TLS

**Impact** : Pour un environnement de production, il faudrait activer la sécurité et utiliser plusieurs nœuds.

---

### **4. Configuration de Logstash**

**Contexte** : Logstash doit traiter les logs NGINX avant de les envoyer à OpenSearch.

**Décision** : 
- **Pipeline simple** : Input (Beats), Filter (Grok + Mutate), Output (OpenSearch)
- **Parsing des logs** : Utilisation de Grok pour parser les logs NGINX
- **Enrichissement** : Ajout de champs (environment, source_type)

**Justification** :
- ✅ **Flexibilité** : Le pipeline peut être étendu facilement
- ✅ **Standardisation** : Les logs sont parsés et structurés avant indexation
- ✅ **Extensibilité** : Facile d'ajouter d'autres filtres ou transformations

**Alternatives envisagées** :
- **Parsing JSON** : Si les logs étaient déjà en JSON
- **Utilisation de plugins** : GeoIP, User-Agent, etc. (non nécessaire pour ce projet)

**Impact** : Le pattern Grok doit être adapté si le format des logs NGINX change.

---

### **5. Configuration de HAProxy**

**Contexte** : HAProxy doit répartir la charge entre les serveurs NGINX.

**Décision** : 
- **Algorithme Round Robin** : Répartition équilibrée entre les serveurs
- **Health Checks** : Vérification de la santé des serveurs
- **Ports standard** : HTTP (80) et HTTPS (443)
- **Statistiques** : Activation de l'interface de statistiques (port 8404)

**Justification** :
- ✅ **Simplicité** : Round Robin est simple et efficace
- ✅ **Fiabilité** : Les health checks permettent de détecter les serveurs en panne
- ✅ **Monitoring** : Les statistiques permettent de surveiller le Load Balancer

**Alternatives envisagées** :
- **Algorithme Leastconn** : Répartition basée sur le nombre de connexions
- **Algorithme Source** : Répartition basée sur l'IP source (pour la persistance de session)
- **SSL Termination** : Terminer le SSL sur HAProxy (plus complexe)

**Impact** : L'algorithme peut être changé facilement dans la configuration.

---

## 💰 **Décisions Financières**

### **1. Utilisation du Free Tier**

**Contexte** : AWS offre 12 mois de Free Tier pour les nouveaux comptes.

**Décision** : Utiliser le Free Tier **autant que possible**

**Justification** :
- ✅ **Économie** : Réduction significative des coûts
- ✅ **Apprentissage** : Permet de tester sans risque financier

**Moyens** :
- Utiliser des instances **t2.micro** (750h/mois gratuites)
- Limiter la durée d'utilisation des instances non éligibles
- Supprimer les ressources inutilisées

**Impact** : Coût estimé réduit à ~5-10€/mois au lieu de ~50-100€/mois.

---

### **2. Optimisation des Coûts**

**Contexte** : Même avec le Free Tier, il faut optimiser les coûts.

**Décision** : 
- **Éteindre les instances** quand elles ne sont pas utilisées
- **Utiliser des instances t2.micro** pour NGINX
- **Éviter le NAT Gateway** (économie de ~$36/mois)
- **Supprimer les ressources inutilisées** après chaque session

**Justification** :
- ✅ **Économie** : Réduction des coûts à quelques euros par mois
- ✅ **Responsabilité** : Bonne pratique DevOps

**Alternatives envisagées** :
- Utiliser des **Spot Instances** (moins chères, mais moins fiables)
- Utiliser des **Reserved Instances** (pour un usage long terme)

**Impact** : Coût total estimé pour le projet : ~20-30€ (au lieu de ~100€+).

---

## 🔧 **Décisions de Dépannage**

### **1. Problème : OpenSearch ne démarre pas**

**Contexte** : Lors du déploiement d'OpenSearch, le service ne démarrait pas.

**Décision** : Augmenter les limites système (nofile et memlock)

**Justification** :
- OpenSearch nécessite des limites élevées pour fonctionner correctement
- Les valeurs par défaut sont trop basses pour un moteur de recherche

**Solution appliquée** :
```bash
# Augmenter la limite de fichiers ouverts
echo "opensearch soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "opensearch hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Augmenter la mémoire virtuelle
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Impact** : OpenSearch a démarré avec succès après cette modification.

---

### **2. Problème : Filebeat ne se connecte pas à Logstash**

**Contexte** : Filebeat ne parvenait pas à envoyer les logs à Logstash.

**Décision** : Vérifier et corriger les règles du Security Group

**Justification** :
- Le Security Group d'OpenSearch ne permettait pas le trafic entrant sur le port 5044 depuis les serveurs NGINX
- Il fallait autoriser le trafic entre les Security Groups

**Solution appliquée** :
```hcl
# Dans terraform/exercice-2/main.tf
resource "aws_security_group" "opensearch_sg" {
  # ...
  
  # Autoriser Logstash (port 5044) depuis NGINX
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    security_groups = [data.aws_security_group.existing_nginx_sg.id]
  }
  
  # ...
}
```

**Impact** : Filebeat a pu se connecter à Logstash après la mise à jour du Security Group.

---

### **3. Problème : Parsing des logs NGINX incorrect**

**Contexte** : Les logs NGINX n'étaient pas correctement parsés par Logstash.

**Décision** : Corriger le pattern Grok dans la configuration Logstash

**Justification** :
- Le pattern Grok initial ne correspondait pas au format des logs NGINX
- Il fallait adapter le pattern pour matcher le format par défaut de NGINX

**Solution appliquée** :
```conf
# Dans ansible/roles/logstash/templates/logstash.conf.j2
filter {
  grok {
    match => { "message" => "%{IPORHOST:client_ip} - %{DATA:remote_user} \[%{HTTPDATE:timestamp}\] \"%{WORD:method} %{URIPATHPARAM:request} HTTP/%{NUMBER:http_version}\" %{NUMBER:status} %{NUMBER:bytes_sent} \"%{DATA:referrer}\" \"%{DATA:user_agent}\"" }
    remove_tag => ["_grokparsefailure"]
  }
  
  # ...
}
```

**Impact** : Les logs sont maintenant correctement parsés et structurés dans OpenSearch.

---

## 📊 **Bilan des Décisions**

### **Décisions Majeures**

| Décision | Impact | Justification |
|----------|--------|---------------|
| Région AWS eu-west-3 | Faible | Proximité géographique |
| t2.micro pour NGINX | Moyen | Coût et Free Tier |
| t3.medium pour OpenSearch | Moyen | Mémoire suffisante |
| OpenSearch au lieu d'Elasticsearch | Faible | Open Source |
| Filebeat → Logstash → OpenSearch | Moyen | Flexibilité |
| Security Groups restrictifs | Élevé | Sécurité |

### **Décisions Mineures**

| Décision | Impact | Justification |
|----------|--------|---------------|
| Single-node OpenSearch | Faible | Simplicité |
| Sécurité désactivée | Faible | Environnement de test |
| Round Robin pour HAProxy | Faible | Simplicité |
| Gzip activé sur NGINX | Faible | Performances |

---

## 🎯 **Leçons Apprises**

1. **L'importance de la planification** : Une bonne architecture en amont évite des problèmes complexes plus tard.
2. **La flexibilité des outils** : Terraform et Ansible permettent une grande flexibilité dans la configuration.
3. **L'importance des tests** : Tester chaque étape avant de passer à la suivante évite des problèmes de dépannage complexes.
4. **La gestion des coûts** : Même avec le Free Tier, il faut surveiller ses dépenses AWS.
5. **La documentation** : Documenter ses décisions et ses problèmes permet de mieux comprendre son travail et de le partager.

---

## 📌 **Conseils pour Remplir ce Fichier**

1. **Soyez précis** : Décrivez exactement ce que vous avez décidé
2. **Soyez honnête** : Notez aussi les décisions qui n'ont pas fonctionné
3. **Expliquez le contexte** : Pourquoi cette décision était nécessaire ?
4. **Comparez les alternatives** : Quelles autres options avez-vous envisagées ?
5. **Notez l'impact** : Quel est l'impact de votre décision ?

---

**Bonne documentation !** ✅

> *"Une bonne décision est basée sur des connaissances, pas sur des suppositions."* — **Anonyme**
