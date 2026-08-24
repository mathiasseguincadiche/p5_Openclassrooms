# 02 — Correspondance consignes → implémentation → preuve

Cette matrice est la **carte de traçabilité** du projet. Elle distingue clairement :

- ce que demande l’exercice ;
- où l’implémentation se trouve dans le dépôt ;
- comment la vérifier ;
- quelle preuve doit provenir d’une exécution réelle.

Le choix de réalisation du dépôt est **AWS pour les trois exercices**.

> **Important :** la présence d’un fichier dans Git ne prouve pas que l’exercice
a été exécuté. Les éléments marqués « preuve réelle » doivent provenir du lab.

## Lecture des états

| État | Signification |
| --- | --- |
| Implémenté | code ou configuration versionné et vérifiable |
| Automatisé | contrôle reproductible fourni par le dépôt |
| Manuel | action volontairement laissée à l’utilisateur |
| Preuve réelle | résultat à produire pendant l’exécution AWS |
| Local uniquement | fichier ignoré par Git et non publiable tel quel |

## Exercice 1 — Terraform, Ansible, NGINX et Angular

| Besoin | Implémentation | Vérification | Preuve attendue |
| --- | --- | --- | --- |
| Infrastructure Terraform | `terraform/exercice-1/` | `terraform validate` + plan | plan relu et `apply` réel |
| VPC et réseau public | `terraform/exercice-1/main.tf` | outputs `vpc_id`, `public_subnet_ids` | ressources AWS créées |
| Cible EC2 | `aws_instance.web` | output `web_public_ip` | instance `running` |
| Compte AWS verrouillé | `allowed_account_ids` | `pre-deployment-check.sh` | `GO TERRAFORM` |
| SSH limité au poste | `your_ip_cidr` `/32` | AWS Ready + plan | règle réseau visible sans donnée sensible |
| Volume EC2 chiffré | `root_block_device.encrypted = true` | CI + plan | configuration Terraform |
| IMDSv2 | `http_tokens = "required"` | CI + plan | configuration Terraform |
| Inventaire Ansible | `hosts_aws.example` + copie locale | `ansible ... -m ping` | ping réel réussi |
| Playbook | `ansible/playbooks/deploy.yml` | syntax-check + exécution | recap sans échec |
| NGINX | `ansible/files/nginx-angular.conf` | `nginx -t` + test Docker | config valide |
| Application Angular réelle | `application/angular/` | `npm test`, build, CI | application réellement servie et visible dans le navigateur |
| Artefact déployé | `ansible/files/angular-app/` | comparaison CI avec `dist/` | même build déployé |
| Idempotence Ansible | même playbook relancé | seconde exécution | recap avec absence de changements inutiles |
| Fallback SPA | `try_files ... /index.html` | `verify-angular-deployment.sh` | `/parcours-p5` en HTTP 200 |
| Bundle JavaScript | build Angular | `verify-angular-deployment.sh` | bundle accessible |
| Logs NGINX | `/var/log/nginx/access.log` | génération + collecte | log réel local |

### Fichiers de preuve locaux

```text
proofs/runtime/exercice-1/
proofs/runtime/exercice-2/*nginx-access-real.log
```

Ils sont **locaux uniquement** tant qu’ils n’ont pas été relus et anonymisés.

### Livrable associé

[`Livrable 1`](livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md)

## Exercice 2 — Amazon OpenSearch et dashboard

| Besoin | Implémentation | Vérification | Preuve attendue |
| --- | --- | --- | --- |
| Mode Cloud retenu | Amazon OpenSearch | guide de l’exercice 2 | domaine réel actif |
| Domaine OpenSearch | `terraform/exercice-2/` | Terraform validate + plan | `apply` réel |
| HTTPS / TLS | `domain_endpoint_options` | CI + plan | configuration visible |
| Chiffrement au repos | `encrypt_at_rest` | CI + plan | configuration visible |
| Chiffrement inter-nœuds | `node_to_node_encryption` | CI + plan | configuration visible |
| Accès limité au poste | politique `SourceIp` `/32` | AWS Ready + plan | accès depuis le lab |
| Données NGINX | sample ou log réel Ex.1 | convertisseur | source validée |
| Mapping OpenSearch | `opensearch/index-template.json` | `verify-opensearch-data.sh` | mapping réel |
| Import Bulk | `import-opensearch-data.sh --apply` | contrôle `.errors == false` | import réussi |
| Au moins 64 documents | dataset / import | `verify-opensearch-data.sh` | comptage réel |
| Index pattern | `p5-dashboard.json` + générateur Saved Objects | `_field_caps` + import/relecture API | objet réel présent dans Dashboards |
| Donut HTTP | Dashboard as Code, champ `http_method` | import/relecture API + contrôle navigateur | capture réelle lisible |
| Octets par 12 h | Dashboard as Code, `Sum(bytes_sent)` + intervalle `12h` | import/relecture API + contrôle navigateur | capture réelle lisible |
| Top 5 URL par 12 h | Dashboard as Code, `url_path`, taille 5 + intervalle `12h` | import/relecture API + contrôle navigateur | capture réelle lisible |
| Dashboard complet | `p5-nginx-observability` versionné | 5 Saved Objects relus par API + contrôle navigateur | capture réelle des 3 visuels réunis |

### Ce qui est automatisé et ce qui reste humain

Le dépôt automatise la transformation et l’import des données, les contrôles de
mapping/agrégations, la génération des Saved Objects, le contrôle `_field_caps`,
l’import avec écrasement contrôlé et la relecture des cinq objets par API.

La partie volontairement humaine est la **validation du rendu réel dans le
navigateur** : vérifier la plage temporelle, la lisibilité des trois
visualisations et réaliser les captures demandées. La soutenance ne doit pas
recréer les graphiques à la souris.

### Livrable associé

[`Livrable 2`](livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md)

## Exercice 3 — HAProxy, round-robin et failover

| Besoin | Implémentation | Vérification | Preuve attendue |
| --- | --- | --- | --- |
| Réutiliser le réseau Ex.1 | data sources Terraform par tags | AWS Ready `exercice-3` | VPC détecté |
| Deux backends | `aws_instance.p5_hello`, `count = 2` | Terraform outputs | 2 EC2 actives |
| HAProxy | `aws_instance.p5_haproxy` | output `haproxy_url` | EC2 active |
| `nginxdemos/hello` | Docker dans `user_data` | navigateur + réponse `Server name` | deux hostnames distincts |
| HTTP backend privé | SG backend depuis SG HAProxy | plan Terraform | backends non exposés directement en HTTP public |
| `roundrobin` | HAProxy config | navigateur + `test-haproxy-roundrobin.sh` | deux backends observés |
| Health check HTTP | `option httpchk GET /` | config + test | retrait automatique |
| Seuil de panne | `fall 3` | config | un seul backend pendant panne |
| Seuil de reprise | `rise 2` | config | retour des deux backends |
| Simulation non destructive | failover sans `--apply` | script | scénario vérifié |
| Panne réelle | failover avec `--apply` | arrêt SSH du conteneur | continuité du service |
| Restauration | `trap` + redémarrage | script | backend réintégré |
| `haproxy.cfg` | Terraform + générateur local | `haproxy -c` | copie anonymisée |

### Livrable associé

[`Livrable 3`](livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md)

## Éléments transverses

| Capacité | Emplacement | Rôle | Preuve / contrôle |
| --- | --- | --- | --- |
| Versions du lab | `environment/versions.env` | reproductibilité | `setup.sh` |
| Configuration AWS | `environment/aws-readiness.env` local | source unique | AWS Ready |
| Synchronisation tfvars | `sync-terraform-tfvars.sh` | cohérence des 3 modules | `--check` |
| Budget AWS | `aws/budgets/` + script | garde-fou coût | AWS Ready |
| Politique IAM | `aws/iam/p5-lab-policy.json` | permissions du lab | confirmation manuelle |
| Validation locale | `validate.sh` | qualité du dépôt | verdict local / CI |
| Non-régression | `audit_non_regression.py` | protège les capacités | workflow dédié |
| Audit secrets | `audit_secrets.py` | hygiène Git | workflow sécurité |
| Diagnostic | `collect-diagnostics.sh` | support | archive nettoyée |
| Preuves techniques | `proofs/runtime/` | collecte locale | non versionné |
| Livrables | `docs/livrables/` | remise | contrôle strict |
| Nettoyage | `destroy-aws.sh` | destruction 3 → 2 → 1 | confirmation `DETRUIRE` |
| Audit final | `check-aws-cleanup.sh` | absence de résidu P5 | `NETTOYAGE AWS COMPLET` |

## Éléments hors périmètre

Les éléments suivants ne constituent pas des exercices de ce P5 :

- Kubernetes ;
- Helm ;
- Prometheus ;
- Grafana ;
- Vault ;
- pipeline GitHub Actions comme livrable autonome.

GitHub Actions est utilisé uniquement comme **mécanisme de qualité du dépôt**.

## Ordre des dépendances

```text
Étape 0A
   ↓
Étape 0B
   ↓
Exercice 1 ─────────────► Exercice 3
   │
   └── logs réels ─────► Exercice 2
```

La dépendance obligatoire est Exercice 1 → Exercice 3.

## Ordre de fermeture

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit global AWS
```

Le contrôle `check-aws-cleanup.sh` est global : il ne doit produire
`NETTOYAGE AWS COMPLET` qu’après la fermeture de l’ensemble du lab.

## Documents associés

- [Architecture technique](architecture-et-flux.md)
- [Runbook de soutenance](RUNBOOK_SOUTENANCE.md)
- [Runbook d’exécution guidée](RUNBOOK_EXECUTION_GUIDEE.md)
- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
- [Livrables](livrables/README.md)
