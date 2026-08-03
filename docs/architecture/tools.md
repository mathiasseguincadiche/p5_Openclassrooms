# 🛠️ Présentation des Outils par Catégorie - P5 OpenClassrooms

**Ce document détaille chaque outil utilisé dans le projet P5**, organisé par **catégorie** (Conteneurisation, CI/CD, Configuration Management, etc.). Pour chaque outil, vous trouverez :
- Une **description** de son rôle.
- Ses **avantages et inconvénients**.
- Des **cas d'usage concrets** dans le projet.
- Des **liens vers la documentation et les ressources**.

---

## 📌 Table des Matières

1. [📦 Conteneurisation](#-conteneurisation)
2. [🚀 CI/CD (Intégration et Livraison Continues)](#-cicd-intégration-et-livraison-continues)
3. [🔧 Configuration Management](#-configuration-management)
4. [☁️ Infrastructure as Code (IaC)](#-infrastructure-as-code-iac)
5. [🐳 Orchestration de Conteneurs](#-orchestration-de-conteneurs)
6. [📊 Monitoring et Observabilité](#-monitoring-et-observabilité)
7. [🔒 Sécurité](#-sécurité)
8. [📜 Résumé par Exercice](#-résumé-par-exercice)

---

## 📦 Conteneurisation

### 🐳 Docker

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Plateforme open-source pour **conteneuriser** des applications et leurs dépendances.       |
| **Version**      | 24.x (recommandée)                                                                             |
| **Site Web**     | [docker.com](https://www.docker.com/)                                                         |
| **Documentation**| [docs.docker.com](https://docs.docker.com)                                                   |
| **Licence**      | Open Source (Apache 2.0)                                                                      |

#### ✅ Avantages
- **Isolation** : Chaque conteneur est isolé des autres et de l'hôte.
- **Portabilité** : Fonctionne de la même manière sur n'importe quel système (Linux, Windows, macOS).
- **Léger** : Les conteneurs partagent le noyau de l'hôte, contrairement aux machines virtuelles.
- **Rapide** : Démarrage en quelques secondes.
- **Écosystème** : Accès à des milliers d'images prêtes à l'emploi sur [Docker Hub](https://hub.docker.com).

#### ❌ Inconvénients
- **Sécurité** : Les conteneurs partagent le noyau de l'hôte (risque de vulnérabilités).
- **Pas de scaling natif** : Nécessite un outil comme Kubernetes pour le scaling.
- **Stockage** : Les données dans un conteneur sont éphémères (nécessite des volumes).

#### 🎯 Cas d'Usage dans le Projet
| **Exercice** | **Utilisation**                                                                               |
|--------------|-----------------------------------------------------------------------------------------------|
| Exercice 1   | Conteneuriser une application Node.js et la déployer localement.                          |
| Exercice 2   | Construire une image Docker et la pousser vers Docker Hub via GitHub Actions.              |
| Exercice 5   | Créer des images Docker pour les conteneurs Kubernetes.                                    |

#### 📚 Ressources
- [Docker pour Débutants](https://docker-curriculum.com/)
- [Docker Cheatsheet](../cheatsheets/docker.md)
- [Template Dockerfile](../../../TEMPLATES/docker/Dockerfile.nodejs)

---

### Docker Compose

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Outil pour définir et gérer des **applications multi-conteneurs** via un fichier YAML.      |
| **Version**      | 2.x (recommandée)                                                                             |
| **Site Web**     | [docker.com](https://www.docker.com/products/docker-compose)                                |
| **Documentation**| [docs.docker.com/compose](https://docs.docker.com/compose/)                                |
| **Licence**      | Open Source (Apache 2.0)                                                                      |

#### ✅ Avantages
- **Simplicité** : Définir une stack complète dans un seul fichier (`docker-compose.yml`).
- **Isolation** : Chaque service tourne dans son propre conteneur.
- **Réseautage** : Les conteneurs peuvent communiquer entre eux via un réseau dédié.
- **Volumes** : Gestion simplifiée des volumes partagés.

#### ❌ Inconvénients
- **Limité à un seul hôte** : Ne fonctionne pas pour des déploiements multi-serveurs.
- **Pas pour la production** : Principalement conçu pour le développement et les tests.

#### 🎯 Cas d'Usage dans le Projet
| **Exercice** | **Utilisation**                                                                               |
|--------------|-----------------------------------------------------------------------------------------------|
| Exercice 1   | Déployer une application avec une base de données et un backend.                          |

#### 📚 Ressources
- [Documentation Officielle](https://docs.docker.com/compose/)
- [Exemple de `docker-compose.yml`](https://docs.docker.com/compose/gettingstarted/)
- [Template Docker Compose](../../../TEMPLATES/docker/docker-compose.yml)

---

## 🚀 CI/CD (Intégration et Livraison Continues)

### GitHub Actions

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Plateforme de **CI/CD** intégrée à GitHub pour automatiser des workflows.                  |
| **Version**      | - (intégré à GitHub)                                                                           |
| **Site Web**     | [github.com/features/actions](https://github.com/features/actions)                         |
| **Documentation**| [docs.github.com/actions](https://docs.github.com/en/actions)                              |
| **Licence**      | Gratuit pour les dépôts publics, minutes limitées pour les dépôts privés.                  |

#### ✅ Avantages
- **Intégré à GitHub** : Pas besoin de configurer un outil externe.
- **Facile à utiliser** : Syntaxe YAML simple et marketplace d'actions prêtes à l'emploi.
- **Évolutif** : Peut gérer des workflows complexes avec des jobs parallèles.
- **Sécurisé** : Secrets gérés nativement par GitHub.

#### ❌ Inconvénients
- **Limité à GitHub** : Ne fonctionne pas avec d'autres forges (GitLab, Bitbucket).
- **Coût** : Les minutes d'exécution sont limitées pour les dépôts privés.
- **Lenteur** : Les runners GitHub peuvent être lents pour des workflows complexes.

#### 🎯 Cas d'Usage dans le Projet
| **Exercice** | **Utilisation**                                                                               |
|--------------|-----------------------------------------------------------------------------------------------|
| Exercice 2   | Automatiser les tests et le déploiement d'une application Node.js.                        |

#### 📚 Ressources
- [Documentation Officielle](https://docs.github.com/en/actions)
- [Marketplace d'Actions](https://github.com/marketplace?type=actions)
- [Template CI Node.js](../../../TEMPLATES/github-actions/ci-nodejs.yml)
- [Template CD AWS](../../../TEMPLATES/github-actions/cd-aws.yml)

---

## 🔧 Configuration Management

### Ansible

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Outil d'**automatisation de la configuration** et de **gestion de l'infrastructure**.       |
| **Version**      | 8.x (recommandée)                                                                             |
| **Site Web**     | [ansible.com](https://www.ansible.com/)                                                       |
| **Documentation**| [docs.ansible.com](https://docs.ansible.com)                                                 |
| **Licence**      | Open Source (GPLv3)                                                                           |

#### ✅ Avantages
- **Agentless** : Pas besoin d'installer un agent sur les machines cibles.
- **Idempotent** : Une tâche exécutée plusieurs fois donne le même résultat.
- **Simple** : Syntaxe YAML facile à lire et à écrire.
- **Modulaire** : Utilisation de modules pour des tâches réutilisables.
- **Puissant** : Gère des milliers de nœuds.

#### ❌ Inconvénients
- **Lenteur** : Peut être lent pour des déploiements à grande échelle.
- **SSH** : Nécessite un accès SSH aux machines cibles.
- **Courbe d'apprentissage** : Les concepts (playbooks, rôles, etc.) peuvent être complexes pour les débutants.

#### 🎯 Cas d'Usage dans le Projet
| **Exercice** | **Utilisation**                                                                               |
|--------------|-----------------------------------------------------------------------------------------------|
| Exercice 3   | Configurer des serveurs pour déployer une application.                                      |

#### 📚 Ressources
- [Documentation Officielle](https://docs.ansible.com)
- [Ansible pour Débutants](https://www.ansible.com/resources/get-started)
- [Galerie de Modules](https://galaxy.ansible.com/)
- [Template Playbook](../../../TEMPLATES/ansible/playbook.yml)
- [Template Inventory](../../../TEMPLATES/ansible/inventory.ini)

---

## ☁️ Infrastructure as Code (IaC)

### Terraform

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Outil pour **provisionner** et **gérer** une infrastructure cloud de manière déclarative.     |
| **Version**      | 1.5.x (recommandée)                                                                           |
| **Site Web**     | [terraform.io](https://www.terraform.io/)                                                     |
| **Documentation**| [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform)             |
| **Licence**      | Open Source (MPL 2.0)                                                                         |

#### ✅ Avantages
- **Multi-cloud** : Fonctionne avec AWS, Azure, GCP, et bien d'autres.
- **Déclaratif** : Définissez l'état souhaité, Terraform se charge du reste.
- **Versionnable** : Les fichiers `.tf` peuvent être versionnés avec Git.
- **Modulaire** : Réutilisez du code avec des modules.
- **Planification** : `terraform plan` montre les changements avant application.

#### ❌ Inconvénients
- **Courbe d'apprentissage** : Les concepts (state, providers, etc.) peuvent être complexes.
- **State File** : Le fichier `terraform.tfstate` doit être géré avec soin.
- **Pas de rollback automatique** : Nécessite une gestion manuelle en cas d'erreur.

#### 🎯 Cas d'Usage dans le Projet
| **Exercice** | **Utilisation**                                                                               |
|--------------|-----------------------------------------------------------------------------------------------|
| Exercice 4   | Provisionner une infrastructure AWS (VPC, EC2, Security Groups, etc.).                     |

#### 📚 Ressources
- [Documentation Officielle](https://developer.hashicorp.com/terraform)
- [Registry de Modules Terraform](https://registry.terraform.io/)
- [Tutoriel Terraform](https://learn.hashicorp.com/terraform)
- [Template main.tf](../../../TEMPLATES/terraform/main.tf)
- [Template variables.tf](../../../TEMPLATES/terraform/variables.tf)

---

## 🐳 Orchestration de Conteneurs

### Kubernetes

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Plateforme open-source pour **orchestrer** des conteneurs à grande échelle.               |
| **Version**      | 1.28.x (recommandée)                                                                           |
| **Site Web**     | [kubernetes.io](https://kubernetes.io/)                                                       |
| **Documentation**| [kubernetes.io/docs](https://kubernetes.io/docs/home/)                                       |
| **Licence**      | Open Source (Apache 2.0)                                                                      |

#### ✅ Avantages
- **Scalable** : Gère des milliers de conteneurs sur des centaines de nœuds.
- **Résilient** : Auto-réparation (redémarrage des conteneurs en échec).
- **Portable** : Fonctionne sur n'importe quel cloud ou on-premise.
- **Écosystème** : Richesse des outils (Helm, Istio, Prometheus, etc.).
- **Déclaratif** : Définissez l'état souhaité, Kubernetes se charge du reste.

#### ❌ Inconvénients
- **Complexité** : Courbe d'apprentissage raide.
- **Lourd** : Nécessite des ressources importantes pour le cluster.
- **Configuration** : Les manifests YAML peuvent être verbeux.

#### 🎯 Cas d'Usage dans le Projet
| **Exercice** | **Utilisation**                                                                               |
|--------------|-----------------------------------------------------------------------------------------------|
| Exercice 5   | Déployer une application sur un cluster Kubernetes local (Minikube/Kind).                  |

#### 📚 Ressources
- [Documentation Officielle](https://kubernetes.io/docs/home/)
- [Tutoriel Kubernetes](https://kubernetes.io/docs/tutorials/)
- [Kubernetes Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Template Deployment](../../../TEMPLATES/kubernetes/deployment.yaml)
- [Template Service](../../../TEMPLATES/kubernetes/service.yaml)

---

## 📊 Monitoring et Observabilité

### Prometheus

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Système de **surveillance** et d'**alerte** pour les métriques.                              |
| **Version**      | 2.x (recommandée)                                                                             |
| **Site Web**     | [prometheus.io](https://prometheus.io/)                                                       |
| **Documentation**| [prometheus.io/docs](https://prometheus.io/docs/introduction/overview/)                   |
| **Licence**      | Open Source (Apache 2.0)                                                                      |

#### ✅ Avantages
- **Pull-based** : Prometheus récupère les métriques depuis les cibles.
- **Flexible** : Langage de requête puissant (PromQL).
- **Écosystème** : Intégrations avec Grafana, Alertmanager, etc.

#### ❌ Inconvénients
- **Complexité** : Configuration avancée nécessaire pour les alertes.
- **Stockage** : Nécessite une gestion du stockage des métriques.

#### 🎯 Cas d'Usage dans le Projet
- **Optionnel** : Peut être utilisé pour surveiller les applications déployées.

#### 📚 Ressources
- [Documentation Officielle](https://prometheus.io/docs/introduction/overview/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

### Grafana

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Outil de **visualisation** pour les métriques (Prometheus, InfluxDB, etc.).                   |
| **Version**      | 10.x (recommandée)                                                                            |
| **Site Web**     | [grafana.com](https://grafana.com/)                                                          |
| **Documentation**| [grafana.com/docs](https://grafana.com/docs/)                                                |
| **Licence**      | Open Source (AGPLv3) / Enterprise (payant)                                                   |

#### ✅ Avantages
- **Visualisation** : Tableaux de bord interactifs et personnalisables.
- **Intégrations** : Plugins pour de nombreuses sources de données.
- **Alertes** : Configuration d'alertes basées sur les métriques.

#### ❌ Inconvénients
- **Ressources** : Peut consommer beaucoup de mémoire pour les grands tableaux de bord.

#### 🎯 Cas d'Usage dans le Projet
- **Optionnel** : Peut être utilisé pour visualiser les métriques Prometheus.

#### 📚 Ressources
- [Documentation Officielle](https://grafana.com/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

---

## 🔒 Sécurité

### HashiCorp Vault

| **Aspect**       | **Détails**                                                                                     |
|------------------|-----------------------------------------------------------------------------------------------|
| **Description**  | Outil pour **gérer les secrets** (mots de passe, clés API, certificats, etc.).                 |
| **Version**      | 1.13.x (recommandée)                                                                          |
| **Site Web**     | [vaultproject.io](https://www.vaultproject.io/)                                               |
| **Documentation**| [developer.hashicorp.com/vault](https://developer.hashicorp.com/vault)                     |
| **Licence**      | Open Source (MPL 2.0) / Enterprise (payant)                                                   |

#### ✅ Avantages
- **Centralisé** : Stockez tous vos secrets au même endroit.
- **Sécurisé** : Chiffrement des secrets au repos et en transit.
- **Audit** : Journalisation de tous les accès aux secrets.
- **Intégrations** : Plugins pour AWS, Kubernetes, etc.

#### ❌ Inconvénients
- **Complexité** : Configuration avancée nécessaire.
- **Coût** : La version Enterprise est payante pour certaines fonctionnalités.

#### 🎯 Cas d'Usage dans le Projet
- **Optionnel** : Peut être utilisé pour gérer les secrets des applications.

#### 📚 Ressources
- [Documentation Officielle](https://developer.hashicorp.com/vault)
- [Vault Tutorial](https://learn.hashicorp.com/vault)

---

## 📜 Résumé par Exercice

| **Exercice** | **Outils Principaux** | **Outils Secondaires** | **Niveau** | **Durée Estimée** |
|--------------|------------------------|------------------------|------------|-------------------|
| 1 | Docker, Docker Compose | - | Débutant | 1h30 |
| 2 | GitHub Actions, Docker | - | Débutant/Intermédiaire | 2h |
| 3 | Ansible | SSH | Intermédiaire | 2h30 |
| 4 | Terraform | AWS/Azure/GCP | Intermédiaire | 3h |
| 5 | Kubernetes | Docker, Minikube/Kind | Avancé | 4h |

---

## 💡 Conseils pour Choisir les Outils

### Vous débutez ?
1. **Commencez par Docker** : Conteneurisez une application simple.
2. **Automatisez avec GitHub Actions** : Configurez un workflow CI/CD basique.
3. **Explorez Ansible** : Automatisez la configuration d'un serveur.

### Vous avez déjà de l'expérience ?
1. **Passez à Terraform** : Provisionnez une infrastructure cloud.
2. **Maîtrisez Kubernetes** : Déployez une application en production.
3. **Ajoutez du monitoring** : Configurez Prometheus et Grafana.

### Vous voulez aller plus loin ?
1. **Sécurisez votre infrastructure** : Utilisez Vault pour gérer les secrets.
2. **Optimisez vos déploiements** : Explorez Helm pour Kubernetes.
3. **Automatisez tout** : Combinez Terraform, Ansible, et Kubernetes.

---

## 📌 Résumé des Outils

| **Catégorie** | **Outil** | **Niveau** | **Lien** | **Template Disponible** |
|--------------|-----------|------------|----------|-------------------------|
| Conteneurisation | Docker | Débutant | [docker.com](https://www.docker.com) | ✅ |
| Conteneurisation | Docker Compose | Débutant | [docs.docker.com/compose](https://docs.docker.com/compose/) | ✅ |
| CI/CD | GitHub Actions | Débutant/Intermédiaire | [docs.github.com/actions](https://docs.github.com/en/actions) | ✅ |
| Configuration Management | Ansible | Intermédiaire | [docs.ansible.com](https://docs.ansible.com) | ✅ |
| IaC | Terraform | Intermédiaire | [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform) | ✅ |
| Orchestration | Kubernetes | Avancé | [kubernetes.io](https://kubernetes.io) | ✅ |
| Monitoring | Prometheus | Avancé | [prometheus.io](https://prometheus.io) | ❌ |
| Monitoring | Grafana | Avancé | [grafana.com](https://grafana.com) | ❌ |
| Sécurité | Vault | Avancé | [vaultproject.io](https://www.vaultproject.io) | ❌ |

---

**Prochaine étape** : [Découvrir les bonnes pratiques DevOps](../guides/best-practices.md) 🚀
