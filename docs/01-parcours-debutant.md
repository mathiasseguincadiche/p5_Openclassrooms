# 01 — Comprendre et exécuter le P5 pas à pas

Ce document est le **guide pédagogique** du P5. Son rôle est d'expliquer ce que
vous faites, pourquoi vous le faites et ce que vous devez vérifier à chaque étape.

Pour une procédure opératoire compacte à exécuter dans l'ordre, utiliser le
[Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md).

## 1. Quel est le but du projet ?

Le P5 met en pratique quatre compétences DevOps :

1. créer une infrastructure avec Terraform ;
2. configurer et déployer avec Ansible ;
3. exploiter des logs avec OpenSearch ;
4. démontrer la haute disponibilité avec HAProxy.

Le choix technique de ce dépôt est simple : **les trois exercices sont réalisés
sur AWS**.

Le projet complet peut se résumer ainsi :

```text
créer l'infrastructure
        ↓
déployer une application
        ↓
observer ses logs
        ↓
tester sa disponibilité
        ↓
produire les preuves
        ↓
nettoyer AWS
```

## 2. Ce que le P5 n'est pas

Le projet n'est pas :

- un projet d'installation Windows ;
- un projet WSL2 ;
- un projet Kubernetes ;
- un projet Helm ;
- un projet de monitoring Prometheus/Grafana ;
- un exercice GitHub Actions.

Windows 11 + WSL2 + Ubuntu servent uniquement de **poste de contrôle** pour lancer
Terraform, Ansible, AWS CLI, Docker et les scripts du dépôt.

Si vous devez installer ou réparer cet environnement, utilisez :
[Préparation de l'environnement](00-preparation-environnement.md).

## 3. Les trois exercices et leur relation

```text
EXERCICE 1
Terraform + Ansible
      │
      ├── produit l'application et son access.log ──► EXERCICE 2
      │                                               OpenSearch
      │
      └── fournit VPC + subnets + clé EC2 ──────────► EXERCICE 3
                                                      HAProxy
```

Cette relation explique deux règles importantes :

- les logs réels de l'exercice 1 peuvent enrichir l'exercice 2 ;
- l'exercice 1 ne doit pas être détruit avant la fin de l'exercice 3.

## 4. Avant de commencer

L'environnement de contrôle doit déjà être opérationnel.

Dans Ubuntu, le dépôt doit être placé dans le filesystem Linux :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Ne travaillez pas sous `/mnt/c` ou `/mnt/d` pour le checkout principal du P5.

Vérifiez ensuite le contrat spécifique au projet sans modifier la machine :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Si un outil ou une version spécifique au P5 manque réellement :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap doit corriger uniquement le delta nécessaire au P5.

## 5. Commencer par observer

Avant toute création AWS :

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande est volontairement non destructive. Elle permet de connaître
l'état réel :

- outils disponibles ;
- configuration AWS locale ;
- session AWS ;
- clé SSH ;
- `terraform.tfvars` ;
- états Terraform existants ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et journaux déjà présents.

L'idée est importante : **on n'applique pas une correction avant d'avoir observé
le problème**.

## 6. Préparer AWS

Commande :

```bash
bash scripts/commands/p5.sh prepare
```

Cette phase prépare les éléments nécessaires au lab :

- profil et identité AWS ;
- région ;
- compte AWS attendu ;
- refus du compte root pour le parcours normal ;
- IPv4 publique d'administration en `/32` ;
- clé SSH ;
- budget ;
- synchronisation des trois `terraform.tfvars` ;
- contrôles avant déploiement.

Les deux portes de validation à retenir sont :

```text
GO AWS
GO TERRAFORM
```

Si l'une de ces portes n'est pas atteinte, il faut corriger la cause signalée
avant de déployer.

Guide détaillé :
[Préparer le compte AWS](00b-preparation-compte-aws.md).

## 7. Exercice 1 — comprendre Terraform et Ansible

Commande :

```bash
bash scripts/commands/p5.sh ex1
```

### Ce que Terraform fait

Terraform décrit l'état attendu de l'infrastructure :

```text
VPC 10.0.0.0/16
├── 2 subnets publics
├── Internet Gateway
├── table de routage
├── Security Group
├── paire de clés
└── EC2 Ubuntu
```

L'orchestrateur lance un plan avant toute application.

```text
plan vide
   ↓
aucun apply

plan avec delta
   ↓
affichage
   ↓
confirmation
   ↓
apply du plan sauvegardé
   ↓
nouveau plan de contrôle
```

C'est le cœur de la convergence Terraform du projet.

### Ce qu'Ansible fait

Une fois l'EC2 disponible :

```text
inventaire
   ↓
connexion SSH
   ↓
Ansible
   ↓
NGINX
   ↓
application Angular
```

Le playbook est rejoué pour prouver l'idempotence.

Résultat attendu :

```text
changed=0
unreachable=0
failed=0
```

Cela signifie que la seconde exécution trouve déjà la cible conforme et n'a plus
besoin de la modifier.

### Pourquoi collecter `access.log` ?

NGINX génère de vrais logs HTTP lorsque l'application reçoit du trafic.
Ces logs deviennent une source réaliste pour l'exercice 2.

Guide détaillé :
[Exercice 1 — Terraform + Ansible](exercices/01-terraform-ansible.md).

## 8. Exercice 2 — comprendre OpenSearch

Commande :

```bash
bash scripts/commands/p5.sh ex2
```

Le principe est :

```text
logs NGINX
    ↓
préparation des documents
    ↓
Bulk API
    ↓
index OpenSearch
    ↓
agrégations
    ↓
visualisations Dashboards
```

Le dépôt peut utiliser :

1. un échantillon reproductible versionné ;
2. le vrai `access.log` récupéré après l'exercice 1.

### Ce qui est automatisé

Le dépôt automatise notamment :

- la convergence du domaine Amazon OpenSearch ;
- la préparation des documents ;
- l'import Bulk ;
- le contrôle des mappings ;
- le comptage ;
- les agrégations attendues.

### Ce qui reste humain

Les visualisations et leurs captures restent manuelles. Ce n'est pas un manque
d'automatisation : cette étape sert à montrer que l'opérateur comprend les données
et sait construire le dashboard attendu.

Guide détaillé :
[Exercice 2 — OpenSearch](exercices/02-elk-opensearch.md).

## 9. Exercice 3 — comprendre HAProxy

Commande :

```bash
bash scripts/commands/p5.sh ex3
```

L'exercice 3 utilise :

```text
HAProxy
  │
  ├── backend 1 → Docker → nginxdemos/hello
  └── backend 2 → Docker → nginxdemos/hello
```

HAProxy fonctionne en `roundrobin` et effectue des health checks HTTP.

Le test doit montrer trois états :

### État normal

Les deux backends répondent.

### Panne contrôlée

Un backend est arrêté. HAProxy doit continuer à servir le trafic avec l'autre.

### Reprise

Le backend est redémarré et doit réintégrer le pool après les health checks.

Cette démonstration est plus importante que la simple présence d'un fichier
`haproxy.cfg` : elle prouve le comportement réel de la solution.

Guide détaillé :
[Exercice 3 — HAProxy](exercices/03-haproxy.md).

## 10. Exécuter tout le parcours

Lorsque vous avez compris les étapes :

```bash
bash scripts/commands/p5.sh all
```

Le parcours est :

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

Le mode `all` ne détruit pas automatiquement AWS.

Option :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` automatise uniquement les confirmations automatisables. Il ne contourne
pas les checkpoints humains ou la destruction finale.

## 11. Utiliser le menu interactif

Pour ne pas mémoriser toutes les commandes :

```bash
bash scripts/commands/p5.sh
```

Le Control Center V11 permet notamment de :

- inspecter ;
- préparer ;
- lancer un exercice ;
- reprendre un lab ;
- diagnostiquer ;
- vérifier les preuves ;
- ouvrir la documentation ;
- nettoyer AWS.

Avant les actions importantes, il indique si une mutation locale, une mutation
AWS ou un coût AWS est possible.

Guide : [Centre de commande V11](CENTRE_DE_COMMANDE.md).

## 12. Comprendre les preuves

Trois notions ne doivent pas être confondues.

### Implémentation

Exemple : `terraform/exercice-1/main.tf` existe dans Git.

Cela prouve que le code existe.

### Contrôle automatisé

Exemple : la CI exécute `terraform validate`.

Cela prouve que le code respecte certains contrats.

### Preuve réelle

Exemple : l'EC2 a réellement été créée, Angular répond, OpenSearch contient les
documents ou HAProxy a réellement continué pendant la panne.

Cela doit provenir de l'exécution du lab.

Les preuves runtime sont stockées localement sous :

```text
proofs/runtime/
```

La carte exacte est disponible dans :
[Correspondance consignes → implémentation → preuve](02-correspondance-consignes-depot.md).

## 13. Reprendre après une interruption

Après fermeture du terminal ou redémarrage :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

Terraform relit l'état connu et compare avec AWS.

Ne supprimez jamais un `terraform.tfstate` pour tenter de « repartir proprement »
tant que les ressources AWS correspondantes existent.

## 14. Diagnostiquer au lieu de bricoler

En cas de problème :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis lire [Troubleshooting](troubleshooting.md).

Méthode recommandée :

```text
observer
   ↓
identifier le delta
   ↓
corriger la cause
   ↓
relancer la même commande
```

Évitez les suppressions improvisées d'états, de fichiers ou de ressources AWS.

## 15. Finaliser pour la soutenance

Commande :

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Cette étape ne remplace pas la relecture humaine des captures et livrables.

Guide :
[Validation, preuves et nettoyage](validation-preuves-nettoyage.md).

## 16. Nettoyer AWS

Lorsque le lab est terminé :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Pourquoi ? Parce que l'exercice 3 réutilise le réseau de l'exercice 1.

La confirmation :

```text
DETRUIRE
```

reste obligatoire.

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

## 17. Documents à lire ensuite

Pour approfondir :

- [Cadre officiel](00-cadre-officiel.md)
- [Architecture et flux](architecture-et-flux.md)
- [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)
- [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
- [Convergence et réexécution](convergence-et-reexecution.md)
- [Troubleshooting](troubleshooting.md)
- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)

Pour l'installation du poste de contrôle uniquement :

- [Préparation Windows 11 / WSL2 / Ubuntu](00-preparation-environnement.md)
