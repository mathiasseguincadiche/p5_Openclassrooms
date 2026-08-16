# Documentation officielle du P5

Ce dossier est la documentation de référence du projet P5 OpenClassrooms.

Le dépôt met en œuvre trois exercices sur AWS et s'exécute en CLI depuis la VM Ubuntu Server
26.04 **`ubuntu-devops`**.

## Ordre de lecture

```text
1. comprendre le besoin
2. préparer l'environnement P5
3. observer l'état réel
4. exécuter les exercices
5. vérifier les résultats
6. conserver les preuves
7. préparer les livrables et la soutenance
8. fermer le lab AWS
```

## 1. Comprendre le projet

1. [`00-cadre-officiel.md`](00-cadre-officiel.md) — consignes et périmètre ;
2. [`architecture-et-flux.md`](architecture-et-flux.md) — architecture et dépendances ;
3. [`01-parcours-debutant.md`](01-parcours-debutant.md) — lecture pédagogique du parcours.

## 2. Préparer l'environnement

1. [`00-preparation-environnement.md`](00-preparation-environnement.md) — VM, checkout et runtime P5 ;
2. [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md) — identité, compte, réseau, budget et quotas ;
3. [`contrat-informations-requises.md`](contrat-informations-requises.md) — données nécessaires au moteur P5.

Contrat VM : [`../environment/vm-devops/README.md`](../environment/vm-devops/README.md).

## 3. Exécuter le projet

1. [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md) — procédure A à Z ;
2. [`CENTRE_DE_COMMANDE.md`](CENTRE_DE_COMMANDE.md) — référence de `p5.sh` ;
3. [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md) — infrastructure et déploiement ;
4. [`exercices/02-opensearch.md`](exercices/02-opensearch.md) — logs et observabilité ;
5. [`exercices/03-haproxy.md`](exercices/03-haproxy.md) — haute disponibilité et résilience.

## 4. Reprendre, diagnostiquer et prouver

1. [`convergence-et-reexecution.md`](convergence-et-reexecution.md) — reprise et idempotence ;
2. [`troubleshooting.md`](troubleshooting.md) — diagnostic par couche ;
3. [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md) — génération et limites des preuves automatiques ;
4. [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md) — validation et fermeture du lab ;
5. [`livrables/README.md`](livrables/README.md) — préparation des livrables.

## 5. Préparer la soutenance

[`05-soutenance.md`](05-soutenance.md) fournit l'ordre de démonstration, les commandes utiles,
les preuves à montrer et les points techniques à expliquer.

## Architecture synthétique

```text
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
```

Schéma : [`schemas/vue-ensemble.svg`](schemas/vue-ensemble.svg).

## Sources de vérité

| Domaine | Source |
| --- | --- |
| plateforme HOST/KVM/VM | `mathiasseguincadiche/Ubuntu-desktops-custom` |
| contrat VM utilisé par P5 | `environment/vm-devops/README.md` |
| versions du runtime P5 | `environment/versions.env` |
| orchestration | `scripts/commands/p5.sh` |
| logs et preuves runtime | `scripts/lib/p5-runtime.sh` |
| infrastructure AWS | `terraform/exercice-{1,2,3}/` |
| configuration serveur | `ansible/playbooks/deploy.yml` |
| application | `application/angular/` |
| non-régression | `scripts/tools/audit_non_regression.py` et `.github/workflows/` |

## Gouvernance et conformité

- [`02-correspondance-consignes-depot.md`](02-correspondance-consignes-depot.md) — consignes → implémentation → preuve ;
- [`03-audit-structurel.md`](03-audit-structurel.md) — règles structurelles ;
- [`04-audit-non-regression.md`](04-audit-non-regression.md) — contrat exécutable ;
- [`suivi/decisions-techniques.md`](suivi/decisions-techniques.md) — décisions techniques ;
- [`suivi/journal-de-session.md`](suivi/journal-de-session.md) — suivi des sessions.

## Invariants documentaires

- exactement trois exercices ;
- mode d'implémentation AWS ;
- exécution P5 dans `ubuntu-devops` ;
- préparation logicielle P5 dans la VM ;
- distinction entre CI et preuve AWS réelle ;
- dépendance exercice 1 → exercice 3 ;
- flux de logs exercice 1 → exercice 2 ;
- ordre de fermeture `3 → 2 → 1` ;
- conservation des `terraform.tfstate` pour la reprise ;
- aucune présentation de Kubernetes, Helm, Prometheus, Grafana ou Vault comme composant du P5.

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
