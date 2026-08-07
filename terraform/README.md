# Terraform — infrastructure AWS du projet P5

Ce dossier contient les trois modules Terraform correspondant aux trois exercices
du P5. Ils partagent des garde-fous communs mais **ne sont pas indépendants de la
même manière** : l’exercice 3 réutilise le réseau et la paire de clés de
l’exercice 1.

## Vue d’ensemble

| Module | Rôle | Ressources principales | Dépendance |
| --- | --- | --- | --- |
| `exercice-1/` | cible Terraform + Ansible | VPC, 2 subnets, IGW, route, SG, key pair, 1 EC2 | aucune |
| `exercice-2/` | observabilité Cloud | 1 domaine Amazon OpenSearch | indépendant |
| `exercice-3/` | disponibilité | 1 HAProxy + 2 backends EC2 | réseau + clé de l’exercice 1 |

Architecture détaillée :
[`docs/architecture-et-flux.md`](../docs/architecture-et-flux.md).

## Source unique des variables locales

Les vrais `terraform.tfvars` ne sont pas maintenus manuellement.

La source de configuration est :

```text
environment/aws-readiness.env
```

Puis :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Le script génère :

```text
terraform/exercice-1/terraform.tfvars
terraform/exercice-2/terraform.tfvars
terraform/exercice-3/terraform.tfvars
```

Ces fichiers sont locaux, écrits en mode `600` et ignorés par Git.

Les `terraform.tfvars.example` restent uniquement des modèles documentaires.

## Garde-fous communs

Chaque provider AWS utilise :

```text
allowed_account_ids = [var.expected_aws_account_id]
```

et les tags :

```text
Project   = p5-openclassrooms
ManagedBy = Terraform
Purpose   = training-lab
Exercise  = 1, 2 ou 3
```

Les trois modules :

- refusent un identifiant de compte d’exemple ;
- exigent une IPv4 d’administration en `/32` ;
- utilisent la même région provenant de la configuration locale ;
- sont contrôlés par `pre-deployment-check.sh` avant les déploiements.

## Workflow Terraform recommandé

Pour chaque module :

```bash
terraform -chdir=terraform/exercice-X init
terraform -chdir=terraform/exercice-X fmt -check
terraform -chdir=terraform/exercice-X validate
terraform -chdir=terraform/exercice-X plan -out=tfplan
terraform -chdir=terraform/exercice-X show tfplan
terraform -chdir=terraform/exercice-X apply tfplan
```

Le plan doit être lu avant `apply`.

Vérifier notamment :

- compte ;
- région ;
- type et nombre de ressources ;
- réseau ;
- accès `/32` ;
- chiffrement ;
- coûts potentiels.

## Exercice 1

### Ressources

```text
VPC 10.0.0.0/16
├── p5-public-1
├── p5-public-2
├── Internet Gateway
├── table de routage publique
├── p5-web-sg
├── p5-key
└── p5-web EC2
```

L’EC2 :

- utilise `t3.micro` par défaut ;
- sélectionne automatiquement Ubuntu 24.04 LTS Canonical si `ami_id = null` ;
- exige IMDSv2 ;
- utilise un volume racine `gp3` chiffré ;
- reçoit Python 3 via `user_data` pour permettre Ansible.

### Réseau

- SSH 22 : uniquement `your_ip_cidr` ;
- HTTP 80 : public pour la démonstration.

### Outputs

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_private_ip
web_public_dns
web_url
```

`web_public_ip` alimente l’inventaire Ansible et `web_url` est utilisé par les
scripts HTTP.

## Exercice 2

### Ressource

Un domaine Amazon OpenSearch Service :

- moteur `OpenSearch_2.19` par défaut ;
- `t3.small.search` par défaut ;
- 1 nœud ;
- 10 Gio `gp3` par défaut ;
- HTTPS obligatoire ;
- TLS 1.2 minimum ;
- chiffrement au repos ;
- chiffrement inter-nœuds ;
- accès limité à `your_ip_cidr`.

### Outputs

```text
opensearch_domain_name
opensearch_endpoint
opensearch_arn
opensearch_dashboards_endpoint
```

L’endpoint principal est utilisé automatiquement par les scripts d’import et de
validation lorsque l’option `--endpoint` n’est pas fournie.

## Exercice 3

### Ressources importées

Le module recherche :

- le VPC de l’exercice 1 ;
- ses sous-réseaux publics ;
- la paire de clés créée pendant l’exercice 1.

La sélection du réseau s’appuie sur les tags du projet.

### Ressources créées

```text
p5-haproxy
├── HTTP public :80
├── SSH depuis /32
└── HAProxy roundrobin

p5-hello-1
└── Docker → nginxdemos/hello

p5-hello-2
└── Docker → nginxdemos/hello
```

Les backends n’acceptent le trafic HTTP que depuis le groupe de sécurité
HAProxy.

Les trois instances imposent IMDSv2 et des volumes racine `gp3` chiffrés.

### Health checks HAProxy

```text
GET /
inter 3s
fall 3
rise 2
```

### Outputs

```text
hello_1_public_ip
hello_2_public_ip
hello_1_private_ip
hello_2_private_ip
haproxy_public_ip
haproxy_private_ip
haproxy_public_dns
haproxy_security_group_id
haproxy_url
```

## États Terraform

Chaque exercice possède son propre état local.

Ne versionnez jamais :

```text
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
tfplan
.terraform/
```

Le dépôt ignore ces fichiers.

### Ne jamais supprimer l’état avant le nettoyage

Un état absent peut empêcher Terraform de connaître les ressources qu’il doit
détruire.

`clean-local.sh` conserve volontairement les états.

## Dépendances et destruction

Dépendance :

```text
Exercice 1 ──► Exercice 3
```

Ordre de destruction :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Commande recommandée :

```bash
./scripts/commands/destroy-aws.sh
```

Le script :

- exige `DETRUIRE` ;
- inspecte l’état local ;
- détruit dans l’ordre 3 → 2 → 1 ;
- signale lorsqu’un état local manque.

Puis :

```bash
./scripts/commands/check-aws-cleanup.sh
```

Verdict attendu uniquement après fermeture globale :

```text
NETTOYAGE AWS COMPLET
```

## Validation locale

```bash
terraform fmt -check -recursive terraform
./scripts/commands/validate.sh
```

La CI initialise les trois modules avec backend désactivé et exécute
`terraform validate`.

## Sécurité et coûts

Avant chaque création :

```bash
./scripts/commands/pre-deployment-check.sh --stage ETAPE
```

Ne supposez jamais qu’une ressource est gratuite. Le contrôle vérifie notamment
le quota EC2, la disponibilité des types, OpenSearch et le budget, mais la lecture
du plan et des coûts reste une responsabilité humaine.

## Documentation associée

- [Architecture](../docs/architecture-et-flux.md)
- [Préparation AWS](../docs/00b-preparation-compte-aws.md)
- [Exercice 1](../docs/exercices/01-terraform-ansible.md)
- [Exercice 2](../docs/exercices/02-elk-opensearch.md)
- [Exercice 3](../docs/exercices/03-haproxy.md)
- [Nettoyage](../docs/validation-preuves-nettoyage.md)
