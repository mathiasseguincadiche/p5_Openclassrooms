# Déploiement Ansible — Exercice 1

Le playbook `playbooks/deploy.yml` installe NGINX, copie l'artefact web et
active la configuration qui sert l'application sur le port 80.

```text
ansible/
├── files/
│   ├── angular-app/index.html
│   └── nginx-angular.conf
├── inventories/hosts_aws.example
├── playbooks/deploy.yml
└── requirements.yml
```

## Préparer l'artefact Angular

Le fichier `angular-app/index.html` versionné est une page statique de
**démonstration**. Avant la remise officielle, remplacez le contenu du dossier
par le résultat réel de `ng build` fourni par l'application du starter kit.

## Exécuter

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

L'inventaire réel `ansible/inventories/hosts_aws` est exclu de Git.
