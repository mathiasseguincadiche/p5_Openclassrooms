# Exercice 3 — HAProxy, disponibilité et performance

![Flux de l'exercice 3](../schemas/exercice-3.svg)

## Objectif officiel

Placer HAProxy devant deux instances de la même application, répartir les
requêtes, surveiller la santé des backends et vérifier la bascule lors d’une
panne.

## Implémentation retenue

Le module AWS déploie une instance HAProxy et deux instances EC2 exécutant
`nginxdemos/hello:plain-text`. Les conteneurs portent les noms déterministes
`p5-hello-1` et `p5-hello-2`, ce qui rend les preuves lisibles.

L’exercice 3 réutilise le VPC, les sous-réseaux publics et la paire de clés de
l’exercice 1. L’exercice 1 doit donc rester déployé jusqu’à la fin de cette
démonstration.

## 1. Contrôler puis déployer

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-3

cp terraform/exercice-3/terraform.tfvars.example \
  terraform/exercice-3/terraform.tfvars
$EDITOR terraform/exercice-3/terraform.tfvars

terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 validate
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 show tfplan
terraform -chdir=terraform/exercice-3 apply tfplan
```

Terraform expose notamment `haproxy_url`, les adresses publiques des backends et
leurs adresses privées.

## 2. Valider la configuration HAProxy

La configuration utilise :

```text
backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 ADRESSE_PRIVEE_1:80 check inter 3s fall 3 rise 2
    server hello-2 ADRESSE_PRIVEE_2:80 check inter 3s fall 3 rise 2
```

Le générateur local permet de vérifier le format sans toucher à AWS :

```bash
./scripts/tools/generer-haproxy-config.sh \
  10.0.1.10 10.0.2.10 /tmp/haproxy.cfg

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

## 3. Tester le round-robin

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 10
```

Le script interroge l’URL Terraform, extrait le champ `Server name` et exige au
moins deux backends distincts. La sortie est enregistrée sous
`proofs/runtime/exercice-3/`.

Le verdict attendu est :

```text
ROUND-ROBIN OPÉRATIONNEL
```

## 4. Prévisualiser le test de panne

```bash
./scripts/commands/test-haproxy-failover.sh
```

Sans `--apply`, le script vérifie uniquement l’état initial des deux backends et
affiche le scénario. Aucun conteneur n’est arrêté.

## 5. Exécuter la panne et la reprise

```bash
./scripts/commands/test-haproxy-failover.sh \
  --backend 1 \
  --requests 6 \
  --apply
```

Le test réalise les phases suivantes :

1. confirme que les deux backends répondent ;
2. arrête `nginx-hello` sur le backend choisi par SSH ;
3. attend la détection du health check ;
4. confirme qu’un seul backend répond sans interruption ;
5. redémarre le conteneur ;
6. confirme le retour des deux backends dans la rotation.

Un piège de sortie tente toujours de redémarrer le conteneur si le script est
interrompu après l’arrêt.

Le verdict attendu est :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## Preuves attendues

- plan et application Terraform ;
- trois instances EC2 actives ;
- copie anonymisée de `haproxy.cfg` ;
- validation `haproxy -c` ;
- sortie du round-robin avec deux noms de serveur ;
- sortie avant, pendant et après la panne ;
- continuité du service pendant l’arrêt ;
- réintégration automatique du backend ;
- aucune clé SSH, IP sensible complète ou variable locale versionnée.

Gabarit :
[`SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md`](../livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md).

## Nettoyage final

Détruire d’abord l’exercice 3, puis l’exercice 2 et enfin l’exercice 1 :

```bash
terraform -chdir=terraform/exercice-3 destroy
terraform -chdir=terraform/exercice-2 destroy
terraform -chdir=terraform/exercice-1 destroy
./scripts/commands/check-aws-cleanup.sh
```
