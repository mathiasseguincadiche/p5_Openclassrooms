# Runbook de soutenance — P5 OpenClassrooms

## Objectif

Ce document est la **référence opérationnelle de la présentation du P5**. Il
organise la démonstration pour montrer que :

1. l'architecture est comprise ;
2. Terraform provisionne réellement l'infrastructure AWS ;
3. Ansible configure le serveur et déploie Angular ;
4. NGINX sert réellement l'application et produit ses logs ;
5. OpenSearch exploite ces vrais logs ;
6. OpenSearch Dashboards est reproductible grâce à une définition versionnée ;
7. HAProxy répartit le trafic et maintient le service pendant une panne ;
8. les preuves et journaux rendent le projet auditable.

Le runbook technique complet reste
[`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).

La règle principale de soutenance est simple : **le schéma explique, le terminal
prouve, le navigateur matérialise le résultat**.

---

# Partie A — Remettre le lab AWS en service avant l'oral

## A1. Principe

Le lab peut être détruit après les travaux afin d'éviter des frais AWS inutiles.
Cela ne supprime pas le projet : Terraform, Ansible, les scripts, les états et les
assets versionnés permettent de reconstruire l'environnement.

La reconstruction doit être faite **avant** la soutenance, jamais improvisée
devant le jury.

## A2. Repartir de `main`

```bash
cd ~/labs/p5_Openclassrooms
git switch main
git pull --ff-only
git status --short
```

**Observer** : aucune modification locale inattendue.

## A3. Observer avant de muter

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

**Verdict attendu avant déploiement** :

```text
GO TERRAFORM
```

Ne pas déployer tant que l'identité AWS, l'IPv4 d'administration `/32`, la clé
SSH, les `terraform.tfvars` ou le garde-fou de budget ne sont pas qualifiés.

## A4. Reconstruire les trois exercices

Préférer les commandes séparées :

```bash
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
```

Pourquoi cet ordre ?

```text
EX1
├── crée le VPC et les subnets utilisés par EX3
└── produit le vrai access.log utilisé par EX2

EX2
└── construit OpenSearch + Dashboard as Code

EX3
└── réutilise le réseau EX1 pour HAProxy + 2 backends
```

Les commandes séparées permettent de diagnostiquer une couche sans masquer le
problème dans un parcours complet.

## A5. Résultats minimums avant l'oral

| Couche | État attendu |
| --- | --- |
| Terraform ex. 1 | infrastructure présente, post-plan sans delta |
| Ansible | second passage `changed=0`, `unreachable=0`, `failed=0` |
| Angular / NGINX | application accessible en HTTP |
| NGINX | vrai `access.log` collecté |
| OpenSearch | données, mappings et agrégations vérifiés |
| Dashboards as Code | 5 Saved Objects importés et relus par API |
| Navigateur OpenSearch | 3 visualisations + dashboard lisibles |
| HAProxy | 2 backends observés |
| Failover | 2 → 1 → 2 backends, service maintenu |

## A6. Figer l'état prêt à présenter

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Puis :

```bash
terraform -chdir=terraform/exercice-1 plan -input=false -detailed-exitcode
terraform -chdir=terraform/exercice-2 plan -input=false -detailed-exitcode
terraform -chdir=terraform/exercice-3 plan -input=false -detailed-exitcode
```

L'idéal est un code retour `0` pour chaque exercice. Un code `2` signifie qu'un
delta existe et doit être compris avant la présentation.

**Ne pas exécuter `cleanup` avant la soutenance.** Les ressources actives restent
potentiellement facturables.

---

# Partie B — Introduire l'architecture

## B1. Le projet en une phrase

> Ce P5 met en œuvre un lab AWS reproductible où Terraform provisionne
> l'infrastructure, Ansible configure et déploie l'application, OpenSearch
> exploite les logs réels de NGINX, OpenSearch Dashboards est reconstruit comme
> du code, et HAProxy démontre la répartition de charge et la continuité de
> service pendant une panne contrôlée.

## B2. Montrer le schéma global

**Montrer** : [`schemas/vue-ensemble.svg`](schemas/vue-ensemble.svg).

```text
                    PLAN DE CONTRÔLE
                  WSL2 Ubuntu 26.04
                         │
             p5.sh / Terraform / Ansible
                         │
         ┌───────────────┼────────────────┐
         │               │                │
         ▼               ▼                ▼
    EXERCICE 1       EXERCICE 2       EXERCICE 3

 Terraform AWS      OpenSearch        HAProxy EC2
 VPC + subnets          ▲                  │
 SG + EC2 web           │             ┌────┴────┐
      │                  │             ▼         ▼
   Ansible               │          backend 1 backend 2
      │                  │
 NGINX + Angular         │
      │                  │
      └── access.log ────┘

 Exercice 1 ── VPC + subnets ─────────────► Exercice 3
```

### À expliquer

- Terraform possède l'infrastructure AWS ;
- Ansible possède la configuration de l'EC2 applicative ;
- NGINX sert Angular et produit les logs HTTP ;
- OpenSearch indexe et agrège les logs ;
- les Saved Objects versionnés reconstruisent la couche Dashboards ;
- HAProxy réutilise le réseau de l'exercice 1 ;
- les trois exercices ont de vraies dépendances.

---

# Partie C — Démonstration 1 : Terraform, Ansible et application

## C1. Montrer l'infrastructure réelle

```bash
terraform -chdir=terraform/exercice-1 output
```

**Observer** notamment :

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_url
```

Puis :

```bash
terraform -chdir=terraform/exercice-1 plan -input=false -detailed-exitcode
```

**Observer** : aucun changement si l'infrastructure est convergée.

### À expliquer

Terraform crée le VPC `10.0.0.0/16`, deux subnets publics, le routage Internet,
le Security Group et l'EC2 Ubuntu cible d'Ansible.

Terraform ne déploie pas l'application : cette responsabilité appartient à
Ansible.

## C2. Montrer la cible Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

**Observer** : `SUCCESS` / `pong`.

L'inventaire est généré depuis les outputs Terraform ; aucune IP AWS n'est
recopiée manuellement dans le parcours normal.

## C3. Montrer l'idempotence

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

**Observer au second passage** :

```text
changed=0
unreachable=0
failed=0
```

### À expliquer

Le playbook installe NGINX, déploie Angular sous `/var/www/p5`, installe la
configuration NGINX, vérifie `nginx -t` puis garantit le service actif.

`changed=0` prouve que la cible est déjà dans l'état désiré.

## C4. Ouvrir l'application

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
printf 'Application : %s\n' "$WEB_URL"
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Puis ouvrir `WEB_URL` dans le navigateur.

### Transition

> L'infrastructure est présente, la configuration est idempotente et
> l'application est servie. Je peux maintenant suivre son activité à partir des
> logs HTTP produits par NGINX.

---

# Partie D — Démonstration 2 : logs, OpenSearch et Dashboard as Code

## D1. Générer du trafic réel

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 12
```

Puis collecter le log actuel :

```bash
WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"

bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-presentation.log

tail -n 10 proofs/runtime/exercice-2/nginx-access-presentation.log
```

### À expliquer

Chaque ligne affichée correspond à une requête réellement reçue par NGINX. Le
sample versionné sert à la reproductibilité ; il ne doit pas être confondu avec
le log runtime de l'EC2.

## D2. Vérifier OpenSearch

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"

bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

**Observer** : mappings, documents et agrégations sans erreur.

Le flux à expliquer est :

```text
NGINX access.log
      ↓
parsing + typage
      ↓
Bulk API
      ↓
Amazon OpenSearch
      ↓
agrégations
```

## D3. Montrer que le dashboard est lui aussi reproductible

Avant l'oral, `p5.sh ex2` a déjà exécuté la synchronisation des Saved Objects.
Pendant la soutenance, il n'est pas nécessaire de recréer les graphiques dans
l'interface.

**Montrer éventuellement la source déclarative** :

```bash
sed -n '1,220p' \
  terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

Elle décrit explicitement :

```text
nginx-access-* / @timestamp
        │
        ├── donut http_method
        ├── Sum(bytes_sent) / 12 h
        └── Top 5 url_path / 12 h
                  │
                  ▼
        P5 — Observabilité NGINX
```

### À expliquer

> Je ne reconstruis pas ces objets manuellement après chaque destruction du
> domaine. Leur définition est versionnée. Le script génère les Saved Objects,
> contrôle les champs réels avec `_field_caps`, les importe avec écrasement
> contrôlé puis relit chacun des cinq objets via l'API.

Cela montre une démarche d'automatisation et de reproductibilité, pas seulement
une utilisation ponctuelle de l'interface graphique.

## D4. Ouvrir directement le dashboard

Le dashboard possède un ID stable :

```text
p5-nginx-observability
```

URL directe :

```bash
DASHBOARD_URL="${DASHBOARDS_URL%/}/app/dashboards#/view/p5-nginx-observability"
printf '%s\n' "$DASHBOARD_URL"
```

Ouvrir cette URL dans le navigateur et présenter :

1. le donut des méthodes HTTP ;
2. la somme de `bytes_sent` par tranches de 12 h ;
3. le top 5 de `url_path` par tranches de 12 h ;
4. le dashboard complet.

### À expliquer

Les champs ont un type exploitable :

- `http_method` est une catégorie agrégable ;
- `bytes_sent` est numérique ;
- `@timestamp` est une date ;
- `url_path` est une dimension agrégable.

### Ce qui est automatique et ce qui reste humain

```text
AUTOMATIQUE
mapping + documents
field_caps
index pattern
3 visualisations
dashboard
import API
relecture API
preuves techniques

HUMAIN
ouvrir le rendu
vérifier la lisibilité
vérifier la plage de temps
réaliser / présenter les captures
```

### Transition

> J'ai montré le déploiement et l'observabilité. La dernière partie vérifie
> maintenant le comportement du service lorsqu'un backend devient indisponible.

---

# Partie E — Démonstration 3 : HAProxy, répartition et panne

## E1. Présenter l'architecture

**Montrer** : [`schemas/exercice-3.svg`](schemas/exercice-3.svg).

```text
Internet
   │
   ▼
HAProxy :80
   │
   │ round-robin + health checks HTTP
   ├─────────────────┐
   ▼                 ▼
hello-1             hello-2
Docker              Docker
nginxdemos/hello    nginxdemos/hello
```

L'exercice 3 réutilise le VPC et les subnets de l'exercice 1.

## E2. Montrer les outputs réels

```bash
terraform -chdir=terraform/exercice-3 output
```

**Observer** : `haproxy_url`, IP HAProxy et IP des deux backends.

## E3. Montrer le comportement configuré

```bash
sed -n '1,120p' terraform/exercice-3/haproxy.cfg.tpl
```

À commenter :

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
check inter 3s fall 3 rise 2
```

## E4. Prouver le round-robin

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"

bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

**Observer** : les deux backends répondent.

## E5. Prouver la panne et la reprise

```bash
BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"

bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

Scénario attendu :

```text
AVANT
2 backends
    ↓
arrêt backend 1
    ↓
PENDANT
1 backend + service disponible
    ↓
redémarrage backend 1
    ↓
APRÈS
2 backends
```

Verdict attendu :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

La haute disponibilité est prouvée par le comportement réel, pas par la seule
présence du fichier `haproxy.cfg`.

---

# Partie F — Livrabilité et audit

## F1. Journaux

```bash
bash scripts/commands/p5.sh logs
```

Chaque session orchestrée écrit sous `logs/<UTC>/` et conserve les étapes
validées ou en échec.

## F2. Preuves OpenSearch Dashboards

Après synchronisation réelle, montrer si utile :

```bash
ls -1 proofs/runtime/exercice-2/*dashboards* 2>/dev/null
```

Les fichiers attendus comprennent :

```text
*-dashboards-saved-objects.ndjson
*-dashboards-import.json
*-dashboards-verify.json
```

Ils prouvent que le dashboard a été reconstruit par API. Les captures restent la
preuve visuelle du rendu.

## F3. Livrables

```bash
ls -1 docs/livrables/
```

Les trois familles de livrables couvrent :

1. Terraform / Ansible / NGINX ;
2. logs / OpenSearch / dashboard ;
3. HAProxy / `nginxdemos/hello`.

---

# Partie G — Conclusion technique

| Propriété | Preuve |
| --- | --- |
| **reproductibilité** | Terraform reconstruit AWS et le dashboard est versionné |
| **idempotence** | Ansible revient à `changed=0` |
| **observabilité** | le vrai `access.log` devient une donnée OpenSearch exploitable |
| **automatisation** | 5 Saved Objects Dashboards sont générés, importés et vérifiés |
| **résilience** | HAProxy maintient le service pendant une panne contrôlée |

Phrase de conclusion :

> L'important dans ce projet n'est pas seulement que chaque outil fonctionne
> séparément. L'infrastructure est décrite, la configuration converge,
> l'application est vérifiable, ses logs deviennent exploitables, la couche de
> visualisation est reproductible, la panne est testée et le cycle reste
> traçable jusqu'au nettoyage AWS.

---

# Partie H — Repli en cas d'incident de démonstration

## H1. Angular ne répond plus

```bash
terraform -chdir=terraform/exercice-1 output
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
bash scripts/commands/p5.sh logs
```

Qualifier réseau, SSH, Ansible et NGINX séparément avant toute mutation.

## H2. OpenSearch ou Dashboards ne répond plus

```bash
terraform -chdir=terraform/exercice-2 output
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

Pour la couche Dashboards, relire le log de `dashboards-assets-sync` et les
preuves API. Ne pas recréer les visualisations à la souris pour masquer un
problème d'accès ou de données.

Si l'interface est momentanément indisponible pendant l'oral, présenter les
captures consolidées en précisant clairement qu'il s'agit de la preuve
enregistrée, distincte du test live.

## H3. Un backend HAProxy ne revient pas

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Ne relancer un test de panne que lorsque les deux backends sont de nouveau
observés.

## H4. Session AWS expirée

```bash
bash scripts/commands/check-aws-session.sh
```

Réparer l'authentification ; ne jamais remplacer les outputs Terraform par des
valeurs inventées ou copiées sans contrôle.

---

# Partie I — Après la soutenance

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

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```

---

# Mémo de soutenance — une page

```text
1. ARCHITECTURE
   schéma global → expliquer les responsabilités

2. TERRAFORM
   outputs réels → plan sans delta

3. ANSIBLE
   ping → playbook → changed=0 / failed=0

4. APPLICATION
   WEB_URL → vérification → navigateur Angular

5. LOGS
   trafic réel → collecte access.log → tail

6. OPENSEARCH
   vérification mapping / documents / agrégations

7. DASHBOARD AS CODE
   montrer la définition versionnée si utile
   ouvrir directement P5 — Observabilité NGINX
   présenter les 3 visuels + dashboard

8. HAPROXY
   round-robin → panne → service maintenu → reprise

9. PREUVES
   logs + preuves API + livrables

10. CONCLUSION
    reproductible + idempotent + observable + automatisé + résilient

11. APRÈS
    cleanup 3 → 2 → 1 → NETTOYAGE AWS COMPLET
```

## À ne pas faire devant le jury

- reconstruire les trois exercices depuis zéro ;
- créer manuellement les trois visualisations OpenSearch ;
- accepter un `terraform apply` sans comprendre le plan ;
- présenter une CI verte comme preuve qu'AWS est actuellement déployé ;
- recopier des IP alors que Terraform les expose ;
- confondre le sample avec le vrai `access.log` ;
- montrer seulement `haproxy.cfg` sans tester la panne ;
- supprimer un `terraform.tfstate` pour « repartir proprement » ;
- afficher un secret, une clé privée ou un vrai `terraform.tfvars`.
