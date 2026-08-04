# Étape 0A — Préparer la VM de lab

Cette étape est le socle local du projet. Sans VM correctement installée,
sécurisée et équipée, les trois exercices AWS ne sont ni reproductibles ni
démontrables. La validation du compte cloud est traitée ensuite dans
[l’étape 0B — AWS Ready](00b-preparation-compte-aws.md).

## Résultat attendu

Une VM nommée `p5-devops` sous **Ubuntu Server 26.04 LTS — Resolute Raccoon** :

- installation en ligne de commande, sans interface graphique ;
- accès réseau et SSH fonctionnels ;
- mises à jour système appliquées ;
- Git, Python, Ansible, Terraform, AWS CLI, Docker et les outils de qualité ;
- Node.js 22.22.0 installé avec NVM pour Angular 21 ;
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
7. Activer OpenSSH Server.
8. Ne sélectionner aucun environnement de bureau.
9. Redémarrer puis retirer l’ISO.

Après la première connexion :

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

## Cloner le dépôt

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Les scripts utiles sont déjà exécutables dans Git.

## Bootstrap du socle DevOps

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le script :

- refuse une distribution non Ubuntu ;
- installe les paquets de base avec APT ;
- installe Terraform depuis le dépôt HashiCorp ;
- installe AWS CLI v2 ;
- installe Docker Engine, Buildx et Compose ;
- installe NVM puis la version Node.js définie dans `environment/versions.env` ;
- fixe Node.js 22.22.0 comme version par défaut ;
- installe `markdownlint-cli2` avec ce Node.js ;
- ajoute l’utilisateur courant au groupe `docker` ;
- ne configure aucun identifiant AWS ;
- ne lance aucun `terraform apply`.

Déconnectez-vous puis reconnectez-vous. Cette reconnexion charge NVM dans le
nouveau shell et applique l’appartenance au groupe `docker`.

Vérifiez ensuite :

```bash
node --version
docker info
```

Le résultat Node.js attendu est `v22.22.0`.

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
profil. Les clés d’accès longues durées sont refusées par défaut par le contrôle
AWS Ready.

## Validation de l’étape 0A

```bash
./scripts/commands/setup.sh --check-only
```

Le contrôle confirme notamment :

- Ubuntu Server 26.04 ;
- Node.js 22.22.0 et les outils obligatoires ;
- moteur Docker accessible ;
- application Angular, verrouillage npm et build Ansible présents ;
- composants OpenSearch et HAProxy présents ;
- scripts exécutables ;
- validations locales du dépôt réussies.

La validation locale complète peut aussi être relancée directement :

```bash
./scripts/commands/validate.sh
```

Elle reconstruit Angular, compare le build Ansible, convertit l’échantillon
OpenSearch, valide HAProxy lorsque Docker est disponible et contrôle Terraform,
Ansible, YAML, Markdown, Bash et les livrables.

Ce verdict signifie uniquement que **la VM et le dépôt sont prêts**. Il ne
garantit pas encore les permissions, quotas, coûts ou paramètres du compte AWS.

## Étape suivante obligatoire

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

La procédure complète se trouve dans
[`00b-preparation-compte-aws.md`](00b-preparation-compte-aws.md).

## Snapshot recommandé

Créer un snapshot nommé par exemple `p5-etape-0a-socle-valide` après validation.
Il permet de revenir à un environnement propre sans réinstaller le lab.

## Ce que l’étape 0A ne fait pas

- elle ne crée aucune ressource AWS ;
- elle ne sécurise pas automatiquement le compte root ;
- elle ne crée pas le budget sans commande explicite ;
- elle ne vérifie pas les quotas ou permissions AWS ;
- elle ne produit pas de fausses preuves de déploiement ;
- elle ne stocke aucun secret dans le dépôt.
