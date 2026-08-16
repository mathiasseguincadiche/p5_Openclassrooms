# 00A — Préparer l'environnement de contrôle P5

## Objectif

Ce document prépare **le runtime dans lequel le P5 sera exécuté**. Il ne décrit ni l'installation du HOST Ubuntu, ni KVM/libvirt, ni la création de la VM.

Le projet évalué reste AWS. Le runtime P5 fournit Bash, Terraform, Ansible, AWS CLI, Docker, Node.js et Git **dans la VM Ubuntu Server 26.04 `ubuntu-devops`**.

## Architecture de référence

```text
HOST Ubuntu
   │
   └── KVM/libvirt
        │
        └── VM ubuntu-devops
             └── Ubuntu Server 26.04 / CLI
                  ├── Bash
                  ├── Terraform
                  ├── Ansible
                  ├── AWS CLI
                  ├── Docker / Compose
                  ├── Node.js / npm
                  └── ~/labs/p5_Openclassrooms
```

La construction et la maintenance des deux premières couches sont la responsabilité du dépôt séparé [`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom).

Le P5 commence **une fois connecté dans `ubuntu-devops`**. Il ne crée pas la VM, ne modifie pas KVM/libvirt et ne gère pas son réseau ou son stockage.

## Pourquoi conserver une préparation P5 distincte ?

Le dépôt Ubuntu fournit une VM DevOps exploitable. Le P5 conserve néanmoins son propre contrat logiciel afin de garantir la reproductibilité de l'évaluation.

Ainsi :

```text
Ubuntu-desktops-custom
└── garantit une VM Ubuntu Server DevOps saine

p5_Openclassrooms
└── garantit les versions/capacités nécessaires au P5 dans cette VM
```

`p5.sh prepare` peut donc installer ou réaligner **dans le guest uniquement** Terraform, Ansible, Node.js, AWS CLI, Docker et les outils strictement nécessaires au P5.

Cette préparation n'est pas une installation de la VM : c'est la préparation de l'environnement du projet.

## Étape 1 — Entrer dans `ubuntu-devops`

Depuis le HOST, utiliser le runbook du dépôt `Ubuntu-desktops-custom` pour vérifier que la VM existe, est démarrée et joignable.

La connexion habituelle est ensuite :

```bash
ssh <utilisateur>@<ip-ubuntu-devops>
```

À partir de ce point, **toutes les commandes de ce document sont exécutées dans la VM**.

### Vérification

```bash
hostname -s
cat /etc/os-release
systemd-detect-virt
pwd
```

Le contrat P5 attend :

```text
hostname            ubuntu-devops
VERSION_ID          26.04
VERSION_CODENAME    resolute
virtualisation      kvm ou qemu
```

Les valeurs de référence P5 sont définies dans `environment/versions.env`.

## Étape 2 — Créer le dossier de labs dans la VM

```bash
mkdir -p ~/labs
cd ~/labs
```

Vérifier le filesystem :

```bash
findmnt -T ~/labs -n -o FSTYPE
```

Le checkout doit rester sur un filesystem Linux local du guest. Le bootstrap accepte les filesystems Linux prévus par le contrat et refuse les environnements qui ne correspondent pas à l'architecture VM.

## Étape 3 — Cloner le dépôt

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Si le dépôt existe déjà :

```bash
cd ~/labs/p5_Openclassrooms
git status
git pull --ff-only
```

`git pull --ff-only` refuse de créer automatiquement un commit de merge inattendu. Si la branche locale a divergé, diagnostiquer la situation avant de modifier l'historique.

## Étape 4 — Vérifier le runtime P5 sans rien installer

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Ce mode est une inspection. Il compare l'environnement réel de `ubuntu-devops` aux versions et capacités attendues par le P5.

Il vérifie notamment :

- Ubuntu Server 26.04 / Resolute ;
- exécution dans la VM KVM/QEMU attendue ;
- hostname `ubuntu-devops` ;
- filesystem Linux local pour le checkout ;
- commandes système nécessaires ;
- Terraform ;
- Ansible ;
- AWS CLI ;
- Node.js/npm ;
- Docker ;
- outils de validation.

### Interpréter le résultat

- code `0` : le runtime P5 est conforme ;
- code `90` : les outils sont installés, mais une nouvelle session SSH est nécessaire pour rendre le groupe Docker actif ;
- autre code : au moins un écart P5 doit être corrigé, ou le script n'est pas exécuté dans la VM attendue.

Ne pas contourner un écart en installant au hasard une autre version. Le projet versionne son contrat dans `environment/versions.env`.

Si le problème concerne la VM elle-même — VM absente, réseau KVM, disque, démarrage, cloud-init initial ou sauvegarde — sortir du périmètre P5 et utiliser `Ubuntu-desktops-custom`.

## Étape 5 — Laisser P5 converger son runtime

La commande normale est :

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` commence par inspecter l'état. Si le runtime est déjà conforme, aucune installation inutile n'est exécutée. S'il manque une capacité ou qu'une version requise par le P5 ne correspond pas, le moteur demande confirmation avant correction.

Cette convergence reste limitée à la VM et au projet P5.

### Cas de la reconnexion Docker

Après l'ajout de l'utilisateur au groupe Docker, le shell SSH courant peut ne pas connaître encore le nouveau groupe.

La bonne action est :

```text
1. quitter la session SSH
2. se reconnecter à ubuntu-devops
3. revenir dans ~/labs/p5_Openclassrooms
4. relancer la même commande
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh prepare
```

## Versions de référence P5

La source de vérité est :

```bash
cat environment/versions.env
```

Le dépôt référence notamment :

```text
VM logique          ubuntu-devops
Ubuntu Server       26.04 / resolute
Node.js             22.22.0
Ansible Core        2.20.1
Terraform           1.15.8
AWS CLI minimum     2.32.0
```

Ces versions concernent le **runtime P5 dans la VM**. Les instances EC2 des exercices 1 et 3 utilisent Ubuntu 24.04 LTS lorsque l'AMI est sélectionnée automatiquement.

## Étape 6 — Vérifier Git et les fichiers locaux

```bash
git status --short
```

Avant le premier déploiement réel, il est normal que certains fichiers locaux soient créés par le moteur puis ignorés par Git, par exemple :

- `environment/aws-readiness.env` ;
- `terraform/exercice-*/terraform.tfvars` ;
- `ansible/inventories/hosts_aws` ;
- états et plans Terraform ;
- `logs/` runtime ;
- `proofs/runtime/`.

Ils ne doivent pas être ajoutés au dépôt.

Vérification supplémentaire :

```bash
python3 scripts/tools/audit_secrets.py
```

## Étape 7 — Inspection initiale P5

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande doit devenir un réflexe. Elle répond à la question :

> « Dans quel état réel se trouve mon lab P5 dans la VM avant que je décide de le modifier ? »

Elle n'est pas destinée à « faire fonctionner » le projet. Elle collecte des faits.

## Étape 8 — Contrôle de préparation

Après `prepare` :

```bash
bash scripts/commands/p5.sh status
```

`status` ne déploie pas le projet. Il vérifie que les prérequis nécessaires sont cohérents : configuration locale, `tfvars`, budget et état AWS adapté à la situation.

## Ce qu'il ne faut pas faire

Ne pas :

- exécuter le P5 sur le HOST pour contourner un problème dans `ubuntu-devops` ;
- utiliser P5 pour créer, réparer ou reconfigurer KVM/libvirt ;
- modifier les versions P5 de manière opportuniste parce qu'une commande échoue ;
- stocker des clés AWS dans `aws-readiness.env` ;
- utiliser le compte root AWS pour le lab normal ;
- supprimer un `terraform.tfstate` pour « réinitialiser » un exercice ;
- exécuter directement `terraform apply` sans savoir quel module et quel compte sont actifs ;
- présenter la plateforme Ubuntu/KVM comme une partie du livrable P5.

## Verdict de cette étape

L'environnement de contrôle P5 est prêt lorsque :

```text
- ubuntu-devops est la VM d'exécution
- Ubuntu Server 26.04 / Resolute est conforme
- la virtualisation KVM/QEMU est détectée
- le checkout actif est sur le filesystem Linux local de la VM
- les outils requis par le P5 sont disponibles
- Docker est utilisable dans la session SSH courante
- p5.sh inspect fonctionne
- p5.sh prepare peut terminer la préparation P5
- p5.sh status ne signale pas de blocage non compris
```

La suite est [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md).
