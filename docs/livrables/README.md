# Livrables du P5 — guide de préparation

## Principe

Ce dossier contient les trois structures de livrables correspondant aux trois exercices OpenClassrooms.

Un livrable ne doit pas remplacer l'exécution réelle :

```text
code versionné ≠ preuve d'exécution
log brut ≠ preuve présentable
capture isolée ≠ explication
```

Le format recommandé est :

```text
objectif
→ commande/action
→ résultat observé
→ interprétation
```

## Livrable 1 — Terraform et Ansible

Fichier :

[`SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md`](SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md)

### Ce que la consigne demande

- fichiers Terraform ;
- playbook(s) Ansible ;
- démonstration du déploiement.

### Ce que le dépôt permet de prouver en plus

- compte AWS verrouillé ;
- plan relu ;
- infrastructure convergée ;
- Ansible ping ;
- NGINX + Angular ;
- second passage Ansible idempotent ;
- application accessible ;
- log NGINX réel collecté.

### Preuves minimales recommandées

```text
1. Terraform plan / apply
2. EC2 active
3. ansible ping
4. premier playbook sans échec
5. second playbook changed=0 unreachable=0 failed=0
6. Angular dans le navigateur
```

Le livrable doit expliquer la séparation :

```text
Terraform = infrastructure
Ansible   = configuration/déploiement
```

## Livrable 2 — OpenSearch et dashboard

Fichier :

[`SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md`](SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md)

Le nom historique du fichier mentionne Kibana car la consigne utilise le vocabulaire ELK. La réalisation Cloud du dépôt utilise **Amazon OpenSearch et OpenSearch Dashboards**.

### Preuves techniques

- domaine OpenSearch actif ;
- données indexées ;
- mapping exploitable ;
- agrégations valides.

### Preuves visuelles

Quatre captures :

1. donut de répartition des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 h ;
3. top 5 `url_path` par tranches de 12 h ;
4. dashboard complet contenant les trois visualisations.

### Ce que l'explication doit montrer

Pour chaque visualisation :

- champ utilisé ;
- type d'agrégation ;
- intervalle temporel si nécessaire ;
- sens de la métrique ;
- résultat observé.

## Livrable 3 — HAProxy et disponibilité

Fichier :

[`SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md`](SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md)

### Point de référence

La page récapitulative des livrables OpenClassrooms contient une formulation générique pour le troisième exercice. Le détail de l'exercice demande clairement le travail HAProxy et la configuration correspondante.

Le livrable de ce dépôt se base donc sur le **besoin détaillé** :

- HAProxy ;
- deux `nginxdemos/hello` ;
- configuration `haproxy.cfg` ;
- round-robin ;
- health checks ;
- panne ;
- continuité ;
- reprise.

### Preuves minimales recommandées

```text
1. architecture avec 3 EC2 actives
2. haproxy.cfg lisible
3. haproxy -c réussi
4. deux backends avant panne
5. un seul backend pendant panne
6. HTTP disponible pendant panne
7. deux backends après restauration
```

## D'où viennent les preuves techniques ?

Les sorties orchestrées sont conservées localement sous :

```text
proofs/runtime/
logs/<RUN_ID>/
```

Les copies de preuves par étape comportent un manifeste avec code retour, durée et empreinte SHA-256.

Ces dossiers sont **privés par défaut**.

## Pourquoi ne pas versionner toutes les preuves brutes ?

Parce qu'elles peuvent contenir :

- IP ;
- endpoints ;
- ARN ;
- identifiants de ressources ;
- chemins locaux ;
- informations de diagnostic inutiles pour l'évaluation.

Le bon processus est :

```text
preuve brute
  ↓
sélection
  ↓
anonymisation si nécessaire
  ↓
contexte
  ↓
livrable
```

## Données à ne jamais publier

- access key AWS ;
- secret access key ;
- session token ;
- clé privée SSH ;
- token GitHub ;
- `environment/aws-readiness.env` ;
- vrais `terraform.tfvars` ;
- `terraform.tfstate` ;
- inventaire Ansible réel complet ;
- archive runtime non relue.

## Contrôle structurel

Avant d'avoir toutes les preuves :

```bash
bash scripts/commands/prepare-livrables.sh --structure-only
```

Ce mode vérifie la présence des documents et sections importantes sans prétendre que les preuves AWS existent déjà.

## Contrôle strict

Avant remise :

```bash
bash scripts/commands/prepare-livrables.sh
```

Le script refuse les marqueurs indiquant une preuve manquante.

La commande intégrée est :

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Relecture finale

Pour chaque exercice :

- [ ] le besoin OpenClassrooms est identifiable ;
- [ ] la réalisation AWS est expliquée ;
- [ ] les commandes importantes sont visibles ;
- [ ] les sorties ne contiennent pas de secret ;
- [ ] les captures sont lisibles ;
- [ ] chaque preuve possède une conclusion ;
- [ ] aucune preuve fictive ou placeholder ne reste ;
- [ ] les technologies hors périmètre ne sont pas présentées comme exercices P5.

## Après la remise des preuves

Lorsque les captures et sorties nécessaires sont sécurisées :

```bash
bash scripts/commands/p5.sh cleanup
```

L'ordre est :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Verdict de fermeture :

```text
NETTOYAGE AWS COMPLET
```

Voir également [`../validation-preuves-nettoyage.md`](../validation-preuves-nettoyage.md).
