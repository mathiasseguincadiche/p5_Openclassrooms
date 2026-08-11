# Convergence et réexécution intelligente

Le P5 suit cette règle pour les éléments qu'il **possède** :

```text
INSPECTER
   ↓
COMPARER état réel ↔ état attendu
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

## Frontière avec la workstation

La plateforme Windows/WSL2 est gérée par
`mathiasseguincadiche/Windows_11_Pro_Custom`.

P5 **ne converge pas** :

- Windows 11 Pro ;
- WSL2 ;
- `%UserProfile%\.wslconfig` ;
- `/etc/wsl.conf` ;
- la distribution `Ubuntu` ;
- le chemin `D:\WSL\Ubuntu-DevOps` ;
- les profils `standard`, `lab-heavy`, `nat-fallback` ;
- le VHDX et la sauvegarde de la workstation.

P5 considère la validation amont suivante comme un prérequis :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

## Observer P5 sans modifier

Dans la distribution `Ubuntu` :

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande inspecte notamment :

- Ubuntu et les outils requis par P5 ;
- configuration AWS locale ;
- session AWS existante ;
- tfvars ;
- clés SSH ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs.

Elle ne déclenche ni installation, ni connexion interactive, ni `apply`, ni
destruction.

## Compatibilité du socle Linux

La workstation amont installe déjà une stack DevOps générale. P5 conserve un
contrat de versions et de capacités propres au projet.

Contrôle seul :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Convergence du delta P5 uniquement :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Un composant déjà conforme est réutilisé. Le bootstrap ne doit jamais devenir un
second installateur WSL2.

## AWS et authentification

`aws-auth.sh` tente d'abord de réutiliser une session temporaire valide. Une
nouvelle authentification n'est demandée que si aucune session utilisable
n'existe.

`configure-lab.sh` conserve les valeurs valides, détecte le compte et l'IPv4
publique, crée la clé SSH seulement si elle manque puis converge les tfvars.

## Budget AWS

Le garde-fou compare le budget réel à la cible : montant, alertes et destinataire.

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

Pour chaque exercice, `p5.sh` utilise un plan différentiel :

```text
code 0 → aucun delta → aucun apply
code 1 → erreur       → arrêt
code 2 → delta réel   → affichage + confirmation + apply
```

Après un `apply`, un nouveau plan doit revenir sans delta.

Une seconde exécution ne recrée donc pas les EC2, le VPC, OpenSearch ou HAProxy si
Terraform constate que l'état AWS est déjà conforme.

## Terraform tfvars

`sync-terraform-tfvars.sh --apply` construit le contenu attendu avant écriture :

- fichier absent ou différent → écriture ;
- permissions seules incorrectes → correction des permissions ;
- contenu et permissions conformes → aucune réécriture.

## Angular

Le script de préparation compare sources, dépendances et artefact :

- dépendances inchangées → pas de `npm ci` inutile ;
- sources et artefact inchangés → build ignoré ;
- différence détectée → seule la chaîne nécessaire est rejouée.

## Ansible

Le playbook est rejoué et doit prouver :

```text
changed=0
unreachable=0
failed=0
```

Le premier passage configure ; le second prouve la stabilité de la cible.

## OpenSearch

Le script compare le template distant et les documents déjà présents avant les
mutations. Les agrégations restent rejouées pour confirmer l'état fonctionnel
actuel.

## HAProxy

Terraform ne modifie rien sur plan vide. En revanche, les tests round-robin et
failover sont volontairement rejoués : ce sont des preuves fonctionnelles, pas
des réinstallations.

## Nettoyage

`destroy-aws.sh` inspecte les trois états Terraform avant destruction.

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La destruction réelle reste protégée par `DETRUIRE`.

## Réexécution normale

Après interruption :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Le projet réobserve l'environnement et l'état AWS au lieu de repartir de zéro.

## Sauvegarde

La convergence et la sauvegarde de WSL2 ne relèvent plus du P5. La V7 de
`Windows_11_Pro_Custom` est la source de vérité pour l'image Windows et l'export
Ubuntu VHDX.

## Contrat CI

```bash
bash scripts/tests/test-convergence-contract.sh
```

Ce test protège les branches « déjà conforme → aucune mutation » du P5. Un
contrat CI séparé protège désormais la frontière avec la workstation amont afin
d'empêcher la réintroduction d'un installateur WSL2 dans ce dépôt.
