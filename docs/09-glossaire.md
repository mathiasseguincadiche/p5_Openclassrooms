# 📖 Glossaire Technique

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce glossaire contient **toutes les définitions des termes techniques** utilisés dans ce projet. Il sert à :

✅ **Comprendre** les concepts et technologies utilisés
✅ **Référence rapide** pendant le développement
✅ **Préparation** pour l'évaluation

**Format** :
- **Termes classés par catégorie**
- **Définitions claires et concises**
- **Exemples** quand nécessaire
- **Liens** vers la documentation officielle

---

## 🌐 **Cloud Computing et AWS**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **AWS** | Amazon Web Services, plateforme de cloud computing proposant plus de 200 services (calcul, stockage, bases de données, réseau, etc.) | EC2, S3, RDS | [aws.amazon.com](https://aws.amazon.com) |
| **Cloud Computing** | Modèle de fourniture de services informatiques (serveurs, stockage, bases de données, réseau, etc.) via Internet | AWS, Azure, GCP | [Wikipédia](https://fr.wikipedia.org/wiki/Cloud_computing) |
| **IaaS** | Infrastructure as a Service : Fourniture d'infrastructure informatique (serveurs, stockage, réseau) via le cloud | AWS EC2, Azure VM | [Wikipédia](https://fr.wikipedia.org/wiki/Infrastructure_as_a_service) |
| **PaaS** | Platform as a Service : Fourniture d'une plateforme complète pour développer, tester et déployer des applications | AWS Elastic Beanstalk, Heroku | [Wikipédia](https://fr.wikipedia.org/wiki/Platform_as_a_service) |
| **SaaS** | Software as a Service : Fourniture de logiciels via le cloud | Gmail, Salesforce | [Wikipédia](https://fr.wikipedia.org/wiki/Software_as_a_service) |
| **Région AWS** | Zone géographique contenant plusieurs Availability Zones (AZ) | eu-west-3 (Paris), us-east-1 (Virginie) | [AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/) |
| **Availability Zone (AZ)** | Centre de données isolé dans une région AWS | eu-west-3a, eu-west-3b | [AWS AZ](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/) |
| **Free Tier** | Offre AWS permettant d'utiliser certains services gratuitement pendant 12 mois | 750h/mois de t2.micro gratuites | [AWS Free Tier](https://aws.amazon.com/free/) |
| **Elastic IP** | Adresse IP publique statique qui peut être attachée à une instance EC2 | 52.47.123.45 | [AWS Elastic IP](https://docs.aws.amazon.com/fr_fr/AWSEC2/latest/UserGuide/elastic-ip-addresses-eips.html) |

---

## 🖥️ **Infrastructure et Réseau**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **VPC** | Virtual Private Cloud : Réseau privé isolé dans AWS | CIDR 10.0.0.0/16 | [AWS VPC](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/what-is-amazon-vpc.html) |
| **Subnet** | Sous-réseau d'un VPC | 10.0.1.0/24 | [AWS Subnets](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/configure-subnets.html) |
| **Public Subnet** | Subnet avec accès à Internet via un Internet Gateway | 10.0.1.0/24 | [AWS Public Subnets](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/vpc-subnets-commands.html) |
| **Private Subnet** | Subnet sans accès direct à Internet | 10.0.3.0/24 | [AWS Private Subnets](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/vpc-subnets-commands.html) |
| **Internet Gateway (IGW)** | Passerelle permettant aux instances dans des subnets publics d'accéder à Internet | igw-xxxxx | [AWS IGW](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/VPC_Internet_Gateway.html) |
| **NAT Gateway (NGW)** | Passerelle permettant aux instances dans des subnets privés d'accéder à Internet | nat-xxxxx | [AWS NAT Gateway](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/vpc-nat-gateway.html) |
| **Route Table** | Table définissant comment le trafic réseau est routé | rtb-xxxxx | [AWS Route Tables](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/VPC_Route_Tables.html) |
| **Security Group** | Firewall virtuel pour les instances EC2, contrôlant le trafic entrant et sortant | sg-xxxxx | [AWS Security Groups](https://docs.aws.amazon.com/fr_fr/AWSEC2/latest/UserGuide/ec2-security-groups.html) |
| **Network ACL** | Liste de contrôle d'accès réseau pour les subnets | acl-xxxxx | [AWS NACL](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/vpc-network-acls.html) |
| **CIDR** | Classless Inter-Domain Routing : Notation pour définir des plages d'adresses IP | 10.0.0.0/16, 192.168.1.0/24 | [Wikipédia](https://fr.wikipedia.org/wiki/Classless_Inter-Domain_Routing) |
| **IP Publique** | Adresse IP accessible depuis Internet | 52.47.123.45 | - |
| **IP Privée** | Adresse IP accessible uniquement dans le VPC | 10.0.1.123 | - |
| **DNS** | Domain Name System : Système de nommage hiérarchique pour les adresses IP | ec2-52-47-123-45.eu-west-3.compute.amazonaws.com | [Wikipédia](https://fr.wikipedia.org/wiki/Domain_Name_System) |

---

## ⛏️ **Terraform**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Terraform** | Outil d'Infrastructure-as-Code (IaC) développé par HashiCorp pour provisionner et gérer des infrastructures cloud | - | [terraform.io](https://www.terraform.io) |
| **IaC** | Infrastructure as Code : Pratique consistant à gérer l'infrastructure via du code | Terraform, AWS CloudFormation | [Wikipédia](https://en.wikipedia.org/wiki/Infrastructure_as_code) |
| **Provider** | Plugin Terraform permettant d'interagir avec un cloud ou un service | aws, azure, google | [Terraform Providers](https://developer.hashicorp.com/terraform/plugin) |
| **Resource** | Élément d'infrastructure géré par Terraform | aws_instance, aws_vpc | [Terraform Resources](https://developer.hashicorp.com/terraform/language/resources) |
| **Module** | Ensemble de ressources Terraform réutilisables | module "vpc" { ... } | [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules) |
| **Variable** | Paramètre configurable dans Terraform | variable "instance_type" | [Terraform Variables](https://developer.hashicorp.com/terraform/language/values/variables) |
| **Output** | Valeur retournée par Terraform après application | output "public_ip" | [Terraform Outputs](https://developer.hashicorp.com/terraform/language/values/outputs) |
| **State** | Fichier stockant l'état actuel de l'infrastructure | terraform.tfstate | [Terraform State](https://developer.hashicorp.com/terraform/language/state) |
| **Backend** | Endroit où le state Terraform est stocké | S3, local | [Terraform Backends](https://developer.hashicorp.com/terraform/language/settings/backends) |
| **Workspace** | Espace de travail Terraform permettant de gérer plusieurs états | default, dev, prod | [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/workspaces) |
| **terraform init** | Commande pour initialiser Terraform et télécharger les providers | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/init) |
| **terraform plan** | Commande pour prévisualiser les changements | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/plan) |
| **terraform apply** | Commande pour appliquer les changements | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/apply) |
| **terraform destroy** | Commande pour supprimer toutes les ressources | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/destroy) |
| **terraform output** | Commande pour afficher les outputs | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/output) |
| **terraform state** | Commande pour gérer le state Terraform | - | [Doc](https://developer.hashicorp.com/terraform/cli/commands/state) |

---

## 🎭 **Ansible**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Ansible** | Outil d'automatisation open source pour la configuration, le déploiement et l'orchestration | - | [ansible.com](https://www.ansible.com) |
| **Configuration Management** | Pratique consistant à gérer la configuration des serveurs de manière automatisée | Ansible, Puppet, Chef | [Wikipédia](https://en.wikipedia.org/wiki/Configuration_management) |
| **Playbook** | Fichier YAML contenant une série de tâches à exécuter sur des serveurs | deploy-nginx.yml | [Ansible Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) |
| **Inventory** | Fichier listant les serveurs à configurer | inventory.ini | [Ansible Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) |
| **Role** | Organisation des tâches Ansible par rôle | roles/nginx/ | [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) |
| **Task** | Une action à exécuter sur un serveur | Installer NGINX | [Ansible Tasks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#tasks) |
| **Handler** | Tâche déclenchée par un changement | Redémarrer NGINX | [Ansible Handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html) |
| **Module** | Fonctionnalité réutilisable dans Ansible | apt, yum, copy | [Ansible Modules](https://docs.ansible.com/ansible/latest/user_guide/modules.html) |
| **Template** | Fichier Jinja2 utilisé pour générer des fichiers de configuration | nginx.conf.j2 | [Ansible Templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) |
| **Variable** | Paramètre configurable dans Ansible | vars: { nginx_version: "1.23" } | [Ansible Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html) |
| **Fact** | Information collectée sur les serveurs cibles | ansible_facts | [Ansible Facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#accessing-facts) |
| **Ad-hoc Command** | Commande Ansible exécutée directement sans playbook | ansible all -m ping | [Ansible Ad-hoc](https://docs.ansible.com/ansible/latest/user_guide/intro_adhoc.html) |
| **ansible-playbook** | Commande pour exécuter un playbook | - | [Doc](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html) |
| **ansible** | Commande pour exécuter des commandes ad-hoc | - | [Doc](https://docs.ansible.com/ansible/latest/cli/ansible.html) |

---

## 🌐 **Serveurs Web et Proxy**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **NGINX** | Serveur web open source, reverse proxy et load balancer | nginx -v | [nginx.org](https://nginx.org) |
| **Serveur Web** | Logiciel servant des pages web | NGINX, Apache | [Wikipédia](https://fr.wikipedia.org/wiki/Serveur_web) |
| **Reverse Proxy** | Serveur agissant comme intermédiaire entre les clients et les serveurs backend | NGINX, HAProxy | [Wikipédia](https://fr.wikipedia.org/wiki/Proxy_inverse) |
| **Load Balancer** | Dispositif répartissant la charge entre plusieurs serveurs | HAProxy, NGINX, ALB | [Wikipédia](https://fr.wikipedia.org/wiki/R%C3%A9partition_de_charge) |
| **HAProxy** | Load Balancer open source haute performance | haproxy -v | [haproxy.org](https://www.haproxy.org) |
| **HTTP** | HyperText Transfer Protocol : Protocole de communication pour le web | Port 80 | [Wikipédia](https://fr.wikipedia.org/wiki/Hypertext_Transfer_Protocol) |
| **HTTPS** | HTTP Secure : HTTP avec chiffrement SSL/TLS | Port 443 | [Wikipédia](https://fr.wikipedia.org/wiki/Hypertext_Transfer_Protocol_Secure) |
| **SSL/TLS** | Protocoles de chiffrement pour sécuriser les communications | Certificat SSL | [Wikipédia](https://fr.wikipedia.org/wiki/Transport_Layer_Security) |
| **Port** | Numéro utilisé pour identifier un service sur un serveur | 80 (HTTP), 443 (HTTPS) | [Wikipédia](https://fr.wikipedia.org/wiki/Port_(informatique)) |
| **Virtual Host** | Configuration permettant d'héberger plusieurs sites web sur un seul serveur | Server Name | [NGINX Virtual Hosts](https://nginx.org/en/docs/http/ngx_http_core_module.html#server) |
| **Static File** | Fichier servi tel quel par le serveur web | index.html | - |
| **Dynamic Content** | Contenu généré dynamiquement par une application | PHP, Node.js | - |

---

## 🔍 **OpenSearch et ELK Stack**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **OpenSearch** | Moteur de recherche et d'analyse open source (fork d'Elasticsearch) | opensearch -v | [opensearch.org](https://opensearch.org) |
| **Elasticsearch** | Moteur de recherche et d'analyse distribué (licence SSPL) | - | [elastic.co](https://www.elastic.co/elasticsearch/) |
| **Kibana** | Interface de visualisation pour Elasticsearch/OpenSearch | - | [elastic.co/kibana](https://www.elastic.co/kibana/) |
| **OpenSearch Dashboards** | Interface de visualisation pour OpenSearch (fork de Kibana) | - | [opensearch.org/docs/dashboards](https://opensearch.org/docs/dashboards/) |
| **Logstash** | Pipeline de traitement de données pour la stack ELK | logstash -v | [elastic.co/logstash](https://www.elastic.co/logstash/) |
| **Beats** | Agents légers pour collecter des données | Filebeat, Metricbeat | [elastic.co/beats](https://www.elastic.co/beats/) |
| **Filebeat** | Beat pour collecter des fichiers de logs | filebeat -v | [elastic.co/beats/filebeat](https://www.elastic.co/beats/filebeat) |
| **Metricbeat** | Beat pour collecter des métriques système | metricbeat -v | [elastic.co/beats/metricbeat](https://www.elastic.co/beats/metricbeat) |
| **ELK Stack** | Ensemble Elasticsearch + Logstash + Kibana | - | [elastic.co/elk-stack](https://www.elastic.co/elk-stack) |
| **Cluster** | Ensemble de nœuds OpenSearch/Elasticsearch travaillant ensemble | - | [OpenSearch Cluster](https://opensearch.org/docs/latest/opensearch/rest-api/cluster/) |
| **Node** | Serveur individuel dans un cluster OpenSearch | Master Node, Data Node | [OpenSearch Nodes](https://opensearch.org/docs/latest/opensearch/node-roles/) |
| **Index** | Ensemble de documents similaires dans OpenSearch | logs-nginx-2024.01.01 | [OpenSearch Index](https://opensearch.org/docs/latest/opensearch/rest-api/index/) |
| **Document** | Unité de base de stockage dans OpenSearch (format JSON) | { "field": "value" } | [OpenSearch Document](https://opensearch.org/docs/latest/opensearch/rest-api/document/) |
| **Shard** | Partition d'un index OpenSearch | - | [OpenSearch Shards](https://opensearch.org/docs/latest/opensearch/index-modules/index-sharding/) |
| **Replica** | Copie d'un shard pour la redondance | - | [OpenSearch Replicas](https://opensearch.org/docs/latest/opensearch/index-modules/index-replication/) |
| **Pipeline** | Ensemble d'étapes pour traiter des données dans Logstash | Input → Filter → Output | [Logstash Pipeline](https://www.elastic.co/guide/en/logstash/current/pipeline-to-pipeline.html) |
| **Input Plugin** | Plugin Logstash pour collecter des données | beats, file, syslog | [Logstash Inputs](https://www.elastic.co/guide/en/logstash/current/input-plugins.html) |
| **Filter Plugin** | Plugin Logstash pour transformer des données | grok, mutate, date | [Logstash Filters](https://www.elastic.co/guide/en/logstash/current/filter-plugins.html) |
| **Output Plugin** | Plugin Logstash pour envoyer des données | opensearch, elasticsearch | [Logstash Outputs](https://www.elastic.co/guide/en/logstash/current/output-plugins.html) |
| **Grok** | Langage de parsing pour extraire des données structurées de texte non structuré | %{IPORHOST:client_ip} | [Grok Documentation](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html) |
| **Index Pattern** | Configuration dans Kibana pour accéder à un ensemble d'index | logs-nginx-* | [Kibana Index Patterns](https://www.elastic.co/guide/en/kibana/current/index-patterns.html) |
| **Visualization** | Représentation graphique des données dans Kibana | Bar chart, Pie chart | [Kibana Visualizations](https://www.elastic.co/guide/en/kibana/current/visualize.html) |
| **Dashboard** | Tableau de bord combinant plusieurs visualisations | - | [Kibana Dashboards](https://www.elastic.co/guide/en/kibana/current/dashboard.html) |
| **Discover** | Interface Kibana pour explorer les données | - | [Kibana Discover](https://www.elastic.co/guide/en/kibana/current/discover.html) |

---

## 💾 **Stockage et Bases de Données**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **NoSQL** | Base de données non relationnelle, sans schéma fixe | OpenSearch, MongoDB | [Wikipédia](https://fr.wikipedia.org/wiki/NoSQL) |
| **SQL** | Base de données relationnelle avec schéma fixe | MySQL, PostgreSQL | [Wikipédia](https://fr.wikipedia.org/wiki/SQL) |
| **Base de Données** | Système organisé pour stocker et récupérer des données | MySQL, OpenSearch | [Wikipédia](https://fr.wikipedia.org/wiki/Base_de_donn%C3%A9es) |
| **JSON** | JavaScript Object Notation : Format de données léger et lisible | { "key": "value" } | [json.org](https://www.json.org/) |
| **YAML** | YAML Ain't Markup Language : Format de sérialisation de données lisible | key: value | [yaml.org](https://yaml.org/) |
| **EBS** | Elastic Block Store : Stockage persistant pour les instances EC2 | vol-xxxxx | [AWS EBS](https://docs.aws.amazon.com/fr_fr/AWSEC2/latest/UserGuide/AmazonEBS.html) |
| **Volume** | Stockage attachable à une instance EC2 | /dev/xvda | [AWS Volumes](https://docs.aws.amazon.com/fr_fr/AWSEC2/latest/UserGuide/Storage.html) |
| **Snapshot** | Copie de sauvegarde d'un volume EBS | snap-xxxxx | [AWS Snapshots](https://docs.aws.amazon.com/fr_fr/AWSEC2/latest/UserGuide/EBSSnapshots.html) |

---

## 🖥️ **Systèmes d'Exploitation et Réseau**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Linux** | Système d'exploitation open source basé sur Unix | Ubuntu, Amazon Linux | [Wikipédia](https://fr.wikipedia.org/wiki/Linux) |
| **Amazon Linux** | Distribution Linux optimisée pour AWS | Amazon Linux 2 | [AWS Amazon Linux](https://aws.amazon.com/amazon-linux-2/) |
| **Ubuntu** | Distribution Linux populaire | Ubuntu 22.04 LTS | [ubuntu.com](https://ubuntu.com) |
| **CentOS** | Distribution Linux basée sur RHEL | CentOS 7 | [centos.org](https://www.centos.org) |
| **SSH** | Secure Shell : Protocole pour se connecter à distance à un serveur | ssh user@host | [Wikipédia](https://fr.wikipedia.org/wiki/Secure_Shell) |
| **Bash** | Shell Unix par défaut sur la plupart des distributions Linux | #!/bin/bash | [Wikipédia](https://fr.wikipedia.org/wiki/Bourne-Again_shell) |
| **Systemd** | Système d'initialisation et de gestion des services sous Linux | systemctl start nginx | [freedesktop.org](https://www.freedesktop.org/software/systemd/man/systemd.html) |
| **Cron** | Planificateur de tâches sous Linux | crontab -e | [Wikipédia](https://fr.wikipedia.org/wiki/Cron) |
| **IP** | Internet Protocol : Adresse unique identifiant un appareil sur un réseau | 192.168.1.1 | [Wikipédia](https://fr.wikipedia.org/wiki/Adresse_IP) |
| **TCP** | Transmission Control Protocol : Protocole de communication fiable | Port 80 (HTTP) | [Wikipédia](https://fr.wikipedia.org/wiki/Transmission_Control_Protocol) |
| **UDP** | User Datagram Protocol : Protocole de communication non fiable | Port 53 (DNS) | [Wikipédia](https://fr.wikipedia.org/wiki/User_Datagram_Protocol) |
| **DNS** | Domain Name System : Système de nommage pour les adresses IP | google.com → 8.8.8.8 | [Wikipédia](https://fr.wikipedia.org/wiki/Domain_Name_System) |
| **Firewall** | Système de sécurité contrôlant le trafic réseau | iptables, ufw | [Wikipédia](https://fr.wikipedia.org/wiki/Pare-feu_(informatique)) |
| **Port** | Numéro utilisé pour identifier un service sur un serveur | 22 (SSH), 80 (HTTP) | [Wikipédia](https://fr.wikipedia.org/wiki/Port_(informatique)) |

---

## 🔧 **DevOps et Bonnes Pratiques**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **DevOps** | Ensemble de pratiques visant à améliorer la collaboration entre les équipes de développement et d'exploitation | CI/CD, IaC | [Wikipédia](https://fr.wikipedia.org/wiki/DevOps) |
| **CI/CD** | Continuous Integration / Continuous Delivery : Pratiques d'automatisation du développement logiciel | GitHub Actions, Jenkins | [Wikipédia](https://fr.wikipedia.org/wiki/Int%C3%A9gration_continue) |
| **Infrastructure as Code (IaC)** | Pratique consistant à gérer l'infrastructure via du code | Terraform, AWS CloudFormation | [Wikipédia](https://en.wikipedia.org/wiki/Infrastructure_as_code) |
| **Configuration Management** | Pratique consistant à gérer la configuration des serveurs de manière automatisée | Ansible, Puppet, Chef | [Wikipédia](https://en.wikipedia.org/wiki/Configuration_management) |
| **Version Control** | Système de gestion des versions du code | Git, SVN | [Wikipédia](https://fr.wikipedia.org/wiki/Contr%C3%B4le_de_version) |
| **Git** | Système de contrôle de version distribué | git commit, git push | [git-scm.com](https://git-scm.com) |
| **GitHub** | Plateforme d'hébergement de code utilisant Git | github.com | [github.com](https://github.com) |
| **Repository** | Dépôt de code versionné | mathiasseguincadiche/p5_Openclassrooms | - |
| **Branch** | Version parallèle d'un repository | main, dev, feature | [Git Branching](https://git-scm.com/book/fr/v2/Git-branching-Branches-et-fusions-de-base) |
| **Commit** | Sauvegarde d'un état du code dans Git | git commit -m "message" | [Git Commit](https://git-scm.com/book/fr/v2/Les-bases-de-Git-Enregistrer-des-modifications-dans-le-d%C3%A9p%C3%B4t) |
| **Push** | Envoi des commits vers un repository distant | git push origin main | [Git Push](https://git-scm.com/docs/git-push) |
| **Pull** | Récupération des commits depuis un repository distant | git pull origin main | [Git Pull](https://git-scm.com/docs/git-pull) |
| **Merge** | Fusion de branches | git merge branch | [Git Merge](https://git-scm.com/docs/git-merge) |
| **Pull Request** | Demande de fusion de branches sur GitHub | PR #123 | [GitHub PR](https://docs.github.com/en/pull-requests) |
| **Issue** | Ticket pour suivre un bug ou une fonctionnalité | Issue #456 | [GitHub Issues](https://docs.github.com/en/issues) |
| **CI Pipeline** | Pipeline d'intégration continue | GitHub Actions Workflow | [GitHub Actions](https://docs.github.com/en/actions) |
| **CD Pipeline** | Pipeline de livraison continue | Deployment to AWS | - |
| **Monitoring** | Surveillance des systèmes et applications | CloudWatch, Prometheus | [Wikipédia](https://fr.wikipedia.org/wiki/Monitoring) |
| **Logging** | Collecte et stockage des logs | OpenSearch, ELK | [Wikipédia](https://fr.wikipedia.org/wiki/Journalisation) |
| **Alerting** | Système de notification en cas de problème | CloudWatch Alarms | - |
| **Scalability** | Capacité d'un système à s'adapter à une charge variable | Auto Scaling | [Wikipédia](https://fr.wikipedia.org/wiki/Scalability) |
| **High Availability (HA)** | Capacité d'un système à rester disponible malgré des pannes | Multi-AZ, Load Balancer | [Wikipédia](https://fr.wikipedia.org/wiki/Haute_disponibilit%C3%A9) |
| **Fault Tolerance** | Capacité d'un système à continuer de fonctionner malgré des pannes | Redondance, Replicas | [Wikipédia](https://fr.wikipedia.org/wiki/Tol%C3%A9rance_aux_pannes) |
| **Load Balancing** | Répartition de la charge entre plusieurs serveurs | HAProxy, ALB | [Wikipédia](https://fr.wikipedia.org/wiki/R%C3%A9partition_de_charge) |
| **Health Check** | Vérification automatique de la santé d'un serveur | HTTP 200 OK | - |

---

## 💰 **Coûts et Facturation**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Coût AWS** | Montant facturé pour l'utilisation des services AWS | ~$50/mois | [AWS Pricing](https://aws.amazon.com/pricing/) |
| **Pay-as-you-go** | Modèle de facturation où vous payez pour ce que vous utilisez | EC2, S3 | [AWS Pay-as-you-go](https://aws.amazon.com/pricing/pay-as-you-go/) |
| **Reserved Instance** | Instance EC2 réservée pour une durée déterminée à prix réduit | 1 an, 3 ans | [AWS Reserved Instances](https://aws.amazon.com/ec2/pricing/reserved-instances/) |
| **Spot Instance** | Instance EC2 à prix réduit, mais pouvant être interrompue | ~70% moins cher | [AWS Spot Instances](https://aws.amazon.com/ec2/spot/) |
| **On-Demand Instance** | Instance EC2 facturée à la seconde | t2.micro | [AWS On-Demand](https://aws.amazon.com/ec2/pricing/on-demand/) |
| **Billing Alert** | Alerte de facturation pour surveiller les coûts | $100 threshold | [AWS Billing Alerts](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-billing-alerts.html) |
| **Cost Explorer** | Outil AWS pour analyser les coûts | - | [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/) |
| **Budget** | Outil AWS pour définir des budgets et recevoir des alertes | $50/mois | [AWS Budgets](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets.html) |

---

## 🔐 **Sécurité**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Sécurité** | Ensemble des pratiques et technologies pour protéger les systèmes | - | [Wikipédia](https://fr.wikipedia.org/wiki/S%C3%A9curit%C3%A9_informatique) |
| **IAM** | Identity and Access Management : Service AWS pour gérer les utilisateurs et permissions | - | [AWS IAM](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/introduction.html) |
| **Utilisateur IAM** | Compte utilisateur dans AWS | p5-user | [AWS IAM Users](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/id_users.html) |
| **Groupe IAM** | Groupe d'utilisateurs IAM | Developers, Admins | [AWS IAM Groups](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/id_groups.html) |
| **Rôle IAM** | Rôle avec des permissions spécifiques | EC2-ReadOnly | [AWS IAM Roles](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/id_roles.html) |
| **Policy IAM** | Ensemble de permissions | AdministratorAccess | [AWS IAM Policies](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/access_policies.html) |
| **Permission** | Autorisation d'effectuer une action | ec2:DescribeInstances | [AWS IAM Permissions](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/reference_policies.html) |
| **MFA** | Multi-Factor Authentication : Authentification à deux facteurs | Google Authenticator | [AWS MFA](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/id_credentials_mfa.html) |
| **Clé d'Accès** | Identifiant pour accéder à AWS via l'API | AKIAIOSFODNN7EXAMPLE | [AWS Access Keys](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/id_credentials_access-keys.html) |
| **Clé Secrète** | Clé secrète associée à la clé d'accès | wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY | [AWS Secret Keys](https://docs.aws.amazon.com/fr_fr/IAM/latest/UserGuide/id_credentials_access-keys.html) |
| **SSH Key** | Paire de clés pour l'authentification SSH | id_rsa, id_rsa.pub | [SSH Keys](https://www.ssh.com/academy/ssh/keygen) |
| **Clé Privée** | Clé SSH à garder secrète | ~/.ssh/id_rsa | - |
| **Clé Publique** | Clé SSH à partager | ~/.ssh/id_rsa.pub | - |
| **Chiffrement** | Processus de transformation de données en un format illisible | AES, RSA | [Wikipédia](https://fr.wikipedia.org/wiki/Chiffrement) |
| **SSL** | Secure Sockets Layer : Protocole de chiffrement pour les communications | HTTPS | [Wikipédia](https://fr.wikipedia.org/wiki/Secure_Sockets_Layer) |
| **TLS** | Transport Layer Security : Successeur de SSL | HTTPS | [Wikipédia](https://fr.wikipedia.org/wiki/Transport_Layer_Security) |
| **Certificat** | Fichier prouvant l'authenticité d'une entité | certificate.crt | [Wikipédia](https://fr.wikipedia.org/wiki/Certificat_%C3%A9lectronique) |
| **CA** | Certificate Authority : Autorité de certification | Let's Encrypt | [Wikipédia](https://fr.wikipedia.org/wiki/Autorit%C3%A9_de_certification) |
| **Firewall** | Système de sécurité contrôlant le trafic réseau | Security Group, NACL | [Wikipédia](https://fr.wikipedia.org/wiki/Pare-feu_(informatique)) |
| **ACL** | Access Control List : Liste de contrôle d'accès | Network ACL | [Wikipédia](https://fr.wikipedia.org/wiki/Access_Control_List) |

---

## 📊 **Monitoring et Observabilité**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Monitoring** | Surveillance des systèmes et applications | CloudWatch, Prometheus | [Wikipédia](https://fr.wikipedia.org/wiki/Monitoring) |
| **Observabilité** | Capacité à comprendre l'état d'un système à partir de ses sorties (logs, métriques, traces) | OpenSearch, Jaeger | [Wikipédia](https://en.wikipedia.org/wiki/Observability) |
| **Log** | Enregistrement d'un événement dans un système | /var/log/nginx/access.log | [Wikipédia](https://fr.wikipedia.org/wiki/Journalisation) |
| **Métrique** | Mesure quantitative d'un aspect d'un système | CPU Usage, Memory Usage | - |
| **Trace** | Enregistrement du chemin suivi par une requête dans un système distribué | Distributed Tracing | [Wikipédia](https://en.wikipedia.org/wiki/Distributed_tracing) |
| **Alert** | Notification automatique en cas de problème | CPU > 90% | - |
| **Dashboard** | Tableau de bord visualisant des données | Kibana Dashboard | - |
| **Visualization** | Représentation graphique de données | Bar Chart, Pie Chart | - |
| **Index** | Structure de données optimisée pour la recherche | OpenSearch Index | - |
| **Query** | Requête pour rechercher des données | SQL, DSL | - |
| **Aggregation** | Opération pour regrouper et analyser des données | Sum, Avg, Count | - |
| **Filter** | Opération pour filtrer des données | status: 200 | - |

---

## 📦 **Conteneurs et Orchestration**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **Conteneur** | Environnement isolé et léger pour exécuter des applications | Docker Container | [Wikipédia](https://fr.wikipedia.org/wiki/Conteneur_(virtualisation)) |
| **Docker** | Plateforme open source pour développer, livrer et exécuter des applications dans des conteneurs | docker run nginx | [docker.com](https://www.docker.com) |
| **Image Docker** | Modèle pour créer un conteneur | nginx:latest | [Docker Images](https://docs.docker.com/engine/reference/commandline/images/) |
| **Dockerfile** | Fichier de configuration pour construire une image Docker | FROM nginx | [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/) |
| **Docker Hub** | Registry public pour les images Docker | hub.docker.com | [Docker Hub](https://hub.docker.com) |
| **Kubernetes** | Système d'orchestration de conteneurs | kubectl apply | [kubernetes.io](https://kubernetes.io) |
| **Pod** | Unité de déploiement Kubernetes (1 ou plusieurs conteneurs) | - | [Kubernetes Pods](https://kubernetes.io/docs/concepts/workloads/pods/) |
| **Deployment** | Objet Kubernetes pour gérer des pods | - | [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) |
| **Service** | Objet Kubernetes pour exposer des pods | - | [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/) |
| **Ingress** | Objet Kubernetes pour gérer l'accès HTTP | - | [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) |
| **Orchestration** | Gestion automatisée du cycle de vie des conteneurs | Kubernetes, Docker Swarm | [Wikipédia](https://en.wikipedia.org/wiki/Orchestration_(computing)) |

---

## 🚀 **Autres Termes Utiles**

| Terme | Définition | Exemple | Lien |
|-------|------------|---------|------|
| **API** | Application Programming Interface : Interface pour interagir avec un service | REST API, GraphQL | [Wikipédia](https://fr.wikipedia.org/wiki/Interface_de_programmation) |
| **REST** | Representational State Transfer : Style d'architecture pour les API | GET /api/users | [Wikipédia](https://fr.wikipedia.org/wiki/REST) |
| **JSON** | JavaScript Object Notation : Format de données léger | { "key": "value" } | [json.org](https://www.json.org/) |
| **YAML** | YAML Ain't Markup Language : Format de sérialisation de données | key: value | [yaml.org](https://yaml.org/) |
| **XML** | eXtensible Markup Language : Format de données structuré | <tag>value</tag> | [Wikipédia](https://fr.wikipedia.org/wiki/Extensible_Markup_Language) |
| **CLI** | Command Line Interface : Interface en ligne de commande | bash, zsh | [Wikipédia](https://fr.wikipedia.org/wiki/Interface_en_ligne_de_commande) |
| **GUI** | Graphical User Interface : Interface graphique | Windows, macOS | [Wikipédia](https://fr.wikipedia.org/wiki/Interface_graphique) |
| **Script** | Programme exécuté par un interpréteur | Bash Script, Python Script | [Wikipédia](https://fr.wikipedia.org/wiki/Script_(informatique)) |
| **Automatisation** | Utilisation de technologie pour exécuter des tâches sans intervention humaine | Ansible, Terraform | [Wikipédia](https://fr.wikipedia.org/wiki/Automatisation) |
| **Idempotent** | Propriété d'une opération qui produit le même résultat si elle est exécutée plusieurs fois | Ansible Playbook | [Wikipédia](https://en.wikipedia.org/wiki/Idempotence) |
| **Immutable** | Propriété d'un objet qui ne peut pas être modifié après sa création | Infrastructure Immutable | [Wikipédia](https://en.wikipedia.org/wiki/Immutable_object) |
| **Stateless** | Propriété d'un système qui ne stocke pas d'état entre les requêtes | REST API | [Wikipédia](https://en.wikipedia.org/wiki/Stateless_protocol) |
| **Stateful** | Propriété d'un système qui stocke un état entre les requêtes | Session | [Wikipédia](https://en.wikipedia.org/wiki/Stateful_protocol) |

---

## 📚 **Résumé par Catégorie**

| Catégorie | Nombre de Termes | Termes Clés |
|----------|------------------|-------------|
| **Cloud Computing et AWS** | 10 | AWS, IaaS, Région, AZ, Free Tier |
| **Infrastructure et Réseau** | 15 | VPC, Subnet, Security Group, CIDR, DNS |
| **Terraform** | 15 | Terraform, IaC, Provider, Resource, State |
| **Ansible** | 15 | Ansible, Playbook, Inventory, Role, Task |
| **Serveurs Web et Proxy** | 15 | NGINX, HAProxy, HTTP, HTTPS, Reverse Proxy |
| **OpenSearch et ELK Stack** | 25 | OpenSearch, Elasticsearch, Kibana, Logstash, Beats |
| **Stockage et Bases de Données** | 10 | NoSQL, SQL, JSON, YAML, EBS |
| **Systèmes d'Exploitation et Réseau** | 15 | Linux, SSH, Bash, Systemd, TCP/UDP |
| **DevOps et Bonnes Pratiques** | 25 | DevOps, CI/CD, IaC, Git, GitHub |
| **Coûts et Facturation** | 10 | Coût AWS, Pay-as-you-go, Reserved Instance |
| **Sécurité** | 20 | IAM, MFA, SSL, TLS, Firewall |
| **Monitoring et Observabilité** | 15 | Monitoring, Log, Métrique, Dashboard |
| **Conteneurs et Orchestration** | 10 | Conteneur, Docker, Kubernetes, Pod |
| **Autres Termes Utiles** | 15 | API, REST, JSON, CLI, Automatisation |

---

## 🎯 **Comment Utiliser ce Glossaire**

1. **Recherche rapide** : Utilisez `Ctrl+F` (ou `Cmd+F` sur Mac) pour trouver un terme spécifique
2. **Apprentissage** : Lisez les définitions des termes que vous ne connaissez pas
3. **Révision** : Relisez ce glossaire avant l'évaluation pour rafraîchir votre mémoire
4. **Référence** : Consultez ce glossaire pendant le développement si vous oubliez un concept

---

## 📌 **Termes à Connaître Absolument**

Pour réussir ce projet, vous devez **maîtriser** les termes suivants :

### **Niveau 1 : Fondamentaux**
- AWS
- VPC
- Subnet
- EC2
- Security Group
- SSH
- HTTP/HTTPS
- Git
- Terraform
- Ansible

### **Niveau 2 : Intermédiaire**
- IaC (Infrastructure as Code)
- Configuration Management
- Load Balancer
- Reverse Proxy
- OpenSearch/Elasticsearch
- Logstash
- Filebeat
- Kibana
- NGINX
- HAProxy

### **Niveau 3 : Avancé**
- Cluster
- Node (Master, Data)
- Index
- Document
- Shard
- Replica
- Pipeline (Logstash)
- Grok
- Index Pattern
- Visualization
- Dashboard

---

**Bonne étude !** 📚

> *"La connaissance est un trésor, mais la pratique en est la clé."* — **Lao Tseu**

> *"Apprendre sans réfléchir est vain. Réfléchir sans apprendre est dangereux."* — **Confucius**
