# 04 — Audit de non-régression

Cet audit protège le projet P5 contre deux dérives opposées : l'accumulation de
contenus génériques hors périmètre et la simplification qui supprimerait une
capacité utile. Le parcours principal doit rester simple, mais aucune fonction
nécessaire à la réalisation, à la preuve ou au nettoyage ne doit disparaître.

## Référence comparée

La référence précédant la simplification est le commit
`2e0600fbf573815077cf541e30a0d9d01591a180`.

La comparaison avec l'état actuel porte sur les fichiers, les fonctions, les
commandes, les contrôles de sécurité et les informations propres au P5. Le
nombre de lignes ou de fichiers n'est pas un critère de qualité : une suppression
n'est acceptable que lorsque son contenu est hors périmètre, faux, redondant ou
remplacé par une solution plus sûre.

## Résultat de l'audit

Aucune capacité indispensable aux trois exercices officiels n'est perdue dans
l'état actuel. Plusieurs suppressions anciennes étaient légitimes, mais des
informations utiles avaient été trop résumées et deux affirmations étaient
devenues obsolètes. Elles sont maintenant corrigées et protégées par un contrat
exécutable.

### Capacités conservées ou renforcées

| Capacité | Avant la simplification | État actuel |
| --- | --- | --- |
| Préparation du poste | phase interactive dépendante de bibliothèques Bash | bootstrap autonome, contrôle du lab et versions fixées |
| Préparation AWS | vérifications partielles | identité, compte autorisé, région, quotas, budget et garde-fous Terraform |
| Application de l'exercice 1 | page statique présentée comme substitut | véritable projet Angular, verrouillage npm et build comparé à l'artefact Ansible |
| Infrastructure | modules Terraform présents | trois modules conservés, compte verrouillé, tags communs et accès `/32` |
| Déploiement Ansible | chemins devenus incohérents | playbook, artefact Angular et configuration NGINX synchronisés |
| OpenSearch | procédure peu reproductible | mapping strict, 64 événements, import contrôlé et vérification des agrégations |
| Haute disponibilité | déploiement sans preuve complète | round-robin, panne contrôlée, restauration par `trap` et réintégration vérifiée |
| Livrables | gabarits isolés | trois livrables, contrôle de structure et refus des preuves fictives |
| Nettoyage | destruction insuffisamment vérifiée | ordre 3 → 2 → 1, confirmation stricte puis audit AWS non destructif |
| Documentation | contenu volumineux et parfois contradictoire | parcours principal ciblé, décisions techniques et journal séparés |
| Schémas | Mermaid ou gabarit SVG répété | six SVG légers, autonomes et spécialisés selon le message à expliquer |

## Suppressions acceptées après comparaison

| Élément supprimé | Classement | Motif |
| --- | --- | --- |
| `docs/exercises/` avec cinq exercices génériques | hors périmètre | décrivait Docker, CI et Kubernetes au lieu des trois exercices officiels |
| `TEMPLATES/` Docker, Kubernetes, GitHub Actions et Terraform | hors périmètre | modèles généralistes sans rôle dans les livrables P5 |
| anciens schémas Mermaid d'architecture générique | trompeur | représentaient Kubernetes, plusieurs clouds et une production inexistante |
| `run-all.sh`, `runbook.sh` et les phases automatiques | automatisation dangereuse | masquaient `plan`, `apply`, la création manuelle du dashboard et les décisions humaines |
| `kibana-api.sh` | automatisation contraire à l'évaluation | les trois visualisations doivent être comprises et construites manuellement |
| bibliothèques Bash partagées volumineuses | doublon | les scripts critiques sont autonomes et plus simples à auditer |
| guides et antisèches généralistes | ressource non spécifique | ne constituaient pas une source de vérité du projet P5 |

Ces suppressions ne doivent pas être interprétées comme une autorisation de
retirer une fonction équivalente du parcours actuel. Par exemple, le lanceur
« tout en un » reste supprimé, mais la préparation, les contrôles, les tests,
les preuves et le nettoyage restent tous disponibles séparément.

## Contrat exécutable

Le contrôle central est :

```bash
python3 scripts/tools/audit_non_regression.py
```

Il vérifie notamment :

- les trois guides et les trois modules Terraform ;
- le parcours complet de la préparation au nettoyage ;
- les sources Angular et l'artefact réellement compilé ;
- les garde-fous de compte, de région, d'adresse `/32` et de chiffrement ;
- les données OpenSearch et les tests HAProxy ;
- la présence des trois livrables et des scripts de destruction et d'audit ;
- l'absence d'états, de variables réelles et d'inventaires sensibles ;
- l'absence d'affirmations documentaires devenues fausses ;
- exactement six SVG intégrés au README, valides, accessibles et inférieurs à
  8 Kio chacun ;
- plusieurs canevas afin d'empêcher le retour à un gabarit unique appliqué à
  tous les schémas.

Le workflow `.github/workflows/non-regression.yml` exécute ce contrat sur chaque
pull request et chaque push vers `main`. Une refonte qui retire une capacité
critique ou réintroduit une incohérence doit donc échouer avant fusion.

## Règles de conception des schémas

La cohérence repose sur une grammaire commune, pas sur la répétition du même
composant :

- une seule question principale par schéma ;
- une composition choisie selon le besoin : carte, fondations, couloirs,
  pipeline de données, topologie avec chronologie ou procédure de fermeture ;
- couleurs sémantiques stables et texte court ;
- aucun élément décoratif sans fonction explicative ;
- aucun script, image encodée, filtre ou dépendance externe ;
- dimensions adaptées à un README et conservation de la lisibilité après mise
  à l'échelle ;
- détails d'exécution conservés dans le texte Markdown, pas entassés dans le
  dessin.

## Limites honnêtes

Cet audit garantit la présence et la cohérence des capacités du dépôt. Il ne
peut pas certifier sans exécution réelle :

- le résultat d'un `terraform apply` dans le compte AWS de l'étudiant ;
- l'état du MFA root, du moyen de paiement ou des quotas à un instant donné ;
- la réception des alertes budgétaires ;
- les captures et sorties qui doivent provenir du véritable environnement ;
- l'absence de toute ressource AWS en dehors du périmètre inspecté par les
  scripts.

Ces points restent des preuves humaines et opérationnelles obligatoires. Ils ne
doivent jamais être simulés dans le dépôt.
