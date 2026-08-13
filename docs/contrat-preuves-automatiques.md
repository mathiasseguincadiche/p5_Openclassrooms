# Contrat des preuves automatiques

## Objectif

Le runtime P5 ne se contente pas d'afficher des commandes. Il conserve une trace structurée de chaque étape orchestrée afin de faciliter :

- le diagnostic ;
- la reprise ;
- la sélection des preuves ;
- la compréhension de ce qui a réellement été exécuté.

Ces traces ne remplacent pas les preuves humaines demandées par OpenClassrooms.

## 1. Une session = un identifiant de run

Au démarrage d'une session orchestrée, le runtime génère un identifiant UTC :

```text
YYYYMMDDTHHMMSSZ
```

Les journaux sont stockés sous :

```text
logs/<RUN_ID>/
```

## 2. Journal principal

Une exécution de `p5.sh` écrit un journal principal :

```text
logs/<RUN_ID>/p5.log
```

Il rassemble la sortie de la session dans l'ordre d'exécution.

## 3. Journaux par étape

Chaque étape possède aussi son propre fichier numéroté :

```text
01-<step>.log
02-<step>.log
03-<step>.log
...
```

Cette granularité permet de partager ou relire un échec sans parcourir tout le run.

## 4. Preuves par étape

Les logs d'étape sont copiés dans :

```text
proofs/runtime/steps/<RUN_ID>/
```

avec permissions restrictives.

Un manifeste est conservé :

```text
manifest.tsv
```

Il contient notamment :

```text
UTC
numéro d'étape
clé d'étape
statut
code retour
durée
SHA-256
nom de la preuve
libellé
```

## 5. Statuts

Le runtime utilise principalement :

```text
VALIDE
ECHEC
```

Une étape n'est `VALIDE` que si son code retour fait partie des codes acceptés pour ce contexte.

Exemple particulier : `terraform plan -detailed-exitcode` peut légitimement retourner `2` pour signifier « delta présent ». Le moteur sait traiter ce code comme un état attendu avant décision.

## 6. Hash des preuves

Lorsque `sha256sum` est disponible, une empreinte SHA-256 est calculée pour la copie de preuve.

But :

- identifier précisément le fichier produit ;
- détecter une modification ultérieure ;
- améliorer la traçabilité technique.

Le hash ne prouve pas que le contenu est pédagogiquement suffisant. Il prouve seulement l'identité du fichier.

## 7. Résumé factuel du run

Le runtime maintient :

```text
logs/<RUN_ID>/summary.log
```

avec notamment :

```text
run_id
validated_steps
failed_steps
result
updated_at
```

Ce résumé est utile pour savoir rapidement si le run contient un échec.

## 8. Journal stable par script

En complément du journal de session, le runtime maintient des historiques sous :

```text
logs/scripts/
```

Le but est de retrouver plusieurs exécutions successives d'un même script spécialisé.

## 9. Redaction des secrets

Avant écriture des logs orchestrés, le runtime filtre plusieurs signatures sensibles, notamment :

- `AWS_SECRET_ACCESS_KEY` ;
- `AWS_SESSION_TOKEN` ;
- tokens GitHub courants ;
- certaines clés/tokens API ;
- en-têtes `Bearer`.

Les aperçus de commandes masquent également les arguments dont le nom ressemble à `password`, `secret`, `token`, `credential` ou `api-key`.

### Limite

Aucune redaction automatique n'est parfaite.

Avant publication d'une preuve :

```text
toujours relire manuellement
```

## 10. Information inconnue

Le runtime distingue une erreur d'une information non vérifiable.

Exemple : Terraform devrait produire `web_public_ip`, mais l'output est absent.

Le comportement attendu est :

```text
INCONNU
Raison : output absent/invalide
Action : réparer le module/state puis relancer
```

Le runtime ne remplace pas l'IP par une valeur copiée arbitrairement.

## 11. Checkpoint humain

Certaines preuves doivent rester humaines.

Exemple principal : exercice 2 OpenSearch Dashboards.

Le runtime peut vérifier :

- endpoint ;
- index ;
- mapping ;
- documents ;
- agrégations.

Il ne peut pas honnêtement affirmer que l'étudiant a :

- compris les trois visualisations ;
- vérifié leur lisibilité ;
- produit les quatre captures.

Le moteur utilise donc un checkpoint manuel et demande une confirmation explicite.

Le mode `--yes` ne doit pas valider ce checkpoint.

## 12. Preuve automatique vs preuve évaluateur

| Type | Exemple | Suffit seul ? |
| --- | --- | --- |
| log automatique | sortie `terraform plan` | non |
| test automatique | round-robin en CI | non pour la preuve AWS réelle |
| preuve runtime AWS | sortie du failover réel | souvent utile, à contextualiser |
| capture | dashboard OpenSearch | oui pour l'élément visuel si lisible et réel |
| livrable contextualisé | commande + résultat + conclusion | format recommandé |

## 13. Convention de preuve

Une preuve finale doit idéalement être présentée ainsi :

```text
Objectif
  ce que l'on cherche à démontrer

Commande / action
  ce qui a réellement été exécuté

Résultat
  sortie, capture ou valeur observée

Interprétation
  pourquoi cela valide le besoin
```

Exemple HAProxy :

```text
Objectif : vérifier la répartition entre deux backends.
Commande : test-haproxy-roundrobin.sh --requests 12.
Résultat : p5-hello-1 et p5-hello-2 sont observés.
Conclusion : les deux backends participent au pool HAProxy.
```

## 14. Dossiers runtime privés

Par défaut, traiter comme privés :

```text
logs/<RUN_ID>/
proofs/runtime/
```

Ils peuvent contenir :

- IP ;
- endpoints ;
- ARNs ;
- détails d'infrastructure ;
- chemins locaux ;
- sorties exhaustives.

Ils ne sont pas des pièces à publier en bloc.

## 15. Audit avant publication

Avant d'ajouter un extrait aux livrables :

1. ouvrir la preuve ;
2. vérifier qu'elle correspond au bon run ;
3. supprimer les informations inutiles ;
4. anonymiser si nécessaire ;
5. conserver les lignes qui démontrent le résultat ;
6. ajouter une explication ;
7. vérifier qu'aucun secret n'est présent.

Commande complémentaire :

```bash
python3 scripts/tools/audit_secrets.py
```

## 16. Ce que le contrat garantit

Le contrat améliore la traçabilité de l'exécution orchestrée.

Il ne garantit pas :

- que chaque capture a été prise ;
- que le dashboard est pédagogiquement correct ;
- que toutes les ressources externes au périmètre P5 ont été nettoyées ;
- qu'un log brut peut être publié sans relecture.

La suite du cycle de preuve est documentée dans [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md).
