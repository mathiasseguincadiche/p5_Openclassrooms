# Livrable 3 — HAProxy et `nginxdemos/hello`

> **Gabarit à compléter avec des preuves réelles.** Les tests de répartition,
> de panne et de reprise doivent être exécutés sur l'environnement AWS du projet.

## 1. Architecture

Le mode retenu est **AWS avec Terraform**.

L'exercice 3 réutilise le réseau et la paire de clés créés par l'exercice 1. Il
ne crée donc pas un second VPC.

Architecture déployée :

```text
Client HTTP
   │
   ▼
EC2 p5-haproxy
   │  roundrobin + health checks
   ├───────────────┐
   ▼               ▼
EC2 p5-hello-1   EC2 p5-hello-2
Docker            Docker
nginxdemos/hello  nginxdemos/hello
```

Caractéristiques à démontrer :

- un serveur HAProxy ;
- deux backends distincts ;
- algorithme `roundrobin` ;
- health check HTTP `GET /` ;
- retrait après trois échecs (`fall 3`) ;
- réintégration après deux succès (`rise 2`) ;
- continuité du service pendant la panne d'un backend.

### Précontrôle et déploiement

Avant Terraform :

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-3
```

Le contrôle doit notamment confirmer la présence du VPC et de la clé EC2 de
l'exercice 1. Le verdict attendu est `GO TERRAFORM`.

Déploiement :

```bash
terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 fmt -check
terraform -chdir=terraform/exercice-3 validate
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 show tfplan
terraform -chdir=terraform/exercice-3 apply tfplan
terraform -chdir=terraform/exercice-3 output
```

**Preuves à insérer :** plan relu, trois instances actives et sorties Terraform
anonymisées permettant d'identifier HAProxy et les deux backends.

## 2. Fichier `haproxy.cfg`

La configuration réelle générée sur l'instance HAProxy contient au minimum :

```text
frontend http-in
    bind *:80
    default_backend hello-servers

backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 ADRESSE_PRIVEE_1:80 check inter 3s fall 3 rise 2
    server hello-2 ADRESSE_PRIVEE_2:80 check inter 3s fall 3 rise 2
```

Le générateur local peut produire une copie minimale équivalente :

```bash
./scripts/tools/generer-haproxy-config.sh \
  ADRESSE_PRIVEE_1 ADRESSE_PRIVEE_2 /tmp/haproxy.cfg
```

Pour la remise, joindre une version lisible et anonymisée de la configuration.
Les adresses privées peuvent être partiellement masquées si la structure reste
compréhensible.

**À joindre :** copie réelle ou reproduction fidèle de `haproxy.cfg`, avec les
paramètres `roundrobin`, `httpchk`, `fall` et `rise` visibles.

## 3. Validation de la configuration

Sur l'instance HAProxy :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
```

La validation doit confirmer :

- syntaxe HAProxy valide ;
- service démarré ;
- aucun backend mal référencé.

Le générateur peut également être validé localement dans un conteneur :

```bash
docker run --rm \
  --volume /tmp/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  haproxy:3.2-alpine \
  haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

**Preuve réelle à insérer.**

## 4. Répartition de charge

Utiliser le test reproductible du dépôt :

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 10
```

Le script lit par défaut la sortie Terraform `haproxy_url`, effectue plusieurs
requêtes et extrait le champ `Server name` renvoyé par `nginxdemos/hello`.

Le verdict attendu est :

```text
ROUND-ROBIN OPÉRATIONNEL
```

La preuve doit montrer au moins deux noms de serveur distincts. Une simple série
de codes HTTP 200 ne suffit pas à démontrer la répartition.

**Preuve à insérer :** sortie du script montrant les deux backends dans la
rotation.

## 5. Panne et continuité de service

### Aperçu non destructif

Commencer sans `--apply` :

```bash
./scripts/commands/test-haproxy-failover.sh
```

Dans ce mode, aucune connexion SSH ne provoque de panne. Le script vérifie l'état
initial et décrit le scénario.

### Panne réelle et reprise

Après validation :

```bash
./scripts/commands/test-haproxy-failover.sh \
  --backend 1 \
  --requests 6 \
  --apply
```

Le scénario automatisé :

1. observe les deux backends avant la panne ;
2. arrête le conteneur `nginx-hello` du backend choisi par SSH ;
3. attend le retrait du backend par les health checks HAProxy ;
4. vérifie que le service continue avec un seul backend ;
5. redémarre le conteneur ;
6. attend sa réintégration ;
7. vérifie le retour des deux backends dans la rotation.

Un `trap` tente de redémarrer le backend si le script est interrompu après son
arrêt.

Le verdict attendu est :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

**Preuves à insérer :**

- avant la panne : deux backends observés ;
- pendant la panne : un seul backend observé et service toujours accessible ;
- après la reprise : retour des deux backends ;
- verdict final du script.

### Conclusion à rédiger

Expliquer brièvement :

- le rôle du `roundrobin` ;
- le rôle des health checks ;
- pourquoi le service reste disponible avec un backend arrêté ;
- comment HAProxy décide de retirer puis de réintégrer le backend.

## 6. Nettoyage

L'exercice 3 doit être détruit **avant l'exercice 1**, car il dépend du réseau de
l'exercice 1.

Nettoyage du seul exercice 3 :

```bash
terraform -chdir=terraform/exercice-3 destroy
```

Pour la fermeture complète du lab, utiliser ensuite la procédure globale :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

L'ordre global est :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Le verdict final attendu après destruction de tout le lab est :

```text
NETTOYAGE AWS COMPLET
```

**Preuve à insérer :** destruction des ressources de l'exercice 3 et, pour la
fin du projet, résultat de l'audit AWS global.

## Données à ne pas publier

Avant la remise, retirer ou anonymiser :

- IP publiques complètes lorsqu'elles ne sont pas utiles ;
- clés SSH ;
- identifiants AWS ;
- inventaires réels ;
- `terraform.tfvars` et états Terraform ;
- journaux runtime non relus.

Les sorties automatisées restent localement sous
`proofs/runtime/exercice-3/` jusqu'à leur sélection et anonymisation.
