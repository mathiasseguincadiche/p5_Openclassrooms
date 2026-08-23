# Runbooks du P5 — catalogue des procédures opérationnelles

## Rôle de ce dossier

Ce portail aide à choisir **la bonne procédure pour la situation actuelle**.

Un runbook n'est pas un cours complet sur Terraform, Ansible ou AWS. Il sert à agir de manière ordonnée, avec des préconditions, des contrôles et des points d'arrêt explicites.

Pour apprendre les concepts avant d'agir, commencer par [`../01-parcours-debutant.md`](../01-parcours-debutant.md).

## Choisir le bon runbook

| Situation | Procédure | Première intention |
| --- | --- | --- |
| première réalisation complète du P5 | [`../RUNBOOK_EXECUTION_GUIDEE.md`](../RUNBOOK_EXECUTION_GUIDEE.md) | qualifier → préparer → exécuter → prouver → nettoyer |
| **préparation et démonstration de soutenance** | [`../RUNBOOK_SOUTENANCE.md`](../RUNBOOK_SOUTENANCE.md) | remettre le lab en service avant l'oral puis démontrer architecture → infrastructure → application → logs → proxy → résilience |
| reprise après fermeture/redémarrage/interruption | [`../convergence-et-reexecution.md`](../convergence-et-reexecution.md) | observer les states et recalculer le delta |
| commande inconnue ou choix de parcours | [`../CENTRE_DE_COMMANDE.md`](../CENTRE_DE_COMMANDE.md) | comprendre `p5.sh` et la mutation associée |
| incident ou résultat inattendu | [`../troubleshooting.md`](../troubleshooting.md) | diagnostiquer la couche en échec avant de corriger |
| préparation du compte et des garde-fous AWS | [`../00b-preparation-compte-aws.md`](../00b-preparation-compte-aws.md) | qualifier identité, région, IP `/32`, clé, quotas et budget |
| validation des preuves et fermeture du lab | [`../validation-preuves-nettoyage.md`](../validation-preuves-nettoyage.md) | conserver les preuves avant destruction puis auditer AWS |
| préparation des livrables | [`../livrables/README.md`](../livrables/README.md) | transformer les preuves réelles en remise exploitable |

## Parcours opératoire normal

```text
RUNBOOK_EXECUTION_GUIDEE
        ↓
Exercice 1
        ↓
Exercice 2
        ↓
Exercice 3
        ↓
validation / preuves
        ↓
cleanup 3 → 2 → 1
        ↓
NETTOYAGE AWS COMPLET
```

## Parcours de soutenance

Le runbook de soutenance est volontairement distinct du runbook d'exécution complet.

```text
AVANT L'ORAL
inspect
  ↓
prepare
  ↓
status → GO TERRAFORM
  ↓
ex1 → ex2 → ex3
  ↓
diagnostics + finalize
  ↓
lab AWS prêt et vérifié

PENDANT L'ORAL
architecture
  ↓
Terraform + outputs
  ↓
Ansible + idempotence
  ↓
Angular / NGINX
  ↓
access.log réel
  ↓
OpenSearch / Dashboards
  ↓
HAProxy round-robin
  ↓
panne contrôlée + reprise

APRÈS L'ORAL
cleanup 3 → 2 → 1
  ↓
NETTOYAGE AWS COMPLET
```

La reconstruction AWS est une **phase de préparation**, pas une démonstration à improviser devant le jury. La soutenance doit montrer un environnement déjà convergé et des preuves courtes, lisibles et reproductibles.

Référence : [`../RUNBOOK_SOUTENANCE.md`](../RUNBOOK_SOUTENANCE.md).

## Parcours en cas d'incident

```text
ne pas modifier au hasard
        ↓
p5.sh inspect
        ↓
p5.sh logs
        ↓
identifier la couche
        ↓
troubleshooting.md
        ↓
corriger la cause
        ↓
relancer la commande convergente
```

Une erreur Terraform ne doit pas être « corrigée » en modifiant Ansible. Une erreur réseau ne doit pas être contournée en injectant une IP inventée. Le diagnostic suit les couches du système.

## Parcours de reprise

```text
ouvrir Ubuntu sous WSL2
        ↓
revenir dans le checkout Linux
        ↓
p5.sh inspect
        ↓
qualifier states + outputs + preuves
        ↓
p5.sh status
        ↓
commande ciblée ou p5.sh all
```

Le principe central est la **convergence** : un lab existant n'est pas recréé simplement parce qu'une session a été interrompue.

## Parcours de fermeture

Avant toute destruction :

1. collecter les diagnostics ;
2. vérifier les preuves ;
3. vérifier les livrables ;
4. seulement ensuite lancer le nettoyage AWS.

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Ordre de destruction :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

## Structure attendue d'un runbook P5

Une procédure opérationnelle doit idéalement contenir :

### 1. Objectif

Ce que la procédure cherche à obtenir.

### 2. Quand l'utiliser

La situation qui déclenche le runbook.

### 3. Préconditions

Ce qui doit déjà être vrai avant de commencer.

### 4. Niveau de risque

Indiquer si la procédure :

- observe uniquement ;
- modifie le runtime local ;
- crée ou modifie AWS ;
- provoque une panne contrôlée ;
- détruit des ressources.

### 5. Étapes

Pour chaque étape :

```text
pourquoi
→ commande
→ résultat attendu
→ point d'arrêt
```

### 6. Definition of Done

Des critères observables permettent de décider si la procédure est réellement terminée.

### 7. Récupération

Lorsqu'elle est pertinente, la procédure explique quoi faire si une étape échoue ou si une mutation temporaire doit être restaurée.

### 8. Suite

Le document indique l'action logique suivante au lieu de laisser l'opérateur deviner.

## Règles communes aux runbooks

### Toujours commencer par l'état réel

La commande de référence en cas d'incertitude est :

```bash
bash scripts/commands/p5.sh inspect
```

### Ne pas supprimer un state pour simplifier un diagnostic

Un `terraform.tfstate` représente la propriété Terraform. Sa disparition peut compliquer le nettoyage et la récupération.

### Refuser une destruction inattendue

Si un plan Terraform propose une suppression non comprise :

```text
refuser
→ inspecter le state
→ relire le code et les variables
→ vérifier compte/région
→ recalculer le plan
```

### Utiliser les outputs comme références

Les IP, URL et endpoints nécessaires à l'exécution doivent provenir des outputs Terraform ou d'une autre source de vérité vérifiée.

### Ne pas automatiser un checkpoint humain fictif

Les visualisations OpenSearch Dashboards et leurs captures restent une validation réelle de l'opérateur.

### Annoncer le risque avant l'action

Les commandes AWS mutatrices, les tests de panne et le cleanup doivent être précédés de leur contexte et de leurs conséquences.

## Limite des runbooks

Les runbooks n'ont pas vocation à dupliquer :

- le glossaire ;
- l'architecture détaillée ;
- toutes les ressources Terraform ;
- toutes les tâches Ansible ;
- les explications de fond de chaque exercice.

Pour cela, utiliser :

- [`../GLOSSAIRE.md`](../GLOSSAIRE.md) ;
- [`../architecture-et-flux.md`](../architecture-et-flux.md) ;
- [`../exercices/01-terraform-ansible.md`](../exercices/01-terraform-ansible.md) ;
- [`../exercices/02-opensearch.md`](../exercices/02-opensearch.md) ;
- [`../exercices/03-haproxy.md`](../exercices/03-haproxy.md).

## Règles de maintenance

Les conventions communes sont décrites dans [`../CONVENTIONS_DOCUMENTAIRES.md`](../CONVENTIONS_DOCUMENTAIRES.md).

Lorsqu'une commande, un verdict, un output ou une dépendance change, utiliser la [`../MATRICE_TRACABILITE.md`](../MATRICE_TRACABILITE.md) pour identifier les runbooks impactés.
