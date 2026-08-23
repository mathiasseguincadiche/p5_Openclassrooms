# Runbook de soutenance — P5 OpenClassrooms

## Objectif

Ce document est la **référence opérationnelle pour la présentation du P5**.
Il ne cherche pas à réexécuter tout le projet devant le jury. Son but est de
montrer, dans un ordre simple et vérifiable, que :

1. l'architecture est comprise ;
2. l'infrastructure AWS est réellement provisionnée par Terraform ;
3. la configuration du serveur et le déploiement Angular sont réellement gérés par Ansible ;
4. l'application est réellement servie par NGINX ;
5. de vrais logs NGINX sont collectés puis exploités dans Amazon OpenSearch ;
6. HAProxy répartit réellement le trafic et maintient le service pendant la panne d'un backend ;
7. les preuves, journaux et livrables permettent de reproduire et d'auditer la démonstration.

Le runbook d'exécution complet reste [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).
Le présent document répond à une autre question : **que montrer, que dire et quelle preuve attendre pendant la soutenance ?**

---

## Convention de lecture

Chaque étape utilise cinq repères :

- **Montrer** : écran, fichier ou résultat à présenter ;
- **Commande** : commande courte à exécuter ;
- **Observer** : résultat attendu ;
- **Expliquer** : idée technique à formuler simplement ;
- **Prouver** : compétence ou propriété démontrée.

Une règle domine toute la présentation : **ne jamais improviser une mutation AWS pour corriger un problème non compris**.
Si un résultat est inattendu, observer les outputs, les logs et les diagnostics avant d'agir.

---

# Partie A — Remettre le lab AWS en service avant la soutenance

## A1. Situation actuelle

Le lab AWS peut être détruit après les travaux afin d'éviter des frais d'exploitation inutiles.
C'est une fermeture normale du projet, pas une perte du projet : le dépôt, les states Terraform,
les scripts, la configuration et les livrables constituent le moyen de **reconstruire l'environnement**.

La soutenance ne doit pas commencer avec une reconstruction complète. Le lab doit être remis en service
et validé **avant** la présentation.

## A2. Repartir du dépôt de référence

Dans WSL2 Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
git switch main
git pull --ff-only
git status --short
```

**Observer** : aucune modification locale inattendue.

**Expliquer** : le dépôt Git est la source versionnée ; les valeurs runtime et AWS sont ensuite relues depuis leurs sources de vérité.

## A3. Observer avant de reconstruire

```bash
bash scripts/commands/p5.sh inspect
```

**Observer** : l'outil doit permettre d'identifier un lab absent, partiel ou déjà présent.

**Expliquer** : le projet est convergent. Il ne suppose pas que tout est vide et ne lance pas un `apply` aveugle.

## A4. Revalider le plan de contrôle et AWS

```bash
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

**Observer** : le précontrôle doit atteindre le verdict :

```text
GO TERRAFORM
```

**Point d'arrêt** : ne pas déployer tant que l'identité AWS, l'IPv4 d'administration `/32`,
la clé SSH, les `terraform.tfvars` ou le budget ne sont pas correctement qualifiés.

## A5. Reconstruire les trois exercices dans l'ordre

Pour une remise en service avant soutenance, préférer les étapes séparées :

```bash
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
```

Pourquoi ne pas commencer par `p5.sh all` ?

- l'exercice 1 fournit le réseau utilisé ensuite par l'exercice 3 ;
- l'exercice 1 produit le vrai log NGINX utilisé par l'exercice 2 ;
- l'exercice 2 contient un checkpoint humain dans OpenSearch Dashboards ;
- les commandes séparées permettent d'arrêter proprement la remise en service à la couche réellement en défaut.

### Résultats minimums à obtenir

| Couche | Résultat attendu |
| --- | --- |
| Terraform exercice 1 | infrastructure créée puis post-plan sans delta |
| Ansible | second passage `changed=0`, `unreachable=0`, `failed=0` |
| Angular / NGINX | application accessible en HTTP |
| Logs NGINX | vrai `access.log` collecté |
| OpenSearch | données, mappings et agrégations vérifiés |
| Dashboards | trois visualisations + dashboard contrôlés visuellement |
| HAProxy | deux backends observés en fonctionnement normal |
| Failover | service maintenu avec un backend puis retour aux deux backends |

## A6. Figer un état prêt à présenter

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Puis vérifier les trois états Terraform :

```bash
terraform -chdir=terraform/exercice-1 plan -input=false -detailed-exitcode
terraform -chdir=terraform/exercice-2 plan -input=false -detailed-exitcode
terraform -chdir=terraform/exercice-3 plan -input=false -detailed-exitcode
```

Pour chaque exercice, le résultat idéal avant soutenance est un **exit code 0** : aucun delta.
Un exit code `2` signifie qu'un changement existe et doit être compris avant la présentation.

**Ne pas exécuter `cleanup` avant la soutenance.** Tant que le lab reste actif, considérer les ressources AWS comme potentiellement facturables.

---

# Partie B — Le récit de la soutenance

## B1. Le projet en une phrase

> Ce P5 met en œuvre un lab AWS reproductible où Terraform provisionne l'infrastructure,
> Ansible configure et déploie l'application, OpenSearch exploite les logs réels de NGINX,
> et HAProxy démontre la répartition de charge et la continuité de service pendant une panne contrôlée.

## B2. Architecture à présenter en premier

**Montrer** : [`schemas/vue-ensemble.svg`](schemas/vue-ensemble.svg).

```text
                    PLAN DE CONTRÔLE
              WSL2 Ubuntu 26.04 LTS
                        │
             p5.sh / Terraform / Ansible
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         ▼              ▼              ▼
   EXERCICE 1      EXERCICE 2      EXERCICE 3

 Terraform AWS     Amazon           HAProxy EC2
 VPC 10.0.0.0/16   OpenSearch            │
 2 subnets publics     ▲                  ├── backend 1
 SG + EC2 web          │                  └── backend 2
         │              │
      Ansible           │
         │              │
 NGINX + Angular        │
         │              │
         └── access.log ┘

 Exercice 1 ── VPC + subnets ─────────► Exercice 3
```

### Ce qu'il faut expliquer

- **Terraform** possède l'infrastructure AWS ;
- **Ansible** possède la configuration de l'EC2 applicative ;
- **NGINX** sert l'artefact Angular et produit les logs HTTP ;
- **OpenSearch** transforme ces logs en données requêtables et visualisables ;
- **HAProxy** réutilise le réseau de l'exercice 1 et répartit le trafic entre deux backends ;
- les trois exercices sont liés par de vraies dépendances, ils ne sont pas trois démonstrations isolées.

### Ce que cette introduction prouve

Vous maîtrisez la séparation des responsabilités et savez expliquer le flux complet avant de montrer les commandes.

---

# Partie C — Démonstration 1 : infrastructure, Ansible et application

## C1. Montrer l'infrastructure réelle

**Commande** :

```bash
terraform -chdir=terraform/exercice-1 output
```

**Observer** notamment :

- `vpc_id` ;
- `public_subnet_ids` ;
- `web_security_group_id` ;
- `web_public_ip` ;
- `web_url`.

Puis :

```bash
terraform -chdir=terraform/exercice-1 plan -input=false -detailed-exitcode
```

**Observer** : aucun changement si l'infrastructure est convergée.

### À expliquer

Terraform crée :

- un VPC `10.0.0.0/16` ;
- deux subnets publics répartis sur deux zones de disponibilité ;
- une Internet Gateway et le routage public ;
- un Security Group avec HTTP public et SSH limité à l'IPv4 d'administration ;
- une EC2 Ubuntu 24.04 qui devient la cible Ansible.

Terraform ne copie pas l'application sur le serveur : cette responsabilité appartient à Ansible.

### Preuve recherchée

**Le code Terraform décrit une infrastructure réellement présente et l'état observé correspond à l'état attendu.**

## C2. Montrer la cible Ansible

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

**Observer** : la cible répond `SUCCESS` / `pong`.

### À expliquer

L'inventaire est généré depuis les outputs Terraform. Il n'est donc pas nécessaire de recopier manuellement une IP AWS dans la procédure.

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

Le playbook :

- installe NGINX et les utilitaires requis ;
- crée l'utilisateur et le groupe applicatifs ;
- déploie l'artefact Angular sous `/var/www/p5` ;
- installe la configuration NGINX ;
- vérifie `nginx -t` ;
- démarre et active le service.

`changed=0` au second passage montre que la cible est déjà dans l'état souhaité.
L'automatisation est rejouable et ne modifie pas le serveur sans raison.

## C4. Montrer l'application réellement servie

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
printf 'Application : %s\n' "$WEB_URL"
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Puis ouvrir `WEB_URL` dans le navigateur.

### À expliquer

Le navigateur n'est pas la seule preuve. La vérification automatisée confirme que la réponse attendue provient bien du déploiement Angular derrière NGINX.

### Phrase de transition

> L'infrastructure est donc présente, la configuration est idempotente et l'application est servie. Je peux maintenant suivre ce qui se passe réellement sur ce serveur à partir de ses logs HTTP.

---

# Partie D — Démonstration 2 : logs NGINX et OpenSearch

## D1. Montrer que les logs proviennent de l'application réelle

Le scénario de reconstruction `p5.sh ex1` génère du trafic puis collecte le vrai `access.log` NGINX.
Pour produire quelques requêtes supplémentaires pendant la présentation :

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 12
```

Collecter ensuite le log actuel :

```bash
WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"

bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-presentation.log

tail -n 10 proofs/runtime/exercice-2/nginx-access-presentation.log
```

### À expliquer

Chaque ligne correspond à une requête HTTP réellement reçue par NGINX.
Le projet possède aussi un sample versionné pour les tests reproductibles, mais il ne faut pas confondre ce sample avec la preuve runtime issue de l'EC2.

## D2. Montrer OpenSearch

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"

printf 'OpenSearch : %s\nDashboards : %s\n' \
  "$OPENSEARCH_ENDPOINT" "$DASHBOARDS_URL"

bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

**Observer** : contrôles de mappings, documents et agrégations sans erreur.

### À expliquer

Le flux est :

```text
NGINX access.log
      ↓
parsing et typage
      ↓
Bulk API
      ↓
Amazon OpenSearch
      ↓
OpenSearch Dashboards
```

Le domaine OpenSearch impose HTTPS, le chiffrement au repos et le chiffrement nœud-à-nœud.
L'accès du lab est limité à l'IPv4 d'administration `/32`.

## D3. Montrer le résultat métier des logs

Ouvrir `DASHBOARDS_URL` et présenter :

1. le donut des méthodes HTTP ;
2. la somme de `bytes_sent` par tranches de 12 h ;
3. le top 5 de `url_path` par tranches de 12 h ;
4. le dashboard complet.

### À expliquer

La démonstration ne consiste pas seulement à stocker des fichiers de logs.
Elle montre que les champs ont un type exploitable pour produire des agrégations :

- méthode HTTP comme catégorie ;
- `bytes_sent` comme valeur numérique ;
- horodatage comme date ;
- chemin URL comme dimension d'analyse.

### Phrase de transition

> J'ai maintenant montré le déploiement et l'observabilité. La dernière partie vérifie le comportement du service lorsqu'un backend devient indisponible.

---

# Partie E — Démonstration 3 : HAProxy, répartition et panne

## E1. Présenter l'architecture HAProxy

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

### À expliquer

L'exercice 3 ne crée pas un second réseau indépendant.
Terraform retrouve le VPC et les subnets de l'exercice 1 par leurs tags et y déploie :

- une EC2 HAProxy ;
- deux EC2 backend ;
- un conteneur `nginxdemos/hello` sur chaque backend.

Les backends acceptent le trafic HTTP provenant du Security Group HAProxy.

## E2. Montrer les outputs réels

```bash
terraform -chdir=terraform/exercice-3 output
```

**Observer** notamment :

- `haproxy_url` ;
- `haproxy_public_ip` ;
- `hello_1_private_ip` ;
- `hello_2_private_ip`.

## E3. Montrer la configuration du proxy

```bash
sed -n '1,120p' terraform/exercice-3/haproxy.cfg.tpl
```

Points à commenter :

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
check inter 3s fall 3 rise 2
```

### À expliquer

- `roundrobin` distribue les requêtes entre les deux serveurs disponibles ;
- HAProxy vérifie `/` et attend un HTTP `200` ;
- `fall 3` retire un backend après trois contrôles consécutifs en échec ;
- `rise 2` réintègre un backend après deux contrôles consécutifs réussis.

## E4. Prouver le round-robin

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"

bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

**Observer** : les réponses doivent faire apparaître les deux backends.

### Preuve recherchée

Le trafic ne repose pas sur un serveur unique : HAProxy distribue réellement les requêtes.

## E5. Prouver la panne et la reprise

```bash
BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"

bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

Le script exécute un scénario contrôlé :

```text
AVANT
2 backends observés
    ↓
arrêt du conteneur nginx-hello sur le backend 1
    ↓
PENDANT LA PANNE
1 backend observé et service toujours disponible
    ↓
redémarrage du conteneur
    ↓
APRÈS LA REPRISE
2 backends de nouveau observés
```

**Verdict attendu** :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

### À expliquer

La haute disponibilité n'est pas prouvée par la présence d'un fichier `haproxy.cfg`.
Elle est prouvée par le comportement observable du système quand un backend disparaît puis revient.

Le script contient en plus une restauration de sécurité : si le scénario est interrompu après l'arrêt du backend,
il tente de redémarrer le conteneur avant de quitter.

---

# Partie F — Montrer que le projet est livrable et auditable

## F1. Montrer les journaux d'exécution

```bash
bash scripts/commands/p5.sh logs
```

### À expliquer

Chaque session orchestrée écrit ses journaux sous `logs/<UTC>/`.
Les logs ne remplacent pas les preuves fonctionnelles, mais ils permettent de retracer ce qui a réellement été exécuté.

## F2. Montrer les livrables

```bash
ls -1 docs/livrables/
```

Le dépôt contient trois livrables dédiés :

1. Terraform / Ansible / NGINX ;
2. logs / dashboard OpenSearch ;
3. HAProxy / `nginxdemos/hello`.

### À expliquer

La soutenance s'appuie sur le lab réel, mais la remise ne dépend pas de la présence permanente de ressources AWS facturables.
Les preuves utiles sont consolidées dans la documentation avant la fermeture du lab.

---

# Partie G — Conclusion technique à donner au jury

Le projet démontre quatre propriétés :

| Propriété | Preuve |
| --- | --- |
| **reproductibilité** | Terraform reconstruit l'infrastructure depuis le dépôt |
| **idempotence** | Ansible revient à `changed=0` lorsque l'état cible est atteint |
| **observabilité** | le vrai `access.log` NGINX devient une donnée analysable dans OpenSearch |
| **résilience** | HAProxy maintient le service pendant la panne contrôlée d'un backend et le réintègre ensuite |

Phrase de conclusion recommandée :

> L'important dans ce projet n'est pas seulement que chaque outil fonctionne séparément.
> La valeur vient de la chaîne complète : l'infrastructure est décrite, la configuration converge,
> l'application est vérifiable, ses logs sont exploitables, la panne est testée et tout le cycle est traçable jusqu'au nettoyage AWS.

---

# Partie H — Si une démonstration ne répond pas comme prévu

## H1. L'application ne répond plus

Ne pas modifier Terraform au hasard.

```bash
terraform -chdir=terraform/exercice-1 output
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
bash scripts/commands/p5.sh logs
```

Puis qualifier séparément réseau, SSH, Ansible et NGINX.

## H2. OpenSearch Dashboards est lent ou inaccessible

```bash
terraform -chdir=terraform/exercice-2 output
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

Présenter les captures consolidées si l'interface graphique n'est momentanément pas exploitable,
mais distinguer clairement la preuve enregistrée du test live.

## H3. Un backend HAProxy ne revient pas

Le test de failover tente une restauration automatique.
Vérifier ensuite l'état avant toute nouvelle panne :

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Ne relancer le test de panne que lorsque les deux backends sont de nouveau observés.

## H4. La session AWS a expiré

```bash
bash scripts/commands/check-aws-session.sh
```

Réparer l'authentification avant de continuer ; ne pas remplacer les outputs Terraform par des valeurs copiées manuellement.

---

# Partie I — Après la soutenance : fermer le lab

Une fois les preuves conservées et la présentation terminée :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

L'ordre de destruction est volontaire :

```text
Exercice 3
    ↓
Exercice 2
    ↓
Exercice 1
    ↓
audit AWS
```

L'exercice 3 dépend du réseau de l'exercice 1 ; il doit donc être détruit avant lui.

Le lab n'est considéré comme fermé qu'après le verdict :

```text
NETTOYAGE AWS COMPLET
```

---

# Mémo de soutenance — une page

```text
1. ARCHITECTURE
   WSL2 → Terraform / Ansible → AWS
   Ex1 → log réel → Ex2
   Ex1 → VPC/subnets → Ex3

2. INFRASTRUCTURE
   terraform output
   terraform plan = aucun delta

3. ANSIBLE
   ping
   playbook
   changed=0 / failed=0

4. APPLICATION
   WEB_URL
   verify-angular-deployment.sh
   navigateur

5. LOGS
   générer quelques requêtes
   collecter access.log
   montrer des lignes réelles

6. OPENSEARCH
   verify-opensearch-data.sh
   3 visualisations + dashboard

7. HAPROXY
   montrer roundrobin + health checks
   test round-robin
   test panne / reprise

8. LIVRABILITÉ
   p5.sh logs
   docs/livrables/

9. CONCLUSION
   reproductible + idempotent + observable + résilient

10. APRÈS LA SOUTENANCE
    cleanup : 3 → 2 → 1 → NETTOYAGE AWS COMPLET
```

## Ce qu'il ne faut pas faire devant le jury

- reconstruire les trois exercices depuis zéro pendant la présentation ;
- accepter un `terraform apply` dont le plan n'a pas été compris ;
- présenter une CI verte comme preuve qu'AWS est actuellement déployé ;
- recopier manuellement des IP alors que Terraform les expose en output ;
- confondre le sample de logs avec le vrai `access.log` NGINX ;
- montrer seulement `haproxy.cfg` sans provoquer et observer une panne ;
- supprimer un `terraform.tfstate` pour essayer de « repartir proprement » ;
- afficher un secret, une clé privée ou un vrai `terraform.tfvars` à l'écran.
