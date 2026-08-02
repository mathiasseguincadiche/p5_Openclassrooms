# 🌐 Exercice 3 : HAPROXY (Load Balancer)

---

## 🎯 OBJECTIFS

**But principal** : Déployer un **load balancer HAProxy** devant les 2 VMs NGINX de l'Exercice 1.

**Compétences visées** :
- ✅ Maîtriser le Load Balancing.
- ✅ Comprendre le rôle d'un reverse proxy.
- ✅ Savoir répartir la charge entre plusieurs serveurs.
- ✅ Configurer la haute disponibilité.

**Résultat attendu** :
- ✅ 1 VM HAProxy déployée dans AWS.
- ✅ HAProxy configuré pour répartir le trafic vers les 2 VMs NGINX.
- ✅ Load balancing fonctionnel (répartition des requêtes).
- ✅ Tolérance aux pannes vérifiée.

---

## 🧠 CONCEPTS CLÉS À COMPRENDRE

### 🔹 1. Load Balancing

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Load Balancer** | Répartit le trafic entre plusieurs serveurs. | Évite la surcharge d'un seul serveur et améliore la disponibilité | Réceptionniste qui dirige les visiteurs |
| **Round Robin** | Algorithme de répartition simple (1 requête par serveur à tour de rôle). | Équilibre la charge de manière simple et efficace | Tour de rôle |
| **Health Check** | Vérification automatique de la santé des serveurs. | Permet de détecter les serveurs en panne et de les exclure | Contrôle de santé |
| **Reverse Proxy** | Serveur qui agit comme intermédiaire entre les clients et les serveurs backend. | Permet de masquer les serveurs backend et d'ajouter des fonctionnalités (SSL, cache, etc.) | Intermédiaire |

---

### 🔹 2. HAProxy

| Concept | Explication | Pourquoi c'est utile ? |
|---------|-------------|------------------------|
| **Frontend** | Définition des ports et adresses IP pour recevoir le trafic. | Permet de configurer comment HAProxy écoute | Porte d'entrée |
| **Backend** | Définition des serveurs vers lesquels le trafic est envoyé. | Permet de configurer les serveurs backend | Destination |
| **Server** | Définition d'un serveur backend. | Permet d'ajouter/supprimer des serveurs facilement | Serveur cible |
| **Balance Algorithm** | Algorithme de répartition de la charge. | Permet de choisir comment répartir le trafic | Stratégie de répartition |

---

## 🛠️ PRÉPARATION

### ✅ Prérequis pour l'Exercice 3

- Exercice 1 terminé avec succès (2 VMs NGINX déployées et accessibles).
- VM **vm-devops** accessible en SSH.
- Terraform, Ansible, AWS CLI installés et configurés.
- Pack P5 disponible dans `/home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/`.

---

### 📌 Commandes de vérification

```bash
# 1. Vérifiez que vous êtes sur la VM vm-devops
hostname
# → Doit afficher : vm-devops

# 2. Vérifiez que Terraform est installé
terraform -version
# → Doit afficher : Terraform v1.15.8 (ou supérieur)

# 3. Vérifiez que AWS CLI est configuré
aws sts get-caller-identity
# → Doit afficher votre UserId et Account

# 4. Vérifiez que les instances NGINX de l'Exercice 1 sont toujours en cours d'exécution
aws ec2 describe-instances --query "Reservations[].Instances[?Tags[?Key=='Project' && Value=='p5-openclassrooms']].[InstanceId, PublicIpAddress, PrivateIpAddress, State.Name]" --output table
# → Doit afficher les 2 instances NGINX avec leur IP privée (nécessaire pour HAProxy)
```

---

## 🚀 ÉTAPES D'EXÉCUTION

### Étape 1 : Récupérer les IPs privées des VMs NGINX

1. **Récupérer les IPs privées** (nécessaires pour la configuration HAProxy) :
   ```bash
   NGINX_1_PRIVATE_IP=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
   NGINX_2_PRIVATE_IP=$(aws ec2 describe-instances --query "Reservations[0].Instances[1].PrivateIpAddress" --output text)
   
   echo "NGINX-1 Private IP: $NGINX_1_PRIVATE_IP"
   echo "NGINX-2 Private IP: $NGINX_2_PRIVATE_IP"
   ```
   **Notez ces IPs privées** pour l'étape suivante.

---

### Étape 2 : Générer la configuration HAProxy

1. **Créer un script pour générer la configuration** (`generer-haproxy-config.sh`) :
   ```bash
   nano generer-haproxy-config.sh
   ```
   **Contenu** :
   ```bash
   #!/bin/bash
   
   NGINX_1_IP=$1
   NGINX_2_IP=$2
   
   cat > haproxy.cfg <<EOF
   frontend http-in
       bind *:80
       default_backend ngx_servers
   
   backend ngx_servers
       balance roundrobin
       server ngx1 ${NGINX_1_IP}:80 check
       server ngx2 ${NGINX_2_IP}:80 check
   
   listen stats
       bind *:8404
       stats enable
       stats uri /stats
       stats refresh 10s
       stats admin if TRUE
   EOF
   
   echo "Configuration HAProxy générée dans haproxy.cfg"
   ```

2. **Rendre le script exécutable** :
   ```bash
   chmod +x generer-haproxy-config.sh
   ```

3. **Générer la configuration** :
   ```bash
   ./generer-haproxy-config.sh $NGINX_1_PRIVATE_IP $NGINX_2_PRIVATE_IP
   ```

4. **Vérifier le fichier généré** :
   ```bash
   cat haproxy.cfg
   ```
   **Résultat attendu** :
   ```cfg
   frontend http-in
       bind *:80
       default_backend ngx_servers
   
   backend ngx_servers
       balance roundrobin
       server ngx1 10.0.1.123:80 check
       server ngx2 10.0.2.45:80 check
   
   listen stats
       bind *:8404
       stats enable
       stats uri /stats
       stats refresh 10s
       stats admin if TRUE
   ```

---

### Étape 3 : Déployer la VM HAProxy avec Terraform

1. **Aller dans le dossier de l'Exercice 3** :
   ```bash
   cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/03_HAPROXY/
   ```

2. **Initialiser Terraform** :
   ```bash
   terraform init
   ```

3. **Vérifier le plan** :
   ```bash
   terraform plan
   ```
   **Ce que vous devriez voir** :
   - Création d'une **VM EC2** pour HAProxy.
   - Création d'un **Security Group** pour HAProxy.
   - Message : `Plan: X to add, 0 to change, 0 to destroy.`

4. **Appliquer le plan** :
   ```bash
   terraform apply -auto-approve
   ```
   **Résultat attendu** :
   ```
   Apply complete! Resources: X added, 0 changed, 0 destroyed.
   ```

5. **Récupérer l'IP publique de HAProxy** :
   ```bash
   HAPROXY_IP=$(terraform output -raw haproxy_public_ip)
   echo "HAProxy Public IP: $HAPROXY_IP"
   ```

---

### Étape 4 : Installer et configurer HAProxy

1. **Se connecter à la VM HAProxy** :
   ```bash
   ssh -i p5-key.pem ubuntu@$HAPROXY_IP
   ```

2. **Installer HAProxy** :
   ```bash
   sudo apt update
   sudo apt install -y haproxy
   ```

3. **Copier la configuration HAProxy** :
   ```bash
   # Depuis votre VM vm-devops, copiez le fichier haproxy.cfg généré précédemment
   scp -i p5-key.pem haproxy.cfg ubuntu@$HAPROXY_IP:/tmp/
   
   # Sur la VM HAProxy, déployez la configuration
   sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
   sudo chmod 644 /etc/haproxy/haproxy.cfg
   ```

4. **Tester la configuration HAProxy** :
   ```bash
   sudo haproxy -c -f /etc/haproxy/haproxy.cfg
   ```
   **Résultat attendu** :
   ```
   Configuration file is valid
   ```

5. **Démarrer HAProxy** :
   ```bash
   sudo systemctl start haproxy
   sudo systemctl enable haproxy
   ```

6. **Vérifier que HAProxy est démarré** :
   ```bash
   sudo systemctl status haproxy
   ```
   **Résultat attendu** :
   ```
   ● haproxy.service - HAProxy Load Balancer
      Loaded: loaded (/lib/systemd/system/haproxy.service; enabled; vendor preset: enabled)
      Active: active (running) since Mon 2026-08-02 12:00:00 UTC; 5min ago
   ```

---

### Étape 5 : Tester le Load Balancing

1. **Tester l'accès via HAProxy** :
   ```bash
   curl http://$HAPROXY_IP
   ```
   **Résultat attendu** :
   ```html
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   ...
   <body>
   <h1>Welcome to nginx!</h1>
   ...
   </body>
   </html>
   ```

2. **Tester la répartition de charge** :
   ```bash
   for i in {1..5}; do curl -s http://$HAPROXY_IP | grep -o "Welcome to nginx from [^<]*"; echo "---"; done
   ```
   **Résultat attendu** :
   ```
   Welcome to nginx from 10.0.1.123
   ---
   Welcome to nginx from 10.0.2.45
   ---
   Welcome to nginx from 10.0.1.123
   ---
   Welcome to nginx from 10.0.2.45
   ---
   Welcome to nginx from 10.0.1.123
   ```
   **Explication** : Les requêtes sont alternées entre NGINX-1 et NGINX-2 (algorithme **Round Robin**).

3. **Vérifier les statistiques HAProxy** :
   ```bash
   curl http://$HAPROXY_IP:8404/stats
   ```
   **Résultat attendu** :
   - Page HTML avec les statistiques de HAProxy.
   - Les deux serveurs backend (NGINX-1 et NGINX-2) doivent être **UP**.

---

### Étape 6 : Tester la tolérance aux pannes

1. **Arrêter une VM NGINX** (ex: NGINX-1) :
   ```bash
   # Récupérer l'ID de l'instance NGINX-1
   NGINX_1_ID=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].InstanceId" --output text)
   
   # Arrêter l'instance
   aws ec2 stop-instances --instance-ids $NGINX_1_ID
   ```

2. **Attendre que l'instance soit arrêtée** :
   ```bash
   aws ec2 describe-instances --instance-ids $NGINX_1_ID --query "Reservations[0].Instances[0].State.Name" --output text
   # → Doit afficher : stopped
   ```

3. **Tester l'accès via HAProxy** :
   ```bash
   curl http://$HAPROXY_IP
   ```
   **Résultat attendu** :
   - La page web doit **toujours s'afficher** (servie par NGINX-2).
   - HAProxy a automatiquement détecté que NGINX-1 est **DOWN** et envoie tout le trafic vers NGINX-2.

4. **Vérifier les statistiques HAProxy** :
   ```bash
   curl http://$HAPROXY_IP:8404/stats
   ```
   **Résultat attendu** :
   - NGINX-1 doit être marqué comme **DOWN**.
   - NGINX-2 doit être marqué comme **UP**.

5. **Redémarrer NGINX-1** :
   ```bash
   aws ec2 start-instances --instance-ids $NGINX_1_ID
   ```

6. **Vérifier que le load balancing fonctionne à nouveau** :
   ```bash
   for i in {1..5}; do curl -s http://$HAPROXY_IP | grep -o "Welcome to nginx from [^<]*"; echo "---"; done
   ```
   **Résultat attendu** :
   - Les requêtes doivent à nouveau être réparties entre NGINX-1 et NGINX-2.

---

## ✅ VÉRIFICATIONS

### Checklist de Vérification

- [ ] **Préparation** :
  - [ ] IPs privées des VMs NGINX récupérées
  - [ ] Configuration HAProxy générée

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès
  - [ ] `terraform plan` affiche la création de la VM HAProxy
  - [ ] `terraform apply` crée la VM avec succès
  - [ ] IP publique de HAProxy récupérée

- [ ] **HAProxy** :
  - [ ] HAProxy installé sur la VM
  - [ ] Configuration HAProxy déployée
  - [ ] Service HAProxy démarré
  - [ ] Accès via HAProxy fonctionne

- [ ] **Load Balancing** :
  - [ ] Répartition de charge vérifiée (Round Robin)
  - [ ] Statistiques HAProxy accessibles
  - [ ] Tolérance aux pannes testée

---

## 🛠️ DÉPANNAGE

### Problèmes Courants et Solutions

#### 1. Erreur : "Configuration file is invalid" (HAProxy)
**Symptômes** :
```
[ALERT] 084/120000 (1234) : parsing [/etc/haproxy/haproxy.cfg:5] : 'bind' expects <address>:<port_range>.
```
**Solutions** :
1. Vérifiez la syntaxe du fichier `haproxy.cfg` :
   ```bash
   sudo haproxy -c -f /etc/haproxy/haproxy.cfg
   ```
2. Vérifiez que les IPs des serveurs backend sont correctes.
3. Vérifiez que les ports sont corrects (80 pour NGINX, 8404 pour les stats).

---

#### 2. Erreur : "Connection refused" (HAProxy)
**Symptômes** :
```
curl: (7) Failed to connect to 54.200.100.50 port 80: Connection refused
```
**Solutions** :
1. Vérifiez que HAProxy est démarré :
   ```bash
   sudo systemctl status haproxy
   ```
2. Vérifiez que HAProxy écoute sur le port 80 :
   ```bash
   sudo netstat -tulnp | grep haproxy
   ```
3. Vérifiez que le Security Group autorise le port 80 :
   ```bash
   aws ec2 describe-security-groups --group-ids $(aws ec2 describe-instances --instance-ids $HAPROXY_ID --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text)
   ```

---

#### 3. Erreur : "No server is available to handle this request" (HAProxy)
**Symptômes** :
```
503 Service Unavailable
No server is available to handle this request.
```
**Solutions** :
1. Vérifiez que les VMs NGINX sont en cours d'exécution :
   ```bash
   aws ec2 describe-instances --query "Reservations[].Instances[?Tags[?Key=='Project' && Value=='p5-openclassrooms']].[InstanceId, State.Name]" --output table
   ```
2. Vérifiez que NGINX est démarré sur les VMs :
   ```bash
   ansible all -i hosts_aws -a "systemctl status nginx"
   ```
3. Vérifiez que les IPs privées dans `haproxy.cfg` sont correctes.
4. Vérifiez que HAProxy peut se connecter aux VMs NGINX :
   ```bash
   # Depuis la VM HAProxy
   nc -zv 10.0.1.123 80
   nc -zv 10.0.2.45 80
   ```

---

#### 4. Erreur : "All servers are DOWN" (Statistiques HAProxy)
**Symptômes** :
- Dans les statistiques HAProxy (`http://$HAPROXY_IP:8404/stats`), les deux serveurs backend sont marqués comme **DOWN**.

**Solutions** :
1. Vérifiez que les VMs NGINX sont accessibles depuis HAProxy :
   ```bash
   # Depuis la VM HAProxy
   curl http://10.0.1.123:80
   curl http://10.0.2.45:80
   ```
2. Vérifiez que le Security Group de HAProxy autorise le trafic **sortant** vers les VMs NGINX.
3. Vérifiez que le Security Group des VMs NGINX autorise le trafic **entrant** depuis HAProxy (port 80).

---

## 📚 RESSOURCES UTILES

- [Documentation HAProxy](https://www.haproxy.org/documentation/)
- [Documentation Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Guide Load Balancing avec HAProxy](https://www.haproxy.com/blog/haproxy-load-balancing-guide/)

---

## 🎯 RÉSUMÉ

✅ **Configuration HAProxy générée** avec les IPs des VMs NGINX
✅ **VM HAProxy déployée** avec Terraform
✅ **HAProxy installé et configuré**
✅ **Load balancing fonctionnel** (Round Robin)
✅ **Statistiques HAProxy accessibles**
✅ **Tolérance aux pannes testée**

**Exercice 3 terminé avec succès !** 🎉

---

## 🧹 NETTOYAGE (À FAIRE À LA FIN)

Pour éviter des coûts inutiles, **supprimez toutes les ressources AWS** après avoir terminé le projet :

```bash
# Exercice 1 : Supprimer les VMs NGINX
cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/01_TERRAFORM_ANSIBLE/
terraform destroy -auto-approve

# Exercice 2 : Supprimer le cluster OpenSearch
cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/02_OPENSEARCH/
terraform destroy -auto-approve

# Exercice 3 : Supprimer la VM HAProxy
cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/03_HAPROXY/
terraform destroy -auto-approve
```

**⚠️ Important** : Vérifiez qu'il n'y a plus de ressources en cours d'exécution :
```bash
aws ec2 describe-instances --query "Reservations[].Instances[?State.Name=='running'].InstanceId" --output text
aws es list-domain-names
```

---

**Projet P5 terminé avec succès !** 🎉
