# P5 OpenClassrooms — Centre de commande V11

Ce document explique le **Control Center V11** du projet P5. Il ne remplace ni
Terraform, ni Ansible, ni les scripts spécialisés : il fournit une interface
humaine au-dessus de l'orchestrateur existant `scripts/commands/p5.sh`.

## 1. Principe fondamental

Le projet conserve une seule source de vérité d'exécution :

```text
scripts/commands/p5.sh
```

Le menu interactif et la CLI appellent exactement les mêmes fonctions métier :

```text
Control Center
      │
      ├── inspect ───────► run_inspect
      ├── prepare ───────► run_prepare
      ├── status ────────► run_status
      ├── ex1 ───────────► run_ex1
      ├── ex2 ───────────► run_ex2
      ├── ex3 ───────────► run_ex3
      ├── all ───────────► run_all
      ├── diagnostics ───► run_diagnostics
      ├── finalize ──────► run_finalize
      └── cleanup ───────► run_cleanup
```

Aucune deuxième logique Terraform/Ansible/AWS n'est maintenue dans le menu.

## 2. Lancer le Control Center

Dans Ubuntu WSL2 :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh
```

Équivalent explicite :

```bash
bash scripts/commands/p5.sh menu
```

## 3. Vue du menu

```text
P5 OPENCLASSROOMS — CONTROL CENTER V11

DÉMARRER / REPRENDRE
 1  Inspecter ma situation actuelle
 2  Préparer / configurer le lab P5
 3  Vérifier si je suis prêt à déployer

EXERCICES
 4  Exercice 1 — Terraform + Ansible + Angular/NGINX
 5  Exercice 2 — Amazon OpenSearch + logs
 6  Exercice 3 — HAProxy + haute disponibilité

PARCOURS COMPLET
 7  Exécuter le projet complet de A à Z
 8  Reprendre un projet déjà commencé

VALIDATION / SOUTENANCE
 9  Vérifier les preuves et livrables
10  Diagnostic complet
11  Consulter les journaux

AIDE
12  Que dois-je faire maintenant ?
13  Afficher la documentation / Runbook
14  Afficher l'aide des commandes

MAINTENANCE
15  Nettoyer les ressources AWS

 0  Quitter
```

## 4. Pourquoi le menu affiche les risques avant l'action

Avant chaque action opérationnelle, le Control Center affiche quatre informations :

```text
Mutation locale
Mutation AWS
Coût AWS
Commande CLI équivalente
```

Exemple d'observation :

```text
ACTION — OBSERVATION
Mutation locale : NON
Mutation AWS    : NON
Coût AWS        : NON
Commande CLI    : bash scripts/commands/p5.sh inspect
```

Exemple de déploiement :

```text
ACTION — DÉPLOIEMENT
Mutation locale : OUI
Mutation AWS    : OUI
Coût AWS        : OUI
Commande CLI    : bash scripts/commands/p5.sh ex1
```

Cette information est pédagogique. Elle **ne remplace jamais** les confirmations
fortes déjà présentes dans Terraform, les scripts AWS ou le nettoyage.

## 5. Tableau de décision rapide

| Besoin | Menu | CLI | AWS | Coût possible |
| --- | ---: | --- | --- | --- |
| Observer l'état | 1 | `p5.sh inspect` | non | non |
| Préparer le lab | 2 | `p5.sh prepare` | possible | possible |
| Vérifier la préparation | 3 | `p5.sh status` | non destructif | non |
| Exercice 1 | 4 | `p5.sh ex1` | oui | oui |
| Exercice 2 | 5 | `p5.sh ex2` | oui | oui |
| Exercice 3 | 6 | `p5.sh ex3` | oui | oui |
| Projet complet | 7 | `p5.sh all` | oui | oui |
| Reprendre | 8 | `p5.sh all` | seulement si delta | possible |
| Finaliser | 9 | `p5.sh finalize` | non | non |
| Diagnostic | 10 | `p5.sh diagnostics` | non | non |
| Logs | 11 | `p5.sh logs` | non | non |
| Assistant de parcours | 12 | `p5.sh guide` | non | non |
| Documentation | 13 | `p5.sh docs` | non | non |
| Aide CLI | 14 | `p5.sh help` | non | non |
| Nettoyage | 15 | `p5.sh cleanup` | destruction | arrête les coûts |

## 6. Option 1 — Inspecter ma situation actuelle

Commande :

```bash
bash scripts/commands/p5.sh inspect
```

### Objectif

Observer l'état réel avant toute modification.

### Ce que l'action vérifie

Selon les informations disponibles :

- outils du socle P5 ;
- configuration AWS locale ;
- état de session AWS ;
- clés SSH ;
- fichiers `terraform.tfvars` ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et journaux déjà présents.

### Mutation

```text
Locale : NON
AWS    : NON
```

C'est le premier choix recommandé lorsqu'on ne sait pas dans quel état se trouve
le projet.

## 7. Option 2 — Préparer / configurer le lab

Commande :

```bash
bash scripts/commands/p5.sh prepare
```

Cette étape :

1. inspecte l'état ;
2. vérifie le contrat outillage P5 ;
3. corrige uniquement les versions/outils manquants ou incompatibles ;
4. prépare l'authentification AWS ;
5. synchronise la configuration locale et les `terraform.tfvars` ;
6. vérifie/converge le garde-fou de budget ;
7. exécute les contrôles AWS Ready.

Le principe reste :

```text
inspecter
   ↓
comparer état réel ↔ état attendu
   ↓
aucun delta ? ──► aucune mutation
   ↓
delta réel
   ↓
confirmation
   ↓
corriger uniquement le delta
```

## 8. Option 3 — Vérifier si je suis prêt à déployer

Commande :

```bash
bash scripts/commands/p5.sh status
```

Cette action est destinée au contrôle. Elle ne lance pas de `terraform apply` et
ne crée pas volontairement de ressource AWS.

Elle est utile :

- avant un exercice ;
- après un redémarrage ;
- après une reconnexion AWS ;
- avant une démonstration ;
- après correction d'un problème.

## 9. Option 4 — Exercice 1

Commande :

```bash
bash scripts/commands/p5.sh ex1
```

Chaîne :

```text
Angular
   ↓
Terraform exercice 1
   ↓
EC2 + réseau
   ↓
inventaire Ansible généré depuis Terraform
   ↓
Ansible
   ↓
NGINX + Angular
   ↓
2e passage Ansible
   ↓
changed=0 / unreachable=0 / failed=0
   ↓
vérification HTTP
   ↓
collecte du vrai access.log NGINX
```

Le second passage Ansible doit prouver l'idempotence :

```text
changed=0
unreachable=0
failed=0
```

## 10. Option 5 — Exercice 2

Commande :

```bash
bash scripts/commands/p5.sh ex2
```

Le projet utilise **Amazon OpenSearch Service** pour l'exercice réel.

La chaîne :

```text
Terraform OpenSearch
   ↓
échantillon reproductible
   +
vrai access.log NGINX si disponible
   ↓
import
   ↓
mappings / agrégations
   ↓
OpenSearch Dashboards
   ↓
checkpoint humain + captures
```

Le Control Center ne valide jamais automatiquement les captures visuelles à la
place de l'opérateur.

## 11. Option 6 — Exercice 3

Commande :

```bash
bash scripts/commands/p5.sh ex3
```

La chaîne :

```text
Terraform
   ↓
HAProxy + deux backends
   ↓
round-robin
   ↓
prévisualisation du test de panne
   ↓
confirmation
   ↓
arrêt contrôlé d'un backend
   ↓
continuité du service
   ↓
réintégration
```

Le test de panne réel n'est pas déclenché sans la confirmation prévue par le
moteur existant.

## 12. Option 7 — Exécuter le projet complet

Commande :

```bash
bash scripts/commands/p5.sh all
```

Séquence :

```text
prepare
   ↓
ex1
   ↓
ex2
   ↓
ex3
   ↓
diagnostics
```

`all` **ne détruit jamais automatiquement AWS** à la fin.

## 13. Option 8 — Reprendre un projet déjà commencé

La reprise utilise la même commande convergente :

```bash
bash scripts/commands/p5.sh all
```

Pourquoi ? Parce que P5 inspecte l'état existant et Terraform recalcule le delta.
Une ressource déjà conforme n'a pas besoin d'être recréée.

Règle absolue :

```text
NE JAMAIS supprimer terraform.tfstate pour forcer une reprise
```

Après un redémarrage Windows :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

## 14. Option 9 — Vérifier les preuves et livrables

Commande :

```bash
bash scripts/commands/p5.sh finalize
```

Cette étape :

- collecte les diagnostics ;
- vérifie la structure des preuves ;
- contrôle strictement les livrables ;
- signale ce qui doit encore être complété.

Verdict cible :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## 15. Option 10 — Diagnostic complet

Commande :

```bash
bash scripts/commands/p5.sh diagnostics
```

Le diagnostic est maintenant exposé comme commande officielle du Control Center.
Il réutilise la fonction de diagnostics déjà utilisée par `all` et `finalize`.

Il peut écrire des journaux et preuves locales, mais ne détruit pas AWS.

En cas de problème :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis consulter :

```text
docs/troubleshooting.md
```

## 16. Option 11 — Journaux

Commande :

```bash
bash scripts/commands/p5.sh logs
```

Les logs sont séparés des preuves :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...

proofs/runtime/
└── preuves techniques produites par le projet
```

`logs/` répond à « qu'est-ce qui a été exécuté ? ».
`proofs/runtime/` répond à « quelle preuve technique ai-je obtenue ? ».

## 17. Option 12 — Que dois-je faire maintenant ?

Commande :

```bash
bash scripts/commands/p5.sh guide
```

L'assistant présente des scénarios simples :

- première exécution ;
- reprise ;
- vérification seule ;
- exercice 1, 2 ou 3 ;
- préparation soutenance ;
- diagnostic ;
- nettoyage.

Il **recommande des commandes**, mais ne déclenche pas silencieusement une
mutation AWS.

## 18. Option 13 — Documentation / Runbook

Commande :

```bash
bash scripts/commands/p5.sh docs
```

La carte documentaire distingue clairement :

| Situation | Document |
| --- | --- |
| Je débute | `docs/01-parcours-debutant.md` |
| Je veux exécuter | `docs/RUNBOOK_EXECUTION_GUIDEE.md` |
| Je veux utiliser le menu | `docs/CENTRE_DE_COMMANDE.md` |
| Je veux comprendre | `docs/architecture-et-flux.md` |
| Je suis bloqué | `docs/troubleshooting.md` |
| Je prépare la soutenance | `docs/validation-preuves-nettoyage.md` |
| Je cherche tout | `docs/README.md` |

## 19. Option 14 — Aide CLI

Commande :

```bash
bash scripts/commands/p5.sh help
```

La CLI reste utilisable indépendamment du menu. C'est important pour :

- les tests ;
- la CI ;
- la reproductibilité ;
- la documentation ;
- un opérateur expérimenté.

## 20. Option 15 — Nettoyer AWS

Commande :

```bash
bash scripts/commands/p5.sh cleanup
```

Cette action est destructive pour les ressources P5 encore suivies par Terraform.

Ordre :

```text
Exercice 3
   ↓
Exercice 2
   ↓
Exercice 1
   ↓
audit AWS global
```

La confirmation forte `DETRUIRE` du script de destruction reste obligatoire.

Verdict final cible :

```text
NETTOYAGE AWS COMPLET
```

## 21. Mode `--yes`

Exemple :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` automatise uniquement les confirmations automatisables.

Il ne contourne jamais :

- une preuve humaine OpenSearch Dashboards ;
- une validation de sécurité qui exige une saisie humaine ;
- la confirmation finale `DETRUIRE`.

## 22. Mode `--full-validation`

```bash
bash scripts/commands/p5.sh status --full-validation
```

Ce mode ajoute la validation locale complète incluant OpenSearch local. Il ne
transforme pas le conteneur local en environnement évalué : le vrai exercice 2
reste Amazon OpenSearch Service.

## 23. Résumé après une action du menu

Le Control Center affiche un résumé honnête :

```text
RÉSULTAT
[ OK ] <action> terminé sans erreur signalée.
Étape recommandée : ...
```

En cas d'échec :

```text
RÉSULTAT
[ AVERTISSEMENT ] <action> s'est arrêté avec le code <n>.
Consultez les logs, puis relancez inspect avant toute correction manuelle.
```

Le menu ne transforme jamais un code d'erreur en faux succès technique.

## 24. Parcours recommandés

### Première exécution

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh all
```

### Reprise

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

### Diagnostic

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

### Soutenance

```bash
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh finalize
```

### Fin du lab

```bash
bash scripts/commands/p5.sh cleanup
```

## 25. Ce que V11 ne change pas

V11 ne refond pas :

- les modules Terraform ;
- les playbooks Ansible ;
- l'application Angular ;
- Amazon OpenSearch ;
- HAProxy ;
- la logique de convergence ;
- la reprise Terraform ;
- le contrat `Windows_11_Pro_Custom` → P5 ;
- les confirmations de sécurité ;
- la stratégie de logs V10.

V11 est une couche d'ergonomie et de documentation au-dessus d'une base V10
conservée.

## 26. Source de vérité

En cas de différence entre un exemple documentaire et le code, la commande
suivante est la source d'exécution :

```text
scripts/commands/p5.sh
```

La CI teste le contrat de cet orchestrateur sans créer de ressource AWS.
