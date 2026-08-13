# RUNBOOK P5 OpenClassrooms — Exécution guidée A → Z

> **But :** exécuter le P5 AWS depuis la workstation Windows 11 Pro / WSL2 déjà
> construite par `Windows_11_Pro_Custom`, sans dupliquer l'installation ou la
> configuration WSL2.

## Comment utiliser ce Runbook

Ce document est la **procédure opératoire**. Pour une découverte plus douce,
commencer par [01-parcours-debutant.md](01-parcours-debutant.md). Pour utiliser le
menu interactif, consulter [CENTRE_DE_COMMANDE.md](CENTRE_DE_COMMANDE.md).

À chaque phase, appliquer la même méthode :

```text
OBJECTIF
   ↓
PRÉREQUIS
   ↓
COMMANDE
   ↓
VÉRIFIER CE QUI PEUT ÊTRE MODIFIÉ
   ↓
EXÉCUTER
   ↓
LIRE LE VERDICT
   ↓
SI KO : LOGS + INSPECT, PAS DE SUPPRESSION IMPROVISÉE
```

Le Control Center V11 est accessible avec :

```bash
bash scripts/commands/p5.sh
```

Il indique avant les actions principales si une mutation locale, une mutation AWS
ou un coût AWS est possible. La CLI reste la source de vérité technique.

## Carte des risques

| Phase | Commande | Mutation locale | Mutation AWS | Coût possible |
| --- | --- | --- | --- | --- |
| Observation | `p5.sh inspect` | non | non | non |
| Préparation | `p5.sh prepare` | si delta | possible | possible |
| Vérification | `p5.sh status` | non | non destructif | non |
| Exercice 1 | `p5.sh ex1` | oui | oui | oui |
| Exercice 2 | `p5.sh ex2` | oui | oui | oui |
| Exercice 3 | `p5.sh ex3` | oui | oui | oui |
| Parcours complet | `p5.sh all` | oui | oui | oui |
| Diagnostic | `p5.sh diagnostics` | journaux/preuves | non | non |
| Finalisation | `p5.sh finalize` | preuves/livrables | non | non |
| Nettoyage | `p5.sh cleanup` | oui | destruction | arrête les coûts |

## 1. Modèle à retenir

```text
Windows_11_Pro_Custom
└── Windows 11 Pro + WSL2
    └── Ubuntu — D:\WSL\Ubuntu-DevOps
        └── stack DevOps générale
                │
                ▼
p5_Openclassrooms
└── contrat projet + AWS + exercices + preuves
```

La workstation est une **dépendance amont**, pas un sous-projet géré par P5.

## 2. Ce que P5 ne fait plus

P5 ne doit jamais :

- installer ou mettre à jour WSL2 ;
- créer une distribution WSL ;
- écrire `%UserProfile%\.wslconfig` ;
- écrire `/etc/wsl.conf` ;
- choisir le chemin du VHDX ou du swap WSL ;
- créer une sauvegarde Windows/WSL concurrente.

Ces responsabilités appartiennent à `Windows_11_Pro_Custom`.

# PHASE A — QUALIFIER LA WORKSTATION

## 3. Objectif

Prouver que la plateforme Windows/WSL2 fournie en amont est prête avant de faire
porter au P5 des problèmes qui ne lui appartiennent pas.

## 4. Vérifier la plateforme amont

Dans le dépôt `Windows_11_Pro_Custom`, PowerShell administrateur :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Verdicts attendus :

```text
VERDICT: V3 DEVOPS READY
VERDICT: V6 WSL2 PLATFORM READY
```

Si l'un de ces verdicts échoue, arrêter ici et corriger la workstation dans le
dépôt amont.

## 5. Profils WSL2 disponibles

La source de vérité amont propose :

```text
standard     → 8 threads / 20 Go / 8 Go swap / mirrored
lab-heavy    → 12 threads / 28 Go / 12 Go swap / mirrored
nat-fallback → 8 threads / 20 Go / 8 Go swap / NAT
```

`standard` est recommandé pour le P5.

## 6. Ouvrir Ubuntu

```powershell
wsl -d Ubuntu
```

Dans Ubuntu :

```bash
ps -p 1 -o comm=
findmnt -T "$HOME" -n -o FSTYPE
```

Attendu : `systemd` et un HOME sur filesystem Linux.

### Si cette phase échoue

Ne pas modifier le P5 pour contourner un problème WSL2. Revenir dans
`Windows_11_Pro_Custom` et corriger la plateforme amont.

# PHASE B — PRÉPARER P5

## 7. Mettre le dépôt P5 à disposition

Clone neuf :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Dépôt existant :

```bash
cd ~/labs/p5_Openclassrooms
git pull
git status
```

Ne pas travailler sous `/mnt/c` ou `/mnt/d`.

## 8. Vérifier le delta projet

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Ce contrôle vérifie les exigences P5 sans modifier la workstation.

Si un composant est absent ou incompatible :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap reste convergent : un outil déjà conforme n'est pas réinstallé.

S'il ajoute l'utilisateur au groupe Docker :

```powershell
wsl --shutdown
wsl -d Ubuntu
```

Puis revenir dans le dépôt et relancer `--check-only`.

## 9. Inspecter le P5

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` doit rester sans mutation : aucune installation, aucune authentification
interactive, aucun `terraform apply`, aucune création ou destruction AWS.

### Verdict opérationnel

Si l'inspection ne montre pas de blocage amont, continuer avec `prepare`.

### Si cette phase échoue

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis consulter [troubleshooting.md](troubleshooting.md).

# PHASE C — PRÉPARATION AWS

## 10. Préparer le lab

Commande explicite :

```bash
bash scripts/commands/p5.sh prepare
```

Ou parcours complet :

```bash
bash scripts/commands/p5.sh all
```

Le centre de commande complet enchaîne :

```text
prepare → ex1 → ex2 → ex3 → diagnostics
```

Le mode `all` ne détruit pas AWS.

## 11. Configuration locale

La source locale des paramètres AWS est :

```text
environment/aws-readiness.env
```

Si elle n'existe pas :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Cette configuration centralise profil, région, compte, IPv4 publique `/32`, clé
SSH, OpenSearch, quotas et budget.

`P5_PUBLIC_IP_CIDR` est l'IPv4 publique vue depuis AWS. Elle n'est pas liée à
l'adresse privée WSL2 ni au choix `mirrored`/NAT.

## 12. Porte AWS Ready

Le parcours doit atteindre :

```text
GO AWS
GO TERRAFORM
```

Ne jamais contourner `STOP AWS` ou un `[ KO ]`.

### Si cette phase échoue

1. ne lancer aucun `terraform apply` manuel pour contourner le contrôle ;
2. exécuter `p5.sh inspect` ;
3. consulter `p5.sh logs` ;
4. corriger uniquement l'information ou permission explicitement signalée ;
5. relancer `p5.sh prepare`.

# PHASE D — EXERCICE 1

## 13. Objectif

Converger l'infrastructure, déployer Angular derrière NGINX avec Ansible et
prouver l'idempotence.

## 14. Exécuter

```bash
bash scripts/commands/p5.sh ex1
```

Le parcours :

1. prépare l'artefact Angular si nécessaire ;
2. lance Terraform `init` puis `plan -detailed-exitcode` ;
3. n'applique rien sur plan vide ;
4. crée/converge l'infrastructure après confirmation si delta ;
5. génère l'inventaire Ansible ;
6. attend SSH et cloud-init ;
7. exécute Ansible ;
8. rejoue le playbook ;
9. exige `changed=0`, `unreachable=0`, `failed=0` ;
10. vérifie Angular/NGINX ;
11. collecte le vrai `access.log`.

Résultat attendu :

```text
changed=0
unreachable=0
failed=0
```

### Si cette phase échoue

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
```

Ne pas supprimer le state. Corriger le delta indiqué, puis relancer exactement :

```bash
bash scripts/commands/p5.sh ex1
```

# PHASE E — EXERCICE 2

## 15. Objectif

Converger Amazon OpenSearch, importer les données et produire les preuves
fonctionnelles attendues.

## 16. OpenSearch

```bash
bash scripts/commands/p5.sh ex2
```

Le parcours converge Amazon OpenSearch, importe le jeu reproductible et le vrai
log NGINX lorsqu'il est disponible, puis vérifie mappings et agrégations.

Le dashboard et les captures restent manuels.

### Checkpoint humain

Ne pas valider `OK` sans avoir réellement vérifié/créé les visualisations et
conservé les captures demandées.

### Si cette phase échoue

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Vérifier ensuite la section OpenSearch de `troubleshooting.md` avant toute
modification manuelle.

# PHASE F — EXERCICE 3

## 17. Objectif

Prouver la distribution du trafic et la continuité de service lors d'une panne
contrôlée d'un backend.

## 18. HAProxy

```bash
bash scripts/commands/p5.sh ex3
```

Prérequis : l'exercice 1 doit toujours exister.

Le test vérifie :

- HAProxy accessible ;
- deux backends ;
- round-robin ;
- panne réelle contrôlée ;
- continuité du service ;
- réintégration du backend.

### Si cette phase échoue

Ne pas détruire l'exercice 1. Consulter les logs de l'étape HAProxy puis relancer
`ex3` après correction du delta.

# PHASE G — REPRISE ET DIAGNOSTIC

## 19. Après fermeture du terminal ou redémarrage Windows

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

Le projet réévalue l'état réel. Ne jamais supprimer un `terraform.tfstate` pour
forcer une reprise.

## 20. Logs

```bash
bash scripts/commands/p5.sh logs
```

Pour un diagnostic partageable :

```bash
bash scripts/commands/p5.sh diagnostics
```

Équivalent spécialisé :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Si le problème concerne WSL2, le profil réseau, Docker système ou la workstation,
retourner dans `Windows_11_Pro_Custom` et exécuter sa validation.

## 21. Arbre de diagnostic recommandé

```text
problème
   ↓
p5.sh inspect
   ↓
p5.sh logs
   ↓
p5.sh diagnostics
   ↓
troubleshooting.md
   ↓
corriger uniquement le delta identifié
   ↓
relancer la même commande
```

# PHASE H — FINALISATION

## 22. Vérifier les livrables

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Si le verdict n'est pas obtenu, compléter uniquement les preuves/captures
signalées et relancer `finalize`.

## 23. Nettoyer AWS

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La confirmation forte `DETRUIRE` reste obligatoire.

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, ne pas supposer que tous les coûts P5 ont
cessé.

# PHASE I — BACKUP DE LA WORKSTATION

## 24. Sauvegarde hors P5

La sauvegarde Windows/WSL2 est gérée uniquement par la V7 de
`Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
.\install.ps1 -BackupAction RestorePlan -BackupTargetDrive E:
```

P5 n'exporte plus de VHDX et ne restaure plus de distribution WSL.

## Checklist finale

- [ ] workstation V3 DevOps READY ;
- [ ] workstation V6 WSL2 PLATFORM READY ;
- [ ] `bootstrap-ubuntu-server.sh --check-only` conforme ;
- [ ] `p5.sh inspect` relu avant mutation ;
- [ ] `p5.sh all` exécuté sur AWS réel ;
- [ ] idempotence Ansible prouvée ;
- [ ] logs NGINX collectés ;
- [ ] OpenSearch et dashboard validés ;
- [ ] HAProxy panne/reprise validé ;
- [ ] `p5.sh finalize` sans élément bloquant ;
- [ ] livrables contrôlés ;
- [ ] AWS nettoyé avec `NETTOYAGE AWS COMPLET`.
