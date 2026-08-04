# Livrable 3 — HAProxy et `nginxdemos/hello`

> **Gabarit à compléter.** Les tests de répartition, de panne et de reprise
> doivent être exécutés réellement.

## 1. Architecture

- un serveur HAProxy ;
- deux backends `nginxdemos/hello` ;
- algorithme `roundrobin` ;
- health checks HTTP ;
- mode du dépôt : AWS avec Terraform.

## 2. Fichier `haproxy.cfg`

Le fichier généré doit contenir au minimum :

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

Génération pour le déploiement :

```bash
./scripts/tools/generer-haproxy-config.sh \
  ADRESSE_PRIVEE_1 ADRESSE_PRIVEE_2 /tmp/haproxy.cfg
```

**À joindre :** une copie lisible de `haproxy.cfg`, sans donnée sensible.

## 3. Validation de la configuration

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

**Preuve réelle à insérer.**

## 4. Répartition de charge

```bash
for _ in {1..10}; do
  curl --fail --silent http://ADRESSE_HAPROXY
  printf '\n'
done
```

**Preuve à insérer :** alternance visible des noms ou adresses de serveur.

## 5. Panne et continuité de service

1. arrêter le premier backend ;
2. répéter les requêtes via HAProxy ;
3. vérifier que le second backend répond seul ;
4. redémarrer le premier backend ;
5. vérifier son retour automatique dans la rotation.

**Preuves à insérer :** état avant la panne, pendant la panne et après la
reprise.

## 6. Nettoyage

```bash
terraform -chdir=terraform/exercice-3 destroy
```

**Preuve à insérer :** trois instances et groupes de sécurité supprimés.
