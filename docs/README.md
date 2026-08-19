# Documentation officielle du P5

Ce dossier est le **portail documentaire de référence** du projet P5 OpenClassrooms.

La documentation est organisée par besoin : comprendre, préparer, exécuter, diagnostiquer, prouver et nettoyer. Elle est volontairement séparée en plusieurs types de documents afin de ne pas transformer le README racine ou le runbook en manuel monolithique.

![Architecture de référence du P5](schemas/vue-ensemble.svg)

## Choisir son point d'entrée

| Je veux… | Lire d'abord | Pourquoi |
| --- | --- | --- |
| découvrir le projet sans connaissances implicites | [`01-parcours-debutant.md`](01-parcours-debutant.md) | explique les concepts, les responsabilités et les dépendances avant les commandes |
| exécuter le projet de A à Z | [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md) | fournit l'ordre opératoire, les points d'arrêt et les critères de succès |
| savoir quelle procédure utiliser | [`runbooks/README.md`](runbooks/README.md) | oriente vers exécution, reprise, incident, preuves ou nettoyage |
| comprendre l'architecture | [`architecture-et-flux.md`](architecture-et-flux.md) | décrit les frontières, réseaux, flux de données et sources de vérité |
| comprendre `p5.sh` | [`CENTRE_DE_COMMANDE.md`](CENTRE_DE_COMMANDE.md) | référence les commandes, mutations et cas d'usage |
| reprendre après une interruption | [`convergence-et-reexecution.md`](convergence-et-reexecution.md) | explique state, delta, idempotence et reprise sûre |
| résoudre un incident | [`troubleshooting.md`](troubleshooting.md) | diagnostique par couche sans casser l'état |
| comprendre un terme DevOps/AWS | [`GLOSSAIRE.md`](GLOSSAIRE.md) | définit le vocabulaire dans le contexte exact du P5 |
| préparer les preuves | [`livrables/README.md`](livrables/README.md) | distingue preuve technique, preuve réelle et livrable publiable |
| préparer l'oral | [`05-soutenance.md`](05-soutenance.md) | organise la démonstration et l'explication technique |
| vérifier qu'un texte correspond encore au code | [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md) | relie chaque affirmation importante à sa source de vérité |

## Les quatre familles de documents

### 1. README — orientation

Le [`README.md`](../README.md) à la racine répond rapidement à :

- quel est le but du projet ?
- quels sont les trois exercices ?
- où s'exécute le lab ?
- comment commencer sans faire de mutation aveugle ?
- où trouver le bon niveau de détail ?

Il ne remplace ni les guides techniques ni les procédures d'exploitation.

### 2. Documentation pédagogique et technique — compréhension

Ces documents répondent surtout à **« pourquoi ? »** et **« comment cela fonctionne ? »**.

- [`00-cadre-officiel.md`](00-cadre-officiel.md) — cadre, consignes et périmètre ;
- [`01-parcours-debutant.md`](01-parcours-debutant.md) — modèle mental progressif ;
- [`architecture-et-flux.md`](architecture-et-flux.md) — architecture et responsabilités ;
- [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md) — exercice 1 en profondeur ;
- [`exercices/02-opensearch.md`](exercices/02-opensearch.md) — exercice 2 en profondeur ;
- [`exercices/03-haproxy.md`](exercices/03-haproxy.md) — exercice 3 en profondeur ;
- [`GLOSSAIRE.md`](GLOSSAIRE.md) — vocabulaire contextualisé.

### 3. Runbooks — action

Un runbook répond surtout à **« que dois-je faire maintenant, dans quel ordre, et comment vérifier que l'étape a réussi ? »**.

Le catalogue est [`runbooks/README.md`](runbooks/README.md). Il référence notamment :

- [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md) — exécution complète ;
- [`convergence-et-reexecution.md`](convergence-et-reexecution.md) — reprise et réexécution ;
- [`troubleshooting.md`](troubleshooting.md) — incident et diagnostic ;
- [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md) — finalisation et fermeture du lab.

Les guides d'exercice expliquent les concepts ; les runbooks imposent la séquence opératoire.

### 4. Contrats, audits et livrables — conformité

Ces documents expliquent **ce qui doit rester vrai** et **comment le prouver**.

- [`02-correspondance-consignes-depot.md`](02-correspondance-consignes-depot.md) — consignes → implémentation → preuves ;
- [`03-audit-structurel.md`](03-audit-structurel.md) — invariants structurels ;
- [`04-audit-non-regression.md`](04-audit-non-regression.md) — contrat exécutable ;
- [`contrat-informations-requises.md`](contrat-informations-requises.md) — entrées attendues ;
- [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md) — limites des preuves automatiques ;
- [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md) — documentation ↔ code ;
- [`CONVENTIONS_DOCUMENTAIRES.md`](CONVENTIONS_DOCUMENTAIRES.md) — règles de rédaction et de maintenance ;
- [`livrables/README.md`](livrables/README.md) — préparation de la remise.

## Parcours recommandé pour un débutant

```text
README racine
    ↓
01-parcours-debutant.md
    ↓
GLOSSAIRE.md au besoin
    ↓
00-preparation-environnement.md
    ↓
00b-preparation-compte-aws.md
    ↓
RUNBOOK_EXECUTION_GUIDEE.md
    ↓
exercices/01-terraform-ansible.md
    ↓
exercices/02-opensearch.md
    ↓
exercices/03-haproxy.md
    ↓
validation-preuves-nettoyage.md
    ↓
05-soutenance.md
```

Le principe est volontaire : **comprendre avant de muter**.

## Parcours recommandé pour une reprise

```text
inspect
  ↓
convergence-et-reexecution.md
  ↓
status
  ↓
exercice ciblé ou all
  ↓
diagnostics
```

Ne pas repartir d'une installation « propre » tant que l'état réel et les states Terraform n'ont pas été qualifiés.

## Préparer l'environnement

1. [`00-preparation-environnement.md`](00-preparation-environnement.md) — WSL2, checkout et runtime P5 ;
2. [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md) — identité, compte, réseau, budget et quotas ;
3. [`contrat-informations-requises.md`](contrat-informations-requises.md) — informations nécessaires au moteur P5.

Contrat WSL2 : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

Parcours visuel : [`schemas/etape-0.svg`](schemas/etape-0.svg).

## Exécuter les trois exercices

| Étape | Guide technique | Commande principale | Résultat attendu |
| --- | --- | --- | --- |
| exercice 1 | [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md) | `bash scripts/commands/p5.sh ex1` | Terraform convergé, Ansible idempotent, Angular servi par NGINX |
| exercice 2 | [`exercices/02-opensearch.md`](exercices/02-opensearch.md) | `bash scripts/commands/p5.sh ex2` | données vérifiées + checkpoint OpenSearch Dashboards |
| exercice 3 | [`exercices/03-haproxy.md`](exercices/03-haproxy.md) | `bash scripts/commands/p5.sh ex3` | round-robin + continuité pendant panne + réintégration |

## Reprendre, diagnostiquer et prouver

- [`convergence-et-reexecution.md`](convergence-et-reexecution.md) — reprise et idempotence ;
- [`troubleshooting.md`](troubleshooting.md) — diagnostic par couche ;
- [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md) — génération et limites des preuves automatiques ;
- [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md) — validation, livrables et fermeture du lab ;
- [`livrables/README.md`](livrables/README.md) — livrables de l'évaluation.

## Parcours visuel officiel

| Étape | Schéma | Idée à retenir |
| --- | --- | --- |
| architecture | [`vue-ensemble.svg`](schemas/vue-ensemble.svg) | `Ubuntu` sous WSL2 pilote trois exercices AWS liés |
| préparation | [`etape-0.svg`](schemas/etape-0.svg) | `inspect → prepare → status → GO TERRAFORM` |
| exercice 1 | [`exercice-1.svg`](schemas/exercice-1.svg) | Terraform crée ; Ansible configure et déploie |
| exercice 2 | [`exercice-2.svg`](schemas/exercice-2.svg) | sample + log réel → OpenSearch → checkpoint humain |
| exercice 3 | [`exercice-3.svg`](schemas/exercice-3.svg) | VPC Ex1 → HAProxy → panne contrôlée → reprise |
| fermeture | [`finalisation.svg`](schemas/finalisation/finalisation.svg) | preuves → livrables → destroy `3 → 2 → 1` → audit AWS |

Conventions graphiques : [`schemas/README.md`](schemas/README.md).

## Sources de vérité

Une documentation fiable ne doit jamais devenir une deuxième configuration concurrente.

| Domaine | Source de vérité technique |
| --- | --- |
| plateforme Windows/WSL2 | `mathiasseguincadiche/Windows_11_Pro_Custom` |
| contrat d'exécution P5 | `environment/wsl2/README.md` + scripts de contrôle |
| versions P5 | `environment/versions.env` |
| orchestration | `scripts/commands/p5.sh` |
| logs et preuves runtime | `scripts/lib/p5-runtime.sh` |
| infrastructure AWS | `terraform/exercice-{1,2,3}/` |
| configuration serveur | `ansible/playbooks/deploy.yml` |
| application | `application/angular/` |
| qualité et non-régression | `scripts/tools/audit_non_regression.py` + `.github/workflows/` |

La table complète et les déclencheurs de mise à jour sont dans [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md).

## Règles de lecture importantes

### Ubuntu 26.04 et Ubuntu 24.04 ne désignent pas la même machine

- **Ubuntu 26.04 / `resolute`** : distribution WSL2 locale qui exécute le plan de contrôle ;
- **Ubuntu 24.04 / `noble`** : AMI EC2 par défaut utilisée par Terraform pour les exercices 1 et 3.

Cette différence est normale et doit rester explicite dans la documentation.

### CI verte et preuve AWS réelle sont différentes

```text
CI VERTE
= dépôt cohérent et tests satisfaits

PREUVE AWS
= comportement réellement observé dans le lab
```

### Le state Terraform fait partie de la reprise

Ne pas supprimer un `terraform.tfstate` pour « repartir proprement » avant d'avoir compris quelles ressources il possède.

### `--yes` n'annule pas les checkpoints humains

Le mode automatique ne valide pas un dashboard OpenSearch, n'invente pas une valeur AWS et ne doit pas transformer la destruction finale en opération silencieuse.

## Gouvernance et conformité

- [`02-correspondance-consignes-depot.md`](02-correspondance-consignes-depot.md) — consignes → implémentation → preuve ;
- [`03-audit-structurel.md`](03-audit-structurel.md) — règles structurelles ;
- [`04-audit-non-regression.md`](04-audit-non-regression.md) — contrat exécutable ;
- [`suivi/decisions-techniques.md`](suivi/decisions-techniques.md) — décisions techniques ;
- [`suivi/journal-de-session.md`](suivi/journal-de-session.md) — suivi des sessions.

## Invariants documentaires

La documentation doit toujours conserver ces faits :

- exactement trois exercices ;
- réalisation AWS pour les trois exercices ;
- plan de contrôle exécuté dans la distribution WSL2 `Ubuntu` 26.04 ;
- EC2 Ubuntu 24.04 par défaut pour les exercices concernés ;
- distinction entre CI et preuve AWS réelle ;
- dépendance exercice 1 → exercice 3 ;
- flux de logs exercice 1 → exercice 2 ;
- ordre de fermeture `3 → 2 → 1` ;
- conservation des states Terraform pour la reprise ;
- absence de Kubernetes, Helm, Prometheus, Grafana ou Vault dans le périmètre P5.

Audit :

```bash
python3 scripts/tools/audit_non_regression.py
```

Navigation rapide :

```bash
bash scripts/commands/p5.sh docs
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh inspect
```
