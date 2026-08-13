# Exercice 3 — HAProxy, round-robin, panne et reprise sur AWS

## Objectif pédagogique

Le troisième exercice démontre qu'un service peut rester disponible lorsqu'un backend devient indisponible.

L'architecture utilise :

- **HAProxy** comme load-balancer ;
- deux serveurs identiques exécutant `nginxdemos/hello` ;
- des health checks ;
- une panne volontaire ;
- une restauration et une réintégration automatique.

Le succès ne se limite pas à « HAProxy démarre ». Il faut observer le comportement avant, pendant et après la panne.

## Architecture

```text
                  client
                    │
                    │ HTTP :80
                    ▼
                HAProxy EC2
                roundrobin
                  /     \
                 /       \
                ▼         ▼
          hello-1 EC2  hello-2 EC2
             Docker       Docker
          nginx hello   nginx hello
```

## Fichiers à connaître

| Élément | Emplacement |
| --- | --- |
| Terraform | `terraform/exercice-3/` |
| générateur de configuration | `scripts/tools/generer-haproxy-config.sh` |
| test round-robin | `scripts/commands/test-haproxy-roundrobin.sh` |
| test panne/reprise | `scripts/commands/test-haproxy-failover.sh` |
| orchestration | `scripts/commands/p5.sh` |

## 1. Dépendance avec l'exercice 1

L'exercice 3 ne crée pas son propre VPC.

Terraform cherche le VPC de l'exercice 1 à l'aide des tags :

```text
Project   = p5-openclassrooms
Exercise  = 1
Name      = p5-vpc
```

Il cherche également les subnets publics tagués :

```text
Project   = p5-openclassrooms
Exercise  = 1
Type      = public
```

Conséquence :

```text
exercice 1 doit exister avant exercice 3
```

et :

```text
exercice 3 doit être détruit avant exercice 1
```

## 2. Security Groups

Deux groupes sont créés.

### HAProxy

Entrées :

```text
TCP/80 depuis 0.0.0.0/0
TCP/22 depuis votre IPv4 /32
```

### Backends

Entrées :

```text
TCP/80 depuis le Security Group HAProxy
TCP/22 depuis votre IPv4 /32
```

### Pourquoi cette séparation ?

Le navigateur doit atteindre HAProxy, pas contourner le load-balancer pour consommer directement le service backend en HTTP.

Les backends gardent SSH pour le lab parce que le test de panne doit pouvoir arrêter puis restaurer le conteneur de manière contrôlée.

## 3. Les deux backends

Terraform crée :

```hcl
count = 2
```

instances EC2.

Leur `user_data` :

1. met à jour les paquets ;
2. installe Docker ;
3. active Docker ;
4. démarre un conteneur `nginxdemos/hello:plain-text` ;
5. expose le port 80.

Chaque conteneur possède un hostname distinct :

```text
p5-hello-1
p5-hello-2
```

Cette différence permet au test de voir quel backend a répondu.

## 4. HAProxy

L'EC2 HAProxy installe le paquet système `haproxy`, écrit `/etc/haproxy/haproxy.cfg`, valide sa syntaxe puis active le service.

La partie centrale est :

```text
frontend http-in
    bind *:80
    default_backend hello-servers

backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 <IP_PRIVEE_1>:80 check inter 3s fall 3 rise 2
    server hello-2 <IP_PRIVEE_2>:80 check inter 3s fall 3 rise 2
```

## 5. Comprendre `roundrobin`

Le mode :

```text
balance roundrobin
```

répartit les nouvelles requêtes successivement entre les serveurs disponibles.

Avec deux backends sains, une série de requêtes doit donc montrer les deux identités.

Le but n'est pas de garantir une alternance parfaite caractère par caractère dans toutes les situations réseau, mais de prouver que les **deux** backends participent à la distribution.

## 6. Comprendre les health checks

```text
option httpchk GET /
http-check expect status 200
```

HAProxy teste régulièrement la racine HTTP de chaque backend et attend un code 200.

### `inter 3s`

Intervalle de contrôle : environ trois secondes entre checks dans cette configuration.

### `fall 3`

Un backend doit échouer plusieurs fois de suite avant d'être déclaré DOWN.

Cette temporisation évite qu'une seule erreur transitoire sorte immédiatement un serveur du pool.

### `rise 2`

Après restauration, plusieurs checks réussis sont nécessaires avant de déclarer le backend UP.

## 7. Lancer l'exercice

```bash
bash scripts/commands/p5.sh ex3
```

Le moteur :

1. vérifie les préconditions ;
2. converge Terraform ;
3. lit les outputs ;
4. attend HAProxy ;
5. teste le round-robin ;
6. prévisualise le test de failover ;
7. demande confirmation ;
8. exécute la panne réelle ;
9. vérifie la restauration.

## 8. Terraform

Le mécanisme reste :

```text
init
  ↓
plan -detailed-exitcode
  ↓
show
  ↓
confirmation si delta
  ↓
apply
  ↓
post-plan
```

Avant d'accepter, vérifier :

- le VPC détecté est bien celui du P5 ;
- deux backends sont prévus ;
- une HAProxy est prévue ;
- le Security Group backend ne publie pas HTTP vers `0.0.0.0/0` ;
- SSH reste limité au `/32` ;
- les types EC2 sont attendus ;
- les volumes sont chiffrés ;
- aucune destruction inattendue n'est proposée.

## 9. Outputs Terraform

Le module publie :

```text
hello_1_public_ip
hello_2_public_ip
hello_1_private_ip
hello_2_private_ip
haproxy_public_ip
haproxy_private_ip
haproxy_public_dns
haproxy_security_group_id
haproxy_url
```

Lecture :

```bash
terraform -chdir=terraform/exercice-3 output
```

URL du répartiteur :

```bash
terraform -chdir=terraform/exercice-3 \
  output -raw haproxy_url
```

Le moteur utilise `hello_1_public_ip` pour administrer le backend utilisé dans le test de panne.

## 10. Vérifier HAProxy manuellement

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 \
  output -raw haproxy_url)"
```

Puis :

```bash
curl -fsS "$HAPROXY_URL/"
```

La réponse `nginxdemos/hello` contient des informations permettant d'identifier le serveur ayant répondu.

Répéter :

```bash
for i in $(seq 1 10); do
  curl -fsS "$HAPROXY_URL/"
  echo
 done
```

Pour la preuve reproductible, utiliser toutefois le script fourni.

## 11. Test automatisé du round-robin

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

### Ce que le test doit prouver

Sur l'ensemble des requêtes, les identités des deux backends doivent être observées.

Si un seul backend est vu alors que les deux devraient être sains, ne pas conclure immédiatement que le test est mauvais. Vérifier l'état du deuxième backend et les health checks.

## 12. Prévisualiser la panne

L'orchestrateur commence par :

```bash
BACKEND_1="$(terraform -chdir=terraform/exercice-3 \
  output -raw hello_1_public_ip)"
```

Puis :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1"
```

Sans `--apply`, cette commande sert à vérifier/préparer le scénario sans effectuer la mutation temporaire réelle.

## 13. Test réel de panne

Après confirmation :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1" \
  --apply
```

Le scénario doit montrer plusieurs phases.

### Phase A — état sain

```text
hello-1 vu
hello-2 vu
```

### Phase B — arrêt contrôlé

Le conteneur `nginx-hello` du backend 1 est arrêté via SSH.

### Phase C — détection

Les health checks HAProxy échouent assez de fois pour atteindre `fall 3`.

### Phase D — continuité

Les requêtes HTTP continuent à réussir, mais via le backend sain uniquement.

C'est la preuve centrale de disponibilité.

### Phase E — restauration

Le conteneur est redémarré.

### Phase F — réintégration

Après `rise 2`, les deux backends doivent de nouveau apparaître dans les réponses.

## 14. Pourquoi le script utilise une restauration

Une panne de démonstration est une **mutation temporaire**.

Le test doit restaurer l'état fonctionnel même si une étape intermédiaire échoue normalement.

Le script intègre donc une logique de restauration (`trap`) afin de réduire le risque de laisser le backend arrêté.

Cela ne dispense pas de vérifier l'état final.

## 15. Vérifier `haproxy.cfg`

Le fichier de configuration utilisé sur l'EC2 est créé à partir des IP privées réelles des backends.

Sur HAProxy, un contrôle utile est :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Pour le livrable, conserver une copie lisible et anonymisée lorsque les IP exactes n'apportent rien à l'évaluation.

Le dépôt fournit également :

```text
scripts/tools/generer-haproxy-config.sh
```

pour générer une configuration à partir des informations attendues selon le contexte du lab.

## 16. Ce que doivent montrer les preuves

### Preuve 1 — architecture active

- HAProxy EC2 active ;
- deux backends actifs.

### Preuve 2 — configuration

- `balance roundrobin` ;
- deux lignes `server` ;
- health checks ;
- `fall` et `rise`.

### Preuve 3 — avant panne

Les deux backends répondent.

### Preuve 4 — pendant panne

Un seul backend répond et le service HTTP reste disponible.

### Preuve 5 — après reprise

Les deux backends répondent à nouveau.

Une bonne conclusion de preuve est :

```text
La perte d'un backend n'interrompt pas le service public.
HAProxy retire la cible en échec puis la réintègre après restauration.
```

## 17. Diagnostic

### Terraform ne trouve pas le VPC

Vérifier d'abord l'exercice 1 :

```bash
terraform -chdir=terraform/exercice-1 state list
terraform -chdir=terraform/exercice-1 output vpc_id
```

Ne pas créer un VPC manuel pour contourner la dépendance : cela rendrait le dépôt incohérent avec son architecture.

### HAProxy ne répond pas

Vérifier :

- instance HAProxy active ;
- Security Group port 80 ;
- `user_data` terminé ;
- service HAProxy ;
- syntaxe `haproxy.cfg`.

Sur l'instance :

```bash
sudo systemctl status haproxy --no-pager
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo journalctl -u haproxy -n 100 --no-pager
```

### Un backend ne répond jamais

Vérifier sur ce backend :

```bash
sudo systemctl status docker --no-pager
sudo docker ps -a
sudo docker logs nginx-hello
curl -fsS http://127.0.0.1/
```

### Le test de panne coupe tout le service

Vérifier :

- le deuxième backend était sain avant la panne ;
- HAProxy pointe bien vers les deux IP privées ;
- le Security Group backend autorise HTTP depuis HAProxy ;
- le health check est valide.

### Le backend restauré ne revient pas

Attendre le nombre de checks nécessaires à `rise 2`, puis vérifier que le conteneur répond réellement.

## 18. Definition of Done

```text
HAProxy actif
+ 2 backends actifs
+ round-robin vérifié
+ health checks vérifiés
+ panne contrôlée
+ continuité HTTP
+ restauration
+ réintégration
+ haproxy.cfg disponible
+ preuves avant/panne/reprise
```

Après cet exercice, passer à [Validation, preuves et nettoyage](../validation-preuves-nettoyage.md).
