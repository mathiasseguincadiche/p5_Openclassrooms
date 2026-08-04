# Application du projet P5

Le projet fait fonctionner **une seule application web Angular**. Elle est
construite sur la VM de lab, copiée dans l’artefact Ansible, puis servie par
NGINX sur l’instance EC2 de l’exercice 1.

```text
application/
└── angular/                  # sources du starter Angular fourni
    ├── package.json
    ├── angular.json
    ├── src/
    └── dist/                 # résultat local de ng build, ignoré par Git

scripts/commands/
└── prepare-angular-artifact.sh

ansible/
├── files/angular-app/        # artefact normalisé à déployer
├── files/nginx-angular.conf
└── playbooks/deploy.yml
```

## Flux réel

```text
Sources Angular
      │ npm ci + npm run build
      ▼
application/angular/dist/
      │ copie contrôlée
      ▼
ansible/files/angular-app/
      │ ansible-playbook
      ▼
EC2 : /var/www/p5
      │ NGINX :80
      ▼
Application accessible
```

Le dépôt ne contient pas le starter OpenClassrooms s’il n’a pas été fourni avec
une licence permettant de le republier. Copiez ses sources dans
`application/angular/`, puis utilisez le script de préparation.

La page versionnée dans `ansible/files/angular-app/` sert uniquement de témoin
technique. Elle doit être remplacée par le build réel avant la remise.
