# 📖 Glossaire Technique - Projet P5 OpenClassrooms

**Déployer et suivre l'infrastructure as code grâce à Terraform, Ansible et la stack ELK**

---

## 📌 Instructions

Ce glossaire contient **toutes les définitions des termes techniques** utilisés dans ce projet.

---

## 🌐 Cloud Computing et AWS

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **AWS** | Amazon Web Services, plateforme de cloud computing proposant plus de 200 services. | EC2, S3, Elasticsearch | [aws.amazon.com](https://aws.amazon.com) |
| **Cloud Computing** | Modèle de fourniture de services informatiques via Internet. | AWS, Azure, GCP | [Wikipédia](https://fr.wikipedia.org/wiki/Cloud_computing) |
| **IaaS** | Infrastructure as a Service : Fourniture d'infrastructure informatique via le cloud. | AWS EC2, Azure VM | [Wikipédia](https://fr.wikipedia.org/wiki/Infrastructure_as_a_service) |
| **us-east-1** | Région AWS en Virginie du Nord (obligatoire pour ce projet). | - | [AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/) |
| **Free Tier** | Offre AWS permettant d'utiliser certains services gratuitement pendant 12 mois. | 750h/mois de t2.micro gratuites | [AWS Free Tier](https://aws.amazon.com/free/) |
| **EC2** | Elastic Compute Cloud : Service AWS pour créer des VMs dans le cloud. | t2.micro, t3.medium | [AWS EC2](https://aws.amazon.com/ec2/) |
| **AMI** | Amazon Machine Image : Image préconfigurée pour créer des instances EC2. | ami-0c55b159cbfafe1f0 | [AWS AMIs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) |
| **Security Group** | Firewall virtuel pour les instances EC2. | sg-xxxxx | [AWS Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html) |
| **VPC** | Virtual Private Cloud : Réseau privé isolé dans AWS. | vpc-xxxxx | [AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) |
| **Subnet** | Sous-réseau d'un VPC. | subnet-xxxxx | [AWS Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html) |
| **Elastic IP** | Adresse IP publique statique. | eipalloc-xxxxx | [AWS Elastic IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eips.html) |

---

## ⛏️ Terraform

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Terraform** | Outil d'Infrastructure-as-Code (IaC) pour provisionner et gérer des infrastructures cloud. | - | [terraform.io](https://www.terraform.io) |
| **IaC** | Infrastructure as Code : Pratique consistant à gérer l'infrastructure via du code. | Terraform, AWS CloudFormation | [Wikipédia](https://en.wikipedia.org/wiki/Infrastructure_as_code) |
| **Provider** | Plugin Terraform pour interagir avec un cloud ou un service. | aws, azure, google | [Terraform Providers](https://developer.hashicorp.com/terraform/plugin) |
| **Resource** | Élément d'infrastructure géré par Terraform. | aws_instance, aws_vpc | [Terraform Resources](https://developer.hashicorp.com/terraform/language/resources) |
| **Variable** | Paramètre configurable dans Terraform. | variable "instance_type" | [Terraform Variables](https://developer.hashicorp.com/terraform/language/values/variables) |
| **Output** | Valeur retournée par Terraform après application. | output "public_ip" | [Terraform Outputs](https://developer.hashicorp.com/terraform/language/values/outputs) |
| **State** | Fichier stockant l'état actuel de l'infrastructure. | terraform.tfstate | [Terraform State](https://developer.hashicorp.com/terraform/language/state) |
| **terraform init** | Initialise Terraform et télécharge les providers. | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/init) |
| **terraform plan** | Affiche les changements à appliquer. | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/plan) |
| **terraform apply** | Applique les changements. | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/apply) |
| **terraform destroy** | Supprime toutes les ressources. | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/destroy) |

---

## 🎭 Ansible

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Ansible** | Outil d'automatisation open source pour la configuration et le déploiement. | - | [ansible.com](https://www.ansible.com) |
| **Configuration Management** | Pratique consistant à gérer la configuration des serveurs de manière automatisée. | Ansible, Puppet, Chef | [Wikipédia](https://en.wikipedia.org/wiki/Configuration_management) |
| **Playbook** | Fichier YAML contenant une série de tâches à exécuter. | deploy.yml | [Ansible Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) |
| **Inventory** | Fichier listant les serveurs à configurer. | hosts_aws | [Ansible Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) |
| **Role** | Organisation des tâches Ansible par rôle. | roles/nginx/ | [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) |
| **Task** | Une action à exécuter sur un serveur. | Installer NGINX | [Ansible Tasks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#tasks) |
| **Module** | Fonctionnalité réutilisable dans Ansible. | apt, yum, copy | [Ansible Modules](https://docs.ansible.com/ansible/latest/user_guide/modules.html) |
| **Handler** | Tâche déclenchée par un changement. | Redémarrer NGINX | [Ansible Handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html) |
| **Become** | Exécute une tâche avec sudo. | --become | [Ansible Become](https://docs.ansible.com/ansible/latest/user_guide/become.html) |
| **ansible-playbook** | Commande pour exécuter un playbook. | - | [Doc](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html) |
| **ansible** | Commande pour exécuter des commandes ad-hoc. | - | [Doc](https://docs.ansible.com/ansible/latest/cli/ansible.html) |

---

## 🌐 Serveurs Web et Proxy

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **NGINX** | Serveur web open source, reverse proxy et load balancer. | nginx -v | [nginx.org](https://nginx.org) |
| **Serveur Web** | Logiciel servant des pages web. | NGINX, Apache | [Wikipédia](https://fr.wikipedia.org/wiki/Serveur_web) |
| **Reverse Proxy** | Serveur agissant comme intermédiaire entre les clients et les serveurs backend. | NGINX, HAProxy | [Wikipédia](https://fr.wikipedia.org/wiki/Proxy_inverse) |
| **Load Balancer** | Dispositif répartissant la charge entre plusieurs serveurs. | HAProxy, NGINX, ALB | [Wikipédia](https://fr.wikipedia.org/wiki/R%C3%A9partition_de_charge) |
| **HAProxy** | Load Balancer open source haute performance. | haproxy -v | [haproxy.org](https://www.haproxy.org) |
| **HTTP** | HyperText Transfer Protocol : Protocole de communication pour le web. | Port 80 | [Wikipédia](https://fr.wikipedia.org/wiki/Hypertext_Transfer_Protocol) |
| **HTTPS** | HTTP Secure : HTTP avec chiffrement SSL/TLS. | Port 443 | [Wikipédia](https://fr.wikipedia.org/wiki/Hypertext_Transfer_Protocol_Secure) |
| **Port** | Numéro utilisé pour identifier un service sur un serveur. | 80 (HTTP), 443 (HTTPS) | [Wikipédia](https://fr.wikipedia.org/wiki/Port_(informatique)) |

---

## 🔍 OpenSearch et ELK Stack

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **OpenSearch** | Moteur de recherche et d'analyse open source (fork d'Elasticsearch). | opensearch -v | [opensearch.org](https://opensearch.org) |
| **Elasticsearch** | Moteur de recherche et d'analyse distribué (licence SSPL). | - | [elastic.co](https://www.elastic.co/elasticsearch/) |
| **Elasticsearch Service** | Service managé AWS pour Elasticsearch/OpenSearch. | - | [AWS Elasticsearch Service](https://aws.amazon.com/opensearch-service/) |
| **Domain** | Cluster OpenSearch managé par AWS. | p5-opensearch | [AWS ES Domains](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-create-domain.html) |
| **Endpoint** | URL pour accéder au cluster OpenSearch. | vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com | - |
| **Cluster** | Ensemble de nœuds OpenSearch travaillant ensemble. | - | [OpenSearch Cluster](https://opensearch.org/docs/latest/opensearch/rest-api/cluster/) |
| **Node** | Serveur individuel dans un cluster OpenSearch. | Master Node, Data Node | [OpenSearch Nodes](https://opensearch.org/docs/latest/opensearch/node-roles/) |
| **Index** | Ensemble de documents similaires dans OpenSearch. | logs-nginx-2026.08.02 | [OpenSearch Index](https://opensearch.org/docs/latest/opensearch/rest-api/index/) |
| **Document** | Unité de base de stockage dans OpenSearch (format JSON). | {"field": "value"} | [OpenSearch Document](https://opensearch.org/docs/latest/opensearch/rest-api/document/) |
| **Shard** | Partition d'un index OpenSearch. | - | [OpenSearch Shards](https://opensearch.org/docs/latest/opensearch/index-modules/index-sharding/) |
| **Replica** | Copie d'un shard pour la redondance. | - | [OpenSearch Replicas](https://opensearch.org/docs/latest/opensearch/index-modules/index-replication/) |
| **ELK Stack** | Ensemble Elasticsearch + Logstash + Kibana. | - | [elastic.co/elk-stack](https://www.elastic.co/elk-stack) |

---

## 🔧 Outils et Concepts DevOps

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **DevOps** | Ensemble de pratiques visant à améliorer la collaboration entre les équipes de développement et d'exploitation. | CI/CD, IaC | [Wikipédia](https://fr.wikipedia.org/wiki/DevOps) |
| **IaC** | Infrastructure as Code : Pratique consistant à gérer l'infrastructure via du code. | Terraform, AWS CloudFormation | [Wikipédia](https://en.wikipedia.org/wiki/Infrastructure_as_code) |
| **Configuration Management** | Pratique consistant à gérer la configuration des serveurs de manière automatisée. | Ansible, Puppet, Chef | [Wikipédia](https://en.wikipedia.org/wiki/Configuration_management) |
| **Load Balancing** | Répartition de la charge entre plusieurs serveurs. | HAProxy, NGINX, ALB | [Wikipédia](https://fr.wikipedia.org/wiki/R%C3%A9partition_de_charge) |
| **High Availability** | Capacité d'un système à rester disponible malgré des pannes. | Multi-AZ, Load Balancer | [Wikipédia](https://fr.wikipedia.org/wiki/Haute_disponibilit%C3%A9) |
| **Fault Tolerance** | Capacité d'un système à continuer de fonctionner malgré des pannes. | Redondance, Replicas | [Wikipédia](https://fr.wikipedia.org/wiki/Tol%C3%A9rance_aux_pannes) |
| **Health Check** | Vérification automatique de la santé d'un serveur. | HTTP 200 OK | - |
| **Round Robin** | Algorithme de répartition simple (1 requête par serveur à tour de rôle). | balance roundrobin | [Wikipédia](https://fr.wikipedia.org/wiki/Round_robin) |

---

## 💻 Systèmes et Réseau

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Fedora** | Distribution Linux basée sur Red Hat. | Fedora 44 Cosmic | [getfedora.org](https://getfedora.org) |
| **Ubuntu** | Distribution Linux basée sur Debian. | Ubuntu 26.04 | [ubuntu.com](https://ubuntu.com) |
| **KVM** | Kernel-based Virtual Machine : Solution de virtualisation intégrée au noyau Linux. | virsh, virt-manager | [Wikipédia](https://fr.wikipedia.org/wiki/Kernel-based_Virtual_Machine) |
| **QEMU** | Émulateur et virtualiseur open source. | qemu-kvm | [qemu.org](https://www.qemu.org) |
| **libvirt** | API open source pour gérer les machines virtuelles. | virsh, virt-manager | [libvirt.org](https://libvirt.org) |
| **virt-manager** | Interface graphique pour gérer les VMs KVM. | - | [virt-manager.org](https://virt-manager.org) |
| **SSH** | Secure Shell : Protocole pour se connecter à distance à un serveur. | ssh user@host | [Wikipédia](https://fr.wikipedia.org/wiki/Secure_Shell) |
| **IP Publique** | Adresse IP accessible depuis Internet. | 54.123.45.67 | - |
| **IP Privée** | Adresse IP accessible uniquement dans le VPC. | 10.0.1.123 | - |
| **DNS** | Domain Name System : Système de nommage pour les adresses IP. | google.com → 8.8.8.8 | [Wikipédia](https://fr.wikipedia.org/wiki/Domain_Name_System) |

---

## 📦 Stockage et Bases de Données

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **NoSQL** | Base de données non relationnelle, sans schéma fixe. | OpenSearch, MongoDB | [Wikipédia](https://fr.wikipedia.org/wiki/NoSQL) |
| **SQL** | Base de données relationnelle avec schéma fixe. | MySQL, PostgreSQL | [Wikipédia](https://fr.wikipedia.org/wiki/SQL) |
| **JSON** | JavaScript Object Notation : Format de données léger et lisible. | {"key": "value"} | [json.org](https://www.json.org/) |
| **YAML** | YAML Ain't Markup Language : Format de sérialisation de données lisible. | key: value | [yaml.org](https://yaml.org/) |
| **gp3** | Type de volume EBS optimisé pour les performances et le coût. | vol-xxxxx | [AWS EBS gp3](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) |

---

## 🔐 Sécurité

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **IAM** | Identity and Access Management : Service AWS pour gérer les utilisateurs et permissions. | - | [AWS IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) |
| **Access Key** | Identifiant pour accéder à AWS via l'API. | AKIAIOSFODNN7EXAMPLE | [AWS Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) |
| **Secret Key** | Clé secrète associée à la clé d'accès. | wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY | [AWS Secret Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) |
| **Security Group** | Firewall virtuel pour les instances EC2. | sg-xxxxx | [AWS Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html) |
| **Access Policy** | Règles de sécurité pour un service AWS. | - | [AWS IAM Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) |

---

## 📊 Monitoring et Observabilité

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Monitoring** | Surveillance des systèmes et applications. | CloudWatch, Prometheus | [Wikipédia](https://fr.wikipedia.org/wiki/Monitoring) |
| **Log** | Enregistrement d'un événement dans un système. | /var/log/nginx/access.log | [Wikipédia](https://fr.wikipedia.org/wiki/Journalisation) |
| **Métrique** | Mesure quantitative d'un aspect d'un système. | CPU Usage, Memory Usage | - |
| **Dashboard** | Tableau de bord visualisant des données. | Kibana Dashboard | - |
| **Visualization** | Représentation graphique de données. | Bar Chart, Pie Chart | - |

---

## 📌 Résumé par Catégorie

| Catégorie | Nombre de Termes | Termes Clés |
|----------|------------------|-------------|
| **Cloud Computing et AWS** | 12 | AWS, EC2, us-east-1, Free Tier, Security Group |
| **Terraform** | 10 | Terraform, IaC, Provider, Resource, State |
| **Ansible** | 12 | Ansible, Playbook, Inventory, Role, Task |
| **Serveurs Web et Proxy** | 10 | NGINX, HAProxy, HTTP, HTTPS, Load Balancer |
| **OpenSearch et ELK Stack** | 12 | OpenSearch, Elasticsearch, Domain, Cluster, Index |
| **Outils et Concepts DevOps** | 10 | DevOps, IaC, Configuration Management, Load Balancing |
| **Systèmes et Réseau** | 12 | Fedora, Ubuntu, KVM, QEMU, SSH |
| **Stockage et Bases de Données** | 5 | NoSQL, SQL, JSON, YAML, gp3 |
| **Sécurité** | 5 | IAM, Access Key, Secret Key, Security Group |
| **Monitoring et Observabilité** | 5 | Monitoring, Log, Métrique, Dashboard |

---

## 🎯 Termes à Connaître Absolument

### Niveau 1 : Fondamentaux
- AWS
- EC2
- us-east-1
- Free Tier
- Security Group
- SSH
- HTTP/HTTPS
- Git
- Terraform
- Ansible

### Niveau 2 : Intermédiaire
- IaC (Infrastructure as Code)
- Configuration Management
- Load Balancer
- Reverse Proxy
- OpenSearch/Elasticsearch
- HAProxy
- NGINX
- KVM/QEMU
- libvirt

### Niveau 3 : Avancé
- Cluster
- Node (Master, Data)
- Index
- Document
- Shard
- Replica
- Round Robin
- Health Check
- Fault Tolerance

---

**Bonne étude !** 📚

> *"La connaissance est un trésor, mais la pratique en est la clé."* — **Lao Tseu**
