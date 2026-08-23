# Livrable 1 — Terraform, Ansible, NGINX et application Angular

> **État vérifié le 23 août 2026.** Ce livrable est fondé sur l'exécution AWS réelle du projet et sur les preuves produites par l'orchestrateur P5. Les identifiants et adresses publiques inutiles à la démonstration ne sont pas reproduits ici.

## 1. Objectif

Démontrer qu'une infrastructure AWS est provisionnée avec Terraform puis qu'Ansible configure une EC2 Ubuntu afin de servir l'application Angular du dépôt avec NGINX.

```text
Terraform → AWS → EC2
                 ↓
              Ansible
                 ↓
          NGINX + Angular
```

## 2. Choix de réalisation

- mode : AWS ;
- infrastructure : Terraform ;
- configuration : Ansible ;
- cible : EC2 Ubuntu `t3.micro` ;
- application : `application/angular/` ;
- serveur HTTP : NGINX ;
- port applicatif public : 80 ;
- SSH : limité à l'IPv4 `/32` du poste d'administration ;
- métadonnées EC2 : IMDSv2 obligatoire ;
- volume racine : chiffré, type `gp3`.

## 3. Fichiers remis

```text
terraform/exercice-1/
ansible/playbooks/deploy.yml
ansible/files/nginx-angular.conf
ansible/files/angular-app/
application/angular/
```

Les éléments d'exécution sensibles ou éphémères restent hors dépôt :

```text
terraform.tfvars
terraform.tfstate*
tfplan
ansible/inventories/hosts_aws
clé SSH privée
logs runtime bruts
```

## 4. Exécution de référence

Commande principale :

```bash
bash scripts/commands/p5.sh ex1
```

Run de validation retenu : `20260823T015131Z`.

```text
validated_steps=13
failed_steps=0
result=OK
```

L'orchestrateur a revérifié l'artefact Angular, Terraform, l'inventaire Ansible, SSH, le ping Ansible, le playbook, l'idempotence, le service HTTP et la collecte des logs NGINX.

## 5. Preuve Terraform

### Provisionnement et état final

Le déploiement initial a produit un plan réel de **10 ressources à créer, 0 à modifier et 0 à détruire**. Il comprenait notamment :

```text
1 VPC
2 subnets publics
1 Internet Gateway
1 table de routage publique + associations
1 Security Group web
1 paire de clés EC2
1 EC2 p5-web
```

Le plan a été relu puis approuvé dans le parcours orchestré. Le run de référence final a ensuite recalculé l'état réel et obtenu :

```text
No changes. Your infrastructure matches the configuration.
```

Les outputs finaux confirmaient la présence du VPC, des deux subnets publics, du Security Group et de l'EC2 web. L'EC2 `p5-web` était `running` et son URL HTTP était fournie par Terraform.

### Points de sécurité vérifiés

```text
SSH :22 limité à une source /32
HTTP :80 public
IMDSv2 : http_tokens = required
volume racine : encrypted = true
volume racine : gp3
compte et région verrouillés par les garde-fous du projet
```

### Traces techniques privées

```text
proofs/runtime/steps/20260823T015131Z/03-tf-ex1-plan.log
proofs/runtime/steps/20260823T015131Z/04-tf-ex1-show.log
proofs/runtime/steps/20260823T015131Z/05-tf-ex1-output.log
proofs/runtime/exercice-1/20260823T015320Z-etat-aws-exercice-1.log
```

### Interprétation

Le plan initial prouve que Terraform connaissait précisément les ressources nécessaires. Le plan final vide prouve ensuite la convergence : Terraform compare la configuration au compte AWS et ne détecte plus aucun écart à corriger. L'infrastructure est donc à la fois réellement créée et conforme à son code déclaratif.

## 6. Preuve Ansible — connectivité

Commande exécutée :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Résultat réel :

```text
web | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

La cible SSH était disponible dès la première tentative du run de référence. La preuve correspondante est conservée dans :

```text
proofs/runtime/steps/20260823T015131Z/08-ansible-ping.log
```

Ce résultat démontre qu'Ansible atteint effectivement l'EC2 avec l'inventaire généré depuis les outputs Terraform.

## 7. Preuve Ansible — premier déploiement

Commande :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le playbook gère notamment :

- l'installation de NGINX et des utilitaires requis ;
- la création de l'utilisateur et du groupe applicatifs ;
- la racine du site ;
- le déploiement de l'artefact Angular ;
- la configuration NGINX du projet ;
- l'activation du site P5 ;
- la désactivation du site NGINX par défaut ;
- la validation de la configuration NGINX ;
- le démarrage et l'activation du service.

Lors du run final de vérification, la machine était déjà configurée et le récapitulatif a confirmé un état sain :

```text
web : ok=12 changed=0 unreachable=0 failed=0 skipped=1 rescued=0 ignored=0
```

Le fait que ce passage final soit déjà à `changed=0` est cohérent avec une machine précédemment déployée : Ansible retrouve l'état voulu sans le réécrire.

Trace :

```text
proofs/runtime/steps/20260823T015131Z/09-ansible-deploy.log
```

## 8. Preuve d'idempotence

Le playbook a été exécuté une seconde fois immédiatement pour établir explicitement l'idempotence.

Résultat strict :

```text
web : ok=12 changed=0 unreachable=0 failed=0 skipped=1 rescued=0 ignored=0
```

L'orchestrateur a produit le verdict :

```text
Idempotence Ansible confirmée : changed=0, unreachable=0, failed=0.
```

Trace :

```text
proofs/runtime/steps/20260823T015131Z/10-ansible-idempotence.log
```

### Interprétation

Ansible décrit un état cible. Comme tous les fichiers, paquets, droits, configurations et services étaient déjà conformes, le second passage n'a effectué aucune modification. Ce comportement évite les changements inutiles et rend le déploiement répétable.

## 9. Preuve applicative

Le contrôle applicatif automatisé a interrogé l'URL fournie par Terraform et obtenu :

```text
OK  réponse HTTP 200
OK  document Angular identifié
OK  bundle principal accessible : main-EPNQBKEW.js
OK  fallback SPA NGINX opérationnel
OK  en-tête de sécurité nosniff

Verdict : APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Commande reproductible :

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Trace technique :

```text
proofs/runtime/steps/20260823T015131Z/11-verify-angular.log
```

La validation HTTP constitue la preuve reproductible versionnée. Une capture navigateur peut être conservée dans le dossier de soutenance sans publier l'adresse publique de l'instance dans le dépôt.

## 10. Logs NGINX pour l'exercice 2

Le run a généré **96 requêtes HTTP** contrôlées afin de produire un trafic varié (`GET`, `HEAD`, `POST`, `OPTIONS`), puis a collecté le vrai `access.log` NGINX.

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 96
```

Puis :

```bash
bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

Résultat de collecte :

```text
Documents valides : 91
Période UTC : 2026-08-23T01:36:57 → 2026-08-23T01:53:22
Format NGINX combined : validé
```

Ces 91 lignes réelles ont ensuite été utilisées dans l'exercice 2 avec le jeu reproductible OpenSearch.

## 11. Conclusion de l'exercice

L'exercice 1 est validé de bout en bout : Terraform a créé l'infrastructure AWS puis a confirmé l'absence de dérive, Ansible a atteint et configuré l'EC2, l'idempotence a été démontrée avec `changed=0`, et l'application Angular est réellement servie par NGINX avec un HTTP 200, son bundle JavaScript et son fallback SPA. Le trafic généré a enfin produit 91 entrées NGINX réelles exploitables par OpenSearch.

## 12. Dépendance avec l'exercice 3

Le VPC et les subnets de l'exercice 1 sont réutilisés par l'exercice 3. Ils doivent donc rester présents jusqu'à la fin des preuves HAProxy.

Le nettoyage global respecte l'ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

La fermeture du lab s'effectue uniquement après finalisation des livrables :

```bash
bash scripts/commands/p5.sh cleanup
```

Verdict attendu après destruction et audit :

```text
NETTOYAGE AWS COMPLET
```
