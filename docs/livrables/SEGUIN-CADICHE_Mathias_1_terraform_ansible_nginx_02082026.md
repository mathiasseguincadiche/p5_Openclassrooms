# Livrable 1 — Terraform, Ansible, NGINX et application Angular

> **Gabarit à compléter avec des preuves réelles.** La présence de ce fichier ne prouve pas que l'exercice a été exécuté.

## 1. Objectif

Démontrer qu'une infrastructure AWS est provisionnée avec Terraform puis qu'Ansible configure l'EC2 afin de servir l'application Angular du dépôt avec NGINX.

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
- cible : EC2 Ubuntu ;
- application : `application/angular/` ;
- serveur HTTP : NGINX ;
- port applicatif public : 80 ;
- SSH : limité à l'IPv4 `/32` du poste.

## 3. Fichiers remis

```text
terraform/exercice-1/
ansible/playbooks/deploy.yml
ansible/files/nginx-angular.conf
ansible/files/angular-app/
application/angular/
```

Ne pas joindre :

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

Cette commande enchaîne le build Angular, Terraform, la génération d'inventaire, Ansible, l'idempotence, la vérification HTTP et la collecte des logs.

## 5. Preuve Terraform

### À montrer

- `terraform init` réussi ;
- plan relu ;
- ressources attendues ;
- apply réel ;
- post-plan sans delta ;
- outputs utiles.

### Ressources attendues

```text
VPC
2 subnets publics
Internet Gateway
route publique
Security Group
EC2 Key Pair
1 EC2 p5-web
```

### Points de sécurité visibles

```text
SSH depuis /32
HTTP :80 public
IMDSv2 obligatoire
volume racine chiffré
compte AWS verrouillé
```

### Preuve à insérer

**Preuve Terraform réelle à insérer ici**, avec les données inutiles anonymisées.

### Interprétation à rédiger

Expliquer pourquoi le plan et le post-plan démontrent que Terraform a convergé vers l'état attendu.

## 6. Preuve Ansible — connectivité

Commande :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Résultat attendu :

```text
SUCCESS
pong
```

**Preuve Ansible ping à insérer ici.**

## 7. Preuve Ansible — premier déploiement

Commande :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le playbook doit :

- installer NGINX ;
- créer les droits applicatifs ;
- copier Angular ;
- installer la configuration NGINX ;
- valider `nginx -t` ;
- démarrer/activer NGINX.

Résultat minimal :

```text
unreachable=0
failed=0
```

**Preuve du premier passage à insérer ici.**

## 8. Preuve d'idempotence

Relancer exactement :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Résultat strict attendu :

```text
changed=0
unreachable=0
failed=0
```

**Preuve du second passage à insérer ici.**

### Interprétation

Expliquer que l'état étant déjà conforme, Ansible ne réalise plus de modification inutile.

## 9. Preuve applicative

Récupérer les outputs :

```bash
WEB_IP="$(terraform -chdir=terraform/exercice-1 \
  output -raw web_public_ip)"
WEB_URL="$(terraform -chdir=terraform/exercice-1 \
  output -raw web_url)"
```

Contrôle reproductible :

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$WEB_URL"
```

### À montrer

- application Angular réelle dans le navigateur ;
- HTTP 200 ;
- bundle JavaScript accessible ;
- fallback SPA fonctionnel.

**Capture de l'application à insérer ici.**

## 10. Logs NGINX pour l'exercice 2

Le parcours `p5.sh ex1` génère le trafic et collecte le log.

Équivalent détaillé :

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

Le fichier brut reste privé par défaut.

## 11. Conclusion de l'exercice

À rédiger après exécution :

```text
Terraform a créé et convergé l'infrastructure AWS attendue.
Ansible a configuré l'EC2 et déployé Angular derrière NGINX.
Le second passage a confirmé l'idempotence.
L'application est accessible et produit des logs réels exploitables pour l'exercice 2.
```

## 12. Dépendance avec l'exercice 3

Ne pas détruire le VPC de cet exercice avant la fin de l'exercice 3.

Le nettoyage global est :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La fermeture du lab est effectuée avec :

```bash
bash scripts/commands/p5.sh cleanup
```

Verdict final du projet :

```text
NETTOYAGE AWS COMPLET
```
