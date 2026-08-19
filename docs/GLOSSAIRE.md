# Glossaire — comprendre le vocabulaire du P5

Ce glossaire explique les termes utilisés dans le dépôt **dans le contexte exact du projet**. Il ne cherche pas à remplacer la documentation officielle des outils : son rôle est d'aider un débutant à comprendre ce que signifie un mot lorsqu'il le rencontre dans le README, un runbook, un plan Terraform ou une preuve.

## Comment utiliser ce glossaire

Lorsqu'un terme est nouveau :

1. lire sa définition ici ;
2. regarder à quoi il correspond concrètement dans le dépôt ;
3. revenir au guide ou au runbook en cours ;
4. consulter ensuite la documentation technique spécialisée si nécessaire.

Le parcours pédagogique principal reste [`01-parcours-debutant.md`](01-parcours-debutant.md).

---

## Plan de contrôle

Le **plan de contrôle** est l'environnement depuis lequel le projet pilote les opérations.

Dans ce P5 :

```text
Windows 11 Pro
└── WSL2
    └── Ubuntu 26.04 LTS
        └── ~/labs/p5_Openclassrooms
            └── scripts/commands/p5.sh
```

C'est depuis cette distribution WSL2 que sont exécutés Terraform, Ansible, AWS CLI, Node.js et les scripts du projet.

Le plan de contrôle n'est pas une EC2 AWS.

---

## WSL2

**Windows Subsystem for Linux 2** permet d'exécuter un environnement Linux virtualisé sous Windows.

Dans ce projet, WSL2 fournit le contexte Linux local de référence. Le checkout doit rester sur le filesystem Linux de la distribution, par exemple :

```text
~/labs/p5_Openclassrooms
```

Les racines `/mnt/c` et `/mnt/d` ne sont pas les workspaces DevOps de référence.

Voir [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

---

## Infrastructure as Code — IaC

L'**Infrastructure as Code** consiste à décrire l'infrastructure dans des fichiers versionnés plutôt que de la créer uniquement à la main dans une console Cloud.

Dans le P5, Terraform décrit les ressources AWS des trois exercices.

L'intérêt principal est de pouvoir :

- relire ce qui doit exister ;
- calculer les différences avec l'état réel ;
- reproduire l'infrastructure ;
- vérifier les changements avant de les appliquer ;
- conserver une trace versionnée de l'intention technique.

---

## Terraform

Terraform est l'outil d'IaC utilisé pour créer et maintenir les ressources AWS du P5.

Le dépôt possède trois modules :

```text
terraform/exercice-1/
terraform/exercice-2/
terraform/exercice-3/
```

Terraform **provisionne l'infrastructure**. Il n'est pas utilisé pour copier le build Angular sur l'EC2 : cette responsabilité appartient à Ansible.

### Provider

Un **provider** est le composant Terraform qui sait communiquer avec une plateforme externe.

Ici :

```text
hashicorp/aws
```

Le provider AWS est configuré avec la région du lab et un `allowed_account_ids` qui empêche d'appliquer le projet dans un compte inattendu.

### State

Le **state Terraform** mémorise la relation entre les ressources décrites dans le code et les ressources réellement gérées.

Exemple local :

```text
terraform/exercice-1/terraform.tfstate
```

Le state n'est **pas un simple cache**. Le supprimer peut empêcher Terraform de savoir quelles ressources il possède encore.

Dans ce projet, les states :

- restent locaux ;
- ne sont pas versionnés ;
- doivent être conservés jusqu'au nettoyage propre du lab.

### Plan

`terraform plan` calcule le **delta** entre l'état demandé par le code et l'état connu/réel.

Il permet de répondre à :

> « Qu'est-ce que Terraform ferait si j'acceptais maintenant ? »

Le projet utilise `-detailed-exitcode` pour distinguer notamment :

```text
0 = aucun changement nécessaire
2 = un delta existe
```

Un delta doit être lu et compris avant `apply`.

### Apply

`terraform apply` applique un plan et peut donc créer, modifier ou détruire des ressources.

Dans le parcours normal, `p5.sh` n'applique pas un plan vide et demande une confirmation lorsqu'un vrai delta existe.

### Output

Un **output Terraform** expose une valeur calculée à partir de l'infrastructure réellement gérée.

Exemples :

```text
web_public_ip
web_url
opensearch_endpoint
haproxy_url
```

Ces outputs sont les sources de référence pour les scripts et les procédures. On évite de recopier manuellement une IP ou une URL lorsqu'un output la fournit.

### Delta

Le **delta** est la différence entre l'état attendu et l'état observé.

```text
état attendu
    vs
état réel
    ↓
delta
```

Une automatisation convergente corrige uniquement ce delta.

---

## Convergence

La **convergence** consiste à amener progressivement le système vers l'état attendu sans recréer inutilement ce qui est déjà correct.

Le principe du P5 est :

```text
inspecter
→ comparer
→ corriger uniquement l'écart
→ vérifier
→ journaliser
```

Cela permet de reprendre un lab existant après une interruption.

Voir [`convergence-et-reexecution.md`](convergence-et-reexecution.md).

---

## Idempotence

Une opération est **idempotente** lorsqu'on peut la rejouer sans provoquer de changement inutile une fois l'état cible atteint.

Dans l'exercice 1, la preuve principale est le second passage Ansible :

```text
changed=0
unreachable=0
failed=0
```

Cela signifie que le serveur est déjà conforme au playbook et qu'Ansible n'a rien eu à modifier.

---

## Ansible

Ansible configure l'EC2 créée par Terraform dans l'exercice 1.

Il est responsable notamment de :

- l'installation de NGINX et `curl` ;
- la création de l'utilisateur et du groupe de l'application ;
- la copie de l'artefact Angular ;
- la configuration NGINX ;
- l'activation et le démarrage du service.

### Inventaire

L'**inventaire Ansible** indique quelles machines Ansible doit administrer et comment les joindre.

Dans ce projet :

```text
ansible/inventories/hosts_aws
```

L'inventaire réel est local et ignoré par Git.

### Playbook

Un **playbook** est un fichier YAML décrivant les tâches qu'Ansible doit réaliser.

Dans le P5 :

```text
ansible/playbooks/deploy.yml
```

### Handler

Un **handler** est une action déclenchée uniquement lorsqu'une tâche notifie qu'un changement pertinent a réellement eu lieu.

Dans `deploy.yml`, NGINX est rechargé lorsque la configuration ou l'artefact déployé change. Cela participe à l'idempotence.

---

## NGINX

NGINX est le serveur web de l'exercice 1.

Il :

- sert l'application Angular sur le port 80 ;
- applique le fallback nécessaire à la SPA ;
- produit les logs HTTP dans `/var/log/nginx/access.log`.

Ces logs réels peuvent ensuite alimenter l'exercice 2.

---

## SPA — Single Page Application

Une **SPA** est une application web dont le navigateur charge principalement un document HTML puis laisse JavaScript gérer l'interface et la navigation.

L'application Angular du P5 est une SPA.

La configuration NGINX utilise un fallback vers `index.html` afin qu'une route Angular comme `/parcours-p5` reste accessible même lorsqu'elle est ouverte directement.

---

## AWS Region

Une **région AWS** est une zone géographique dans laquelle les ressources Cloud sont créées.

Le P5 centralise la région du lab dans sa configuration locale. Le compte et la région doivent rester cohérents entre AWS CLI et Terraform.

---

## VPC

Un **Virtual Private Cloud** est le réseau logique privé utilisé par les ressources AWS.

L'exercice 1 crée :

```text
VPC 10.0.0.0/16
```

L'exercice 3 réutilise ce VPC au lieu d'en créer un autre.

---

## Subnet

Un **subnet** est une subdivision du VPC.

L'exercice 1 crée deux subnets publics dans deux zones de disponibilité disponibles. L'exercice 3 les retrouve par leurs tags.

---

## Internet Gateway — IGW

Une **Internet Gateway** permet au VPC d'échanger du trafic avec Internet lorsque les routes et règles de sécurité l'autorisent.

Dans l'exercice 1, elle est associée à une table de routage publique contenant notamment :

```text
0.0.0.0/0 → Internet Gateway
```

---

## Security Group — SG

Un **Security Group** est un pare-feu virtuel attaché aux ressources AWS.

Exemples dans le P5 :

- HTTP `80` public vers NGINX ou HAProxy ;
- SSH `22` limité à l'adresse d'administration ;
- HTTP des backends de l'exercice 3 autorisé uniquement depuis le Security Group HAProxy.

---

## `/32`

Une adresse comme :

```text
203.0.113.10/32
```

représente **une seule adresse IPv4**.

Le P5 utilise ce principe pour limiter SSH et l'accès OpenSearch à l'IPv4 publique actuelle du poste d'administration plutôt que d'ouvrir ces accès à Internet entier.

Si l'IPv4 publique change, la configuration doit être réévaluée.

---

## EC2

**Amazon EC2** fournit des machines virtuelles dans AWS.

Le P5 utilise des EC2 pour :

- l'instance Angular/NGINX de l'exercice 1 ;
- l'instance HAProxy de l'exercice 3 ;
- les deux backends `nginxdemos/hello` de l'exercice 3.

Les EC2 des exercices 1 et 3 utilisent par défaut une AMI Ubuntu 24.04 LTS Canonical.

Cela ne doit pas être confondu avec Ubuntu 26.04 sous WSL2, qui est le plan de contrôle local.

---

## AMI

Une **Amazon Machine Image** est l'image de base utilisée pour créer une EC2.

Le code Terraform recherche par défaut une image Canonical Ubuntu 24.04 LTS `noble` pour les exercices concernés.

---

## IMDSv2

**Instance Metadata Service v2** est le mécanisme sécurisé permettant à une EC2 d'accéder à ses métadonnées.

Les EC2 du P5 exigent IMDSv2 avec :

```text
http_tokens = required
```

C'est un garde-fou de sécurité défini dans Terraform.

---

## Amazon OpenSearch Service

Amazon OpenSearch Service est le service managé utilisé dans l'exercice 2 pour indexer et analyser les logs HTTP.

Le domaine du P5 applique notamment :

- HTTPS obligatoire ;
- TLS 1.2 minimum ;
- chiffrement au repos ;
- chiffrement entre nœuds ;
- restriction d'accès à l'IPv4 `/32` du lab.

### Index

Un **index** regroupe des documents dans OpenSearch.

Le pipeline du P5 transforme les lignes NGINX en documents structurés puis les importe dans OpenSearch.

### Mapping

Le **mapping** décrit les types des champs.

Exemple : `bytes_sent` doit être numérique pour permettre une somme. Un mauvais type peut rendre une visualisation impossible même si les données sont présentes.

### Bulk API

La **Bulk API** permet d'envoyer plusieurs opérations d'indexation dans une même requête.

Le pipeline P5 produit des données NDJSON adaptées à cet import.

### Agrégation

Une **agrégation** calcule une vue synthétique sur les documents.

Le P5 utilise des agrégations nécessaires aux visualisations :

- répartition des méthodes HTTP ;
- somme de `bytes_sent` ;
- top des `url_path`.

### OpenSearch Dashboards

OpenSearch Dashboards est l'interface graphique utilisée pour explorer les données et construire les visualisations de l'exercice 2.

La consigne pédagogique peut employer le vocabulaire ELK/Kibana ; le mode Cloud de ce dépôt utilise Amazon OpenSearch et OpenSearch Dashboards.

---

## Load balancer

Un **load balancer** répartit les requêtes entre plusieurs serveurs.

Dans l'exercice 3, HAProxy joue ce rôle devant deux backends.

---

## HAProxy

HAProxy est le répartiteur de charge de l'exercice 3.

Il est installé sur une EC2 et distribue le trafic HTTP entre deux backends `nginxdemos/hello`.

### Round-robin

Le **round-robin** distribue successivement les requêtes entre les backends disponibles.

Dans le P5 :

```text
requête 1 → backend 1
requête 2 → backend 2
requête 3 → backend 1
...
```

Le comportement exact dépend aussi de l'état de santé des backends.

### Health check

Un **health check** vérifie périodiquement qu'un backend est capable de répondre correctement.

Le P5 utilise un contrôle HTTP `GET /`. Lorsqu'un backend échoue suffisamment de fois, HAProxy le retire temporairement du pool. Après plusieurs contrôles réussis, il le réintègre.

---

## CI — Continuous Integration

La **CI** automatise les contrôles du dépôt lors des changements de code.

Dans le P5, GitHub Actions vérifie notamment :

- scripts Bash ;
- Terraform ;
- Ansible ;
- Angular ;
- tests locaux NGINX/OpenSearch/HAProxy ;
- sécurité et non-régression documentaire/structurelle.

Une CI verte prouve la cohérence du dépôt. Elle **ne prouve pas** que votre compte AWS a réellement exécuté les trois exercices.

---

## Preuve runtime

Une **preuve runtime** est un résultat observé pendant une véritable exécution.

Exemples :

- sortie d'un `terraform plan` convergé ;
- second passage Ansible à `changed=0` ;
- capture OpenSearch Dashboards ;
- test HAProxy pendant la panne.

Une bonne preuve répond à :

```text
quelle action ?
quel résultat ?
pourquoi ce résultat valide-t-il le besoin ?
```

---

## Checkpoint humain

Un **checkpoint humain** est une validation qui ne doit pas être déclarée automatiquement à la place de l'opérateur.

Dans l'exercice 2, la création et la vérification visuelle des trois visualisations et du dashboard constituent un checkpoint humain.

Même le mode `--yes` ne doit pas inventer cette validation.

---

## Non-régression

La **non-régression** consiste à vérifier qu'une amélioration ne casse pas les capacités déjà validées.

Le dépôt dispose notamment de :

```bash
python3 scripts/tools/audit_non_regression.py
```

et de workflows GitHub Actions dédiés.

---

## Nettoyage AWS

Le **nettoyage** est une phase technique complète du projet. Il ne s'agit pas seulement de fermer le terminal.

Ordre attendu :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, il ne faut pas supposer que toute ressource facturable a disparu.

---

## Aller plus loin dans la documentation

- [Portail documentaire](README.md)
- [Parcours débutant](01-parcours-debutant.md)
- [Architecture et flux](architecture-et-flux.md)
- [Runbook complet](RUNBOOK_EXECUTION_GUIDEE.md)
- [Troubleshooting](troubleshooting.md)
- [Matrice de traçabilité](MATRICE_TRACABILITE.md)
