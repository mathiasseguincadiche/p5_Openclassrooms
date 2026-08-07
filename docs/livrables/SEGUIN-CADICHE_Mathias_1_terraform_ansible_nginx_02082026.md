# Livrable 1 — Terraform, Ansible, NGINX et application Angular

> **Gabarit à compléter.** Les preuves doivent provenir d’un déploiement réel.
> La présence de ce document ne signifie pas que l’exercice a été exécuté.

## 1. Choix de réalisation

- Mode retenu : **AWS**.
- Région de référence : `us-east-1`.
- Provisionnement : Terraform.
- Configuration : Ansible.
- Service web : NGINX.
- Application : véritable projet Angular du dépôt.
- Infrastructure : VPC, deux sous-réseaux publics, groupe de sécurité, paire de
  clés et une cible EC2.

L’exercice 3 réutilise le VPC, les sous-réseaux et la paire de clés créés ici.
Ils doivent donc rester disponibles jusqu’à la fin de la démonstration HAProxy.

## 2. Fichiers remis

```text
terraform/exercice-1/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── .terraform.lock.hcl

application/angular/             # sources Angular
ansible/
├── inventories/hosts_aws.example
├── playbooks/deploy.yml
└── files/
    ├── angular-app/             # build de production synchronisé
    └── nginx-angular.conf
```

Fichiers exclus de toute remise publique :

- `terraform.tfvars` ;
- `terraform.tfstate*` ;
- `tfplan` ;
- inventaire Ansible réel ;
- clé privée SSH ;
- contenu runtime non relu.

## 3. Preuves Terraform

### Validation

```bash
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 fmt -check
terraform -chdir=terraform/exercice-1 validate
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
```

**Preuves à insérer :**

- validation réussie ;
- résumé du plan ;
- VPC, deux sous-réseaux, groupe de sécurité, paire de clés et EC2 clairement
  identifiables ;
- règles SSH limitées au `/32` d’administration ;
- absence de ressource inattendue.

### Application

```bash
terraform -chdir=terraform/exercice-1 apply tfplan
terraform -chdir=terraform/exercice-1 output
```

**Preuves à insérer :**

- résumé de l’application ;
- instance EC2 en état `running` ;
- outputs utiles anonymisés ;
- confirmation que la bonne région et le bon compte sont utilisés.

## 4. Preuves Ansible

### Connectivité

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

**Preuve à insérer :** ping Ansible réussi.

### Prévisualisation

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff
```

### Déploiement réel

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

### Idempotence

Relancer le même playbook :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

**Preuves à insérer :**

- première exécution sans échec ;
- NGINX installé et actif ;
- seconde exécution montrant l’idempotence ;
- aucune donnée sensible affichée.

## 5. Preuve de l'application

Le dépôt contient les sources Angular sous `application/angular/` et l’artefact
exact déployé par Ansible sous `ansible/files/angular-app/`.

Avant le déploiement :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Après le déploiement :

```bash
./scripts/commands/verify-angular-deployment.sh
```

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

**Preuves à insérer :**

- capture navigateur de l’application Angular réelle ;
- réponse HTTP 200 ;
- bundle JavaScript principal accessible ;
- fallback SPA opérationnel ;
- en-tête de sécurité NGINX ;
- `nginx -t` valide.

### Logs pour l’exercice 2

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh
```

**Preuve à insérer :** collecte d’un journal NGINX réel, sans publier le fichier
brut s’il contient des informations inutiles ou sensibles.

## 6. Nettoyage

> **Ne pas détruire l’exercice 1 avant l’exercice 3.** Le module HAProxy
> réutilise son VPC, ses sous-réseaux et sa paire de clés.

Une fois l’exercice 3 terminé et toutes les preuves sauvegardées, la fermeture
globale suit l’ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Commande recommandée en fin de projet :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

**Preuve à insérer :** confirmation de la destruction finale et verdict
`NETTOYAGE AWS COMPLET` après fermeture de l’ensemble du lab.
