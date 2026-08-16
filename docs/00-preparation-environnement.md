# 00A — Préparer l'environnement de contrôle P5

## Objectif

Cette procédure prépare l'environnement logiciel utilisé par le P5 dans la VM
Ubuntu Server 26.04 **`ubuntu-devops`**.

Le projet évalué s'exécute sur AWS. La VM fournit le plan de contrôle CLI depuis lequel
Terraform, Ansible, AWS CLI, Docker, Node.js et les scripts P5 sont exécutés.

## Architecture de référence

![Étape 0 — préparation du plan de contrôle P5](schemas/etape-0.svg)

La plateforme HOST/KVM/VM est fournie par
[`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom).
Le contrat d'intégration attendu par le P5 est défini dans
[`../environment/vm-devops/README.md`](../environment/vm-devops/README.md).

Toutes les commandes ci-dessous sont exécutées **dans `ubuntu-devops`**. Le parcours de référence
est `inspect → prepare → status → GO TERRAFORM`.

## 1. Ouvrir une session dans la VM

Depuis le HOST, obtenir l'adresse de la VM selon le runbook de la plateforme puis se connecter :

```bash
ssh <utilisateur>@<ip-ubuntu-devops>
```

Vérifier l'identité du runtime :

```bash
hostname -s
cat /etc/os-release
systemd-detect-virt
```

Résultat attendu :

```text
hostname            ubuntu-devops
VERSION_ID          26.04
VERSION_CODENAME    resolute
virtualisation      kvm ou qemu
```

## 2. Préparer le workspace Linux

```bash
mkdir -p ~/labs
cd ~/labs
findmnt -T ~/labs -n -o FSTYPE
```

Le checkout doit résider sur un filesystem Linux local de la VM.

Chemin de référence :

```text
~/labs/p5_Openclassrooms
```

## 3. Cloner ou mettre à jour le dépôt

Première installation :

```bash
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Dépôt déjà présent :

```bash
cd ~/labs/p5_Openclassrooms
git status
git pull --ff-only
```

En cas de divergence locale, diagnostiquer l'historique avant toute réécriture de branche.

## 4. Observer l'état réel du P5

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` collecte les faits utiles avant toute mutation :

- configuration locale disponible ;
- états Terraform présents ;
- outputs existants ;
- preuves déjà collectées ;
- classification du lab pour une éventuelle reprise.

Cette étape ne converge rien. Elle fournit le point de départ réel à partir duquel le delta sera
calculé.

## 5. Contrôler le runtime P5

Contrôle sans mutation :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Le bootstrap contrôle notamment :

- Ubuntu Server 26.04 / Resolute ;
- la VM `ubuntu-devops` ;
- KVM/QEMU ;
- le filesystem du checkout ;
- Terraform ;
- Ansible Core ;
- AWS CLI ;
- Docker Engine et Compose ;
- Node.js/npm ;
- les outils de validation du dépôt.

Interprétation :

- code `0` : runtime conforme ;
- code `90` : reconnexion SSH requise pour activer l'appartenance au groupe Docker ;
- autre code : écart à corriger ou contrat VM non respecté.

La source de vérité des versions P5 est :

```bash
cat environment/versions.env
```

Références principales :

```text
VM logique          ubuntu-devops
Ubuntu Server       26.04 / resolute
Terraform           1.15.8
Ansible Core        2.20.1
Node.js             22.22.0
AWS CLI minimum     2.32.0
```

Les instances EC2 créées par les exercices 1 et 3 utilisent leur propre contrat d'AMI et
ne doivent pas être confondues avec le système de la VM de contrôle.

## 6. Converger l'environnement P5

Commande de référence :

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` :

1. réinspecte l'état réel ;
2. converge les dépendances P5 nécessaires ;
3. contrôle l'accès AWS ;
4. prépare `environment/aws-readiness.env` ;
5. vérifie le budget et les garde-fous ;
6. synchronise les `terraform.tfvars` locaux ;
7. exécute les précontrôles du lab.

La convergence logicielle seule peut être lancée avec :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

### Reconnexion Docker

Si l'utilisateur vient d'être ajouté au groupe Docker :

```text
1. quitter la session SSH
2. se reconnecter à ubuntu-devops
3. revenir dans ~/labs/p5_Openclassrooms
4. relancer prepare
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh prepare
```

## 7. Vérifier les fichiers locaux

```bash
git status --short
```

Les fichiers runtime suivants restent locaux et ignorés par Git :

- `environment/aws-readiness.env` ;
- `terraform/exercice-*/terraform.tfvars` ;
- `ansible/inventories/hosts_aws` ;
- états et plans Terraform ;
- journaux runtime ;
- `proofs/runtime/`.

Audit supplémentaire :

```bash
python3 scripts/tools/audit_secrets.py
```

## 8. Revalider la préparation

```bash
bash scripts/commands/p5.sh status
```

Le précontrôle doit pouvoir atteindre :

```text
GO TERRAFORM
```

Ce verdict indique que le lab peut passer à la lecture d'un plan Terraform. Tout plan doit être
relu avant confirmation d'une mutation AWS.

## Garde-fous

Ne pas :

- exécuter les commandes P5 depuis le HOST ;
- supprimer un `terraform.tfstate` pour recommencer un exercice ;
- stocker des identifiants AWS longue durée dans les fichiers du projet ;
- utiliser le compte root AWS pour l'exploitation normale du lab ;
- modifier les versions de référence sans mettre à jour leur contrat et les validations associées ;
- exécuter un `terraform apply` sans identifier le module, le compte et le delta attendu.

Les opérations de cycle de vie de `ubuntu-devops` relèvent du runbook de la plateforme Ubuntu.

## Definition of Done

L'environnement de contrôle est prêt lorsque :

```text
VM                ubuntu-devops
OS                Ubuntu Server 26.04 / resolute
virtualisation    KVM/QEMU
checkout          filesystem Linux local
runtime P5        conforme
Docker            accessible dans la session
p5.sh inspect     opérationnel
p5.sh prepare     terminé sans blocage
p5.sh status      cohérent avec l'état réel
```

La suite est [`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md).
