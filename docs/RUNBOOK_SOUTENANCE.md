# Runbook soutenance P5 — moins de 20 minutes

> **But :** présenter l'architecture, lancer les preuves utiles, montrer le résultat dans le navigateur.
>
> **Règle :** schéma → 2 phrases d'explication → commande → résultat → navigateur.

## Avant l'oral — hors chrono

```bash
cd ~/labs/p5_Openclassrooms
git switch main
git pull --ff-only
bash scripts/commands/p5.sh status
```

Préparer les variables :

```bash
export WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
export OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
export DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
export DASHBOARD_URL="${DASHBOARDS_URL%/}/app/dashboards#/view/p5-nginx-observability"
export HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
export BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"
```

Ouvrir trois onglets :

```text
1. $WEB_URL
2. $DASHBOARD_URL
3. $HAPROXY_URL
```

Ne pas lancer `cleanup` avant la fin de la soutenance.

---

# 0:00 → 1:00 — Présenter le projet

## Afficher

![Vue d'ensemble](schemas/vue-ensemble.svg)

## Dire

> « Le projet contient trois exercices. Le premier provisionne AWS avec Terraform puis déploie Angular avec Ansible et NGINX. Le deuxième exploite les logs NGINX dans Amazon OpenSearch. Le troisième met HAProxy devant deux backends pour démontrer la répartition de charge et la reprise après panne. »

## Enchaîner

```text
Ex. 1 : construire et déployer
Ex. 2 : observer les logs
Ex. 3 : répartir et résister
```

---

# 1:00 → 6:00 — Exercice 1 — Terraform + Ansible + Angular

## 1:00 → 2:30 — Architecture

### Afficher

![Architecture exercice 1](schemas/exercice-1.svg)

### Dire

> « Terraform crée dans `us-east-1` un VPC `10.0.0.0/16`, deux subnets publics et l'EC2 `p5-web` en `t3.micro` dans le premier subnet. Ansible se connecte ensuite en SSH, installe NGINX et déploie Angular. Le deuxième subnet sera réutilisé dans l'exercice 3. »

### À pointer sur le schéma

```text
VPC 10.0.0.0/16
├── subnet public 1 → p5-web · t3.micro · Ubuntu 24.04
└── subnet public 2 → réutilisé par Ex. 3

HTTP 80 → NGINX → Angular
SSH 22  → Ansible
```

## 2:30 → 3:15 — Prouver Terraform

```bash
terraform -chdir=terraform/exercice-1 output
```

### Vérifier

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_url
```

Puis :

```bash
terraform -chdir=terraform/exercice-1 plan \
  -input=false \
  -detailed-exitcode
```

### Résultat attendu

```text
No changes
```

### Dire

> « Terraform gère bien l'infrastructure et le plan est convergé. »

## 3:15 → 4:00 — Prouver la connexion Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

### Résultat attendu

```text
SUCCESS
ping: pong
```

## 4:00 → 5:00 — Prouver le déploiement Ansible

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

### Résultat attendu sur un environnement déjà convergé

```text
changed=0
unreachable=0
failed=0
```

### Dire

> « Ansible configure NGINX et déploie Angular. `changed=0` montre que la configuration est déjà conforme. »

## 5:00 → 6:00 — Montrer Angular

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$WEB_URL"
```

### Navigateur

Ouvrir ou revenir sur :

```text
$WEB_URL
```

### Montrer

```text
application Angular affichée
HTTP 200
rafraîchissement fonctionnel
```

### Transition

> « L'application fonctionne. J'utilise maintenant ses logs HTTP dans l'exercice 2. »

---

# 6:00 → 10:30 — Exercice 2 — Logs + Amazon OpenSearch

## 6:00 → 7:30 — Architecture

### Afficher

![Architecture exercice 2](schemas/exercice-2.svg)

### Dire

> « Le NGINX de l'exercice 1 produit `access.log`. Les logs sont parsés et envoyés à Amazon OpenSearch Service, puis OpenSearch Dashboards affiche les trois visualisations demandées. OpenSearch est ici un service AWS managé, pas une EC2 du VPC. »

### À pointer sur le schéma

```text
access.log
→ parsing / typage
→ Bulk API
→ Amazon OpenSearch
→ OpenSearch Dashboards
```

Configuration utile :

```text
OpenSearch 2.19
1 × t3.small.search
EBS gp3 · 10 Gio
HTTPS
```

## 7:30 → 8:00 — Prouver OpenSearch

```bash
terraform -chdir=terraform/exercice-2 output
```

### Vérifier

```text
opensearch_domain_name
opensearch_endpoint
opensearch_dashboards_endpoint
```

## 8:00 → 8:45 — Prouver les données

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

### Vérifier

```text
documents présents
mapping valide
http_method agrégable
bytes_sent sommable
url_path agrégable
agrégations valides
```

### Dire

> « Les logs sont correctement structurés et les agrégations nécessaires aux graphiques fonctionnent. »

## 8:45 → 10:30 — Montrer le dashboard

### Navigateur

Ouvrir ou revenir sur :

```text
$DASHBOARD_URL
```

### Montrer dans cet ordre

```text
1. donut : méthodes HTTP
2. histogramme : somme bytes_sent / 12 h
3. top 5 url_path / 12 h
4. dashboard complet
```

### Dire

> « Ce sont les trois visualisations demandées par l'exercice, regroupées dans le dashboard. »

### Transition

> « Je termine avec la répartition de charge et la continuité de service. »

---

# 10:30 → 17:30 — Exercice 3 — HAProxy + deux backends

## 10:30 → 12:00 — Architecture

### Afficher

![Architecture exercice 3](schemas/exercice-3.svg)

### Dire

> « L'exercice 3 réutilise le VPC et les deux subnets de l'exercice 1. HAProxy et `p5-hello-1` sont dans le premier subnet ; `p5-hello-2` est dans le second. HAProxy reçoit le trafic public puis communique avec les deux backends sur leurs IP privées. »

### À pointer sur le schéma

```text
subnet public 1
├── p5-haproxy · t3.micro
└── p5-hello-1 · t3.micro

subnet public 2
└── p5-hello-2 · t3.micro

Internet → HAProxy:80 → IP privées des backends:80
```

## 12:00 → 12:45 — Montrer la configuration HAProxy

```bash
grep -E 'bind|balance|httpchk|http-check|server hello' \
  terraform/exercice-3/haproxy.cfg.tpl
```

### À montrer

```text
bind *:80
balance roundrobin
option httpchk GET /
http-check expect status 200
fall 3
rise 2
```

### Dire

> « HAProxy répartit en round-robin, retire un backend après trois échecs de health check et le réintègre après deux succès. »

## 12:45 → 14:00 — Montrer le round-robin dans le navigateur

### Navigateur

Ouvrir ou revenir sur :

```text
$HAPROXY_URL
```

Rafraîchir plusieurs fois.

### Montrer

```text
Server name
Server address
```

Les valeurs doivent alterner entre les deux backends.

## 14:00 → 15:00 — Prouver le round-robin dans le terminal

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

### Résultat attendu

```text
p5-hello-1
p5-hello-2
2 backends distincts observés
ROUND-ROBIN OPÉRATIONNEL
```

## 15:00 → 17:00 — Prouver la panne et la reprise

### Dire avant de lancer

> « Je vais arrêter le service sur un backend. HAProxy doit le retirer, continuer avec l'autre, puis le réintégrer après son redémarrage. »

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

### Résultat attendu

```text
AVANT  : 2 backends
PENDANT: 1 backend
APRÈS  : 2 backends

BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## 17:00 → 17:30 — Vérification navigateur

Revenir sur :

```text
$HAPROXY_URL
```

Rafraîchir plusieurs fois et vérifier que les deux backends sont de nouveau servis.

---

# 17:30 → 18:00 — Conclusion

## Dire

> « Les trois résultats sont démontrés : Terraform et Ansible déploient l'application Angular derrière NGINX, les logs sont exploitables dans Amazon OpenSearch avec les trois visualisations demandées, et HAProxy assure la répartition de charge ainsi que la reprise après panne. »

---

# Repli rapide si un écran pose problème

## Angular

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

## OpenSearch

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

## HAProxy

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

## Après la soutenance

```bash
bash scripts/commands/p5.sh cleanup
```
