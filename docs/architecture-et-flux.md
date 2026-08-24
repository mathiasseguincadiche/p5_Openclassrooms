# Architecture et flux du P5

## Objectif

Ce document est la **référence d'architecture du projet**. Il explique comment les trois exercices s'emboîtent, quelles ressources AWS existent, qui possède chaque responsabilité, quels flux circulent et pourquoi l'ordre d'exécution est important.

Pour une démonstration guidée devant le jury, utiliser [`RUNBOOK_SOUTENANCE.md`](RUNBOOK_SOUTENANCE.md). Pour exécuter le projet pas à pas, utiliser [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).

## 1. Vue globale

![Architecture globale du P5](schemas/vue-ensemble.svg)

Le projet se lit en trois verbes :

```text
CONSTRUIRE ET DÉPLOYER
        ↓
OBSERVER
        ↓
RÉPARTIR ET RÉSISTER
```

| Exercice | But | Résultat concret |
| --- | --- | --- |
| Exercice 1 | créer le socle AWS et livrer Angular | application visible dans le navigateur |
| Exercice 2 | transformer les logs NGINX en indicateurs | dashboard OpenSearch |
| Exercice 3 | répartir le trafic et tester la panne | service maintenu pendant un failover |

Deux dépendances donnent sa cohérence au projet :

```text
Exercice 1 ── access.log ──► Exercice 2
Exercice 1 ── VPC/subnets ─► Exercice 3
```

## 2. Responsabilités

Le dépôt orchestre plusieurs outils, mais leurs responsabilités restent distinctes.

| Composant | Responsabilité |
| --- | --- |
| Terraform | créer et maintenir les ressources AWS |
| state Terraform | mémoriser la propriété et l'état des ressources gérées |
| Ansible | configurer l'EC2 de l'exercice 1 et déployer Angular |
| NGINX | servir Angular et produire les logs HTTP |
| Angular | application web livrée |
| parser NGINX | transformer les lignes de log en documents structurés |
| Amazon OpenSearch | indexer et agréger les documents |
| OpenSearch Dashboards | rendre les agrégations visibles |
| HAProxy | répartir les requêtes et surveiller les backends |
| `p5.sh` | orchestrer les étapes, garde-fous, preuves et ordre d'exécution |

La règle d'architecture la plus importante est :

```text
Terraform crée.
Ansible configure.
NGINX sert.
OpenSearch observe.
HAProxy répartit.
```

## 3. Exercice 1 — infrastructure et déploiement

![Architecture de l'exercice 1](schemas/exercice-1.svg)

### 3.1 Ce que Terraform crée

Le module [`terraform/exercice-1/`](../terraform/exercice-1/) crée le socle réseau et la cible de déploiement.

```text
AWS us-east-1
└── VPC 10.0.0.0/16
    ├── subnet public 1
    ├── subnet public 2
    ├── Internet Gateway
    ├── table de routage publique
    ├── Security Group p5-web
    ├── EC2 Key Pair
    └── EC2 p5-web
```

La cible `p5-web` utilise par défaut :

| Élément | Valeur |
| --- | --- |
| type EC2 | `t3.micro` |
| OS | Ubuntu 24.04 LTS |
| volume racine | EBS `gp3` chiffré |
| metadata | IMDSv2 obligatoire |
| bootstrap | Python 3 uniquement |

### 3.2 Pourquoi deux subnets ?

Deux subnets publics sont créés dans les deux premières zones de disponibilité disponibles.

Le second subnet n'est pas un doublon inutile : le réseau est volontairement construit comme un **socle réutilisable**. L'exercice 3 retrouve ensuite ces subnets et répartit ses backends sur ce réseau.

### 3.3 Flux Internet

```text
Internet
   │ HTTP :80
   ▼
Internet Gateway
   ▼
route 0.0.0.0/0
   ▼
Security Group p5-web
   ▼
EC2 p5-web
   ▼
NGINX
   ▼
Angular
```

Le Security Group distingue deux usages :

| Port | Source | Usage |
| --- | --- | --- |
| TCP/80 | `0.0.0.0/0` | accès public à l'application |
| TCP/22 | IPv4 admin `/32` | administration SSH / Ansible |

### 3.4 Flux Terraform → Ansible

Terraform ne déploie pas Angular.

Le `user_data` installe uniquement Python 3 afin de rendre la cible administrable par Ansible.

```text
Terraform
   ↓
EC2 créée
   ↓
output IP / DNS
   ↓
inventaire Ansible
   ↓
SSH
   ↓
deploy.yml
```

### 3.5 Ce qu'Ansible configure

Le playbook [`ansible/playbooks/deploy.yml`](../ansible/playbooks/deploy.yml) :

```text
installe NGINX + curl
      ↓
crée appuser / appgroup
      ↓
crée /var/www/p5
      ↓
copie l'artefact Angular
      ↓
installe la configuration NGINX
      ↓
nginx -t
      ↓
active et démarre NGINX
```

Les handlers évitent de recharger NGINX lorsque rien n'a changé.

### 3.6 Convergence et idempotence

Deux propriétés différentes sont démontrées :

```text
Terraform
plan sans delta
= infrastructure convergée

Ansible
changed=0
= configuration idempotente
```

Terraform répond à « faut-il modifier l'infrastructure ? ».

Ansible répond à « faut-il modifier la configuration de la machine ? ».

### 3.7 Sortie de l'exercice 1

L'exercice produit deux résultats utiles :

```text
1. application Angular visible
2. /var/log/nginx/access.log
```

Le premier prouve le déploiement. Le second devient une entrée de l'exercice 2.

---

## 4. Exercice 2 — logs et observabilité

![Flux de l'exercice 2](schemas/exercice-2.svg)

### 4.1 Problème traité

Une ligne de log NGINX est d'abord du texte. Pour calculer une somme, un top ou une répartition, elle doit devenir un document structuré avec des types cohérents.

```text
ligne texte
   ↓
parsing
   ↓
document structuré
   ↓
mapping
   ↓
agrégation
   ↓
visualisation
```

### 4.2 Deux sources de données

Le pipeline accepte :

```text
sample versionné
        ┐
        ├──► parser
        │
access.log réel
        ┘
```

Le sample rend les tests reproductibles.

Le log réel prouve que l'observabilité est reliée à l'application AWS réellement déployée.

### 4.3 Transformation

Le convertisseur [`scripts/tools/convert-nginx-logs.py`](../scripts/tools/convert-nginx-logs.py) produit des documents adaptés à la Bulk API.

Les champs essentiels sont :

| Champ | Type attendu | Usage |
| --- | --- | --- |
| `@timestamp` | date | axe temporel |
| `http_method` | keyword | répartition des méthodes |
| `bytes_sent` | numérique | somme du volume envoyé |
| `url_path` | keyword | top des chemins |

Un mauvais mapping peut donc laisser les données présentes tout en empêchant une visualisation correcte.

### 4.4 Domaine Amazon OpenSearch

Le module [`terraform/exercice-2/`](../terraform/exercice-2/) crée un domaine managé.

| Paramètre | Valeur de référence |
| --- | --- |
| moteur | `OpenSearch_2.19` |
| nombre d'instances | 1 |
| type | `t3.small.search` |
| stockage | EBS `gp3` |
| taille | 10 Gio |
| HTTPS | obligatoire |
| TLS | minimum 1.2 |
| chiffrement au repos | activé |
| chiffrement inter-nœuds | activé |
| contrôle d'accès | IP d'administration `/32` |

Le nœud unique correspond au dimensionnement d'un lab pédagogique, pas à une architecture OpenSearch de production hautement disponible.

### 4.5 Flux d'ingestion

```text
access.log / sample
        ↓
convert-nginx-logs.py
        ↓
NDJSON Bulk
        ↓
index-template.json
        ↓
Bulk API
        ↓
nginx-access-*
        ↓
verify-opensearch-data.sh
```

La vérification porte sur les documents, mappings et agrégations avant même d'ouvrir l'interface graphique.

### 4.6 Dashboard as Code

La source de vérité visuelle est :

```text
terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

La chaîne est :

```text
définition versionnée
        ↓
génération Saved Objects
        ↓
_field_caps
        ↓
import API
        ↓
relecture API
        ↓
validation navigateur
```

Les cinq objets attendus sont :

```text
1 index pattern
3 visualisations
1 dashboard
```

L'automatisation rend la reconstruction reproductible. Le contrôle visuel humain reste nécessaire pour confirmer que les graphiques sont réellement lisibles.

### 4.7 Les trois visualisations

| Visualisation | Champ | Question |
| --- | --- | --- |
| donut | `http_method` | quelles méthodes HTTP dominent ? |
| somme / 12 h | `bytes_sent` | quel volume le serveur envoie-t-il ? |
| top 5 / 12 h | `url_path` | quels chemins sont les plus sollicités ? |

### 4.8 Sortie de l'exercice 2

Le résultat attendu n'est pas seulement « OpenSearch répond ».

Il faut pouvoir montrer :

```text
données présentes
+
mappings corrects
+
agrégations correctes
+
3 visualisations
+
dashboard complet
```

---

## 5. Exercice 3 — HAProxy et résilience

![Architecture et failover de l'exercice 3](schemas/exercice-3.svg)

### 5.1 Réutilisation du réseau

L'exercice 3 ne crée pas de nouveau VPC.

Terraform utilise des data sources filtrées par tags afin de retrouver :

```text
VPC p5-vpc
+
subnets publics de l'exercice 1
```

Cette dépendance explique pourquoi l'exercice 1 doit exister avant l'exercice 3.

### 5.2 Topologie

```text
Internet
   │ HTTP :80
   ▼
EC2 HAProxy
   │
   ├──► backend 1
   └──► backend 2
```

Les trois EC2 utilisent `t3.micro` par défaut.

Les backends exécutent :

```text
Docker
└── nginxdemos/hello:0.4-plain-text
```

### 5.3 Security Groups

Le flux applicatif est intentionnellement orienté vers HAProxy.

```text
Internet
   │
   ▼
SG HAProxy
   │ HTTP :80
   ▼
HAProxy
   │
   ▼
SG backends
   │ HTTP :80 autorisé depuis SG HAProxy
   ▼
backends
```

Les backends ont une IP publique dans le contexte du lab, mais leur port HTTP n'est pas ouvert à Internet entier.

### 5.4 Round-robin

Le template [`terraform/exercice-3/haproxy.cfg.tpl`](../terraform/exercice-3/haproxy.cfg.tpl) contient :

```text
balance roundrobin
```

Lorsque les deux backends sont sains, les requêtes sont distribuées entre eux.

Le navigateur permet de matérialiser cette répartition grâce à `Server name` et `Server address`.

### 5.5 Health checks

HAProxy exécute :

```text
GET /
```

et attend :

```text
HTTP 200
```

Les paramètres sont :

| Paramètre | Effet |
| --- | --- |
| `inter 3s` | intervalle entre deux contrôles |
| `fall 3` | trois échecs avant passage DOWN |
| `rise 2` | deux succès avant retour UP |

### 5.6 Scénario dynamique

```text
2 backends UP
      ↓
arrêt backend 1
      ↓
3 checks KO
      ↓
backend 1 DOWN
      ↓
trafic vers backend 2
      ↓
service maintenu
      ↓
backend 1 redémarre
      ↓
2 checks OK
      ↓
backend 1 UP
      ↓
retour à 2 backends
```

La preuve porte sur le **comportement** et non uniquement sur la présence de `balance roundrobin` dans un fichier.

### 5.7 Sortie de l'exercice 3

Le résultat attendu est :

```text
AVANT   : deux backends observés
PENDANT : un backend, HTTP reste disponible
APRÈS   : deux backends observés
```

Verdict :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

---

## 6. Flux transverses

### 6.1 Flux applicatif

```text
navigateur
   ↓
NGINX
   ↓
Angular
```

### 6.2 Flux de logs

```text
requête HTTP
   ↓
NGINX
   ↓
access.log
   ↓
parser
   ↓
OpenSearch
   ↓
Dashboards
```

### 6.3 Flux HAProxy

```text
client
   ↓
HAProxy
   ↓
backend sain
```

### 6.4 Flux d'administration

Les flux d'administration sont différents des flux utilisateurs.

```text
administration SSH
        ↓
IP /32
        ↓
EC2

utilisateur HTTP
        ↓
port 80
        ↓
NGINX ou HAProxy
```

---

## 7. Sources de vérité

La documentation décrit le système ; elle ne doit pas devenir une deuxième configuration.

| Domaine | Source de vérité |
| --- | --- |
| ressources Ex. 1 | `terraform/exercice-1/` |
| configuration Ex. 1 | `ansible/playbooks/deploy.yml` + `ansible/files/` |
| application | `application/angular/` |
| ressources Ex. 2 | `terraform/exercice-2/` |
| mapping OpenSearch | `terraform/exercice-2/opensearch/index-template.json` |
| dashboard | `terraform/exercice-2/opensearch/dashboards/p5-dashboard.json` |
| ressources Ex. 3 | `terraform/exercice-3/` |
| comportement HAProxy | `terraform/exercice-3/haproxy.cfg.tpl` |
| orchestration | `scripts/commands/p5.sh` |
| preuves runtime | `scripts/lib/p5-runtime.sh` |
| règles documentaires | `MATRICE_TRACABILITE.md` |

---

## 8. Convergence et réexécution

Le projet ne considère pas « rejouer » comme « tout recréer ».

Pour Terraform :

```text
state existant
      ↓
plan
      ↓
delta ?
  ┌───┴───┐
 non     oui
  │       │
stop    appliquer le plan validé
```

Pour Ansible :

```text
état cible
   ↓
playbook
   ↓
écart ?
  ┌─┴─┐
 non oui
  │   │
changed=0
    corriger
```

La convergence repose sur la conservation du state et sur le recalcul du delta.

Voir [`convergence-et-reexecution.md`](convergence-et-reexecution.md).

---

## 9. Preuves

Une configuration n'est pas automatiquement une preuve d'exécution.

Le projet distingue :

```text
CODE
ce qui devrait arriver

PREUVE TERMINAL
ce que les outils ont réellement observé

PREUVE NAVIGATEUR
ce que l'utilisateur peut réellement voir
```

Exemples :

| Affirmation | Preuve adaptée |
| --- | --- |
| Terraform est convergé | plan sans delta |
| Ansible est idempotent | `changed=0` |
| Angular fonctionne | navigateur + vérification HTTP |
| OpenSearch contient les logs | vérification documents/mappings/aggs |
| dashboard fonctionne | navigateur |
| HAProxy répartit | deux backends observés |
| failover fonctionne | scénario réel `2 → 1 → 2` |

---

## 10. Dépendances d'exécution

```text
prepare
   ↓
status
   ↓
ex1
 ├──► ex2 via access.log
 └──► ex3 via VPC/subnets
   ↓
diagnostics
   ↓
finalize
```

Nuance :

- le pipeline Ex. 2 dispose d'un sample et peut être testé sans log réel ;
- la preuve de bout en bout de l'Ex. 2 utilise le log réel de l'Ex. 1 ;
- l'Ex. 3 dépend réellement du réseau Ex. 1.

---

## 11. Ordre de destruction

Les dépendances imposent l'ordre de fermeture :

```text
Exercice 3
    ↓
Exercice 2
    ↓
Exercice 1
    ↓
audit AWS
```

L'exercice 3 est détruit avant l'exercice 1 parce qu'il réutilise son réseau.

Le verdict final attendu est :

```text
NETTOYAGE AWS COMPLET
```

---

## 12. Sécurité structurante

Les garde-fous principaux sont :

- `allowed_account_ids` dans les providers Terraform ;
- accès SSH limité à une IPv4 `/32` ;
- accès OpenSearch limité à l'IPv4 `/32` ;
- HTTPS et TLS 1.2 minimum pour OpenSearch ;
- chiffrement EBS et OpenSearch ;
- IMDSv2 sur les EC2 ;
- port HTTP des backends autorisé depuis le SG HAProxy ;
- états, tfvars réels, inventaires réels et secrets non versionnés.

---

## 13. Annexe — environnement de contrôle local

L'environnement local existe pour **piloter** le projet ; il n'est pas la topologie AWS démontrée au jury.

Le contexte de référence est :

```text
Windows 11 Pro
└── WSL2
    └── Ubuntu 26.04
        └── checkout P5 sur filesystem Linux
```

Les EC2 AWS des exercices 1 et 3 utilisent, elles, Ubuntu 24.04 LTS par défaut.

Cette distinction évite de confondre :

```text
poste de contrôle
≠
ressources AWS du projet
```

Pour le contrat d'environnement local, voir [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

---

## 14. Documents associés

- [`RUNBOOK_SOUTENANCE.md`](RUNBOOK_SOUTENANCE.md) — démonstration orale ;
- [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md) — exécution complète ;
- [`GLOSSAIRE.md`](GLOSSAIRE.md) — vocabulaire ;
- [`schemas/README.md`](schemas/README.md) — langage visuel ;
- [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md) — documentation ↔ code ;
- [`troubleshooting.md`](troubleshooting.md) — diagnostic ;
- [`CONVENTIONS_DOCUMENTAIRES.md`](CONVENTIONS_DOCUMENTAIRES.md) — règles de rédaction.
