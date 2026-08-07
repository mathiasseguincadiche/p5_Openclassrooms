# Déploiement Ansible — Exercice 1

Ce dossier transforme l'instance EC2 créée par Terraform en serveur web NGINX
servant le build Angular du projet. Terraform **provisionne** la cible ; Ansible
la **configure**.

La procédure complète se trouve dans
[`docs/exercices/01-terraform-ansible.md`](../docs/exercices/01-terraform-ansible.md).

## Structure

```text
ansible/
├── inventories/
│   ├── hosts_aws.example     # structure versionnée
│   └── hosts_aws             # cible réelle, ignorée par Git
├── files/
│   ├── angular-app/          # build Angular exact à déployer
│   └── nginx-angular.conf    # configuration NGINX du projet
└── playbooks/
    └── deploy.yml
```

## Entrées du déploiement

Ansible dépend de trois éléments :

1. l'EC2 de l'exercice 1 existe ;
2. `ansible/files/angular-app/` correspond au build Angular courant ;
3. l'inventaire réel pointe vers l'IP publique Terraform avec la clé SSH du lab.

Préparer l'artefact :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Préparer l'inventaire :

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
$EDITOR ansible/inventories/hosts_aws
```

L'inventaire réel est ignoré par Git.

## Contrat du playbook

`playbooks/deploy.yml` cible le groupe `webservers` avec élévation de privilèges.
Il :

- installe NGINX et `curl` ;
- crée le groupe système `appgroup` ;
- crée l'utilisateur système `appuser` sans shell ;
- crée `/var/www/p5` ;
- copie le build Angular sous `/var/www/p5` ;
- installe `/etc/nginx/sites-available/p5` ;
- active le site et désactive le site NGINX par défaut ;
- exécute `nginx -t` ;
- démarre et active NGINX ;
- recharge NGINX uniquement lorsqu'un fichier concerné change.

Cette dernière propriété permet de démontrer l'idempotence lors d'une seconde
exécution.

## Vérifier la connexion

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Un échec ici doit être résolu avant le playbook. Vérifier en priorité :

- l'IP de l'inventaire ;
- l'utilisateur SSH ;
- la clé `~/.ssh/p5-key` ;
- les permissions `600` de la clé privée ;
- l'adresse `/32` autorisée dans le groupe de sécurité ;
- l'état de l'EC2.

## Prévisualiser puis déployer

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff

ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Rejouer ensuite la commande sans `--check` :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

La seconde exécution doit tendre vers zéro changement lorsque la cible est déjà
conforme.

## Configuration NGINX

`files/nginx-angular.conf` sert l'application sur le port 80 avec :

- racine `/var/www/p5` ;
- `index.html` comme index ;
- fallback SPA `try_files $uri $uri/ /index.html` ;
- cache long pour les assets versionnés ;
- en-têtes de sécurité ;
- gzip pour les formats texte et JavaScript.

Les assets inexistants renvoient une erreur plutôt que le fallback SPA afin de
ne pas masquer les fichiers manquants.

## Vérifier le résultat

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le verdict attendu est :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Les preuves automatisées sont écrites sous `proofs/runtime/exercice-1/` et ne
sont pas publiées automatiquement.

## Validation locale sans AWS

La CI et `validate.sh` contrôlent également la syntaxe Ansible et testent le
build Angular avec la vraie configuration NGINX dans un conteneur éphémère :

```bash
bash scripts/tests/test-nginx-angular.sh
```

## Sécurité

Ne versionnez jamais :

- `ansible/inventories/hosts_aws` ;
- une clé privée SSH ;
- un mot de passe ou token ;
- une sortie runtime non relue.

## Références

- [Architecture et flux](../docs/architecture-et-flux.md)
- [Application Angular](../application/README.md)
- [Exercice 1 complet](../docs/exercices/01-terraform-ansible.md)
- [Troubleshooting](../docs/troubleshooting.md)
