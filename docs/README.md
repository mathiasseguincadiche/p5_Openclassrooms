# Documentation officielle du P5

Ce dossier est la **source documentaire officielle** du projet P5 OpenClassrooms.

Le `README.md` à la racine présente le projet. Ici, la documentation explique **comment il fonctionne, comment l'exécuter, pourquoi chaque étape existe, comment lire les résultats, comment produire les preuves et comment nettoyer AWS sans perdre l'état Terraform**.

## Règle de lecture

Le projet doit toujours être compris dans cet ordre :

```text
1. comprendre le besoin
2. préparer l'environnement
3. observer l'état réel
4. exécuter l'exercice
5. vérifier le résultat
6. conserver les preuves
7. finaliser les livrables
8. nettoyer AWS
```

Le périmètre évalué est **AWS**. Windows 11 et WSL2 n'apparaissent dans cette documentation que lorsqu'ils sont nécessaires à l'exécution du projet depuis le poste de contrôle.

## Parcours conseillé si vous découvrez le dépôt

### Niveau 1 — Comprendre le projet

1. [`00-cadre-officiel.md`](00-cadre-officiel.md) — ce que demande OpenClassrooms, les trois exercices et le choix AWS du dépôt ;
2. [`architecture-et-flux.md`](architecture-et-flux.md) — architecture, responsabilité des outils et dépendances entre exercices ;
3. [`01-parcours-debutant.md`](01-parcours-debutant.md) — explication progressive du parcours complet avant de lancer des ressources payantes.

### Niveau 2 — Préparer le lab

4. [`00-preparation-environnement.md`](00-preparation-environnement.md) — ouvrir WSL2, placer le checkout sur le filesystem Linux et qualifier les outils ;
5. [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md) — authentification, compte autorisé, SSH `/32`, budget, quotas et garde-fous ;
6. [`contrat-informations-requises.md`](contrat-informations-requises.md) — comprendre les informations réellement nécessaires au moteur P5 et leur provenance.

### Niveau 3 — Exécuter le projet de A à Z

7. [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md) — procédure opératoire complète, commande par commande ;
8. [`CENTRE_DE_COMMANDE.md`](CENTRE_DE_COMMANDE.md) — référence des commandes `p5.sh` et de leur niveau de risque ;
9. [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md) — Terraform, AWS, Ansible, NGINX et Angular ;
10. [`exercices/02-elk-opensearch.md`](exercices/02-elk-opensearch.md) — Amazon OpenSearch, logs NGINX et dashboard ;
11. [`exercices/03-haproxy.md`](exercices/03-haproxy.md) — HAProxy, round-robin, health checks, panne et reprise.

### Niveau 4 — Reprendre, diagnostiquer et prouver

12. [`convergence-et-reexecution.md`](convergence-et-reexecution.md) — reprendre proprement après fermeture du terminal, reboot ou exécution partielle ;
13. [`troubleshooting.md`](troubleshooting.md) — diagnostic par couche, sans « réparer au hasard » ;
14. [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md) — logs, preuves par étape, manifeste et limites de l'automatisation ;
15. [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md) — transformer les sorties runtime en preuves publiables puis fermer le lab ;
16. [`livrables/README.md`](livrables/README.md) — contenu attendu pour chacun des trois livrables.

## Documentation de conformité et de gouvernance

Ces fichiers ne constituent **pas** le parcours d'exécution normal. Ils expliquent pourquoi le dépôt reste conforme au P5 et comment éviter les régressions documentaires ou techniques :

- [`02-correspondance-consignes-depot.md`](02-correspondance-consignes-depot.md) — matrice OpenClassrooms → implémentation → vérification → preuve ;
- [`03-audit-structurel.md`](03-audit-structurel.md) — règles structurelles du dépôt actuel ;
- [`04-audit-non-regression.md`](04-audit-non-regression.md) — contrat exécutable empêchant de supprimer une capacité indispensable ;
- [`suivi/decisions-techniques.md`](suivi/decisions-techniques.md) — décisions techniques et arbitrages ;
- [`suivi/journal-de-session.md`](suivi/journal-de-session.md) — suivi des sessions de travail.

Ces documents peuvent mentionner une référence de comparaison ou une décision passée uniquement lorsqu'elle est nécessaire à l'audit. Ils ne doivent jamais être confondus avec les instructions opérationnelles actuelles.

## Carte technique

```text
POSTE DE CONTRÔLE
Windows 11 + WSL2 + Ubuntu 26.04
             │
             ▼
scripts/commands/p5.sh
             │
     ┌───────┴────────┐
     ▼                │
EXERCICE 1            │
Terraform → AWS       │
Ansible → NGINX       │
Angular → EC2         │
     │                │
     ├── access.log ─────────► EXERCICE 2
     │                         Amazon OpenSearch
     │                         + Dashboards
     │
     └── VPC/subnets ────────► EXERCICE 3
                               HAProxy
                               + 2 backends
                                      │
                                      ▼
                         preuves / livrables
                                      │
                                      ▼
                         cleanup 3 → 2 → 1
```

Le schéma graphique de référence est [`schemas/vue-ensemble.svg`](schemas/vue-ensemble.svg).

## Source de vérité : code ou documentation ?

Les deux doivent rester cohérents, mais en cas de doute sur **ce qu'une commande fait réellement**, le code exécuté est la source technique :

- orchestration : `scripts/commands/p5.sh` ;
- runtime/logs/preuves : `scripts/lib/p5-runtime.sh` ;
- infrastructure : `terraform/exercice-{1,2,3}/` ;
- configuration : `ansible/playbooks/deploy.yml` ;
- application : `application/angular/` ;
- versions : `environment/versions.env` ;
- règles de non-régression : `scripts/tools/audit_non_regression.py` et `.github/workflows/`.

La documentation officielle doit expliquer ces fichiers, jamais inventer une seconde implémentation.

## Commandes de navigation rapide

Depuis la racine du dépôt :

```bash
bash scripts/commands/p5.sh docs
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh inspect
```

- `docs` rappelle la carte documentaire ;
- `guide` aide à choisir le prochain parcours ;
- `inspect` observe l'état avant toute correction.

## Ce qui doit rester vrai

La documentation est considérée comme cohérente lorsque :

- elle décrit exactement **trois exercices** ;
- elle ne transforme pas Windows/WSL2 en exercice évalué ;
- elle ne présente pas Kubernetes, Helm, Prometheus, Grafana ou Vault comme éléments du P5 ;
- elle respecte le choix AWS du dépôt ;
- elle distingue clairement CI locale et preuve AWS réelle ;
- elle explique la dépendance exercice 1 → exercice 3 ;
- elle explique le flux de logs exercice 1 → exercice 2 ;
- elle conserve l'ordre de nettoyage `3 → 2 → 1` ;
- elle ne demande jamais de supprimer un `terraform.tfstate` pour « repartir proprement » ;
- elle garde les secrets, états, inventaires et preuves brutes hors Git.

L'audit correspondant est exécuté par :

```bash
python3 scripts/tools/audit_non_regression.py
```
