# Exercice 1 — Terraform, Ansible, NGINX et Angular

Cette fiche décrit l'exécution réelle de l'exercice 1 dans l'implémentation AWS
du dépôt.

![Flux de l'exercice 1](../schemas/exercice-1.svg)

## Mode recommandé

```bash
bash scripts/commands/p5.sh ex1
```

Cette commande automatise le parcours complet de l'exercice tout en affichant le
plan Terraform avant `apply`.

Elle réalise notamment :

- build Angular ;
- Terraform ;
- génération de l'inventaire Ansible ;
- attente SSH/cloud-init ;
- ping Ansible ;
- déploiement NGINX/Angular ;
- seconde exécution du playbook avec contrôle strict `changed=0` ;
- vérification HTTP ;
- génération de trafic ;
- collecte du vrai log NGINX pour l'exercice 2.

Les étapes manuelles ci-dessous restent la référence détaillée pour comprendre ou
rejouer une opération isolée.

## Objectif

Provisionner une infrastructure AWS avec Terraform, puis utiliser Ansible pour
configurer une instance EC2, installer NGINX et servir le véritable build Angular
du projet.

## Résultat final attendu

```text
Terraform crée l'infrastructure
        ↓
Ansible configure l'EC2
        ↓
NGINX sert Angular sur le port 80
        ↓
seconde exécution Ansible : changed=0
        ↓
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
        ↓
logs NGINX réels collectés
```

## Prérequis

Avant cet exercice :

- étape 0A validée ;
- AWS Ready validé ;
- `environment/aws-readiness.env` complété ;
- les trois tfvars synchronisés ;
- clé SSH disponible ;
- verdict `GO TERRAFORM` obtenu.

Avec l'orchestrateur, ces contrôles sont effectués par `prepare`/`all`.

Contrôle manuel :

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

## Ce que Terraform crée

Le module `terraform/exercice-1/` crée :

- VPC `10.0.0.0/16` ;
- deux sous-réseaux publics ;
- Internet Gateway ;
- table de routage publique ;
- groupe de sécurité `p5-web-sg` ;
- paire de clés EC2 ;
- une EC2 Ubuntu 24.04 LTS.

Sécurité principale :

- SSH autorisé uniquement depuis `your_ip_cidr` en `/32` ;
- HTTP public sur le port 80 pour la démonstration ;
- IMDSv2 obligatoire ;
- volume racine `gp3` chiffré.

Le VPC, les sous-réseaux et la paire de clés sont réutilisés par l'exercice 3.

## Fichiers concernés

```text
application/angular/
scripts/commands/
├── p5.sh
├── prepare-angular-artifact.sh
├── generate-ansible-inventory.sh
├── verify-angular-deployment.sh
├── generate-nginx-traffic.sh
└── collect-nginx-access-log.sh

ansible/
├── files/angular-app/
├── files/nginx-angular.conf
├── inventories/hosts_aws.example
└── playbooks/deploy.yml

terraform/exercice-1/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example
```

## Procédure manuelle détaillée

### 1. Construire l'artefact Angular

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script exécute `npm ci`, construit Angular, exige un unique artefact navigateur
puis le synchronise sous `ansible/files/angular-app/`.

### 2. Revalider avant Terraform

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

Condition :

```text
GO TERRAFORM
```

### 3. Initialiser et valider Terraform

```bash
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 fmt -check
terraform -chdir=terraform/exercice-1 validate
```

### 4. Produire et relire le plan

```bash
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
```

Contrôler :

- compte et région ;
- VPC et sous-réseaux ;
- règles SSH `/32` ;
- HTTP 80 ;
- type d'instance ;
- AMI ;
- volume chiffré ;
- paire de clés ;
- absence de ressource inattendue.

### 5. Appliquer

```bash
terraform -chdir=terraform/exercice-1 apply tfplan
terraform -chdir=terraform/exercice-1 output
```

### 6. Générer l'inventaire Ansible

La méthode recommandée, même en mode manuel, est désormais :

```bash
bash scripts/commands/generate-ansible-inventory.sh
```

Le script lit `web_public_ip`, vérifie la clé privée associée et écrit
`ansible/inventories/hosts_aws` en mode restrictif.

Puis :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

### 7. Déployer NGINX et Angular

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le playbook :

- installe NGINX et `curl` ;
- crée `appuser` / `appgroup` ;
- crée `/var/www/p5` ;
- copie le build Angular ;
- installe le site NGINX ;
- désactive le site par défaut ;
- valide `nginx -t` ;
- active NGINX au démarrage ;
- recharge NGINX uniquement lorsqu'un fichier change.

> Le mode `--check --diff` n'est pas utilisé comme prérequis au tout premier
> déploiement, car certaines tâches de validation dépendent de NGINX déjà
> installé. Il peut être utilisé ensuite comme outil de diagnostic.

### 8. Démontrer l'idempotence

Relancer exactement le même playbook :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le récapitulatif attendu doit contenir :

```text
changed=0
unreachable=0
failed=0
```

`p5.sh ex1` vérifie automatiquement ces trois valeurs et échoue si la seconde
exécution modifie encore la cible.

### 9. Vérifier l'application

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le script vérifie :

- HTTP 200 sur `/` ;
- présence de `<app-root` ;
- identification de l'application P5 ;
- bundle JavaScript principal ;
- fallback SPA ;
- en-tête `X-Content-Type-Options: nosniff`.

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

### 10. Générer et collecter les logs NGINX

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 96
./scripts/commands/collect-nginx-access-log.sh \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

Le log réel devient l'une des deux sources de l'exercice 2.

## Preuves à conserver

### Terraform

- `validate` réussi ;
- plan relu ;
- `apply` réussi ;
- EC2 active ;
- outputs utiles anonymisés.

### Ansible

- ping réussi ;
- première exécution ;
- seconde exécution ;
- `changed=0` ;
- `unreachable=0` ;
- `failed=0`.

### Application

- capture navigateur ;
- verdict du script de vérification ;
- bundle JavaScript ;
- fallback SPA ;
- configuration NGINX valide.

### Logs

- trafic généré ;
- collecte NGINX réelle ;
- `nginx-access-real.log` destiné à OpenSearch.

Gabarit :
[Livrable 1](../livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md).

## Ce qu'il ne faut pas publier

- `terraform.tfvars` ;
- `terraform.tfstate` ;
- `tfplan` ;
- clé privée SSH ;
- inventaire Ansible réel ;
- IP ou identité non nécessaires à la preuve ;
- contenu brut non relu de `proofs/runtime/` ou `logs/`.

## Nettoyage

Ne pas détruire l'exercice 1 immédiatement : l'exercice 3 dépend de son VPC, de
ses sous-réseaux et de sa paire de clés.

Ordre correct :

```text
Exercice 1 déployé
    ↓
Exercice 3 exécuté
    ↓
Exercice 3 détruit
    ↓
Exercice 1 détruit
```

La destruction globale est gérée par :

```bash
bash scripts/commands/p5.sh cleanup
```

## Étapes suivantes

- [Exercice 2 — OpenSearch](02-elk-opensearch.md)
- [Exercice 3 — HAProxy](03-haproxy.md)
