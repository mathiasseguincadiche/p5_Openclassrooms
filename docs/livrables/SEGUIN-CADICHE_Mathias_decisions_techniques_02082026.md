# Décisions techniques - Projet P5 OpenClassrooms
**Déployez et suivez l'infrastructure as code**

---

## 🏗️ Architecture

| Décision | Choix | Justification | Alternatives envisagées |
|----------|-------|---------------|---------------------------|
| **Région AWS** | us-east-1 | Région **obligatoire** pour le projet OpenClassrooms | Aucune (imposé par le projet) |
| **Type d'instances (Web)** | t2.micro | Suffisant et **gratuit** avec Free Tier | t3.micro (plus puissant mais payant) |
| **Type d'instances (OpenSearch)** | t3.medium.search | **Minimum requis** pour OpenSearch | t3.small.search (insuffisant) |
| **Type d'instances (HAProxy)** | t2.micro | Suffisant pour un load balancer de test | t3.micro (sur-dimensionné) |
| **Algorithme HAProxy** | roundrobin | **Équilibrage simple** et efficace | leastconn, source, uri |

---

## 🛠️ Outils

| Outil | Version | Justification | Alternatives |
|-------|---------|---------------|--------------|
| **Terraform** | v1.15+ | Version **stable et compatible** avec AWS | Terragrunt, Pulumi |
| **Ansible** | 2.15+ | Version **moderne** avec support complet | Chef, Puppet |
| **AWS CLI** | 2.x.x | Version **récente** avec toutes les commandes | AWS CloudShell |
| **OpenSearch** | 2.x | Version **compatible** avec Kibana | Elasticsearch (non conforme OC) |
| **Kibana** | 2.x | Intégré à OpenSearch | Grafana (alternative) |
| **HAProxy** | 2.6+ | Version **stable** et performante | NGINX (load balancing) |

---

## 🌐 Décisions pour l'Exercice 1 (Terraform + Ansible + Angular)

| Décision | Choix | Justification | Alternatives |
|----------|-------|---------------|--------------|
| **Application Web** | Angular | **Conforme aux consignes** OpenClassrooms | React, Vue.js |
| **Serveur Web** | NGINX | **Standard industriel**, performant et léger | Apache |
| **Méthode de déploiement** | Ansible | **Automatisation complète** | Manuel (SSH) |
| **Configuration NGINX** | Fichier statique | Simple et efficace | Template dynamique |
| **Build Angular** | npm run build --prod | **Optimisé pour la production** | ng serve (dev) |

---

## 📊 Décisions pour l'Exercice 2 (OpenSearch + Kibana + Dashboard)

| Décision | Choix | Justification | Alternatives |
|----------|-------|---------------|--------------|
| **Service de logs** | OpenSearch | **Conforme aux consignes** OpenClassrooms | ELK Stack |
| **Index pattern** | nginx-access* | **Correspond aux logs** NGINX | custom-* |
| **Champ de temps** | @timestamp | **Standard** pour les logs | date, timestamp |
| **Diagramme 1** | Donut (Répartition des verbes HTTP) | **Obligatoire** pour OpenClassrooms | Bar chart |
| **Diagramme 2** | Histogram (Quantité par 12h) | **Obligatoire** pour OpenClassrooms | Line chart |
| **Diagramme 3** | Histogram cumulé (Top 5 requêtes) | **Obligatoire** pour OpenClassrooms | Area chart |
| **Méthode de création** | API OpenSearch | **Automatisée** via kibana-api.sh | Manuelle |

---

## ⚖️ Décisions pour l'Exercice 3 (HAProxy + nginxdemos/hello)

| Décision | Choix | Justification | Alternatives |
|----------|-------|---------------|--------------|
| **Application backend** | nginxdemos/hello | **Conforme aux consignes** OpenClassrooms | NGINX standard |
| **Nombre de serveurs** | 2 | **Équilibrage de charge** efficace | 1 (pas de HA), 3+ (sur-dimensionné) |
| **Algorithme** | roundrobin | **Simple et efficace** | leastconn, source |
| **Port HAProxy** | 80 | **Standard HTTP** | 8080, 8000 |
| **Port stats** | 8404 | **Non standard** (évite les conflits) | 8080, 1936 |
| **Authentification stats** | admin:P5OpenClassrooms2026 | **Sécurisé** | Pas d'auth (non sécurisé) |

---

## 🔄 Décisions pour l'automatisation

| Décision | Choix | Justification | Alternatives |
|----------|-------|---------------|--------------|
| **Script principal** | run-all.sh | **Exécution complète** en une commande | Exécution manuelle |
| **Mode par défaut** | Interactif | **Sécurité** (confirmation à chaque étape) | Automatique |
| **Logging** | Fichiers dans /tmp/p5_logs/ | **Traçabilité** complète | Pas de logs |
| **Gestion d'erreur** | Arrêt automatique | **Évite les erreurs en cascade** | Continuer |
| **Health checks** | Script dédié | **Vérification pré-exécution** | Pas de vérification |

---

## 💰 Décisions financières

| Décision | Choix | Justification | Coût estimé |
|----------|-------|---------------|-------------|
| **Free Tier AWS** | Oui | **Gratuit** pour les 12 premiers mois | 0$ |
| **OpenSearch** | t3.medium.search | **Minimum requis** | ~0.10$/h |
| **Autres ressources** | t2.micro | **Gratuit** avec Free Tier | 0$ |
| **Nettoyage automatique** | Oui | **Évite les coûts inutiles** | Économies |

---

## 📚 Décisions personnelles

| Décision | Choix | Justification | Apprentissage |
|----------|-------|---------------|--------------|
| **Mode de déploiement** | AWS uniquement | **Plus proche de la production** | Moins de complexité |
| **Automatisation** | 100% | **Gain de temps** et **réduction des erreurs** | Meilleure compréhension des outils |
| **Documentation** | Complète | **Facilite la maintenance** | Meilleure organisation |
| **Nommage des ressources** | Préfixe p5- | **Clarté** et **évite les conflits** | Bonne pratique DevOps |

---

## 🎯 Justification du choix AWS-only

> **Pourquoi j'ai choisi de me concentrer sur AWS plutôt que Docker ?**

1. **Conformité avec les consignes** : OpenClassrooms demande explicitement l'utilisation d'AWS pour les exercices.
2. **Expérience production** : AWS est plus proche d'un environnement réel que Docker local.
3. **Simplicité** : Moins de complexité à gérer (pas besoin de configurer Docker, KVM, etc.).
4. **Reproductibilité** : Plus facile à reproduire sur n'importe quelle machine avec AWS CLI.
5. **Free Tier** : Permet de tester gratuitement pendant 12 mois.

**Inconvénients** :
- Moins flexible pour les tests locaux.
- Nécessite une connexion internet.
- Coût potentiel si on oublie de nettoyer.

**Solution alternative** : Si nécessaire, Docker peut être ajouté ultérieurement comme option supplémentaire.

---

## 🔧 Bonnes pratiques appliquées

✅ **Infrastructure as Code** : Tout est défini dans du code (Terraform, Ansible).
✅ **Automatisation** : Tous les processus répétitifs sont automatisés.
✅ **Modularité** : Chaque exercice est indépendant et peut être exécuté séparément.
✅ **Documentation** : Chaque décision est justifiée et documentée.
✅ **Sécurité** : Mots de passe, clés, et informations sensibles ne sont pas stockés dans le code.
✅ **Nettoyage** : Script de nettoyage fourni pour éviter les coûts inutiles.

---

**Conseil** : Documentez **toutes vos décisions techniques** ici pour justifier vos choix lors de l'évaluation.
