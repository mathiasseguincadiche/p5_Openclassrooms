# 01 — Parcours d'exécution de bout en bout

Ce document est le **runbook principal** du projet. La voie normale d'exécution
est le centre de commande `p5.sh`. Les guides d'exercice conservent les commandes
Terraform, Ansible et OpenSearch détaillées pour comprendre ou diagnostiquer une
étape isolée.

Référence d'architecture :
[architecture technique](architecture-et-flux.md).

## Règles du parcours

- exécuter les commandes depuis la racine du dépôt ;
- ne jamais versionner `environment/aws-readiness.env`, `terraform.tfvars`, les
  états Terraform, l'inventaire Ansible réel, `logs/` ou `proofs/runtime/` ;
- considérer `environment/aws-readiness.env` comme la source unique des paramètres
  dépendant du compte AWS ;
- relire chaque plan Terraform avant `apply` ;
- ne jamais détruire l'exercice 1 avant la fin de l'exercice 3 ;
- conserver les preuves avant la destruction ;
- terminer par l'audit AWS global.

## Parcours recommandé

Depuis un clone du dépôt :

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Le parcours complet est :

```text
prepare
  │
  ├─ contrôle du socle DevOps
  ├─ bootstrap si nécessaire
  ├─ configuration AWS locale
  ├─ synchronisation des tfvars
  ├─ budget
  └─ GO AWS + GO TERRAFORM
  │
  ▼
ex1
  ├─ build Angular
  ├─ Terraform exercice 1
  ├─ inventaire Ansible généré automatiquement
  ├─ attente SSH/cloud-init
  ├─ ping Ansible
  ├─ déploiement
  ├─ seconde exécution → changed=0
  ├─ vérification Angular/NGINX
  ├─ génération de trafic
  └─ collecte du vrai access.log
  │
  ▼
ex2
  ├─ Terraform OpenSearch
  ├─ import du jeu reproductible
  ├─ import du vrai access.log si disponible
  ├─ vérification mappings/agrégations
  └─ dashboard + captures manuelles
  │
  ▼
ex3
  ├─ Terraform HAProxy + 2 backends
  ├─ attente HTTP
  ├─ round-robin
  ├─ panne contrôlée
  └─ reprise et réintégration
  │
  ▼
diagnostics + structure des livrables
```

## Première exécution sur une VM neuve

Si le socle DevOps manque, `p5.sh` propose automatiquement :

```text
bootstrap-ubuntu-server.sh
```

Le bootstrap peut modifier les groupes Docker et l'environnement Node/NVM. Dans
ce cas, le centre de commande affiche :

```text
RECONNEXION REQUISE
```

Après reconnexion, relancer simplement :

```bash
bash scripts/commands/p5.sh all
```

Aucune autre séquence n'est nécessaire pour reprendre.

## Préparation AWS

La commande :

```bash
bash scripts/commands/p5.sh prepare
```

prend en charge :

- profil AWS ;
- connexion SSO lorsque le profil l'utilise ;
- identité AWS et refus du compte root ;
- région ;
- détection de l'IPv4 publique en `/32` ;
- clé SSH du lab ;
- vérifications de sécurité qui nécessitent une confirmation humaine ;
- budget ;
- création et synchronisation des trois `terraform.tfvars` ;
- contrôles AWS Ready et pré-déploiement.

Les confirmations de sécurité doivent être saisies réellement. Le mode `--yes`
ne les invente jamais.

Conditions de sortie :

```text
GO AWS
GO TERRAFORM
```

Pour contrôler sans créer de ressource AWS :

```bash
bash scripts/commands/p5.sh status
```

Pour inclure l'intégration OpenSearch locale :

```bash
bash scripts/commands/p5.sh status --full-validation
```

## Exercice 1 — Terraform, Ansible, NGINX et Angular

Commande recommandée :

```bash
bash scripts/commands/p5.sh ex1
```

Le centre de commande :

1. construit l'artefact Angular reproductible ;
2. lance `terraform init` ;
3. produit le plan ;
4. affiche le plan en clair ;
5. attend la confirmation avant `apply` ;
6. génère l'inventaire Ansible depuis `web_public_ip` ;
7. attend SSH, Python et cloud-init ;
8. effectue un `ansible ping` ;
9. exécute le playbook ;
10. rejoue le même playbook ;
11. refuse l'idempotence si le récapitulatif n'indique pas
    `changed=0`, `unreachable=0`, `failed=0` ;
12. vérifie Angular derrière NGINX ;
13. génère 96 requêtes contrôlées ;
14. collecte `/var/log/nginx/access.log` sous
    `proofs/runtime/exercice-2/nginx-access-real.log`.

Condition de sortie :

```text
Exercice 1 opérationnel, idempotence prouvée et logs NGINX réels collectés.
```

Détail manuel :
[Exercice 1](exercices/01-terraform-ansible.md).

## Exercice 2 — OpenSearch

Commande recommandée :

```bash
bash scripts/commands/p5.sh ex2
```

Deux sources sont volontairement utilisées lorsque l'exercice 1 a déjà été
exécuté :

1. `terraform/exercice-2/samples/nginx-access.log.sample` ;
2. `proofs/runtime/exercice-2/nginx-access-real.log`.

Le premier fichier garantit une distribution temporelle suffisante pour les
visualisations par tranches de 12 heures. Le second démontre la vraie chaîne :

```text
NGINX réel → collecte SSH → conversion NDJSON → Amazon OpenSearch
```

Les IDs OpenSearch sont déterministes à partir du fichier source, du numéro de
ligne et du contenu. Rejouer un même import ne duplique donc pas une ligne
identique.

Le centre de commande valide les deux sources, demande confirmation avant
l'import, importe le jeu reproductible puis les logs réels disponibles, et lance
la vérification des mappings et agrégations.

Condition technique :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

La création du dashboard reste volontairement manuelle. `p5.sh` affiche l'URL et
les actions attendues puis exige la saisie exacte `OK` après :

- donut des méthodes HTTP ;
- somme de `bytes_sent` par tranches de 12 h ;
- top 5 des `url_path` par tranches de 12 h ;
- captures nécessaires aux livrables.

Même avec `--yes`, ce checkpoint ne peut pas être validé automatiquement.

Détail manuel :
[Exercice 2](exercices/02-elk-opensearch.md).

## Exercice 3 — HAProxy

Commande recommandée :

```bash
bash scripts/commands/p5.sh ex3
```

Prérequis critique : l'exercice 1 doit encore exister.

Le centre de commande :

1. vérifie la dépendance de l'exercice 1 ;
2. applique Terraform après affichage du plan ;
3. attend que HAProxy réponde en HTTP ;
4. exige deux backends en round-robin ;
5. prévisualise le scénario de panne ;
6. demande confirmation ;
7. arrête réellement un backend ;
8. vérifie la continuité du service ;
9. redémarre le backend ;
10. confirme sa réintégration.

Condition de sortie :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

Détail manuel :
[Exercice 3](exercices/03-haproxy.md).

## Mode `--yes`

Exemple :

```bash
bash scripts/commands/p5.sh all --yes
```

Ce mode confirme uniquement les mutations automatisables après affichage des
informations nécessaires.

Il ne contourne pas :

- les confirmations de sécurité AWS non vérifiables automatiquement ;
- le checkpoint du dashboard OpenSearch ;
- la confirmation `DETRUIRE` du nettoyage final.

## Reprise après interruption

Les états Terraform sont utilisés pour distinguer un lab neuf d'un lab déjà
géré. Après une coupure, une déconnexion SSH ou une interruption volontaire :

```bash
bash scripts/commands/p5.sh all
```

Le script réévalue le lab existant au lieu de considérer automatiquement les
ressources comme des collisions.

Règle absolue : **ne jamais supprimer un `terraform.tfstate` pour forcer une
reprise**. Cela pourrait orpheliner des ressources AWS.

## Logs

Chaque lancement de `p5.sh` crée une session :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Le terminal affiche pour chaque étape :

```text
P5  07 — Déployer Angular et NGINX avec Ansible
       Commande : ...
       Log      : .../07-ansible-deploy.log

[ OK ] Déployer Angular et NGINX avec Ansible — 18 s
```

Pour retrouver les derniers journaux :

```bash
bash scripts/commands/p5.sh logs
```

Les logs opérateur servent au diagnostic. Les preuves pédagogiques restent dans
`proofs/runtime/`.

## Finalisation

Le mode `all` s'arrête après les exercices, les diagnostics et le contrôle de
structure. Il ne détruit rien.

Après avoir inséré et relu les captures/preuves réelles :

```bash
bash scripts/commands/p5.sh finalize
```

Le contrôle strict doit aboutir à :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Documentation :
[Validation, preuves et nettoyage](validation-preuves-nettoyage.md).

## Nettoyage AWS

Quand la démonstration est terminée :

```bash
bash scripts/commands/p5.sh cleanup
```

L'ordre est :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La destruction garde la confirmation exacte :

```text
DETRUIRE
```

Le verdict final attendu est :

```text
NETTOYAGE AWS COMPLET
```

## Procédures manuelles

Les commandes manuelles restent documentées et supportées. Elles servent à :

- comprendre ce que l'orchestrateur exécute ;
- refaire une seule opération ;
- diagnostiquer un échec ;
- préparer une démonstration pédagogique détaillée.

Références :

- [Étape 0A — VM](00-preparation-environnement.md)
- [Étape 0B — AWS](00b-preparation-compte-aws.md)
- [Exercice 1](exercices/01-terraform-ansible.md)
- [Exercice 2](exercices/02-elk-opensearch.md)
- [Exercice 3](exercices/03-haproxy.md)
- [Scripts](../scripts/README.md)

## Niveau de validation

Trois niveaux ne doivent pas être confondus :

| Niveau | Preuve |
| --- | --- |
| Code | CI, syntaxe, tests, audits |
| Intégrations locales | Angular/NGINX, OpenSearch, HAProxy, orchestrateur simulé |
| AWS réel | exécution de `p5.sh all` sur la VM avec un compte/session AWS valide |

Une CI verte ne remplace donc pas le premier déploiement réel AWS. Elle réduit le
risque avant celui-ci et garantit que l'orchestrateur, ses garde-fous et les
briques locales respectent leur contrat.

## Checklist de fin

- [ ] `p5.sh all` exécuté sur le vrai lab AWS ;
- [ ] idempotence Ansible prouvée ;
- [ ] logs NGINX réels collectés ;
- [ ] jeu reproductible et logs réels importés dans OpenSearch ;
- [ ] dashboard et trois visualisations capturés ;
- [ ] round-robin, panne et reprise HAProxy validés ;
- [ ] diagnostics conservés ;
- [ ] livrables complétés et contrôlés avec `p5.sh finalize` ;
- [ ] ressources détruites avec `p5.sh cleanup` ;
- [ ] audit final `NETTOYAGE AWS COMPLET`.
