# Runbook de soutenance — P5 OpenClassrooms

> **But de ce document :** ouvrir, suivre, démontrer. Ce runbook est le **conducteur live de la soutenance**, pas un tutoriel de construction. Pendant l'oral : **expliquer → prouver dans le terminal → montrer dans le navigateur → enchaîner**.

# MODE SOUTENANCE — COMMENCER ICI

## 0. Précondition

Le lab AWS a déjà été reconstruit et validé avant l'oral avec :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Pendant la soutenance, **ne pas reconstruire AWS** et **ne pas lancer `cleanup`**.

## 1. Préparer le terminal de démonstration

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

Garder trois onglets navigateur prêts :

```text
1. Angular            → WEB_URL
2. OpenSearch         → DASHBOARD_URL
3. HAProxy            → HAPROXY_URL
```

---

# DÉMO 1 — Architecture

## Objectif

Donner au jury la carte du projet avant les commandes.

## À montrer

```text
schemas/vue-ensemble.svg
```

```text
                    WSL2 Ubuntu 26.04
                           │
                 p5.sh / Terraform / Ansible
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
      EXERCICE 1       EXERCICE 2       EXERCICE 3

 Terraform AWS       OpenSearch          HAProxy
      │                  ▲               /     \
   Ansible                │              /       \
      │                   │         backend 1  backend 2
 NGINX + Angular          │
      │                   │
      └── access.log ─────┘
```

## À dire

> « Terraform provisionne l'infrastructure AWS. Ansible configure l'EC2 et déploie Angular derrière NGINX. Les logs NGINX alimentent Amazon OpenSearch et son dashboard. Enfin, HAProxy répartit les requêtes entre deux backends et démontre la continuité de service pendant une panne contrôlée. »

## Transition

> « Je commence par l'infrastructure et le déploiement de l'application. »

---

# DÉMO 2 — Terraform : infrastructure AWS réelle

## Terminal

```bash
terraform -chdir=terraform/exercice-1 output
```

Montrer rapidement :

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

## À observer

Aucun changement si l'infrastructure est convergée.

## À dire

> « Terraform décrit et possède l'infrastructure. Ce plan sans delta prouve que l'état AWS correspond au code. Terraform crée la machine ; Ansible prend ensuite en charge sa configuration applicative. »

---

# DÉMO 3 — Ansible : connectivité et idempotence

## Terminal — ping

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

## À dire

> « L'inventaire est généré depuis les outputs Terraform. L'adresse de l'EC2 n'est pas recopiée manuellement. »

## Terminal — second passage du playbook

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Attendu :

```text
changed=0
unreachable=0
failed=0
```

## À dire

> « Le playbook installe NGINX, déploie Angular et configure NGINX pour servir l'application. `changed=0` montre que la cible est déjà dans l'état souhaité : le déploiement est idempotent. »

---

# DÉMO 4 — Angular / NGINX : montrer réellement l'application

> **Cette étape ne doit pas rester uniquement en ligne de commande.** OpenClassrooms demande de vérifier que l'application Angular est accessible en naviguant vers l'adresse du serveur.

## Terminal — preuve technique

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Verdict attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

Le script vérifie notamment HTTP 200, Angular, le bundle JavaScript et le fallback SPA.

## NAVIGATEUR — preuve visuelle

Ouvrir :

```text
WEB_URL
```

Montrer :

- la page Angular réellement rendue ;
- le contenu de l'application P5 ;
- un rafraîchissement ;
- si utile : `WEB_URL/parcours-p5` pour matérialiser le routage SPA.

## À dire

> « Le terminal prouve le service HTTP. Ici je montre le résultat final : l'application Angular est réellement servie par NGINX sur l'EC2 AWS. »

## Transition

> « L'application fonctionne. Je vais maintenant générer du trafic et suivre ce trafic dans les logs. »

---

# DÉMO 5 — NGINX : produire et montrer de vrais logs

## Terminal — trafic réel

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 12
```

## Terminal — collecte

```bash
bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-presentation.log
```

Puis :

```bash
tail -n 10 proofs/runtime/exercice-2/nginx-access-presentation.log
```

## À dire

> « Ces lignes correspondent à des requêtes réellement reçues par le NGINX AWS. Le sample versionné assure la reproductibilité ; ici je montre le log runtime réel produit par l'application. »

---

# DÉMO 6 — OpenSearch : données, mappings et agrégations

L'exercice OpenClassrooms autorise explicitement le **mode Cloud avec AWS OpenSearch**.

## Terminal

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

## À observer

Documents, mappings et agrégations sans erreur.

## À expliquer

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

## Montrer brièvement le Dashboard as Code

```bash
jq '{index_pattern, visualizations, dashboard: {id: .dashboard.id, title: .dashboard.title}}' \
  terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

## À dire

> « Le dashboard est versionné. L'automatisation contrôle les champs avec `_field_caps`, importe les Saved Objects et relit les cinq objets par API. La validation visuelle reste humaine. »

---

# DÉMO 7 — OpenSearch Dashboards : montrer les 3 visualisations demandées

> **Passer dans le navigateur.** Ne pas recréer les graphiques pendant l'oral.

## NAVIGATEUR

Ouvrir :

```text
DASHBOARD_URL
```

Titre attendu :

```text
P5 — Observabilité NGINX
```

Montrer dans cet ordre :

1. **Donut** — répartition des méthodes HTTP (`http_method`).
2. **Histogramme** — somme de `bytes_sent` par tranche de 12 h.
3. **Histogramme cumulé / Top 5** — `url_path` par tranche de 12 h.
4. **Dashboard complet** avec les trois visuels ensemble.

Si un graphique semble vide, vérifier immédiatement la plage temporelle et les filtres.

## À dire

> « Le dashboard reprend les trois visualisations demandées par l'exercice : verbes HTTP, quantité cumulée de données envoyées par tranches de 12 heures et top 5 des requêtes par tranches de 12 heures. »

## Captures à avoir déjà conservées

```text
01-dashboard-complet
02-donut-methodes-http
03-histogramme-bytes-12h
04-top5-url-12h
```

Les captures servent de preuve enregistrée et de repli, pas de remplacement au test live.

## Transition

> « J'ai montré le déploiement et l'observabilité. Je termine par la disponibilité et la réaction à la panne. »

---

# DÉMO 8 — HAProxy : montrer le round-robin dans le navigateur

## Terminal — outputs réels

```bash
terraform -chdir=terraform/exercice-3 output
```

Puis montrer uniquement les directives utiles :

```bash
grep -E 'bind|balance|httpchk|http-check|server hello' \
  terraform/exercice-3/haproxy.cfg.tpl
```

À expliquer :

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
fall 3
rise 2
```

## NAVIGATEUR — preuve visuelle demandée

Ouvrir :

```text
HAPROXY_URL
```

Rafraîchir la page plusieurs fois.

Observer dans `nginxdemos/hello` :

```text
Server address
Server name
```

Les valeurs doivent alterner entre les deux backends.

## À dire

> « La répartition est directement visible : à chaque rafraîchissement, l'adresse ou le nom du serveur change. HAProxy distribue donc les requêtes entre les deux instances. »

## Terminal — preuve sur une série de requêtes

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Attendu : deux backends distincts observés.

---

# DÉMO 9 — HAProxy : panne contrôlée et reprise

## Terminal

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

Le scénario attendu est :

```text
AVANT
2 backends
    ↓
arrêt backend 1
    ↓
PENDANT
1 backend + service toujours disponible
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

## NAVIGATEUR — état final

Revenir sur `HAPROXY_URL` et rafraîchir plusieurs fois.

Montrer que les deux `Server name` sont de nouveau observables.

## À dire

> « HAProxy détecte l'indisponibilité, retire le backend de la rotation, maintient le service sur l'autre instance, puis réintègre automatiquement le backend restauré. »

---

# DÉMO 10 — Preuves et conclusion

## Preuves — rester bref

```bash
bash scripts/commands/p5.sh logs
```

Puis si nécessaire :

```bash
ls -1 proofs/runtime/exercice-2/*dashboards* 2>/dev/null
ls -1t proofs/runtime/exercice-3/*failover* 2>/dev/null | head
```

## Conclusion

| Propriété | Preuve montrée |
| --- | --- |
| Infrastructure as Code | Terraform + outputs + plan sans delta |
| Automatisation de configuration | Ansible ping + playbook + idempotence |
| Application fonctionnelle | Angular réellement affichée dans le navigateur |
| Observabilité | vrai `access.log` + OpenSearch + dashboard |
| Reproductibilité | infrastructure + Saved Objects versionnés |
| Répartition de charge | deux backends visibles dans le navigateur et le terminal |
| Résilience | panne contrôlée 2 → 1 → 2 avec service maintenu |
| Traçabilité | logs et preuves runtime |

Phrase de conclusion :

> « L'infrastructure est décrite et reproductible, la configuration converge avec Ansible, l'application est réellement accessible, ses logs deviennent exploitables dans OpenSearch, le dashboard est reproductible et HAProxy maintient le service pendant une panne contrôlée. »

---

# MÉMO ULTRA-COURT — SI JE DOIS ALLER VITE

```text
1  SCHÉMA
   expliquer Terraform / Ansible / NGINX / OpenSearch / HAProxy

2  TERRAFORM
   output → plan sans delta

3  ANSIBLE
   ping → playbook → changed=0

4  ANGULAR — NAVIGATEUR
   verify-angular → ouvrir WEB_URL → montrer l'application

5  LOGS
   12 requêtes → collecte → tail

6  OPENSEARCH
   verify-opensearch-data

7  DASHBOARD — NAVIGATEUR
   donut → bytes/12h → top5/12h → dashboard complet

8  HAPROXY — NAVIGATEUR
   rafraîchir → Server name/address alternent

9  HAPROXY — TERMINAL
   round-robin → failover 2→1→2

10 CONCLUSION
   IaC + idempotence + application + observabilité + résilience
```

---

# AVANT LA SOUTENANCE — CHECKLIST DE PRÉPARATION

Cette partie se fait **avant** l'oral. Elle ne fait pas partie de la démonstration live.

## 1. Repartir de `main`

```bash
cd ~/labs/p5_Openclassrooms
git switch main
git pull --ff-only
git status --short
```

Attendu : aucun changement local inattendu.

## 2. Observer avant de muter

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

Attendu :

```text
GO TERRAFORM
```

Ne pas déployer tant que l'identité AWS, l'IPv4 `/32`, la clé SSH, les `terraform.tfvars` ou le budget ne sont pas qualifiés.

## 3. Reconstruire dans le bon ordre

```bash
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
```

Dépendances :

```text
EX1 ── VPC + subnets ───────────────► EX3
 │
 └── access.log NGINX réel ─────────► EX2
```

## 4. État minimum avant oral

| Couche | État attendu |
| --- | --- |
| Terraform ex. 1 | infrastructure présente, post-plan sans delta |
| Ansible | second passage `changed=0`, `unreachable=0`, `failed=0` |
| Angular / NGINX | application visible dans le navigateur |
| NGINX | vrai `access.log` collecté |
| OpenSearch | données, mappings et agrégations validés |
| Dashboards as Code | 5 Saved Objects importés et relus par API |
| OpenSearch navigateur | 3 visualisations + dashboard lisibles |
| HAProxy navigateur | 2 backends observables par rafraîchissement |
| Failover | 2 → 1 → 2, service maintenu |

## 5. Finaliser les preuves

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

Code `0` idéal. Code `2` = delta à comprendre avant l'oral.

## 6. Préparer les fenêtres

Avant l'oral :

- terminal WSL2 dans `~/labs/p5_Openclassrooms` ;
- runbook ouvert ;
- schéma global prêt ;
- Angular déjà testé ;
- OpenSearch Dashboards déjà testé ;
- HAProxy déjà testé ;
- captures OpenSearch déjà enregistrées ;
- aucune fenêtre affichant des secrets.

---

# REPLI EN CAS D'INCIDENT

## Angular ne s'affiche plus

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
bash scripts/commands/p5.sh logs
```

Si le test automatisé est vert mais le navigateur pose problème, montrer une capture en précisant qu'il s'agit d'une preuve enregistrée.

## Dashboard vide ou inaccessible

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"

ls -1 proofs/runtime/exercice-2/*dashboards* 2>/dev/null
```

Ne pas recréer les visualisations manuellement. Vérifier d'abord la plage temporelle et les filtres.

## HAProxy n'affiche qu'un backend avant la panne

Ne pas lancer le failover.

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Relancer le scénario de panne uniquement lorsque deux backends sont observés.

## Session AWS expirée

```bash
bash scripts/commands/check-aws-session.sh
```

Réparer l'authentification. Ne jamais inventer une IP ou remplacer un output Terraform par une valeur copiée au hasard.

---

# APRÈS LA SOUTENANCE

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

# À NE PAS FAIRE DEVANT LE JURY

- reconstruire les trois exercices depuis zéro ;
- lancer un `terraform apply` sans lire le plan ;
- perdre plusieurs minutes dans la console AWS à chercher une ressource ;
- se contenter d'un HTTP 200 sans montrer l'application Angular ;
- recréer manuellement les visualisations OpenSearch ;
- confondre le sample avec le vrai `access.log` NGINX ;
- présenter seulement `haproxy.cfg` sans montrer le round-robin et la panne ;
- déclencher le failover si un seul backend est déjà disponible ;
- afficher une clé privée, un secret, un mot de passe ou un vrai `terraform.tfvars` ;
- lancer `cleanup` avant la fin de la soutenance.
