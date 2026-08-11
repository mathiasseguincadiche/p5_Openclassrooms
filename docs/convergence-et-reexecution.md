# Convergence et réexécution intelligente

Le P5 suit une règle commune pour les éléments persistants :

```text
INSPECTER
   ↓
COMPARER état actuel ↔ état attendu
   ↓
aucun écart ? ── oui ──► NE RIEN MODIFIER
   │
   non
   ↓
CORRIGER UNIQUEMENT LE DELTA
   ↓
VÉRIFIER À NOUVEAU
   ↓
JOURNALISER LE VERDICT
```

Cette logique couvre désormais deux niveaux distincts :

1. **Windows 11 / WSL2** pour le poste de contrôle local ;
2. **Ubuntu + AWS** pour le socle DevOps et les ressources évaluées.

## WSL2

La configuration globale attendue est définie dans :

```text
environment/wsl2/.wslconfig.example
```

Cible :

```text
6 processeurs logiques
16 Go RAM
8 Go swap
NAT
DNS tunneling
firewall WSL/Hyper-V
```

La configuration de la distribution est définie dans :

```text
environment/wsl2/wsl.conf.example
```

avec notamment :

```text
systemd=true
hostname=p5-devops
```

Les scripts Windows sont réexécutables :

```powershell
.\scripts\windows\install-wsl2-p5.ps1
.\scripts\windows\configure-wsl2-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

Une distribution existante n'est pas supprimée ni recréée automatiquement.

## Réseau WSL2

Le mode retenu est NAT. L'IPv4 privée WSL2 n'est pas une donnée stable du projet.
Elle est détectée au runtime avec :

```powershell
wsl -d p5-devops hostname -I
```

Le projet vérifie également la passerelle, la route par défaut et la résolution
DNS. Une nouvelle IPv4 après `wsl --shutdown` ou un redémarrage Windows n'est pas
considérée comme une dérive nécessitant une modification du dépôt.

`P5_PUBLIC_IP_CIDR` reste l'IPv4 publique `/32` visible depuis AWS. Elle est
indépendante de l'adresse NAT WSL2.

## Démarrage et arrêt

L'arrêt de `p5-devops` est persistant :

```powershell
.\scripts\windows\stop-p5.ps1
```

La reprise s'effectue avec :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Aucun paquet, dépôt, état Terraform ou fichier utilisateur n'est perdu lors d'un
arrêt normal de la distribution.

## Sauvegarde et restauration

La sauvegarde complète est volontairement explicite :

```powershell
.\scripts\windows\backup-p5.ps1
```

Elle produit un VHDX et son SHA-256.

La restauration :

```powershell
.\scripts\windows\restore-p5.ps1 -BackupPath <fichier.vhdx>
```

est non destructive : elle refuse d'écraser une distribution existante.

## Observer le socle Linux sans modifier

Dans Ubuntu WSL2 :

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande inspecte notamment :

- version Ubuntu ;
- présence et versions des outils ;
- Docker ;
- configuration AWS locale ;
- session AWS lorsqu'elle est active ;
- tfvars ;
- clés SSH ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs existants.

Elle ne déclenche ni installation, ni connexion AWS interactive, ni `apply`, ni
destruction.

## Bootstrap Ubuntu

Deux comportements sont disponibles :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le premier observe uniquement. Le second installe ou corrige seulement les
paquets et outils non conformes.

Le bootstrap compare notamment :

- paquets APT ;
- Terraform ;
- Docker Engine et Compose ;
- AWS CLI ;
- Ansible Core ;
- NVM et Node.js ;
- `markdownlint-cli2`.

Si l'appartenance au groupe Docker ou l'environnement NVM exige une nouvelle
session, il suffit d'arrêter puis relancer `p5-devops` :

```powershell
.\scripts\windows\stop-p5.ps1
.\scripts\windows\start-p5.ps1
```

## AWS et authentification

Le projet tente d'abord de réutiliser une session temporaire valide. Une nouvelle
authentification n'est demandée que si aucune source utilisable n'existe.

La configuration locale conserve les valeurs valides, détecte l'IPv4 publique,
crée la clé SSH uniquement si nécessaire puis converge les tfvars.

## Budget AWS

Le garde-fou compare :

- nom du budget ;
- limite mensuelle ;
- alertes 50 %, 80 % et 100 % ;
- destinataire.

Contrôle :

```bash
bash scripts/commands/setup-aws-guardrails.sh --check
```

Convergence :

```bash
bash scripts/commands/setup-aws-guardrails.sh --apply
```

Seuls les écarts sont corrigés.

## Terraform

Pour chaque exercice, `p5.sh` utilise un vrai plan différentiel :

```text
code 0 → aucun delta → aucun apply
code 1 → erreur       → arrêt
code 2 → delta réel   → affichage + confirmation + apply
```

Après `apply`, un nouveau plan doit revenir sans delta.

Une seconde exécution ne recrée donc pas inutilement VPC, EC2, OpenSearch ou
HAProxy.

## Terraform tfvars

`sync-terraform-tfvars.sh --apply` compare d'abord le contenu attendu :

- absent ou différent → écriture ;
- contenu identique mais permissions incorrectes → permissions corrigées ;
- contenu et permissions conformes → aucune réécriture.

## Angular

Le script de préparation compare les sources, dépendances et artefacts :

- dépendances inchangées → `npm ci` ignoré ;
- sources et artefact inchangés → build ignoré ;
- build identique → artefact Ansible non réécrit.

## Ansible

Le second passage doit produire :

```text
changed=0
unreachable=0
failed=0
```

Le projet prouve ainsi que la configuration distante est stable.

## OpenSearch

Le template distant est comparé au template attendu. Les documents utilisent des
IDs déterministes et les IDs présents sont vérifiés avant import Bulk.

Si tout est déjà présent, aucune mutation d'import n'est nécessaire ; les
agrégations sont néanmoins revérifiées.

## HAProxy et tests fonctionnels

Terraform ne modifie pas l'infrastructure lorsque son plan est vide. Les tests de
round-robin et de failover sont en revanche rejouables pour prouver l'état
fonctionnel actuel.

La distinction reste :

- **état persistant conforme** → ne pas refaire ;
- **preuve fonctionnelle actuelle** → rejouer lorsque nécessaire.

## Reprise normale après interruption

Après fermeture de terminal, arrêt WSL2 ou redémarrage Windows :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Terraform réévalue l'état AWS réel. Ne jamais supprimer un `terraform.tfstate`
pour forcer une reprise.

## Nettoyage

Le nettoyage AWS inspecte les états Terraform et détruit dans l'ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Le nettoyage AWS n'arrête ni ne supprime WSL2. La distribution reste disponible
pour les preuves, archives ou autres travaux après suppression des ressources AWS.

## Contrats CI

Le modèle de convergence est protégé notamment par :

```bash
bash scripts/tests/test-convergence-contract.sh
```

et le contrat WSL2 par :

```text
.github/workflows/wsl2-contract.yml
```

La CI vérifie notamment le profil 6 CPU / 16 Go, la présence des scripts Windows,
le parsing PowerShell et l'absence des anciennes instructions KVM dans le parcours
canonique.
