# Livrable 3 — HAProxy et `nginxdemos/hello`

> **Gabarit à compléter avec des preuves réelles.** Le round-robin, la panne et la reprise doivent être démontrés sur l'environnement AWS du projet.

## 1. Objectif

Démontrer qu'un load-balancer HAProxy répartit les requêtes entre deux backends, retire un backend défaillant sans interrompre le service puis le réintègre après restauration.

```text
              HAProxy
            /         \
           ▼           ▼
      p5-hello-1   p5-hello-2
```

## 2. Architecture

- mode : AWS ;
- réseau : VPC et subnets de l'exercice 1 ;
- load-balancer : une EC2 HAProxy ;
- backends : deux EC2 ;
- service backend : `nginxdemos/hello:plain-text` dans Docker ;
- algorithme : `roundrobin` ;
- santé : `GET /`, `fall 3`, `rise 2`.

L'exercice ne crée pas un second VPC.

## 3. Exécution de référence

```bash
bash scripts/commands/p5.sh ex3
```

La commande converge Terraform, attend HAProxy, vérifie le round-robin, prévisualise la panne, demande confirmation puis exécute la panne et la reprise réelles.

## 4. Preuve Terraform

À montrer :

```text
1 EC2 HAProxy
2 EC2 backends
Security Group HAProxy
Security Group backends
réutilisation du VPC exercice 1
```

Les outputs disponibles comprennent :

```text
hello_1_public_ip
hello_2_public_ip
hello_1_private_ip
hello_2_private_ip
haproxy_public_ip
haproxy_private_ip
haproxy_url
```

**Preuve Terraform/AWS réelle à insérer ici.**

## 5. Configuration `haproxy.cfg`

La configuration doit rendre visibles au minimum :

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

### Ce qu'il faut expliquer

- `roundrobin` distribue les requêtes entre les backends disponibles ;
- `httpchk GET /` contrôle le service HTTP ;
- `fall 3` évite de retirer un serveur après un seul échec transitoire ;
- `rise 2` exige plusieurs succès avant réintégration.

**Copie lisible/anonymisée de la configuration à insérer ici.**

## 6. Validation de la configuration

Sur l'EC2 HAProxy :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
```

**Preuve de syntaxe/service à insérer ici.**

## 7. Preuve du round-robin

Récupérer l'URL :

```bash
HAPROXY_URL="$(terraform -chdir=terraform/exercice-3 \
  output -raw haproxy_url)"
```

Puis :

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" \
  --requests 12
```

La sortie doit observer les deux identités de backend.

**Preuve round-robin à insérer ici.**

### Conclusion

Expliquer pourquoi deux noms de serveur distincts prouvent que les deux backends participent au pool.

## 8. Prévisualisation de la panne

Récupérer le backend ciblé :

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

Sans `--apply`, aucune panne réelle n'est exécutée.

## 9. Panne réelle et reprise

Après validation du scénario :

```bash
bash scripts/commands/test-haproxy-failover.sh \
  --url "$HAPROXY_URL" \
  --backend-host "$BACKEND_1" \
  --requests 6 \
  --apply
```

Le test doit montrer :

```text
AVANT
hello-1 + hello-2

PENDANT
hello-2 uniquement
HTTP toujours disponible

APRÈS
hello-1 + hello-2
```

Le script restaure le conteneur du backend après la mutation temporaire et attend sa réintégration.

## 10. Preuves du failover

### Avant panne

**Preuve montrant les deux backends à insérer ici.**

### Pendant panne

**Preuve montrant un seul backend et le maintien HTTP à insérer ici.**

### Après restauration

**Preuve montrant le retour des deux backends à insérer ici.**

## 11. Conclusion à rédiger

La conclusion doit expliquer :

- comment HAProxy distribue le trafic ;
- comment les health checks détectent la panne ;
- pourquoi les requêtes continuent à fonctionner ;
- comment le backend restauré revient dans la rotation.

Exemple de structure :

```text
Le backend 1 a été arrêté volontairement.
HAProxy l'a retiré après les échecs de health check.
Le backend 2 a continué à répondre, donc le service public est resté disponible.
Après redémarrage, HAProxy a validé les checks de reprise et a réintégré le backend 1.
```

## 12. Données à ne pas publier

Ne pas joindre :

- clé SSH ;
- state Terraform ;
- vrais `tfvars` ;
- inventaire réel ;
- token/session AWS ;
- logs bruts non relus.

Les IP peuvent être anonymisées dans la copie de `haproxy.cfg` si leur valeur exacte n'apporte rien à la preuve.

## 13. Nettoyage

L'exercice 3 doit être détruit **avant l'exercice 1**.

La fermeture globale utilise :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```
