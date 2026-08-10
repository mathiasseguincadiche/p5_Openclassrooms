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

L'objectif n'est pas simplement qu'une commande puisse être relancée sans erreur.
Une réexécution doit éviter les installations, écritures et appels de mutation
inutiles tout en revérifiant l'état fonctionnel réel.

## Observer sans modifier

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande inspecte notamment :

- version Ubuntu et socle DevOps ;
- présence/versions des outils ;
- configuration AWS locale ;
- session AWS lorsqu'elle est déjà active ;
- tfvars ;
- clés SSH ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs déjà présents.

Elle ne déclenche ni installation, ni connexion AWS interactive, ni `apply`, ni
destruction.

## VM Ubuntu

Le bootstrap possède deux comportements :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le premier observe uniquement. Le second installe ou corrige uniquement les
paquets/outils non conformes.

Le bootstrap compare :

- paquets APT obligatoires ;
- Terraform avec la version épinglée ;
- Docker Engine et Compose ;
- AWS CLI avec la version minimale requise ;
- Ansible Core avec la version épinglée ;
- NVM et Node.js ;
- `markdownlint-cli2`.

`apt full-upgrade` n'est pas exécuté implicitement. Une mise à niveau globale du
système doit être demandée explicitement avec `--upgrade-system`.

## AWS et authentification

`aws-auth.sh` tente d'abord de réutiliser une session temporaire valide. Il
renouvelle une session console ou SSO connue uniquement lorsqu'elle n'est plus
valide. Une nouvelle authentification n'est demandée que si aucune source
utilisable n'existe.

`configure-lab.sh` conserve les valeurs déjà valides, détecte le compte et l'IP,
crée la clé SSH seulement si elle manque, puis converge les tfvars.

## Budget AWS

Le garde-fou ne considère plus « le budget existe » comme une preuve suffisante.
Il compare :

- nom du budget ;
- limite mensuelle attendue ;
- alerte réelle à 50 % ;
- alerte réelle à 80 % ;
- alerte prévisionnelle à 100 % ;
- destinataire e-mail attendu.

Contrôle seul :

```bash
bash scripts/commands/setup-aws-guardrails.sh --check
```

Convergence :

```bash
bash scripts/commands/setup-aws-guardrails.sh --apply
```

Seuls les écarts sont corrigés. Les alertes supplémentaires ne sont pas supprimées
automatiquement.

## Terraform

Pour chaque exercice, `p5.sh` exécute un vrai `terraform plan` avec rafraîchissement
de l'état distant et `-detailed-exitcode`.

Les trois cas sont :

```text
code 0 → aucun delta → aucun apply
code 1 → erreur       → arrêt
code 2 → delta réel   → affichage + confirmation + apply du plan sauvegardé
```

Après un `apply`, un second plan doit revenir sans delta. Sinon l'étape échoue.

Ainsi une seconde exécution ne recrée pas les EC2, VPC, OpenSearch ou HAProxy :
Terraform compare d'abord l'état AWS réel avec la configuration attendue.

## Terraform tfvars

`sync-terraform-tfvars.sh --apply` construit d'abord le contenu attendu en mémoire.

- fichier absent/différent : écriture ;
- contenu identique mais permissions incorrectes : correction des permissions ;
- contenu et permissions conformes : aucune réécriture.

## Angular

Le script de préparation calcule des empreintes des sources, dépendances et de
l'artefact actuellement déployable.

- dépendances inchangées : `npm ci` ignoré ;
- sources + artefact inchangés : build ignoré ;
- build produit identique : artefact Ansible non réécrit ;
- différence détectée : seule la chaîne nécessaire est rejouée.

L'état local d'optimisation est stocké sous `.p5/`, qui est ignoré par Git.

## Ansible

Le playbook reste la source de convergence du serveur. Il peut être rejoué.

Le P5 exécute ensuite un deuxième passage et exige :

```text
changed=0
unreachable=0
failed=0
```

Le projet ne se contente donc pas d'un premier passage réussi : il prouve que la
configuration distante est stable.

## Inventaire Ansible

L'inventaire réel est construit depuis l'output Terraform. Il n'est réécrit que
si l'IP, l'utilisateur SSH ou la clé ont changé. Les permissions sont corrigées
indépendamment si nécessaire.

## OpenSearch

Le script compare le template distant avec le template attendu avant tout `PUT`.
Les logs sont convertis avec des IDs déterministes, puis le script vérifie les IDs
déjà présents avant l'import Bulk.

Si le template et tous les documents sont déjà présents :

```text
OPENSEARCH DÉJÀ CONFORME — AUCUNE MUTATION NÉCESSAIRE
```

Les agrégations sont néanmoins revérifiées afin de ne pas retourner un ancien
`OK` alors que l'état fonctionnel aurait changé.

## HAProxy et tests fonctionnels

Terraform ne modifie pas l'infrastructure si son plan est vide. En revanche, les
tests de round-robin et de failover peuvent être rejoués volontairement.

C'est une distinction importante :

- **installation/configuration persistante** → ne pas refaire si conforme ;
- **vérification fonctionnelle actuelle** → rejouer pour prouver que le service
  fonctionne encore maintenant.

Un test n'est donc pas considéré comme une réinstallation inutile.

## Nettoyage

`destroy-aws.sh` inspecte d'abord les trois états Terraform.

- aucun état : ignoré ;
- état vide : `destroy` ignoré ;
- ressources encore suivies : confirmation `DETRUIRE`, puis destruction dans
  l'ordre 3 → 2 → 1.

L'audit AWS final reste exécuté car il sert à détecter des ressources orphelines
ou hors état Terraform.

## Réexécution normale

La commande normale reste :

```bash
bash scripts/commands/p5.sh all
```

Au premier passage, elle peut installer/créer les éléments manquants. Aux passages
suivants, elle réobserve l'environnement et doit tendre vers des messages tels que :

```text
VM déjà convergée
Budget déjà conforme
terraform.tfvars déjà synchronisés
Infrastructure Terraform déjà conforme — aucun apply
Inventaire Ansible déjà conforme
Artefact Angular déjà conforme
OPENSEARCH DÉJÀ CONFORME
changed=0
```

Les vérifications fonctionnelles sont ensuite rejouées pour confirmer que cet
état « conforme » est toujours vrai au moment de l'exécution.

## Contrat CI

```bash
bash scripts/tests/test-convergence-contract.sh
```

Ce test verrouille notamment :

- l'existence des branches « déjà conforme → aucune mutation » ;
- deux exécutions tfvars sans réécriture au second passage ;
- la correction ciblée d'une dérive de permissions ;
- le support du plan Terraform différentiel ;
- la stabilité de la numérotation des logs.
