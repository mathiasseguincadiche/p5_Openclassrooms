# Décisions techniques - Projet P5 OpenClassrooms

**Déployez et suivez l'infrastructure as code**

---

## 🏗️ Architecture

| Décision | Choix | Justification | Point d'attention |
|----------|-------|---------------|-------------------|
| **Région AWS** | `us-east-1` | Région imposée par le projet | Les paires de clés et AMI sont régionales |
| **Serveurs web** | `t2.micro` | Taille adaptée à une démonstration | Vérifier l'éligibilité et le prix du compte |
| **OpenSearch** | `t3.small.search` | Taille minimale du module pédagogique | Service payant à détruire après usage |
| **HAProxy** | `t2.micro` | Charge de démonstration limitée | Le port 8404 est restreint à l'IP d'administration |
| **Algorithme HAProxy** | `roundrobin` | Alternance simple à démontrer | `leastconn` conviendrait à des requêtes longues |

---

## 🛠️ Outils

| Outil | Version cible | Justification |
|-------|---------------|---------------|
| **Terraform** | 1.15.8 | Version fixée dans la CI |
| **Provider AWS** | 5.x | Verrouillé par les fichiers `.terraform.lock.hcl` |
| **Ansible Core** | 2.18 ou 2.19 | Contrôle syntaxique reproductible |
| **AWS CLI** | 2.x | Commandes `ec2`, `sts` et `opensearch` |
| **OpenSearch** | 2.19 | Version déclarée dans Terraform |
| **HAProxy** | Paquet Ubuntu 24.04 | Installation simple et maintenue par la distribution |

---

## 🌐 Décisions pour l'Exercice 1

| Décision | Choix | Justification |
|----------|-------|---------------|
| **Interface web** | HTML/CSS statique | Le dépôt ne contient pas de projet Angular compilable |
| **Serveur web** | NGINX | Léger, courant et simple à vérifier |
| **Déploiement** | Ansible | Configuration idempotente des deux hôtes |
| **Accès SSH** | IP `/32` | Évite une ouverture SSH mondiale |

> Si l'évaluation exige explicitement Angular, un vrai projet Angular et son étape de build devront être ajoutés ; il ne faut pas présenter le fichier HTML actuel comme une application Angular.

---

## 📊 Décisions pour l'Exercice 2

| Décision | Choix | Justification |
|----------|-------|---------------|
| **Service de logs** | Amazon OpenSearch | Service demandé pour l'exercice |
| **Index** | `nginx-access-*` | Regroupe les logs quotidiens |
| **Champ de temps** | `@timestamp` | Convention OpenSearch |
| **Accès** | HTTPS + filtrage IP | Réduit l'exposition de l'endpoint |
| **Visualisations** | Donut et deux histogrammes | Répond aux trois vues demandées |

---

## ⚖️ Décisions pour l'Exercice 3

| Décision | Choix | Justification |
|----------|-------|---------------|
| **Backends** | Deux conteneurs `nginxdemos/hello` | Rend l'alternance observable |
| **Accès backend** | Groupe de sécurité HAProxy uniquement | Évite l'exposition HTTP directe |
| **Statistiques** | Port 8404 + mot de passe externe | Secret absent du dépôt |
| **Secret** | Variables `HAPROXY_STATS_PASSWORD` et `TF_VAR_haproxy_stats_password` | Transmission au moment du déploiement |

---

## 💰 Décisions financières

- Vérifier les tarifs du compte et de la région avant chaque `terraform apply`.
- Ne jamais supposer qu'une ressource est gratuite simplement parce qu'elle a déjà été éligible au Free Tier.
- Détruire chaque module après la collecte des preuves et vérifier l'absence de ressources résiduelles.

---

## 🔧 Bonnes pratiques appliquées

- ✅ Infrastructure déclarative et modules Terraform séparés.
- ✅ CI bloquante sans `|| true` sur les contrôles importants.
- ✅ Secrets, états et inventaires réels exclus de Git.
- ✅ Livrables distinguant clairement exemples et preuves réelles.
- ✅ Documentation conservant ses sections, emojis et navigation visuelle.
