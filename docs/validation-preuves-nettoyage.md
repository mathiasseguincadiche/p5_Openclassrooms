# Validation, preuves, publication et nettoyage

Ce document décrit le cycle de validation du projet, depuis les contrôles locaux
jusqu'à la fermeture complète du lab AWS.

Le principe central est de ne pas confondre :

1. un dépôt cohérent ;
2. une VM prête ;
3. un compte AWS prêt ;
4. un exercice réellement exécuté ;
5. des preuves réellement capturées ;
6. un nettoyage AWS réellement terminé.

## Parcours recommandé

Les commandes principales sont :

```bash
bash scripts/commands/p5.sh status --full-validation
bash scripts/commands/p5.sh all
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Elles correspondent respectivement à :

```text
validation locale et préparation
        ↓
déploiement et preuves techniques
        ↓
contrôle strict des livrables
        ↓
destruction et audit AWS final
```

## Les niveaux de validation

| Niveau | Contrôle | Garantit | Ne garantit pas |
| --- | --- | --- | --- |
| Dépôt | `validate.sh` / CI | cohérence, syntaxe, intégrations locales | compte AWS prêt |
| Orchestrateur | `test-p5-orchestrator.sh` | séquencement et garde-fous sans AWS | vrai `apply` AWS |
| VM | `setup.sh --check-only` | outils, versions, structure | quotas/permissions AWS |
| AWS | `check-aws-readiness.sh` | identité, région, IP, quotas, budget | futur `apply` réussi |
| Pré-déploiement | `pre-deployment-check.sh` | VM + dépôt + tfvars + AWS Ready | validation humaine du plan |
| Exercice | `p5.sh ex1/ex2/ex3` | scénario technique exécuté | qualité des captures humaines |
| Finalisation | `p5.sh finalize` | livrables complets selon le contrat | destruction AWS |
| Nettoyage | `p5.sh cleanup` | destruction ordonnée + audit | absence de coût hors périmètre P5 |

Un `terraform apply` reste précédé de l'affichage du plan.

## Validation locale

Commande recommandée :

```bash
bash scripts/commands/p5.sh status --full-validation
```

Équivalent spécialisé :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

La validation locale couvre notamment :

- périmètre du dépôt ;
- audit de non-régression ;
- Bash/ShellCheck ;
- JSON/YAML/Markdown ;
- Angular, TypeScript et dépendances ;
- vrai build Angular derrière NGINX ;
- OpenSearch local, Bulk et agrégations ;
- HAProxy local, round-robin, panne et reprise ;
- Terraform ;
- Ansible ;
- structure des livrables ;
- secrets.

Elle est non destructive vis-à-vis d'AWS.

## Test du centre de commande

La CI exécute également :

```bash
bash scripts/tests/test-p5-orchestrator.sh
```

Ce test utilise des commandes factices et **ne crée aucune ressource AWS**. Il
vérifie notamment :

- aide et sous-commandes ;
- exécution du statut ;
- séquence de l'exercice 1 ;
- preuve d'idempotence Ansible ;
- séquence HAProxy ;
- appel des scripts spécialisés ;
- impossibilité pour `--yes` de contourner le checkpoint manuel OpenSearch.

Ce test renforce le contrat de l'orchestrateur mais ne remplace pas le premier
run réel AWS.

## Préparation VM et AWS

La commande :

```bash
bash scripts/commands/p5.sh prepare
```

prend en charge la préparation locale et les contrôles AWS.

Elle peut :

- proposer le bootstrap de la VM ;
- configurer ou utiliser un profil AWS ;
- relancer une session SSO ;
- refuser l'identité root ;
- détecter l'IPv4 publique ;
- créer la clé SSH du lab ;
- générer les tfvars ;
- préparer le budget ;
- lancer AWS Ready et le précontrôle.

Les confirmations root MFA, absence de clés root, politique IAM et contacts de
facturation restent humaines.

Conditions attendues :

```text
GO AWS
GO TERRAFORM
```

## Règle de mutation

### Non destructif

Exemples :

```bash
bash scripts/commands/p5.sh status
./scripts/commands/verify-opensearch-data.sh
python3 scripts/tools/audit_secrets.py
```

### Mutation confirmée

`p5.sh` affiche les plans Terraform avant `apply`. `--yes` peut confirmer les
mutations automatisables mais ne valide pas une preuve humaine.

Les scripts spécialisés conservent également leurs modes aperçu/`--apply` pour :

- budget ;
- import OpenSearch ;
- failover HAProxy.

### Destruction protégée

```bash
bash scripts/commands/p5.sh cleanup
```

appelle `destroy-aws.sh`, qui exige la saisie exacte :

```text
DETRUIRE
```

## Preuves de l'exercice 1

Le parcours automatisé produit ou vérifie :

- plan et apply Terraform ;
- ping Ansible ;
- premier déploiement ;
- seconde exécution Ansible ;
- `changed=0` ;
- `unreachable=0` ;
- `failed=0` ;
- application Angular servie par NGINX ;
- fallback SPA et bundle ;
- trafic NGINX ;
- vrai `access.log` collecté.

Le log réel est écrit sous :

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

## Preuves de l'exercice 2

Le parcours importe :

1. le jeu de données versionné ;
2. le vrai log NGINX, lorsqu'il existe.

Le jeu versionné garantit les tranches temporelles nécessaires au dashboard. Le
vrai log démontre la chaîne NGINX → OpenSearch.

Le script de vérification contrôle :

- mappings ;
- volume de documents ;
- méthodes HTTP ;
- buckets de 12 h ;
- chemins ;
- agrégations.

Restent manuels :

- Discover ;
- donut des méthodes ;
- somme des octets par 12 h ;
- top 5 des URL par 12 h ;
- dashboard complet ;
- captures.

Le checkpoint exige la saisie exacte `OK` et n'est pas contourné par `--yes`.

## Preuves de l'exercice 3

Le parcours vérifie :

- trois EC2 créées par le module ;
- HAProxy accessible ;
- deux backends en round-robin ;
- panne réelle d'un backend ;
- continuité du service ;
- redémarrage ;
- retour des deux backends.

Le script de failover conserve un mécanisme de restauration en cas
d'interruption.

## Logs opérateur et preuves pédagogiques

Ils sont volontairement séparés.

### Logs opérateur

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Ils servent au diagnostic de l'exécution.

### Preuves pédagogiques

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Elles servent aux livrables.

Les deux emplacements sont ignorés par Git pour les données runtime.

## Diagnostic

Depuis l'orchestrateur :

```bash
bash scripts/commands/p5.sh logs
```

Diagnostic partageable :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Le collecteur produit un résumé, un journal complet local, une version nettoyée,
un manifeste et une archive partageable après relecture.

Le journal complet non filtré n'est pas ajouté à l'archive.

## Finalisation des livrables

Une fois les captures réelles insérées et anonymisées :

```bash
bash scripts/commands/p5.sh finalize
```

Cette commande :

1. collecte les diagnostics ;
2. contrôle la structure ;
3. lance le contrôle strict des trois livrables.

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Le contrôle strict échoue notamment si un fichier manque, si une section
obligatoire a disparu, si un marqueur de preuve reste présent ou si une signature
de secret est détectée.

## Publication

Tout contenu sous `proofs/runtime/` ou `logs/` est privé par défaut.

| État | Publication |
| --- | --- |
| log complet | non |
| preuve brute | non |
| diagnostic nettoyé | après relecture |
| capture anonymisée | oui si nécessaire |
| gabarit non complété | ce n'est pas une preuve |
| livrable final relu | oui selon le besoin |

Aucun masquage automatique ne remplace la relecture humaine.

## Nettoyage

Commande recommandée :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Cette règle existe parce que l'exercice 3 réutilise le réseau et la clé de
l'exercice 1.

L'audit final recherche notamment les ressources P5 restantes :

- EC2 ;
- volumes EBS ;
- interfaces réseau ;
- Elastic IP ;
- groupes de sécurité ;
- sous-réseaux ;
- routes ;
- Internet Gateway ;
- VPC ;
- paire de clés ;
- domaine OpenSearch.

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

Le budget reste volontairement actif après la destruction afin de signaler une
ressource oubliée.

## Ne jamais supprimer les états Terraform avant `destroy`

Les états permettent à Terraform de retrouver les ressources qu'il gère. Les
supprimer pour « repartir proprement » peut orpheliner des ressources payantes.

En cas d'interruption, relancer :

```bash
bash scripts/commands/p5.sh all
```

et laisser le mode reprise réévaluer le lab.

## Ce que signifie une CI verte

Une CI verte prouve :

- le contrat du dépôt ;
- les intégrations locales ;
- le contrat simulé de l'orchestrateur ;
- la qualité syntaxique et documentaire.

Elle ne prouve pas :

- que les credentials AWS de la VM sont valides ;
- que les quotas sont suffisants au moment du run ;
- qu'AWS ne rencontre aucune erreur de service ;
- que le déploiement complet a déjà été exécuté dans le compte réel.

La validation finale du système reste :

```bash
bash scripts/commands/p5.sh all
```

sur la VM réelle avec une session AWS valide.

## Checklist de fermeture

- [ ] CI verte ;
- [ ] `p5.sh all` exécuté sur AWS réel ;
- [ ] idempotence Ansible prouvée ;
- [ ] logs NGINX réels importés dans OpenSearch ;
- [ ] dashboard capturé ;
- [ ] panne/reprise HAProxy validée ;
- [ ] diagnostics relus ;
- [ ] livrables sans placeholder ;
- [ ] `p5.sh finalize` réussi ;
- [ ] `p5.sh cleanup` exécuté ;
- [ ] verdict `NETTOYAGE AWS COMPLET` ;
- [ ] budget AWS surveillé après la démonstration.

## Documents associés

- [Parcours complet](01-parcours-debutant.md)
- [Architecture](architecture-et-flux.md)
- [Exercice 1](exercices/01-terraform-ansible.md)
- [Exercice 2](exercices/02-elk-opensearch.md)
- [Exercice 3](exercices/03-haproxy.md)
- [Livrables](livrables/README.md)
- [Preuves runtime](../proofs/README.md)
- [Scripts](../scripts/README.md)
- [Sécurité](../SECURITY.md)
- [Troubleshooting](troubleshooting.md)
