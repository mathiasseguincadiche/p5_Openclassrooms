# Assessment P5 OpenClassrooms — architecture et démonstration

> **But de ce document :** présenter le projet de manière claire, expliquer précisément l'architecture des trois exercices, puis démontrer que chaque résultat attendu est réellement obtenu.
>
> Le déroulé est volontairement séparé en deux parties : **PARTIE A — je présente et j'explique l'architecture** ; **PARTIE B — je démontre par des preuves que l'implémentation fonctionne**.
>
> L'environnement local qui exécute les commandes n'est pas le sujet de l'assessment. Le récit principal porte sur **AWS, Terraform, Ansible, NGINX, Angular, Amazon OpenSearch et HAProxy**.

## Comment utiliser ce document

Pendant l'assessment, suivre toujours la même logique :

```text
1. PRÉSENTER LE BESOIN
2. MONTRER L'ARCHITECTURE
3. EXPLIQUER LE RÔLE DE CHAQUE COMPOSANT
4. MONTRER COMMENT C'EST CONFIGURÉ
5. EXÉCUTER LA PREUVE
6. MONTRER LE RÉSULTAT RÉEL
7. RELIER LA PREUVE À L'ATTENDU OPENCLASSROOMS
```

La règle de présentation est simple :

```text
schéma       = comprendre l'architecture
code         = comprendre comment elle est déclarée
terminal     = prouver le comportement technique
navigateur   = montrer le résultat réel
```

---

# 0 — Préparer l'assessment avant l'arrivée de l'évaluateur

Le lab doit être déjà reconstruit et validé. Ne pas utiliser le temps de présentation pour créer les ressources depuis zéro.

```bash
cd ~/labs/p5_Openclassrooms

git switch main
git pull --ff-only
git status --short

bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

État minimal avant l'assessment :

| Élément | État attendu |
| --- | --- |
| Exercice 1 / Terraform | infrastructure AWS présente et plan convergé |
| Exercice 1 / Ansible | cible joignable, playbook sans erreur, second passage idempotent |
| Exercice 1 / Angular | application visible dans le navigateur |
| Exercice 2 / OpenSearch | domaine actif, données et agrégations vérifiées |
| Exercice 2 / Dashboards | trois visualisations et dashboard complets visibles |
| Exercice 3 / HAProxy | deux backends disponibles et round-robin observable |
| Exercice 3 / failover | scénario `2 → 1 → 2` validé |

Préparer les valeurs utiles :

```bash
export WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
export WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"

export OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
export DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
export DASHBOARD_URL="${DASHBOARDS_URL%/}/app/dashboards#/view/p5-nginx-observability"

export HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
export BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"
```

Préparer trois onglets navigateur : Angular, OpenSearch Dashboards et HAProxy.

---

# PARTIE A — PRÉSENTATION ET ARCHITECTURE

# 1 — Présenter le projet

## 1.1 Le projet en une phrase

> « Ce projet met en œuvre trois compétences complémentaires : créer et configurer une infrastructure avec Terraform et Ansible, exploiter les logs d'un serveur HTTP avec Amazon OpenSearch, puis démontrer la répartition de charge et la continuité de service avec HAProxy. »

## 1.2 Vue globale

![Architecture globale du P5](schemas/vue-ensemble.svg)

## 1.3 Comment lire la vue globale

Le projet contient exactement trois exercices :

| Exercice | Question traitée | Résultat principal |
| --- | --- | --- |
| **1 — Terraform + Ansible** | comment créer une infrastructure puis déployer une application de manière automatisée ? | Angular est servie par NGINX sur une EC2 AWS |
| **2 — Logs + OpenSearch** | comment transformer des logs HTTP en informations lisibles ? | trois visualisations et un dashboard sont disponibles |
| **3 — HAProxy** | comment répartir le trafic et réagir à la panne d'un service ? | deux backends partagent la charge et HAProxy gère la panne/reprise |

Deux liens donnent de la cohérence au projet :

```text
Exercice 1 ── access.log NGINX ──► Exercice 2
Exercice 1 ── VPC + 2 subnets ───► Exercice 3
```

### À dire à l'évaluateur

> « Je vais d'abord vous présenter l'architecture de chaque exercice. Ensuite, je reprendrai les résultats attendus et je les démontrerai un par un avec le code, le terminal et le navigateur. »

---

# 2 — Exercice 1 : architecture Terraform + Ansible + NGINX + Angular

## 2.1 Ce qu'OpenClassrooms attend

Pour l'option AWS, la consigne demande notamment :

- un projet Terraform avec le provider AWS et une machine EC2 ;
- l'exécution correcte de `terraform init`, `terraform plan` et `terraform apply` ;
- la vérification que la ressource AWS existe réellement ;
- un inventaire Ansible et un test `ansible all -i hosts -m ping` réussi ;
- un `deploy.yml` qui installe NGINX, installe Angular, déploie la configuration NGINX et utilise un handler ;
- l'exécution du playbook sans erreur ;
- NGINX fonctionnel sur le port 80 et servant l'application Angular ;
- une vérification de l'application dans le navigateur via l'adresse du serveur.

### Note sur `t2.micro` / `t3.micro`

La documentation OpenClassrooms fournie contient une incohérence : une section mentionne `t3.micro`, un bloc « résultat attendu » mentionne `t2.micro`, puis la partie déploiement mentionne de nouveau `t3.micro`.

L'implémentation actuelle du dépôt utilise **`t3.micro` par défaut**, valeur paramétrable dans Terraform. Pendant l'oral, présenter la configuration réellement utilisée et ne pas inventer une autre valeur.

## 2.2 Architecture réelle de l'exercice 1

![Architecture de l'exercice 1](schemas/exercice-1.svg)

### Placement des ressources

| Ressource | Emplacement | Configuration / rôle |
| --- | --- | --- |
| Région | AWS `us-east-1` | région du lab |
| VPC | `10.0.0.0/16` | réseau principal du projet |
| Subnet public 1 | première zone disponible | contient l'EC2 `p5-web` |
| Subnet public 2 | deuxième zone disponible | créé dès l'exercice 1 et réutilisé par l'exercice 3 |
| EC2 `p5-web` | subnet public 1 | `t3.micro`, Ubuntu 24.04 LTS |
| Security Group `p5-web-sg` | VPC | HTTP 80 public ; SSH 22 depuis l'IP d'administration `/32` |
| Internet Gateway + route publique | VPC | permet l'accès Internet aux subnets publics |

### Ce que Terraform crée

Terraform possède la couche infrastructure :

```text
provider AWS
→ VPC
→ 2 subnets publics
→ Internet Gateway
→ table de routage
→ Security Group
→ paire de clés EC2
→ EC2 p5-web
```

L'EC2 reçoit également :

```text
Ubuntu 24.04 LTS
EBS gp3 chiffré
IMDSv2 obligatoire
IP publique
Python 3 via user_data
```

Le `user_data` reste volontairement minimal : il prépare Python pour Ansible, mais **ne déploie pas l'application**.

### Ce qu'Ansible configure

Ansible prend le relais après la création de l'EC2 :

```text
EC2 p5-web
   │ SSH
   ▼
deploy.yml
   ├── installe NGINX + curl
   ├── crée l'utilisateur applicatif
   ├── prépare /var/www/p5
   ├── copie l'artefact Angular
   ├── installe la configuration NGINX
   ├── exécute nginx -t
   ├── démarre et active NGINX
   └── handler : recharge NGINX si nécessaire
```

### Flux réseau à expliquer

```text
Navigateur ── HTTP 80 ──► IP publique EC2 p5-web ──► NGINX ──► Angular

Administration / Ansible ── SSH 22 ──► EC2 p5-web
                                      accès limité à l'IP /32
```

### Principe à retenir

> **Terraform crée l'infrastructure. Ansible configure la machine. NGINX sert l'application Angular.**

### À dire à l'évaluateur

> « Dans l'exercice 1, j'ai séparé le provisionnement de la configuration. Terraform crée le réseau AWS, la sécurité et l'EC2 `p5-web`. Cette EC2 est placée dans le premier subnet public. Ansible se connecte ensuite en SSH, installe NGINX, déploie Angular et configure le serveur web. Le second subnet est déjà créé et sera réutilisé dans l'exercice 3. »

---

# 3 — Exercice 2 : architecture logs + Amazon OpenSearch

## 3.1 Ce qu'OpenClassrooms attend

OpenClassrooms autorise deux modes pour l'exercice 2 : local ou Cloud. Le **mode Cloud utilise Amazon OpenSearch sur AWS**.

Le résultat demandé est un dashboard contenant trois visualisations :

| Visualisation | Information représentée |
| --- | --- |
| Donut | répartition des verbes / méthodes HTTP |
| Histogramme | quantité cumulée de données envoyées par le serveur par tranche de 12 h |
| Histogramme cumulé | top 5 des requêtes / URL par tranche de 12 h |

Quatre captures doivent pouvoir être fournies : le dashboard complet, le donut, l'histogramme des octets et le top 5.

## 3.2 Architecture réelle de l'exercice 2

![Architecture de l'exercice 2](schemas/exercice-2.svg)

### Point important : OpenSearch n'est pas une EC2 du VPC

Dans cette implémentation, l'exercice 2 utilise **Amazon OpenSearch Service**, un service AWS managé.

Le Terraform actuel ne place pas le domaine OpenSearch dans les subnets du VPC de l'exercice 1. Le domaine expose un endpoint HTTPS AWS et son accès est limité à l'IPv4 d'administration `/32` par la policy du domaine.

### Configuration du domaine

| Élément | Valeur |
| --- | --- |
| Nom | `p5-opensearch` par défaut |
| Moteur | `OpenSearch_2.19` |
| Nombre de nœuds | 1 |
| Type | `t3.small.search` |
| Stockage | EBS `gp3`, 10 Gio par défaut |
| HTTPS | obligatoire |
| TLS | minimum 1.2 |
| Chiffrement au repos | activé |
| Chiffrement entre nœuds | activé |
| Accès | IPv4 d'administration `/32` |

### Flux de données

```text
NGINX de l'exercice 1
        │
        └── access.log réel
                │
                ▼
        parsing / typage
                │
                ▼
              NDJSON
                │
             Bulk API
                │
                ▼
       Amazon OpenSearch
                │
         mappings + index
         + agrégations
                │
                ▼
     OpenSearch Dashboards
        ├── donut HTTP
        ├── bytes_sent / 12 h
        └── top 5 URL / 12 h
```

### Sample OpenClassrooms et log réel du projet

La consigne pédagogique travaille à partir d'un fichier échantillon. Le dépôt conserve donc un **sample versionné** pour la reproductibilité.

L'implémentation ajoute aussi le **vrai `access.log` de NGINX de l'exercice 1**. C'est une amélioration du projet : le sample permet de rejouer les tests, tandis que le log réel prouve que l'observabilité peut exploiter l'activité de l'application réellement déployée.

### Dashboard as Code

Les trois visualisations et le dashboard sont versionnés dans :

```text
terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

L'automatisation :

```text
définition versionnée
→ contrôle des champs OpenSearch
→ génération des Saved Objects
→ import API
→ relecture des 5 objets
→ contrôle visuel dans le navigateur
```

Cette automatisation est une amélioration d'industrialisation. Le **résultat attendu par l'évaluation reste visuel** : les trois graphiques doivent être lisibles dans OpenSearch Dashboards.

### À dire à l'évaluateur

> « Pour le mode Cloud autorisé par OpenClassrooms, j'utilise Amazon OpenSearch Service. Les logs NGINX sont transformés en documents structurés puis indexés via la Bulk API. OpenSearch calcule les agrégations et OpenSearch Dashboards présente les trois visualisations demandées. Le domaine est managé par AWS, il n'est pas hébergé sur une EC2 du VPC. »

---

# 4 — Exercice 3 : architecture HAProxy + deux backends

## 4.1 Ce qu'OpenClassrooms attend

L'exercice demande une architecture composée de :

```text
1 serveur HAProxy
+
2 services applicatifs identiques
```

HAProxy doit :

- écouter sur le port 80 et être accessible dans le navigateur ;
- répartir les requêtes en alternance entre les deux services ;
- permettre d'observer le changement de `Server address` et `Server name` au rafraîchissement ;
- vérifier l'état de santé des services ;
- retirer un service indisponible ;
- maintenir les requêtes sur le service restant ;
- réintégrer automatiquement le service restauré ;
- fournir le fichier `haproxy.cfg` comme livrable.

## 4.2 Architecture réelle de l'exercice 3

![Architecture de l'exercice 3](schemas/exercice-3.svg)

### Réutilisation du réseau de l'exercice 1

Terraform ne crée pas un nouveau VPC. Il recherche le VPC et les deux subnets publics créés par l'exercice 1 grâce à leurs tags.

### Placement précis des trois EC2

| Instance | Placement | Type | Rôle |
| --- | --- | --- | --- |
| `p5-haproxy` | subnet public 1 | `t3.micro` / Ubuntu 24.04 | point d'entrée HTTP / load balancer |
| `p5-hello-1` | subnet public 1 | `t3.micro` / Ubuntu 24.04 | backend Docker `nginxdemos/hello` |
| `p5-hello-2` | subnet public 2 | `t3.micro` / Ubuntu 24.04 | backend Docker `nginxdemos/hello` |

Les backends exécutent :

```text
Docker
└── nginxdemos/hello:0.4-plain-text
    ├── p5-hello-1
    └── p5-hello-2
```

### Chemin d'une requête

```text
Utilisateur
   │ HTTP 80 vers IP publique
   ▼
p5-haproxy
   │
   │ round-robin via IP privées
   ├──────────────► p5-hello-1:80
   └──────────────► p5-hello-2:80
```

HAProxy ne contacte pas les backends via leurs IP publiques : le template utilise leurs **IP privées**.

### Sécurité réseau

Deux Security Groups séparent les rôles :

```text
p5-haproxy-sg
├── HTTP 80 : Internet
└── SSH 22  : IP admin /32

p5-hello-sg
├── HTTP 80 : uniquement depuis p5-haproxy-sg
└── SSH 22  : IP admin /32
```

Les backends ont une IP publique pour les besoins d'administration du lab, mais leur port HTTP n'est pas ouvert directement à Internet.

### Configuration HAProxy à connaître

```text
bind *:80
balance roundrobin
option httpchk GET /
http-check expect status 200
inter 3s
fall 3
rise 2
```

Interprétation :

```text
fall 3 = 3 checks en échec avant de déclarer le backend DOWN
rise 2 = 2 checks réussis avant de le réintégrer UP
```

### Scénario de panne

```text
ÉTAT NORMAL
2 backends disponibles
      ↓
ARRÊT DU SERVICE p5-hello-1
      ↓
HAProxy constate les échecs
      ↓
p5-hello-1 retiré de la rotation
      ↓
p5-hello-2 continue à répondre
      ↓
REDÉMARRAGE p5-hello-1
      ↓
HAProxy constate les succès
      ↓
p5-hello-1 réintégré
      ↓
2 backends disponibles
```

Le script du dépôt automatise cette panne applicative en arrêtant puis redémarrant le conteneur `nginx-hello` sur l'une des EC2. Il simule donc l'indisponibilité du **service applicatif** que HAProxy doit détecter.

### À dire à l'évaluateur

> « L'exercice 3 réutilise le VPC et les deux subnets de l'exercice 1. HAProxy et le premier backend sont dans le premier subnet, le deuxième backend dans le second. Le client accède uniquement à HAProxy. HAProxy distribue ensuite les requêtes sur les IP privées des deux backends, surveille leur état et retire automatiquement un backend si son service ne répond plus. »

---

# PARTIE B — DÉMONSTRATION DES RÉSULTATS ATTENDUS

# 5 — Démonstration Exercice 1

## 5.1 Preuve A — Terraform décrit et possède l'infrastructure

Afficher les outputs :

```bash
terraform -chdir=terraform/exercice-1 output
```

À montrer :

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_public_dns
web_url
```

Puis montrer l'état géré :

```bash
terraform -chdir=terraform/exercice-1 show
```

### Ce que cela prouve

> Les ressources ne sont pas seulement décrites dans un fichier HCL : elles appartiennent au state Terraform et correspondent au déploiement de l'exercice 1.

## 5.2 Preuve B — Terraform est convergé

```bash
terraform -chdir=terraform/exercice-1 plan \
  -input=false \
  -detailed-exitcode
```

Résultat idéal : aucun changement.

### À dire

> « `terraform init`, `plan` et `apply` ont été utilisés pour construire le lab. Pendant l'assessment je ne relance pas un apply inutile ; je montre le plan convergé, qui indique que l'état réel correspond à la configuration. »

## 5.3 Preuve C — l'EC2 est réellement joignable par Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Attendu :

```text
SUCCESS
ping: pong
```

Cela répond directement au test d'inventaire/connectivité demandé dans l'exercice.

## 5.4 Preuve D — le playbook configure correctement le serveur

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Sur un environnement déjà convergé, montrer :

```text
changed=0
unreachable=0
failed=0
```

### À dire

> « La consigne demande que le playbook s'exécute sans erreur. Le second passage va plus loin : `changed=0` prouve qu'il est idempotent et que la machine est déjà dans l'état attendu. »

## 5.5 Preuve E — NGINX sert réellement Angular

Preuve technique :

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$WEB_URL"
```

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Puis **obligatoirement ouvrir `$WEB_URL` dans le navigateur**.

Montrer :

- l'application Angular rendue ;
- un rafraîchissement de page ;
- si utile, une route SPA comme `/parcours-p5`.

### Correspondance avec l'attendu OpenClassrooms

| Attendu | Preuve montrée |
| --- | --- |
| infrastructure Terraform créée | outputs + `terraform show` |
| cible accessible | Ansible `ping` → `SUCCESS / pong` |
| NGINX installé/configuré | `deploy.yml` + exécution sans erreur |
| Angular installée | playbook + test de déploiement |
| NGINX sert Angular sur port 80 | navigateur sur `WEB_URL` |
| déploiement automatisé | Terraform + Ansible versionnés |

### Transition

> « L'application fonctionne réellement. Je passe maintenant à l'exercice 2 et j'utilise ses logs HTTP comme données d'observabilité. »

---

# 6 — Démonstration Exercice 2

## 6.1 Preuve A — le domaine Amazon OpenSearch existe

```bash
terraform -chdir=terraform/exercice-2 output
```

À montrer :

```text
opensearch_domain_name
opensearch_endpoint
opensearch_dashboards_endpoint
```

### À dire

> « J'ai retenu le mode Cloud prévu par OpenClassrooms. Le service de recherche est Amazon OpenSearch Service. »

## 6.2 Preuve B — produire et montrer un vrai log NGINX

Générer du trafic :

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 12
```

Collecter le log :

```bash
bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-presentation.log
```

Afficher quelques lignes :

```bash
tail -n 10 proofs/runtime/exercice-2/nginx-access-presentation.log
```

### À dire

> « La consigne utilise un fichier échantillon. Le projet conserve ce sample, mais je montre aussi ici un vrai `access.log` provenant du NGINX de l'exercice 1. »

## 6.3 Preuve C — les données sont exploitables dans OpenSearch

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

À observer :

```text
documents présents
mapping valide
http_method agrégable
bytes_sent numérique / sommable
url_path agrégable
agrégations sans erreur
```

### À dire

> « Je vérifie d'abord les données. Si le mapping ou les agrégations étaient faux, un graphique visuellement présent ne constituerait pas une preuve correcte. »

## 6.4 Preuve D — les trois visualisations demandées existent

Ouvrir :

```text
DASHBOARD_URL
```

Montrer successivement :

1. le **donut des méthodes HTTP** ;
2. l'**histogramme de la somme de `bytes_sent` par 12 h** ;
3. le **top 5 de `url_path` par 12 h** ;
4. le **dashboard complet**.

Vérifier la plage temporelle et l'absence de filtre parasite.

### Captures attendues

Conserver quatre captures lisibles :

```text
01-dashboard-complet
02-donut-methodes-http
03-histogramme-bytes-12h
04-top5-url-12h
```

### Correspondance avec l'attendu OpenClassrooms

| Attendu | Preuve montrée |
| --- | --- |
| mode Cloud OpenSearch opérationnel | outputs Terraform + endpoint |
| données disponibles | log/sample + vérification OpenSearch |
| donut HTTP | navigateur + capture |
| quantité cumulée / 12 h | navigateur + capture |
| top 5 / 12 h | navigateur + capture |
| dashboard complet | navigateur + capture globale |

### Transition

> « Les logs sont maintenant transformés en informations exploitables. Je termine avec l'exercice 3 : la répartition de charge et la réaction à une panne. »

---

# 7 — Démonstration Exercice 3

## 7.1 Preuve A — montrer les trois instances et leur placement logique

```bash
terraform -chdir=terraform/exercice-3 output
```

À repérer :

```text
haproxy_public_ip
haproxy_private_ip
hello_1_private_ip
hello_2_private_ip
haproxy_url
```

### À dire

> « HAProxy possède l'URL publique utilisée par le client. Les deux adresses privées des backends sont celles injectées dans la configuration HAProxy. »

## 7.2 Preuve B — montrer la configuration HAProxy utile

```bash
grep -E 'bind|balance|httpchk|http-check|server hello' \
  terraform/exercice-3/haproxy.cfg.tpl
```

À expliquer :

```text
bind *:80
    → point d'entrée HTTP

balance roundrobin
    → alternance entre les backends disponibles

option httpchk GET /
http-check expect status 200
    → contrôle de santé applicatif

fall 3
    → retrait après 3 échecs

rise 2
    → réintégration après 2 succès
```

## 7.3 Preuve C — round-robin dans le navigateur

Ouvrir :

```text
HAPROXY_URL
```

Rafraîchir plusieurs fois et montrer dans la page `nginxdemos/hello` :

```text
Server address
Server name
```

Les valeurs doivent provenir des deux backends.

Cette preuve visuelle correspond directement au résultat demandé par OpenClassrooms.

## 7.4 Preuve D — round-robin dans le terminal

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Attendu :

```text
p5-hello-1
p5-hello-2
2 backends distincts observés
ROUND-ROBIN OPÉRATIONNEL
```

## 7.5 Preuve E — panne et réintégration

Avant de lancer le test, annoncer le scénario :

```text
AVANT   : 2 backends
PANNE   : le service backend 1 est arrêté
PENDANT : 1 backend reste disponible
APRÈS   : le service backend 1 revient et est réintégré
```

Exécuter :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

Verdict attendu :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

Le script arrête le conteneur `nginx-hello`, attend que HAProxy ne voie plus qu'un backend, redémarre le conteneur puis attend le retour des deux backends.

## 7.6 Preuve F — résultat final dans le navigateur

Revenir sur `HAPROXY_URL` et rafraîchir plusieurs fois.

Montrer que `Server name` / `Server address` correspondent de nouveau aux deux services.

### Correspondance avec l'attendu OpenClassrooms

| Attendu | Preuve montrée |
| --- | --- |
| HAProxy accessible sur port 80 | navigateur `HAPROXY_URL` |
| alternance entre deux services | changement `Server name` / `Server address` |
| règles de health check | `haproxy.cfg.tpl` |
| service défaillant retiré | test failover phase PENDANT |
| service disponible via l'autre backend | réponses HTTP pendant la panne |
| service restauré réintégré | phase APRÈS + navigateur |
| fichier `haproxy.cfg` disponible | template versionné dans le dépôt |

---

# 8 — Conclusion de l'assessment

## Résumer les trois résultats

| Exercice | Ce que j'ai construit | Ce que j'ai démontré |
| --- | --- | --- |
| **1** | infrastructure AWS + déploiement Ansible | EC2 gérée par Terraform, Ansible opérationnel et Angular réellement servie par NGINX |
| **2** | chaîne de logs vers Amazon OpenSearch | données exploitables et trois visualisations demandées visibles |
| **3** | HAProxy + deux backends | round-robin, détection de panne et réintégration automatique |

## Phrase de conclusion

> « Les trois exercices sont démontrés par leur résultat réel : l'infrastructure est créée et gérée avec Terraform, la configuration et le déploiement convergent avec Ansible, l'application Angular est servie par NGINX, les logs sont exploitables dans Amazon OpenSearch avec les visualisations demandées, et HAProxy répartit le trafic tout en maintenant le service lorsqu'un backend devient indisponible. »

---

# 9 — Mémo express pour l'oral

```text
PRÉSENTATION
Projet → 3 exercices → architecture globale

ARCHITECTURE EX1
AWS / VPC / 2 subnets
subnet 1 : p5-web t3.micro
Terraform crée → Ansible configure → NGINX sert Angular

ARCHITECTURE EX2
access.log + sample → parser → OpenSearch managé → Dashboards
1 × t3.small.search / gp3 10 Gio

ARCHITECTURE EX3
VPC Ex1
subnet 1 : HAProxy + backend 1
subnet 2 : backend 2
HAProxy → IP privées → round-robin + health checks

DÉMO EX1
Terraform output/show → plan → Ansible ping → playbook → navigateur Angular

DÉMO EX2
OpenSearch output → vrai log → verify → donut → bytes/12h → top5/12h → dashboard

DÉMO EX3
outputs → haproxy.cfg → navigateur round-robin → test 2→1→2 → navigateur final

CONCLUSION
3 architectures expliquées + 3 résultats prouvés
```

---

# 10 — Questions importantes à savoir défendre

## Pourquoi Terraform et Ansible ?

> Terraform gère le cycle de vie de l'infrastructure AWS. Ansible gère l'état de la machine et le déploiement applicatif. Les responsabilités sont séparées et rejouables.

## Pourquoi deux subnets dans l'exercice 1 alors qu'une seule EC2 y est déployée ?

> L'exercice 1 construit le socle réseau complet. Le premier subnet héberge `p5-web`; le second est réutilisé dans l'exercice 3 pour répartir les deux backends sur deux zones disponibles.

## Pourquoi `t3.micro` ?

> C'est la valeur par défaut du Terraform actuel. Les documents OpenClassrooms fournis contiennent des mentions contradictoires `t2.micro` / `t3.micro`; la configuration réelle du projet est explicitement `t3.micro` et reste paramétrable.

## Pourquoi OpenSearch plutôt qu'un ELK local ?

> OpenClassrooms propose explicitement un mode Cloud basé sur Amazon OpenSearch. Le projet suit cette option AWS.

## Pourquoi un seul nœud OpenSearch ?

> C'est un dimensionnement de lab. L'objectif de l'exercice est l'indexation, les agrégations et les visualisations, pas la construction d'un cluster de production multi-nœuds.

## Pourquoi un sample si le vrai log existe ?

> Le sample garantit la reproductibilité des tests. Le log réel démontre que la chaîne fonctionne aussi avec l'activité du NGINX réellement déployé dans l'exercice 1.

## Pourquoi les backends ont-ils une IP publique si le trafic doit passer par HAProxy ?

> Elles facilitent l'administration et le test contrôlé du lab. Le Security Group backend n'ouvre cependant le port 80 qu'au Security Group HAProxy : le trafic applicatif utilisateur passe par le load balancer.

## Le test de panne arrête-t-il toute l'EC2 ?

> Le script arrête le conteneur applicatif `nginx-hello` sur l'EC2. Il simule précisément l'indisponibilité du service que le health check HAProxy doit détecter, puis vérifie sa réintégration après redémarrage.

---

# 11 — Repli en cas d'incident pendant la présentation

## Angular

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
bash scripts/commands/p5.sh logs
```

## OpenSearch

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

Si le dashboard paraît vide, vérifier d'abord la plage temporelle et les filtres.

## HAProxy

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Ne pas lancer le failover si les deux backends ne sont pas sains au départ.

---

# 12 — Après l'assessment

Une fois les preuves conservées :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Ordre de fermeture :

```text
Exercice 3
   ↓
Exercice 2
   ↓
Exercice 1
   ↓
audit AWS
```

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

Ne jamais lancer `cleanup` avant la fin de la démonstration.
