# Documentation officielle du P5

Ce dossier est la source documentaire officielle du projet P5 OpenClassrooms.

Le `README.md` racine présente le projet. Ici, la documentation explique le fonctionnement, l'exécution, les preuves, les livrables et la préparation de la soutenance.

## Ordre de lecture

```text
1. comprendre le besoin
2. préparer l'environnement P5 dans la VM
3. observer l'état réel
4. exécuter les exercices
5. vérifier les résultats
6. conserver les preuves
7. préparer la soutenance et les livrables
8. fermer le lab proprement
```

Le **mode d'implémentation retenu dans ce dépôt est 100 % AWS**. Le P5 s'exécute en CLI dans la VM Ubuntu Server 26.04 `ubuntu-devops`. Le HOST Ubuntu, KVM/libvirt et le cycle de vie de cette VM appartiennent au dépôt séparé `mathiasseguincadiche/Ubuntu-desktops-custom`.

## Niveau 1 — Comprendre le projet

1. [`00-cadre-officiel.md`](00-cadre-officiel.md) — consignes, trois exercices et choix d'implémentation ;
2. [`architecture-et-flux.md`](architecture-et-flux.md) — architecture, responsabilités et dépendances ;
3. [`01-parcours-debutant.md`](01-parcours-debutant.md) — parcours pédagogique progressif.

## Niveau 2 — Préparer le lab

1. [`00-preparation-environnement.md`](00-preparation-environnement.md) — VM `ubuntu-devops`, checkout et qualification du runtime P5 ;
2. [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md) — identité, compte, réseau, budget, quotas et garde-fous ;
3. [`contrat-informations-requises.md`](contrat-informations-requises.md) — informations réellement nécessaires au moteur P5.

## Niveau 3 — Exécuter le projet

1. [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md) — procédure A à Z ;
2. [`CENTRE_DE_COMMANDE.md`](CENTRE_DE_COMMANDE.md) — référence de `p5.sh` ;
3. [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md) — Terraform, Ansible, NGINX et Angular ;
4. [`exercices/02-opensearch.md`](exercices/02-opensearch.md) — Amazon OpenSearch, logs NGINX et dashboard ;
5. [`exercices/03-haproxy.md`](exercices/03-haproxy.md) — HAProxy, round-robin, health checks, panne et reprise.

## Niveau 4 — Reprendre, diagnostiquer et prouver

1. [`convergence-et-reexecution.md`](convergence-et-reexecution.md) — reprise après interruption ;
2. [`troubleshooting.md`](troubleshooting.md) — diagnostic par couche ;
3. [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md) — logs, preuves et limites de l'automatisation ;
4. [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md) — validation des preuves et fermeture du lab ;
5. [`livrables/README.md`](livrables/README.md) — contenu attendu des livrables.

## Niveau 5 — Préparer la soutenance

[`05-soutenance.md`](05-soutenance.md) fournit l'ordre de démonstration, les commandes utiles, ce que chaque résultat prouve, les points à expliquer oralement, les erreurs à éviter et les questions techniques probables.

## Conformité et gouvernance

- [`02-correspondance-consignes-depot.md`](02-correspondance-consignes-depot.md) — consignes → implémentation → preuve ;
- [`03-audit-structurel.md`](03-audit-structurel.md) — règles structurelles ;
- [`04-audit-non-regression.md`](04-audit-non-regression.md) — contrat exécutable de non-régression ;
- [`suivi/decisions-techniques.md`](suivi/decisions-techniques.md) — décisions techniques ;
- [`suivi/journal-de-session.md`](suivi/journal-de-session.md) — suivi des sessions.

## Carte technique

```text
PLATEFORME AMONT
Ubuntu HOST + KVM/libvirt
             │
             ▼
VM ubuntu-devops / Ubuntu Server 26.04
             │
             ▼
       runtime P5 CLI
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
                               HAProxy + 2 backends
                                      │
                                      ▼
                              preuves / livrables
```

Schéma de référence : [`schemas/vue-ensemble.svg`](schemas/vue-ensemble.svg).

## Source de vérité technique

En cas de doute sur ce qu'une commande fait réellement :

- plateforme VM : dépôt séparé `mathiasseguincadiche/Ubuntu-desktops-custom` ;
- contrat d'intégration P5 : `environment/vm-devops/README.md` ;
- orchestration : `scripts/commands/p5.sh` ;
- runtime/logs/preuves : `scripts/lib/p5-runtime.sh` ;
- infrastructure : `terraform/exercice-{1,2,3}/` ;
- configuration : `ansible/playbooks/deploy.yml` ;
- application : `application/angular/` ;
- versions P5 : `environment/versions.env` ;
- non-régression : `scripts/tools/audit_non_regression.py` et `.github/workflows/`.

La documentation doit expliquer cette implémentation, jamais en créer une seconde.

## Navigation rapide

```bash
bash scripts/commands/p5.sh docs
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh inspect
```

## Invariants documentaires

- exactement trois exercices ;
- mode AWS clairement identifié ;
- exécution P5 dans `ubuntu-devops` ;
- HOST/KVM/cycle de vie VM hors périmètre du dépôt P5 ;
- préparation logicielle P5 conservée dans la VM ;
- aucune présentation de Kubernetes, Helm, Prometheus, Grafana ou Vault comme élément du P5 ;
- distinction entre CI et preuve AWS réelle ;
- dépendance exercice 1 → exercice 3 ;
- flux de logs exercice 1 → exercice 2 ;
- ordre de fermeture `3 → 2 → 1` ;
- aucune suppression de `terraform.tfstate` comme méthode de reprise.

Audit :

```bash
python3 scripts/tools/audit_non_regression.py
```
