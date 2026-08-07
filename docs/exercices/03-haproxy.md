# Exercice 3 — HAProxy, disponibilité et reprise

Cette fiche décrit l’exercice 3 dans le parcours AWS retenu. L’objectif est de
démontrer une répartition réelle entre deux backends, la continuité du service
pendant une panne et la réintégration automatique du backend restauré.

![Flux de l’exercice 3](../schemas/exercice-3.svg)

## Objectif

Déployer HAProxy devant deux instances `nginxdemos/hello`, utiliser
`roundrobin`, superviser la santé des backends et vérifier la bascule lors d’une
panne contrôlée.

## Résultat final attendu

```text
2 backends actifs
      ↓
ROUND-ROBIN OPÉRATIONNEL
      ↓
1 backend arrêté
      ↓
service toujours disponible
      ↓
backend redémarré
      ↓
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## Dépendance critique

L’exercice 3 réutilise :

- le VPC de l’exercice 1 ;
- les deux sous-réseaux publics de l’exercice 1 ;
- la paire de clés EC2 de l’exercice 1.

L’exercice 1 doit donc être **encore déployé**.

Le module recherche ces ressources par tags au lieu de créer un nouveau réseau.

## Prérequis

- étape 0A validée ;
- AWS Ready validé ;
- exercice 1 encore présent ;
- clé privée SSH disponible ;
- tfvars synchronisés ;
- adresse publique `/32` actuelle ;
- quota EC2 suffisant.

Contrôles :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
./scripts/commands/pre-deployment-check.sh --stage exercice-3
```

Le contrôle doit confirmer le VPC et la clé de l’exercice 1.

## Ce que Terraform crée

Le module `terraform/exercice-3/` crée :

- groupe de sécurité HAProxy ;
- groupe de sécurité des backends ;
- deux EC2 backends ;
- une EC2 HAProxy.

### HAProxy

Le groupe de sécurité HAProxy autorise :

- HTTP 80 publiquement ;
- SSH 22 uniquement depuis le `/32` d’administration.

### Backends

Chaque backend :

- utilise Ubuntu 24.04 LTS par défaut ;
- installe Docker dans `user_data` ;
- démarre `nginxdemos/hello:plain-text` ;
- expose le conteneur sur le port 80 ;
- n’autorise HTTP que depuis le groupe de sécurité HAProxy ;
- autorise SSH uniquement depuis le `/32` du lab ;
- impose IMDSv2 ;
- utilise un volume racine `gp3` chiffré.

Les noms des conteneurs sont identiques (`nginx-hello`) mais leurs hostnames
sont déterministes : `p5-hello-1` et `p5-hello-2`.

## Configuration HAProxy utilisée

Le cœur du backend est :

```text
backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 ADRESSE_PRIVEE_1:80 check inter 3s fall 3 rise 2
    server hello-2 ADRESSE_PRIVEE_2:80 check inter 3s fall 3 rise 2
```

Interprétation :

- `inter 3s` : contrôle toutes les 3 secondes ;
- `fall 3` : retrait après trois échecs successifs ;
- `rise 2` : réintégration après deux succès successifs.

## Fichiers concernés

```text
terraform/exercice-3/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example

scripts/
├── commands/test-haproxy-roundrobin.sh
├── commands/test-haproxy-failover.sh
├── tests/test-haproxy-containers.sh
└── tools/generer-haproxy-config.sh
```

## Étape 1 — Initialiser et valider Terraform

```bash
terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 fmt -check
terraform -chdir=terraform/exercice-3 validate
```

## Étape 2 — Produire et relire le plan

```bash
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 show tfplan
```

Vérifier :

- utilisation du bon VPC ;
- deux backends ;
- une instance HAProxy ;
- règles réseau ;
- types d’instance ;
- clé EC2 ;
- chiffrement ;
- absence de ressource réseau dupliquée inutilement.

## Étape 3 — Appliquer

```bash
terraform -chdir=terraform/exercice-3 apply tfplan
terraform -chdir=terraform/exercice-3 output
```

Outputs :

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

Les services démarrés par `user_data` peuvent nécessiter un court délai après la
fin de `terraform apply`.

## Étape 4 — Valider une configuration HAProxy localement

Le générateur permet de vérifier la syntaxe indépendamment d’AWS :

```bash
./scripts/tools/generer-haproxy-config.sh \
  10.0.1.10 10.0.2.10 /tmp/haproxy.cfg
```

Puis :

```bash
docker run --rm \
  --volume /tmp/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  haproxy:3.2-alpine \
  haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

Sur l’instance réelle :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
```

## Étape 5 — Vérifier le round-robin

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 10
```

Le script :

- lit `haproxy_url` ;
- envoie plusieurs requêtes ;
- extrait `Server name` ;
- exige au moins deux backends distincts ;
- écrit la preuve sous `proofs/runtime/exercice-3/`.

Verdict :

```text
ROUND-ROBIN OPÉRATIONNEL
```

## Étape 6 — Prévisualiser le scénario de panne

```bash
./scripts/commands/test-haproxy-failover.sh
```

Sans `--apply` :

- les deux backends sont observés ;
- le scénario est préparé ;
- aucune connexion SSH destructive n’arrête de conteneur.

Utilisez ce mode avant chaque démonstration réelle.

## Étape 7 — Exécuter la panne réelle

Exemple :

```bash
./scripts/commands/test-haproxy-failover.sh \
  --backend 1 \
  --requests 6 \
  --apply
```

Le script :

1. confirme les deux backends ;
2. récupère l’IP publique du backend choisi ;
3. se connecte en SSH ;
4. arrête `nginx-hello` ;
5. attend la détection de panne ;
6. exige un seul backend en réponse ;
7. redémarre `nginx-hello` ;
8. attend la réintégration ;
9. exige de nouveau deux backends.

Valeurs de référence :

- attente après arrêt : 12 secondes ;
- attente après redémarrage : 10 secondes.

Ces délais sont configurables par options du script.

## Restauration de sécurité

Après un arrêt réel, un `trap` est actif sur `EXIT`, `INT` et `TERM`.

Si le script est interrompu alors que le backend est marqué arrêté, il tente :

```text
sudo docker start nginx-hello
```

Cette restauration réduit le risque d’une panne permanente mais ne dispense pas
de vérifier manuellement l’état après une interruption.

## Verdict final

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## Preuves à conserver

### Infrastructure

- plan Terraform ;
- trois EC2 actives ;
- outputs utiles anonymisés.

### Configuration

- copie lisible de `haproxy.cfg` ;
- `haproxy -c` réussi ;
- service HAProxy actif.

### Round-robin

- deux noms de serveur observés sur plusieurs requêtes.

### Panne

- deux backends avant la panne ;
- un seul pendant la panne ;
- service HTTP toujours disponible.

### Reprise

- conteneur redémarré ;
- retour des deux backends ;
- verdict final du script.

Gabarit :
[`Livrable 3`](../livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md).

## Ce qu’il ne faut pas publier

- clé privée SSH ;
- tfvars ;
- état Terraform ;
- adresse complète non nécessaire ;
- contenu brut non relu de `proofs/runtime/`.

## Nettoyage

Une fois toutes les preuves de l’exercice 3 collectées :

```bash
terraform -chdir=terraform/exercice-3 destroy
```

Vous pouvez ensuite détruire l’exercice 1 si ses preuves et ses logs ne sont plus
nécessaires.

Ordre global recommandé :

```text
Exercice 3 → Exercice 2 → Exercice 1 → check-aws-cleanup.sh
```

La procédure complète se trouve dans
[Validation, preuves et nettoyage](../validation-preuves-nettoyage.md).
