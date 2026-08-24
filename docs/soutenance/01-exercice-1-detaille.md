# P5 OpenClassrooms — Runbook mentor — Exercice 1

## Objectif de la séquence

**Exercice 1 : développer l'infrastructure IaC avec Terraform et automatiser le déploiement avec Ansible.**

L'objectif de la démonstration n'est pas de refaire un cours sur Terraform ou Ansible. Il faut prouver, dans cet ordre :

1. que l'infrastructure AWS est décrite et gérée par Terraform ;
2. qu'Ansible sait joindre la cible créée par Terraform ;
3. que le playbook configure réellement NGINX et déploie Angular ;
4. que la configuration est rejouable sans changement inutile ;
5. que l'application est réellement accessible en HTTP.

> **Phrase d'ouverture**
>
> « J'ai choisi le mode Cloud AWS. Terraform prend en charge l'infrastructure, puis Ansible prend le relais pour la configuration du serveur et le déploiement de l'application Angular derrière NGINX. Je vais d'abord vous montrer l'architecture, puis la démonstration de bout en bout. »

---

## 1 — Architecture à présenter

![Schéma Exercice 1](../schemas/soutenance/exercice-1-detaille.svg)

### Lecture du schéma

**Plan de contrôle local**

- Windows 11 est l'OS hôte.
- WSL2 Ubuntu 26.04 est le plan de contrôle Linux du projet.
- Terraform, AWS CLI, Ansible et les commandes du dépôt sont lancés depuis cet environnement.
- La clé SSH du lab est utilisée par Ansible pour administrer l'EC2.

**AWS — région `us-east-1`**

Terraform crée :

- un VPC `p5-vpc` en `10.0.0.0/16` ;
- deux subnets publics :
  - `10.0.1.0/24` dans une première zone de disponibilité ;
  - `10.0.2.0/24` dans une deuxième zone ;
- une Internet Gateway ;
- une table de routage publique avec `0.0.0.0/0` vers l'Internet Gateway ;
- un Security Group `p5-web-sg` ;
- une paire de clés EC2 ;
- une EC2 `p5-web` dans le premier subnet.

L'EC2 est une `t3.micro` sous Ubuntu 24.04. Le volume racine est en `gp3` chiffré et IMDSv2 est obligatoire.

### Pourquoi deux subnets alors qu'il n'y a qu'une EC2 dans l'exercice 1 ?

Le deuxième subnet fait partie du socle réseau du projet et sera réutilisé par l'exercice 3. Cela permet de conserver une architecture cohérente et d'y répartir les futurs backends HAProxy.

### Security Group

```text
TCP/22  ← uniquement l'IPv4 publique d'administration /32
TCP/80  ← 0.0.0.0/0
egress  → autorisé
```

**Ce que tu dis :**

> « Le SSH n'est pas ouvert à Internet : il est limité à mon IP publique en `/32`. Le port 80 est public parce que l'application doit être accessible dans le navigateur. »

### Frontière Terraform / Ansible

```text
Terraform
  └─ réseau + sécurité + clé + EC2
         ↓
     EC2 prête à être administrée
         ↓ SSH
Ansible
  └─ NGINX + utilisateur applicatif + artefact Angular + configuration NGINX
         ↓
Navigateur
  └─ HTTP 80 → NGINX → Angular
```

Le `user_data` Terraform installe seulement Python 3, car Python est nécessaire au fonctionnement d'Ansible sur la cible.

**Phrase importante :**

> « J'ai volontairement gardé une séparation des responsabilités : Terraform prépare l'infrastructure et la machine ; Ansible configure le système et déploie l'application. »

---

## 2 — Fichiers à connaître avant la présentation

```text
terraform/exercice-1/main.tf
terraform/exercice-1/variables.tf
terraform/exercice-1/outputs.tf
ansible/inventories/hosts_aws
ansible/inventories/hosts_aws.example
ansible/playbooks/deploy.yml
ansible/files/angular-app/
ansible/files/nginx-angular.conf
application/angular/
scripts/commands/verify-angular-deployment.sh
```

Le fichier `hosts_aws` réel est généré à partir des outputs Terraform et ne doit pas être confondu avec `hosts_aws.example`.

---

## 3 — Préparation hors présentation

À faire avant que le mentor arrive :

```bash
cd ~/labs/p5_Openclassrooms
git switch main
git pull --ff-only

bash scripts/commands/p5.sh status
```

Le lab doit être dans un état cohérent. Ne lance pas de destruction AWS avant la fin des trois exercices.

Prépare l'URL :

```bash
export WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
printf '%s\n' "$WEB_URL"
```

Ouvre déjà `$WEB_URL` dans un onglet de ton **navigateur Internet habituel sous Windows 11** (Firefox, Edge ou Chrome). Le navigateur ne tourne pas dans WSL2 : WSL2 lance les commandes, puis le navigateur Windows accède à l’URL publique de l’EC2.

---

## 4 — Démonstration Exercice 1

### Étape A — Montrer que Terraform connaît l'infrastructure

```bash
terraform -chdir=terraform/exercice-1 output
```

#### À regarder

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_private_ip
web_public_dns
web_url
```

#### Ce que ça prouve

Le state Terraform possède les valeurs réelles de l'infrastructure déployée.

#### Ce que tu dis

> « Je commence par les outputs Terraform. Ils me donnent les identifiants et adresses utiles de l'infrastructure réellement créée, notamment le VPC, les deux subnets, le Security Group et l'IP de l'EC2. »

---

### Étape B — Montrer la convergence Terraform

```bash
terraform -chdir=terraform/exercice-1 plan \
  -input=false \
  -detailed-exitcode
```

#### Résultat attendu

```text
No changes.
Your infrastructure matches the configuration.
```

Code de sortie attendu : `0`.

#### Ce que ça prouve

L'état réel AWS et l'état déclaré dans le code Terraform sont alignés.

#### Ce que tu dis

> « Le plan ne propose aucun changement. L'infrastructure est donc convergée : ce qui existe sur AWS correspond à ce que décrit mon code Terraform. »

> **Ne fais pas un `terraform apply` pour le spectacle si le plan est vide.** Un `apply` inutile n'ajoute aucune preuve.

---

### Étape C — Prouver la connectivité Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

#### Résultat attendu

```text
SUCCESS
"ping": "pong"
```

#### Ce que ça prouve

Ansible peut :

- résoudre la cible de l'inventaire ;
- se connecter en SSH ;
- s'authentifier avec la clé ;
- exécuter Python sur l'EC2.

#### Ce que tu dis

> « L'inventaire pointe vers l'EC2 créée par Terraform et le `ping` Ansible confirme que la chaîne SSH et Python est opérationnelle. »

---

### Étape D — Montrer rapidement le playbook

Commande de lecture ciblée :

```bash
grep -nE \
  'Installer NGINX|Déployer l.artefact Angular|configuration NGINX|nginx -t|Démarrer et activer NGINX|handlers|Recharger NGINX' \
  ansible/playbooks/deploy.yml
```

#### Points à expliquer

Le playbook :

- installe `nginx` et `curl` ;
- crée `appgroup` et `appuser` ;
- crée `/var/www/p5` ;
- copie l'artefact Angular ;
- déploie la configuration NGINX ;
- active le site et retire le site par défaut ;
- exécute `nginx -t` ;
- démarre et active NGINX ;
- recharge NGINX via un handler uniquement lorsqu'une configuration change.

#### Ce que tu dis

> « Mon playbook décrit l'état voulu du serveur. Il ne se contente pas de lancer des commandes shell : les tâches Ansible convergent la machine vers l'état attendu et le handler ne recharge NGINX que lorsque c'est nécessaire. »

---

### Étape E — Vérifier la syntaxe

```bash
ansible-playbook \
  --syntax-check \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

#### Résultat attendu

```text
playbook: ansible/playbooks/deploy.yml
```

Aucune erreur.

---

### Étape F — Prouver l'idempotence

Sur un environnement déjà déployé :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

#### Résultat attendu dans le recap

```text
changed=0
unreachable=0
failed=0
```

#### Ce que ça prouve

Le playbook peut être rejoué et ne modifie pas inutilement une machine déjà conforme.

#### Ce que tu dis

> « Le point important ici est `changed=0`. Le serveur était déjà dans l'état voulu, donc Ansible ne refait pas inutilement le déploiement. C'est la preuve d'idempotence. »

---

### Étape G — Prouver le résultat HTTP

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$WEB_URL"
```

#### Résultats attendus essentiels

```text
OK  réponse HTTP 200
OK  document Angular identifié
OK  bundle principal accessible
OK  fallback SPA NGINX opérationnel
OK  en-tête de sécurité nosniff

Verdict : APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

#### Puis navigateur

Dans ton **navigateur Internet Windows** (Firefox, Edge ou Chrome), ouvre :

```text
$WEB_URL
```

Tu copies simplement l’URL affichée par `echo "$WEB_URL"` ou `printf`, puis tu la colles dans la barre d’adresse. Montre l’application, rafraîchis une fois et navigue si nécessaire.

#### Ce que tu dis

> « La preuve finale est applicative : l'EC2 répond en HTTP 200, NGINX sert bien l'artefact Angular et le fallback SPA fonctionne. »

---

## 5 — Conclusion de l'exercice 1

> « Pour résumer : Terraform fournit une infrastructure AWS versionnée et convergée ; Ansible se connecte à la cible, installe et configure NGINX puis déploie Angular de façon idempotente ; enfin la vérification HTTP prouve que l'application est réellement accessible. Les logs NGINX générés ici deviennent ensuite une source de données pour l'exercice 2. »

---

## 6 — Questions probables du mentor

### Pourquoi Terraform et Ansible, pourquoi pas un seul outil ?

Terraform est utilisé pour le **cycle de vie de l'infrastructure** AWS. Ansible est utilisé pour la **configuration du système** et le **déploiement applicatif**. Cette séparation rend les responsabilités plus lisibles.

### Pourquoi installer Python 3 dans `user_data` ?

Parce qu'Ansible utilise Python sur la machine distante. Le `user_data` prépare seulement ce prérequis ; il ne déploie pas NGINX ni Angular, afin de conserver la frontière Terraform/Ansible.

### Pourquoi `changed=0` est important ?

Parce qu'un système d'automatisation doit pouvoir être rejoué. Si l'état est déjà conforme, un second passage ne doit pas produire de modifications inutiles.

### Pourquoi SSH en `/32` ?

Pour limiter l'accès administratif à une seule IPv4 publique au lieu d'exposer SSH à tout Internet.

### Pourquoi deux subnets ?

L'exercice 1 construit le socle réseau complet. Le second subnet sera réutilisé dans l'exercice 3 pour répartir les backends.

### Pourquoi ne pas détruire l'exercice 1 immédiatement ?

Dans cette implémentation, l'exercice 3 retrouve et réutilise le VPC et les subnets de l'exercice 1. L'ordre de destruction doit donc être `Exercice 3 → Exercice 2 → Exercice 1`.

---

## 7 — Attention à une incohérence de formulation dans la consigne

La consigne PDF mélange à un endroit les notions **AMI** et **type d'instance** (`t2.micro` / `t3.micro`). Dans le dépôt, l'implémentation est cohérente :

```text
AMI        : Ubuntu 24.04 LTS Canonical
instance   : t3.micro
```

Si le mentor pose la question, ne dis pas « AMI t3.micro » : `t3.micro` est un **type d'instance EC2**, pas une AMI.
