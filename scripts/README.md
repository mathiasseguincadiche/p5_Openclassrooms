# Scripts du projet P5

Les scripts préparent et contrôlent le lab sans masquer les commandes
pédagogiques. Aucun script ne lance automatiquement les trois exercices.

| Besoin | Commande |
| --- | --- |
| Installer le socle sur Ubuntu Server 26.04 | `./scripts/commands/bootstrap-ubuntu-server.sh` |
| Vérifier la VM et l’arborescence | `./scripts/commands/setup.sh --check-only` |
| Contrôler avant le premier `apply` | `./scripts/commands/pre-deployment-check.sh` |
| Construire Angular et préparer Ansible | `./scripts/commands/prepare-angular-artifact.sh` |
| Valider les fichiers du dépôt | `./scripts/commands/validate.sh` |
| Contrôler les trois gabarits | `./scripts/commands/prepare-livrables.sh` |
| Nettoyer les caches sans supprimer les états | `./scripts/commands/clean-local.sh` |
| Détruire les ressources AWS | `./scripts/commands/destroy-aws.sh` |
| Générer un `haproxy.cfg` minimal | `./scripts/tools/generer-haproxy-config.sh IP1 IP2` |

## Règles de sécurité

- `bootstrap-ubuntu-server.sh` installe des outils, mais ne configure aucun
  secret et ne crée aucune ressource AWS.
- `pre-deployment-check.sh` est non destructif.
- `prepare-angular-artifact.sh` remplace uniquement l’artefact sous
  `ansible/files/angular-app/` après un build réussi.
- `destroy-aws.sh` détruit dans l’ordre **3 → 2 → 1**.
- `clean-local.sh` conserve les états Terraform pour ne pas orpheliner des
  ressources AWS.
