# Runbook d'exécution guidée — P5 de A à Z

## Objet du runbook

Ce document est la **procédure opératoire principale** du P5. Il répond à quatre questions pour chaque phase :

1. **pourquoi** cette phase existe ;
2. **quelle commande** exécuter ;
3. **quel résultat** doit être observé ;
4. **quand s'arrêter** au lieu de continuer avec un état incertain.

Il est destiné à l'exécution réelle du lab. Pour comprendre les concepts avant d'agir, lire d'abord [`01-parcours-debutant.md`](01-parcours-debutant.md). Pour approfondir un exercice, utiliser les guides sous [`exercices/`](exercices/).

Toutes les commandes P5 sont exécutées dans la distribution WSL2 **`Ubuntu`**, Ubuntu 26.04 LTS (`resolute`). Les EC2 créées par Terraform utilisent Ubuntu 24.04 LTS par défaut : ce sont des machines distinctes.

> **Règle de sécurité**  
> Si une valeur importante est inconnue, si un plan Terraform contient une destruction non comprise ou si l'identité AWS n'est pas celle attendue, **arrêter la procédure**. Le bon réflexe est `inspect → logs → diagnostic`, pas une modification au hasard.

## Parcours complet

![Architecture et dépendances du P5](schemas/vue-ensemble.svg)

```text
qualifier la plateforme WSL2
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
cleanup : 3 → 2 → 1
        ↓
audit AWS → NETTOYAGE AWS COMPLET
```

## Règles opératoires communes

- travailler dans `Ubuntu` sous WSL2 ;
- conserver le checkout sur le filesystem Linux, par exemple `~/labs/p5_Openclassrooms` ;
- commencer par observer l'état réel ;
- conserver les `terraform.tfstate` : ils matérialisent la propriété Terraform et permettent la reprise ;
- lire chaque `terraform plan` avant toute confirmation ;
- utiliser les outputs Terraform comme source des IP, URL et endpoints ;
- ne jamais remplacer une valeur inconnue par une IP copiée depuis un autre environnement ;
- conserver les checkpoints humains demandés par le projet ;
- traiter toute ressource AWS active comme potentiellement facturable ;
- conserver les preuves utiles avant la destruction du lab.

Le cycle de vie de Windows, WSL2 et du VHDX est géré par [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom), pas par ce dépôt.

---

## Phase 0 — Qualifier la plateforme d'exécution

### Pourquoi ?

Terraform, Ansible, Docker et les scripts Bash doivent s'exécuter dans le contexte pour lequel le projet a été validé. Diagnostiquer AWS depuis une plateforme déjà incorrecte rend les erreurs difficiles à interpréter.

### Depuis le dépôt `Windows_11_Pro_Custom`

Dans PowerShell, valider la plateforme puis ouvrir la distribution :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
wsl.exe -d Ubuntu
```

### Dans WSL2

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
noyau        : microsoft-standard-WSL2
PID 1        : systemd
workspace    : filesystem Linux du VHDX
```

### Ouvrir le projet

```bash
mkdir -p ~/labs
cd ~/labs
```

Pour une première utilisation :

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
pwd
git status --short
bash scripts/commands/bootstrap-wsl2.sh --check-only
```

### Point d'arrêt

Ne pas poursuivre si :

- `WSL_DISTRO_NAME` n'est pas `Ubuntu` ;
- `/etc/os-release` ne correspond pas au contrat attendu ;
- systemd n'est pas PID 1 ;
- le checkout est utilisé comme workspace sous `/mnt/c` ou `/mnt/d` ;
- les outils communs fournis par la plateforme Windows/WSL2 sont absents ou incohérents.

Référence : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

---

## Phase 1 — Observer l'état réel

### Pourquoi ?

Le lab est convergent : il doit pouvoir reprendre un état existant. Avant de créer ou réparer quoi que ce soit, il faut déterminer ce qui existe déjà.

### Commande

```bash
bash scripts/commands/p5.sh inspect
```

### Ce que `inspect` cherche à qualifier

- configuration locale disponible ;
- states Terraform présents ;
- outputs existants ;
- preuves déjà collectées ;
- état de reprise du lab ;
- informations inconnues qui doivent rester inconnues tant qu'une source fiable ne les fournit pas.

### Critère de succès

Le résultat doit être compréhensible : vous devez savoir si vous êtes face à un premier run, une reprise ou un état incomplet.

### Point d'arrêt

Si l'état observé contredit ce que vous pensiez trouver, ne passez pas directement à `apply`. Consultez [`convergence-et-reexecution.md`](convergence-et-reexecution.md).

---

## Phase 2 — Préparer le runtime P5 et le compte AWS

### Pourquoi ?

Cette phase aligne les prérequis **sans confondre préparation et déploiement des exercices**.

### Commande

```bash
bash scripts/commands/p5.sh prepare
```

### Responsabilités réelles de `prepare`

Le moteur :

- **vérifie** la présence et la compatibilité des outils communs fournis par la plateforme, notamment Terraform, AWS CLI et Docker ;
- **converge les dépendances propres au P5**, notamment Node.js, Ansible Core et les outils de validation concernés ;
- qualifie l'identité et le compte AWS ;
- prépare `environment/aws-readiness.env` ;
- qualifie l'IPv4 publique d'administration en `/32` ;
- vérifie ou prépare la clé SSH du lab ;
- vérifie/converge le budget selon les confirmations ;
- synchronise les trois `terraform.tfvars` locaux.

Le contrat logiciel se trouve dans [`../environment/versions.env`](../environment/versions.env).

### Contrôle du runtime seul

```bash
bash scripts/commands/bootstrap-wsl2.sh --check-only
```

### Point particulier : groupe Docker

Après ajout de l'utilisateur au groupe Docker, la session courante peut conserver les anciens groupes.

Depuis PowerShell :

```powershell
wsl.exe --terminate Ubuntu
wsl.exe -d Ubuntu
```

Puis dans WSL2 :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh status
```

Ne réinstallez pas Docker pour un simple problème de session de groupe.

### Point d'arrêt

Ne pas poursuivre si :

- l'identité AWS est root ou inattendue ;
- le compte AWS ne correspond pas au compte attendu ;
- l'IPv4 `/32`, la clé SSH ou les paramètres requis sont incomplets ;
- les `terraform.tfvars` ne sont pas synchronisés ;
- une mutation proposée n'est pas comprise.

---

## Phase 3 — Revalider avant Terraform

### Pourquoi ?

`prepare` peut corriger des écarts. `status` sert à vérifier l'état résultant sans déployer l'infrastructure des exercices.

### Commande

```bash
bash scripts/commands/p5.sh status
```

### Verdict attendu

```text
GO TERRAFORM
```

### Ce que ce verdict signifie

Le lab est suffisamment préparé pour **lire un plan Terraform**.

### Ce qu'il ne signifie pas

- qu'un `apply` est obligatoire ;
- que le plan contient forcément un changement souhaitable ;
- que le compte AWS est gratuit ;
- que les exercices ont déjà été réalisés.

---

## Phase 4 — Exercice 1 : Terraform + Ansible + Angular/NGINX

![Exercice 1 — infrastructure et déploiement](schemas/exercice-1.svg)

### Pourquoi ?

L'exercice démontre la séparation entre **provisionnement d'infrastructure** et **configuration de serveur**.

- Terraform crée VPC, subnets, Internet Gateway, routage, Security Group, paire de clés et EC2 ;
- Ansible installe/configure NGINX et déploie l'artefact Angular ;
- le second passage Ansible démontre l'idempotence ;
- le trafic généré produit le vrai `access.log` utilisé par l'exercice 2.

### Commande principale

```bash
bash scripts/commands/p5.sh ex1
```

### Flux exécuté

```text
build Angular
+ Terraform init / plan / apply si delta
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

Vérifier le déploiement :

```bash
bash scripts/commands/verify-angular-deployment.sh --url "$WEB_URL"
```

Vérifier la connectivité Ansible :

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

Rejouer du trafic et collecter le log si nécessaire :

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 96

bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

### Definition of Done — exercice 1

- [ ] plan Terraform compris et infrastructure convergée ;
- [ ] post-plan sans delta ;
- [ ] EC2 disponible ;
- [ ] Ansible ping réussi ;
- [ ] premier playbook sans échec ;
- [ ] second passage `changed=0`, `unreachable=0`, `failed=0` ;
- [ ] Angular accessible derrière NGINX ;
- [ ] `access.log` réel collecté.

### Si la phase échoue

Ne supprimez pas le state pour recommencer. Commencez par :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
```

Puis utilisez [`troubleshooting.md`](troubleshooting.md), sections Terraform, SSH, Ansible ou NGINX selon la couche en échec.

Guide technique : [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md).

---

## Phase 5 — Exercice 2 : Amazon OpenSearch

![Exercice 2 — logs vers OpenSearch](schemas/exercice-2.svg)

### Pourquoi ?

L'exercice transforme des logs bruts en informations exploitables. Le sample versionné garantit la reproductibilité ; le vrai log NGINX démontre le lien avec une application réellement déployée.

### Commande principale

```bash
bash scripts/commands/p5.sh ex2
```

### Flux exécuté

1. convergence du domaine Amazon OpenSearch ;
2. préparation du sample reproductible ;
3. import du log réel de l'exercice 1 lorsqu'il est disponible ;
4. vérification des mappings, documents et agrégations ;
5. checkpoint humain dans OpenSearch Dashboards.

### Récupérer les endpoints

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
printf 'OPENSEARCH_ENDPOINT=%s\nDASHBOARDS_URL=%s\n' \
  "$OPENSEARCH_ENDPOINT" "$DASHBOARDS_URL"
```

### Contrôle technique

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

### Checkpoint humain obligatoire

Créer ou vérifier réellement :

1. un donut de répartition des méthodes HTTP ;
2. la somme de `bytes_sent` par tranches de 12 h ;
3. le top 5 de `url_path` par tranches de 12 h ;
4. le dashboard regroupant les trois visualisations.

Conserver quatre captures lisibles : les trois visualisations et le dashboard complet.

Le mode `--yes` **ne valide pas** ce checkpoint à la place de l'opérateur.

### Definition of Done — exercice 2

- [ ] domaine OpenSearch actif ;
- [ ] plan Terraform compris et convergé ;
- [ ] données importées sans erreur ;
- [ ] mappings et agrégations valides ;
- [ ] données visibles dans Dashboards ;
- [ ] trois visualisations correctes ;
- [ ] dashboard complet ;
- [ ] quatre captures conservées.

### Si la phase échoue

Ne recréez pas le domaine par réflexe. Vérifiez d'abord :

- état du domaine ;
- endpoint Terraform ;
- région et compte ;
- IPv4 `/32` actuelle ;
- plage temporelle dans Dashboards ;
- mapping des champs.

Guide technique : [`exercices/02-opensearch.md`](exercices/02-opensearch.md).

---

## Phase 6 — Exercice 3 : HAProxy et résilience

![Exercice 3 — HAProxy et résilience](schemas/exercice-3.svg)

### Précondition forte

L'exercice 1 doit encore fournir son VPC et ses subnets. L'exercice 3 les recherche par tags AWS/Terraform.

### Pourquoi ?

La simple présence de `haproxy.cfg` ne prouve pas la haute disponibilité. Il faut observer le comportement du service avant, pendant et après une panne contrôlée.

### Commande principale

```bash
bash scripts/commands/p5.sh ex3
```

### Flux exécuté

1. convergence de l'infrastructure exercice 3 ;
2. attente de la disponibilité de HAProxy ;
3. vérification du round-robin ;
4. panne temporaire d'un backend après confirmation ;
5. vérification de la continuité du service ;
6. restauration du backend ;
7. vérification de sa réintégration.

### Récupérer les valeurs Terraform

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
BACKEND_1_IP="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"
printf 'HAPROXY_URL=%s\nBACKEND_1_IP=%s\n' \
  "$HAPROXY_URL" "$BACKEND_1_IP"
```

### Vérifier le round-robin

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

### Preuve attendue

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

### Si la phase échoue

Vérifiez d'abord si le problème vient :

1. du réseau de l'exercice 1 ;
2. de l'EC2 HAProxy ;
3. du service HAProxy ;
4. d'un backend Docker ;
5. du test de panne lui-même.

Guide technique : [`exercices/03-haproxy.md`](exercices/03-haproxy.md).

---

## Phase 7 — Diagnostiquer et finaliser les livrables

### Pourquoi ?

La CI et les logs automatiques ne remplacent pas les preuves finales. Il faut contrôler que chaque preuve existe, correspond à une exécution réelle et ne publie pas d'information sensible inutile.

### Collecter les diagnostics

```bash
bash scripts/commands/p5.sh diagnostics
```

### Contrôler les livrables

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu lorsque les preuves requises sont présentes :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

### Avant publication

- relire chaque capture ;
- vérifier qu'elle prouve bien l'objectif annoncé ;
- masquer les informations sensibles inutiles ;
- ne jamais publier de state Terraform, vrai `tfvars`, clé privée ou credential ;
- contextualiser chaque preuve par **commande → résultat → interprétation**.

Références :

- [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md) ;
- [`livrables/README.md`](livrables/README.md) ;
- [`05-soutenance.md`](05-soutenance.md).

---

## Phase 8 — Fermer le lab AWS

![Finalisation et fermeture AWS](schemas/finalisation/finalisation.svg)

### Précondition

Ne détruisez pas le lab avant d'avoir conservé les preuves et captures nécessaires.

### Commande

```bash
bash scripts/commands/p5.sh cleanup
```

### Ordre de destruction

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

L'exercice 3 doit disparaître avant l'exercice 1 puisqu'il dépend de son réseau.

### Verdict final

```text
NETTOYAGE AWS COMPLET
```

### Point d'arrêt

Si ce verdict n'est pas obtenu :

- ne concluez pas que les coûts sont arrêtés ;
- identifiez la ressource restante ;
- identifiez le module Terraform qui devrait en être propriétaire ;
- vérifiez le state avant toute suppression manuelle.

L'arrêt ou la sauvegarde de la distribution WSL2 `Ubuntu` est indépendant du nettoyage AWS.

---

## Reprendre après une interruption

### Situation normale

Après fermeture du terminal, redémarrage de Windows ou interruption du travail :

```bash
wsl.exe -d Ubuntu
```

Puis dans WSL2 :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh status
```

Le parcours convergent complet peut être relancé :

```bash
bash scripts/commands/p5.sh all
```

`all` recalcule les deltas et réutilise les states existants. Il ne signifie pas « tout recréer depuis zéro ».

Guide : [`convergence-et-reexecution.md`](convergence-et-reexecution.md).

## Matrice de reprise rapide

| Situation | Première action | Ne pas faire |
| --- | --- | --- |
| WSL2 ne démarre pas | revenir à `Windows_11_Pro_Custom` | modifier Terraform |
| erreur après redémarrage | `p5.sh inspect` | supprimer les states |
| compte AWS inattendu | corriger l'authentification | changer `allowed_account_ids` pour contourner |
| plan propose une destruction inattendue | refuser puis inspecter state/code/variables | accepter pour « voir » |
| SSH inaccessible | vérifier output, clé, `/32`, SG et route | modifier Ansible en premier |
| OpenSearch inaccessible | vérifier domaine, endpoint et `/32` | recréer le domaine immédiatement |
| backend HAProxy en panne après test | restaurer le conteneur puis vérifier | lancer un nouvel `apply` sans diagnostic |
| cleanup incomplet | auditer la ressource et son state | supposer que les coûts sont terminés |

## Commandes de support

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh docs
```

Dépannage : [`troubleshooting.md`](troubleshooting.md).

Catalogue des procédures : [`runbooks/README.md`](runbooks/README.md).

Contrat WSL2 : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).
