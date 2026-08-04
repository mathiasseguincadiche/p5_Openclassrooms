# Scripts du projet P5

Le dépôt évite volontairement le déploiement « en un clic ». Un débutant doit
lire le plan Terraform, exécuter les commandes de chaque fiche et comprendre ce
qui est créé.

| Besoin | Commande |
| --- | --- |
| Vérifier l’environnement sans rien installer | `./scripts/commands/setup.sh --check-only` |
| Valider la structure et les fichiers | `./scripts/commands/validate.sh` |
| Contrôler les trois gabarits de remise | `./scripts/commands/prepare-livrables.sh` |
| Supprimer les caches et plans locaux, sans toucher aux états | `./scripts/commands/clean-local.sh` |
| Détruire les ressources Terraform AWS | `./scripts/commands/destroy-aws.sh` |
| Générer un `haproxy.cfg` minimal | `./scripts/tools/generer-haproxy-config.sh IP1 IP2` |

`destroy-aws.sh` détruit les modules dans l’ordre **3 → 2 → 1** afin de
respecter la dépendance réseau entre les exercices 3 et 1. Une vérification
manuelle dans la console AWS reste obligatoire.

`clean-local.sh` conserve toujours les fichiers `terraform.tfstate`, car les supprimer avant `terraform destroy` pourrait laisser des ressources AWS orphelines.
