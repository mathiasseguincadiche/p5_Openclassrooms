# 📁 Templates DevOps

Ce dossier regroupe des exemples autonomes à copier dans d'autres projets. Ces
templates ne sont pas les fichiers de déploiement principaux du projet P5 : ils
servent de points de départ pédagogiques.

| Technologie | Contenu | Documentation |
| --- | --- | --- |
| Ansible | Inventaire et playbook génériques | [Ouvrir](./ansible/README.md) |
| Docker | Dockerfiles et Docker Compose | [Ouvrir](./docker/README.md) |
| GitHub Actions | Exemples de CI et CD AWS | [Ouvrir](./github-actions/README.md) |
| Kubernetes | Deployment, Service, Ingress et configuration | [Ouvrir](./kubernetes/README.md) |
| Terraform | Module AWS minimal | [Ouvrir](./terraform/README.md) |

## ✅ Principes d'utilisation

1. Copiez uniquement le template nécessaire.
2. Remplacez les valeurs d'exemple.
3. Injectez les secrets depuis l'environnement ou le gestionnaire de secrets.
4. Validez le fichier avant tout déploiement.

Les fichiers d'exemple n'intègrent aucune valeur d'identification réelle.
