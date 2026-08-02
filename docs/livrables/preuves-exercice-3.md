# Preuves Exercice 3 : HAProxy (Load Balancer)

---

## 📌 Contexte
**But** : Déployer un **load balancer HAProxy** devant les 2 VMs NGINX de l'Exercice 1.
**Outils utilisés** : Terraform, HAProxy, AWS CLI.

---

## 🔹 1. Configuration HAProxy

### Génération du fichier `haproxy.cfg`
**Commande** : `./generer-haproxy-config.sh $NGINX_IP1 $NGINX_IP2`

**Fichier généré** :
```cfg
frontend http-in
    bind *:80
    default_backend ngx_servers

backend ngx_servers
    balance roundrobin
    server ngx1 54.123.45.67:80 check
    server ngx2 54.123.45.68:80 check
```

---

## 🔹 2. Déploiement de la VM HAProxy

### Plan Terraform
**Commande** : `terraform plan`

**Résultat** : [Copier-coller la sortie complète ici]

---

### Application Terraform
**Commande** : `terraform apply -auto-approve`

**Résultat** : [Copier-coller la sortie complète ici]

---

## 🔹 3. Installation et configuration de HAProxy

**Commande** : `sudo systemctl status haproxy`

**Résultat** : [Copier-coller la sortie ici]

---

## 🔹 4. Test du load balancing

**Commande** : `for i in {1..5}; do curl -s http://54.200.100.50 | grep -o "Welcome to nginx from [^<]*"; echo "---"; done`

**Résultat** : [Copier-coller la sortie ici]

---

## ✅ Checklist de Vérification

- [ ] Configuration HAProxy générée
- [ ] VM HAProxy déployée avec Terraform
- [ ] HAProxy installé et configuré
- [ ] Service HAProxy démarré
- [ ] Load balancing fonctionnel (répartition entre NGINX-1 et NGINX-2)
- [ ] Statistiques HAProxy accessibles (port 8404)

---

**Conseil** : 
- Vérifiez que les deux serveurs NGINX sont bien **UP** dans les statistiques HAProxy.
- Testez la tolérance aux pannes en arrêtant une VM NGINX.
