# Documentation du projet P5

Cette documentation est organisée pour qu’une personne découvrant le dépôt
puisse répondre rapidement à cinq questions :

1. **Quel est le but du projet ?**
2. **Comment l’architecture est-elle construite ?**
3. **Dans quel ordre faut-il exécuter les étapes ?**
4. **Quelles preuves faut-il produire ?**
5. **Comment diagnostiquer et nettoyer correctement le lab ?**

Le parcours retenu pour cette implémentation est **100 % AWS**. La VM Ubuntu
Server sert de poste de contrôle DevOps ; les infrastructures évaluées sont
créées dans AWS.

## Par où commencer ?

### Je découvre le dépôt

Lire dans cet ordre :

1. [Cadre officiel et périmètre](00-cadre-officiel.md)
2. [Architecture technique et flux](architecture-et-flux.md)
3. [Parcours d’exécution de bout en bout](01-parcours-debutant.md)
4. [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)

### Je veux exécuter le projet

1. [Étape 0A — préparer la VM](00-preparation-environnement.md)
2. [Étape 0B — préparer AWS](00b-preparation-compte-aws.md)
3. [Exercice 1 — Terraform, Ansible et Angular](exercices/01-terraform-ansible.md)
4. [Exercice 2 — Amazon OpenSearch](exercices/02-elk-opensearch.md)
5. [Exercice 3 — HAProxy](exercices/03-haproxy.md)
6. [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)

### Je suis bloqué

Utiliser :

- [Troubleshooting](troubleshooting.md)
- [Scripts et commandes](../scripts/README.md)
- [Diagnostic partageable](../proofs/README.md)

Commande de premier diagnostic :

```bash
bash scripts/commands/collect-diagnostics.sh
```

### Je prépare la remise

Lire :

- [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)
- [Livrables et preuves](livrables/README.md)
- [Validation, publication et nettoyage](validation-preuves-nettoyage.md)
- [Politique de sécurité](../SECURITY.md)

## Parcours global

```text
Étape 0A
Préparer la VM
    │
    ▼
Étape 0B
Sécuriser et valider AWS
    │
    ▼
GO AWS + GO TERRAFORM
    │
    ▼
Exercice 1
Terraform → EC2 → Ansible → NGINX → Angular
    │                         │
    │                         └─ logs NGINX réels
    │
    ├──────────────────────────────► Exercice 3
    │                                HAProxy → 2 backends
    │
    └──────────────────────────────► Exercice 2
                                     OpenSearch → Dashboard
    │
    ▼
Preuves et livrables
    │
    ▼
Destruction 3 → 2 → 1
    │
    ▼
NETTOYAGE AWS COMPLET
```

![Vue d’ensemble](schemas/vue-ensemble.svg)

## Sources de vérité

Pour éviter les contradictions, chaque sujet possède une référence principale.

| Sujet | Source de vérité |
| --- | --- |
| Périmètre OpenClassrooms et choix AWS | `docs/00-cadre-officiel.md` |
| Architecture et dépendances | `docs/architecture-et-flux.md` |
| Ordre d’exécution | `docs/01-parcours-debutant.md` |
| Configuration locale AWS | `environment/aws-readiness.env` local |
| Versions du lab | `environment/versions.env` |
| Infrastructure AWS | `terraform/exercice-*/` |
| Déploiement Angular/NGINX | `ansible/playbooks/deploy.yml` |
| Application | `application/angular/` |
| Commandes d’aide et validations | `scripts/` |
| Preuves techniques locales | `proofs/runtime/` local |
| Livrables | `docs/livrables/` |
| Sécurité | `SECURITY.md` |
| Décisions de conception | `docs/suivi/decisions-techniques.md` |

## Important : configuration Terraform

La configuration dépendant du compte n’est pas maintenue manuellement dans trois
fichiers différents.

Le flux attendu est :

```text
environment/aws-readiness.env
        │
        ▼
sync-terraform-tfvars.sh
        │
        ├─ exercice-1/terraform.tfvars
        ├─ exercice-2/terraform.tfvars
        └─ exercice-3/terraform.tfvars
```

Après toute modification du compte, de la région, de l’IP ou des tailles :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

## Documentation d’exécution

### Étape 0 — fondations

- [VM Ubuntu Server](00-preparation-environnement.md)
- [Compte AWS, sécurité, quotas et budget](00b-preparation-compte-aws.md)
- [Environnement de lab](../environment/README.md)
- [Garde-fous AWS](../aws/README.md)

### Exercice 1 — déploiement applicatif

- [Guide d’exercice](exercices/01-terraform-ansible.md)
- [Application](../application/README.md)
- [Projet Angular](../application/angular/README.md)
- [Ansible](../ansible/README.md)
- [Terraform](../terraform/README.md)

### Exercice 2 — observabilité

- [Guide d’exercice](exercices/02-elk-opensearch.md)
- [Référence OpenSearch](../terraform/exercice-2/opensearch/README.md)
- [Terraform](../terraform/README.md)

### Exercice 3 — disponibilité

- [Guide d’exercice](exercices/03-haproxy.md)
- [Architecture et dépendances](architecture-et-flux.md)
- [Scripts HAProxy](../scripts/README.md)

## Validation et exploitation

- [Validation, preuves, publication et nettoyage](validation-preuves-nettoyage.md)
- [Preuves runtime](../proofs/README.md)
- [Livrables](livrables/README.md)
- [Troubleshooting](troubleshooting.md)
- [Scripts](../scripts/README.md)
- [Sécurité](../SECURITY.md)

## Documentation de maintenance

Ces documents expliquent l’historique et protègent le dépôt contre les
régressions. Ils ne font pas partie du parcours obligatoire pour exécuter le lab.

- [Audit structurel](03-audit-structurel.md)
- [Audit de non-régression](04-audit-non-regression.md)
- [Décisions techniques](suivi/decisions-techniques.md)
- [Modèle de journal de session](suivi/journal-de-session.md)
- [Schémas pédagogiques](schemas/README.md)
- [Ressources pédagogiques](ressources/README.md)

## Règles documentaires

La documentation suit les principes suivants :

- une seule source de vérité par sujet ;
- les guides d’exercice décrivent l’exécution réelle ;
- les README de composants servent de référence technique locale ;
- les documents de suivi expliquent les décisions, pas les commandes à exécuter ;
- aucune preuve fictive n’est présentée comme une exécution réelle ;
- aucun secret ni fichier local sensible ne doit être publié ;
- les schémas expliquent les flux sans remplacer les procédures ;
- exactement trois guides existent sous `docs/exercices/`.

## Contrôle de cohérence documentaire

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

La CI contrôle également le Markdown, les liens, les schémas, les fichiers
sensibles et les capacités indispensables du dépôt.
