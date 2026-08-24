# Schémas de référence — assessment P5

Les schémas de ce dossier servent d'abord à **présenter l'architecture du projet pendant l'assessment**. Ils ne remplacent ni le code Terraform ni les explications du runbook.

Leur fonction est de répondre rapidement à quatre questions :

```text
quelles ressources existent ?
où sont-elles placées ?
comment communiquent-elles ?
quel résultat doit être démontré ?
```

## Ordre de présentation

| Schéma | Ce qu'il faut expliquer |
| --- | --- |
| [Vue d'ensemble](vue-ensemble.svg) | les trois exercices et leurs dépendances |
| [Exercice 1](exercice-1.svg) | VPC, deux subnets, placement de `p5-web`, rôle de Terraform et Ansible |
| [Exercice 2](exercice-2.svg) | source des logs, pipeline d'import et domaine Amazon OpenSearch managé |
| [Exercice 3](exercice-3.svg) | placement de HAProxy et des deux backends, flux réseau et failover |
| [Étape 0](etape-0.svg) | préparation technique du lab, hors récit principal de l'oral |
| [Finalisation](finalisation/finalisation.svg) | preuves, destruction et audit après la démonstration |

## Vue globale

La vue globale doit permettre de dire simplement :

```text
Exercice 1
Infrastructure + déploiement
      │
      ├── access.log ─────► Exercice 2 : logs + OpenSearch
      │
      └── VPC + subnets ──► Exercice 3 : HAProxy + deux backends
```

L'environnement Windows/WSL2 n'appartient pas à ce schéma : il s'agit uniquement du poste depuis lequel les commandes sont exécutées.

## Exercice 1 — topologie à montrer

Le schéma doit faire apparaître clairement :

```text
AWS us-east-1
└── VPC 10.0.0.0/16
    ├── subnet public 1
    │   └── EC2 p5-web · t3.micro · Ubuntu 24.04
    │       └── NGINX + Angular
    └── subnet public 2
        └── aucune EC2 Ex. 1 ; réseau réutilisé Ex. 3
```

Il doit également distinguer :

```text
Terraform → crée l'infrastructure
Ansible   → configure p5-web via SSH
Navigateur → accède à NGINX/Angular via HTTP 80
```

## Exercice 2 — architecture à montrer

Amazon OpenSearch Service est un **service AWS managé** dans l'implémentation actuelle.

Le schéma ne doit donc pas dessiner artificiellement une EC2 OpenSearch dans le VPC de l'exercice 1.

Flux de référence :

```text
access.log NGINX ─┐
                  ├─► parsing / typage ─► Bulk API ─► Amazon OpenSearch ─► Dashboards
sample versionné ─┘
```

Configuration importante :

```text
OpenSearch 2.19
1 × t3.small.search
EBS gp3 · 10 Gio
HTTPS / TLS 1.2+
accès limité à l'IP d'administration /32
```

Le résultat visuel attendu reste : donut HTTP, octets par 12 h, top 5 URL par 12 h et dashboard complet.

## Exercice 3 — topologie à montrer

Le schéma doit rendre le placement des trois EC2 immédiatement compréhensible :

```text
VPC Exercice 1
├── subnet public 1
│   ├── p5-haproxy · t3.micro
│   └── p5-hello-1 · t3.micro
└── subnet public 2
    └── p5-hello-2 · t3.micro
```

Flux utilisateur :

```text
Internet → HAProxy:80 → IP privée backend 1:80
                    └→ IP privée backend 2:80
```

Le Security Group des backends n'autorise HTTP que depuis le Security Group HAProxy.

Le scénario de validation est :

```text
2 backends disponibles
→ panne d'un service
→ 1 backend continue
→ restauration
→ 2 backends disponibles
```

## Règles graphiques

Un schéma d'assessment doit être lisible à l'écran sans zoom excessif. Il doit donc :

- montrer le placement réel des ressources lorsque ce placement est important ;
- afficher les types d'instance utiles à l'explication ;
- distinguer VPC, subnets, service managé et flux Internet ;
- éviter les détails qui ne servent pas l'explication orale ;
- utiliser les mêmes noms que le code (`p5-web`, `p5-haproxy`, `p5-hello-1`, `p5-hello-2`) ;
- nommer les flux importants : HTTP public, SSH d'administration, IP privées backend ;
- rester compréhensible indépendamment des couleurs.

## Contrat technique SVG

Les six SVG restent :

- autonomes ;
- accessibles avec `title`, `desc`, `role="img"` et `aria-labelledby` ;
- horizontaux et adaptés à GitHub ;
- sans script ni ressource externe ;
- sans Mermaid ;
- sous les limites de poids et de complexité contrôlées par la CI.

Contrôle :

```bash
python3 scripts/tools/audit_non_regression.py --schemas-only
```

Le document canonique de présentation est [`../RUNBOOK_SOUTENANCE.md`](../RUNBOOK_SOUTENANCE.md).
