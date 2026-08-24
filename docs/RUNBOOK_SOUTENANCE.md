# Runbook soutenance P5 — moins de 20 minutes

> **But :** présenter l'architecture, lancer les preuves utiles, montrer le résultat dans le navigateur.
>
> **Règle :** schéma → 2 phrases d'explication → commande → résultat → navigateur.

## Repères pour toi

```text
POURQUOI  = ce que l'étape doit prouver
VÉRIFIER  = ce que tu regardes dans la sortie
DIRE      = la phrase courte à donner au jury
NAVIGATEUR = le résultat concret à montrer
```

Ne cherche pas à commenter toute la sortie d'une commande : montre uniquement les lignes utiles indiquées dans **Vérifier**.

## Avant l'oral — hors chrono

```bash
cd ~/labs/p5_Openclassrooms
git switch main
git pull --ff-only
bash scripts/commands/p5.sh status
```

**Pourquoi :** partir du bon dépôt, sur `main`, avec un lab déjà prêt.

Préparer les variables :

```bash
export WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
export OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
export DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
export DASHBOARD_URL="${DASHBOARDS_URL%/}/app/dashboards#/view/p5-nginx-observability"
export HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
export BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"
```

**Pourquoi :** éviter de rechercher les URLs et IP pendant la soutenance.

Ouvrir trois onglets :

```text
1. $WEB_URL       → application Angular
2. $DASHBOARD_URL → OpenSearch Dashboards
3. $HAPROXY_URL   → service derrière HAProxy
```

Ne pas lancer `cleanup` avant la fin de la soutenance.

---

# 0:00 → 1:00 — Présenter le projet

## Afficher

![Vue d'ensemble](schemas/vue-ensemble.svg)

## Dire

> « Le projet contient trois exercices. Le premier provisionne AWS avec Terraform puis déploie Angular avec Ansible et NGINX. Le deuxième exploite les logs NGINX dans Amazon OpenSearch. Le troisième met HAProxy devant deux backends pour démontrer la répartition de charge et la reprise après panne. »

## À retenir

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

### À pointer

```text
VPC 10.0.0.0/16
├── subnet public 1 → p5-web · t3.micro · Ubuntu 24.04
└── subnet public 2 → réutilisé par Ex. 3

HTTP 80 → NGINX → Angular
SSH 22  → Ansible
```

**À comprendre :** Terraform crée l'infrastructure ; Ansible configure la machine ; NGINX sert l'application.

## 2:30 → 3:15 — Prouver Terraform

```bash
terraform -chdir=terraform/exercice-1 output
```

### Pourquoi

Montrer que Terraform connaît bien les ressources déployées et leurs valeurs utiles.

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

### Pourquoi

Vérifier que la configuration Terraform et l'infrastructure déployée sont déjà alignées.

### Résultat attendu

```text
No changes
```

### Dire

> « Terraform gère bien l'infrastructure et le plan est convergé : il n'y a aucun changement à appliquer. »

## 3:15 → 4:00 — Prouver la connexion Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

### Pourquoi

Prouver que l'inventaire Ansible pointe vers la bonne EC2 et que la connexion SSH fonctionne.

### Résultat attendu

```text
SUCCESS
ping: pong
```

### Dire

> « Ansible atteint correctement l'instance cible. »

## 4:00 → 5:00 — Prouver le déploiement Ansible

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

### Pourquoi

Prouver que la configuration NGINX et le déploiement Angular sont automatisés et rejouables.

### Résultat attendu sur un environnement déjà convergé

```text
changed=0
unreachable=0
failed=0
```

### Dire

> « Ansible configure NGINX et déploie Angular. `changed=0` montre que la machine est déjà dans l'état attendu. »

## 5:00 → 6:00 — Montrer Angular

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$WEB_URL"
```

### Pourquoi

Prouver techniquement que NGINX répond et sert bien l'application déployée.

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

### Dire

> « Le résultat final de l'exercice 1 est bien visible : Angular est réellement servie par NGINX sur l'EC2 AWS. »

### Transition

> « L'application fonctionne. J'utilise maintenant ses logs HTTP dans l'exercice 2. »

---

# 6:00 → 10:30 — Exercice 2 — Logs + Amazon OpenSearch

## 6:00 → 7:30 — Architecture

### Afficher

![Architecture exercice 2](schemas/exercice-2.svg)

### Dire

> « Le NGINX de l'exercice 1 produit `access.log`. Les logs sont parsés et envoyés à Amazon OpenSearch Service, puis OpenSearch Dashboards affiche les trois visualisations demandées. OpenSearch est ici un service AWS managé, pas une EC2 du VPC. »

### À pointer

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

**À comprendre :** NGINX produit la donnée ; le parser la structure ; OpenSearch l'indexe et l'agrège ; Dashboards la rend lisible.

## 7:30 → 8:00 — Prouver OpenSearch

```bash
terraform -chdir=terraform/exercice-2 output
```

### Pourquoi

Prouver que le domaine OpenSearch et ses endpoints sont bien issus du déploiement Terraform.

### Vérifier

```text
opensearch_domain_name
opensearch_endpoint
opensearch_dashboards_endpoint
```

### Dire

> « Le domaine Amazon OpenSearch est bien déployé et Terraform me fournit ses endpoints. »

## 8:00 → 8:45 — Prouver les données

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

### Pourquoi

Vérifier que les données nécessaires aux trois graphiques sont réellement exploitables.

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

### Pourquoi

Montrer le résultat visuel demandé par l'exercice, pas seulement une preuve API.

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

### À pointer

```text
subnet public 1
├── p5-haproxy · t3.micro
└── p5-hello-1 · t3.micro

subnet public 2
└── p5-hello-2 · t3.micro

Internet → HAProxy:80 → IP privées des backends:80
```

**À comprendre :** le client ne choisit jamais un backend ; HAProxy reçoit la requête et sélectionne un backend sain.

## 12:00 → 12:45 — Montrer la configuration HAProxy

```bash
grep -E 'bind|balance|httpchk|http-check|server hello' \
  terraform/exercice-3/haproxy.cfg.tpl
```

### Pourquoi

Montrer uniquement les directives qui expliquent le comportement observé ensuite.

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

### Pourquoi

Matérialiser visuellement l'alternance entre les deux services applicatifs.

### Montrer

```text
Server name
Server address
```

Les valeurs doivent alterner entre les deux backends.

### Dire

> « À chaque rafraîchissement, HAProxy répartit les requêtes entre les deux backends. »

## 14:00 → 15:00 — Prouver le round-robin dans le terminal

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

### Pourquoi

Confirmer par plusieurs requêtes que les deux backends sont réellement utilisés.

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

### Pourquoi

Prouver exactement le comportement attendu : détection de panne, continuité de service et réintégration automatique.

### Résultat attendu

```text
AVANT  : 2 backends
PENDANT: 1 backend
APRÈS  : 2 backends

BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

### À comprendre

```text
2 → 1 = HAProxy a détecté la panne
1     = le service reste disponible
1 → 2 = HAProxy a détecté le retour du backend
```

## 17:00 → 17:30 — Vérification navigateur

Revenir sur :

```text
$HAPROXY_URL
```

Rafraîchir plusieurs fois et vérifier que les deux backends sont de nouveau servis.

### Dire

> « Le backend restauré a bien été réintégré automatiquement dans la rotation. »

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
