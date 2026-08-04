# Exercice 3 — HAProxy, disponibilité et performance

![Flux de l'exercice 3](../schemas/exercice-3.svg)

## Objectif officiel

Placer HAProxy devant deux instances de la même application, répartir les
requêtes, surveiller la santé des backends et vérifier la bascule lors d’une
panne.

## Option retenue : AWS

OpenClassrooms autorise une exécution locale ou Cloud. Pour cette réalisation,
le choix validé est **AWS** : une instance EC2 HAProxy répartit les requêtes
vers deux instances EC2 exécutant `nginxdemos/hello`. Le mode Docker Compose
local n’est pas implémenté dans ce dépôt.

## Dépendance du dépôt

Le module recherche le VPC, les sous-réseaux et la paire de clés créés pendant
l’exercice 1. Exécutez donc l’exercice 1 avant l’exercice 3. Cette dépendance
est un choix d’implémentation, pas une obligation OpenClassrooms.

## Étapes attendues

1. démarrer HAProxy et deux backends ;
2. configurer un backend `roundrobin` ;
3. ajouter les health checks ;
4. rafraîchir la page et observer l’alternance du serveur ;
5. arrêter un backend ;
6. vérifier que HAProxy l’exclut sans interrompre le service ;
7. redémarrer le backend et vérifier sa réintégration automatique.

## Configuration minimale

```text
frontend http-in
    bind *:80
    default_backend hello-servers

backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 ADRESSE_PRIVEE_1:80 check
    server hello-2 ADRESSE_PRIVEE_2:80 check
```

Le générateur facultatif crée un fichier complet sans secret :

```bash
./scripts/tools/generer-haproxy-config.sh \
  ADRESSE_PRIVEE_1 ADRESSE_PRIVEE_2 /tmp/haproxy.cfg
```

Validez ensuite la configuration sur le serveur :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

## Livrables et preuves

- `haproxy.cfg` avec deux backends et les health checks ;
- alternance visible entre les deux instances ;
- preuve avant, pendant et après l’arrêt d’un backend ;
- réintégration automatique du backend restauré ;
- validation de la configuration HAProxy ;
- aucune valeur sensible dans les fichiers ou captures.

Gabarit :
[`SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md`](../livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md).
