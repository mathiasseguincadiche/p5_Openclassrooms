# Documentation du projet P5

Cette documentation décrit à la fois le **parcours automatisé recommandé** et les
procédures détaillées permettant de comprendre ou rejouer chaque étape
manuellement.

Le périmètre retenu est **100 % AWS**. La VM Ubuntu Server sert de poste de
contrôle ; les infrastructures évaluées sont créées dans AWS.

Le centre de commande applique un modèle de **convergence** : il observe l'état
réel avant de modifier quoi que ce soit, compare cet état à la cible puis ne
corrige que le delta. Voir
[Convergence et réexécution intelligente](convergence-et-reexecution.md).

## Exécution recommandée

Le point d'entrée principal du projet est :

```bash
bash scripts/commands/p5.sh
```

Pour observer l'état actuel sans aucune mutation :

```bash
bash scripts/commands/p5.sh inspect
```

Pour exécuter ou réexécuter le parcours technique complet :

```bash
bash scripts/commands/p5.sh all
```

Le centre de commande prend en charge :

1. inspection de l'état existant ;
2. convergence de la VM et du compte AWS ;
3. configuration locale, tfvars et budget ;
4. exercice 1 — Terraform, Ansible, Angular et NGINX ;
5. preuve d'idempotence Ansible ;
6. génération et collecte des logs NGINX réels ;
7. exercice 2 — OpenSearch, import reproductible et import des logs réels ;
8. checkpoint humain du dashboard ;
9. exercice 3 — HAProxy, round-robin, panne et reprise ;
10. diagnostics et contrôle de structure des livrables.

Deux niveaux de runbook sont disponibles :

- [01 — parcours d'exécution de bout en bout](01-parcours-debutant.md) : runbook principal et synthétique du projet ;
- [Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md) : version opératoire détaillée, à suivre écran par écran pendant la réalisation réelle du lab.

## Commandes principales

| Besoin | Commande |
| --- | --- |
| Menu | `bash scripts/commands/p5.sh` |
| Inspecter sans modifier | `bash scripts/commands/p5.sh inspect` |
| Préparer / converger | `bash scripts/commands/p5.sh prepare` |
| Vérifier l'état | `bash scripts/commands/p5.sh status` |
| Exercice 1 | `bash scripts/commands/p5.sh ex1` |
| Exercice 2 | `bash scripts/commands/p5.sh ex2` |
| Exercice 3 | `bash scripts/commands/p5.sh ex3` |
| Tout exécuter | `bash scripts/commands/p5.sh all` |
| Validation locale complète | `bash scripts/commands/p5.sh status --full-validation` |
| Finaliser | `bash scripts/commands/p5.sh finalize` |
| Voir les logs | `bash scripts/commands/p5.sh logs` |
| Nettoyer AWS | `bash scripts/commands/p5.sh cleanup` |

Le mode `--yes` ne contourne ni les validations de sécurité impossibles à prouver
par la CLI, ni le checkpoint du dashboard, ni la confirmation `DETRUIRE`.

## Principe de réexécution

Une seconde exécution de `p5.sh all` ne signifie pas « tout refaire ». Pour les
éléments persistants, la règle est :

```text
inspecter → comparer → corriger seulement le delta → vérifier → journaliser
```

Exemples :

- VM conforme : aucun paquet réinstallé ;
- session AWS valide : aucune reconnexion ;
- budget conforme : aucune mutation Budget ;
- tfvars identiques : aucune réécriture ;
- plan Terraform vide : aucun `apply` ;
- artefact Angular inchangé : pas de `npm ci` ni de build ;
- inventaire identique : aucune réécriture ;
- template/documents OpenSearch déjà conformes : PUT/Bulk ignorés ;
- état Terraform vide au nettoyage : `destroy` ignoré.

Les **tests fonctionnels**, eux, peuvent être rejoués afin de vérifier que l'état
actuel est réellement fonctionnel. Cela évite de retourner un faux `OK` fondé sur
une ancienne exécution.

Détails :
[Convergence et réexécution intelligente](convergence-et-reexecution.md).

## Parcours global

```text
Inspection de l'état réel
        │
        ▼
Étape 0A / 0B
VM + AWS + budget + tfvars
        │
        ▼
GO AWS + GO TERRAFORM
        │
        ▼
Exercice 1
Terraform → EC2 → Ansible → NGINX → Angular
        │                    │
        │                    ├─ seconde exécution → changed=0
        │                    └─ logs NGINX réels
        │
        ├──────────────────────────► Exercice 2
        │                            OpenSearch
        │                            ├─ jeu reproductible
        │                            ├─ logs NGINX réels
        │                            └─ dashboard manuel
        │
        └──────────────────────────► Exercice 3
                                     HAProxy → 2 backends
                                     round-robin → panne → reprise
        │
        ▼
Diagnostics + preuves + livrables
        │
        ▼
Destruction 3 → 2 → 1
        │
        ▼
NETTOYAGE AWS COMPLET
```

![Vue d'ensemble](schemas/vue-ensemble.svg)

## Par où commencer ?

### Je veux exécuter le projet

Lire :

1. [Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
2. [Convergence et réexécution intelligente](convergence-et-reexecution.md)
3. [Parcours automatisé et reprise](01-parcours-debutant.md)
4. [Préparation de la VM](00-preparation-environnement.md)
5. [Préparation du compte AWS](00b-preparation-compte-aws.md)
6. [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)

Puis lancer :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

### Je veux comprendre l'architecture

Lire :

1. [Cadre officiel et périmètre](00-cadre-officiel.md)
2. [Architecture technique et flux](architecture-et-flux.md)
3. [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)

### Je veux comprendre un exercice en détail

- [Exercice 1 — Terraform, Ansible, NGINX et Angular](exercices/01-terraform-ansible.md)
- [Exercice 2 — Logs NGINX et OpenSearch](exercices/02-elk-opensearch.md)
- [Exercice 3 — HAProxy](exercices/03-haproxy.md)

Ces guides conservent les commandes détaillées pour comprendre les mécanismes
sous-jacents et diagnostiquer une étape isolée.

### Je suis bloqué

Commencer par :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/collect-diagnostics.sh
```

Puis consulter :

- [Runbook d'exécution guidée A → Z — procédure en cas d'échec](RUNBOOK_EXECUTION_GUIDEE.md)
- [Troubleshooting](troubleshooting.md)
- [Scripts et commandes](../scripts/README.md)
- [Convention des preuves](../proofs/README.md)

### Je prépare la remise

Lire :

- [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)
- [Livrables et preuves](livrables/README.md)
- [Validation, publication et nettoyage](validation-preuves-nettoyage.md)
- [Politique de sécurité](../SECURITY.md)

Commande :

```bash
bash scripts/commands/p5.sh finalize
```

## Sources de vérité

| Sujet | Source de vérité |
| --- | --- |
| Point d'entrée opérateur | `scripts/commands/p5.sh` |
| Runbook principal | `docs/01-parcours-debutant.md` |
| Guide opérateur détaillé | `docs/RUNBOOK_EXECUTION_GUIDEE.md` |
| Modèle de convergence | `docs/convergence-et-reexecution.md` |
| Runtime et logs opérateur | `scripts/lib/p5-runtime.sh` |
| Ordre global | `docs/01-parcours-debutant.md` |
| Périmètre | `docs/00-cadre-officiel.md` |
| Architecture | `docs/architecture-et-flux.md` |
| Configuration locale AWS | `environment/aws-readiness.env` local |
| Versions | `environment/versions.env` |
| Infrastructure | `terraform/exercice-*/` |
| Déploiement Angular/NGINX | `ansible/playbooks/deploy.yml` |
| Application | `application/angular/` |
| Commandes spécialisées | `scripts/commands/` |
| Preuves techniques | `proofs/runtime/` local |
| Journaux d'exécution | `logs/` local |
| État local d'optimisation | `.p5/` local, ignoré |
| Livrables | `docs/livrables/` |
| Sécurité | `SECURITY.md` |
| Décisions | `docs/suivi/decisions-techniques.md` |

## Configuration Terraform

La configuration dépendant du compte est centralisée dans :

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

Le centre de commande appelle cette synchronisation automatiquement pendant
`prepare`. Il compare le contenu attendu au contenu existant avant toute écriture.
Pour un diagnostic manuel :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

## Validation

La validation locale standard peut être lancée via :

```bash
bash scripts/commands/p5.sh status
```

Avec OpenSearch local :

```bash
bash scripts/commands/p5.sh status --full-validation
```

Le contrat de réexécution est vérifié par :

```bash
bash scripts/tests/test-convergence-contract.sh
```

La CI contrôle également la syntaxe, les intégrations locales, l'orchestrateur,
Terraform, Ansible, Markdown, liens, secrets et non-régression.

Important : une CI verte prouve la cohérence du dépôt, **pas un déploiement réel
sur le compte AWS de l'opérateur**. Le test d'intégration final est l'exécution
réelle de `p5.sh all` sur la VM.

## Documentation de maintenance

Ces documents protègent le dépôt contre les régressions mais ne sont pas requis
pour lancer le lab :

- [Audit structurel](03-audit-structurel.md)
- [Audit de non-régression](04-audit-non-regression.md)
- [Décisions techniques](suivi/decisions-techniques.md)
- [Journal de session](suivi/journal-de-session.md)
- [Schémas](schemas/README.md)
- [Ressources](ressources/README.md)

## Règles documentaires

- `p5.sh` est la voie normale d'exécution ;
- `p5.sh inspect` est la voie normale d'observation sans mutation ;
- `docs/01-parcours-debutant.md` reste le runbook principal synthétique ;
- `docs/RUNBOOK_EXECUTION_GUIDEE.md` est le guide opérateur détaillé pour l'exécution réelle et le diagnostic ;
- les guides détaillés restent la référence pédagogique et de dépannage ;
- une seule source de vérité est conservée par sujet ;
- aucune preuve fictive n'est présentée comme une exécution réelle ;
- les fichiers locaux sensibles ne sont jamais versionnés ;
- les journaux opérateur et les preuves pédagogiques restent séparés ;
- les schémas expliquent les flux sans remplacer les procédures ;
- exactement trois guides existent sous `docs/exercices/`.

## Contrôle de cohérence documentaire

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```
