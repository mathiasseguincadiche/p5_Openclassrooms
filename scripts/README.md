# Scripts du projet P5

Les scripts préparent et contrôlent le lab sans masquer les commandes
pédagogiques. Aucun script ne lance automatiquement les trois exercices AWS.

| Besoin | Commande |
| --- | --- |
| Installer le socle sur Ubuntu Server 26.04 | `./scripts/commands/bootstrap-ubuntu-server.sh` |
| Vérifier la VM et l’arborescence | `./scripts/commands/setup.sh --check-only` |
| Générer les trois `terraform.tfvars` | `bash scripts/commands/sync-terraform-tfvars.sh --apply` |
| Vérifier la cohérence des variables | `bash scripts/commands/sync-terraform-tfvars.sh --check` |
| Contrôler avant le premier `apply` | `./scripts/commands/pre-deployment-check.sh` |
| Construire Angular et préparer Ansible | `./scripts/commands/prepare-angular-artifact.sh` |
| Valider le dépôt et les intégrations courtes | `./scripts/commands/validate.sh` |
| Inclure OpenSearch local dans la validation | `P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh` |
| Tester Angular derrière NGINX | `bash scripts/tests/test-nginx-angular.sh` |
| Tester HAProxy, panne et reprise | `bash scripts/tests/test-haproxy-containers.sh` |
| Tester OpenSearch local et les agrégations | `bash scripts/tests/test-opensearch-local.sh` |
| Contrôler les trois gabarits | `./scripts/commands/prepare-livrables.sh` |
| Nettoyer les caches sans supprimer les états | `./scripts/commands/clean-local.sh` |
| Détruire les ressources AWS | `./scripts/commands/destroy-aws.sh` |
| Générer un `haproxy.cfg` minimal | `./scripts/tools/generer-haproxy-config.sh IP1 IP2` |

## Règles de sécurité

- `bootstrap-ubuntu-server.sh` installe des outils, mais ne configure aucun
  secret et ne crée aucune ressource AWS.
- `sync-terraform-tfvars.sh` écrit des fichiers locaux en mode `600` et refuse
  les valeurs d’exemple du compte AWS et de l’adresse IP.
- `pre-deployment-check.sh` est non destructif et bloque les variables
  Terraform désynchronisées.
- les tests NGINX, HAProxy et OpenSearch utilisent uniquement des conteneurs
  éphémères locaux ; ils sont supprimés par un `trap`, même en cas d’échec.
- `prepare-angular-artifact.sh` remplace uniquement l’artefact sous
  `ansible/files/angular-app/` après un build réussi.
- `destroy-aws.sh` détruit dans l’ordre **3 → 2 → 1**.
- `clean-local.sh` conserve les états Terraform pour ne pas orpheliner des
  ressources AWS.
