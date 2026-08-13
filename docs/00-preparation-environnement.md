# 00A — Préparer l'environnement de contrôle

## Objectif

Ce document prépare **le poste depuis lequel le P5 sera exécuté**. Il ne décrit pas un exercice OpenClassrooms.

Le projet évalué reste AWS. Le poste de contrôle fournit simplement Bash, Terraform, Ansible, AWS CLI, Docker, Node.js et Git.

## Architecture du poste

```text
Windows 11 Pro
   │
   └── WSL2
        └── Ubuntu 26.04
             ├── Bash
             ├── Terraform
             ├── Ansible
             ├── AWS CLI
             ├── Docker CLI / Compose
             ├── Node.js / npm
             └── checkout P5 sur filesystem Linux
```

La configuration générale de la workstation est maintenue dans le dépôt [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom). P5 ne duplique pas `.wslconfig`, la gestion du VHDX, les sauvegardes Windows ou les scripts de cycle de vie WSL2.

## Pourquoi le checkout doit rester côté Linux

Le dépôt actif doit être placé dans un chemin comme :

```text
~/labs/p5_Openclassrooms
```

et **pas** dans :

```text
/mnt/c/...
/mnt/d/...
```

Le moteur vérifie ce point parce que les outils Linux, les permissions, les bits exécutables, les performances de nombreux petits fichiers et certains comportements de Docker/Git sont plus prévisibles sur le filesystem Linux WSL2.

## Étape 1 — Ouvrir Ubuntu

Depuis PowerShell ou Windows Terminal :

```powershell
wsl -d Ubuntu
```

### Ce que fait la commande

- `wsl` appelle Windows Subsystem for Linux ;
- `-d Ubuntu` choisit explicitement la distribution Ubuntu attendue ;
- le shell qui s'ouvre devient l'environnement d'exécution des commandes P5.

### Vérification

Dans Ubuntu :

```bash
cat /etc/os-release
uname -a
pwd
```

Le contrat P5 attend Ubuntu 26.04. Les valeurs exactes de référence sont définies dans `environment/versions.env`.

## Étape 2 — Créer le dossier de labs

```bash
mkdir -p ~/labs
cd ~/labs
```

`mkdir -p` crée le dossier s'il n'existe pas et ne produit pas d'erreur s'il existe déjà.

Vérifier le filesystem :

```bash
findmnt -T ~/labs -n -o FSTYPE
```

Le résultat attendu pour le checkout actif est `ext4`.

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

## Étape 4 — Vérifier le socle sans rien installer

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Ce mode est une inspection. Il compare l'environnement réel aux versions et capacités attendues.

Il vérifie notamment :

- distribution Ubuntu attendue ;
- emplacement du checkout ;
- commandes système nécessaires ;
- Terraform ;
- Ansible ;
- AWS CLI ;
- Node.js/npm ;
- Docker ;
- outils de validation.

### Interpréter le résultat

- code `0` : le socle est conforme ;
- code `90` : les outils sont installés, mais une reconnexion est nécessaire pour rendre le groupe Docker actif ;
- autre code : au moins un écart doit être corrigé.

Ne pas contourner un écart en installant au hasard une autre version. Le projet versionne son contrat dans `environment/versions.env`.

## Étape 5 — Laisser P5 converger le socle

La commande normale est :

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` commence par inspecter l'état. Si le bootstrap est déjà conforme, aucune installation inutile n'est exécutée. S'il manque une capacité ou qu'une version ne correspond pas, le moteur demande confirmation avant correction.

### Cas de la reconnexion Docker

Après l'ajout de l'utilisateur au groupe Docker, le shell courant peut ne pas connaître encore le nouveau groupe.

Le moteur retourne alors l'état spécifique de reconnexion. La bonne action est :

```text
1. quitter le shell Ubuntu
2. rouvrir Ubuntu
3. revenir dans ~/labs/p5_Openclassrooms
4. relancer la même commande
```

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh prepare
```

## Versions de référence

Ne recopier les versions dans des scripts personnels que si cela est indispensable. La source de vérité est :

```bash
cat environment/versions.env
```

Le dépôt référence notamment :

```text
Ubuntu WSL2       26.04
Node.js           22.22.0
Ansible Core      2.20.1
Terraform         1.15.8
AWS CLI minimum   2.32.0
```

Ces versions concernent le **poste de contrôle**. Les instances EC2 des exercices 1 et 3 utilisent Ubuntu 24.04 LTS lorsque l'AMI est sélectionnée automatiquement.

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

> « Dans quel état réel se trouve mon lab avant que je décide de le modifier ? »

Elle n'est pas destinée à « faire fonctionner » le projet. Elle collecte des faits.

## Étape 8 — Contrôle de préparation

Après `prepare` :

```bash
bash scripts/commands/p5.sh status
```

`status` ne déploie pas le projet. Il vérifie que les prérequis nécessaires sont cohérents : configuration locale, `tfvars`, budget et état AWS adapté à la situation.

## Ce qu'il ne faut pas faire

Ne pas :

- cloner le dépôt actif sous `/mnt/c` ou `/mnt/d` ;
- modifier les versions de manière opportuniste parce qu'une commande échoue ;
- stocker des clés AWS dans `aws-readiness.env` ;
- utiliser le compte root AWS pour le lab normal ;
- supprimer un `terraform.tfstate` pour « réinitialiser » un exercice ;
- exécuter directement `terraform apply` sans savoir quel module et quel compte sont actifs ;
- traiter Windows/WSL2 comme une partie du livrable P5.

## Verdict de cette étape

L'environnement de contrôle est prêt lorsque :

```text
- Ubuntu WSL2 est conforme au contrat P5
- le checkout actif est sur le filesystem Linux
- les outils requis sont disponibles
- Docker est utilisable dans le shell courant
- p5.sh inspect fonctionne
- p5.sh prepare peut terminer la préparation
- p5.sh status ne signale pas de blocage non compris
```

La suite est [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md).
