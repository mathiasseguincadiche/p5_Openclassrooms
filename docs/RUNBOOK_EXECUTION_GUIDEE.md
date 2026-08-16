# Runbook d'exécution guidée — P5 de A à Z

## Objectif

Ce runbook est la procédure opératoire principale du P5. Il donne l'ordre d'exécution, les commandes à copier-coller, les résultats attendus et les points d'arrêt.

Les guides `docs/exercices/` expliquent les concepts en détail ; ici, l'objectif est de **réaliser le parcours sans inventer de valeur runtime**.

Toutes les commandes P5 sont exécutées dans la VM Ubuntu Server 26.04 `ubuntu-devops`.

## Règles de sécurité et de reprise

1. exécuter les commandes P5 depuis `ubuntu-devops`, pas depuis le HOST ;
2. laisser `Ubuntu-desktops-custom` propriétaire du HOST, de KVM/libvirt et du cycle de vie de la VM ;
3. travailler dans `~/labs/p5_Openclassrooms` sur le filesystem Linux local de la VM ;
4. commencer par observer l'état réel ;
5. ne jamais supprimer un `terraform.tfstate` pour forcer une reprise ;
6. lire tout plan Terraform avant de confirmer un changement ;
7. utiliser les outputs Terraform comme source des IP et URL ;
8. conserver les validations humaines lorsqu'une preuve visuelle est demandée ;
9. considérer toute ressource AWS active comme potentiellement facturable.

## Phase 0 — Entrer dans la VM d'exécution

La création, le démarrage, l'arrêt et la réparation de la VM sont documentés dans [`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom).

Une fois `ubuntu-devops` saine et joignable, se connecter en SSH :

```bash
ssh <utilisateur>@<ip-ubuntu-devops>
```

Puis, **dans la VM** :

```bash
cd ~/labs/p5_Openclassrooms
hostname -s
cat /etc/os-release
systemd-detect-virt
pwd
git status --short
```

Résultats attendus :

```text
hostname : ubuntu-devops
OS       : Ubuntu Server 26.04 / resolute
virt     : kvm ou qemu
checkout : /home/<utilisateur>/labs/p5_Openclassrooms
```

`git status` ne doit pas signaler de secret, de state Terraform ou de vrai `terraform.tfvars` ajouté au suivi Git.

## Phase 1 — Observer avant de modifier

```bash
bash scripts/commands/p5.sh inspect
```

Cette étape permet de détecter un lab déjà commencé, des states Terraform, des outputs existants, une configuration locale et des preuves déjà collectées.

### Point d'arrêt

Si le contrôle indique que l'environnement n'est pas `ubuntu-devops` sous Ubuntu Server 26.04/KVM, ne pas essayer de corriger la virtualisation avec le P5. Revenir au dépôt `Ubuntu-desktops-custom`.

Si une valeur Terraform/AWS nécessaire est inconnue, ne pas la remplacer par une valeur copiée au hasard dans la console. Corriger la source indiquée par le diagnostic.

## Phase 2 — Préparer le runtime P5 et AWS

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` vérifie ou réconcilie :

- le runtime logiciel requis par le P5 **dans `ubuntu-devops`** ;
- Terraform, Ansible, Node.js, AWS CLI, Docker et les outils P5 nécessaires ;
- l'authentification AWS ;
- `environment/aws-readiness.env` ;
- l'IPv4 publique d'administration `/32` ;
- la clé SSH du lab ;
- le budget et les garde-fous ;
- les trois `terraform.tfvars` locaux.

`prepare` ne crée pas la VM, ne modifie pas KVM/libvirt et ne change pas le HOST.

Contrôle du runtime seul, sans modification :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

### Point d'arrêt

Ne pas poursuivre si :

- le runtime n'est pas exécuté dans la VM attendue ;
- l'identité AWS ou le compte attendu est incohérent ;
- l'IPv4 `/32`, la clé SSH, les quotas ou les `tfvars` sont incohérents.

Si la préparation ajoute l'utilisateur au groupe Docker, quitter puis rouvrir la session SSH avant de relancer `prepare`.

## Phase 3 — Vérifier que le lab est prêt

```bash
bash scripts/commands/p5.sh status
```

Le précontrôle Terraform doit pouvoir atteindre :

```text
GO TERRAFORM
```

Ce verdict autorise la lecture du plan. Il n'autorise jamais un changement aveugle.

---

# Exercice 1 — Terraform + Ansible + Angular/NGINX

## Phase 4 — Lancer l'exercice 1

```bash
bash scripts/commands/p5.sh ex1
```

Le parcours réalise :

```text
build Angular
→ Terraform init/plan
→ confirmation si delta
→ outputs Terraform
→ inventaire Ansible
→ attente SSH
→ Ansible ping
→ déploiement Angular + NGINX
→ second passage Ansible
→ vérification HTTP
→ trafic de preuve
→ collecte access.log
```

## Vérifications manuelles utiles

Récupérer les valeurs depuis Terraform :

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"
printf 'WEB_URL=%s\nWEB_IP=%s\n' "$WEB_URL" "$WEB_IP"
```

Vérifier l'application :

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$WEB_URL"
```

Tester Ansible :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Le second passage du playbook doit se terminer par :

```text
changed=0
unreachable=0
failed=0
```

Générer puis collecter les logs si une reprise ciblée est nécessaire :

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
- [ ] vrai `access.log` collecté.

Guide détaillé : [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md).

---

# Exercice 2 — Amazon OpenSearch

## Phase 5 — Lancer l'exercice 2

```bash
bash scripts/commands/p5.sh ex2
```

Le parcours fait converger le domaine Amazon OpenSearch, valide les données, importe le sample et le log réel disponible, puis vérifie mappings et agrégations.

## Récupérer les endpoints sans les recopier manuellement

```bash
OPENSEARCH_ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
DASHBOARDS_URL="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint)"
printf 'OPENSEARCH_ENDPOINT=%s\nDASHBOARDS_URL=%s\n' \
  "$OPENSEARCH_ENDPOINT" "$DASHBOARDS_URL"
```

Contrôle technique ciblé :

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$OPENSEARCH_ENDPOINT"
```

## Checkpoint humain OpenSearch Dashboards

Ouvrir l'URL affichée par :

```bash
printf '%s\n' "$DASHBOARDS_URL"
```

Vérifier ou créer réellement :

1. un donut de répartition des méthodes HTTP ;
2. la somme de `bytes_sent` par tranches de 12 h ;
3. le top 5 de `url_path` par tranches de 12 h ;
4. le dashboard qui rassemble les trois visualisations.

Conserver quatre captures réelles : les trois visualisations et le dashboard complet.

Le mode `--yes` de l'orchestrateur ne remplace pas cette validation humaine.

### Definition of Done — exercice 2

- [ ] domaine OpenSearch actif ;
- [ ] données importées sans erreur ;
- [ ] mapping et agrégations valides ;
- [ ] données visibles dans Dashboards ;
- [ ] trois visualisations correctes ;
- [ ] dashboard complet ;
- [ ] quatre captures conservées.

Guide détaillé : [`exercices/02-opensearch.md`](exercices/02-opensearch.md).

---

# Exercice 3 — HAProxy et résilience

## Phase 6 — Lancer l'exercice 3

L'exercice 1 doit encore fournir son VPC et ses sous-réseaux.

```bash
bash scripts/commands/p5.sh ex3
```

Le parcours vérifie le round-robin puis démontre une panne contrôlée et la réintégration du backend restauré.

## Récupérer les valeurs depuis Terraform

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

La preuve attendue doit montrer :

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

Guide détaillé : [`exercices/03-haproxy.md`](exercices/03-haproxy.md).

---

# Phase 7 — Diagnostics, livrables et soutenance

Collecter l'état et les preuves :

```bash
bash scripts/commands/p5.sh diagnostics
```

Contrôler strictement les livrables :

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu lorsque les livrables ne contiennent plus de preuve à compléter :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Avant publication :

- relire les captures ;
- masquer les données sensibles inutiles ;
- ne jamais publier de state Terraform, de vrai `tfvars`, de clé ou de credential ;
- contextualiser chaque preuve.

Préparation de l'oral : [`05-soutenance.md`](05-soutenance.md).

---

# Phase 8 — Fermer le lab AWS

Une fois les preuves et captures terminées :

```bash
bash scripts/commands/p5.sh cleanup
```

Le projet respecte l'ordre de dépendance :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Le lab AWS n'est considéré comme fermé qu'après :

```text
NETTOYAGE AWS COMPLET
```

Le nettoyage P5 **ne détruit pas `ubuntu-devops`**. L'arrêt ou la sauvegarde de la VM relève ensuite du dépôt `Ubuntu-desktops-custom`.

Si l'audit détecte encore une ressource AWS gérée, identifier d'abord le module Terraform propriétaire et son state avant toute correction.

---

# Reprendre après une interruption

Après fermeture du terminal, redémarrage de la VM ou redémarrage du HOST :

1. utiliser `Ubuntu-desktops-custom` pour confirmer que `ubuntu-devops` est saine et démarrée ;
2. se reconnecter en SSH à la VM ;
3. reprendre le P5 sans supprimer son état.

Dans la VM :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh status
```

Ensuite relancer uniquement l'étape réellement nécessaire ou reprendre le parcours convergent :

```bash
bash scripts/commands/p5.sh all
```

`all` recalcule les deltas et réutilise les states existants. Il ne signifie pas « supprimer puis recréer ».

## Commandes de support

```bash
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh guide
bash scripts/commands/p5.sh docs
bash scripts/commands/p5.sh diagnostics
```

En cas de blocage P5 : [`troubleshooting.md`](troubleshooting.md).

En cas de blocage HOST/KVM/VM : utiliser le runbook de `Ubuntu-desktops-custom`.
