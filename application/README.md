# Application du projet P5

Le dépôt contient **une application web Angular réelle et autonome**. Elle est construite sur la VM de lab, copiée dans l'artefact Ansible, puis servie par NGINX sur l'instance EC2 de l'exercice 1.

L'interface présente le parcours complet du projet : VM, préparation AWS, Terraform, Ansible, OpenSearch et HAProxy. Elle ne dépend d'aucun service ou asset graphique externe.

```text
application/
└── angular/
    ├── angular.json
    ├── package.json
    ├── package-lock.json
    ├── tsconfig.json
    ├── public/
    └── src/

scripts/commands/
├── prepare-angular-artifact.sh
└── verify-angular-deployment.sh

ansible/
├── files/angular-app/        # build Angular versionné
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

## Construire l'artefact

Depuis la racine du dépôt :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

Le script exige le fichier de verrouillage npm, exécute un build de production, détecte l'unique artefact navigateur puis remplace proprement `ansible/files/angular-app/`.

La CI reconstruit également l'application et compare le résultat au build versionné. Une modification des sources qui n'a pas été répercutée dans l'artefact Ansible bloque donc la pull request.

## Vérifier le déploiement réel

Après Terraform et Ansible :

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le contrôle vérifie la réponse HTTP, la présence de la racine Angular, le bundle JavaScript, le fallback SPA NGINX et un en-tête de sécurité. Les résultats sont enregistrés localement sous `proofs/runtime/exercice-1/`.

Cette application constitue la source de référence du dépôt. Toute évolution doit conserver la reproductibilité du build et la synchronisation exacte avec l’artefact déployé par Ansible.
