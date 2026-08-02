# 🎯 Introduction et Prérequis

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code avec Terraform, Ansible et ELK**

---

## 📚 **Contexte du Projet**

### **Pourquoi ce projet ?**

Dans le monde du **DevOps** et du **Cloud Computing**, la capacité à **automatiser** le déploiement et la gestion de l'infrastructure est devenue une compétence **essentielle**. Les entreprises cherchent à :

- ✅ **Réduire les coûts** en optimisant l'utilisation des ressources cloud
- ✅ **Améliorer la rapidité** de déploiement des applications
- ✅ **Garantir la reproductibilité** des environnements
- ✅ **Centraliser les logs** pour une meilleure observabilité
- ✅ **Assurer la haute disponibilité** des services

Ce projet vous permettra de **maîtriser ces concepts** à travers une approche **pratique et pédagogique**.

---

### **Scénario du Projet**

Vous êtes **DevOps Engineer** dans une entreprise qui souhaite moderniser son infrastructure. Votre mission :

1. **Automatiser le déploiement** de serveurs web avec **Terraform** et **Ansible**
2. **Centraliser les logs** de vos applications avec une **stack ELK (OpenSearch)**
3. **Améliorer la disponibilité** avec un **Load Balancer (HAProxy)**
4. **Documenter** votre travail de manière professionnelle

**Architecture finale** :
```
Client → HAProxy (Load Balancer) → NGINX-1 + NGINX-2 → OpenSearch (Logs) → Kibana (Visualisation)
```

---

### **Objectifs Pédagogiques**

À la fin de ce projet, vous serez capable de :

🎯 **Comprendre les concepts** :
- Infrastructure-as-Code (IaC)
- Configuration Management
- Centralisation des logs
- Load Balancing
- Observabilité

🛠️ **Utiliser les outils** :
- **Terraform** pour le provisionnement d'infrastructure
- **Ansible** pour la configuration des serveurs
- **OpenSearch** pour la recherche et l'analyse des logs
- **HAProxy** pour le Load Balancing
- **NGINX** comme serveur web

📊 **Appliquer les bonnes pratiques** :
- Gestion des configurations avec Git
- Documentation technique
- Dépannage et résolution de problèmes
- Optimisation des coûts cloud

---

## 📋 **Prérequis**

### **🎓 Compétences Requises**

Avant de commencer ce projet, assurez-vous de maîtriser les concepts suivants :

| Compétence | Niveau | Ressources pour apprendre |
|-----------|--------|--------------------------|
| **Linux (CLI)** | Intermédiaire | [LinuxCommand.org](https://linuxcommand.org) |
| **Réseau (IP, DNS, Ports)** | Débutant | [Computer Networking: A Top-Down Approach](https://gaia.cs.umass.edu/kurose_ross/) |
| **Git et GitHub** | Débutant | [GitHub Guides](https://guides.github.com) |
| **AWS (Concepts de base)** | Débutant | [AWS Cloud Practitioner](https://aws.amazon.com/certification/certified-cloud-practitioner/) |
| **YAML** | Débutant | [YAML Spec](https://yaml.org/spec/) |
| **JSON** | Débutant | [JSON.org](https://www.json.org/) |

**⚠️ Si vous ne maîtrisez pas ces concepts**, prenez le temps de les apprendre avant de commencer. Ce projet sera plus facile à comprendre !

---

### **💻 Outils Nécessaires**

#### **1. Outils de Base**

| Outil | Version | Lien | Installation | Vérification |
|-------|---------|------|--------------|--------------|
| **Git** | ≥ 2.x | [git-scm.com](https://git-scm.com) | `brew install git` / `apt install git` | `git --version` |
| **Curl** | - | - | `brew install curl` / `apt install curl` | `curl --version` |
| **Wget** | - | - | `brew install wget` / `apt install wget` | `wget --version` |
| **SSH** | - | - | Intégré | `ssh -V` |

#### **2. Outils DevOps**

| Outil | Version | Lien | Installation | Vérification |
|-------|---------|------|--------------|--------------|
| **Terraform** | ≥ 1.5.x | [terraform.io](https://www.terraform.io) | `brew install terraform` | `terraform --version` |
| **Ansible** | ≥ 2.14.x | [ansible.com](https://www.ansible.com) | `pip install ansible` | `ansible --version` |
| **AWS CLI** | ≥ 2.x | [aws.amazon.com/cli](https://aws.amazon.com/cli) | `brew install awscli` / `pip install awscli` | `aws --version` |

#### **3. Outils Optionnels (Recommandés)**

| Outil | Utilisation | Installation |
|-------|-------------|--------------|
| **Visual Studio Code** | Éditeur de code | [code.visualstudio.com](https://code.visualstudio.com) |
| **Postman** | Test d'API | [postman.com](https://www.postman.com) |
| **DBeaver** | Client base de données | [dbeaver.io](https://dbeaver.io) |
| **Draw.io** | Schémas d'architecture | [app.diagrams.net](https://app.diagrams.net) |

---

### **🌐 Configuration de l'Environnement**

#### **1. Créer un Compte AWS**

1. Allez sur [AWS Sign Up](https://portal.aws.amazon.com/billing/signup)
2. Suivez les instructions pour créer un compte
3. **⚠️ Important** : Utilisez une **carte de crédit valide** (nécessaire pour la vérification)
4. **Activer le Free Tier** : AWS offre 12 mois de services gratuits pour les nouveaux comptes

#### **2. Configurer les Credentials AWS**

1. **Créer un utilisateur IAM** (recommandé) :
   - Allez dans **IAM** → **Users** → **Add user**
   - **User name** : `p5-user` (ou un nom de votre choix)
   - **Select AWS credential type** : ✅ Access key (Programmatic access)
   - **Permissions** : Attachez la policy **AdministratorAccess** (pour simplifier)
   - **Tags** : Optionnel
   - **Review** → **Create user**
   - **Téléchargez le fichier CSV** avec les credentials (à garder en sécurité !)

2. **Configurer AWS CLI** :
   ```bash
   aws configure
   ```
   
   **Exemple de configuration** :
   ```
   AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
   AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   Default region name [None]: eu-west-3
   Default output format [None]: json
   ```

3. **Vérifier la configuration** :
   ```bash
   aws sts get-caller-identity
   ```
   
   **Sortie attendue** :
   ```json
   {
       "UserId": "AIDAIOSFODNN7EXAMPLE",
       "Account": "123456789012",
       "Arn": "arn:aws:iam::123456789012:user/p5-user"
   }
   ```

#### **3. Créer une Paire de Clés SSH**

1. **Générer une nouvelle paire de clés** :
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key -N ""
   ```
   
   **Explications** :
   - `-t rsa` : Type de clé (RSA)
   - `-b 4096` : Taille de la clé (4096 bits)
   - `-f ~/.ssh/p5-key` : Fichier de la clé privée
   - `-N ""` : Pas de phrase de passe (pour simplifier)

2. **Vérifier les fichiers créés** :
   ```bash
   ls -la ~/.ssh/p5-key*
   ```
   
   **Sortie attendue** :
   ```
   -rw-------  1 user user 4096 Jan  1 12:00 /home/user/.ssh/p5-key
   -rw-r--r--  1 user user  912 Jan  1 12:00 /home/user/.ssh/p5-key.pub
   ```

3. **Ajouter la clé au SSH Agent** (optionnel) :
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/p5-key
   ```

#### **4. Trouver Votre IP Publique**

Vous aurez besoin de votre **IP publique** pour configurer les Security Groups AWS.

```bash
# Méthode 1 : Utiliser curl
curl ifconfig.me

# Méthode 2 : Utiliser dig (OpenDNS)
dig +short myip.opendns.com @resolver1.opendns.com

# Méthode 3 : Visiter un site web
# https://whatismyipaddress.com/
```

**⚠️ Important** : Notez cette IP, vous en aurez besoin pour configurer Terraform.

---

## 🧪 **Vérification de l'Environnement**

Avant de commencer les exercices, vérifiez que tout est correctement configuré :

### **1. Vérifier les Outils Installés**

```bash
# Vérifier Terraform
tf_version=$(terraform --version | head -n1 | cut -d' ' -f2 | cut -d'v' -f2)
echo "Terraform: v$tf_version"

# Vérifier Ansible
ansible_version=$(ansible --version | head -n1 | cut -d' ' -f2 | cut -d'[' -f1)
echo "Ansible: $ansible_version"

# Vérifier AWS CLI
aws_version=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
echo "AWS CLI: $aws_version"

# Vérifier Git
git_version=$(git --version | cut -d' ' -f3)
echo "Git: $git_version"
```

**Sortie attendue** :
```
Terraform: v1.5.x
Ansible: 2.14.x
AWS CLI: 2.x.x
Git: 2.x.x
```

### **2. Vérifier la Connectivité AWS**

```bash
# Vérifier que vous pouvez lister vos instances EC2
aws ec2 describe-instances --query 'length(Reservations)'

# Vérifier que vous pouvez lister vos VPC
aws ec2 describe-vpcs --query 'length(Vpcs)'

# Vérifier votre identité
aws sts get-caller-identity
```

**Si une commande échoue** :
1. Vérifiez que vos **credentials AWS** sont correctement configurés
2. Vérifiez que votre **utilisateur IAM** a les permissions nécessaires
3. Vérifiez que vous êtes dans la **bonne région** (`eu-west-3`)

### **3. Vérifier la Clé SSH**

```bash
# Vérifier que la clé privée existe
ls -la ~/.ssh/p5-key

# Vérifier que la clé publique existe
ls -la ~/.ssh/p5-key.pub

# Vérifier le contenu de la clé publique
cat ~/.ssh/p5-key.pub
```

**Sortie attendue** :
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7... user@host
```

---

## 🎯 **Conseils pour Réussir le Projet**

### **1. Organisation du Travail**

- **Lisez attentivement** chaque exercice avant de commencer
- **Prenez des notes** dans le [journal de session](livrables/journal-session.md)
- **Documentez vos décisions** dans [decisions.md](livrables/decisions.md)
- **Faites des pauses** régulièrement pour éviter la fatigue

### **2. Bonnes Pratiques**

- **Versionnez votre code** : Faites des commits réguliers avec des messages clairs
- **Testez souvent** : Vérifiez que chaque étape fonctionne avant de passer à la suivante
- **Documentez tout** : Notez les problèmes rencontrés et leurs solutions
- **Nettoyez derrière vous** : Supprimez les ressources AWS inutilisées pour éviter des coûts

### **3. Gestion des Erreurs**

- **Ne paniquez pas** si quelque chose ne fonctionne pas
- **Lisez les messages d'erreur** attentivement
- **Utilisez Google** : La plupart des erreurs ont déjà été rencontrées par d'autres
- **Consultez la documentation** officielle des outils
- **Demandez de l'aide** si vous êtes bloqué depuis trop longtemps

### **4. Optimisation des Coûts**

- **Utilisez le Free Tier** : AWS offre 12 mois de services gratuits
- **Ne laissez pas tourner les instances 24/7** pendant le développement
- **Supprimez les ressources inutilisées** après chaque session
- **Utilisez des instances t2.micro** quand c'est possible (éligible au Free Tier)

---

## 📖 **Ressources pour Aller Plus Loin**

### **Documentation Officielle**

| Outil | Documentation | Lien |
|-------|---------------|------|
| **Terraform** | Documentation complète | [developer.hashicorp.com/terraform/docs](https://developer.hashicorp.com/terraform/docs) |
| **Ansible** | Documentation complète | [docs.ansible.com](https://docs.ansible.com) |
| **AWS** | Documentation complète | [docs.aws.amazon.com](https://docs.aws.amazon.com) |
| **OpenSearch** | Documentation complète | [opensearch.org/docs](https://opensearch.org/docs) |
| **HAProxy** | Documentation complète | [www.haproxy.org/documentation](https://www.haproxy.org/documentation) |
| **NGINX** | Documentation complète | [nginx.org/en/docs](https://nginx.org/en/docs) |

### **Tutoriels et Guides**

| Sujet | Ressource | Lien |
|-------|-----------|------|
| **Terraform pour débutants** | HashiCorp Learn | [learn.hashicorp.com/terraform](https://learn.hashicorp.com/terraform) |
| **Ansible pour débutants** | Ansible Docs | [docs.ansible.com/ansible/latest/user_guide](https://docs.ansible.com/ansible/latest/user_guide/index.html) |
| **AWS pour débutants** | AWS Getting Started | [aws.amazon.com/getting-started](https://aws.amazon.com/getting-started) |
| **OpenSearch** | OpenSearch Docs | [opensearch.org/docs](https://opensearch.org/docs) |
| **ELK Stack** | Elastic Guide | [www.elastic.co/guide](https://www.elastic.co/guide/index.html) |

### **Communautés et Forums**

| Communauté | Description | Lien |
|------------|-------------|------|
| **Stack Overflow** | Questions/réponses techniques | [stackoverflow.com](https://stackoverflow.com) |
| **HashiCorp Discuss** | Forum Terraform | [discuss.hashicorp.com](https://discuss.hashicorp.com) |
| **Ansible Community** | Forum Ansible | [forum.ansible.com](https://forum.ansible.com) |
| **AWS Forums** | Forum AWS | [forums.aws.amazon.com](https://forums.aws.amazon.com) |
| **OpenClassrooms** | Forum des étudiants | [openclassrooms.com/forum](https://openclassrooms.com/forum) |

---

## 🚀 **Par où Commencer ?**

Maintenant que votre environnement est prêt, vous pouvez commencer par :

1. **Lire** [02-architecture.md](02-architecture.md) pour comprendre l'architecture globale du projet
2. **Commencer** par [Exercice 1 - Terraform + Ansible + NGINX](exercices/exercice-1-terraform-ansible-nginx.md)
3. **Poursuivre** avec [Exercice 2 - OpenSearch (ELK)](exercices/exercice-2-opensearch-part1.md)
4. **Terminer** par [Exercice 3 - HAProxy (Load Balancer)](exercices/exercice-3-haproxy.md)

---

## ⚠️ **Avertissements Importants**

### **1. Coûts AWS**

⚠️ **Ce projet utilise des ressources AWS payantes.**

- **Estimation des coûts** : ~20-50€/mois si vous laissez tout allumé 24/7
- **Avec optimisations** : ~5-10€/mois (Free Tier + utilisation ponctuelle)
- **Pour l'examen** : ~5-10€ (quelques jours d'utilisation)

**Conseils pour réduire les coûts** :
- Utilisez le **Free Tier** (750h/mois de t2.micro gratuites)
- **Éteignez les instances** quand vous ne les utilisez pas
- Utilisez des **instances t2.micro** quand c'est possible
- **Supprimez toutes les ressources** après avoir terminé le projet

### **2. Sécurité**

⚠️ **Ne commitez JAMAIS vos credentials dans Git !**

- **Fichiers à NE PAS commiter** :
  - `*.tfvars` (sauf `.tfvars.example`)
  - `*.pem`, `*.key`, `*.crt`
  - `credentials`, `config` (AWS)
  - Tout fichier contenant des mots de passe ou clés secrètes

- **Utilisez toujours le `.gitignore`** fourni dans ce projet

### **3. Sauvegarde**

⚠️ **Sauvegardez votre travail régulièrement !**

- Faites des **commits Git** fréquents
- Utilisez des **branches** pour les modifications expérimentales
- Sauvegardez les **fichiers importants** (journal, décisions, preuves) sur votre machine locale

---

## 🎓 **Ce que vous allez Apprendre**

À la fin de ce projet, vous aurez acquis les compétences suivantes :

### **Compétences Techniques**

✅ **Infrastructure-as-Code (IaC)** :
- Décrire une infrastructure avec Terraform
- Gérer l'état de l'infrastructure
- Utiliser des modules et des variables

✅ **Configuration Management** :
- Configurer des serveurs avec Ansible
- Créer des playbooks et des rôles
- Utiliser des templates Jinja2

✅ **Cloud Computing (AWS)** :
- Créer et gérer des VPC, subnets, Security Groups
- Lancer des instances EC2
- Configurer des Elastic IP

✅ **Centralisation des Logs** :
- Déployer OpenSearch
- Configurer Logstash pour le traitement des logs
- Utiliser Filebeat pour la collecte
- Visualiser les logs avec Kibana

✅ **Load Balancing** :
- Configurer HAProxy comme Load Balancer
- Répartir la charge entre plusieurs serveurs
- Configurer des algorithmes de Load Balancing

✅ **Observabilité** :
- Centraliser les logs
- Créer des visualisations
- Configurer des tableaux de bord
- Analyser les données

### **Compétences Transversales**

✅ **Résolution de problèmes** :
- Dépanner des infrastructures cloud
- Analyser des logs et des erreurs
- Trouver des solutions en ligne

✅ **Documentation** :
- Rédiger une documentation technique
- Créer des preuves de travail
- Documenter des décisions

✅ **Gestion de projet** :
- Organiser son travail
- Gérer son temps
- Prioriser les tâches

✅ **Collaboration** :
- Utiliser Git et GitHub
- Travailler avec des branches
- Faire des pull requests

---

**Bonne chance dans votre apprentissage !** 💪

> *"Le succès, c'est d'aller d'échec en échec sans perdre son enthousiasme."* — **Winston Churchill**

> *"Le code est de la poésie qui fonctionne."* — **Linus Torvalds**

> *"Automatisez tout, même l'automatisation."* — **DevOps Proverb**
