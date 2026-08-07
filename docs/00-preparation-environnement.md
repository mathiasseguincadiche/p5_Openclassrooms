# Étape 0A — Préparer la VM de lab

Cette étape construit le **poste de contrôle DevOps** du projet. La VM exécute
Terraform, Ansible, AWS CLI, Node.js, Docker et les scripts du dépôt ; elle ne
remplace pas les infrastructures AWS évaluées.

La préparation du compte est traitée ensuite dans
[l’étape 0B — AWS Ready](00b-preparation-compte-aws.md).

![Préparation de la VM](schemas/etape-0.svg)

## Résultat attendu

Une VM nommée par exemple `p5-devops` avec :

- Ubuntu Server 26.04 ;
- environnement CLI sans bureau requis ;
- accès réseau et SSH ;
- Git, Python, Terraform, Ansible, AWS CLI et Docker ;
- Node.js 22.22.0 avec NVM ;
- dépôt cloné ;
- clé SSH dédiée au lab ;
- validation locale réussie.

Le verdict de fin d’étape est :

```text
Étape 0A validée. Poursuivez avec le contrôle AWS Ready.
```

## Dimensionnement conseillé

| Ressource | Minimum pratique | Recommandé |
| --- | ---: | ---: |
| vCPU | 2 | 4 |
| Mémoire | 4 Gio | 8 Gio |
| Disque | 30 Gio | 50 Gio extensibles |
| Réseau | NAT | NAT avec accès SSH ou pont |

La VM ne porte pas le domaine Amazon OpenSearch du livrable : ce service est
créé dans AWS.

## Versions de référence

La source de vérité est :

```text
environment/versions.env
```

Le dépôt fixe notamment :

| Composant | Référence |
| --- | --- |
| Ubuntu Server | 26.04 |
| Node.js | 22.22.0 |
| Ansible Core | 2.20.1 |
| Terraform | 1.15.8 |
| OpenSearch local de test | 2.19.6 |
| NGINX local de test | `nginx:1.28-alpine` |
| HAProxy local de test | `haproxy:3.2-alpine` |

## 1. Installer Ubuntu Server

1. créer une VM UEFI ;
2. installer Ubuntu Server 26.04 ;
3. créer un utilisateur administrateur non `root` ;
4. activer OpenSSH Server ;
5. ne pas installer d’environnement de bureau si inutile ;
6. redémarrer après l’installation.

Puis :

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

## 2. Cloner le dépôt

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

## 3. Installer le socle automatiquement

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le script :

- refuse une exécution en `root` ;
- contrôle que le système est Ubuntu ;
- installe les paquets de base avec APT ;
- télécharge **Terraform depuis l’archive officielle HashiCorp** ;
- vérifie le SHA-256 de l’archive Terraform ;
- installe Docker Engine et Compose depuis le dépôt Docker ;
- installe AWS CLI v2 ;
- installe Ansible Core avec `pipx` ;
- installe NVM et la version Node.js fixée ;
- installe `markdownlint-cli2` ;
- ajoute l’utilisateur au groupe `docker` ;
- contrôle les versions obtenues.

Il ne :

- configure aucun secret AWS ;
- lance aucun `terraform apply` ;
- crée aucune ressource AWS ;
- crée aucune clé SSH à votre place.

## 4. Se reconnecter

Après le bootstrap, déconnectez-vous puis reconnectez-vous à la VM.

Cette étape est nécessaire pour :

- appliquer l’appartenance au groupe `docker` ;
- charger NVM et Node.js dans un nouveau shell.

Vérifiez :

```bash
node --version
docker info
```

Node.js doit afficher :

```text
v22.22.0
```

## 5. Configurer Git

```bash
git config --global user.name "Votre nom"
git config --global user.email "votre-adresse@example.com"
git config --global init.defaultBranch main
```

## 6. Créer la clé SSH du lab

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/p5-key -C "p5-lab"
chmod 600 ~/.ssh/p5-key
chmod 644 ~/.ssh/p5-key.pub
```

La clé privée :

```text
~/.ssh/p5-key
```

ne doit jamais entrer dans le dépôt.

La clé publique sera utilisée par Terraform pour créer la paire EC2.

## 7. Préparer le profil AWS

Le mode recommandé est IAM Identity Center :

```bash
aws configure sso --profile p5-lab
aws sso login --profile p5-lab
export AWS_PROFILE=p5-lab
aws sts get-caller-identity
```

Un rôle IAM fourni par une organisation est également acceptable.

La validation stricte du compte est réalisée à l’étape 0B ; ici, on vérifie
seulement que l’outil AWS CLI peut être utilisé.

## 8. Valider la VM

```bash
./scripts/commands/setup.sh --check-only
```

Le contrôle vérifie notamment :

- version Ubuntu ;
- outils obligatoires ;
- version Node.js ;
- moteur Docker ;
- fichiers critiques du dépôt ;
- véritable artefact Angular ;
- validation locale `validate.sh`.

Si la configuration AWS locale existe déjà et que le profil est actif, le script
peut aussi signaler que l’identité AWS est accessible, mais **AWS Ready reste
obligatoire**.

## 9. Validation locale complète

Commande standard :

```bash
./scripts/commands/validate.sh
```

Elle couvre selon les outils disponibles :

- structure du dépôt ;
- non-régression ;
- Angular ;
- NGINX ;
- HAProxy local ;
- données OpenSearch ;
- Terraform ;
- Ansible ;
- Bash ;
- YAML ;
- Markdown ;
- livrables.

Pour inclure OpenSearch local :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

Cette validation ne crée aucune infrastructure AWS.

## 10. Diagnostic en cas de problème

```bash
bash scripts/commands/collect-diagnostics.sh
```

Le collecteur produit une archive nettoyée partageable après relecture.

Voir : [Troubleshooting](troubleshooting.md).

## 11. Snapshot recommandé

Après validation, créer un snapshot de la VM, par exemple :

```text
p5-etape-0a-socle-valide
```

Cela permet de revenir à un poste propre sans réinstaller le socle.

## Ce que l’étape 0A ne valide pas

Elle ne garantit pas :

- le MFA root ;
- le bon compte AWS ;
- le budget ;
- les quotas ;
- la région ;
- l’IP `/32` ;
- les permissions nécessaires ;
- l’absence de collision avec des ressources déjà présentes.

Ces éléments appartiennent à l’étape 0B.

## Étape suivante obligatoire

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
bash scripts/commands/sync-terraform-tfvars.sh --apply
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

Lire :
[Étape 0B — Préparer et valider AWS](00b-preparation-compte-aws.md).
