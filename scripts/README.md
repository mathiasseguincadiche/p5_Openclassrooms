# Scripts du projet P5

Le point d'entrée opérateur est :

```bash
bash scripts/commands/p5.sh
```

Le centre de commande orchestre les scripts spécialisés, Terraform et Ansible. Il ne crée pas une seconde implémentation du projet.

Toutes les commandes P5 sont exécutées **dans la VM Ubuntu Server 26.04 `ubuntu-devops`**. La création et l'administration de cette VM restent dans le dépôt séparé `mathiasseguincadiche/Ubuntu-desktops-custom`.

## Menu principal

```text
DÉMARRER / REPRENDRE
 1  Inspecter ma situation actuelle
 2  Préparer / configurer le lab P5 dans la VM
 3  Vérifier si je suis prêt à déployer

EXERCICES
 4  Exercice 1 — Terraform + Ansible + Angular/NGINX
 5  Exercice 2 — Amazon OpenSearch + logs
 6  Exercice 3 — HAProxy + haute disponibilité

PARCOURS COMPLET
 7  Exécuter le projet complet de A à Z
 8  Reprendre un projet déjà commencé

VALIDATION / SOUTENANCE
 9  Vérifier les preuves et livrables
10  Diagnostic complet
11  Consulter les journaux

AIDE
12  Que dois-je faire maintenant ?
13  Afficher la documentation / Runbook
14  Afficher l'aide des commandes

MAINTENANCE
15  Nettoyer les ressources AWS

 0  Quitter
```

Documentation détaillée : [Centre de commande](../docs/CENTRE_DE_COMMANDE.md).

## Commandes CLI

| Commande | Rôle |
| --- | --- |
| `p5.sh inspect` | observer l'état réel P5 dans la VM sans mutation |
| `p5.sh prepare` | aligner le runtime P5 dans `ubuntu-devops`, AWS, les `tfvars` et les garde-fous |
| `p5.sh status` | vérifier la préparation |
| `p5.sh ex1` | Terraform + Ansible + Angular/NGINX |
| `p5.sh ex2` | Amazon OpenSearch + données |
| `p5.sh ex3` | HAProxy + test de résilience |
| `p5.sh all` | `prepare → ex1 → ex2 → ex3 → diagnostics` |
| `p5.sh diagnostics` | collecter les diagnostics et l'état des preuves |
| `p5.sh finalize` | contrôler les livrables |
| `p5.sh logs` | consulter les journaux |
| `p5.sh guide` | choisir le prochain parcours |
| `p5.sh docs` | afficher la carte documentaire |
| `p5.sh cleanup` | nettoyer les ressources P5 puis auditer AWS |

## Parcours complet

```bash
bash scripts/commands/p5.sh all
```

`all` laisse les ressources en place pour la démonstration et les preuves. Le nettoyage reste une étape séparée.

Le mode `--yes` ne valide jamais à la place de l'opérateur le checkpoint OpenSearch Dashboards ni la confirmation finale de nettoyage.

## Principe de convergence

```text
inspecter → comparer → corriger uniquement le delta → vérifier → journaliser
```

Après une interruption :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

Ne jamais supprimer un `terraform.tfstate` pour forcer une reprise.

## Runtime P5 dans la VM Ubuntu

Contrôle du runtime :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Alignement des seuls écarts nécessaires au P5 :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap peut installer ou réaligner les dépendances nécessaires **dans `ubuntu-devops` uniquement**. Il ne gère ni le HOST, ni KVM/libvirt, ni le cycle de vie de la VM.

Le checkout opérationnel doit rester sur le filesystem Linux local de la VM, par exemple `~/labs/p5_Openclassrooms`.

## Scripts centraux

| Fichier | Responsabilité |
| --- | --- |
| `scripts/commands/p5.sh` | orchestration et menu opérateur |
| `scripts/lib/p5-runtime.sh` | confirmations, logs et runtime commun |
| `scripts/commands/inspect-state.sh` | observation P5 sans mutation |
| `scripts/commands/bootstrap-ubuntu-server.sh` | contrat logiciel P5 dans Ubuntu Server 26.04 |
| `scripts/commands/aws-auth.sh` | authentification AWS du lab |
| `scripts/commands/configure-lab.sh` | configuration locale du lab |
| `scripts/commands/generate-ansible-inventory.sh` | inventaire depuis Terraform |
| `scripts/commands/collect-diagnostics.sh` | diagnostic partageable |
| `scripts/commands/prepare-livrables.sh` | contrôle des livrables |
| `scripts/commands/destroy-aws.sh` | nettoyage ordonné `3 → 2 → 1` |
| `scripts/commands/check-aws-cleanup.sh` | audit final AWS |
| `scripts/tests/test-p5-orchestrator.sh` | contrat de l'orchestrateur sans AWS réel |

## Frontière de responsabilité

Le répertoire `scripts/` ne doit contenir aucune logique de provisioning KVM/libvirt pour `ubuntu-devops`.

La frontière d'intégration est décrite dans [`environment/vm-devops/README.md`](../environment/vm-devops/README.md).

## Logs et preuves

Les journaux opérateur sont sous `logs/<UTC>/`. Les preuves techniques restent séparées sous `proofs/runtime/`.

## Documentation opératoire

- [Runbook A à Z](../docs/RUNBOOK_EXECUTION_GUIDEE.md)
- [Guide de soutenance](../docs/05-soutenance.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [Validation, preuves et nettoyage](../docs/validation-preuves-nettoyage.md)
