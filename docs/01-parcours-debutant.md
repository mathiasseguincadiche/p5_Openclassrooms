# 01 — Parcours conseillé

## Étape 0 — Installer et valider le lab

La VM n’est pas un prérequis implicite : elle fait partie du projet.

1. Installer Ubuntu Server 26.04 LTS sans interface graphique.
2. Activer OpenSSH pendant l’installation.
3. Cloner le dépôt dans `~/labs/p5_Openclassrooms`.
4. Installer le socle DevOps :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

5. Se reconnecter pour activer le groupe `docker`.
6. Configurer Git, la clé `~/.ssh/p5-key` et le profil AWS `p5-lab`.
7. Valider le lab :

```bash
export AWS_PROFILE=p5-lab
./scripts/commands/setup.sh --check-only
./scripts/commands/pre-deployment-check.sh
```

Guide complet : [préparation de la VM](00-preparation-environnement.md).

## Étape 1 — Construire puis déployer l’application

1. Copier le starter dans `application/angular/`.
2. Construire l’artefact :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

3. Créer `terraform.tfvars` depuis l’exemple de l’exercice 1.
4. Exécuter `terraform init`, puis `terraform plan`.
5. Lire le plan avant `terraform apply`.
6. Reporter l’adresse EC2 dans l’inventaire Ansible.
7. Vérifier la connexion avec le module `ping`.
8. Exécuter `deploy.yml` et vérifier l’application sur le port 80.
9. Conserver les sorties et captures utiles.

Fiche : [Exercice 1](exercices/01-terraform-ansible.md).

## Étape 2 — Amazon OpenSearch

1. Déployer le domaine à partir de `terraform/exercice-2/`.
2. Importer l’échantillon NGINX.
3. Créer le motif d’index et vérifier les champs dans Discover.
4. Construire manuellement les trois visualisations imposées.
5. Capturer le dashboard complet et les trois graphiques.
6. Détruire OpenSearch après les preuves.

Fiche : [Exercice 2](exercices/02-elk-opensearch.md).

## Étape 3 — HAProxy

1. Conserver l’infrastructure réseau de l’exercice 1.
2. Déployer deux backends EC2 et une EC2 HAProxy.
3. Configurer `roundrobin` et les health checks.
4. Vérifier l’alternance des backends.
5. Arrêter un backend et contrôler la continuité du service.
6. Le redémarrer et vérifier sa réintégration.
7. Conserver `haproxy.cfg` et les preuves avant, pendant et après la panne.

Fiche : [Exercice 3](exercices/03-haproxy.md).

## Finalisation — Livrables et nettoyage

```bash
./scripts/commands/prepare-livrables.sh
./scripts/commands/destroy-aws.sh
```

La destruction s’effectue dans l’ordre 3 → 2 → 1. Vérifier ensuite EC2,
OpenSearch, les volumes et les adresses dans la console AWS. Ne jamais supprimer
les états Terraform avant `destroy`.
