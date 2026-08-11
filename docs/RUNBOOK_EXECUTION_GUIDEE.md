# RUNBOOK P5 OpenClassrooms — Exécution guidée A → Z

> **But :** réaliser le P5 AWS depuis **Windows 11 Pro + WSL2 + Ubuntu 26.04**,
> comprendre chaque étape, conserver les preuves, diagnostiquer proprement les
> erreurs et terminer par le contrôle des livrables puis le nettoyage AWS.

## 1. Architecture à retenir

```text
Windows 11 Pro
└── WSL2
    ├── 6 processeurs logiques
    ├── 16 Go RAM
    ├── 8 Go swap
    ├── NAT + DNS tunneling
    └── p5-devops
        └── Ubuntu 26.04 + systemd
            ├── AWS CLI
            ├── Terraform
            ├── Ansible
            ├── Docker
            ├── Node.js / Angular
            └── p5.sh
                  │
                  ▼
                AWS
                ├── Exercice 1 : VPC + EC2 → Ansible → NGINX → Angular
                ├── Exercice 2 : Amazon OpenSearch ← logs NGINX
                └── Exercice 3 : HAProxy → Backend 1 + Backend 2
```

Le réseau WSL2 local et le réseau AWS sont distincts. Le VPC AWS reste
`10.0.0.0/16`. L'adresse privée WSL2 n'est pas utilisée comme CIDR
d'administration AWS.

## 2. Philosophie du dépôt

```text
INSPECTER
   ↓
COMPARER état réel ↔ état attendu
   ↓
ÉCART ?
 ├─ NON → aucune mutation
 └─ OUI → corriger uniquement le delta
   ↓
VÉRIFIER
   ↓
JOURNALISER
```

Les éléments persistants ne sont pas recréés inutilement. Les tests fonctionnels
peuvent en revanche être rejoués pour prouver que le système fonctionne encore
au moment de la démonstration.

# PHASE A — PRÉPARER WINDOWS 11 ET WSL2

## 3. Installer le socle WSL2

Depuis PowerShell **en tant qu'administrateur** :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Le script :

- exige Windows 11 ;
- met WSL à jour ;
- définit WSL2 comme version par défaut ;
- applique le profil 6 CPU / 16 Go / 8 Go swap ;
- configure NAT, DNS tunneling et firewall ;
- installe Ubuntu 26.04 sous le nom `p5-devops` si nécessaire ;
- refuse d'écraser une distribution déjà existante.

## 4. Premier lancement Ubuntu

```powershell
wsl -d p5-devops
```

Terminer la création de l'utilisateur Linux proposée par Ubuntu puis quitter :

```bash
exit
```

Configurer ensuite la distribution :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
```

Le résultat attendu comprend :

```text
hostname : p5-devops
PID 1    : systemd
```

## 5. Contrôler WSL2

```powershell
.\scripts\windows\check-wsl2-p5.ps1
```

Le contrôle vérifie notamment :

- noyau WSL2 ;
- au moins 6 processeurs disponibles ;
- environ 16 Go de RAM ;
- `systemd` ;
- hostname ;
- IPv4 WSL ;
- passerelle ;
- route par défaut ;
- DNS ;
- HTTPS vers Internet.

L'adresse WSL peut changer après un arrêt global ou un redémarrage Windows. C'est
normal : elle est détectée dynamiquement.

# PHASE B — INSTALLER LE SOCLE DEVOPS

## 6. Cloner le dépôt dans Linux

Depuis Ubuntu WSL2 :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Éviter d'exécuter le projet depuis `/mnt/c`. Le dépôt de travail doit rester dans
le VHDX Linux.

## 7. Installer les outils

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap converge notamment :

- paquets Linux ;
- Terraform ;
- Ansible Core ;
- AWS CLI ;
- Docker Engine + Compose ;
- NVM + Node.js ;
- outils de validation.

S'il affiche une reconnexion requise pour Docker ou NVM, quitter Ubuntu :

```bash
exit
```

Puis depuis PowerShell :

```powershell
.\scripts\windows\stop-p5.ps1
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Ne réinstallez pas manuellement tout le socle.

## 8. Contrôle complet du poste

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/setup.sh --check-only
```

Puis côté Windows :

```powershell
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

# PHASE C — INSPECTER LE LAB

## 9. Mettre le dépôt à jour

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
git pull
git status
```

## 10. Observer sans modifier

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` regarde notamment :

- Ubuntu et le socle DevOps ;
- Terraform ;
- Docker ;
- AWS CLI ;
- Ansible ;
- Node/NVM ;
- configuration AWS locale ;
- session AWS ;
- clés SSH ;
- tfvars ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs existants.

Il ne doit déclencher aucune installation, authentification interactive,
création AWS ou destruction.

# PHASE D — LANCER LE PARCOURS

## 11. Commandes principales

```bash
# Observer
bash scripts/commands/p5.sh inspect

# Préparer
bash scripts/commands/p5.sh prepare

# Contrôler
bash scripts/commands/p5.sh status

# Exercices
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3

# Parcours complet
bash scripts/commands/p5.sh all

# Finalisation
bash scripts/commands/p5.sh finalize

# Logs
bash scripts/commands/p5.sh logs

# Nettoyage final
bash scripts/commands/p5.sh cleanup
```

Pour la première exécution réelle, utiliser `all` sans `--yes` afin de voir les
plans Terraform et les validations humaines.

## 12. Parcours de `all`

```text
prepare
  ↓
ex1
  ↓
ex2
  ↓
ex3
  ↓
diagnostics
```

`all` ne détruit pas AWS.

# PHASE E — AWS READY

## 13. Authentification AWS

Le projet privilégie les credentials temporaires et refuse l'utilisation
quotidienne du compte root.

Une session valide est réutilisée. Si nécessaire, le flux peut utiliser :

```bash
aws login --remote
```

L'URL d'autorisation est ouverte dans le navigateur Windows. Les identifiants
restent saisis chez AWS et ne sont jamais transmis au dépôt.

Ne jamais partager :

- mot de passe AWS ;
- Access Key ;
- Secret Access Key ;
- token de session ;
- code MFA ;
- cookies.

## 14. Configuration du lab

La source locale est :

```text
environment/aws-readiness.env
```

Elle contient notamment :

- profil et région AWS ;
- compte attendu ;
- IPv4 publique `/32` ;
- clé SSH ;
- paramètres OpenSearch ;
- budget.

Les trois `terraform.tfvars` sont générés depuis cette source unique.

## 15. Porte AWS Ready

Résultats attendus :

```text
GO AWS
GO TERRAFORM
```

Si un `STOP AWS` ou `[ KO ]` apparaît, ne contournez pas le contrôle.

# PHASE F — EXERCICE 1

## 16. Lancer l'exercice

```bash
bash scripts/commands/p5.sh ex1
```

Le centre de commande :

1. prépare l'artefact Angular ;
2. lance Terraform ;
3. affiche le plan ;
4. applique uniquement si le plan contient un delta ;
5. génère l'inventaire Ansible ;
6. attend SSH et cloud-init ;
7. exécute le playbook ;
8. le rejoue ;
9. exige l'idempotence ;
10. vérifie Angular/NGINX ;
11. génère du trafic ;
12. collecte le vrai `access.log`.

Résultat obligatoire du second passage Ansible :

```text
changed=0
unreachable=0
failed=0
```

# PHASE G — EXERCICE 2

## 17. Lancer OpenSearch

```bash
bash scripts/commands/p5.sh ex2
```

Le parcours utilise :

- le jeu versionné reproductible ;
- le vrai log NGINX collecté pendant l'exercice 1.

La création du dashboard reste manuelle. Vérifier :

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 h ;
3. top 5 des `url_path` par tranches de 12 h.

Le checkpoint humain ne peut pas être contourné par `--yes`.

# PHASE H — EXERCICE 3

## 18. Lancer HAProxy

```bash
bash scripts/commands/p5.sh ex3
```

L'exercice 1 doit toujours exister.

Le scénario attendu est :

```text
Backend 1 OK + Backend 2 OK
          ↓
round-robin
          ↓
arrêt contrôlé d'un backend
          ↓
service toujours disponible
          ↓
redémarrage
          ↓
réintégration du backend
```

Ne jamais détruire l'exercice 1 avant l'exercice 3.

# PHASE I — ARRÊT ET REPRISE WSL2

## 19. Fermer seulement le terminal

Aucune donnée n'est perdue. Pour reprendre :

```powershell
wsl -d p5-devops
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

## 20. Arrêter la distribution

```powershell
.\scripts\windows\stop-p5.ps1
```

La distribution passe à l'état arrêté mais son VHDX et toutes les données sont
conservés.

Pour reprendre :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Puis dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

## 21. Après `wsl --shutdown` ou redémarrage Windows

Relancer simplement :

```powershell
.\scripts\windows\start-p5.ps1
.\scripts\windows\status-p5.ps1
wsl -d p5-devops
```

L'adresse IP WSL peut être différente. Ce changement ne nécessite aucune édition
manuelle du dépôt.

## 22. Règle absolue Terraform

Après une interruption :

```bash
bash scripts/commands/p5.sh all
```

Ne jamais supprimer un `terraform.tfstate` pour « recommencer ». Terraform doit
réévaluer les ressources déjà existantes.

# PHASE J — SAUVEGARDE ET RESTAURATION WSL2

## 23. Créer une sauvegarde

Avant une étape importante :

```powershell
.\scripts\windows\backup-p5.ps1
```

Le script :

1. arrête proprement `p5-devops` ;
2. exporte la distribution en VHDX ;
3. calcule le SHA-256 ;
4. conserve l'original intact.

Les fichiers VHDX sont ignorés par Git.

## 24. Restaurer une sauvegarde

```powershell
.\scripts\windows\restore-p5.ps1 -BackupPath <fichier.vhdx>
```

La restauration utilise un nouveau nom et refuse d'écraser une distribution
existante.

Après restauration, contrôler :

```powershell
.\scripts\windows\status-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

# PHASE K — LOGS ET DIAGNOSTIC

## 25. Retrouver les logs P5

```bash
bash scripts/commands/p5.sh logs
```

Organisation :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Pour un diagnostic Linux partageable :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Pour un diagnostic WSL2 :

```powershell
.\scripts\windows\status-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

En cas d'échec, conserver :

1. la commande lancée ;
2. le premier message `[ KO ]` ou l'erreur ;
3. le nom de l'étape ;
4. le log complet correspondant ;
5. si le problème est local, la sortie de `check-wsl2-p5.ps1`.

# PHASE L — FINALISATION

## 26. Finaliser les livrables

Après les captures et preuves réelles :

```bash
bash scripts/commands/p5.sh finalize
```

Résultat attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

# PHASE M — NETTOYAGE AWS

## 27. Détruire uniquement à la fin

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La destruction réelle nécessite la saisie :

```text
DETRUIRE
```

Résultat final :

```text
NETTOYAGE AWS COMPLET
```

Le nettoyage AWS ne supprime pas la distribution WSL2.

# PHASE N — CHECKLIST FINALE

- [ ] Windows 11 Pro + WSL2 validés ;
- [ ] `p5-devops` sous Ubuntu 26.04 validé ;
- [ ] 6 CPU / 16 Go visibles ;
- [ ] systemd, NAT, route et DNS validés ;
- [ ] socle DevOps complet ;
- [ ] `p5.sh all` exécuté sur AWS réel ;
- [ ] idempotence Ansible `changed=0` ;
- [ ] logs NGINX réels collectés ;
- [ ] OpenSearch et visualisations validés ;
- [ ] HAProxy round-robin, panne et reprise validés ;
- [ ] `p5.sh finalize` réussi ;
- [ ] sauvegarde WSL2 créée si souhaitée ;
- [ ] AWS nettoyé avec `NETTOYAGE AWS COMPLET`.

## Références

- [Préparation Windows 11 + WSL2](00-preparation-environnement.md)
- [Guide WSL2](../environment/wsl2/README.md)
- [Parcours de bout en bout](01-parcours-debutant.md)
- [Architecture](architecture-et-flux.md)
- [Convergence et reprise](convergence-et-reexecution.md)
- [Troubleshooting](troubleshooting.md)
