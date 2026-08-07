# Validation, preuves, publication et nettoyage

Ce document décrit le **cycle de validation** du projet, depuis les contrôles
locaux jusqu’à la fermeture complète du lab AWS. Il répond à quatre questions :

1. qu’est-ce qui doit être validé avant chaque étape ?
2. quelles preuves faut-il conserver ?
3. qu’est-ce qui peut être publié ?
4. quand le projet est-il réellement terminé ?

## 1. Les quatre niveaux de validation

Le dépôt sépare volontairement les validations afin de ne pas confondre un code
correct avec un environnement AWS prêt ou avec un exercice réellement démontré.

| Niveau | Contrôle | Ce qu’il garantit | Ce qu’il ne garantit pas |
| --- | --- | --- | --- |
| Dépôt | `validate.sh` | cohérence, syntaxe, tests et intégrations locales | disponibilité du compte AWS |
| VM | `setup.sh --check-only` | outils, versions et structure du lab | quotas, budget et permissions AWS |
| AWS | `check-aws-readiness.sh` | identité, région, IP, quotas, budget, collisions | succès d’un futur `apply` |
| Pré-déploiement | `pre-deployment-check.sh` | VM + tfvars + dépôt + AWS pour une étape | validation humaine du plan Terraform |

Un `terraform apply` n’est autorisé qu’après :

```text
Étape 0A validée
GO AWS
GO TERRAFORM
plan Terraform relu
```

## 2. Validation locale du dépôt

Commande standard :

```bash
./scripts/commands/validate.sh
```

Le script exécute les contrôles disponibles sur la machine, notamment :

- périmètre limité aux trois exercices ;
- présence des fichiers critiques ;
- audit de non-régression ;
- permissions exécutables ;
- syntaxe Bash ;
- JSON ;
- données OpenSearch reproductibles ;
- structure des livrables ;
- build, tests, lint et audit npm Angular ;
- comparaison du build Angular avec l’artefact Ansible ;
- test Angular derrière NGINX avec Docker ;
- test HAProxy round-robin, panne et reprise avec Docker ;
- format et validation Terraform ;
- YAML, Ansible et Markdown lorsque les outils sont présents.

Pour inclure l’intégration OpenSearch locale :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

Cette validation est **non destructive vis-à-vis d’AWS**.

## 3. Contrôle de la VM

```bash
./scripts/commands/setup.sh --check-only
```

Le verdict valide l’étape 0A lorsque :

- Ubuntu Server et les versions attendues sont présents ;
- Docker est accessible ;
- l’arborescence critique est complète ;
- le véritable artefact Angular est versionné ;
- `validate.sh` réussit.

Après le bootstrap, une reconnexion est souvent nécessaire avant ce contrôle
pour appliquer le groupe `docker` et charger correctement l’environnement Node.

## 4. Contrôle AWS Ready

La configuration locale est créée une seule fois :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Puis les tfvars sont dérivés de cette source :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Le budget est prévisualisé puis créé explicitement :

```bash
./scripts/commands/setup-aws-guardrails.sh
./scripts/commands/setup-aws-guardrails.sh --apply
```

Contrôles par étape :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

Les principaux motifs bloquants sont :

- mauvais compte ou profil ;
- session AWS expirée ;
- utilisation du compte root ;
- région incohérente ;
- IP publique différente du `/32` configuré ;
- confirmations de sécurité non réalisées ;
- budget absent ;
- quota EC2 insuffisant ;
- combinaison OpenSearch indisponible ;
- `terraform.tfvars` absents ou désynchronisés ;
- ressource existante entrant en collision avec l’étape demandée ;
- dépendance de l’exercice 1 absente avant l’exercice 3.

## 5. Précontrôle unifié avant Terraform

La commande recommandée avant chaque exercice est :

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage exercice-2
./scripts/commands/pre-deployment-check.sh --stage exercice-3
```

Le précontrôle combine :

- système et versions ;
- clé SSH ;
- présence et synchronisation des tfvars ;
- composants propres à l’exercice ;
- validation locale du dépôt ;
- AWS Ready.

Le verdict attendu est :

```text
Verdict : GO TERRAFORM — relisez le plan et les coûts avant apply.
```

## 6. Règle de mutation

Le dépôt distingue trois catégories de commandes.

### Non destructif

Exemples :

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage initial
./scripts/commands/verify-opensearch-data.sh
python3 scripts/tools/audit_secrets.py
```

### Aperçu puis action explicite

Exemples :

```bash
./scripts/commands/setup-aws-guardrails.sh
./scripts/commands/setup-aws-guardrails.sh --apply

./scripts/commands/import-opensearch-data.sh
./scripts/commands/import-opensearch-data.sh --apply

./scripts/commands/test-haproxy-failover.sh
./scripts/commands/test-haproxy-failover.sh --apply
```

### Destructif confirmé

```bash
./scripts/commands/destroy-aws.sh
```

Le script exige la saisie exacte de `DETRUIRE` et détruit dans l’ordre 3 → 2 → 1.

## 7. Où sont enregistrées les preuves techniques ?

Les scripts écrivent sous :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Le dossier est ignoré par Git.

### Exercice 1

Exemples de preuves générées :

- en-têtes HTTP ;
- copie de la page Angular reçue ;
- résultat du fallback SPA ;
- journal de vérification ;
- journal de génération de trafic ;
- log NGINX récupéré par SSH.

### Exercice 2

Exemples :

- réponse de création du template ;
- réponse Bulk ;
- comptage des documents ;
- mapping ;
- agrégations ;
- journaux d’import et de vérification.

### Exercice 3

Exemples :

- round-robin ;
- état avant panne ;
- état pendant panne ;
- état après reprise ;
- verdict de réintégration.

## 8. États de publication

Toutes les données sous `proofs/runtime/` sont **privées par défaut**.

| État | Exemple | Git | Publication |
| --- | --- | --- | --- |
| Brut local | log complet, IP, endpoints | interdit | non |
| Diagnostic nettoyé | archive générée par `collect-diagnostics.sh` | interdit | partage privé après relecture |
| Preuve sélectionnée | extrait ou capture anonymisée | selon besoin | oui après relecture |
| Gabarit | fichier de `docs/livrables/` non complété | oui | oui, mais ce n’est pas une preuve |
| Livrable final | gabarit complété avec preuves réelles | oui si souhaité | oui après contrôle strict |

Le fait qu’un script masque certaines signatures sensibles ne remplace jamais la
relecture humaine.

## 9. Diagnostic partageable

Commande standard :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Avec l’intégration OpenSearch locale :

```bash
bash scripts/commands/collect-diagnostics.sh --complet
```

Avec les preuves runtime existantes :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Le collecteur produit :

- un résumé `OK / AVERTISSEMENTS / KO` ;
- un journal complet local ;
- un journal nettoyé ;
- un manifeste des preuves ;
- une archive `p5-diagnostic-<UTC>.tar.gz`.

Le journal complet **n’est pas placé dans l’archive**.

## 10. Preuves minimales par exercice

### Exercice 1

- `terraform validate` ;
- plan Terraform relu ;
- application des ressources ;
- instance EC2 active ;
- ping Ansible ;
- playbook réussi ;
- seconde exécution démontrant l’idempotence ;
- application Angular réelle servie ;
- bundle JavaScript accessible ;
- fallback SPA ;
- configuration NGINX valide.

### Exercice 2

- domaine OpenSearch actif ;
- données importées ;
- mapping exploitable ;
- Discover ;
- donut des méthodes HTTP ;
- somme des octets par tranches de 12 h ;
- top 5 des URL par tranches de 12 h ;
- dashboard complet.

### Exercice 3

- trois EC2 actives ;
- `haproxy.cfg` lisible ;
- validation `haproxy -c` ;
- deux backends en round-robin ;
- un seul backend pendant la panne ;
- continuité du service ;
- retour des deux backends après reprise.

## 11. Contrôle des livrables

Contrôle de structure utilisé avant les vraies preuves :

```bash
./scripts/commands/prepare-livrables.sh --structure-only
```

Contrôle final :

```bash
./scripts/commands/prepare-livrables.sh
```

Le mode strict échoue si :

- un fichier obligatoire manque ;
- une section obligatoire a disparu ;
- une signature de secret est détectée ;
- un marqueur de type « preuve à insérer » subsiste.

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## 12. Nettoyage : règles importantes

### Ne pas supprimer les états Terraform

Les fichiers d’état permettent à Terraform de retrouver les ressources qu’il a
créées. Les supprimer avant `destroy` risque d’orpheliner des ressources AWS.

`clean-local.sh` préserve volontairement ces états.

### Dépendance Exercice 1 → Exercice 3

L’exercice 3 réutilise le réseau et la paire de clés de l’exercice 1.

Donc :

```text
INTERDIT : détruire Exercice 1 puis essayer Exercice 3
CORRECT : Exercice 1 → Exercice 3 → destruction Exercice 3 → destruction Exercice 1
```

### Destruction finale recommandée

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

L’audit final recherche notamment :

- instances EC2 ;
- volumes EBS ;
- interfaces réseau ;
- Elastic IP ;
- groupes de sécurité ;
- sous-réseaux ;
- tables de routage ;
- Internet Gateway ;
- VPC ;
- paire de clés EC2 ;
- domaine OpenSearch.

Le verdict final attendu est :

```text
NETTOYAGE AWS COMPLET
```

Le budget reste volontairement actif après la destruction afin de signaler une
éventuelle ressource oubliée.

## 13. Important : portée de l’audit global

`check-aws-cleanup.sh` contrôle **l’ensemble du projet P5**, pas un exercice
isolé.

Il est donc normal qu’il signale des ressources restantes si, par exemple,
l’exercice 1 est encore conservé pour l’exercice 3.

Utilisez le verdict `NETTOYAGE AWS COMPLET` uniquement après la fermeture globale
du lab.

## 14. Checklist de fermeture

Avant de considérer le projet terminé :

- [ ] les trois exercices ont été exécutés réellement ;
- [ ] les preuves utiles sont conservées ;
- [ ] les captures ont été relues et anonymisées ;
- [ ] `audit_secrets.py` réussit ;
- [ ] les trois livrables ne contiennent plus de placeholder ;
- [ ] le contrôle strict des livrables réussit ;
- [ ] l’exercice 3 est détruit ;
- [ ] l’exercice 2 est détruit ;
- [ ] l’exercice 1 est détruit ;
- [ ] l’audit AWS global retourne `NETTOYAGE AWS COMPLET` ;
- [ ] les états Terraform n’ont été supprimés qu’après confirmation du nettoyage ;
- [ ] le budget AWS reste surveillé après la démonstration.

## 15. Documents associés

- [Parcours complet](01-parcours-debutant.md)
- [Architecture technique](architecture-et-flux.md)
- [Livrables](livrables/README.md)
- [Preuves runtime](../proofs/README.md)
- [Politique de sécurité](../SECURITY.md)
- [Troubleshooting](troubleshooting.md)
