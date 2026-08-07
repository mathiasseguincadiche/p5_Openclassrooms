# Troubleshooting — diagnostic du projet P5

Ce guide regroupe les problèmes les plus probables du parcours réel. L’objectif
est de diagnostiquer **sans supprimer un état Terraform, sans contourner un
garde-fou et sans recréer des ressources au hasard**.

## Réflexe de base

Avant toute correction importante :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Pour un diagnostic plus complet avec l’intégration OpenSearch locale :

```bash
bash scripts/commands/collect-diagnostics.sh --complet
```

Le script produit une archive nettoyée à transmettre et conserve le journal
complet uniquement en local.

## 1. `setup.sh` échoue juste après le bootstrap

### Symptôme

```text
KO  moteur Docker inaccessible
```

ou Node.js n’est pas trouvé dans le nouveau shell.

### Cause probable

Le bootstrap ajoute l’utilisateur au groupe `docker` et installe NVM. Ces deux
changements nécessitent une nouvelle session utilisateur.

### Correction

Déconnectez-vous réellement de la VM puis reconnectez-vous :

```bash
node --version
docker info
./scripts/commands/setup.sh --check-only
```

Ne lancez pas Docker avec `sudo` uniquement pour masquer un problème de groupe.

## 2. Mauvais compte AWS ou session expirée

### Symptômes

- `impossible de lire l'identité AWS` ;
- compte actif différent de `P5_EXPECTED_ACCOUNT_ID` ;
- `GO AWS` refusé.

### Vérifications

```bash
aws --profile p5-lab sts get-caller-identity
aws configure get region --profile p5-lab
```

Avec IAM Identity Center :

```bash
aws sso login --profile p5-lab
export AWS_PROFILE=p5-lab
```

Puis :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

Ne modifiez jamais `expected_aws_account_id` pour faire correspondre
artificiellement un mauvais compte actif.

## 3. L’adresse `/32` n’est plus valide

### Symptôme

```text
adresse publique actuelle ... différente de P5_PUBLIC_IP_CIDR
```

### Cause

L’adresse publique du poste ou du routeur a changé.

### Correction

Obtenez l’IPv4 publique actuelle puis mettez à jour **la source unique** :

```bash
$EDITOR environment/aws-readiness.env
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
./scripts/commands/pre-deployment-check.sh --stage initial
```

N’éditez pas les trois `terraform.tfvars` séparément.

## 4. `terraform.tfvars` désynchronisés

### Symptôme

```text
KO  ... terraform.tfvars n’est pas synchronisé avec aws-readiness.env
```

### Correction

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

La source de vérité reste `environment/aws-readiness.env`.

## 5. Collision de VPC, clé EC2 ou domaine OpenSearch

### Symptômes

Le contrôle AWS Ready indique qu’une ressource P5 existe déjà alors que l’étape
attend un environnement vierge.

### À ne pas faire

- ne supprimez pas le fichier `terraform.tfstate` ;
- ne supprimez pas immédiatement la ressource dans la console ;
- ne changez pas les tags juste pour contourner le contrôle.

### Diagnostic

```bash
terraform -chdir=terraform/exercice-1 state list
terraform -chdir=terraform/exercice-2 state list
terraform -chdir=terraform/exercice-3 state list
```

Puis contrôlez AWS :

```bash
./scripts/commands/check-aws-cleanup.sh
```

Si l’environnement est réellement encore géré par les états locaux, utilisez
la procédure de destruction normale. Si l’état et AWS divergent, analysez la
situation avant toute suppression manuelle.

## 6. Quota EC2 insuffisant

### Symptôme

```text
quota EC2 ... inférieur aux ... requis
```

La configuration de référence prévoit jusqu’à quatre `t3.micro` lorsque les
exercices 1 et 3 coexistent.

### Actions

- vérifier le quota EC2 Standard dans la région ;
- demander une augmentation si nécessaire ;
- vérifier que d’autres ressources du compte ne consomment pas le quota ;
- ne pas réduire arbitrairement `P5_REQUIRED_STANDARD_VCPUS` uniquement pour
  obtenir un faux `GO AWS`.

## 7. Le budget AWS est absent

### Diagnostic

Prévisualisez l’action :

```bash
./scripts/commands/setup-aws-guardrails.sh
```

Puis créez le budget :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
```

Relancez le contrôle AWS Ready.

## 8. Terraform ne trouve pas l’AMI Ubuntu

Le comportement normal utilise `ami_id = null`, ce qui sélectionne l’AMI
Canonical Ubuntu 24.04 LTS la plus récente correspondant aux filtres du module.

Vérifiez d’abord :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

Si une AMI personnalisée est réellement nécessaire, renseignez `P5_AMI_ID` dans
`environment/aws-readiness.env`, puis resynchronisez les tfvars.

## 9. Ansible ne joint pas l’EC2

### Vérifications

```bash
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
cat ansible/inventories/hosts_aws
ls -l ~/.ssh/p5-key
```

La clé privée doit être protégée :

```bash
chmod 600 ~/.ssh/p5-key
```

Test direct :

```bash
ssh -i ~/.ssh/p5-key ubuntu@ADRESSE_EC2
```

Puis :

```bash
ansible all -i ansible/inventories/hosts_aws -m ping
```

Contrôlez aussi que :

- l’inventaire utilise l’adresse publique actuelle ;
- l’utilisateur est `ubuntu` pour l’AMI Canonical ;
- le groupe de sécurité autorise votre IPv4 actuelle en `/32` sur le port 22.

## 10. Le playbook Ansible échoue sur NGINX

Commencez par le mode de vérification :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff
```

Sur l’EC2 :

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo journalctl -u nginx --no-pager -n 100
```

Le playbook attend l’artefact Angular sous `ansible/files/angular-app/` et la
configuration sous `ansible/files/nginx-angular.conf`.

## 11. L’artefact Angular n’est plus synchronisé

### Symptôme

La CI ou `validate.sh` détecte une différence entre le build et
`ansible/files/angular-app/`.

### Correction

```bash
./scripts/commands/prepare-angular-artifact.sh
./scripts/commands/validate.sh
```

Le script exécute `npm ci`, construit Angular puis remplace l’artefact uniquement
après un build valide.

## 12. L’application répond mais le fallback SPA échoue

### Diagnostic

```bash
./scripts/commands/verify-angular-deployment.sh
```

Test manuel :

```bash
curl -i http://ADRESSE_EC2/
curl -i http://ADRESSE_EC2/parcours-p5
```

La configuration NGINX doit contenir un fallback équivalent à :

```text
try_files $uri $uri/ /index.html;
```

Vérifiez aussi :

```bash
sudo nginx -t
```

## 13. Aucun log NGINX n’est disponible

Générez d’abord du trafic :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
```

Puis collectez :

```bash
./scripts/commands/collect-nginx-access-log.sh
```

Si SSH échoue, revenez au diagnostic Ansible/SSH. Si le fichier est vide,
vérifiez `/var/log/nginx/access.log` sur l’EC2.

## 14. OpenSearch n’est pas accessible

### Vérifications

```bash
terraform -chdir=terraform/exercice-2 output
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

Points fréquents :

- domaine encore en cours de création ;
- IP publique du poste différente du `/32` autorisé ;
- endpoint mal copié ;
- accès tenté en HTTP au lieu de HTTPS ;
- session ou permissions AWS insuffisantes pour le diagnostic.

Le script d’import n’accepte HTTP sans TLS que pour `localhost` ou `127.0.0.1`
dans les tests locaux.

## 15. L’import OpenSearch ne contient pas les données attendues

Commencez sans mutation :

```bash
./scripts/commands/import-opensearch-data.sh
```

Puis import réel :

```bash
./scripts/commands/import-opensearch-data.sh --apply
```

Validation :

```bash
./scripts/commands/verify-opensearch-data.sh
```

Le jeu de référence doit permettre au minimum :

- 64 documents ;
- 3 méthodes HTTP ;
- 4 tranches de 12 h ;
- 5 chemins distincts.

## 16. Le dashboard OpenSearch ne montre pas les trois graphiques

Vérifiez d’abord le verdict :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

Puis contrôlez le data view `nginx-access-*` avec `@timestamp` comme champ
temporel.

Les trois vues doivent utiliser :

1. Terms sur `http_method` ;
2. Date histogram `12h` + Sum sur `bytes_sent` ;
3. Date histogram `12h` + Terms taille 5 sur `url_path`.

La création de ces visualisations est manuelle et n’est pas automatisée par le
dépôt.

## 17. L’exercice 3 ne trouve pas le VPC

### Cause la plus probable

L’exercice 1 n’est plus déployé ou ses tags attendus ne sont plus présents.

### Contrôle

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

L’exercice 3 recherche le VPC avec les tags :

```text
Project=p5-openclassrooms
Exercise=1
Name=p5-vpc
```

Il recherche aussi les sous-réseaux publics de l’exercice 1 et la paire de clés
créée précédemment.

## 18. HAProxy ne montre qu’un backend

### Vérifications

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 10
```

Sur chaque backend :

```bash
sudo docker ps
sudo docker logs nginx-hello
curl http://localhost/
```

Sur HAProxy :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
```

Tenez compte des health checks : `inter 3s`, `fall 3`, `rise 2`. Un backend
récemment démarré peut nécessiter quelques secondes avant sa réintégration.

## 19. Le test de panne échoue en SSH

Le test réel nécessite :

- la clé SSH privée ;
- l’accès SSH `/32` aux backends ;
- l’utilisateur `ubuntu` ;
- les outputs Terraform de l’exercice 3.

Testez d’abord le mode simulation :

```bash
./scripts/commands/test-haproxy-failover.sh
```

Puis seulement :

```bash
./scripts/commands/test-haproxy-failover.sh --apply
```

En cas d’interruption après l’arrêt du backend, le `trap` tente de redémarrer le
conteneur. Vérifiez néanmoins manuellement son état.

## 20. `check-aws-cleanup.sh` dit “NETTOYAGE INCOMPLET” alors qu’OpenSearch est détruit

C’est normal si les exercices 1 ou 3 existent encore.

`check-aws-cleanup.sh` est un **audit global du projet**, pas un audit du seul
exercice 2.

Le verdict final ne doit être attendu qu’après :

```text
Exercice 3 détruit
Exercice 2 détruit
Exercice 1 détruit
```

Puis :

```bash
./scripts/commands/check-aws-cleanup.sh
```

## 21. Un état Terraform manque pendant la destruction

`destroy-aws.sh` signale qu’une vérification manuelle est nécessaire lorsqu’un
module n’a plus son `terraform.tfstate` local.

Ne concluez pas que les ressources n’existent plus.

Utilisez :

```bash
./scripts/commands/check-aws-cleanup.sh
```

et inspectez le compte AWS. La récupération d’un état perdu est une opération à
traiter avec prudence ; évitez de supprimer manuellement des ressources tant que
les dépendances ne sont pas comprises.

## 22. Les contrôles CI échouent après une modification documentaire

Vérifiez localement :

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

Le dépôt protège notamment :

- exactement trois guides sous `docs/exercices/` ;
- absence de Mermaid ;
- présence des six SVG attendus ;
- cohérence du véritable projet Angular ;
- garde-fous Terraform ;
- scripts critiques ;
- liens Markdown ;
- absence de fichiers sensibles suivis.

## 23. Que transmettre pour demander de l’aide ?

Préférez l’archive générée :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Elle contient un journal nettoyé et un résumé. Relisez-la malgré tout avant
tout partage.

Ne transmettez jamais directement :

- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- `terraform.tfstate` ;
- `~/.ssh/p5-key` ;
- credentials AWS ;
- tout `proofs/runtime/` non relu.

## Documents associés

- [Architecture](architecture-et-flux.md)
- [Parcours complet](01-parcours-debutant.md)
- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
- [Scripts](../scripts/README.md)
- [Sécurité](../SECURITY.md)
