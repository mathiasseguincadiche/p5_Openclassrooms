# Étape 0 — Préparer la VM de lab

Cette étape est le socle du projet. Sans VM correctement installée, sécurisée et
équipée, les trois exercices AWS ne sont ni reproductibles ni démontrables.

## Résultat attendu

Une VM nommée `p5-devops` sous **Ubuntu Server 26.04 LTS — Resolute Raccoon** :

- installation en ligne de commande, sans interface graphique ;
- accès réseau et SSH fonctionnels ;
- mises à jour système appliquées ;
- Git, Python, Ansible, Terraform, AWS CLI, Docker, Node.js et les utilitaires
  de diagnostic disponibles ;
- dépôt cloné dans `~/labs/p5_Openclassrooms` ;
- identité AWS vérifiée sans enregistrer de secret dans Git ;
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

### AWS CLI

Utiliser un profil dédié :

```bash
aws configure --profile p5-lab
export AWS_PROFILE=p5-lab
aws sts get-caller-identity
```

Préférer des identifiants temporaires ou un rôle IAM lorsque le contexte le
permet. Ne jamais écrire de clé AWS dans un fichier Terraform, Markdown ou
capture d’écran.

## Cloner et préparer le dépôt

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
cp terraform/exercice-1/terraform.tfvars.example terraform/exercice-1/terraform.tfvars
cp terraform/exercice-2/terraform.tfvars.example terraform/exercice-2/terraform.tfvars
cp terraform/exercice-3/terraform.tfvars.example terraform/exercice-3/terraform.tfvars
```

Compléter les trois fichiers locaux sans les commiter.

## Validation de l’étape 0

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/pre-deployment-check.sh
```

Le contrôle doit confirmer :

- Ubuntu Server 26.04 ;
- outils présents ;
- Docker fonctionnel ;
- identité AWS active ;
- clé SSH protégée ;
- arborescence du dépôt complète ;
- Terraform, YAML, Bash et Ansible valides.

## Snapshot recommandé

Créer un snapshot de la VM après validation, nommé par exemple
`p5-etape-0-socle-valide`. Il permet de revenir à un environnement propre sans
réinstaller tout le lab.

## Ce que l’étape 0 ne fait pas

- elle ne crée aucune ressource AWS ;
- elle ne construit pas automatiquement les dashboards ;
- elle ne remplace pas la lecture des plans Terraform ;
- elle ne stocke aucun secret dans le dépôt.
