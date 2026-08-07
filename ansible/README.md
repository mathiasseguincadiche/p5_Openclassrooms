# Déploiement Ansible — Exercice 1

Le playbook installe NGINX sur l’instance EC2, copie le build Angular versionné et sert l’application sur le port 80.

```text
application/angular/             # sources Angular reproductibles
        │ npm ci + npm run build
        ▼
ansible/files/angular-app/       # build navigateur synchronisé
ansible/files/nginx-angular.conf # configuration NGINX
ansible/inventories/             # cible EC2
ansible/playbooks/deploy.yml     # déploiement idempotent
```

## Préparer l’application

Depuis la racine du dépôt :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script vérifie `package.json` et `package-lock.json`, exécute un build reproductible, détecte l’unique artefact navigateur puis remplace atomiquement `ansible/files/angular-app/`.

La CI reconstruit l’application et compare exactement le résultat au build versionné. Toute modification des sources non répercutée dans l’artefact Ansible bloque donc la pull request.

## Préparer l’inventaire

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
```

Reporter l’adresse retournée dans `hosts_aws`. L’inventaire réel est ignoré par Git.

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

Le playbook crée l’utilisateur de service, déploie sous `/var/www/p5`, valide NGINX, active le site et recharge le service uniquement lorsqu’un fichier change.

## Vérifier le service

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le contrôle vérifie la réponse HTTP, la racine Angular, le bundle JavaScript, le fallback SPA et les en-têtes de sécurité NGINX. Les résultats restent sous `proofs/runtime/exercice-1/` et ne doivent être publiés qu’après relecture.
