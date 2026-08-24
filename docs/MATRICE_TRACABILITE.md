# Matrice de traçabilité — documentation ↔ code ↔ configuration

## Objectif

Cette matrice empêche la documentation de devenir une seconde réalité parallèle au code.

La règle est simple :

> **Une affirmation technique importante doit pouvoir être reliée à une source de vérité identifiable dans le dépôt.**

Lorsqu'une source de vérité change, les documents qui l'expliquent doivent être relus dans la même évolution.

## Comment utiliser cette matrice

Avant de modifier une documentation :

1. identifier le sujet technique ;
2. lire la source de vérité indiquée ;
3. vérifier le comportement réellement implémenté ;
4. mettre à jour les documents concernés ;
5. lancer les contrôles de qualité et de non-régression.

Avant de modifier le code :

1. repérer la ligne correspondante dans cette matrice ;
2. identifier les documents impactés ;
3. mettre à jour code et documentation ensemble lorsque le comportement public change.

---

## 1. Environnement d'exécution

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| distribution WSL2 attendue `Ubuntu` | `environment/versions.env`, `environment/wsl2/README.md`, `scripts/commands/bootstrap-wsl2.sh` | `README.md`, `docs/README.md`, `docs/00-preparation-environnement.md`, `docs/01-parcours-debutant.md`, runbook | changement de distribution, release ou contrôle de bootstrap |
| Ubuntu 26.04 / `resolute` pour le plan de contrôle | `environment/versions.env` | mêmes documents + `environment/README.md` | changement de version/codename |
| workspaces autorisés | `environment/versions.env`, `environment/wsl2/README.md`, contrôles de bootstrap | README, préparation, parcours débutant, troubleshooting | changement de racines ou de politique `/mnt/*` |
| responsabilité Windows/WSL2 vs P5 | `environment/wsl2/README.md`, scripts de bootstrap | README, architecture, centre de commande, runbook | transfert de responsabilité entre dépôts |
| versions Node/Ansible/Terraform/AWS CLI | `environment/versions.env` | `environment/README.md`, guides qui citent une version précise | modification de `versions.env` |

### Invariant important

Le runtime local et les cibles AWS sont différents :

```text
plan de contrôle : Ubuntu 26.04 sous WSL2
EC2 ex. 1 et 3 : Ubuntu 24.04 LTS par défaut
```

Toute documentation qui parle simplement de « la machine Ubuntu » sans préciser le contexte doit être vérifiée.

---

## 2. Orchestration `p5.sh`

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| liste des commandes | `scripts/commands/p5.sh` → `show_help()` et parsing des arguments | README racine, `docs/CENTRE_DE_COMMANDE.md`, runbook, portail docs | ajout/suppression/renommage d'une commande |
| options `--yes` et `--full-validation` | `scripts/commands/p5.sh` | centre de commande, runbook | changement de sémantique d'une option |
| ordre de `all` | fonctions d'orchestration dans `scripts/commands/p5.sh` | README, runbook, centre de commande | modification de l'enchaînement |
| absence d'`apply` si plan vide | logique `terraform_apply_exercise()` | README, architecture, convergence | changement de traitement `-detailed-exitcode` |
| confirmations avant mutations | `scripts/lib/p5-runtime.sh`, `scripts/commands/p5.sh` | runbook, centre de commande, conventions de sécurité | changement des confirmations |
| logs par run | `scripts/lib/p5-runtime.sh` | centre de commande, preuves, troubleshooting | changement d'arborescence ou de format |

### Contrat documentaire

Ne jamais documenter une commande `p5.sh` qui n'existe pas réellement dans l'aide du script.

---

## 3. Exercice 1 — Terraform

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| version Terraform/provider | `terraform/exercice-1/main.tf`, lockfile, `environment/versions.env` | `terraform/README.md`, guide ex. 1 | changement de contrainte/provider |
| VPC `10.0.0.0/16` | `terraform/exercice-1/main.tf` | architecture, guide ex. 1, parcours débutant | changement CIDR |
| deux subnets publics | `terraform/exercice-1/main.tf` | mêmes documents | changement de topologie |
| Internet Gateway + route publique | `terraform/exercice-1/main.tf` | architecture, guide ex. 1 | changement réseau |
| SSH depuis `your_ip_cidr` | `terraform/exercice-1/main.tf`, `variables.tf` | sécurité, AWS preparation, guide ex. 1 | changement de règle SG |
| HTTP public `:80` | `terraform/exercice-1/main.tf` | architecture, guide ex. 1 | changement du service exposé |
| AMI Ubuntu 24.04 par défaut | filtre `data.aws_ami.ubuntu` dans `terraform/exercice-1/main.tf` | README, architecture, guide ex. 1, glossaire | changement de distribution/AMI |
| IMDSv2 obligatoire | `metadata_options` | sécurité, architecture, Terraform README | changement de politique metadata |
| volume racine gp3 chiffré | `root_block_device` | sécurité, architecture, Terraform README | changement stockage/chiffrement |
| Python 3 via `user_data` | `user_data` | guide ex. 1 si expliqué | changement de bootstrap EC2 |
| outputs web/IP/VPC/subnets | `terraform/exercice-1/outputs.tf` | runbook, guide ex. 1, scripts qui les consomment | ajout/renommage/suppression d'un output |

---

## 4. Exercice 1 — Ansible et Angular

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| groupe cible `webservers` | `ansible/playbooks/deploy.yml`, inventaire example | `ansible/README.md`, guide ex. 1 | changement de groupe/inventaire |
| utilisateur `appuser` / groupe `appgroup` | `ansible/playbooks/deploy.yml` | Ansible README, guide si mentionnés | changement des comptes système |
| racine web `/var/www/p5` | `deploy.yml`, `ansible/files/nginx-angular.conf` | Ansible README, architecture | changement de chemin |
| NGINX + `curl` installés | `deploy.yml` | Ansible README, guide ex. 1 | changement de paquets |
| artefact Angular copié | `deploy.yml`, `scripts/commands/prepare-angular-artifact.sh` | application README, Ansible README, guide ex. 1 | changement du pipeline de build |
| handler de reload NGINX | `deploy.yml` | Ansible README, notion d'idempotence | changement de notification/service |
| fallback SPA | `ansible/files/nginx-angular.conf` | Ansible README, app README, troubleshooting | changement `try_files` |
| sources Angular | `application/angular/` | application READMEs | changement structure applicative |
| scripts npm réellement disponibles | `application/angular/package.json` | `application/angular/README.md`, CI docs | ajout/renommage d'un script npm |
| lint Angular/TS/templates | `package.json`, `eslint.config.js`, `angular.json` | application README, docs CI | changement de stack lint |
| tests contrat + unitaires | `package.json`, `tests/`, `src/**/*.spec.ts` | application README, docs CI | changement des tests |
| artefact versionné synchronisé | `prepare-angular-artifact.sh`, CI | app README, Ansible README | changement du mécanisme de comparaison |

### Invariant important

```text
Terraform crée la machine.
Ansible configure la machine.
Angular fournit l'artefact applicatif.
NGINX sert l'artefact.
```

Une documentation qui attribue ces quatre responsabilités au même outil est incorrecte.

---

## 5. Exercice 2 — Amazon OpenSearch

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| service Amazon OpenSearch | `terraform/exercice-2/main.tf` | README, architecture, guide ex. 2 | changement de mode d'implémentation |
| version moteur de référence | variables/tfvars + `terraform/exercice-2/main.tf` | Terraform README, guide ex. 2 | changement de version par défaut |
| une instance pour le lab | `cluster_config` | guide ex. 2, Terraform README | changement de topologie |
| EBS gp3 | `ebs_options` | Terraform README, architecture | changement stockage |
| HTTPS/TLS | `domain_endpoint_options` | sécurité, AWS README, architecture | changement de politique TLS |
| chiffrement au repos | `encrypt_at_rest` | sécurité, architecture | changement de chiffrement |
| chiffrement node-to-node | `node_to_node_encryption` | sécurité, architecture | changement de chiffrement |
| accès SourceIp `/32` | `access_policies` | sécurité, guide ex. 2, troubleshooting | changement de policy |
| sample reproductible | `terraform/exercice-2/samples/nginx-access.log.sample` | guide ex. 2, architecture | changement du dataset |
| parsing NGINX | `scripts/tools/convert-nginx-logs.py` | guide ex. 2, architecture | changement de champs/parser |
| mapping | `terraform/exercice-2/opensearch/index-template.json` | guide ex. 2, troubleshooting | changement de types/champs |
| import Bulk | `scripts/commands/import-opensearch-data.sh` | guide ex. 2, runbook | changement de CLI ou comportement |
| vérification agrégations | `scripts/commands/verify-opensearch-data.sh` | guide ex. 2, preuves | changement des vérifications |
| Dashboard as Code | `terraform/exercice-2/opensearch/dashboards/p5-dashboard.json`, `scripts/tools/build-opensearch-saved-objects.py`, `scripts/commands/sync-opensearch-dashboards.sh`, orchestration `p5.sh` | README, runbook, guide ex. 2, correspondance consignes | changement des Saved Objects, champs, IDs ou synchronisation API |
| contrôle visuel et captures | checkpoint humain de `p5.sh ex2` | runbook, guide ex. 2, livrables | changement des visuels ou des preuves demandées |

### Vocabulaire de la consigne

Si les consignes pédagogiques emploient **ELK/Kibana**, la documentation doit préciser que le mode Cloud du dépôt utilise **Amazon OpenSearch / OpenSearch Dashboards**. Elle ne doit pas prétendre qu'un cluster Elasticsearch/Kibana est déployé par le code actuel.

---

## 6. Exercice 3 — HAProxy

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| réutilisation du VPC Ex1 | data sources `aws_vpc` / `aws_subnets` dans `terraform/exercice-3/main.tf` | README, architecture, guide ex. 3, cleanup | changement de dépendance réseau |
| 1 EC2 HAProxy | `aws_instance.p5_haproxy` | architecture, guide ex. 3 | changement topologie |
| 2 backends EC2 | `aws_instance.p5_hello` avec `count = 2` | architecture, guide ex. 3 | changement nombre de backends |
| backends `nginxdemos/hello:0.4-plain-text` | `user_data` des backends | Terraform README, guide ex. 3 | changement d'image |
| Docker sur les backends | `user_data` des backends | architecture, guide ex. 3 | changement runtime backend |
| HAProxy installé via apt sur EC2 | `user_data` de `p5_haproxy` | guide ex. 3 si implémentation détaillée | changement mode d'installation |
| HTTP backend seulement depuis SG HAProxy | `aws_security_group.p5_hello_sg` | architecture, sécurité, guide ex. 3 | changement règle SG |
| round-robin | `terraform/exercice-3/haproxy.cfg.tpl` | guide ex. 3, glossaire | changement algorithme |
| health check HTTP | `haproxy.cfg.tpl` | guide ex. 3, glossaire | changement de contrôle |
| test round-robin | `scripts/commands/test-haproxy-roundrobin.sh` | runbook, guide ex. 3 | changement CLI/test |
| test failover et restauration | `scripts/commands/test-haproxy-failover.sh` | runbook, guide ex. 3, troubleshooting | changement scénario de panne |

---

## 7. Configuration AWS et garde-fous

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| configuration locale | `environment/aws-readiness.env.example`, scripts de configuration | AWS README, préparation AWS, runbook | ajout/suppression de paramètres |
| vrais `terraform.tfvars` générés | `scripts/commands/sync-terraform-tfvars.sh` | Terraform README, préparation AWS | changement du générateur |
| identité non root | scripts readiness + politique du projet | AWS README, préparation AWS, sécurité | changement de contrôle d'identité |
| budget | `aws/budgets/`, `setup-aws-guardrails.sh` | AWS README, préparation AWS | changement du mécanisme budgétaire |
| politique IAM du lab | `aws/iam/p5-lab-policy.json` | AWS README, SECURITY.md | changement de permissions |
| fichiers sensibles ignorés | `.gitignore`, audit non-régression | SECURITY.md, README spécialisés | changement de politique Git |

---

## 8. Preuves, livrables et nettoyage

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| structure des preuves runtime | `scripts/lib/p5-runtime.sh`, `proofs/README.md` | contrat preuves, runbook, troubleshooting | changement de structure/manifest |
| préparation des livrables | `scripts/commands/prepare-livrables.sh` | `docs/livrables/README.md`, runbook | changement de contrôle des marqueurs |
| finalisation | logique `finalize` de `p5.sh` | centre de commande, runbook | changement de verdict/étapes |
| destruction ordre 3→2→1 | `scripts/commands/destroy-aws.sh`, dépendance Terraform Ex3→Ex1 | README, runbook, architecture, cleanup docs | changement de dépendances |
| audit AWS final | `scripts/commands/check-aws-cleanup.sh` | README, runbook, troubleshooting | changement du périmètre d'audit |
| verdict `NETTOYAGE AWS COMPLET` | script de cleanup/audit | README, runbook | changement explicite de verdict |

---

## 9. CI, sécurité et non-régression

| Sujet documenté | Source de vérité technique | Documentation à maintenir | Déclencheur de mise à jour |
| --- | --- | --- | --- |
| pipeline CI | `.github/workflows/ci.yml` | README/app docs/audit docs si capacités changent | modification des jobs |
| audit de non-régression | `.github/workflows/non-regression.yml`, `scripts/tools/audit_non_regression.py` | `docs/04-audit-non-regression.md`, conventions docs | changement d'invariants |
| workflow sécurité | `.github/workflows/security.yml` | SECURITY.md si politique change | modification contrôles sécurité |
| contrat WSL2 | `.github/workflows/wsl2-devops-contract.yml` | docs environnement | changement de contrat |
| Dependabot | `.github/dependabot.yml` | docs maintenance uniquement si politique publiée | changement de politique de versions |

### CI ≠ AWS réel

Aucune modification de workflow ne doit conduire la documentation à dire :

```text
CI verte = exercices AWS réellement exécutés
```

La distinction correcte reste :

```text
CI verte     = dépôt cohérent selon ses contrôles
preuve AWS   = comportement réellement observé dans le lab
```

---

## 10. Documents dont la fonction ne doit pas dériver

| Document | Fonction attendue | À éviter |
| --- | --- | --- |
| `README.md` racine | orientation et démarrage | copier toute la documentation technique |
| `docs/README.md` | portail de navigation | devenir un second runbook |
| `docs/01-parcours-debutant.md` | compréhension pédagogique | enchaîner des commandes sans expliquer pourquoi |
| `docs/architecture-et-flux.md` | architecture et responsabilités | procédures incident détaillées |
| `docs/RUNBOOK_EXECUTION_GUIDEE.md` | procédure complète | longs cours théoriques |
| `docs/RUNBOOK_SOUTENANCE.md` | conducteur live : expliquer → prouver → navigateur → transition | reconstruire le lab pendant l’oral ou devenir un tutoriel exhaustif |
| `docs/troubleshooting.md` | diagnostic et récupération | cacher les symptômes derrière des commandes destructives |
| `docs/CENTRE_DE_COMMANDE.md` | référence CLI | documenter des commandes inexistantes |
| guides `docs/exercices/` | compréhension approfondie par exercice | dupliquer tout le runbook A→Z |
| `docs/livrables/` | preuves et remise | présenter un résultat non observé comme preuve réelle |

---

## Checklist de maintenance documentaire

À utiliser lorsqu'un changement technique modifie le comportement public du projet :

- [ ] la source de vérité a été identifiée ;
- [ ] le README racine reste exact ;
- [ ] le portail `docs/README.md` pointe vers les bons documents ;
- [ ] le guide débutant reste compréhensible sans connaissance implicite ;
- [ ] le runbook utilise les commandes réellement supportées ;
- [ ] les résultats attendus correspondent aux scripts ;
- [ ] les avertissements de coût/destruction sont toujours placés avant l'action ;
- [ ] l'architecture reflète les ressources et dépendances réelles ;
- [ ] les versions précises proviennent d'un fichier de configuration ou du code ;
- [ ] les preuves automatiques ne sont pas présentées comme preuves humaines ;
- [ ] aucun secret, state ou valeur runtime réelle n'a été ajouté à la documentation ;
- [ ] aucun bloc Mermaid n'a été introduit ;
- [ ] les liens relatifs fonctionnent ;
- [ ] l'audit de non-régression passe ;
- [ ] la CI est verte.

## Contrôles recommandés

Depuis la racine du dépôt :

```bash
python3 scripts/tools/audit_non_regression.py
bash scripts/commands/validate.sh
```

Les workflows GitHub Actions complètent ces contrôles lors d'une pull request.

## Références

- [Conventions documentaires](CONVENTIONS_DOCUMENTAIRES.md)
- [Portail documentaire](README.md)
- [Architecture et flux](architecture-et-flux.md)
- [Centre de commande](CENTRE_DE_COMMANDE.md)
- [Audit de non-régression](04-audit-non-regression.md)
