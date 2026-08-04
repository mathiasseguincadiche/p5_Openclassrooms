# Environnement de lab — Étape 0

Ce dossier décrit le **poste de contrôle** du P5 : une VM Ubuntu Server 26.04
LTS « Resolute Raccoon », administrée en ligne de commande.

```text
environment/
├── README.md
├── apt-packages.txt   # paquets système utiles au lab
└── versions.env       # versions et canaux de référence
```

## Rôle du dossier

Les fichiers d’`environment/` centralisent les choix de la VM. L’installation
réelle est effectuée par :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le contrôle non destructif est effectué par :

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/pre-deployment-check.sh
```

## Socle attendu

- administration : OpenSSH, Git, curl, jq et outils réseau ;
- Infrastructure as Code : Terraform ;
- automatisation : Ansible Core ;
- cloud : AWS CLI version 2 ;
- application : Node.js, npm et build Angular ;
- conteneurs : Docker Engine, Buildx et Compose ;
- qualité : ShellCheck, yamllint et markdownlint-cli2 ;
- intégration VM : `qemu-guest-agent` lorsque la VM tourne sous QEMU/KVM.

Le bootstrap ne lance ni `aws configure`, ni `terraform apply`, ni création de
clé SSH. Les secrets et décisions d’accès restent sous le contrôle de
l’utilisateur.

La procédure complète se trouve dans
[`docs/00-preparation-environnement.md`](../docs/00-preparation-environnement.md).
