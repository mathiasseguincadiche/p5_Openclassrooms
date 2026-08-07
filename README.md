# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.
Ce dépôt contient l’implémentation exécutable du projet P5 et le parcours complet
permettant de préparer le lab, provisionner AWS avec Terraform, déployer Angular
avec Ansible et NGINX, exploiter les logs dans Amazon OpenSearch, tester la
disponibilité avec HAProxy, produire les preuves puis nettoyer les ressources.

> **Périmètre retenu : 100 % AWS.** La VM Ubuntu Server 26.04 sert de poste
> DevOps. Les infrastructures évaluées sont créées dans AWS.

> **Attention aux coûts AWS :** les valeurs fournies sont adaptées à un lab,
> mais ne garantissent jamais la gratuité. Relire chaque plan Terraform,
> contrôler les quotas, maintenir le budget d’alerte et détruire les ressources
> après la démonstration.

Le README présente le fonctionnement utile du dépôt. Les procédures exhaustives,
les décisions et les preuves attendues restent dans la
[documentation complète](docs/README.md).

## Compétences démontrées

| Domaine | Mise en œuvre |
| --- | --- |
| Infrastructure as Code | Trois modules Terraform avec garde-fous de compte, réseau, chiffrement et tags |
| Configuration automatisée | Build Angular reproductible, déploiement Ansible idempotent et NGINX |
| Observabilité | Collecte, transformation, import et analyse de logs NGINX dans OpenSearch |
| Haute disponibilité | Round-robin, retrait d’un backend défaillant et réintégration avec HAProxy |
| Sécurité | Accès `/32`, IMDSv2, volumes chiffrés, audit des secrets et journaux nettoyés |
| Qualité | CI, tests locaux, non-régression documentaire et vérification des livrables |
| Exploitation | Diagnostics partageables, preuves contrôlées, destruction ordonnée et audit AWS |

## Cycle complet du projet

| Phase | Action principale | Sortie ou verdict |
| --- | --- | --- |
| 0 — Préparer | Installer les outils, configurer le compte, la clé SSH et les variables | `GO AWS`, puis `GO TERRAFORM` |
| 1 — Déployer | Construire Angular, créer EC2, configurer NGINX avec Ansible | Application et fallback SPA validés |
| 2 — Observer | Collecter les logs, convertir en Bulk NDJSON et importer dans OpenSearch | Index, agrégations et dashboard vérifiés |
| 3 — Résister | Déployer HAProxy et deux backends, tester panne et reprise | Service continu et backends réintégrés |
| 4 — Prouver | Collecter les sorties, captures et diagnostics | Livrables complets et relus |
| 5 — Nettoyer | Détruire dans l’ordre 3 → 2 → 1 et auditer AWS | `NETTOYAGE AWS COMPLET` |

```text
Poste DevOps
  → contrôles locaux et AWS
  → Terraform
  → Ansible + NGINX
  → application Angular
  → logs NGINX
  → Amazon OpenSearch
  → HAProxy + 2 backends
  → preuves relues
  → destruction 3 → 2 → 1
  → audit final
```

Aucun lanceur « tout en un » n’est fourni. Les étapes restent séparées afin que
les plans, les mutations AWS, les visualisations et les validations humaines
restent visibles et compréhensibles.

## Paramètres et modèles par défaut

Les valeurs suivantes constituent un point de départ reproductible. Elles restent
configurables et doivent être revérifiées avant chaque déploiement.

| Élément | Valeur par défaut | Comportement |
| --- | --- | --- |
| Poste DevOps | Ubuntu Server 26.04 | Versions du lab contrôlées par `environment/versions.env` |
| Région AWS | `us-east-1` | Commune aux trois modules Terraform |
| Compte AWS | Aucun compte implicite | `expected_aws_account_id` est obligatoire et verrouille le provider |
| Adresse d’administration | Aucune valeur implicite | IPv4 réelle obligatoire au format `/32` |
| EC2 exercices 1 et 3 | `t3.micro` | Coût et quota à contrôler avant `apply` |
| AMI EC2 | `null` | Sélection automatique de l’Ubuntu Server 24.04 LTS Canonical la plus récente |
| Clé EC2 | `p5-key` | Clé publique attendue par défaut dans `~/.ssh/p5-key.pub` |
| OpenSearch | `OpenSearch_2.19` | Version déclarée explicitement dans Terraform |
| Nœud OpenSearch | `t3.small.search` | Un seul nœud pour le lab |
| Stockage OpenSearch | 10 Gio `gp3` | Volume borné entre 10 et 100 Gio |
| Répartition HAProxy | `roundrobin` | Alternance observable entre deux backends |
| Santé HAProxy | contrôle toutes les 3 s | Retrait après 3 échecs, retour après 2 succès |
| Tags Terraform | projet, gestionnaire, objectif, exercice | Inventaire, coûts et nettoyage facilités |

Les fichiers `terraform.tfvars.example` documentent la forme attendue. Les vrais
`terraform.tfvars` sont générés localement avec des permissions `600` et ne
doivent jamais être versionnés.

### Modèles versionnés et rôle

| Modèle | Rôle |
| --- | --- |
| `environment/aws-readiness.env.example` | Centralise les valeurs à renseigner avant tout contrôle AWS |
| `terraform/exercice-*/terraform.tfvars.example` | Documente les variables de chacun des trois modules |
| `ansible/inventories/hosts_aws.example` | Fournit la structure de l’inventaire sans publier l’hôte réel |
| `aws/budgets/p5-monthly-budget.json.example` | Décrit le budget créé explicitement avec `--apply` |
| `docs/livrables/` | Fournit trois gabarits qui ne deviennent des preuves qu’après exécution réelle |

## Garde-fous, escalade et fallbacks

### Niveaux de contrôle

Le dépôt applique une progression volontairement stricte :

1. **Aperçu local non destructif** : syntaxe, formats, build, tests et cohérence.
2. **Contrôle AWS Ready** : identité, compte autorisé, région, quotas, budget et
   paramètres sensibles.
3. **Précontrôle par étape** : `initial`, `exercice-2` ou `exercice-3`.
4. **Verdict bloquant** : un seul `KO` empêche le verdict `GO TERRAFORM`.
5. **Mutation explicite** : option `--apply`, confirmation dédiée ou application
   manuelle d’un plan relu.
6. **Validation humaine** : coûts, captures, dashboard, anonymisation et remise.
7. **Validation de forge** : CI, sécurité et contrat de non-régression sur chaque
   pull request et chaque push vers `main`.

Les diagnostics distinguent `OK`, `AVERTISSEMENT` et `KO`. Un avertissement doit
être compris et documenté ; un `KO` bloque l’étape concernée.

### Fallbacks et restauration

| Situation | Mécanisme de repli ou de restauration |
| --- | --- |
| Route Angular inconnue | NGINX sert `/index.html` avec `try_files` pour préserver le routage SPA |
| `ami_id = null` | Terraform sélectionne automatiquement l’AMI Ubuntu 24.04 LTS Canonical |
| Backend HAProxy défaillant | HAProxy retire le backend après le seuil `fall 3` |
| Backend de nouveau sain | HAProxy le réintègre après le seuil `rise 2` |
| Test HAProxy interrompu | Un `trap` tente de redémarrer le backend et de nettoyer les ressources temporaires |
| Test local NGINX, HAProxy ou OpenSearch en échec | Les conteneurs éphémères sont supprimés par `trap` |
| Build Angular en échec | L’artefact Ansible existant n’est remplacé qu’après un build réussi |
| Nettoyage local | Les caches sont supprimés, mais les états Terraform sont conservés |
| Destruction AWS | Ordre obligatoire 3 → 2 → 1 pour préserver le réseau partagé jusqu’à la fin |

## Démarrage sécurisé

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
./scripts/commands/bootstrap-ubuntu-server.sh
```

Après reconnexion :

```bash
./scripts/commands/setup.sh --check-only

cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env

./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/sync-terraform-tfvars.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le premier déploiement ne doit commencer qu’après :

```text
GO AWS
GO TERRAFORM
```

Le plan Terraform doit ensuite être sauvegardé, affiché et relu avant son
application.

## Exercice 1 — Terraform, Ansible, Angular et NGINX

### Objectif

Construire le véritable projet Angular, créer l’infrastructure AWS puis déployer
l’artefact avec Ansible et NGINX.

```bash
./scripts/commands/prepare-angular-artifact.sh

terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
terraform -chdir=terraform/exercice-1 apply tfplan

ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping

ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml

./scripts/commands/verify-angular-deployment.sh
./scripts/commands/generate-nginx-traffic.sh
./scripts/commands/collect-nginx-access-log.sh
```

### Preuves attendues

- véritable application Angular accessible en HTTP ;
- bundle JavaScript chargé ;
- fallback SPA NGINX fonctionnel ;
- seconde exécution Ansible idempotente ;
- logs NGINX réels disponibles pour l’exercice 2.

Guide détaillé :
[Terraform, Ansible, Angular et NGINX](docs/exercices/01-terraform-ansible.md).

## Exercice 2 — Logs NGINX et Amazon OpenSearch

### Objectif

Transformer les logs NGINX en événements structurés, les importer dans
OpenSearch et produire les visualisations demandées.

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-2

terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 show tfplan
terraform -chdir=terraform/exercice-2 apply tfplan
```

L’import fonctionne en deux états :

```bash
# Préparation et aperçu, sans écriture dans OpenSearch.
./scripts/commands/import-opensearch-data.sh

# Import réel après validation.
./scripts/commands/import-opensearch-data.sh --apply

# Vérification non destructive.
./scripts/commands/verify-opensearch-data.sh
```

Le dépôt fournit un échantillon de 64 événements. Les logs réels de l’exercice 1
peuvent être transmis au convertisseur avec l’option `--input`.

### Visualisations attendues

| Visualisation | Agrégation |
| --- | --- |
| Donut | Répartition de `http_method` |
| Histogramme | Somme de `bytes_sent` par tranches de 12 heures |
| Top 5 temporel | `url_path` les plus fréquents par tranches de 12 heures |

La création du dashboard reste manuelle afin de démontrer la compréhension des
champs et des agrégations.

Guide détaillé :
[logs NGINX et Amazon OpenSearch](docs/exercices/02-elk-opensearch.md).

## Exercice 3 — HAProxy, panne et reprise

### Objectif

Démontrer que HAProxy répartit les requêtes entre deux backends, maintient le
service pendant une panne et réintègre automatiquement le backend restauré.

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-3

terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 show tfplan
terraform -chdir=terraform/exercice-3 apply tfplan

./scripts/commands/test-haproxy-roundrobin.sh
```

Le test de bascule possède deux états :

```bash
# Simulation et contrôles préalables, sans arrêt réel.
./scripts/commands/test-haproxy-failover.sh

# Panne réelle, contrôle du service, redémarrage et réintégration.
./scripts/commands/test-haproxy-failover.sh --apply
```

L’exercice 3 réutilise le VPC, les sous-réseaux et la clé créés par l’exercice 1.
Il doit donc être détruit avant l’exercice 1.

Guide détaillé :
[HAProxy, round-robin et failover](docs/exercices/03-haproxy.md).

## Journalisation, preuves et états de publication

Tous les fichiers techniques n’ont pas le même niveau de publication.

| État | Emplacement | Versionné | Règle |
| --- | --- | --- | --- |
| Journal brut privé | `proofs/runtime/diagnostics/<UTC>/` | Non | Reste local, permissions restrictives |
| Preuves runtime | `proofs/runtime/exercice-*` | Non | Contiennent des données réelles du lab, à relire |
| Archive diagnostic nettoyée | `proofs/runtime/diagnostics/p5-diagnostic-<UTC>.tar.gz` | Non | Partageable uniquement après contrôle manuel |
| Gabarits de livrables | `docs/livrables/` | Oui | Ne constituent pas encore des preuves |
| Livrables complétés | `docs/livrables/` | Oui | Publiables après anonymisation et contrôle strict |
| README et documentation | Racine et `docs/` | Oui | Ne doivent contenir ni secret, ni état Terraform, ni preuve fictive |

Le collecteur de diagnostics produit :

```bash
bash scripts/commands/collect-diagnostics.sh
bash scripts/commands/collect-diagnostics.sh --complet
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

L’archive nettoyée contient un résumé `OK / AVERTISSEMENTS / KO`, les versions,
les contrôles locaux, un journal expurgé et un manifeste. Le journal complet non
filtré n’est jamais ajouté à l’archive.

Les clés AWS, jetons, en-têtes d’autorisation et blocs de clé privée détectables
sont masqués, mais une relecture humaine reste obligatoire avant toute
publication publique.

## Finalisation et nettoyage

```bash
# Contrôle de structure utilisé par la CI.
./scripts/commands/prepare-livrables.sh --structure-only

# Contrôle strict avant remise.
./scripts/commands/prepare-livrables.sh

# Destruction confirmée et ordonnée.
./scripts/commands/destroy-aws.sh

# Audit non destructif des ressources restantes.
./scripts/commands/check-aws-cleanup.sh
```

Le mode strict des livrables échoue tant qu’un marqueur tel que
« preuve à insérer » subsiste. Le dépôt organise les preuves, mais n’en invente
aucune.

Verdicts finaux attendus :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
NETTOYAGE AWS COMPLET
```

Le budget AWS reste volontairement actif après la démonstration afin de signaler
une éventuelle ressource oubliée.

## Automatisation et validation humaine

| Automatisé par le dépôt | À valider humainement |
| --- | --- |
| Installation et contrôle du socle DevOps | MFA root, moyen de paiement et récupération du compte |
| Synchronisation des variables Terraform | Valeurs réelles du compte et de l’adresse IP |
| Build Angular et comparaison de l’artefact | Lecture du résultat fonctionnel |
| Déploiement Ansible idempotent | Validation de l’accès et du comportement |
| Conversion et vérification des logs | Choix et création des visualisations |
| Tests HAProxy | Observation de la continuité du service |
| Collecte et nettoyage des diagnostics | Relecture avant partage |
| Destruction et audit des ressources P5 | Vérification finale dans la console AWS |
| Contrôles CI et non-régression | Décision de fusion et remise OpenClassrooms |

## Structure du projet

```text
p5_Openclassrooms/
├── .github/workflows/        # CI, sécurité et non-régression
├── application/angular/      # sources Angular, tests et verrou npm
├── ansible/
│   ├── files/                # build Angular et configuration NGINX
│   ├── inventories/          # exemple versionné, inventaire réel ignoré
│   └── playbooks/            # déploiement idempotent
├── aws/                      # politique IAM et budget du lab
├── environment/              # versions et configuration AWS d’exemple
├── docs/
│   ├── exercices/            # trois guides officiels
│   ├── livrables/            # gabarits puis livrables relus
│   ├── schemas/              # six schémas SVG spécialisés
│   └── suivi/                # décisions et journal du projet
├── proofs/                   # convention ; runtime local ignoré par Git
├── scripts/
│   ├── commands/             # préparation, contrôles, preuves et nettoyage
│   ├── tests/                # intégrations locales éphémères
│   └── tools/                # audits, conversion NGINX et génération HAProxy
└── terraform/
    ├── exercice-1/           # VPC, sous-réseaux, clé et EC2 Angular
    ├── exercice-2/           # domaine Amazon OpenSearch
    └── exercice-3/           # HAProxy et deux backends
```

## Règles de forge et de non-régression

Les modifications sont proposées sur une branche dédiée puis relues dans une
pull request vers `main`.

Les règles du dépôt sont les suivantes :

- conserver des commits cohérents et explicites, avec les préfixes usuels
  `docs:`, `fix:`, `feat:`, `test:` ou `chore:` ;
- ne jamais versionner de secrets, `terraform.tfvars`, états Terraform,
  inventaires réels ou dossiers `proofs/runtime/` ;
- conserver exactement trois guides d’exercices officiels ;
- ne pas réintroduire de modèles génériques hors périmètre ni de blocs Mermaid ;
- ne pas masquer une mutation AWS derrière une commande automatique ;
- conserver le parcours complet de la préparation jusqu’à l’audit de nettoyage ;
- exécuter la validation locale avant publication ;
- ne fusionner qu’après réussite des contrôles CI, sécurité et non-régression.

Les trois workflows utilisent des permissions GitHub en lecture seule, annulent
les exécutions devenues obsolètes sur une même référence et s’exécutent sur les
pull requests ainsi que sur les pushes vers `main`.

La CI vérifie notamment :

- le périmètre, les chemins, les versions et les permissions exécutables ;
- le build Angular réel et sa synchronisation avec l’artefact Ansible ;
- la configuration NGINX et le fallback SPA ;
- Terraform, Ansible, YAML, Markdown, JSON et les liens ;
- les garde-fous AWS, l’adresse `/32`, IMDSv2 et le chiffrement ;
- OpenSearch local, HAProxy, panne et reprise ;
- les secrets et fichiers sensibles suivis par Git ;
- le contrat fonctionnel et documentaire de non-régression.

Contrôles locaux :

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

Validation complète avec OpenSearch local :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

## Documentation approfondie

- [Index complet de la documentation](docs/README.md)
- [Préparation de la VM](docs/00-preparation-environnement.md)
- [Préparation du compte AWS](docs/00b-preparation-compte-aws.md)
- [Correspondance entre consignes, fichiers et preuves](docs/02-correspondance-consignes-depot.md)
- [Audit structurel](docs/03-audit-structurel.md)
- [Audit de non-régression](docs/04-audit-non-regression.md)
- [Décisions techniques](docs/suivi/decisions-techniques.md)
- [Scripts et commandes](scripts/README.md)
- [Infrastructure Terraform](terraform/README.md)
- [Application Angular](application/README.md)
- [Déploiement Ansible](ansible/README.md)
- [Preuves et diagnostics](proofs/README.md)
- [Politique de sécurité](SECURITY.md)

<details>
<summary>Accès direct aux six schémas</summary>

- [Vue d’ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation](docs/schemas/etape-0.svg)
- [Exercice 1](docs/schemas/exercice-1.svg)
- [Exercice 2](docs/schemas/exercice-2.svg)
- [Exercice 3](docs/schemas/exercice-3.svg)
- [Finalisation](docs/schemas/finalisation/finalisation.svg)

</details>

## État de finalisation

Le code, les configurations et les contrôles automatisés sont versionnés. Les
documents de `docs/livrables/` restent des gabarits tant que les sorties et
captures du véritable environnement AWS n’y ont pas été insérées, relues et
anonymisées.

## Licence

Ce dépôt est distribué sous licence [MIT](LICENSE).
