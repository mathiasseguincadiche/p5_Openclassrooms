# Runbook d'exécution guidée — P5 de A à Z

## But du runbook

Ce document est la procédure opératoire principale pour **réaliser le P5 avec l'implémentation actuelle du dépôt**.

Il ne remplace pas les guides pédagogiques : il donne l'ordre, les commandes, les contrôles et les points d'arrêt.

## Règles avant de commencer

1. exécuter les commandes Linux depuis Ubuntu WSL2 ;
2. rester dans `~/labs/p5_Openclassrooms` ;
3. ne pas travailler depuis `/mnt/c` ou `/mnt/d` ;
4. ne jamais supprimer un state Terraform pour forcer une reprise ;
5. lire un plan Terraform avant de confirmer une mutation ;
6. conserver les confirmations manuelles lorsqu'une preuve ne peut pas être automatisée ;
7. considérer toute ressource AWS active comme potentiellement facturable ;
8. terminer le projet par le nettoyage `3 → 2 → 1`.

## Phase 0 — Ouvrir le poste de contrôle

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
pwd
git status --short
```

Résultat attendu :

```text
/home/<utilisateur>/labs/p5_Openclassrooms
```

Le dépôt peut avoir des fichiers locaux ignorés par Git après une première exécution. `git status` ne doit pas montrer de secret ou d'état Terraform ajouté au suivi.

## Phase 1 — Observer avant de modifier

```bash
bash scripts/commands/p5.sh inspect
```

### Pourquoi commencer par `inspect` ?

Parce qu'une session précédente peut avoir laissé :

- un state Terraform ;
- des ressources AWS existantes ;
- des outputs encore valides ;
- un fichier de configuration locale ;
- des preuves déjà collectées.

Le moteur doit d'abord classifier la situation avant de décider s'il faut créer, reprendre ou ne rien faire.

### Point d'arrêt

Si une valeur provenant de Terraform/AWS est affichée comme inconnue, **ne pas la remplacer par une valeur supposée**. Corriger la source indiquée par le diagnostic.

## Phase 2 — Préparer le poste et AWS

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` orchestre plusieurs sous-problèmes.

### 2.1 Qualification du socle Linux

Le moteur vérifie l'équivalent de :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Si des écarts sont détectés, il propose de converger les outils nécessaires.

### 2.2 Configuration locale AWS

Le moteur crée ou réconcilie :

```text
environment/aws-readiness.env
```

à partir du modèle :

```text
environment/aws-readiness.env.example
```

Les informations importantes sont :

- profil AWS ;
- région ;
- compte AWS attendu ;
- IPv4 publique `/32` ;
- types d'instances ;
- clé SSH ;
- paramètres OpenSearch ;
- budget et e-mail d'alerte ;
- confirmations de sécurité.

### 2.3 Budget AWS

Le moteur vérifie :

```bash
bash scripts/commands/setup-aws-guardrails.sh --check
```

Si le budget n'est pas conforme, il peut proposer la convergence correspondante.

### 2.4 Synchronisation Terraform

La configuration locale alimente les trois fichiers `terraform.tfvars` ignorés par Git.

Contrôle équivalent :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

### Point d'arrêt

Ne pas poursuivre si :

- l'identité AWS n'est pas celle attendue ;
- le compte root est utilisé pour le lab normal ;
- l'IP SSH n'est pas en `/32` ;
- la clé SSH privée manque ;
- le budget n'est pas compris ;
- les quotas sont insuffisants ;
- les `tfvars` ne correspondent pas à la configuration locale.

## Phase 3 — Vérifier l'état de préparation

```bash
bash scripts/commands/p5.sh status
```

Cette commande est non destructive.

Elle doit permettre de répondre :

> « Si je lance maintenant un exercice, les prérequis locaux et AWS sont-ils cohérents ? »

Un des verdicts importants du contrôle Terraform est :

```text
GO TERRAFORM
```

Ce verdict autorise la suite des contrôles ; il ne remplace jamais la lecture du plan.

---

# Exercice 1 — Terraform + Ansible + Angular/NGINX

## Phase 4 — Lancer l'exercice 1

```bash
bash scripts/commands/p5.sh ex1
```

L'orchestrateur exécute le parcours suivant.

## 4.1 Préparer l'artefact Angular

Commande interne principale :

```bash
bash scripts/commands/prepare-angular-artifact.sh
```

### Rôle

Le dépôt contient :

```text
application/angular/          sources
ansible/files/angular-app/    artefact à déployer
```

Le script vérifie/converge l'artefact afin qu'Ansible déploie le build issu des sources actuelles.

### Vérification conceptuelle

La CI exécute notamment :

```bash
npm ci --prefix application/angular --no-audit --no-fund
npm run lint --prefix application/angular
npm test --prefix application/angular
npm run build --prefix application/angular
```

puis compare le build avec l'artefact Ansible.

## 4.2 Initialiser Terraform

Le moteur lance pour `terraform/exercice-1` :

```bash
terraform init -input=false
```

### Pourquoi ?

`terraform init` prépare le répertoire de travail et télécharge les providers verrouillés par le module.

Ce n'est pas une création de ressources AWS.

## 4.3 Calculer le delta

Le moteur utilise :

```bash
terraform plan -input=false -detailed-exitcode -out=tfplan
```

### Lire les codes

```text
0 → configuration déjà conforme
2 → Terraform a détecté un changement à appliquer
autre → erreur
```

Le plan sauvegardé est ensuite affiché avec :

```bash
terraform show -no-color tfplan
```

### Ce qu'il faut lire

Avant d'accepter un delta, vérifier notamment :

- bon compte et bonne région ;
- VPC attendu ;
- deux subnets publics ;
- Security Group SSH `/32` ;
- HTTP 80 ;
- type EC2 attendu ;
- clé EC2 attendue ;
- volume chiffré ;
- aucune ressource inattendue.

## 4.4 Appliquer uniquement si nécessaire

Si le plan retourne `2`, le moteur demande confirmation puis applique **le plan sauvegardé**.

Après l'apply, il exécute un nouveau plan.

Résultat attendu : aucun delta résiduel.

## 4.5 Lire les outputs Terraform

Le moteur récupère notamment :

- l'IPv4 publique de l'EC2 Angular ;
- l'URL HTTP de l'application.

Ces valeurs doivent venir de Terraform. Ne pas recopier arbitrairement une autre EC2 depuis la console.

Pour comprendre manuellement les outputs :

```bash
terraform -chdir=terraform/exercice-1 output
```

## 4.6 Générer l'inventaire Ansible

```bash
bash scripts/commands/generate-ansible-inventory.sh
```

Le fichier local est :

```text
ansible/inventories/hosts_aws
```

Il est ignoré par Git parce qu'il contient des informations propres au lab courant.

## 4.7 Attendre SSH

Le moteur attend que :

- l'instance soit joignable ;
- Python soit disponible ;
- `cloud-init` soit terminé.

Cette attente évite d'exécuter Ansible sur une EC2 encore en initialisation.

## 4.8 Tester Ansible

```bash
ansible all -i ansible/inventories/hosts_aws -m ping
```

Résultat attendu : `SUCCESS` et `pong`.

Si le ping échoue, ne pas passer au playbook. Diagnostiquer d'abord :

- IP publique ;
- Security Group ;
- route Internet ;
- clé SSH ;
- utilisateur `ubuntu` ;
- permissions de la clé.

## 4.9 Déployer Angular et NGINX

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le playbook :

1. installe NGINX et `curl` ;
2. crée le groupe et l'utilisateur applicatifs ;
3. crée `/var/www/p5` ;
4. copie l'artefact Angular ;
5. installe la configuration NGINX ;
6. active le site P5 ;
7. retire le site par défaut ;
8. exécute `nginx -t` ;
9. démarre et active NGINX ;
10. recharge NGINX lorsque les fichiers notifiés changent.

## 4.10 Prouver l'idempotence

Le moteur rejoue le même playbook.

Résultat strict attendu :

```text
changed=0
unreachable=0
failed=0
```

Si `changed` est supérieur à zéro, comprendre quelle tâche change encore avant de considérer l'exercice convergé.

## 4.11 Vérifier l'application

```bash
bash scripts/commands/verify-angular-deployment.sh --url <URL_TERRAFORM>
```

Le contrôle vérifie notamment :

- HTTP disponible ;
- application Angular servie ;
- bundle JavaScript accessible ;
- fallback SPA.

## 4.12 Générer et collecter les logs

Le moteur génère du trafic puis collecte le log NGINX :

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url <URL_TERRAFORM> --requests 96
```

puis :

```bash
bash scripts/commands/collect-nginx-access-log.sh \
  --host <IP_TERRAFORM> \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

### Definition of Done exercice 1

- [ ] Terraform convergé ;
- [ ] EC2 disponible ;
- [ ] Ansible ping réussi ;
- [ ] premier playbook sans échec ;
- [ ] second playbook `changed=0`, `unreachable=0`, `failed=0` ;
- [ ] Angular accessible derrière NGINX ;
- [ ] log réel NGINX collecté ;
- [ ] preuves utiles conservées.

---

# Exercice 2 — Amazon OpenSearch

## Phase 5 — Lancer l'exercice 2

```bash
bash scripts/commands/p5.sh ex2
```

## 5.1 Terraform OpenSearch

Le même mécanisme `init → plan → show → confirmation → apply → post-plan` est utilisé dans :

```text
terraform/exercice-2
```

Vérifier le plan :

- domaine OpenSearch attendu ;
- moteur attendu ;
- un nœud pour le lab ;
- volume EBS attendu ;
- chiffrement ;
- HTTPS ;
- policy limitée à votre `/32` ;
- absence de ressource inattendue.

## 5.2 Lire les endpoints

Terraform fournit :

- endpoint OpenSearch ;
- URL OpenSearch Dashboards.

L'orchestrateur refuse d'inventer ces valeurs si elles sont absentes.

## 5.3 Valider les données avant import

Le sample versionné est validé sans mutation OpenSearch :

```bash
bash scripts/commands/import-opensearch-data.sh
```

Si le log réel de l'exercice 1 existe, il est également validé :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log
```

## 5.4 Importer dans OpenSearch

Après confirmation, l'orchestrateur applique l'import :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --endpoint <ENDPOINT> --apply
```

et, si disponible :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log \
  --endpoint <ENDPOINT> --apply
```

`--apply` est important : sans ce drapeau, le script reste dans une logique de validation/prévisualisation.

## 5.5 Vérifier mappings et agrégations

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint <ENDPOINT>
```

Le but est de prouver que les données peuvent réellement produire les métriques du dashboard.

## 5.6 Checkpoint humain OpenSearch Dashboards

Ouvrir l'URL fournie par Terraform.

Vérifier les données dans Discover, puis créer/vérifier :

1. **donut des méthodes HTTP** ;
2. **somme de `bytes_sent` par tranches de 12 h** ;
3. **top 5 `url_path` par tranches de 12 h** ;
4. dashboard contenant les trois.

### Captures à conserver

- capture du donut ;
- capture de la métrique `bytes_sent` / 12 h ;
- capture du top 5 / 12 h ;
- capture du dashboard complet.

Le mode `--yes` de l'orchestrateur **ne confirme pas** cette action à votre place. Le checkpoint demande une validation explicite lorsque la preuve est réellement produite.

### Definition of Done exercice 2

- [ ] domaine OpenSearch actif ;
- [ ] données importées sans erreur Bulk ;
- [ ] mapping exploitable ;
- [ ] comptage et agrégations vérifiés ;
- [ ] données visibles dans Dashboards ;
- [ ] trois visualisations correctes ;
- [ ] dashboard complet ;
- [ ] quatre captures réelles conservées.

---

# Exercice 3 — HAProxy et résilience

## Phase 6 — Lancer l'exercice 3

```bash
bash scripts/commands/p5.sh ex3
```

## 6.1 Précondition réseau

L'exercice 3 réutilise le VPC et les subnets créés par l'exercice 1.

Si les ressources de l'exercice 1 ont été détruites, l'exercice 3 ne peut pas résoudre correctement ses data sources.

## 6.2 Terraform HAProxy

Le module :

```text
terraform/exercice-3
```

crée :

- Security Group HAProxy ;
- Security Group backends ;
- deux EC2 backend ;
- une EC2 HAProxy.

Les backends installent Docker et exécutent :

```text
nginxdemos/hello:plain-text
```

HAProxy est configuré pour pointer vers leurs IP privées.

## 6.3 Attendre HAProxy

Le moteur attend une réponse HTTP sur l'URL issue des outputs Terraform.

Cette étape confirme que le `user_data` et le service HAProxy ont terminé leur initialisation.

## 6.4 Vérifier le round-robin

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url <HAPROXY_URL> --requests 12
```

Le test doit observer les deux backends.

## 6.5 Prévisualiser le scénario de panne

Avant mutation réelle :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url <HAPROXY_URL> \
  --backend-host <BACKEND_1_IP>
```

Cette exécution explique/valide le scénario sans arrêter réellement le backend.

## 6.6 Rejouer la panne réelle

Après confirmation :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url <HAPROXY_URL> \
  --backend-host <BACKEND_1_IP> \
  --apply
```

Le test doit démontrer :

```text
1. deux backends visibles avant panne
2. arrêt contrôlé du backend 1
3. HAProxy retire le backend défaillant
4. HTTP continue via le backend 2
5. backend 1 redémarré
6. HAProxy le réintègre
7. deux backends visibles à nouveau
```

Le script prévoit une restauration afin de ne pas laisser volontairement le backend arrêté après une interruption normale du test.

### Definition of Done exercice 3

- [ ] trois EC2 actives pendant la démonstration ;
- [ ] HAProxy accessible ;
- [ ] deux backends observés en round-robin ;
- [ ] health checks actifs ;
- [ ] un backend retiré pendant la panne ;
- [ ] service disponible pendant la panne ;
- [ ] backend restauré et réintégré ;
- [ ] configuration HAProxy lisible disponible pour le livrable ;
- [ ] preuves avant / panne / reprise conservées.

---

# Phase 7 — Diagnostics et finalisation

## 7.1 Collecter les diagnostics

```bash
bash scripts/commands/p5.sh diagnostics
```

Cette commande collecte l'état détaillé et vérifie la structure des livrables.

## 7.2 Contrôle strict

```bash
bash scripts/commands/p5.sh finalize
```

Le contrôle strict échoue si les livrables contiennent encore des marqueurs de preuve à compléter.

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## 7.3 Relire les preuves

Avant publication :

- retirer ou masquer les données sensibles inutiles ;
- ne jamais publier de clé ou token ;
- ne pas publier le state Terraform ;
- ne pas publier les vrais `tfvars` ;
- ne pas publier l'inventaire réel ;
- contextualiser chaque capture ou sortie CLI.

---

# Phase 8 — Nettoyage AWS

## 8.1 Pourquoi le nettoyage vient après les preuves

Les ressources doivent rester disponibles tant que la démonstration ou les captures ont encore besoin d'elles.

Mais dès que les preuves sont acquises, conserver OpenSearch et les EC2 ne produit plus de valeur pédagogique et peut produire des coûts.

## 8.2 Lancer le nettoyage

```bash
bash scripts/commands/p5.sh cleanup
```

La commande appelle la destruction Terraform dans l'ordre :

```text
3 → 2 → 1
```

La confirmation forte `DETRUIRE` reste nécessaire.

## 8.3 Auditer après destruction

Le moteur appelle ensuite le contrôle AWS global.

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

### Si l'audit détecte encore une ressource

Ne pas la supprimer au hasard depuis la console si elle appartient encore à un state Terraform valide.

Procédure :

1. identifier l'exercice propriétaire ;
2. vérifier son state ;
3. utiliser Terraform pour converger/détruire ;
4. relancer l'audit.

---

# Reprise après interruption

Si le terminal a été fermé ou Windows redémarré :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

`all` réutilise les states et recalcule les deltas. Il ne doit pas être compris comme une commande « supprimer puis recréer ».

Pour une reprise plus ciblée :

```bash
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
```

selon l'étape réellement incomplète.

# Parcours complet en une commande

Une fois l'environnement compris et préparé :

```bash
bash scripts/commands/p5.sh all
```

Le moteur enchaîne :

```text
prepare
  ↓
ex1
  ↓
ex2
  ↓
ex3
  ↓
diagnostics
```

Il ne détruit pas AWS à la fin.

Le mode :

```bash
bash scripts/commands/p5.sh all --yes
```

peut confirmer les mutations automatisables, mais ne contourne pas :

- le checkpoint humain OpenSearch ;
- les informations non vérifiables ;
- la confirmation forte de destruction.

# Commandes de support

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh docs
bash scripts/commands/p5.sh diagnostics
```

En cas de problème, consulter [`troubleshooting.md`](troubleshooting.md) avant de modifier manuellement l'infrastructure.
