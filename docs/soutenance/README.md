# Soutenance P5 — runbooks mentor détaillés

Ce dossier complète [`../RUNBOOK_SOUTENANCE.md`](../RUNBOOK_SOUTENANCE.md), qui reste le **conducteur court (<20 minutes)** utilisé pendant la démonstration. Une version prête à imprimer ou à conserver hors ligne est disponible dans [`../RUNBOOK_SOUTENANCE.pdf`](../RUNBOOK_SOUTENANCE.pdf).

Les documents ci-dessous servent de **référence détaillée et pédagogique** pour préparer la session, réviser les architectures, comprendre le rôle des composants, connaître les commandes de preuve et anticiper les questions du mentor.

## Commencer ici

- [`../RUNBOOK_SOUTENANCE.md`](../RUNBOOK_SOUTENANCE.md) — conducteur LIVE de moins de 20 minutes ;
- [`../RUNBOOK_SOUTENANCE.pdf`](../RUNBOOK_SOUTENANCE.pdf) — version PDF du même conducteur, avec les schémas officiels HQ ;
- [`RUNBOOK_MENTOR_COMPLET_DETAILLE.md`](RUNBOOK_MENTOR_COMPLET_DETAILLE.md) — version intégrale regroupant les trois exercices ;
- [`01-exercice-1-detaille.md`](01-exercice-1-detaille.md) — Terraform + Ansible + NGINX + Angular ;
- [`02-exercice-2-detaille.md`](02-exercice-2-detaille.md) — logs NGINX + Amazon OpenSearch + OpenSearch Dashboards ;
- [`03-exercice-3-detaille.md`](03-exercice-3-detaille.md) — HAProxy + round-robin + health checks + failover.

## Schémas détaillés

- [`../schemas/soutenance/exercice-1-detaille.svg`](../schemas/soutenance/exercice-1-detaille.svg)
- [`../schemas/soutenance/exercice-2-detaille.svg`](../schemas/soutenance/exercice-2-detaille.svg)
- [`../schemas/soutenance/exercice-3-detaille.svg`](../schemas/soutenance/exercice-3-detaille.svg)

## Principe d'utilisation

```text
RUNBOOK_MENTOR_COMPLET_DETAILLE.md
= apprendre, comprendre et préparer

RUNBOOK_SOUTENANCE.md
= dérouler la démonstration le jour J

RUNBOOK_SOUTENANCE.pdf
= même conducteur, prêt à imprimer / consulter hors ligne
```

Les commandes sont exécutées dans **WSL2 Ubuntu 26.04**. Les preuves visuelles HTTP sont ouvertes dans le **navigateur Windows 11** : Angular, OpenSearch Dashboards et le service derrière HAProxy.
