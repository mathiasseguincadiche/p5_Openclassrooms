# 📝 Journal de Session

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce fichier doit être **complété au fur et à mesure** de votre travail sur le projet. Il sert à :

✅ **Suivre votre progression**
✅ **Documenter les problèmes rencontrés** et leurs solutions
✅ **Noter les décisions prises**
✅ **Preuve de votre travail** pour l'évaluation

**Format recommandé** :
- **1 fichier par session** (ou par jour)
- **Structure claire** avec horodatages
- **Détails techniques** (commandes, erreurs, solutions)

---

## 📅 **Session 1 : [Date]**

### **🕒 Début : [HH:MM]**

**Objectif de la session** : [Exemple : Déployer l'infrastructure de base avec Terraform]

---

### **📋 Activités Réalisées**

#### **1. [Nom de l'activité]**

**Description** : [Décrivez ce que vous avez fait]

**Commandes exécutées** :
```bash
# Exemple :
cd terraform/exercice-1
terraform init
terraform plan
terraform apply
```

**Résultats** :
- [x] Terraform initialisé avec succès
- [x] Plan généré : 12 ressources à créer
- [x] Infrastructure déployée avec succès

**Problèmes rencontrés** : Aucun

---

#### **2. [Nom de l'activité]**

**Description** : [Décrivez ce que vous avez fait]

**Commandes exécutées** :
```bash
# Exemple :
ansible -i inventories/exercice-1.ini nginx_servers -m ping
ansible-playbook -i inventories/exercice-1.ini playbooks/deploy-nginx.yml
```

**Résultats** :
- [x] Connexion SSH testée avec succès
- [x] Playbook exécuté : 12 tâches, 10 changées
- [x] NGINX installé et configuré

**Problèmes rencontrés** :
- ❌ **Problème** : [Décrivez le problème]
  - **Symptômes** : [Décrivez les symptômes]
  - **Cause** : [Expliquez la cause]
  - **Solution** : [Décrivez la solution]
  - **Commandes de dépannage** :
    ```bash
    # Exemple :
    ssh -v -i ~/.ssh/p5-key ec2-user@<IP>
    tail -f /var/log/cloud-init.log
    ```
  - **Résultat** : [Problème résolu/non résolu]

---

### **📊 Bilan de la Session**

**Tâches complétées** :
- [x] Déploiement Terraform
- [x] Configuration Ansible
- [x] Déploiement NGINX
- [ ] Tests de vérification

**Tâches en cours** :
- [ ] [Nom de la tâche]

**Tâches restantes** :
- [ ] [Nom de la tâche]

**Durée** : [X] heures [Y] minutes

**Difficultés** : [Décrivez les principales difficultés rencontrées]

**Solutions trouvées** : [Décrivez comment vous avez résolu les problèmes]

---

### **🕒 Fin : [HH:MM]**

---

## 📅 **Session 2 : [Date]**

### **🕒 Début : [HH:MM]**

**Objectif de la session** : [Exemple : Déployer OpenSearch et configurer la stack ELK]

---

### **📋 Activités Réalisées**

#### **1. Déploiement OpenSearch avec Terraform**

**Description** : Création de l'infrastructure pour OpenSearch

**Commandes exécutées** :
```bash
cd terraform/exercice-2
terraform init
terraform plan
terraform apply
```

**Résultats** :
- [x] Security Group créé
- [x] Instance OpenSearch déployée
- [x] Elastic IP attachée

**Problèmes rencontrés** : Aucun

---

#### **2. Configuration d'OpenSearch avec Ansible**

**Description** : Installation et configuration d'OpenSearch et Logstash

**Commandes exécutées** :
```bash
ansible-playbook -i inventories/exercice-2.ini playbooks/deploy-opensearch.yml
```

**Résultats** :
- [x] OpenSearch installé
- [x] Logstash installé
- [x] Services démarrés

**Problèmes rencontrés** :
- ❌ **OpenSearch ne démarrait pas**
  - **Symptômes** : `Job for opensearch.service failed`
  - **Cause** : Limite de fichiers ouverts trop basse
  - **Solution** : Augmenter la limite dans `/etc/security/limits.conf`
  - **Commande** : `echo "opensearch soft nofile 65536" | sudo tee -a /etc/security/limits.conf`
  - **Résultat** : ✅ Problème résolu

---

#### **3. Déploiement de Filebeat**

**Description** : Installation de Filebeat sur les serveurs NGINX

**Commandes exécutées** :
```bash
ansible-playbook -i inventories/exercice-2.ini playbooks/deploy-filebeat.yml
```

**Résultats** :
- [x] Filebeat installé sur nginx-1
- [x] Filebeat installé sur nginx-2
- [x] Configuration pour Logstash

**Problèmes rencontrés** :
- ❌ **Filebeat ne se connectait pas à Logstash**
  - **Symptômes** : `Failed to connect to backoff(async(...))`
  - **Cause** : Security Group ne permettait pas le trafic sur le port 5044
  - **Solution** : Ajouter une règle dans le Security Group
  - **Résultat** : ✅ Problème résolu

---

### **📊 Bilan de la Session**

**Tâches complétées** :
- [x] Déploiement Terraform pour OpenSearch
- [x] Configuration OpenSearch + Logstash
- [x] Déploiement Filebeat
- [x] Vérification du flux de données

**Tâches en cours** :
- [ ] Configuration de Kibana

**Tâches restantes** :
- [ ] Création des visualisations
- [ ] Exercice 3 (HAProxy)

**Durée** : [X] heures [Y] minutes

**Difficultés** :
- Configuration des limites système pour OpenSearch
- Problèmes de connectivité entre Filebeat et Logstash

**Solutions trouvées** :
- Augmentation des limites de fichiers ouverts
- Correction des règles du Security Group

---

### **🕒 Fin : [HH:MM]**

---

## 📅 **Session 3 : [Date]**

### **🕒 Début : [HH:MM]**

**Objectif de la session** : [Exemple : Configurer HAProxy et finaliser le projet]

---

### **📋 Activités Réalisées**

#### **1. Déploiement HAProxy avec Terraform**

**Description** : Création de l'infrastructure pour HAProxy

**Commandes exécutées** :
```bash
cd terraform/exercice-3
terraform init
terraform plan
terraform apply
```

**Résultats** :
- [x] Instance HAProxy déployée
- [x] Security Group configuré
- [x] Elastic IP attachée

---

#### **2. Configuration HAProxy avec Ansible**

**Description** : Installation et configuration de HAProxy

**Commandes exécutées** :
```bash
ansible-playbook -i inventories/exercice-3.ini playbooks/deploy-haproxy.yml
```

**Résultats** :
- [x] HAProxy installé
- [x] Configuration pour NGINX-1 et NGINX-2
- [x] Service démarré

**Problèmes rencontrés** : Aucun

---

#### **3. Tests de Load Balancing**

**Description** : Vérification du fonctionnement de HAProxy

**Commandes exécutées** :
```bash
# Tester l'accès via HAProxy
curl http://<IP-HAPROXY>

# Vérifier les statistiques
curl http://<IP-HAPROXY>:8404

# Tester la tolérance aux pannes
# Arrêter NGINX-1 et vérifier que le site reste accessible
```

**Résultats** :
- [x] Accès via HAProxy fonctionne
- [x] Répartition de charge vérifiée
- [x] Tolérance aux pannes testée

---

### **📊 Bilan de la Session**

**Tâches complétées** :
- [x] Déploiement Terraform pour HAProxy
- [x] Configuration HAProxy
- [x] Tests de Load Balancing
- [x] Vérification complète

**Tâches en cours** : Aucun

**Tâches restantes** :
- [ ] Documentation finale
- [ ] Nettoyage des ressources

**Durée** : [X] heures [Y] minutes

**Difficultés** : Aucune

---

### **🕒 Fin : [HH:MM]**

---

## 📈 **Bilan Global**

### **Temps Total Passé**

| Session | Date | Durée | Tâches Complétées |
|---------|------|-------|-------------------|
| 1 | [Date] | [Durée] | [Liste] |
| 2 | [Date] | [Durée] | [Liste] |
| 3 | [Date] | [Durée] | [Liste] |
| **Total** | - | **[X] heures [Y] minutes** | **100%** |

### **Problèmes Rencontrés**

| Problème | Cause | Solution | Résolu |
|----------|-------|---------|--------|
| [Problème 1] | [Cause] | [Solution] | ✅/❌ |
| [Problème 2] | [Cause] | [Solution] | ✅/❌ |

### **Leçons Apprises**

1. **Terraform** : [Décrivez ce que vous avez appris]
2. **Ansible** : [Décrivez ce que vous avez appris]
3. **AWS** : [Décrivez ce que vous avez appris]
4. **OpenSearch/ELK** : [Décrivez ce que vous avez appris]
5. **HAProxy** : [Décrivez ce que vous avez appris]

### **Améliorations Possibles**

- [ ] [Amélioration 1]
- [ ] [Amélioration 2]
- [ ] [Amélioration 3]

---

## 📌 **Conseils pour Remplir ce Journal**

1. **Soyez précis** : Notez les commandes exactes que vous avez exécutées
2. **Soyez honnête** : Notez aussi les échecs et les problèmes
3. **Soyez détaillé** : Expliquez les solutions que vous avez trouvées
4. **Soyez régulier** : Mettez à jour le journal après chaque session
5. **Utilisez des captures** : Ajoutez des captures d'écran dans le dossier `captures/` si nécessaire

---

## 📎 **Annexes**

### **Captures d'Écran**

Les captures d'écran doivent être stockées dans le dossier `captures/` et référencées ici :

- [captures/exercice-1/terraform-apply.png](captures/exercice-1/terraform-apply.png) : Résultat de `terraform apply`
- [captures/exercice-1/nginx-page.png](captures/exercice-1/nginx-page.png) : Page NGINX affichée
- [captures/exercice-2/opensearch-dashboard.png](captures/exercice-2/opensearch-dashboard.png) : Tableau de bord Kibana

### **Fichiers de Configuration**

Les fichiers de configuration importants peuvent être référencés ici :

- [terraform/exercice-1/main.tf](terraform/exercice-1/main.tf) : Configuration Terraform
- [ansible/playbooks/deploy-nginx.yml](ansible/playbooks/deploy-nginx.yml) : Playbook Ansible

---

**Bonne documentation !** 📝

> *"Si vous ne le documentez pas, ça n'existe pas."* — **DevOps Proverb**
