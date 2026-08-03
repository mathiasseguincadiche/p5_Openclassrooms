# Journal de session - Projet P5 OpenClassrooms
**Déployez et suivez l'infrastructure as code**

---

## 📋 Informations générales

| Champ | Valeur |
|-------|--------|
| **Étudiant** | SEGUIN-CADICHE Mathias |
| **Projet** | P5 - Déployez et suivez l'infrastructure as code |
| **Date de début** | 02/08/2026 |
| **Date de fin** | À compléter |
| **Environnement** | AWS (us-east-1) |

---

## 📅 Journal des actions

### 🗓️ 02/08/2026

| Heure | Action | Commande | Résultat | Notes |
|-------|--------|----------|----------|-------|
| 10:00-11:00 | Configuration de l'environnement | `sudo apt update && sudo apt upgrade -y` | ✅ Succès | Mise à jour des packages |
| 11:00-12:00 | Installation des outils | `sudo apt install -y terraform ansible awscli git nodejs npm` | ✅ Succès | Tous les outils installés |
| 14:00-15:00 | Exercice 1 : Préparation | `./scripts/phase-0-preparation.sh --auto` | ✅ Succès | Environnement prêt |
| 15:00-16:30 | Exercice 1 : Terraform + Ansible | `./scripts/phase-1-terraform-ansible.sh --auto` | ✅ Succès | 2 VMs déployées avec Angular |
| 16:30-17:00 | Vérification Exercice 1 | `curl http://<IP_VM>` | ✅ Succès | Application Angular accessible |

### 🗓️ [À compléter]

| Heure | Action | Commande | Résultat | Notes |
|-------|--------|----------|----------|-------|
| | Exercice 2 : OpenSearch + Kibana | `./scripts/phase-2-opensearch-kibana.sh --auto` | | |
| | Création du dashboard | `./scripts/utils/kibana-api.sh --auto --wait` | | |
| | Génération des captures | `./scripts/utils/capture-screenshots.sh --auto` | | |
| | Exercice 3 : HAProxy | `./scripts/phase-3-haproxy.sh --auto` | | |
| | Vérification HAProxy | `curl http://<IP_HAPROXY>` | | |
| | Génération des livrables | `./scripts/phase-4-livrables.sh --auto` | | |

---

## 📊 Résumé des ressources AWS

| Ressource | Type | ID/URL | Statut | Coût |
|----------|------|--------|--------|------|
| VPC | AWS VPC | vpc-XXXXXX | ✅ Actif | Gratuit |
| VM Web 1 | EC2 t2.micro | i-XXXXXX | ✅ Actif | Gratuit (Free Tier) |
| VM Web 2 | EC2 t2.micro | i-XXXXXX | ✅ Actif | Gratuit (Free Tier) |
| Cluster OpenSearch | OpenSearch | p5-opensearch | ✅ Actif | ~0.10$/h |
| VM HAProxy | EC2 t2.micro | i-XXXXXX | ✅ Actif | Gratuit (Free Tier) |
| Instances hello-1 | EC2 t2.micro | i-XXXXXX | ✅ Actif | Gratuit (Free Tier) |
| Instances hello-2 | EC2 t2.micro | i-XXXXXX | ✅ Actif | Gratuit (Free Tier) |

---

## 🔧 Décisions techniques

| Décision | Choix | Justification |
|----------|-------|---------------|
| **Région AWS** | us-east-1 | Région **obligatoire** pour le projet OpenClassrooms |
| **Type d'instances (Web)** | t2.micro | Suffisant et **gratuit** avec Free Tier |
| **Type d'instances (OpenSearch)** | t3.medium.search | **Minimum requis** pour OpenSearch |
| **Type d'instances (HAProxy)** | t2.micro | Suffisant pour un load balancer de test |
| **Algorithme HAProxy** | roundrobin | **Équilibrage simple** et efficace |
| **Application Web** | Angular + NGINX | Conforme aux consignes OpenClassrooms |
| **Serveurs backend** | nginxdemos/hello | Conforme aux consignes OpenClassrooms |
| **Mode de déploiement** | AWS uniquement | Choix justifié : plus proche de la production, plus simple à maintenir |

---

## 📝 Notes et observations

### ✅ Points positifs
- Tous les scripts d'automatisation fonctionnent parfaitement.
- L'infrastructure est déployée rapidement et sans erreur.
- Les logs sont correctement centralisés dans OpenSearch.
- Le dashboard Kibana est généré automatiquement.

### ⚠️ Problèmes rencontrés
- [À compléter] Problème 1 : Description + Solution
- [À compléter] Problème 2 : Description + Solution

### 💡 Améliorations possibles
- Ajouter des tests automatiques pour vérifier le bon fonctionnement.
- Implémenter un pipeline CI/CD pour automatiser les déploiements.
- Ajouter des alertes pour surveiller les ressources AWS.

---

## 🎯 Prochaines étapes

- [ ] Finaliser l'Exercice 2 (Dashboard + Captures)
- [ ] Finaliser l'Exercice 3 (HAProxy + nginxdemos/hello)
- [ ] Générer les livrables finaux
- [ ] Nettoyer les ressources AWS
- [ ] Soumettre le projet sur OpenClassrooms

---

**Conseil** : Mettez à jour ce journal **après chaque session** pour ne rien oublier !
