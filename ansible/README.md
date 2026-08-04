# Déploiement Ansible — Exercice 1

Le playbook installe NGINX sur l’instance EC2, copie l’artefact Angular et sert
l’application sur le port 80.

```text
application/angular/             # sources du starter
        │ npm ci + npm run build
        ▼
ansible/files/angular-app/       # artefact navigateur
ansible/files/nginx-angular.conf # configuration NGINX
ansible/inventories/             # cible EC2
ansible/playbooks/deploy.yml     # déploiement idempotent
```

## Préparer l’application

Copier le starter Angular dans `application/angular/`, puis :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script détecte le `index.html` généré sous `dist/` et remplace l’artefact de
démonstration. Ne présentez jamais la page témoin comme une preuve de build
Angular.

## Préparer l’inventaire

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
```

Reporter l’adresse retournée dans `hosts_aws`. L’inventaire réel est ignoré par
Git.

## Vérifier puis déployer

```bash
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le playbook crée l’utilisateur de service, déploie sous `/var/www/p5`, valide
NGINX, active le site et recharge le service uniquement lorsqu’un fichier
change.
