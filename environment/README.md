# Environnement de lab — Étape 0

Ce dossier décrit et automatise le **poste de contrôle** du P5 : une VM Ubuntu
Server 26.04 LTS « Resolute Raccoon », administrée uniquement en ligne de
commande.

```text
environment/
├── README.md
├── apt-packages.txt   paquets système nécessaires au projet
└── versions.env       OS, canaux et contraintes de versions
```

## Ce qui est installé

- administration : OpenSSH, Git, curl, rsync, jq et outils réseau ;
- Infrastructure as Code : Terraform depuis le dépôt officiel HashiCorp ;
- automatisation : Ansible Core isolé avec `pipx` ;
- cloud : AWS CLI version 2 depuis l’installeur officiel AWS ;
- application : Node.js LTS avec `nvm`, npm et Angular CLI ;
- conteneurs et validation : Docker Engine, Buildx et Compose ;
- qualité : ShellCheck, yamllint et markdownlint-cli2 ;
- intégration VM : `qemu-guest-agent`.

## Commandes

```bash
make vm-bootstrap   # installation, avec sudo ; aucune ressource AWS créée
# Fermer puis rouvrir la session pour le groupe docker.
make vm-check       # vérification complète
make validate       # validation du dépôt
make preflight      # contrôle avant le premier déploiement
```

Le bootstrap est idempotent : il peut être relancé après une mise à jour ou sur
une VM reconstruite. Il n’exécute ni `aws configure`, ni `terraform apply`, ni
la création de clés SSH sans décision explicite de l’utilisateur.

La procédure d’installation détaillée se trouve dans
[`docs/etape-0/README.md`](../docs/etape-0/README.md).
