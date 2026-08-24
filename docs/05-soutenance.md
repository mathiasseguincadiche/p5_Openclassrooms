# Préparer l'assessment — P5 OpenClassrooms

## Document canonique

Le conducteur officiel de présentation est :

[`RUNBOOK_SOUTENANCE.md`](RUNBOOK_SOUTENANCE.md)

Ce fichier ne duplique pas le scénario. Il fixe uniquement la méthode de préparation.

## Structure de l'assessment

La présentation doit être faite dans cet ordre :

```text
PARTIE A — PRÉSENTER
1. le projet
2. l'architecture globale
3. l'architecture Exercice 1
4. l'architecture Exercice 2
5. l'architecture Exercice 3

PARTIE B — DÉMONTRER
6. preuves Exercice 1
7. preuves Exercice 2
8. preuves Exercice 3
9. conclusion
```

Le principe est volontaire : **l'évaluateur comprend d'abord ce qui a été construit, puis il voit les preuves que cela fonctionne.**

![Architecture globale du P5](schemas/vue-ensemble.svg)

## Ce que l'évaluateur doit comprendre

### Exercice 1

```text
AWS us-east-1
└── VPC 10.0.0.0/16
    ├── subnet public 1 → EC2 p5-web t3.micro → NGINX + Angular
    └── subnet public 2 → réutilisé ensuite par l'exercice 3

Terraform crée l'infrastructure
Ansible configure l'EC2
NGINX sert Angular
```

### Exercice 2

```text
access.log NGINX + sample
→ parsing / typage
→ Amazon OpenSearch Service
→ trois visualisations + dashboard
```

Le domaine OpenSearch est un service managé AWS dans l'implémentation actuelle, pas une EC2 placée dans le VPC de l'exercice 1.

### Exercice 3

```text
VPC Exercice 1
├── subnet public 1
│   ├── p5-haproxy t3.micro
│   └── p5-hello-1 t3.micro
└── subnet public 2
    └── p5-hello-2 t3.micro

Internet → HAProxy → IP privées des deux backends
```

Le résultat à démontrer est : round-robin, panne d'un service, maintien du trafic, puis réintégration.

## Préparation avant l'oral

Avant l'arrivée de l'évaluateur, le lab doit déjà être actif et validé :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Préparer dans le navigateur :

```text
Angular
OpenSearch Dashboards
HAProxy
```

## Règle de démonstration

Pour chaque exercice :

```text
ATTENDU OPENCLASSROOMS
       ↓
SOURCE / CONFIGURATION
       ↓
PREUVE TERMINAL
       ↓
RÉSULTAT NAVIGATEUR
       ↓
CONCLUSION
```

Ne pas reconstruire l'infrastructure pendant l'assessment sauf demande explicite de l'évaluateur.

## À montrer absolument

| Exercice | Preuves minimales |
| --- | --- |
| Ex. 1 | Terraform outputs/state, Ansible ping, playbook sans erreur/idempotent, Angular dans le navigateur |
| Ex. 2 | domaine OpenSearch, données exploitables, donut, bytes/12h, top5/12h, dashboard complet |
| Ex. 3 | `haproxy.cfg`, alternance `Server name` / `Server address`, test de panne et réintégration |

## Après l'assessment

Une fois les preuves conservées :

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