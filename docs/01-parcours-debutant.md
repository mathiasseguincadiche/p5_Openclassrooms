# 01 — Parcours débutant : comprendre le P5 avant de l'exécuter

## À qui s'adresse ce guide ?

Ce document est destiné à quelqu'un qui arrive sur le dépôt et veut comprendre **ce qu'il va faire avant de lancer des commandes AWS**.

Il répond à cinq questions :

1. quel problème chaque exercice résout-il ?
2. quel outil est responsable de quoi ?
3. comment les exercices s'enchaînent-ils ?
4. que doit-on observer pour considérer une étape réussie ?
5. quelles actions sont potentiellement coûteuses ou destructives ?

Pour la procédure exacte à copier/exécuter, utiliser ensuite [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).

## Vision d'ensemble

```text
Préparer la VM P5 et AWS
        ↓
Exercice 1
Terraform construit l'infrastructure
Ansible configure et déploie Angular/NGINX
        ↓
   ┌────┴───────────────┐
   │                    │
   ▼                    ▼
Exercice 2          Exercice 3
OpenSearch          HAProxy
logs NGINX          réutilise réseau ex. 1
   │                    │
   └──────────┬─────────┘
              ▼
      preuves et livrables
              ↓
       nettoyage 3→2→1
```

## Étape 0 — Comprendre l'environnement d'exécution

Le P5 n'administre pas le poste hôte ni la virtualisation. Il est exécuté **dans la VM `ubuntu-devops`**, Ubuntu Server 26.04 LTS en CLI.

La VM est construite et maintenue séparément par [`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom).

La séparation est simple :

```text
Ubuntu-desktops-custom
└── HOST Ubuntu + KVM/libvirt + VM ubuntu-devops

p5_Openclassrooms
└── runtime P5 + AWS + exercices + preuves dans ubuntu-devops
```

Une fois connecté en SSH dans la VM :

```bash
cd ~/labs/p5_Openclassrooms
```

Le checkout actif doit rester sur le filesystem Linux local de la VM.

Pourquoi ? Parce que le projet utilise des scripts Bash, des permissions Unix, Terraform, Ansible, Docker et beaucoup de petits fichiers. Le guest Linux est le contexte de référence du P5.

Le dépôt P5 ne doit pas appeler `virsh`, `virt-install` ou modifier la configuration KVM/libvirt. Inversement, la préparation P5 garde la responsabilité des versions logicielles nécessaires au projet **dans le guest**.

## Étape 1 — Comprendre `p5.sh`

La commande centrale est :

```bash
bash scripts/commands/p5.sh
```

Elle ouvre un menu. On peut aussi appeler directement une commande :

```bash
bash scripts/commands/p5.sh inspect
```

### Le principe de convergence

Le moteur ne part pas du principe que « rien n'existe ».

Il cherche d'abord à savoir :

```text
état attendu
    vs
état réel
```

Puis :

```text
si aucun écart → ne rien modifier
si écart       → corriger cet écart
si inconnu     → s'arrêter et demander une information fiable
```

C'est une idée importante en DevOps : une automatisation sûre doit pouvoir être relancée.

## Étape 2 — Préparer le lab sans créer les exercices

Trois commandes structurent la préparation :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

### `inspect`

Observe l'état P5 **dans la VM**. Elle doit être préférée avant toute correction.

### `prepare`

Peut converger :

- les dépendances du runtime P5 dans `ubuntu-devops` ;
- Terraform, Ansible, Node.js, AWS CLI, Docker et les outils de validation nécessaires au projet ;
- la configuration locale AWS ;
- l'authentification ;
- les garde-fous de budget ;
- les `terraform.tfvars`.

Elle ne signifie pas « déployer les trois exercices » et ne signifie pas « administrer la VM ».

### `status`

Contrôle que le lab est cohérent sans créer les ressources applicatives.

À ce stade, le débutant doit savoir expliquer :

- pourquoi le P5 s'exécute dans `ubuntu-devops` ;
- pourquoi KVM/libvirt reste hors du dépôt P5 ;
- quel compte AWS sera utilisé ;
- dans quelle région ;
- pourquoi SSH est limité en `/32` ;
- où se trouve sa clé SSH ;
- à quoi sert le budget ;
- pourquoi les vrais `tfvars` ne sont pas dans Git.

## Étape 3 — Exercice 1 : Terraform construit, Ansible configure

C'est la séparation la plus importante du premier exercice.

### Terraform

Terraform décrit l'infrastructure souhaitée :

```text
VPC
├── subnet public 1
├── subnet public 2
├── Internet Gateway
├── table de routage
├── Security Group
├── paire de clés
└── EC2 Ubuntu
```

Terraform n'est pas utilisé ici pour installer NGINX ou copier le build Angular.

### Ansible

Une fois l'EC2 disponible, Ansible :

```text
inventaire
   ↓
ping
   ↓
deploy.yml
   ↓
NGINX + Angular
```

Il installe les paquets, crée les droits, copie l'application, installe la configuration NGINX et s'assure que le service est démarré.

### Pourquoi rejouer Ansible ?

Un premier passage peut légitimement modifier le serveur.

Le second passage sert à répondre à :

> « Si l'état demandé est déjà présent, est-ce que l'automatisation sait ne rien refaire inutilement ? »

Le résultat attendu est :

```text
changed=0
unreachable=0
failed=0
```

### Pourquoi générer du trafic ensuite ?

Le projet a besoin de **vrais logs NGINX**. L'orchestrateur envoie donc des requêtes vers l'application et collecte `access.log`.

Ces logs pourront être utilisés dans l'exercice 2.

## Étape 4 — Exercice 2 : passer du log à l'information

Un log brut n'est pas encore une information opérationnelle.

Le parcours est :

```text
ligne NGINX
    ↓
parsing / typage
    ↓
Bulk API
    ↓
index OpenSearch
    ↓
agrégations
    ↓
visualisations
```

### Pourquoi un sample et un log réel ?

Le sample versionné permet de reproduire les tests.

Le log réel de l'exercice 1 montre que le même pipeline sait traiter l'activité de l'application réellement déployée.

### Pourquoi le dashboard reste manuel ?

Parce que l'objectif pédagogique n'est pas seulement d'avoir un JSON qui décrit des visualisations. Il faut comprendre ce que chaque métrique représente.

Les trois visualisations demandées sont :

1. répartition des méthodes HTTP ;
2. somme des octets envoyés par période de 12 heures ;
3. top 5 des URL/requêtes par période de 12 heures.

Le dépôt vérifie les données ; l'opérateur vérifie visuellement le dashboard.

## Étape 5 — Exercice 3 : rendre un service tolérant à une panne de backend

L'architecture est :

```text
            client
              │
              ▼
           HAProxy
           /     \
          /       \
     backend 1  backend 2
     nginx hello nginx hello
```

HAProxy utilise le mode `roundrobin` pour alterner les requêtes.

Les health checks permettent d'écarter un backend qui ne répond plus.

Le comportement recherché est :

```text
AVANT PANNE
backend 1 + backend 2

PENDANT PANNE
backend 2 uniquement
service toujours disponible

APRÈS RESTAURATION
backend 1 + backend 2
```

L'exercice n'est donc pas terminé simplement parce que `haproxy.cfg` est syntaxiquement valide. Il faut démontrer le comportement.

## Étape 6 — Comprendre les dépendances

### Dépendance exercice 1 → exercice 2

Les logs NGINX réels de l'exercice 1 sont une source de données de l'exercice 2.

### Dépendance exercice 1 → exercice 3

L'exercice 3 cherche le VPC et les subnets de l'exercice 1 par tags Terraform/AWS.

Cela implique :

> Ne pas détruire l'exercice 1 tant que l'exercice 3 doit encore être créé ou testé.

## Étape 7 — Comprendre les preuves

Un fichier `.tf` prouve que du code Terraform existe. Il ne prouve pas qu'AWS a réellement créé l'infrastructure.

Même logique pour Ansible, OpenSearch et HAProxy.

Une preuve utile répond à trois questions :

```text
Quelle commande a été exécutée ?
Quel résultat a été observé ?
Pourquoi ce résultat valide-t-il le besoin ?
```

Le moteur conserve ses journaux sous :

```text
logs/<UTC>/
proofs/runtime/
```

Ces éléments sont privés par défaut. On sélectionne ensuite les extraits nécessaires pour les livrables.

## Étape 8 — Comprendre la différence entre CI et lab AWS

La CI peut vérifier :

- syntaxe Bash ;
- ShellCheck ;
- Terraform `fmt` et `validate` ;
- Ansible syntax-check ;
- build Angular ;
- NGINX ;
- OpenSearch en conteneur éphémère ;
- HAProxy en environnement de test ;
- contrat d'intégration avec la VM `ubuntu-devops` ;
- contrats documentaires et sécurité.

Elle ne peut pas prouver à votre place :

- que votre compte AWS a réellement créé l'EC2 ;
- que votre dashboard existe ;
- que votre panne réelle a été observée ;
- que vos captures sont prêtes pour l'évaluation.

Il faut donc toujours distinguer :

```text
CI VERTE = dépôt cohérent
PREUVES AWS = exercice réellement réalisé
```

## Étape 9 — Finaliser

Quand les trois exercices sont terminés :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

`diagnostics` collecte l'état technique.

`finalize` applique le contrôle strict des livrables et doit finir par :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Étape 10 — Nettoyer

Le nettoyage est une étape du projet, pas une formalité après le projet.

Commande :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
3 → 2 → 1
```

Puis audit AWS.

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, ne pas supposer que les coûts ont cessé.

## Les commandes à connaître avant le runbook

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

## Ce que vous devez savoir expliquer à la fin

- frontière `Ubuntu-desktops-custom` / `p5_Openclassrooms` ;
- différence plateforme VM / préparation runtime P5 ;
- différence Terraform / Ansible ;
- rôle d'un provider Terraform et d'un state ;
- intérêt de `plan` avant `apply` ;
- rôle d'un inventaire Ansible ;
- notion d'idempotence ;
- rôle de NGINX dans l'exercice 1 ;
- chemin d'un log NGINX jusqu'à OpenSearch ;
- signification des trois visualisations ;
- rôle d'un load-balancer ;
- différence round-robin / health check ;
- pourquoi le service continue pendant la panne ;
- pourquoi l'exercice 3 doit être détruit avant l'exercice 1 ;
- différence entre une CI verte et une preuve réelle.

Lorsque ces notions sont claires, passer au [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).
