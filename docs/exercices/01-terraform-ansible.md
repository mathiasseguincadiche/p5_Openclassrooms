# Exercice 1 — Terraform, Ansible, NGINX et Angular

Cette fiche décrit l’exécution réelle de l’exercice 1 dans l’implémentation AWS
du dépôt.

![Flux de l’exercice 1](../schemas/exercice-1.svg)

## Objectif

Provisionner une infrastructure AWS avec Terraform, puis utiliser Ansible pour
configurer une instance EC2, installer NGINX et servir le **véritable build
Angular** du projet.

## Résultat final attendu

```text
Terraform crée l’infrastructure
        ↓
Ansible configure l’EC2
        ↓
NGINX sert Angular sur le port 80
        ↓
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

## Prérequis

Avant cet exercice :

- étape 0A validée ;
- AWS Ready validé ;
- `environment/aws-readiness.env` complété ;
- les trois tfvars synchronisés ;
- clé SSH `p5-key` disponible ;
- verdict `GO TERRAFORM` obtenu.

Contrôle :

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

Le VPC, les sous-réseaux et la paire de clés seront **réutilisés par l’exercice
3**.

## Fichiers concernés

```text
application/angular/             # sources Angular
scripts/commands/
├── prepare-angular-artifact.sh
├── verify-angular-deployment.sh
├── generate-nginx-traffic.sh
└── collect-nginx-access-log.sh

ansible/
├── files/angular-app/           # build Angular déployé
├── files/nginx-angular.conf
├── inventories/hosts_aws.example
└── playbooks/deploy.yml

terraform/exercice-1/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example
```

## Étape 1 — Construire l’artefact Angular

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script :

1. exige `package.json` et `package-lock.json` ;
2. exécute `npm ci` ;
3. lance le build Angular ;
4. exige un unique artefact navigateur ;
5. copie le build sous `ansible/files/angular-app/`.

La CI reconstruit ensuite l’application et compare exactement le résultat avec
l’artefact versionné.

## Étape 2 — Revalider avant Terraform

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

Ne poursuivre qu’avec :

```text
GO TERRAFORM
```

## Étape 3 — Initialiser Terraform

```bash
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 fmt -check
terraform -chdir=terraform/exercice-1 validate
```

## Étape 4 — Produire et relire le plan

```bash
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
```

Contrôler avant application :

- compte autorisé ;
- région ;
- VPC et deux sous-réseaux ;
- règles SSH `/32` ;
- port HTTP 80 ;
- type d’instance ;
- AMI attendue ;
- volume chiffré ;
- clé EC2 ;
- absence de ressource inattendue.

## Étape 5 — Appliquer le plan

```bash
terraform -chdir=terraform/exercice-1 apply tfplan
terraform -chdir=terraform/exercice-1 output
```

Outputs utiles :

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_private_ip
web_public_dns
web_url
```

## Étape 6 — Préparer l’inventaire Ansible

L’inventaire réel est local et ignoré par Git.

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
$EDITOR ansible/inventories/hosts_aws
```

Vérifier la connexion :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

## Étape 7 — Prévisualiser Ansible

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff
```

Le playbook cible `webservers` et utilise l’élévation de privilèges.

## Étape 8 — Déployer NGINX et Angular

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
- recharge NGINX uniquement lorsqu’un fichier change.

## Étape 9 — Démontrer l’idempotence

Relancer exactement le même playbook :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

La seconde exécution doit montrer l’absence de modification inutile.

## Étape 10 — Vérifier l’application

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le script utilise `web_url` par défaut et vérifie :

- HTTP 200 sur `/` ;
- présence de `<app-root` ;
- identification de l’application P5 ;
- accessibilité du bundle JavaScript principal ;
- fallback SPA sur `/parcours-p5` ;
- en-tête `X-Content-Type-Options: nosniff`.

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Les fichiers techniques sont enregistrés sous :

```text
proofs/runtime/exercice-1/
```

## Étape 11 — Produire les logs pour l’exercice 2

Générer du trafic :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
```

Le script répartit plusieurs méthodes et chemins HTTP afin d’alimenter le
journal NGINX.

Collecter le journal réel :

```bash
./scripts/commands/collect-nginx-access-log.sh
```

Le script :

- lit `web_public_ip` ;
- se connecte en SSH ;
- récupère `/var/log/nginx/access.log` ;
- valide le format ;
- écrit le fichier en mode restrictif sous `proofs/runtime/exercice-2/`.

## Preuves à conserver

### Terraform

- version Terraform ;
- `validate` réussi ;
- résumé du plan ;
- `apply` réussi ;
- EC2 active ;
- outputs utiles anonymisés.

### Ansible

- ping réussi ;
- première exécution du playbook ;
- seconde exécution idempotente ;
- absence de tâche en échec.

### Application

- capture navigateur ;
- verdict du script de vérification ;
- bundle JavaScript ;
- fallback SPA ;
- configuration NGINX valide.

### Logs

- trafic généré ;
- collecte NGINX réelle ;
- fichier destiné à l’exercice 2 si utilisé.

Gabarit :
[`Livrable 1`](../livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md).

## Ce qu’il ne faut pas publier

- `terraform.tfvars` ;
- `terraform.tfstate` ;
- `tfplan` ;
- clé privée SSH ;
- inventaire Ansible réel ;
- IP ou identité non nécessaires à la preuve ;
- contenu brut non relu de `proofs/runtime/`.

## Nettoyage

**Ne détruisez pas l’exercice 1 immédiatement.**

L’exercice 3 dépend de son VPC, de ses sous-réseaux et de sa paire de clés.

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

La destruction finale globale est documentée dans
[Validation, preuves et nettoyage](../validation-preuves-nettoyage.md).

## Étapes suivantes

Selon l’ordre choisi :

- [Exercice 2 — OpenSearch](02-elk-opensearch.md)
- [Exercice 3 — HAProxy](03-haproxy.md)
