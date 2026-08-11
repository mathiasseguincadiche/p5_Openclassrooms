# 01 — Parcours d'exécution de bout en bout

Ce document est le **runbook principal synthétique** du P5.

La workstation Windows/WSL2 est préparée en amont par
`mathiasseguincadiche/Windows_11_Pro_Custom`. Le P5 ne crée plus sa propre
distribution WSL2.

Pour une exécution détaillée, consulter aussi le
[Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md).

## Règles du parcours

- utiliser la distribution WSL2 `Ubuntu` fournie par la workstation ;
- conserver le dépôt sous `~/labs/` dans le filesystem Linux ;
- qualifier WSL2 et la stack DevOps dans le dépôt Windows avant P5 ;
- ne jamais modifier `.wslconfig` depuis P5 ;
- ne jamais versionner `environment/aws-readiness.env`, `terraform.tfvars`, les
  états Terraform, `logs/` ou `proofs/runtime/` ;
- relire chaque plan Terraform avant `apply` ;
- ne jamais détruire l'exercice 1 avant la fin de l'exercice 3 ;
- terminer par l'audit AWS global.

## 1. Qualifier la workstation

Dans `Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Verdicts attendus :

```text
VERDICT: V3 DEVOPS READY
VERDICT: V6 WSL2 PLATFORM READY
```

Si cette validation échoue, corriger la plateforme dans le dépôt Windows avant
de continuer.

## 2. Ouvrir Ubuntu

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
```

Pour un clone neuf :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

## 3. Vérifier le delta P5

Sans mutation :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Si le socle satisfait déjà le contrat P5, aucune installation n'est nécessaire.
Si une version ou un outil spécifique au projet est incompatible :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap ne doit corriger que le delta P5. Il n'installe pas WSL2 et ne gère
pas le VHDX.

## 4. Inspecter le lab

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande observe notamment :

- socle Ubuntu et outils P5 ;
- configuration AWS locale ;
- session AWS existante ;
- clés SSH ;
- `terraform.tfvars` ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs existants.

Elle ne crée aucune ressource.

## 5. Parcours complet

```bash
bash scripts/commands/p5.sh all
```

Le parcours est :

```text
workstation amont qualifiée
        ↓
contrat P5 local
        ↓
prepare
  ├── configuration AWS locale
  ├── synchronisation tfvars
  ├── budget
  └── GO AWS + GO TERRAFORM
        ↓
ex1
  ├── Angular
  ├── Terraform exercice 1
  ├── inventaire Ansible
  ├── déploiement
  ├── deuxième passage changed=0
  └── logs NGINX réels
        ↓
ex2
  ├── Terraform OpenSearch
  ├── imports
  ├── agrégations
  └── dashboard + captures
        ↓
ex3
  ├── Terraform HAProxy
  ├── round-robin
  ├── panne contrôlée
  └── reprise
        ↓
diagnostics + preuves + livrables
```

## Préparation AWS

```bash
bash scripts/commands/p5.sh prepare
```

Cette étape gère :

- profil/session AWS ;
- identité et refus du compte root ;
- région ;
- IPv4 publique `/32` ;
- clé SSH ;
- budget ;
- synchronisation des trois `terraform.tfvars` ;
- contrôles AWS Ready.

Conditions de sortie :

```text
GO AWS
GO TERRAFORM
```

## Exercice 1

```bash
bash scripts/commands/p5.sh ex1
```

Le centre de commande construit l'artefact Angular si nécessaire, converge
Terraform, génère l'inventaire Ansible, déploie NGINX/Angular et rejoue le
playbook.

Résultat obligatoire du second passage :

```text
changed=0
unreachable=0
failed=0
```

Le vrai `access.log` NGINX est ensuite collecté pour l'exercice 2.

## Exercice 2

```bash
bash scripts/commands/p5.sh ex2
```

Deux sources de données peuvent être utilisées :

1. l'échantillon reproductible versionné ;
2. le vrai `access.log` de l'exercice 1.

Le dashboard et ses captures restent un checkpoint humain.

## Exercice 3

```bash
bash scripts/commands/p5.sh ex3
```

L'exercice 1 doit encore exister. Le parcours vérifie le round-robin, arrête un
backend de façon contrôlée, vérifie la continuité puis confirme sa réintégration.

## Mode `--yes`

```bash
bash scripts/commands/p5.sh all --yes
```

Ce mode ne contourne pas :

- les confirmations de sécurité AWS non automatisables ;
- le checkpoint OpenSearch Dashboards ;
- la confirmation `DETRUIRE`.

## Reprise après interruption

Après fermeture du terminal ou redémarrage Windows :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Terraform réévalue les états existants. Ne jamais supprimer un `terraform.tfstate`
pour forcer une reprise.

## Logs

```bash
bash scripts/commands/p5.sh logs
```

Organisation :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
└── ...
```

Les preuves pédagogiques restent sous `proofs/runtime/`.

## Finalisation

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Nettoyage AWS

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

## Backup de la workstation

Il n'appartient plus au P5. Utiliser la V7 de `Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
```

## Références

- [Préparation de l'environnement](00-preparation-environnement.md)
- [Architecture](architecture-et-flux.md)
- [Convergence](convergence-et-reexecution.md)
- [Troubleshooting](troubleshooting.md)
- [Validation et nettoyage](validation-preuves-nettoyage.md)
