# 01 — Parcours conseillé pour débuter

## Étape 0 — Comprendre avant d’exécuter

Lisez le [cadre officiel](00-cadre-officiel.md), puis lancez les contrôles non
destructifs :

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/validate.sh
```

Ces commandes n’installent rien et ne créent aucune ressource AWS.

## Étape 1 — Terraform et Ansible

1. Utilisez le mode **AWS retenu pour ce projet**.
2. Créez `terraform.tfvars` depuis l’exemple.
3. Exécutez `terraform init`, puis `terraform plan`.
4. Lisez le plan avant `terraform apply`.
5. Créez l’inventaire Ansible à partir de l’adresse retournée par Terraform.
6. Vérifiez la connexion avec le module `ping`.
7. Remplacez la page de démonstration par le véritable build Angular.
8. Exécutez `deploy.yml` et vérifiez l’application sur le port 80.
9. Collectez les preuves.

Fiche : [Exercice 1](exercices/01-terraform-ansible.md).

## Étape 2 — Amazon OpenSearch

1. Utilisez le mode **Cloud AWS retenu** avec Amazon OpenSearch.
2. Déployez le domaine à partir de `terraform/exercice-2/`.
3. Importez `nginx-access.log`.
4. Créez l’index ou le motif `nginx-access`.
5. Explorez les champs dans Discover.
6. Construisez manuellement les trois visualisations imposées.
7. Capturez le dashboard complet et chaque graphique séparément.
8. Détruisez OpenSearch après les preuves si vous utilisez AWS.

Fiche : [Exercice 2](exercices/02-elk-opensearch.md).

## Étape 3 — HAProxy

1. Déployez sur AWS deux instances EC2 `nginxdemos/hello` et une instance EC2 HAProxy.
2. Configurez `roundrobin` et les health checks.
3. Rafraîchissez la page pour observer l’alternance des backends.
4. Arrêtez un backend et vérifiez que le service reste disponible.
5. Redémarrez-le et vérifiez sa réintégration automatique.
6. Conservez `haproxy.cfg` et les preuves avant, pendant et après la panne.

Fiche : [Exercice 3](exercices/03-haproxy.md).

## Étape 4 — Livrables

Utilisez [la checklist](livrables/README.md). Une capture d’exemple ou une zone
« à compléter » ne remplace jamais une preuve produite sur votre environnement.

## Étape 5 — Nettoyage

```bash
./scripts/commands/destroy-aws.sh
```

La commande détruit les exercices dans l’ordre 3, 2 puis 1. Vérifiez ensuite
manuellement EC2 et OpenSearch dans la console AWS. Ne supprimez jamais les
fichiers d’état Terraform avant cette destruction.
