# Runbook d'exécution guidée — P5 de A à Z

## Objet

Ce document est la procédure opératoire principale du P5. Pour chaque phase, il
indique :

1. pourquoi elle existe ;
2. quelle commande exécuter ;
3. quel résultat observer ;
4. quand s'arrêter au lieu de poursuivre dans un état incertain.

Toutes les commandes du projet s'exécutent dans la distribution WSL2 **Ubuntu
26.04 LTS**. Les EC2 créées par Terraform utilisent Ubuntu 24.04 LTS par défaut :
ce sont des systèmes distincts.

> **Règle de sécurité**  
> Si une valeur importante est inconnue, si un plan Terraform contient une
> destruction non comprise ou si l'identité AWS n'est pas celle attendue,
> arrêter la procédure. Le réflexe correct est `inspect → logs → diagnostic`.

## Parcours complet

![Architecture et dépendances du P5](schemas/vue-ensemble.svg)

```text
qualifier WSL2
    ↓
inspect
    ↓
prepare
    ↓
status → GO TERRAFORM
    ↓
ex1 ── access.log ──► ex2
 │                     │
 │                     └── OpenSearch + Dashboard as Code
 │
 └── VPC/subnets ──► ex3
    ↓
diagnostics
    ↓
finalize
    ↓
cleanup : 3 → 2 → 1
    ↓
NETTOYAGE AWS COMPLET
```

## Règles communes

- travailler dans `Ubuntu` sous WSL2 ;
- conserver le checkout sur le filesystem Linux, par exemple
  `~/labs/p5_Openclassrooms` ;
- commencer par observer l'état réel ;
- conserver les `terraform.tfstate` ;
- lire chaque `terraform plan` avant confirmation ;
- utiliser les outputs Terraform comme source des IP et endpoints ;
- ne jamais remplacer une valeur inconnue par une valeur inventée ;
- automatiser les opérations reproductibles ;
- conserver les checkpoints humains lorsqu'ils valident un rendu réel ;
- considérer toute ressource AWS active comme potentiellement facturable ;
- conserver les preuves avant destruction du lab.

---

# Phase 0 — Qualifier la plateforme

## Depuis Windows

La plateforme Windows/WSL2 reste gérée par le dépôt
`Windows_11_Pro_Custom`. Ouvrir la distribution `Ubuntu` depuis PowerShell :

```powershell
wsl.exe -d Ubuntu
```

## Dans WSL2

```bash
cat /etc/os-release
uname -r
ps -p 1 -o comm=
printf '%s\n' "$WSL_DISTRO_NAME"
findmnt -T ~/labs -n -o FSTYPE
```

Résultats de référence :

```text
distribution : Ubuntu
OS           : Ubuntu 26.04 / resolute
PID 1        : systemd
workspace    : filesystem Linux du VHDX
```

Ouvrir le dépôt :

```bash
cd ~/labs/p5_Openclassrooms
pwd
git status --short
bash scripts/commands/bootstrap-wsl2.sh --check-only
```

## Point d'arrêt

Ne pas poursuivre si le workspace actif est sous `/mnt/c` ou `/mnt/e`, si la
mauvaise distribution est utilisée ou si le contrat logiciel est incohérent.

Référence : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

---

# Phase 1 — Observer l'état réel

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` qualifie notamment :

- la configuration locale ;
- les states Terraform ;
- les outputs existants ;
- les preuves déjà collectées ;
- le mode premier run / reprise ;
- les valeurs qui restent inconnues faute de source fiable.

Le but est de savoir **ce qui existe avant d'agir**.

---

# Phase 2 — Préparer WSL2 et AWS

```bash
bash scripts/commands/p5.sh prepare
```

La phase prépare ou vérifie :

- les outils requis ;
- l'identité et le compte AWS ;
- `environment/aws-readiness.env` ;
- l'IPv4 d'administration `/32` ;
- la clé SSH ;
- le budget AWS ;
- les trois `terraform.tfvars`.

## Point d'arrêt

Ne pas poursuivre si :

- l'identité AWS est inattendue ;
- l'IPv4 `/32` ou la clé SSH sont inconnues ;
- les `terraform.tfvars` sont incohérents ;
- une mutation proposée n'est pas comprise.

---

# Phase 3 — Revalider avant Terraform

```bash
bash scripts/commands/p5.sh status
```

Verdict attendu :

```text
GO TERRAFORM
```

Cela signifie que le lab est prêt à **lire un plan Terraform**, pas qu'un
`apply` doit nécessairement être exécuté.

---

# Phase 4 — Exercice 1 : Terraform + Ansible + Angular/NGINX

![Exercice 1 — infrastructure et déploiement](schemas/exercice-1.svg)

## Objectif

Séparer clairement :

```text
Terraform
  └── infrastructure AWS

Ansible
  └── configuration EC2 + NGINX + Angular
```

## Commande principale

```bash
bash scripts/commands/p5.sh ex1
```

## Flux exécuté

```text
build Angular
    ↓
Terraform init / plan / apply si delta
    ↓
outputs Terraform
    ↓
inventaire Ansible
    ↓
attente SSH + ping Ansible
    ↓
déploiement NGINX + Angular
    ↓
second passage Ansible
    ↓
vérification HTTP
    ↓
génération de trafic
    ↓
collecte du vrai access.log
```

## Contrôles ciblés

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"

bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Ansible :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Au second passage du playbook :

```text
changed=0
unreachable=0
failed=0
```

Le vrai log utilisé par l'exercice 2 doit exister :

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

## Definition of Done

- [ ] Terraform convergé ;
- [ ] post-plan sans delta ;
- [ ] EC2 accessible ;
- [ ] Ansible `pong` ;
- [ ] second passage idempotent ;
- [ ] Angular accessible derrière NGINX ;
- [ ] vrai `access.log` collecté.

Guide : [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md).

---

# Phase 5 — Exercice 2 : OpenSearch + Dashboard as Code

![Exercice 2 — logs vers OpenSearch](schemas/exercice-2.svg)

## Objectif

Transformer les logs NGINX en données requêtables puis reconstruire la couche de
visualisation de manière reproductible.

## Commande principale

```bash
bash scripts/commands/p5.sh ex2
```

## Flux exécuté

```text
Terraform OpenSearch
    ↓
validation sample + log réel
    ↓
réconciliation template / documents
    ↓
vérification mappings / agrégations
    ↓
génération Saved Objects
    ↓
vérification field_caps réel
    ↓
import index pattern + 3 visualisations + dashboard
    ↓
relecture des 5 objets par API
    ↓
checkpoint visuel humain
```

## Récupérer les endpoints

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_endpoint)"
DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_dashboards_endpoint)"
```

## Vérifier les données

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

Le contrôle doit confirmer :

- mapping exploitable ;
- documents présents ;
- `@timestamp`, `http_method`, `bytes_sent`, `url_path` utilisables ;
- agrégations nécessaires au dashboard fonctionnelles.

## Dashboard as Code

Source de vérité :

```text
terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

Elle déclare :

```text
index pattern nginx-access-* / @timestamp
    ├── donut http_method
    ├── Sum(bytes_sent) / 12 h
    └── Top 5 url_path / 12 h
              ↓
      P5 — Observabilité NGINX
```

Le bundle NDJSON est généré par :

```text
scripts/tools/build-opensearch-saved-objects.py
```

La synchronisation distante est gérée par :

```text
scripts/commands/sync-opensearch-dashboards.sh
```

Le script valide les champs réels avec `_field_caps`, attend l'API Dashboards,
importe les Saved Objects avec `overwrite=true`, relit les cinq objets et
conserve les preuves techniques.

Prévisualisation sans mutation :

```bash
bash scripts/commands/sync-opensearch-dashboards.sh
```

## Checkpoint humain obligatoire

Le checkpoint ne demande plus de **créer** les graphiques. Ils ont déjà été
réconciliés automatiquement.

Il demande uniquement de vérifier dans le navigateur :

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` / 12 h ;
3. top 5 de `url_path` / 12 h ;
4. dashboard complet ;
5. plage de temps et lisibilité ;
6. captures réelles.

Le mode `--yes` ne valide jamais le rendu à la place de l'opérateur.

## Definition of Done

- [ ] domaine OpenSearch actif ;
- [ ] plan Terraform compris ;
- [ ] données importées ;
- [ ] mappings et agrégations valides ;
- [ ] `_field_caps` valide les quatre champs ;
- [ ] cinq Saved Objects importés ;
- [ ] cinq Saved Objects relus par API ;
- [ ] trois visualisations visibles ;
- [ ] dashboard complet visible ;
- [ ] quatre captures conservées.

Guide : [`exercices/02-opensearch.md`](exercices/02-opensearch.md).

---

# Phase 6 — Exercice 3 : HAProxy et résilience

![Exercice 3 — HAProxy et résilience](schemas/exercice-3.svg)

## Précondition

L'exercice 1 doit encore fournir son VPC et ses subnets.

## Commande principale

```bash
bash scripts/commands/p5.sh ex3
```

## Flux exécuté

```text
Terraform HAProxy + 2 backends
    ↓
attente HTTP
    ↓
round-robin
    ↓
prévisualisation panne
    ↓
arrêt temporaire backend 1
    ↓
service maintenu sur backend 2
    ↓
redémarrage backend 1
    ↓
réintégration automatique
```

## Round-robin

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"

bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Les deux backends doivent être observés.

## Failover réel

```bash
BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 \
  output -raw hello_1_public_ip)"

bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1_IP" \
  --apply
```

Verdict attendu :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## Definition of Done

- [ ] HAProxy répond ;
- [ ] deux backends observés en fonctionnement normal ;
- [ ] un backend retiré pendant la panne ;
- [ ] service toujours disponible ;
- [ ] backend redémarré ;
- [ ] deux backends observés après reprise.

Guide : [`exercices/03-haproxy.md`](exercices/03-haproxy.md).

---

# Phase 7 — Diagnostics et finalisation

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Cette phase consolide les journaux et vérifie la structure des preuves et des
livrables.

Pour la préparation orale, utiliser aussi
[`RUNBOOK_SOUTENANCE.md`](RUNBOOK_SOUTENANCE.md).

---

# Phase 8 — Reprise après interruption

Toujours commencer par :

```bash
bash scripts/commands/p5.sh inspect
```

Puis relancer la couche concernée ou :

```bash
bash scripts/commands/p5.sh all
```

Principes :

- Terraform recalcule le delta ;
- Ansible reconverge vers l'état cible ;
- l'import OpenSearch est déterministe ;
- les Saved Objects Dashboards ont des IDs stables et sont réconciliés ;
- les tests fonctionnels sont rejoués.

Ne jamais supprimer un state Terraform pour forcer une reprise.

---

# Phase 9 — Nettoyer AWS après les preuves

Après la soutenance et après conservation des preuves :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3
    ↓
Exercice 2
    ↓
Exercice 1
    ↓
audit AWS
```

L'exercice 3 dépend du réseau de l'exercice 1 et doit être détruit avant lui.

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```

---

# Résumé opérateur

```text
AVANT
inspect
prepare
status → GO TERRAFORM

CONSTRUIRE
ex1
ex2
ex3

VALIDER
diagnostics
finalize

PRÉSENTER
RUNBOOK_SOUTENANCE.md

FERMER
cleanup
→ NETTOYAGE AWS COMPLET
```

## Principe final

```text
observer
  ↓
calculer le delta
  ↓
confirmer la mutation
  ↓
converger
  ↓
vérifier
  ↓
journaliser
  ↓
conserver la preuve
```

La qualité du projet vient de cette capacité à reconstruire, vérifier et fermer
le lab sans dépendre d'une suite de manipulations manuelles non versionnées.
