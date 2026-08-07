# Architecture technique et flux du projet P5

Ce document explique **comment les composants du dépôt s’assemblent réellement**.
Il complète le [cadre du projet](00-cadre-officiel.md) et sert de référence avant
les guides d’exécution.

## Vue d’ensemble

Le projet utilise une VM Ubuntu Server comme **poste de contrôle DevOps**. La VM
ne remplace pas les infrastructures évaluées : elle exécute Terraform, Ansible,
AWS CLI, Node.js, Docker et les scripts de validation qui pilotent les ressources
créées dans AWS.

```text
VM Ubuntu Server 26.04
│
├─ Angular : sources → build de production
├─ Terraform : provisionnement AWS
├─ Ansible : configuration de la cible de l’exercice 1
├─ AWS CLI : contrôles, quotas, budget et audit
├─ Docker : intégrations locales et backends de l’exercice 3
└─ scripts : validations, preuves, diagnostics et nettoyage
        │
        ▼
AWS — us-east-1
│
├─ Exercice 1
│  ├─ VPC 10.0.0.0/16
│  ├─ 2 sous-réseaux publics
│  ├─ Internet Gateway + table de routage
│  ├─ paire de clés EC2
│  └─ 1 EC2 Ubuntu → Ansible → NGINX → Angular
│
├─ Exercice 2
│  └─ Amazon OpenSearch Service → index nginx-access-* → Dashboards
│
└─ Exercice 3
   ├─ réutilise le VPC, les sous-réseaux et la clé de l’exercice 1
   ├─ 1 EC2 HAProxy
   └─ 2 EC2 → Docker → nginxdemos/hello
```

![Vue d’ensemble du parcours](schemas/vue-ensemble.svg)

## 1. Poste de contrôle local

Le socle de référence est défini dans `environment/versions.env` :

| Composant | Référence du dépôt | Rôle |
| --- | --- | --- |
| Ubuntu Server | 26.04 | poste de contrôle CLI |
| Node.js | 22.22.0 | build Angular |
| Angular | 21.x | application de l’exercice 1 |
| Terraform | 1.15.8 | provisionnement AWS |
| Ansible Core | 2.20.1 | configuration de la cible EC2 |
| Docker | moteur local | tests d’intégration et backends HAProxy |
| AWS CLI v2 | profil `p5-lab` | identité, contrôles et exploitation AWS |

La VM possède deux responsabilités distinctes :

1. **préparer et valider** le code avant toute mutation AWS ;
2. **piloter** les exercices et enregistrer les preuves techniques locales.

Elle ne doit contenir dans Git aucun secret, état Terraform, inventaire réel ou
preuve runtime.

## 2. Source unique de configuration AWS

Le fichier local `environment/aws-readiness.env` est la source de vérité des
paramètres dépendant du compte et de la session :

```text
environment/aws-readiness.env
          │
          ├─ identité / région / compte attendu
          ├─ IPv4 publique /32
          ├─ taille des ressources
          ├─ clé EC2
          ├─ paramètres OpenSearch
          └─ budget et confirmations de sécurité
          │
          ▼
scripts/commands/sync-terraform-tfvars.sh
          │
          ├─ terraform/exercice-1/terraform.tfvars
          ├─ terraform/exercice-2/terraform.tfvars
          └─ terraform/exercice-3/terraform.tfvars
```

Les trois `terraform.tfvars` **ne doivent pas être édités comme trois sources
indépendantes**. Toute évolution de compte, région, IP ou taille doit être faite
dans `aws-readiness.env`, puis synchronisée :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Les fichiers produits sont écrits en mode `600` et ignorés par Git.

## 3. Exercice 1 — réseau partagé et cible Ansible

Terraform crée :

- un VPC `10.0.0.0/16` ;
- deux sous-réseaux publics répartis sur deux zones de disponibilité ;
- une Internet Gateway ;
- une table de routage publique ;
- un groupe de sécurité `p5-web-sg` ;
- une paire de clés EC2 ;
- une instance EC2 Ubuntu 24.04 LTS.

Le groupe de sécurité autorise :

- SSH `22/tcp` uniquement depuis `your_ip_cidr` en `/32` ;
- HTTP `80/tcp` publiquement pour la démonstration de l’application.

L’instance impose IMDSv2 et un volume racine `gp3` chiffré.

### Flux applicatif

```text
application/angular/
      │ npm ci + npm run build
      ▼
application/angular/dist/
      │ copie contrôlée
      ▼
ansible/files/angular-app/
      │ ansible-playbook
      ▼
EC2 /var/www/p5
      │
      ▼
NGINX :80
      │
      ├─ fichiers statiques Angular
      └─ fallback SPA → /index.html
```

Le playbook cible le groupe Ansible `webservers`, crée un utilisateur de service,
copie l’artefact sous `/var/www/p5`, installe la configuration NGINX, valide
`nginx -t`, active le service et ne recharge NGINX que lorsqu’un fichier change.

### Sorties Terraform utiles

| Output | Utilisation |
| --- | --- |
| `web_public_ip` | inventaire Ansible et collecte SSH des logs |
| `web_private_ip` | diagnostic réseau |
| `web_public_dns` | accès alternatif à la cible |
| `web_url` | vérification HTTP et génération de trafic |
| `vpc_id` | compréhension de la dépendance avec l’exercice 3 |
| `public_subnet_ids` | compréhension du réseau partagé |

## 4. Exercice 2 — pipeline de logs OpenSearch

L’exercice 2 est indépendant du VPC de l’exercice 1. Terraform crée un domaine
Amazon OpenSearch Service avec :

- OpenSearch 2.19 par défaut ;
- un nœud `t3.small.search` par défaut ;
- un volume `gp3` de 10 Gio par défaut ;
- chiffrement au repos ;
- chiffrement entre nœuds ;
- HTTPS obligatoire avec TLS 1.2 minimum ;
- politique d’accès limitée à l’IPv4 d’administration en `/32`.

### Flux des données

```text
NGINX access.log réel                échantillon versionné
        │                                   │
        └──────────────┬────────────────────┘
                       ▼
             convert-nginx-logs.py
                       │
                       ▼
                 Bulk NDJSON
                       │
                       ▼
           import-opensearch-data.sh
                       │
             nginx-access-*
                       │
                       ▼
           verify-opensearch-data.sh
                       │
                       ▼
          OpenSearch Dashboards
            ├─ Donut méthodes HTTP
            ├─ Octets par 12 h
            └─ Top 5 URL par 12 h
```

L’import est volontairement séparé en deux modes :

- sans `--apply` : validation et génération locale du Bulk ;
- avec `--apply` : création du template et import réel.

Les visualisations restent manuelles car leur construction fait partie de la
compréhension évaluée.

### Sorties Terraform utiles

| Output | Utilisation |
| --- | --- |
| `opensearch_domain_name` | identification du domaine |
| `opensearch_endpoint` | scripts d’import et de vérification |
| `opensearch_dashboards_endpoint` | construction manuelle du dashboard |
| `opensearch_arn` | diagnostic et inventaire |

## 5. Exercice 3 — HAProxy et dépendance réseau

L’exercice 3 **ne crée pas un second VPC**. Il recherche par tags le VPC et les
sous-réseaux publics créés par l’exercice 1, puis réutilise aussi la paire de
clés `p5-key`.

Terraform crée :

- un groupe de sécurité HAProxy ;
- un groupe de sécurité pour les backends ;
- deux instances EC2 `p5-hello-1` et `p5-hello-2` ;
- une instance EC2 `p5-haproxy`.

Les backends exécutent `nginxdemos/hello:plain-text` dans Docker. Leur port HTTP
n’est autorisé que depuis le groupe de sécurité HAProxy. L’administration SSH
reste limitée à l’adresse `/32` du poste de contrôle.

### Flux HTTP

```text
Client
  │ HTTP :80
  ▼
HAProxy
  │ balance roundrobin
  │ health check GET /
  │ inter 3s / fall 3 / rise 2
  ├───────────────┐
  ▼               ▼
p5-hello-1     p5-hello-2
Docker          Docker
nginxdemos      nginxdemos
```

Le test de panne :

1. observe deux backends ;
2. arrête `nginx-hello` sur un backend par SSH ;
3. attend le retrait par HAProxy ;
4. vérifie la continuité avec un seul backend ;
5. redémarre le conteneur ;
6. attend la réintégration ;
7. observe de nouveau deux backends.

Un `trap` tente de restaurer le backend si le script est interrompu après
l’arrêt.

### Sorties Terraform utiles

| Output | Utilisation |
| --- | --- |
| `haproxy_url` | tests round-robin et failover |
| `haproxy_public_ip` | accès et diagnostic |
| `hello_1_public_ip`, `hello_2_public_ip` | administration SSH des backends |
| `hello_1_private_ip`, `hello_2_private_ip` | configuration HAProxy |
| `haproxy_security_group_id` | diagnostic réseau |

## 6. Dépendances et ordre d’exécution

```text
Étape 0A ──► Étape 0B ──► Exercice 1 ──┬──► Exercice 3
                                        │
                                        └──► logs réels pour Exercice 2

Exercice 2 peut techniquement être déployé indépendamment,
mais les logs réels sont produits naturellement par l’exercice 1.
```

La dépendance critique est :

```text
Exercice 1 réseau + clé EC2 ──► Exercice 3
```

Conséquence : **ne jamais détruire l’exercice 1 avant l’exercice 3**.

## 7. Ordre de destruction

L’ordre de fermeture du lab est :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS global
```

Le script `destroy-aws.sh` applique cet ordre lorsqu’un état Terraform local est
présent. L’audit `check-aws-cleanup.sh` vérifie ensuite l’absence de ressources P5
sur l’ensemble du compte/région ciblé.

## 8. Tags et garde-fous communs

Les trois providers Terraform utilisent :

- `allowed_account_ids` ;
- `Project = p5-openclassrooms` ;
- `ManagedBy = Terraform` ;
- `Purpose = training-lab` ;
- un tag `Exercise` propre au module.

Ces tags servent à la compréhension, au contrôle des collisions, à l’inventaire
et au nettoyage final.

## 9. Où aller ensuite

- Exécution complète : [parcours de bout en bout](01-parcours-debutant.md)
- Exercice 1 : [Terraform + Ansible + Angular](exercices/01-terraform-ansible.md)
- Exercice 2 : [OpenSearch](exercices/02-elk-opensearch.md)
- Exercice 3 : [HAProxy](exercices/03-haproxy.md)
- Preuves et nettoyage : [validation, preuves et finalisation](validation-preuves-nettoyage.md)
- Problèmes : [guide de diagnostic](troubleshooting.md)
