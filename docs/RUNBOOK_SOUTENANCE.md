# Runbook de soutenance — P5 OpenClassrooms

> **Fonction du document :** conducteur de démonstration du projet. Il doit permettre de suivre l'oral sans improviser : **expliquer l'architecture → montrer le code utile → prouver dans le terminal → montrer le résultat réel → conclure → enchaîner**.
>
> Le récit principal porte sur **le projet AWS et les trois exercices**. L'environnement local utilisé pour lancer les commandes n'est pas l'architecture présentée au jury.

# MODE SOUTENANCE — COMMENCER ICI

## Principe de démonstration

Pour chaque exercice, conserver toujours le même ordre :

```text
1. CE QUE J'AI CONSTRUIT
        ↓
2. POURQUOI CETTE ARCHITECTURE
        ↓
3. COMMENT C'EST CONFIGURÉ
        ↓
4. PREUVE TERMINAL
        ↓
5. PREUVE NAVIGATEUR
        ↓
6. CE QUE CELA DÉMONTRE
        ↓
7. TRANSITION
```

Le terminal ne remplace pas le résultat réel :

```text
Terraform / Ansible / scripts = preuve technique
Navigateur                   = résultat concret
Explication                  = compréhension du choix d'architecture
```

---

# 0 — AVANT L'ORAL : PRÉPARER LE LAB, PAS LE RECONSTRUIRE DEVANT LE JURY

Cette partie est exécutée **avant** la soutenance.

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

État minimum attendu avant l'oral :

| Couche | État attendu |
| --- | --- |
| Exercice 1 / Terraform | infrastructure présente et plan sans delta |
| Exercice 1 / Ansible | second passage `changed=0`, `unreachable=0`, `failed=0` |
| Angular / NGINX | application réellement visible dans le navigateur |
| NGINX | vrai `access.log` collecté |
| Exercice 2 / OpenSearch | données, mappings et agrégations validés |
| OpenSearch Dashboards | cinq Saved Objects importés et relus par API |
| Dashboard navigateur | trois visualisations lisibles |
| Exercice 3 / HAProxy | deux backends observables |
| Failover | scénario 2 → 1 → 2 validé |

Pendant l'oral : **ne pas reconstruire AWS** et **ne pas lancer `cleanup`**.

## Préparer les URLs avant l'entrée du jury

```bash
cd ~/labs/p5_Openclassrooms

export WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
export WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"
export OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
export DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
export DASHBOARD_URL="${DASHBOARDS_URL%/}/app/dashboards#/view/p5-nginx-observability"
export HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
export BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"

printf 'Angular   : %s\n' "$WEB_URL"
printf 'Dashboard : %s\n' "$DASHBOARD_URL"
printf 'HAProxy   : %s\n' "$HAPROXY_URL"
```

Préparer trois onglets navigateur :

```text
1. Application Angular    → WEB_URL
2. OpenSearch Dashboards  → DASHBOARD_URL
3. HAProxy                → HAPROXY_URL
```

---

# 1 — PRÉSENTER L'ARCHITECTURE GLOBALE DU PROJET

## Objectif

Donner au jury une vision claire du projet avant d'entrer dans les commandes.

Le projet est organisé en **trois exercices complémentaires** :

```text
┌──────────────────────────────────────────────────────────────────────┐
│                        PROJET P5 — AWS                              │
└──────────────────────────────────────────────────────────────────────┘

EXERCICE 1 — INFRASTRUCTURE ET DÉPLOIEMENT

Terraform
   │
   ├── VPC 10.0.0.0/16
   ├── 2 subnets publics
   ├── Internet Gateway + routage
   ├── Security Group
   ├── clé SSH
   └── EC2 t3.micro — Ubuntu 24.04 LTS
                          │
                       Ansible
                          │
                       NGINX
                          │
                       Angular
                          │
                     access.log
                          │
                          ▼

EXERCICE 2 — LOGS ET OBSERVABILITÉ

access.log NGINX
       │
       ├── parsing / typage
       └── Bulk API
              │
              ▼
      Amazon OpenSearch
      1 × t3.small.search
      EBS gp3 — 10 Gio
              │
              ▼
      OpenSearch Dashboards
              │
      ┌───────┼────────┐
      ▼       ▼        ▼
    Donut   bytes/12h  Top 5 URL/12h


EXERCICE 3 — RÉPARTITION DE CHARGE ET HAUTE DISPONIBILITÉ

VPC + subnets de l'exercice 1
              │
              ▼
       EC2 HAProxy t3.micro
              │
          round-robin
          /         \
         /           \
        ▼             ▼
EC2 t3.micro     EC2 t3.micro
 backend 1        backend 2
    │                │
  Docker           Docker
    │                │
nginx hello 1    nginx hello 2
```

## Les valeurs importantes à connaître

| Élément | Valeur du projet | Rôle |
| --- | --- | --- |
| Région AWS | `us-east-1` | région du lab |
| VPC | `10.0.0.0/16` | réseau principal créé à l'exercice 1 |
| Subnets | 2 publics | répartis sur les deux premières zones disponibles |
| EC2 exercice 1 | `t3.micro` | serveur cible Terraform/Ansible |
| OS EC2 | Ubuntu 24.04 LTS | système des EC2 du lab |
| OpenSearch | `OpenSearch_2.19` | moteur du domaine managé |
| Nœud OpenSearch | `t3.small.search` | instance unique du lab |
| Stockage OpenSearch | EBS `gp3`, 10 Gio | stockage du domaine |
| EC2 exercice 3 | 3 × `t3.micro` | 1 HAProxy + 2 backends |
| HTTP public | port 80 | application et HAProxy |
| SSH administration | port 22 depuis IP `/32` | administration limitée au poste autorisé |

## À dire

> « Mon projet est structuré en trois exercices qui se complètent. Dans le premier, Terraform provisionne l'infrastructure AWS et Ansible configure une instance EC2 pour déployer Angular derrière NGINX. Dans le deuxième, j'exploite les logs réels de ce serveur avec Amazon OpenSearch et un dashboard d'observabilité. Dans le troisième, je réutilise le réseau créé au premier exercice pour placer HAProxy devant deux instances applicatives et démontrer la répartition de charge ainsi que la continuité de service en cas de panne. »

## Ce que cette introduction doit faire comprendre

```text
Exercice 1 = construire et déployer
Exercice 2 = observer
Exercice 3 = répartir et résister à une panne
```

## Transition

> « Je commence par l'exercice 1 : comment l'infrastructure AWS est créée, puis comment l'application est déployée dessus. »

---

# 2 — EXERCICE 1 : TERRAFORM → EC2 → ANSIBLE → NGINX → ANGULAR

## Objectif

Démontrer que l'infrastructure et le déploiement applicatif sont reproductibles et séparés proprement.

## Architecture de l'exercice 1

```text
                           INTERNET
                              │
                       Internet Gateway
                              │
                     table de routage
                              │
                   VPC 10.0.0.0/16
                       /         \
                      /           \
                     ▼             ▼
              subnet public 1  subnet public 2
                     │
                     ▼
              Security Group
              ├── HTTP 80 : public
              └── SSH 22  : IP admin /32
                     │
                     ▼
              EC2 t3.micro
              Ubuntu 24.04
                     │
                  Ansible
                     │
              ┌──────┴──────┐
              ▼             ▼
            NGINX         Angular
              │             │
              └──── sert ────┘
                     │
                     ▼
                 Navigateur
```

## Pourquoi séparer Terraform et Ansible ?

```text
Terraform = infrastructure
Ansible   = configuration du système et déploiement
NGINX     = serveur HTTP
Angular   = application livrée
```

### À dire

> « Je sépare volontairement le provisionnement de la configuration. Terraform crée les ressources AWS : réseau, sécurité et EC2. Une fois la machine disponible, Ansible prend le relais pour installer NGINX, déployer l'artefact Angular et appliquer la configuration du serveur web. Cette séparation rend chaque responsabilité lisible et rejouable. »

## Ce que Terraform crée réellement

Le fichier de référence est :

```text
terraform/exercice-1/main.tf
```

Éléments principaux :

- VPC `10.0.0.0/16` avec DNS activé ;
- deux subnets publics ;
- Internet Gateway ;
- route `0.0.0.0/0` vers Internet ;
- Security Group HTTP/SSH ;
- clé publique SSH importée dans AWS ;
- EC2 `t3.micro` par défaut ;
- Ubuntu 24.04 LTS sélectionné automatiquement ;
- adresse IP publique ;
- disque racine EBS `gp3` chiffré ;
- IMDSv2 obligatoire ;
- `user_data` minimal qui installe uniquement Python 3 pour permettre à Ansible de prendre la main.

### Si le jury demande « t2.micro ou t3.micro ? »

Réponse :

> « Dans l'état actuel du projet, la valeur Terraform par défaut est `t3.micro`. Le type reste une variable afin de pouvoir l'adapter aux quotas et aux coûts du compte AWS. »

## Code à montrer si nécessaire

Pour afficher uniquement les ressources principales :

```bash
grep -nE 'resource "aws_(vpc|subnet|internet_gateway|route_table|security_group|key_pair|instance)"' \
  terraform/exercice-1/main.tf
```

Pour montrer le type d'instance :

```bash
grep -nA5 'variable "instance_type"' terraform/exercice-1/variables.tf
```

Ne pas lire tout `main.tf` devant le jury. Montrer seulement la partie qui répond à la question posée.

---

## DÉMONSTRATION 1A — Prouver l'infrastructure Terraform

### Terminal

```bash
terraform -chdir=terraform/exercice-1 output
```

À repérer :

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_public_dns
web_url
```

### À dire

> « Ces valeurs viennent de l'état Terraform et correspondent aux ressources réellement créées dans AWS. Je n'utilise pas d'IP recopiée manuellement pour piloter la suite. »

### Prouver la convergence

```bash
terraform -chdir=terraform/exercice-1 plan -input=false -detailed-exitcode
```

Résultat idéal : aucun changement.

### À dire

> « Le plan ne détecte plus de différence entre la configuration versionnée et l'état réel de l'infrastructure. Je peux donc démontrer que le lab est convergé. »

### Ce que cela démontre

- Infrastructure as Code ;
- reproductibilité ;
- traçabilité des ressources ;
- contrôle du delta avant mutation.

---

## DÉMONSTRATION 1B — Expliquer et prouver Ansible

### Architecture de configuration

```text
EC2 créée par Terraform
        │
        ▼
inventaire Ansible
        │
        ▼
deploy.yml
        │
        ├── installe NGINX + curl
        ├── crée appuser/appgroup
        ├── crée /var/www/p5
        ├── déploie l'artefact Angular
        ├── déploie la configuration NGINX
        ├── exécute nginx -t
        └── démarre / active NGINX
```

Le playbook de référence est :

```text
ansible/playbooks/deploy.yml
```

### À dire

> « Le `user_data` Terraform ne déploie pas l'application. Il prépare seulement le minimum nécessaire. Toute la configuration applicative est confiée à Ansible, ce qui évite de mélanger infrastructure et configuration. »

### Terminal — connectivité

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

### Terminal — idempotence

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Attendu sur un lab déjà convergé :

```text
changed=0
unreachable=0
failed=0
```

### À dire

> « Je rejoue exactement le même playbook sur une cible déjà configurée. `changed=0` montre qu'Ansible reconnaît que l'état souhaité est déjà atteint : le déploiement est idempotent. »

### Ce que cela démontre

- automatisation de configuration ;
- idempotence ;
- séparation des responsabilités ;
- capacité à cibler de nouveau une machine sans refaire les actions inutilement.

---

## DÉMONSTRATION 1C — Montrer réellement Angular dans le navigateur

Cette étape est **obligatoirement visuelle**. Un HTTP 200 seul ne suffit pas pour une application web.

### Terminal — preuve technique

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Le script contrôle notamment :

- HTTP 200 ;
- présence du document Angular ;
- bundle JavaScript principal accessible ;
- fallback SPA NGINX ;
- en-tête de sécurité `nosniff`.

### NAVIGATEUR — preuve concrète

Ouvrir l'onglet :

```text
WEB_URL
```

Montrer :

1. la page Angular réellement rendue ;
2. le contenu graphique de l'application ;
3. un rafraîchissement ;
4. éventuellement `WEB_URL/parcours-p5` pour montrer le fallback SPA.

### À dire

> « Le test terminal valide techniquement le déploiement. Ici, je montre le résultat final : l'application Angular est réellement accessible depuis le navigateur et servie par NGINX sur l'instance EC2. »

### Ce que cela démontre

```text
Terraform a créé la cible
        ↓
Ansible l'a configurée
        ↓
NGINX sert l'application
        ↓
Angular est réellement utilisable
```

## Transition vers l'exercice 2

> « Maintenant que l'application fonctionne, je vais utiliser l'activité réelle de son serveur NGINX comme source de données pour l'observabilité. »

---

# 3 — EXERCICE 2 : NGINX ACCESS.LOG → AMAZON OPENSEARCH → DASHBOARD

## Objectif

Démontrer comment les logs d'un serveur web réel deviennent des données structurées, interrogeables et visualisables.

## Architecture de l'exercice 2

```text
Navigateur
    │
    ▼
Application Angular
    │
    ▼
NGINX
    │
    └── /var/log/nginx/access.log
                │
                ▼
        collecte du log réel
                │
                ▼
        parsing / typage
                │
                ▼
            Bulk API
                │
                ▼
       Amazon OpenSearch
       OpenSearch 2.19
       1 × t3.small.search
       EBS gp3 — 10 Gio
                │
                ▼
       index nginx-access-*
                │
                ▼
          agrégations
                │
                ▼
       OpenSearch Dashboards
          /      |       \
         /       |        \
        ▼        ▼         ▼
      Donut   bytes/12h   Top5/12h
```

## Pourquoi cette architecture ?

### À dire

> « Je pars du `access.log` NGINX produit par le serveur web de l'exercice 1. Les lignes sont transformées en documents structurés, puis envoyées dans Amazon OpenSearch via la Bulk API. Les champs typés peuvent ensuite être agrégés et utilisés par OpenSearch Dashboards. »

## Infrastructure OpenSearch à connaître

Le Terraform de référence est :

```text
terraform/exercice-2/main.tf
```

Configuration actuelle :

| Paramètre | Valeur |
| --- | --- |
| Service | Amazon OpenSearch Service |
| Moteur | `OpenSearch_2.19` |
| Nombre de nœuds | 1 |
| Instance | `t3.small.search` |
| Stockage | EBS `gp3` |
| Taille | 10 Gio par défaut |
| HTTPS | obligatoire |
| TLS | minimum 1.2 |
| Chiffrement au repos | activé |
| Chiffrement inter-nœuds | activé |
| Accès | limité à l'adresse IP `/32` du lab |

### À dire

> « Comme il s'agit d'un lab pédagogique, le domaine utilise un seul nœud. J'ai néanmoins conservé les protections essentielles : HTTPS, TLS 1.2 minimum, chiffrement au repos, chiffrement inter-nœuds et restriction d'accès par IP. »

---

## DÉMONSTRATION 2A — Produire un log réel devant le jury

### Générer du trafic

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 12
```

### Collecter le vrai `access.log`

```bash
bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-presentation.log
```

### Montrer quelques lignes

```bash
tail -n 10 proofs/runtime/exercice-2/nginx-access-presentation.log
```

### À dire

> « Ces lignes viennent du NGINX AWS que je viens de montrer. Elles correspondent à de vraies requêtes reçues par le serveur. Le dataset versionné me sert à assurer la reproductibilité des tests, mais ici je démontre la chaîne avec le log runtime réel. »

### Ce que cela démontre

```text
application réelle
      ↓
trafic réel
      ↓
log réel
      ↓
source d'observabilité réelle
```

---

## DÉMONSTRATION 2B — Expliquer les champs avant les graphiques

Les champs principaux à connaître :

```text
@timestamp
    └── date/heure de la requête

http_method
    └── GET, POST, HEAD, etc.

bytes_sent
    └── volume envoyé par NGINX

url_path
    └── ressource demandée
```

Correspondance avec les visualisations :

```text
http_method
    ↓
répartition des verbes HTTP
    ↓
DONUT

bytes_sent
    ↓
somme des données envoyées
    ↓
HISTOGRAMME PAR 12 H

url_path
    ↓
requêtes les plus fréquentes
    ↓
TOP 5 PAR 12 H
```

### À dire

> « Avant d'afficher un graphique, il faut savoir ce que l'on agrège. `http_method` sert à la répartition des verbes HTTP, `bytes_sent` au volume transmis par le serveur, et `url_path` au classement des chemins les plus sollicités. »

---

## DÉMONSTRATION 2C — Prouver OpenSearch dans le terminal

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

À observer :

- documents présents ;
- mappings valides ;
- champs exploitables ;
- agrégations sans erreur.

### À dire

> « Avant de montrer le dashboard, je vérifie directement la couche données. Cela permet de distinguer un problème d'indexation d'un simple problème d'affichage dans Dashboards. »

---

## DÉMONSTRATION 2D — Expliquer le Dashboard as Code

La source de vérité est :

```text
terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

Afficher une vue courte :

```bash
jq '{index_pattern, visualizations, dashboard: {id: .dashboard.id, title: .dashboard.title}}' \
  terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

Chaîne d'automatisation :

```text
p5-dashboard.json
       │
       ▼
génération Saved Objects
       │
       ▼
contrôle _field_caps
       │
       ▼
import API avec overwrite contrôlé
       │
       ▼
relecture des 5 objets par API
       │
       ▼
validation visuelle humaine
```

Les cinq objets sont :

```text
1 index pattern
3 visualisations
1 dashboard
```

### À dire

> « Je ne reconstruis pas les graphiques manuellement après chaque destruction du lab. Leur définition est versionnée. L'automatisation vérifie les champs réels du domaine, génère et importe les Saved Objects, puis relit les objets par API. Je garde ensuite un contrôle humain du rendu dans le navigateur. »

### Ce que cela démontre

- reproductibilité ;
- automatisation ;
- réduction des opérations manuelles ;
- conservation d'un contrôle humain sur le résultat visuel.

---

## DÉMONSTRATION 2E — Montrer les trois visualisations dans le navigateur

### NAVIGATEUR

Ouvrir :

```text
DASHBOARD_URL
```

Titre attendu :

```text
P5 — Observabilité NGINX
```

Montrer dans cet ordre :

1. **Donut — répartition des méthodes HTTP** ;
2. **Histogramme — somme de `bytes_sent` par tranche de 12 h** ;
3. **Top 5 des `url_path` par tranche de 12 h** ;
4. **dashboard complet** avec les trois visualisations réunies.

### À dire

> « Le donut permet de voir quelles méthodes HTTP sont les plus utilisées. Le second graphique montre le volume cumulé envoyé par le serveur par fenêtres de 12 heures. Le troisième suit les cinq chemins les plus sollicités dans le temps. »

### Si un graphique paraît vide

Vérifier d'abord :

```text
plage temporelle
filtres actifs
données réellement présentes
```

Ne pas recréer le graphique à la souris pendant l'oral.

### Captures de secours à avoir avant la soutenance

```text
01-dashboard-complet
02-donut-methodes-http
03-histogramme-bytes-12h
04-top5-url-12h
```

Elles servent de preuve enregistrée en cas d'incident navigateur, pas de remplacement systématique à la démonstration live.

## Transition vers l'exercice 3

> « Après avoir démontré le déploiement et l'observabilité, je termine par la disponibilité : comment répartir le trafic sur plusieurs serveurs et maintenir le service lorsqu'un backend tombe. »

---

# 4 — EXERCICE 3 : HAPROXY → DEUX BACKENDS → PANNE → RÉINTÉGRATION

## Objectif

Démontrer la répartition de charge et la réaction automatique à la défaillance d'un backend.

## Architecture de l'exercice 3

L'exercice 3 **réutilise le VPC et les deux subnets publics créés à l'exercice 1**.

```text
                           INTERNET
                              │
                              ▼
                     Security Group HAProxy
                     ├── HTTP 80 public
                     └── SSH 22 depuis IP /32
                              │
                              ▼
                      EC2 HAProxy
                       t3.micro
                              │
                        round-robin
                       /           \
                      /             \
                     ▼               ▼
            EC2 backend 1       EC2 backend 2
               t3.micro            t3.micro
                  │                   │
                Docker              Docker
                  │                   │
           nginx-hello          nginx-hello
          p5-hello-1           p5-hello-2
```

## Réutilisation du réseau

### À dire

> « Je ne recrée pas un second VPC pour l'exercice 3. Terraform retrouve le VPC et les subnets de l'exercice 1 grâce aux tags. J'utilise donc une architecture cohérente où le réseau initial sert aussi à la démonstration de haute disponibilité. »

## Sécurité réseau à expliquer

```text
Internet
   │
   │ HTTP 80
   ▼
HAProxy
   │
   │ HTTP 80 autorisé par le Security Group HAProxy
   ▼
Backends
```

Les Security Groups des backends n'autorisent le trafic HTTP que depuis le Security Group HAProxy.

### À dire

> « Le point d'entrée applicatif est HAProxy. Les backends ne sont pas destinés à recevoir directement le trafic utilisateur sur HTTP : leur règle de sécurité autorise ce trafic depuis le Security Group du load balancer. »

> **Nuance du lab :** les EC2 backends disposent d'une IP publique pour les besoins d'administration et de démonstration, mais leur port HTTP reste filtré par le Security Group.

## Instances utilisées

```text
1 × EC2 t3.micro : HAProxy
2 × EC2 t3.micro : backends applicatifs
```

Les deux backends exécutent :

```text
Docker
  └── nginxdemos/hello:0.4-plain-text
      ├── hostname p5-hello-1
      └── hostname p5-hello-2
```

---

## DÉMONSTRATION 3A — Expliquer la configuration HAProxy

Fichier de référence :

```text
terraform/exercice-3/haproxy.cfg.tpl
```

Afficher seulement les directives utiles :

```bash
grep -E 'bind|default_backend|balance|httpchk|http-check|server hello' \
  terraform/exercice-3/haproxy.cfg.tpl
```

Configuration à savoir expliquer :

```text
bind *:80
    → HAProxy écoute sur HTTP 80

balance roundrobin
    → les requêtes sont réparties en alternance

option httpchk GET /
http-check expect status 200
    → HAProxy vérifie la santé en HTTP

inter 3s
    → contrôle toutes les 3 secondes

fall 3
    → 3 échecs consécutifs avant retrait

rise 2
    → 2 succès consécutifs avant réintégration
```

### À dire

> « HAProxy écoute sur le port 80 et répartit les requêtes en round-robin. Chaque backend est surveillé par une requête HTTP. Après trois échecs consécutifs, il est retiré de la rotation ; après deux contrôles réussis, il est réintégré. »

---

## DÉMONSTRATION 3B — Montrer le round-robin dans le navigateur

### NAVIGATEUR

Ouvrir :

```text
HAPROXY_URL
```

Dans la page `nginxdemos/hello`, repérer :

```text
Server address
Server name
```

Rafraîchir plusieurs fois.

Résultat attendu :

```text
rafraîchissement 1 → p5-hello-1
rafraîchissement 2 → p5-hello-2
rafraîchissement 3 → p5-hello-1
rafraîchissement 4 → p5-hello-2
```

L'ordre exact peut varier, mais **les deux backends doivent être observés**.

### À dire

> « Ici, la répartition est visible directement dans le navigateur : les réponses proviennent alternativement des deux backends. »

### Terminal — confirmer sur une série de requêtes

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Attendu : deux serveurs distincts observés.

### Ce que cela démontre

- load balancing ;
- utilisation effective des deux instances ;
- cohérence entre la configuration HAProxy et le comportement observable.

---

## DÉMONSTRATION 3C — Provoquer une panne contrôlée

Avant la commande, expliquer ce qui va se produire :

```text
ÉTAT NORMAL
2 backends disponibles
       │
       ▼
ARRÊT DU CONTENEUR SUR BACKEND 1
       │
       ▼
HAProxy détecte les échecs
       │
       ▼
backend 1 retiré de la rotation
       │
       ▼
backend 2 continue à répondre
       │
       ▼
REDÉMARRAGE BACKEND 1
       │
       ▼
HAProxy détecte les succès
       │
       ▼
backend 1 réintégré
       │
       ▼
2 backends disponibles
```

### Terminal

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

Le scénario doit montrer :

```text
AVANT       : 2 backends
PENDANT     : 1 backend, service toujours disponible
APRÈS       : 2 backends
```

Verdict attendu :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

### À dire pendant le test

> « Le script arrête uniquement le conteneur du backend ciblé. HAProxy doit détecter la panne et continuer à servir les requêtes avec l'instance restante. Le conteneur est ensuite redémarré et HAProxy doit le réintégrer automatiquement. »

### NAVIGATEUR — confirmer l'état final

Revenir sur :

```text
HAPROXY_URL
```

Rafraîchir plusieurs fois et montrer que les deux `Server name` sont de nouveau visibles.

### À dire

> « Le service n'a pas dépendu d'un serveur unique. Le backend défaillant a été retiré, le trafic a continué sur l'autre instance et le backend restauré a été réintégré automatiquement. »

### Ce que cela démontre

- health checks ;
- détection de panne ;
- continuité de service ;
- réintégration automatique ;
- compréhension du rôle d'un load balancer.

---

# 5 — RELIER LES TROIS EXERCICES : LE FIL CONDUCTEUR DU PROJET

À ce stade, le jury doit pouvoir résumer le projet de cette manière :

```text
EXERCICE 1
Je crée et je déploie
        │
        │ NGINX produit des logs
        ▼
EXERCICE 2
J'observe et j'analyse


EXERCICE 1
Je crée le réseau AWS
        │
        │ VPC + subnets réutilisés
        ▼
EXERCICE 3
Je répartis la charge et je teste la résilience
```

## À dire

> « Les exercices ne sont pas trois démonstrations isolées. Le premier crée le socle AWS et déploie l'application. Les logs réels de cette application alimentent le deuxième exercice. Le réseau du premier exercice est également réutilisé dans le troisième pour mettre en place la répartition de charge. »

C'est le message d'architecture global à faire retenir.

---

# 6 — CONCLUSION DE LA SOUTENANCE

## Preuves à rappeler sans tout rejouer

```bash
bash scripts/commands/p5.sh logs
```

Si nécessaire :

```bash
ls -1 proofs/runtime/exercice-2/*dashboards* 2>/dev/null
ls -1t proofs/runtime/exercice-3/*failover* 2>/dev/null | head
```

## Tableau de conclusion

| Propriété | Ce qui a été démontré |
| --- | --- |
| Infrastructure as Code | Terraform crée et décrit l'infrastructure AWS |
| Convergence | plan Terraform sans delta |
| Configuration automatisée | Ansible configure NGINX et Angular |
| Idempotence | second passage Ansible `changed=0` |
| Application fonctionnelle | Angular réellement affichée dans le navigateur |
| Observabilité | vrai `access.log` → OpenSearch → dashboard |
| Reproductibilité du dashboard | Saved Objects versionnés et synchronisés par API |
| Répartition de charge | deux backends visibles via HAProxy |
| Résilience | panne contrôlée 2 → 1 → 2 |
| Traçabilité | logs et preuves runtime |

## Phrase de conclusion

> « Ce projet montre une chaîne DevOps complète autour de l'infrastructure et de l'exploitation : Terraform rend l'infrastructure AWS reproductible, Ansible automatise la configuration et le déploiement, NGINX sert l'application et produit des logs exploitables, OpenSearch transforme ces logs en observabilité, et HAProxy démontre la répartition de charge ainsi que la continuité de service pendant une panne contrôlée. »

---

# 7 — MÉMO ULTRA-COURT — À UTILISER SI JE DOIS ALLER VITE

```text
1  ARCHITECTURE PROJET
   Ex1 construire/déployer → Ex2 observer → Ex3 répartir/résilier

2  EX1 — TERRAFORM
   VPC + 2 subnets + SG + EC2 t3.micro
   output → plan sans delta

3  EX1 — ANSIBLE
   ping → deploy.yml → changed=0

4  EX1 — ANGULAR
   verify-angular → NAVIGATEUR → montrer l'application

5  EX2 — LOG RÉEL
   trafic → collecte access.log → tail

6  EX2 — OPENSEARCH
   t3.small.search + gp3 10 Gio
   verify-opensearch-data

7  EX2 — DASHBOARD
   expliquer Dashboard as Code
   NAVIGATEUR → donut → bytes/12h → top5/12h

8  EX3 — ARCHITECTURE
   VPC Ex1 → HAProxy t3.micro → 2 × EC2 t3.micro

9  EX3 — ROUND-ROBIN
   NAVIGATEUR → rafraîchir → 2 Server name

10 EX3 — FAILOVER
   terminal → 2 → 1 → 2
   NAVIGATEUR → deux backends revenus

11 CONCLUSION
   IaC + idempotence + application + observabilité + résilience
```

---

# 8 — QUESTIONS TECHNIQUES PROBABLES DU JURY

## Pourquoi Terraform et Ansible ensemble ?

> Terraform gère les ressources d'infrastructure ; Ansible gère la configuration de la machine et le déploiement. Cette séparation évite de transformer le `user_data` en script de configuration monolithique.

## Quel type d'instance EC2 utilisez-vous ?

> Les EC2 des exercices 1 et 3 utilisent `t3.micro` par défaut. Le type est paramétrable par variable Terraform.

## Pourquoi deux subnets publics alors que l'exercice 1 n'utilise qu'une EC2 ?

> Le réseau est construit avec deux subnets sur deux zones disponibles et il est réutilisé ensuite par l'exercice 3, où les deux backends sont répartis sur ces subnets.

## Pourquoi Python 3 dans le `user_data` ?

> Pour préparer la cible Ubuntu à l'exécution des modules Ansible. La configuration de l'application reste dans le playbook.

## Pourquoi le deuxième passage Ansible est important ?

> Il prouve l'idempotence : une cible déjà conforme ne doit pas être modifiée inutilement.

## Quelle est la différence entre le sample NGINX et le log réel ?

> Le sample est versionné pour rendre les tests reproductibles. Le log réel est collecté depuis le NGINX AWS et prouve le fonctionnement de la chaîne sur l'application réellement déployée.

## Pourquoi Amazon OpenSearch ?

> Le projet utilise le mode Cloud avec un service managé AWS. Cela fournit le moteur d'indexation et OpenSearch Dashboards sans devoir administrer soi-même tout un cluster de recherche pour ce lab.

## Pourquoi un seul nœud OpenSearch ?

> C'est un choix de dimensionnement de lab. L'objectif est de démontrer ingestion, mapping, agrégations et visualisation, pas de construire un cluster OpenSearch de production.

## Pourquoi automatiser le dashboard ?

> Pour rendre la reconstruction reproductible. Après destruction puis recréation du domaine, les visualisations peuvent être réinstallées depuis le dépôt au lieu d'être recréées manuellement.

## Comment HAProxy sait-il qu'un serveur est en panne ?

> Il effectue un `GET /` et attend un statut HTTP 200. Avec `fall 3`, trois contrôles en échec provoquent le retrait du backend ; `rise 2` demande deux contrôles réussis avant sa réintégration.

## Les backends sont-ils directement accessibles en HTTP depuis Internet ?

> Leur EC2 dispose d'une IP publique dans ce lab, mais le Security Group du backend n'autorise le port 80 que depuis le Security Group HAProxy. Le flux applicatif utilisateur passe donc par le load balancer.

---

# 9 — REPLI EN CAS D'INCIDENT PENDANT L'ORAL

## Angular ne s'affiche plus

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
bash scripts/commands/p5.sh logs
```

Si la preuve technique est saine mais que le navigateur pose problème, utiliser une capture en précisant qu'il s'agit d'une preuve enregistrée avant l'oral.

## Dashboard vide ou inaccessible

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"

ls -1 proofs/runtime/exercice-2/*dashboards* 2>/dev/null
```

Vérifier d'abord la plage temporelle et les filtres. Ne pas reconstruire les visualisations manuellement devant le jury.

## HAProxy n'affiche qu'un backend avant le test de panne

Ne pas lancer le failover.

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Le test de panne n'est pertinent que lorsque les deux backends sont sains au départ.

## Session AWS expirée

```bash
bash scripts/commands/check-aws-session.sh
```

Réparer l'authentification avant de poursuivre. Ne jamais remplacer un output Terraform par une valeur inventée.

---

# 10 — APRÈS LA SOUTENANCE

Une fois les preuves conservées :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Ordre de destruction :

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

---

# 11 — À NE PAS FAIRE DEVANT LE JURY

- commencer la présentation par l'environnement local au lieu de l'architecture du projet ;
- détailler WSL2, Windows ou le poste de travail sans que le jury le demande ;
- reconstruire les trois exercices depuis zéro ;
- lancer un `terraform apply` sans lire le plan ;
- parcourir de longs fichiers de code sans objectif précis ;
- perdre du temps dans la console AWS à chercher une ressource ;
- se contenter d'un HTTP 200 sans montrer Angular dans le navigateur ;
- présenter un sample comme s'il s'agissait du vrai log NGINX ;
- recréer manuellement les visualisations OpenSearch ;
- présenter seulement `haproxy.cfg` sans montrer le round-robin ;
- lancer le failover si un seul backend est déjà disponible ;
- afficher une clé privée, un secret, un mot de passe ou un vrai `terraform.tfvars` ;
- lancer `cleanup` avant la fin de la soutenance.

---

# 12 — ANNEXE : ENVIRONNEMENT DE CONTRÔLE, UNIQUEMENT SI LE JURY LE DEMANDE

Cette information n'appartient pas au récit d'architecture principal.

Réponse courte possible :

> « J'exécute mes outils d'administration depuis un environnement Linux local dédié au travail DevOps. Cet environnement sert uniquement de plan de contrôle ; les ressources démontrées dans ce projet sont les ressources AWS décrites dans les trois exercices. »

Revenir immédiatement au projet :

```text
Terraform → AWS → Ansible → NGINX/Angular → OpenSearch → HAProxy
```
