# Runbook d'exécution guidée — P5 de A à Z

## Objectif

Ce runbook est la procédure opératoire principale du P5. Il fixe l'ordre d'exécution, les commandes,
les résultats attendus, les points d'arrêt et les conditions de reprise.

Toutes les commandes P5 sont exécutées dans la distribution WSL2 **`Ubuntu`**, Ubuntu 26.04 LTS.

Les guides `docs/exercices/` expliquent les concepts en profondeur. Le présent document décrit la
séquence opératoire à suivre pour exécuter le projet de manière reproductible.

## Parcours complet

![Architecture et dépendances du P5](schemas/vue-ensemble.svg)

```text
ouverture de la distribution Ubuntu
        ↓
inspect
        ↓
prepare
        ↓
status → GO TERRAFORM
        ↓
exercice 1
   ├────► exercice 2 via access.log
   └────► exercice 3 via VPC/subnets
        ↓
diagnostics
        ↓
finalize
        ↓
cleanup 3 → 2 → 1
        ↓
audit AWS
```

## Règles opératoires

1. travailler dans `Ubuntu` sous WSL2 ;
2. utiliser `~/labs/p5_Openclassrooms` sur le filesystem Linux local de la distribution WSL2 ;
3. commencer par observer l'état réel ;
4. conserver les `terraform.tfstate` comme source de propriété Terraform ;
5. lire chaque plan Terraform avant confirmation ;
6. utiliser les outputs Terraform comme source des IP, URL et endpoints ;
7. conserver les checkpoints humains demandés par le projet ;
8. traiter toute ressource AWS active comme potentiellement facturable ;
9. journaliser et conserver les preuves utiles à chaque exercice.

Le cycle de vie de la distribution WSL2 est documenté dans
[`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

---

## Phase 0 — Ouvrir et qualifier le plan de contrôle

![Étape 0 — qualification et préparation](schemas/etape-0.svg)

Depuis PowerShell, valider puis ouvrir la distribution :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
wsl.exe -d Ubuntu
```

Dans WSL2 :

```bash
cd ~/labs/p5_Openclassrooms
cat /etc/os-release
uname -r
ps -p 1 -o comm=
printf '%s\n' "$WSL_DISTRO_NAME"
pwd
git status --short
```

Résultats attendus :

```text
WSL      : Ubuntu
OS       : Ubuntu 26.04 / resolute
noyau    : microsoft-standard-WSL2
PID 1    : systemd
checkout : /home/<utilisateur>/labs/p5_Openclassrooms
```

### Point d'arrêt

Ne pas poursuivre si l'identité WSL2, l'OS, systemd ou le filesystem du checkout ne
correspondent pas au contrat `environment/wsl2/README.md`.

---

## Phase 1 — Observer l'état réel

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` collecte notamment :

- la configuration locale disponible ;
- les states Terraform présents ;
- les outputs existants ;
- les preuves déjà collectées ;
- la classification du lab pour la reprise.

Aucune valeur runtime ne doit être inventée ou remplacée par une valeur copiée sans source.

---

## Phase 2 — Préparer le runtime P5 et AWS

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` vérifie ou réconcilie :

- le runtime logiciel P5 dans `Ubuntu` sous WSL2 ;
- Terraform, Ansible Core, Node.js, AWS CLI et Docker ;
- les outils nécessaires aux validations du dépôt ;
- l'authentification AWS ;
- `environment/aws-readiness.env` ;
- l'IPv4 publique d'administration en `/32` ;
- la clé SSH du lab ;
- le budget et les garde-fous ;
- les trois `terraform.tfvars` locaux.

Contrôle du runtime seul, sans mutation :

```bash
bash scripts/commands/bootstrap-wsl2.sh --check-only
```

### Point d'arrêt

Ne pas poursuivre si :

- le runtime P5 n'est pas conforme ;
- l'identité ou le compte AWS attendu est incohérent ;
- l'IPv4 `/32`, la clé SSH, les quotas ou les `tfvars` sont incomplets ;
- une mutation proposée n'est pas comprise.

Si l'utilisateur vient d'être ajouté au groupe Docker, fermer les terminaux WSL2, exécuter
`wsl.exe --terminate Ubuntu` dans PowerShell, rouvrir `Ubuntu`, puis relancer `prepare`.

---

## Phase 3 — Valider le lab avant Terraform

```bash
bash scripts/commands/p5.sh status
```

Le précontrôle doit pouvoir atteindre :

```text
GO TERRAFORM
```

Ce verdict autorise le passage à la lecture du plan Terraform. Il n'autorise jamais un changement
aveugle.

---

## Phase 4 — Exercice 1 : Terraform + Ansible + Angular/NGINX

![Exercice 1 — infrastructure et déploiement](schemas/exercice-1.svg)

Lancer :

```bash
bash scripts/commands/p5.sh ex1
```

Flux attendu :

```text
build Angular
+ Terraform init/plan/apply si delta
        ↓
outputs Terraform + artefact Angular
        ↓
inventaire Ansible
        ↓
attente SSH + Ansible ping
        ↓
déploiement NGINX + Angular
        ↓
second passage Ansible
        ↓
vérification HTTP
        ↓
trafic de preuve + collecte access.log
```

### Contrôles ciblés

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"
printf 'WEB_URL=%s\nWEB_IP=%s\n' "$WEB_URL" "$WEB_IP"
```

Vérifier l'application :

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Vérifier Ansible :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Le second passage du playbook doit terminer avec :

```text
changed=0
unreachable=0
failed=0
```

Rejouer le trafic et la collecte de logs si nécessaire :

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 96

bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

### Definition of Done — exercice 1

- [ ] Terraform convergé ;
- [ ] EC2 disponible ;
- [ ] Ansible ping réussi ;
- [ ] premier playbook sans échec ;
- [ ] second passage `changed=0`, `unreachable=0`, `failed=0` ;
- [ ] Angular accessible derrière NGINX ;
- [ ] `access.log` réel collecté.

Guide : [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md).

---

## Phase 5 — Exercice 2 : Amazon OpenSearch

![Exercice 2 — logs vers OpenSearch](schemas/exercice-2.svg)

Lancer :

```bash
bash scripts/commands/p5.sh ex2
```

Le parcours :

1. fait converger le domaine Amazon OpenSearch ;
2. prépare le jeu de données reproductible ;
3. importe le log réel de l'exercice 1 lorsqu'il est disponible ;
4. vérifie mappings, nombre de documents et agrégations ;
5. laisse la validation visuelle à l'opérateur.

### Récupérer les endpoints

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
printf 'OPENSEARCH_ENDPOINT=%s\nDASHBOARDS_URL=%s\n' \
  "$OPENSEARCH_ENDPOINT" "$DASHBOARDS_URL"
```

Contrôle technique :

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

### Checkpoint OpenSearch Dashboards

Créer ou vérifier réellement :

1. un donut de répartition des méthodes HTTP ;
2. la somme de `bytes_sent` par tranches de 12 h ;
3. le top 5 de `url_path` par tranches de 12 h ;
4. le dashboard regroupant les trois visualisations.

Conserver quatre captures : les trois visualisations et le dashboard complet.

Le mode `--yes` ne valide pas ce checkpoint à la place de l'opérateur.

### Definition of Done — exercice 2

- [ ] domaine OpenSearch actif ;
- [ ] données importées sans erreur ;
- [ ] mappings et agrégations valides ;
- [ ] données visibles dans Dashboards ;
- [ ] trois visualisations correctes ;
- [ ] dashboard complet ;
- [ ] quatre captures conservées.

Guide : [`exercices/02-opensearch.md`](exercices/02-opensearch.md).

---

## Phase 6 — Exercice 3 : HAProxy et résilience

![Exercice 3 — HAProxy et résilience](schemas/exercice-3.svg)

L'exercice 1 doit fournir son VPC et ses sous-réseaux.

Lancer :

```bash
bash scripts/commands/p5.sh ex3
```

Le parcours :

1. fait converger l'infrastructure de l'exercice 3 ;
2. attend la disponibilité de HAProxy ;
3. vérifie le round-robin ;
4. arrête temporairement un backend ;
5. vérifie la continuité du service ;
6. restaure le backend ;
7. vérifie sa réintégration.

### Récupérer les valeurs Terraform

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"
printf 'HAPROXY_URL=%s\nBACKEND_1_IP=%s\n' \
  "$HAPROXY_URL" "$BACKEND_1_IP"
```

Vérifier le round-robin :

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Preuve attendue :

```text
AVANT  : les deux backends répondent
PANNE  : le backend défaillant est retiré et le service reste disponible
APRÈS  : le backend restauré est réintégré
```

### Definition of Done — exercice 3

- [ ] HAProxy accessible ;
- [ ] deux backends observés en round-robin ;
- [ ] health checks actifs ;
- [ ] service disponible pendant la panne ;
- [ ] backend restauré et réintégré ;
- [ ] preuves avant / panne / reprise conservées.

Guide : [`exercices/03-haproxy.md`](exercices/03-haproxy.md).

---

## Phase 7 — Diagnostics et livrables

Collecter l'état et les preuves :

```bash
bash scripts/commands/p5.sh diagnostics
```

Contrôler strictement les livrables :

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu lorsque les preuves requises sont présentes :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Avant publication :

- relire chaque capture ;
- masquer les informations sensibles inutiles ;
- ne jamais publier de state Terraform, de vrai `tfvars`, de clé ou de credential ;
- contextualiser chaque preuve par l'action, le résultat et son interprétation.

Préparation de l'oral : [`05-soutenance.md`](05-soutenance.md).

---

## Phase 8 — Fermer le lab AWS

![Finalisation et fermeture AWS](schemas/finalisation/finalisation.svg)

Après validation des preuves et captures :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre de destruction :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

Si l'audit détecte encore une ressource gérée, identifier le module Terraform propriétaire et son
state avant toute correction.

L'arrêt ou la sauvegarde de `Ubuntu` sous WSL2 est indépendant du nettoyage AWS du P5.

---

## Reprendre après une interruption

Après une fermeture de terminal ou un redémarrage :

1. ouvrir `Ubuntu` avec `wsl.exe -d Ubuntu` ;
2. vérifier que systemd et Docker sont actifs ;
3. revenir dans le checkout ;
4. observer l'état ;
5. reprendre uniquement l'étape nécessaire.

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh status
```

Le parcours convergent complet peut être relancé avec :

```bash
bash scripts/commands/p5.sh all
```

`all` recalcule les deltas et réutilise les states existants.

## Commandes de support

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh docs
bash scripts/commands/p5.sh diagnostics
```

Dépannage P5 : [`troubleshooting.md`](troubleshooting.md).

Contrat de la distribution WSL2 : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).
