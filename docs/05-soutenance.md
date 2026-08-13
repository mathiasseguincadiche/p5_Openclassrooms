# Guide de soutenance — P5 OpenClassrooms

## Objectif

Ce document prépare la démonstration du projet. Il ne remplace ni le runbook ni les livrables.

La soutenance doit montrer une chaîne cohérente :

```text
besoin
  ↓
infrastructure reproductible
  ↓
configuration idempotente
  ↓
application réellement servie
  ↓
logs réellement exploitables
  ↓
haute disponibilité démontrée
  ↓
preuves et fermeture propre du lab
```

## Avant la soutenance

Vérifier au minimum :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh finalize
```

Le but n'est pas de tout redéployer quelques minutes avant la présentation. Il faut surtout confirmer que l'état actuel, les preuves et les livrables sont cohérents.

Conserver à portée de main :

- le `README.md` racine ;
- le schéma d'architecture ;
- les sorties Terraform utiles ;
- la preuve du second passage Ansible ;
- l'URL Angular/NGINX ;
- les quatre captures OpenSearch Dashboards ;
- la preuve HAProxy avant, pendant et après panne ;
- les livrables finalisés.

## Déroulé recommandé

### 1. Présenter l'architecture globale

**Montrer** : `docs/schemas/vue-ensemble.svg` ou le schéma du README.

**Expliquer** :

- exercice 1 : Terraform crée l'infrastructure, Ansible configure l'EC2 et déploie Angular derrière NGINX ;
- exercice 2 : les logs HTTP sont convertis, indexés et analysés dans Amazon OpenSearch ;
- exercice 3 : HAProxy répartit le trafic entre deux backends et gère la perte d'un backend ;
- dépendance réseau : l'exercice 3 réutilise le VPC et les sous-réseaux de l'exercice 1 ;
- dépendance de données : le vrai `access.log` de l'exercice 1 alimente l'exercice 2.

**Ce que cela prouve** : le projet a été conçu comme un parcours cohérent, pas comme trois démonstrations isolées.

### 2. Montrer Terraform exercice 1

Commande de lecture :

```bash
terraform -chdir=terraform/exercice-1 output
```

Si une relecture du delta est utile :

```bash
terraform -chdir=terraform/exercice-1 plan -input=false -detailed-exitcode
```

**Montrer** : VPC, deux sous-réseaux publics, Security Group, EC2 et outputs.

**Expliquer** :

- Terraform possède l'infrastructure ;
- le plan est lu avant toute mutation ;
- `-detailed-exitcode` permet de distinguer état conforme, delta et erreur ;
- après convergence, aucun delta résiduel n'est attendu.

**Question probable** : pourquoi ne pas configurer NGINX directement avec Terraform ?

**Réponse attendue** : Terraform gère l'infrastructure ; Ansible gère la configuration du système et de l'application. Cette séparation rend les responsabilités plus claires et l'idempotence plus lisible.

### 3. Montrer Ansible et l'idempotence

Commande :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

**Résultat essentiel** :

```text
changed=0
unreachable=0
failed=0
```

**Expliquer** : un second passage sans changement montre que l'état cible est déjà atteint ; l'automatisation ne répète pas inutilement les modifications.

**Question probable** : pourquoi `changed=0` est-il important ?

**Réponse attendue** : parce qu'une automatisation de configuration doit être rejouable. Si elle modifie toujours la cible sans raison, elle n'est pas correctement idempotente.

### 4. Montrer Angular derrière NGINX

Récupérer l'URL depuis Terraform :

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
printf '%s\n' "$WEB_URL"
```

Contrôle :

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

**Montrer** : l'application dans le navigateur et, si utile, la réponse HTTP.

**Expliquer** : le build Angular versionné côté Ansible est comparé au build des sources par la CI afin d'éviter de déployer un artefact obsolète.

### 5. Montrer le passage des logs vers OpenSearch

Rappeler la chaîne :

```text
NGINX access.log
      ↓
conversion
      ↓
Bulk API
      ↓
Amazon OpenSearch
      ↓
OpenSearch Dashboards
```

Endpoint courant :

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
printf '%s\n' "$OPENSEARCH_ENDPOINT"
```

Contrôle technique :

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

**Expliquer** : le sample versionné garantit la reproductibilité ; le vrai log NGINX relie l'observabilité à l'application réellement déployée.

### 6. Montrer OpenSearch Dashboards

Présenter les quatre captures :

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 h ;
3. top 5 de `url_path` par tranches de 12 h ;
4. dashboard complet.

**Expliquer** :

- `http_method` doit être agrégable comme catégorie ;
- `bytes_sent` doit être numérique ;
- l'horodatage doit être exploitable comme date ;
- `url_path` doit permettre une agrégation `terms` ;
- le checkpoint visuel reste humain parce qu'une capture pédagogique ne doit pas être déclarée valide automatiquement.

**Question probable** : pourquoi OpenSearch au lieu d'un ELK local ?

**Réponse attendue** : cette réalisation retient le mode Cloud AWS autorisé par l'exercice. Le besoin pédagogique reste le même : indexer des logs, les explorer et produire les visualisations demandées.

### 7. Montrer HAProxy en fonctionnement normal

Récupérer l'URL :

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
printf '%s\n' "$HAPROXY_URL"
```

Test :

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

**Montrer** : les deux backends observés.

**Expliquer** : HAProxy utilise `balance roundrobin` et des health checks HTTP.

### 8. Montrer la panne et la reprise

La preuve de soutenance doit montrer trois états :

```text
AVANT  : deux backends disponibles
PANNE  : backend 1 retiré, service toujours disponible via backend 2
APRÈS  : backend 1 restauré puis réintégré
```

Configuration importante :

```text
option httpchk GET /
fall 3
rise 2
```

**Expliquer** :

- `fall 3` retire un backend après trois contrôles consécutifs en échec ;
- `rise 2` le réintègre après deux contrôles consécutifs réussis ;
- l'objectif n'est pas seulement de montrer un fichier `haproxy.cfg`, mais le comportement réel pendant une panne.

### 9. Montrer les preuves et la reproductibilité

Commande :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

**Expliquer** :

- `logs/` retrace ce qui a été exécuté ;
- `proofs/runtime/` contient les preuves techniques ;
- les livrables restent relus avant remise ;
- une CI verte valide le dépôt mais ne remplace pas une exécution AWS réelle.

### 10. Expliquer la fermeture du lab

L'ordre est :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

**Pourquoi ?** L'exercice 3 dépend du réseau de l'exercice 1. Détruire l'exercice 1 en premier casserait cette dépendance.

Le projet n'est considéré comme fermé qu'après le verdict :

```text
NETTOYAGE AWS COMPLET
```

## Questions techniques probables

### Pourquoi Terraform et Ansible ?

Terraform décrit et fait converger l'infrastructure AWS. Ansible décrit et fait converger la configuration de l'EC2 et de l'application. Les deux outils ont des responsabilités complémentaires.

### Pourquoi ne pas supprimer `terraform.tfstate` pour repartir proprement ?

Le state relie la configuration Terraform aux ressources gérées. Le supprimer peut faire perdre à Terraform la connaissance des objets qu'il doit encore gérer ou détruire.

### Que signifie un plan Terraform vide ?

L'état observé correspond déjà à l'état attendu. L'orchestrateur n'exécute alors aucun `apply` inutile.

### Pourquoi limiter SSH et OpenSearch à `/32` ?

Le lab n'a pas besoin d'exposer les interfaces d'administration à tout Internet. Une IPv4 publique unique est donc autorisée lorsque le besoin le permet.

### Pourquoi conserver un sample de logs si un vrai log existe ?

Le sample donne un jeu reproductible pour la CI et les tests. Le log réel fournit la preuve liée au déploiement AWS. Les deux ont des rôles différents.

### Pourquoi le checkpoint OpenSearch n'est-il pas automatisé ?

Parce que la preuve demandée inclut une validation visuelle réelle dans Dashboards. L'automatisation peut vérifier les données et les agrégations, pas prétendre qu'une capture a été produite et relue.

### Comment HAProxy sait-il qu'un backend est en panne ?

Il exécute des health checks HTTP. Après le nombre d'échecs défini par `fall`, le backend est retiré ; après le nombre de succès défini par `rise`, il est réintégré.

### Pourquoi l'exercice 3 dépend-il de l'exercice 1 ?

La réalisation réutilise le VPC et les sous-réseaux créés par l'exercice 1 afin d'éviter de dupliquer inutilement le socle réseau.

## Erreurs à éviter pendant la présentation

- lire tout le README au lieu de raconter le parcours ;
- lancer une mutation AWS non préparée uniquement pour « montrer quelque chose » ;
- utiliser une IP ou un endpoint copié manuellement alors qu'un output Terraform existe ;
- présenter une CI verte comme preuve d'un déploiement AWS réel ;
- oublier de montrer `changed=0` ;
- montrer uniquement `haproxy.cfg` sans preuve de panne et reprise ;
- présenter le sample OpenSearch comme s'il s'agissait du vrai log NGINX ;
- exposer un secret, un state ou un vrai `terraform.tfvars` dans une capture.

## Mémo final

```text
Architecture
→ Terraform
→ Ansible changed=0
→ Angular/NGINX
→ logs réels
→ OpenSearch + 4 captures
→ HAProxy round-robin
→ panne
→ reprise
→ preuves
→ fermeture AWS
```

Le runbook reste la référence d'exécution : [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).
