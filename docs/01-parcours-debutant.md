# 01 — Parcours d’exécution de bout en bout

Ce document est le **runbook principal** du projet. Il indique l’ordre des
étapes, les commandes à exécuter, les verdicts attendus et les moments où les
preuves doivent être collectées.

Pour comprendre les dépendances avant d’exécuter, lire
[l’architecture technique](architecture-et-flux.md).

## Règles du parcours

Avant de commencer :

- exécuter les commandes depuis la racine du dépôt sauf indication contraire ;
- ne jamais versionner `environment/aws-readiness.env`, `terraform.tfvars`, les
  états Terraform, l’inventaire Ansible réel ou `proofs/runtime/` ;
- considérer `environment/aws-readiness.env` comme la source unique des
  paramètres AWS du lab ;
- relire chaque plan Terraform avant `apply` ;
- ne jamais détruire l’exercice 1 avant l’exercice 3 ;
- conserver les preuves avant de détruire les ressources ;
- terminer par l’audit global AWS.

## Vue rapide

| Étape | Action | Condition de sortie |
| --- | --- | --- |
| 0A | préparer la VM | `Étape 0A validée` |
| 0B | préparer AWS | `GO AWS` puis `GO TERRAFORM` |
| 1 | Terraform + Ansible + Angular | application validée et logs disponibles |
| 2 | OpenSearch | données prêtes + dashboard capturé |
| 3 | HAProxy | round-robin + panne + reprise validés |
| Finalisation | livrables + destruction | `NETTOYAGE AWS COMPLET` |

## Étape 0A — Installer et valider la VM

### Objectif

Obtenir un poste DevOps reproductible capable d’exécuter l’ensemble du projet.

### 1. Installer Ubuntu Server

Référence : [préparation de la VM](00-preparation-environnement.md).

Configuration recommandée :

- Ubuntu Server 26.04 ;
- 4 vCPU ;
- 8 Gio de RAM ;
- 50 Gio de disque ;
- OpenSSH actif ;
- aucun environnement graphique requis.

### 2. Cloner le dépôt

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 3. Installer le socle

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Déconnectez-vous puis reconnectez-vous afin d’appliquer le groupe `docker` et
l’environnement utilisateur.

### 4. Préparer la clé SSH

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/p5-key -C "p5-lab"
chmod 600 ~/.ssh/p5-key
chmod 644 ~/.ssh/p5-key.pub
```

### 5. Valider la VM

```bash
./scripts/commands/setup.sh --check-only
```

Condition de sortie :

```text
Étape 0A validée. Poursuivez avec le contrôle AWS Ready.
```

### Checkpoint

- [ ] OS et versions corrects ;
- [ ] Docker accessible sans `sudo` ;
- [ ] clé SSH créée ;
- [ ] dépôt cohérent ;
- [ ] `validate.sh` réussit.

## Étape 0B — Sécuriser et valider AWS

Référence complète :
[préparation du compte AWS](00b-preparation-compte-aws.md).

### 1. Sécuriser le compte

Vérifier dans la console :

- MFA root ;
- absence de clés root ;
- contacts de récupération/facturation ;
- politique IAM adaptée au lab.

### 2. Configurer le profil

Exemple IAM Identity Center :

```bash
aws configure sso --profile p5-lab
aws sso login --profile p5-lab
export AWS_PROFILE=p5-lab
aws sts get-caller-identity
```

### 3. Créer la configuration locale

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Remplacer toutes les valeurs d’exemple nécessaires.

### 4. Synchroniser Terraform

```bash
bash scripts/commands/sync-terraform-tfvars.sh
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Ne modifiez pas ensuite les trois `terraform.tfvars` séparément.

### 5. Créer le budget

```bash
./scripts/commands/setup-aws-guardrails.sh
./scripts/commands/setup-aws-guardrails.sh --apply
```

### 6. Obtenir les verdicts

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage initial
```

Conditions de sortie :

```text
GO AWS
GO TERRAFORM
```

### Checkpoint

- [ ] compte correct ;
- [ ] identité non root ;
- [ ] session temporaire ou rôle ;
- [ ] région correcte ;
- [ ] IP publique `/32` correcte ;
- [ ] budget présent ;
- [ ] quota EC2 suffisant ;
- [ ] tfvars synchronisés ;
- [ ] aucune collision P5 initiale.

## Exercice 1 — Déployer Angular avec Terraform et Ansible

Référence :
[guide de l’exercice 1](exercices/01-terraform-ansible.md).

### 1. Préparer le véritable artefact Angular

```bash
./scripts/commands/prepare-angular-artifact.sh
```

### 2. Refaire le précontrôle

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

### 3. Initialiser et planifier Terraform

```bash
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 fmt -check
terraform -chdir=terraform/exercice-1 validate
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
```

Avant `apply`, contrôler :

- compte et région ;
- VPC et deux sous-réseaux ;
- groupe de sécurité ;
- SSH limité au `/32` ;
- HTTP public attendu ;
- type EC2 ;
- volume chiffré ;
- paire de clés.

### 4. Appliquer

```bash
terraform -chdir=terraform/exercice-1 apply tfplan
terraform -chdir=terraform/exercice-1 output
```

### 5. Préparer l’inventaire Ansible

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
$EDITOR ansible/inventories/hosts_aws
```

### 6. Tester Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

### 7. Vérifier puis déployer

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff

ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Relancer une seconde fois le playbook pour démontrer l’idempotence :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

### 8. Vérifier l’application

```bash
./scripts/commands/verify-angular-deployment.sh
```

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

### 9. Générer et collecter les logs NGINX

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh
```

### Checkpoint Exercice 1

- [ ] Terraform appliqué ;
- [ ] cible EC2 accessible ;
- [ ] ping Ansible réussi ;
- [ ] playbook réussi ;
- [ ] seconde exécution idempotente ;
- [ ] Angular accessible ;
- [ ] bundle principal accessible ;
- [ ] fallback SPA validé ;
- [ ] logs NGINX collectés ;
- [ ] preuves enregistrées.

### Ne pas nettoyer maintenant

Le VPC, les sous-réseaux et la paire de clés sont nécessaires à l’exercice 3.

## Exercice 2 — Importer et visualiser les logs dans OpenSearch

Référence :
[guide de l’exercice 2](exercices/02-elk-opensearch.md).

L’exercice 2 peut être réalisé avant ou après l’exercice 3. Pour limiter les
coûts, détruisez OpenSearch dès que les captures sont terminées, sans lancer pour
autant l’audit global tant que les autres exercices existent encore.

### 1. Contrôler l’étape

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/pre-deployment-check.sh --stage exercice-2
```

Si l’IP publique a changé, mettez à jour `aws-readiness.env` puis resynchronisez
les tfvars avant de poursuivre.

### 2. Déployer OpenSearch

```bash
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 validate
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 show tfplan
terraform -chdir=terraform/exercice-2 apply tfplan
terraform -chdir=terraform/exercice-2 output
```

Attendez que le domaine soit actif.

### 3. Prévisualiser l’import

Avec l’échantillon versionné :

```bash
./scripts/commands/import-opensearch-data.sh
```

Avec un log réel collecté précédemment :

```bash
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log
```

### 4. Importer réellement

```bash
./scripts/commands/import-opensearch-data.sh --apply
```

ou avec un fichier réel :

```bash
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log --apply
```

### 5. Vérifier les données

```bash
./scripts/commands/verify-opensearch-data.sh
```

Verdict attendu :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

### 6. Construire le dashboard manuellement

Créer un data view `nginx-access-*` utilisant `@timestamp`.

Créer :

1. donut sur `http_method` ;
2. histogramme 12 h avec somme de `bytes_sent` ;
3. top 5 `url_path` par tranches de 12 h ;
4. dashboard regroupant les trois vues.

### 7. Capturer les preuves

Conserver Discover, les trois visualisations et le dashboard complet.

### 8. Détruire OpenSearch après les captures

```bash
terraform -chdir=terraform/exercice-2 destroy
```

Ne lancez pas `check-aws-cleanup.sh` pour conclure au nettoyage global tant que
l’exercice 1 ou 3 existe encore.

### Checkpoint Exercice 2

- [ ] domaine actif ;
- [ ] import réussi ;
- [ ] données vérifiées ;
- [ ] Discover capturé ;
- [ ] trois visualisations capturées ;
- [ ] dashboard complet capturé ;
- [ ] domaine détruit lorsqu’il n’est plus utile.

## Exercice 3 — HAProxy, panne et reprise

Référence :
[guide de l’exercice 3](exercices/03-haproxy.md).

### Prérequis critique

L’exercice 1 doit encore exister.

### 1. Contrôler l’étape

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
./scripts/commands/pre-deployment-check.sh --stage exercice-3
```

Le contrôle doit confirmer la présence du VPC et de la paire de clés de
l’exercice 1.

### 2. Déployer

```bash
terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 validate
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 show tfplan
terraform -chdir=terraform/exercice-3 apply tfplan
terraform -chdir=terraform/exercice-3 output
```

### 3. Tester le round-robin

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 10
```

Verdict attendu :

```text
ROUND-ROBIN OPÉRATIONNEL
```

### 4. Prévisualiser la panne

```bash
./scripts/commands/test-haproxy-failover.sh
```

Aucune connexion SSH destructive n’est exécutée dans ce mode.

### 5. Exécuter la panne réelle

```bash
./scripts/commands/test-haproxy-failover.sh \
  --backend 1 \
  --requests 6 \
  --apply
```

Verdict attendu :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

### Checkpoint Exercice 3

- [ ] HAProxy valide ;
- [ ] deux backends observés ;
- [ ] panne réelle exécutée ;
- [ ] service continu pendant la panne ;
- [ ] backend redémarré ;
- [ ] deux backends réintégrés ;
- [ ] preuves enregistrées.

## Finalisation — sélectionner les preuves

Référence :
[validation, preuves et nettoyage](validation-preuves-nettoyage.md).

### 1. Auditer les secrets

```bash
python3 scripts/tools/audit_secrets.py
```

### 2. Contrôler la structure des livrables

```bash
./scripts/commands/prepare-livrables.sh --structure-only
```

### 3. Compléter les trois gabarits

Utiliser les preuves réelles sous `proofs/runtime/`, sélectionner uniquement ce
qui est utile et anonymiser les données sensibles.

### 4. Contrôler strictement les livrables

```bash
./scripts/commands/prepare-livrables.sh
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Finalisation — détruire AWS

### Ordre obligatoire

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Commande recommandée :

```bash
./scripts/commands/destroy-aws.sh
```

Le script exige la saisie exacte de `DETRUIRE`.

### Audit final

```bash
./scripts/commands/check-aws-cleanup.sh
```

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

Ne supprimez les états Terraform qu’après avoir confirmé ce nettoyage.

## Dernière validation du dépôt

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

## En cas de problème

Utiliser :

- [Troubleshooting](troubleshooting.md) ;
- diagnostic standard :

```bash
bash scripts/commands/collect-diagnostics.sh
```

- diagnostic complet local :

```bash
bash scripts/commands/collect-diagnostics.sh --complet
```

## Résumé final

Le projet n’est pas considéré terminé uniquement parce que le code est présent.
La fermeture correcte est :

```text
Code validé
  +
3 exercices réellement démontrés
  +
preuves relues
  +
livrables complets
  +
ressources AWS détruites
  +
NETTOYAGE AWS COMPLET
```
