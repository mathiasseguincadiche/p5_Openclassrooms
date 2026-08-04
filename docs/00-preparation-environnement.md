# Étape 0A — Préparer la VM de lab

Cette étape est le socle local du projet. Sans VM correctement installée,
sécurisée et équipée, les trois exercices AWS ne sont ni reproductibles ni
démontrables. La validation du compte cloud est traitée ensuite dans
[l'étape 0B — AWS Ready](00b-preparation-compte-aws.md).

## Résultat attendu

Une VM nommée `p5-devops` sous **Ubuntu Server 26.04 LTS — Resolute Raccoon** :

- installation en ligne de commande, sans interface graphique ;
- accès réseau et SSH fonctionnels ;
- mises à jour système appliquées ;
- Git, Python, Ansible, Terraform, AWS CLI, Docker, Node.js et les utilitaires
  de diagnostic disponibles ;
- dépôt cloné dans `~/labs/p5_Openclassrooms` ;
- paire de clés SSH dédiée au lab ;
- contrôles locaux du dépôt réussis.

![Préparation de la VM](schemas/etape-0.svg)

## Dimensionnement conseillé

| Ressource | Minimum pratique | Recommandé |
| --- | ---: | ---: |
| vCPU | 2 | 4 |
| Mémoire | 4 Gio | 8 Gio |
| Disque | 30 Gio | 50 Gio extensibles |
| Réseau | NAT | NAT avec redirection SSH ou pont |

La VM pilote AWS ; elle n’héberge pas Amazon OpenSearch. Les ressources AWS
consommatrices sont créées dans le cloud par Terraform.

## Installation d’Ubuntu Server

1. Télécharger l’image **Ubuntu Server 26.04 LTS AMD64**.
2. Créer une VM en mode UEFI avec un disque virtuel extensible.
3. Démarrer sur l’ISO et choisir l’installation serveur standard.
4. Configurer le clavier, le réseau et le stockage.
5. Créer un utilisateur administrateur non `root`.
6. Nommer la machine `p5-devops`.
7. Activer l’installation d’OpenSSH Server.
8. Ne sélectionner aucun environnement de bureau.
9. Redémarrer puis retirer l’ISO.

Après la première connexion :

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

## Bootstrap du socle DevOps

Depuis le dépôt :

```bash
chmod +x scripts/commands/*.sh scripts/tools/*.sh
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le script :

- refuse de s’exécuter sur une distribution non Ubuntu ;
- installe les paquets de base avec APT ;
- installe Terraform depuis le dépôt HashiCorp ;
- installe AWS CLI v2 avec l’installeur officiel ;
- installe Docker Engine et le plugin Compose ;
- installe Ansible, Git, Python, Node.js, npm, ShellCheck et les utilitaires ;
- ajoute l’utilisateur courant au groupe `docker` ;
- ne configure pas les identifiants AWS ;
- ne lance aucun `terraform apply`.

Une reconnexion est nécessaire après l’ajout au groupe `docker`.

## Configuration utilisateur

### Git

```bash
git config --global user.name "Votre nom"
git config --global user.email "votre-adresse@example.com"
git config --global init.defaultBranch main
```

### Clé SSH du lab

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/p5-key -C "p5-lab"
chmod 600 ~/.ssh/p5-key
chmod 644 ~/.ssh/p5-key.pub
```

La clé privée ne doit jamais être copiée dans le dépôt.

### Profil AWS CLI

Le mode recommandé utilise IAM Identity Center :

```bash
aws configure sso --profile p5-lab
aws sso login --profile p5-lab
export AWS_PROFILE=p5-lab
aws sts get-caller-identity
```

Un rôle IAM déjà fourni par une organisation peut également alimenter ce
profil. Les clés d’accès longues durées ne sont pas recommandées et sont
refusées par défaut par le contrôle AWS Ready.

## Cloner et préparer le dépôt

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

## Validation de l’étape 0A

```bash
./scripts/commands/setup.sh --check-only
```

Le contrôle doit confirmer :

- Ubuntu Server 26.04 ;
- outils présents ;
- Docker fonctionnel ;
- arborescence du dépôt complète ;
- Terraform, YAML, Bash et Ansible valides.

Ce verdict signifie uniquement que **la VM est prête**. Il ne garantit pas
encore les permissions, quotas, coûts ou paramètres du compte AWS.

## Étape suivante obligatoire

Poursuivez avec :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

La procédure complète se trouve dans
[`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md).

## Snapshot recommandé

Créer un snapshot de la VM après validation, nommé par exemple
`p5-etape-0a-socle-valide`. Il permet de revenir à un environnement propre sans
réinstaller tout le lab.

## Ce que l’étape 0A ne fait pas

- elle ne crée aucune ressource AWS ;
- elle ne sécurise pas automatiquement le compte root ;
- elle ne crée pas le budget AWS ;
- elle ne vérifie pas les quotas ou les permissions du compte ;
- elle ne construit pas automatiquement les dashboards ;
- elle ne remplace pas la lecture des plans Terraform ;
- elle ne stocke aucun secret dans le dépôt.
