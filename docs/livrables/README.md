# Livrables et preuves du P5

OpenClassrooms demande trois ensembles de livrables correspondant aux trois
exercices officiels.

| Exercice | Éléments à remettre | Gabarit du dépôt |
| --- | --- | --- |
| 1 — Terraform et Ansible | Fichiers Terraform, inventaire anonymisé si nécessaire, playbook `deploy.yml` et preuves de déploiement | [Livrable 1](SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md) |
| 2 — ELK / OpenSearch | Dashboard des logs et captures des trois visualisations imposées | [Livrable 2](SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md) |
| 3 — HAProxy | `haproxy.cfg`, alternance, health checks, panne et reprise | [Livrable 3](SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md) |

## Règles de preuve

- Une zone « à compléter » n'est pas une preuve.
- Les captures doivent venir de votre environnement réel.
- Les IP peuvent être partiellement masquées, mais les résultats doivent rester
  vérifiables.
- Aucun secret, clé, mot de passe, identifiant AWS ou état Terraform ne doit
  apparaître.
- Le livrable 1 doit montrer la véritable application Angular, pas uniquement
  la page statique de démonstration du dépôt.
- Le livrable 2 doit contenir exactement les trois visualisations indiquées.
- Le livrable 3 doit inclure un `haproxy.cfg` nettoyé de tout secret.

## Nom et canal de remise

La page de bilan demande un ZIP nommé selon le projet, le nom et le prénom, et
un nom de livrable contenant son numéro et la date de démarrage. Les documents
fournis emploient à la fois « dépôt GitLab » et « dépôt GitHub ». Vérifiez la
consigne visible sur la plateforme et confirmez-la avec le mentor avant la
remise finale.

## Contrôle rapide

```bash
./scripts/commands/prepare-livrables.sh
```
