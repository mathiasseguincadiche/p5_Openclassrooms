# RUNBOOK P5 OpenClassrooms — Exécution guidée A → Z

> **But :** exécuter, reprendre, diagnostiquer et fermer proprement le lab P5 AWS.

Ce Runbook est la **procédure opératoire** du projet. Il suppose que le poste de
contrôle est déjà disponible.

Pour comprendre les concepts avant d'exécuter les commandes, lire :
[01-parcours-debutant.md](01-parcours-debutant.md).

Pour installer ou réparer Windows 11 / WSL2 / Ubuntu, utiliser uniquement :
[00-preparation-environnement.md](00-preparation-environnement.md).

## 1. Résultat attendu

Le parcours P5 doit démontrer :

```text
Exercice 1
Terraform → AWS → Ansible → NGINX → Angular
                     ↓
              idempotence Ansible
                     ↓
                 access.log
                     │
                     ├────────────► Exercice 2
                     │              OpenSearch
                     │
                     └────────────► Exercice 3
                                    réseau AWS réutilisé
                                    HAProxy + 2 backends
```

Puis :

```text
preuves
   ↓
finalisation
   ↓
destruction 3 → 2 → 1
   ↓
NETTOYAGE AWS COMPLET
```

## 2. Règle opératoire

À chaque phase :

```text
OBJECTIF
   ↓
OBSERVER
   ↓
VÉRIFIER LES PRÉREQUIS
   ↓
EXÉCUTER
   ↓
LIRE LE VERDICT
   ↓
SI KO : LOGS + DIAGNOSTIC
   ↓
CORRIGER UNIQUEMENT LA CAUSE
   ↓
RELANCER LA MÊME COMMANDE
```

Ne supprimez pas un état Terraform, une ressource AWS ou un fichier runtime pour
« repartir proprement » sans avoir identifié la cause.

## 3. Carte des commandes et des risques

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

Le Control Center V11 affiche ces informations avant les actions importantes :

```bash
bash scripts/commands/p5.sh
```

# PHASE A — OUVRIR ET QUALIFIER LE P5

## 4. Ouvrir l'environnement de contrôle

Depuis Windows :

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

Le checkout principal doit rester dans le filesystem Linux, pas sous `/mnt/c` ou
`/mnt/d`.

Si `wsl -d Ubuntu` ne fonctionne pas ou si la toolchain générale de la workstation
est absente, corrigez d'abord le poste de contrôle avec le guide d'installation.

## 5. Vérifier le contrat spécifique P5

Sans mutation :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Ce contrôle vérifie les outils et versions attendus par le P5.

Si un delta propre au projet existe :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap ne doit corriger que le delta P5.

Après un éventuel ajout au groupe Docker :

```powershell
wsl --shutdown
wsl -d Ubuntu
```

Puis revenez dans le dépôt et relancez `--check-only`.

## 6. Observer l'état réel

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` ne doit créer ni modifier de ressource AWS.

Relisez notamment :

- état de la toolchain ;
- présence de la configuration locale AWS ;
- session AWS ;
- clé SSH ;
- états Terraform existants ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs existants.

### Si cette phase échoue

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis consultez [Troubleshooting](troubleshooting.md).

# PHASE B — PRÉPARER AWS

## 7. Préparer le lab

```bash
bash scripts/commands/p5.sh prepare
```

Cette phase :

1. inspecte d'abord le lab ;
2. vérifie/converge le contrat P5 local ;
3. réconcilie la configuration AWS ;
4. vérifie le budget ;
5. synchronise les trois `terraform.tfvars` ;
6. lance les contrôles AWS nécessaires.

## 8. Configuration locale AWS

La source locale est :

```text
environment/aws-readiness.env
```

Si elle n'existe pas :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Cette configuration centralise notamment :

- profil AWS ;
- région ;
- compte AWS attendu ;
- IPv4 publique `/32` ;
- clé SSH ;
- paramètres OpenSearch ;
- quotas ;
- budget.

`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique d'administration vue depuis AWS.

## 9. Portes de validation

Avant Terraform, le parcours doit atteindre :

```text
GO AWS
GO TERRAFORM
```

Ne contournez jamais un `STOP AWS` ou un `[ KO ]` par un `terraform apply`
manuellement lancé à côté de l'orchestrateur.

### Si la préparation échoue

1. exécutez `p5.sh inspect` ;
2. consultez `p5.sh logs` ;
3. corrigez l'information, la permission ou le quota explicitement signalé ;
4. relancez `p5.sh prepare`.

# PHASE C — EXERCICE 1

## 10. Objectif

Créer/converger l'infrastructure AWS, déployer Angular derrière NGINX avec
Ansible et prouver l'idempotence.

## 11. Exécuter

```bash
bash scripts/commands/p5.sh ex1
```

Le parcours réalise :

1. préparation de l'artefact Angular si nécessaire ;
2. `terraform init` ;
3. `terraform plan -detailed-exitcode` ;
4. affichage du plan ;
5. aucun `apply` si le plan est vide ;
6. confirmation puis application du delta s'il existe ;
7. post-plan pour vérifier la convergence ;
8. génération de l'inventaire Ansible ;
9. attente SSH et cloud-init ;
10. premier passage Ansible ;
11. second passage Ansible ;
12. contrôle HTTP de NGINX/Angular ;
13. génération de trafic ;
14. collecte du vrai `access.log`.

## 12. Verdict Ansible

Le second passage doit se terminer avec :

```text
changed=0
unreachable=0
failed=0
```

Si `changed` reste supérieur à zéro, l'idempotence n'est pas démontrée.

## 13. Si l'exercice 1 échoue

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
```

Ne supprimez pas le `terraform.tfstate`.

Corrigez le delta identifié puis relancez :

```bash
bash scripts/commands/p5.sh ex1
```

# PHASE D — EXERCICE 2

## 14. Objectif

Créer/converger Amazon OpenSearch, importer les données et produire les contrôles
techniques nécessaires au dashboard.

## 15. Exécuter

```bash
bash scripts/commands/p5.sh ex2
```

Le parcours :

1. fait converger le domaine Amazon OpenSearch ;
2. prépare le jeu de données reproductible ;
3. utilise le vrai log NGINX de l'exercice 1 lorsqu'il est disponible ;
4. importe les documents avec la Bulk API ;
5. vérifie les mappings ;
6. vérifie le nombre de documents ;
7. vérifie les agrégations attendues.

## 16. Checkpoint humain Dashboards

Les visualisations et captures ne doivent pas être déclarées conformes sans les
avoir réellement vérifiées.

Le dépôt attend notamment les visualisations définies dans le guide de
l'exercice 2.

Guide : [Exercice 2 — OpenSearch](exercices/02-elk-opensearch.md).

## 17. Si l'exercice 2 échoue

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis consultez la section OpenSearch de
[troubleshooting.md](troubleshooting.md).

# PHASE E — EXERCICE 3

## 18. Objectif

Démontrer la distribution du trafic et la continuité de service lors d'une panne
contrôlée d'un backend.

## 19. Prérequis

L'exercice 1 doit encore exister car l'exercice 3 réutilise :

- le VPC ;
- les sous-réseaux publics ;
- la paire de clés EC2.

## 20. Exécuter

```bash
bash scripts/commands/p5.sh ex3
```

Le test doit vérifier :

- HAProxy accessible ;
- deux backends ;
- round-robin ;
- panne réelle contrôlée ;
- continuité du service ;
- restauration ;
- réintégration du backend.

## 21. Si l'exercice 3 échoue

Ne détruisez pas l'exercice 1.

Consultez les logs HAProxy, corrigez la cause puis relancez :

```bash
bash scripts/commands/p5.sh ex3
```

# PHASE F — PARCOURS COMPLET

## 22. Exécuter de bout en bout

```bash
bash scripts/commands/p5.sh all
```

Enchaînement :

```text
prepare → ex1 → ex2 → ex3 → diagnostics
```

Le mode `all` ne détruit pas AWS.

## 23. Mode `--yes`

```bash
bash scripts/commands/p5.sh all --yes
```

Ce mode ne contourne jamais :

- les validations humaines de sécurité ;
- le checkpoint OpenSearch Dashboards ;
- la confirmation `DETRUIRE`.

# PHASE G — REPRISE ET DIAGNOSTIC

## 24. Reprendre après une interruption

Après fermeture du terminal ou redémarrage :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

Le projet réévalue l'état réel au lieu de repartir de zéro.

## 25. Journaux

```bash
bash scripts/commands/p5.sh logs
```

Chaque exécution crée des journaux persistants sous :

```text
logs/<UTC>/
```

## 26. Diagnostic complet

```bash
bash scripts/commands/p5.sh diagnostics
```

Équivalent spécialisé :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Le diagnostic doit rester non destructif côté AWS.

## 27. Arbre de diagnostic

```text
problème
   ↓
inspect
   ↓
logs
   ↓
diagnostics
   ↓
troubleshooting.md
   ↓
corriger uniquement le delta identifié
   ↓
relancer la même commande
```

Si le problème concerne l'installation WSL2 ou la workstation elle-même, sortez
du périmètre P5 et utilisez le guide d'environnement dédié.

# PHASE H — PREUVES ET FINALISATION

## 28. Contrôler les preuves

Avant la soutenance :

```bash
bash scripts/commands/p5.sh diagnostics
```

Relisez ensuite la matrice :

[Correspondance consignes → implémentation → preuve](02-correspondance-consignes-depot.md).

La présence d'un fichier dans Git ne remplace jamais une preuve AWS réelle.

## 29. Finaliser

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Si ce verdict n'est pas obtenu, complétez uniquement les éléments signalés puis
relancez `finalize`.

# PHASE I — NETTOYAGE AWS

## 30. Quand nettoyer ?

Uniquement après :

- collecte des preuves ;
- validation du dashboard ;
- test HAProxy terminé ;
- captures réalisées ;
- livrables contrôlés.

## 31. Détruire proprement

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La confirmation forte :

```text
DETRUIRE
```

reste obligatoire.

## 32. Audit final

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, ne supposez pas que toutes les ressources
ou tous les coûts P5 ont disparu.

# CHECKLIST FINALE

- [ ] environnement de contrôle disponible ;
- [ ] contrat P5 conforme ;
- [ ] `p5.sh inspect` relu avant mutation ;
- [ ] `GO AWS` obtenu ;
- [ ] `GO TERRAFORM` obtenu ;
- [ ] exercice 1 exécuté sur AWS réel ;
- [ ] idempotence Ansible prouvée ;
- [ ] Angular réellement servi par NGINX ;
- [ ] logs NGINX réels collectés ;
- [ ] exercice 2 exécuté ;
- [ ] données OpenSearch vérifiées ;
- [ ] visualisations/captures Dashboards validées ;
- [ ] exercice 3 exécuté ;
- [ ] round-robin vérifié ;
- [ ] panne et reprise vérifiées ;
- [ ] diagnostics collectés ;
- [ ] `p5.sh finalize` conforme ;
- [ ] livrables relus ;
- [ ] AWS nettoyé ;
- [ ] `NETTOYAGE AWS COMPLET` obtenu.

# RÉFÉRENCES

- [Cadre officiel](00-cadre-officiel.md)
- [Parcours pédagogique](01-parcours-debutant.md)
- [Architecture et flux](architecture-et-flux.md)
- [Centre de commande V11](CENTRE_DE_COMMANDE.md)
- [Préparation AWS](00b-preparation-compte-aws.md)
- [Convergence et réexécution](convergence-et-reexecution.md)
- [Troubleshooting](troubleshooting.md)
- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
- [Installation de l'environnement de contrôle](00-preparation-environnement.md)
