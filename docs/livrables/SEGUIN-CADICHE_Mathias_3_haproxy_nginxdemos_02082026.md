# Livrable 3 — HAProxy et `nginxdemos/hello`

> **État vérifié le 23 août 2026.** Le round-robin, la panne contrôlée et la réintégration ont été rejoués sur l'environnement AWS réel. Les adresses publiques ne sont pas reproduites ici lorsqu'elles ne sont pas nécessaires à l'explication.

## 1. Objectif

Démontrer qu'un load-balancer HAProxy répartit les requêtes entre deux backends, détecte la défaillance d'un backend grâce à ses health checks, le retire de la rotation puis le réintègre après restauration.

```text
              HAProxy
            /         \
           ▼           ▼
      p5-hello-1   p5-hello-2
```

## 2. Architecture

- mode : AWS ;
- réseau : VPC et subnets réutilisés depuis l'exercice 1 ;
- load-balancer : une EC2 HAProxy ;
- backends : deux EC2 Ubuntu ;
- service backend : `nginxdemos/hello:0.4-plain-text` dans Docker ;
- configuration canonique : `terraform/exercice-3/haproxy.cfg.tpl` ;
- algorithme : `roundrobin` ;
- health check : `GET /`, réponse attendue HTTP 200 ;
- retrait : `fall 3` ;
- réintégration : `rise 2`.

L'exercice ne crée pas un second VPC. Les règles réseau des backends autorisent HTTP depuis le Security Group HAProxy, tandis que SSH reste limité à la source d'administration `/32`.

## 3. Exécution de référence

```bash
bash scripts/commands/p5.sh ex3
```

Run final retenu : `20260823T052610Z`.

```text
validated_steps=12
failed_steps=0
result=OK
```

Ce run a recalculé le delta Terraform, remplacé uniquement l'instance HAProxy concernée par la correction de bootstrap, revérifié le post-plan, attendu la disponibilité HTTP, testé le round-robin puis exécuté la panne et la reprise réelles d'un backend.

## 4. Preuve Terraform

Le premier déploiement de l'exercice 3 avait créé :

```text
1 EC2 HAProxy
2 EC2 backends
1 Security Group HAProxy
1 Security Group backends
```

Le plan initial était :

```text
Plan: 5 to add, 0 to change, 0 to destroy.
```

et l'apply réel avait terminé par :

```text
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

Après identification d'un défaut de bootstrap HAProxy, la configuration Terraform a été corrigée pour forcer le chargement de la configuration validée au démarrage. Le plan final a alors ciblé **uniquement HAProxy** :

```text
aws_instance.p5_haproxy must be replaced
Plan: 1 to add, 0 to change, 1 to destroy.
```

L'apply correspondant a confirmé :

```text
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

Les deux EC2 backends et les deux Security Groups ont donc été conservés. Le post-plan final a ensuite retourné :

```text
No changes. Your infrastructure matches the configuration.
```

L'audit AWS de fin de run a confirmé trois instances actives :

```text
EC2 HAProxy          : running
EC2 backend hello-1 : running
EC2 backend hello-2 : running

Verdict : ÉTAT AWS EXERCICE 3 VALIDÉ — 3 EC2 RUNNING
```

Traces techniques privées :

```text
proofs/runtime/steps/20260823T052610Z/03-tf-ex3-show.log
proofs/runtime/steps/20260823T052610Z/05-tf-ex3-apply.log
proofs/runtime/steps/20260823T052610Z/07-tf-ex3-post-plan.log
proofs/runtime/exercice-3/20260823T052913Z-etat-aws-exercice-3.log
```

## 5. Configuration `haproxy.cfg`

La configuration effective est rendue à partir du template versionné avec les IP privées réelles des deux backends. Présentation anonymisée :

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

Interprétation :

- `bind *:80` expose le frontend HTTP de HAProxy ;
- `roundrobin` répartit les requêtes entre les serveurs actuellement disponibles ;
- `httpchk GET /` teste réellement le service HTTP, et pas seulement l'état de l'EC2 ;
- `http-check expect status 200` exige une réponse saine ;
- `inter 3s` fixe la fréquence des contrôles ;
- `fall 3` demande trois échecs avant de considérer un serveur indisponible ;
- `rise 2` demande deux succès avant de réintégrer un serveur restauré.

L'utilisation des IP privées maintient le trafic backend à l'intérieur du VPC.

## 6. Validation de la configuration

Le diagnostic exécuté sur l'EC2 HAProxy a vérifié la configuration avec :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Résultat :

```text
Configuration file is valid
```

Le fichier vérifié contenait bien :

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
server hello-1 <IP_PRIVEE_1>:80 check inter 3s fall 3 rise 2
server hello-2 <IP_PRIVEE_2>:80 check inter 3s fall 3 rise 2
```

Après la correction du bootstrap, le run final a attendu que l'URL HAProxy soit réellement accessible avant de poursuivre les tests fonctionnels. Le succès du round-robin et du failover confirme que le service actif utilisait la configuration attendue.

## 7. Preuve du round-robin

Commande :

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 output -raw haproxy_url)"
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

Résultat réel du run final :

```text
01  p5-hello-2
02  p5-hello-1
03  p5-hello-2
04  p5-hello-1
05  p5-hello-2
06  p5-hello-1
07  p5-hello-2
08  p5-hello-1
09  p5-hello-2
10  p5-hello-1
11  p5-hello-2
12  p5-hello-1

OK  2 backends distincts observés
Verdict : ROUND-ROBIN OPÉRATIONNEL
```

Trace :

```text
proofs/runtime/steps/20260823T052610Z/10-haproxy-roundrobin.log
```

### Conclusion

Deux identités de serveur distinctes apparaissent de manière alternée. Les réponses traversent donc bien HAProxy et sont distribuées vers les deux membres du pool ; il ne s'agit pas d'un accès direct à un backend unique.

## 8. Prévisualisation de la panne

Avant toute mutation, le scénario a été lancé sans `--apply` :

```bash
BACKEND_1="$(terraform -chdir=terraform/exercice-3 output -raw hello_1_public_ip)"
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1"
```

La prévisualisation a observé les deux backends et s'est terminée sans arrêter de conteneur :

```text
Phase : avant la panne
OK  2 backend(s) distinct(s)
Simulation terminée. Relancez avec --apply pour arrêter le conteneur.
```

Cette étape constitue un garde-fou : la cible et le comportement nominal sont vérifiés avant la mutation temporaire.

## 9. Panne réelle et reprise

Le test réel a ensuite été explicitement confirmé et exécuté :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1" \
  --apply
```

Résultat observé :

```text
AVANT LA PANNE
p5-hello-2
p5-hello-1
p5-hello-2
p5-hello-1
p5-hello-2
p5-hello-1
OK  2 backends distincts

ARRÊT DU BACKEND 1
le conteneur nginx-hello est arrêté volontairement

PENDANT LA PANNE, APRÈS CONVERGENCE DES HEALTH CHECKS
p5-hello-2
p5-hello-2
p5-hello-2
p5-hello-2
p5-hello-2
p5-hello-2
OK  1 backend distinct

RESTAURATION
le conteneur nginx-hello du backend 1 est redémarré

APRÈS LA REPRISE
p5-hello-2
p5-hello-1
p5-hello-2
p5-hello-1
p5-hello-2
p5-hello-1
OK  2 backends distincts
```

Le test a produit le verdict :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

### À propos des deux réponses 503 transitoires

Deux tentatives HTTP ont reçu un `503` immédiatement après l'arrêt du backend 1, pendant la courte fenêtre où HAProxy n'avait pas encore cumulé les trois échecs requis par `fall 3`. Ce comportement est cohérent avec la configuration choisie : le serveur n'est marqué `DOWN` qu'après le seuil de détection. Une fois ce seuil atteint, toutes les requêtes de la phase de panne ont été servies par `p5-hello-2`.

Cette observation est conservée dans le livrable parce qu'elle décrit le comportement réel du health check au lieu de masquer une transition transitoire.

## 10. Preuves du failover

### Avant panne

Les six requêtes de contrôle ont observé `p5-hello-1` et `p5-hello-2`. Le pool était donc entièrement opérationnel.

### Pendant panne

Après convergence des health checks, six requêtes consécutives ont toutes été servies par `p5-hello-2`. HAProxy avait donc retiré le backend arrêté de la rotation.

### Après restauration

Après redémarrage du conteneur, les réponses ont de nouveau alterné entre `p5-hello-1` et `p5-hello-2`. Le backend restauré a bien satisfait les checks `rise 2` et a été automatiquement réintégré.

Trace de référence :

```text
proofs/runtime/steps/20260823T052610Z/12-haproxy-failover.log
proofs/runtime/exercice-3/20260823T052840Z-failover-backend-1.log
```

## 11. Conclusion à rédiger

L'exercice démontre trois propriétés distinctes. Premièrement, HAProxy distribue réellement le trafic entre deux backends avec `roundrobin`. Deuxièmement, les health checks détectent l'arrêt volontaire d'un service et retirent ce serveur de la rotation après le seuil `fall 3`, ce qui permet au backend sain de prendre seul la charge. Troisièmement, après restauration, HAProxy attend les succès `rise 2` puis réintègre automatiquement le serveur dans le pool.

La fenêtre transitoire observée juste après l'arrêt rappelle qu'un mécanisme de health check possède un temps de détection configurable. Elle ne remet pas en cause le failover validé ; elle permet au contraire d'expliquer précisément l'effet des paramètres `inter`, `fall` et `rise`.

## 12. Données à ne pas publier

Restent hors du livrable public :

- clé SSH privée ;
- state Terraform ;
- vrais `tfvars` ;
- inventaire réel complet ;
- token ou session AWS ;
- logs runtime bruts non relus ;
- adresses publiques exactes lorsqu'elles n'apportent rien à la démonstration.

Les IP privées sont anonymisées dans l'extrait de configuration présenté ci-dessus.

## 13. Nettoyage

L'exercice 3 réutilise le réseau de l'exercice 1 et doit donc être détruit en premier lors de la fermeture du lab.

Commande orchestrée :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre de destruction et de vérification :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict attendu après fermeture complète :

```text
NETTOYAGE AWS COMPLET
```
