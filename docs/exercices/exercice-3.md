# Exercice 3 : HAPROXY + NGINXDEMOS/HELLO (Aligné 100% avec OpenClassrooms)

---

## 📌 **OBJECTIFS (Conforme aux consignes OpenClassrooms)**

**But principal** : Dépllloyer un **load balancer HAProxy** devant **2 instances de l'application `nginxdemos/hello`**.

**Compétences visées** :
- ✅ Maîtriser le **Load Balancing** avec HAProxy.
- ✅ Comprendre le rôle d'un **reverse proxy**.
- ✅ Déplllloyer des **l'application** (`nginxdemos/hello`).
- ✅ Configurer HAProxy pour répartir la charge entre plusieurs conteneurs.
- ✅ Vérifier l'**alternance des requêtes** (Server name change à chaque rafraîchissement).

**Résultat attendu** (selon OpenClassrooms) :
- ✅ **1 VM HAProxy déployée** dans AWS .
- ✅ **2 instances de `nginxdemos/hello`** (Docker) déployées.
- ✅ **HAProxy configuré** pour répartir la charge entre les 2 instances.
- ✅ **Vérification de l'alternance** : À chaque rafraîchissement, le **Server name** change (ex : `faf376c0f0b1`).
- ✅ **Fichier `haproxy.cfg`** livré (conforme aux consignes).

---

## 📚 **CONCEPTS CLÉS À COMPRENDRE**

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

---

### 🔹 4. Architecture de l'Exercice 3

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                                                                               │
│   ┌─────────────┐                                                               │
│   │   Client    │                                                               │
│   └──────┬──────┘                                                               │
│          │                                                                       │
│          ▼                                                                       │
│   ┌─────────────┐                                                               │
│   │  HAProxy    │  (Load Balancer - Port 80)                                    │
│   │  (VM ou    │                                                               │
│   │  Conteneur) │                                                               │
│   └──────┬──────┘                                                               │
│          │                                                                       │
│          ├───► ┌─────────────┐                                                   │
│          │    │ nginxdemos/ │  (Server name: faf376c0f0b1)                         │
│          │    │   hello     │  (Port 80)                                         │
│          │    └─────────────┘                                                   │
│          │                                                                       │
│          └───► ┌─────────────┐                                                   │
│               │ nginxdemos/ │  (Server name: 3a8f2b1c4d5e)                         │
│               │   hello     │  (Port 80)                                         │
│               └─────────────┘                                                   │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ **PRÉPARATION**

### ✅ **Prérequis pour l'Exercice 3**

#### **Option 1 : Mode Cloud (AWS)**
- Exercice 1 terminé avec succès (2 VMs déployées, **mais pas NGINX standard** → voir [corrections](#)).
- VM **vm-devops** accessible en SSH.
- Terraform, Ansible, AWS CLI installés et configurés.
- **Docker installé** sur les VMs backend.
- Pack P5 disponible dans `/home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/`.

---

### 🔍 **Commandes de vérification**

```bash
# 1. Vérifiez que vous êtes sur la VM vm-devops (si AWS)
hostname
# ✅ Doit afficher : vm-devops

# 2. Vérifiez que Terraform est installé
terraform -version
# ✅ Doit afficher : Terraform v1.15.8 (ou supérieur)

# 3. Vérifiez que AWS CLI est configuré (si AWS)
aws sts get-caller-identity
# ✅ Doit afficher votre UserId et Account

# 4. Vérifiez que Docker est installé
# ✅ Doit afficher : Docker version 20.x.x

# 5. Vérifiez que docker-compose est installé (si local)
# ✅ Doit afficher : docker-compose version 1.x.x
```

---

## 🚀 **ÉTAPES D'EXÉCUTION**

---

### ✅ **Étape 0 : Choisir le mode (AWS ou Local)**

#### **Option 1 : Mode AWS (Recommandé pour OpenClassrooms)**
- Dépllloiement sur **AWS avec Terraform**.
- **2 VMs backend** avec `nginxdemos/hello`.
- **1 VM HAProxy** pour le load balancing.

---

### ✅ **Étape 1 : Dépllloyer les 2 instances `nginxdemos/hello` (AWS)**

> **⚠️ Correction par rapport à l'Exercice 1 : On utilise `nginxdemos/hello` au lieu de NGINX standard.**

1. **Aller dans le dossier de l'Exercice 3** :
   ```bash
   cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/03_HAPROXY/
   ```

2. **Modifier le fichier `main.tf`** pour déployer **2 VMs avec `nginxdemos/hello`** :
   ```bash
   nano terraform/exercice-3/main.tf
   ```
   **Contenu à ajouter/modifier** (extrait) :
   ```hcl
   # Créer 2 VMs pour nginxdemos/hello
   resource "aws_instance" "nginx_hello" {
     count         = 2
     ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 LTS (Free Tier)
     instance_type = "t2.micro"
     subnet_id     = aws_subnet.p5_public_subnet_a.id
     
     # Clé SSH
     key_name = "p5-key"
     
     # Security Group (autorise HTTP et SSH)
     vpc_security_group_ids = [aws_security_group.p5_nginx_sg.id]
     
     # Tags
     tags = {
       Name    = "p5-nginx-hello-${count.index}"
       Project = "p5-openclassrooms"
     }
     
     # User Data : Installer et lancer nginxdemos/hello
     user_data = <<-EOF
               #!/bin/bash
               sudo apt update -y
               sudo apt install -y docker.io
               sudo systemctl start docker
               sudo systemctl enable docker
               sudo usermod -aG docker ubuntu
               sudo docker run -d --name nginx-hello -p 80:80 nginxdemos/hello
               EOF
   }
   ```

3. **Appliquer Terraform** :
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

4. **Vérifier que les conteneurs sont en cours d'exécution** :
   ```bash
   # Récupérer les IPs privées des VMs
   NGINX_HELLO_1_IP=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
   NGINX_HELLO_2_IP=$(aws ec2 describe-instances --query "Reservations[0].Instances[1].PrivateIpAddress" --output text)
   
   # Se connecter à la première VM et vérifier l'application
   ssh -i p5-key.pem ubuntu@$(aws ec2 describe-instances --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
   docker ps
   ```
   **Résultat attendu** :
   ```
   CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                  NAMES
   abc123def456   nginxdemos/hello      "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp,:::80->80/tcp   nginx-hello
   ```

5. **Tester l'accès aux instances `nginxdemos/hello`** :
   ```bash
   # Depuis la VM vm-devops, tester via les IPs privées
   curl http://$NGINX_HELLO_1_IP
   curl http://$NGINX_HELLO_2_IP
   ```
   **Résultat attendu** :
   ```html
   <!DOCTYPE html>
   <html>
   <head>
   <title>Hello from NGINX!</title>
   <style>
       body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
       h1 { color: #0078d7; }
   </style>
   </head>
   <body>
   <h1>Hello from NGINX!</h1>
   <p>Server name: <strong>faf376c0f0b1</strong></p>
   <p>Server address: 10.0.1.123:80</p>
   </body>
   </html>
   ```
   **✅ Notez les `Server name`** (ex : `faf376c0f0b1` et `3a8f2b1c4d5e`).

---

### ✅ **Étape 2 : Générer la configuration HAProxy**

1. **Créer le script `generer-haproxy-config.sh`** :
   ```bash
   nano scripts/generer-haproxy-config.sh
   ```
   **Contenu** :
   ```bash
   #!/bin/bash
   
   # IPs des instances nginxdemos/hello
   NGINX_HELLO_1_IP=$1
   NGINX_HELLO_2_IP=$2
   
   cat > haproxy.cfg <<EOF
   # =============================================================================
   # Configuration HAProxy pour nginxdemos/hello
   # Projet P5 OpenClassrooms - Exercice 3
   # =============================================================================
   
   global
       log /dev/log local0
       log /dev/log local1 notice
       chroot /var/lib/haproxy
       stats socket /run/haproxy/admin.sock mode 660 level admin
       stats timeout 30s
       user haproxy
       group haproxy
       daemon
   
   defaults
       log global
       mode http
       option httplog
       option dontlognull
       timeout connect 5000
       timeout client 50000
       timeout server 50000
       errorfile 400 /etc/haproxy/errors/400.http
       errorfile 403 /etc/haproxy/errors/403.http
       errorfile 408 /etc/haproxy/errors/408.http
       errorfile 500 /etc/haproxy/errors/500.http
       errorfile 502 /etc/haproxy/errors/502.http
       errorfile 503 /etc/haproxy/errors/503.http
       errorfile 504 /etc/haproxy/errors/504.http
   
   # ===========================================================================
   # Frontend : Écoute sur le port 80
   # ===========================================================================
   frontend http-in
       bind *:80
       default_backend nginx_hello_servers
   
   # ===========================================================================
   # Backend : Répartition entre les 2 instances nginxdemos/hello
   # ===========================================================================
   backend nginx_hello_servers
       balance roundrobin
       server nginx-hello-1 ${NGINX_HELLO_1_IP}:80 check
       server nginx-hello-2 ${NGINX_HELLO_2_IP}:80 check
   
   # ===========================================================================
   # Statistiques HAProxy (port 8404)
   # ===========================================================================
   listen stats
       bind *:8404
       stats enable
       stats uri /stats
       stats refresh 10s
       stats admin if TRUE
       stats show-legends
   EOF
   
   echo "✅ Configuration HAProxy générée dans haproxy.cfg"
   echo "   - Backend 1 : $NGINX_HELLO_1_IP:80"
   echo "   - Backend 2 : $NGINX_HELLO_2_IP:80"
   ```

2. **Rendre le script exécutable** :
   ```bash
   chmod +x scripts/generer-haproxy-config.sh
   ```

3. **Générer la configuration** :
   ```bash
   ./scripts/generer-haproxy-config.sh $NGINX_HELLO_1_IP $NGINX_HELLO_2_IP
   ```

4. **Vérifier le fichier généré** :
   ```bash
   cat haproxy.cfg
   ```

---

### ✅ **Étape 3 : Dépllloyer la VM HAProxy avec Terraform**

1. **Modifier le fichier `main.tf`** pour déployer HAProxy :
   ```bash
   nano terraform/exercice-3/main.tf
   ```
   **Contenu à ajouter** (si non déjà présent) :
   ```hcl
   # VM HAProxy
   resource "aws_instance" "haproxy" {
     ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 LTS
     instance_type = "t2.micro"
     subnet_id     = aws_subnet.p5_public_subnet_b.id
     
     # Clé SSH
     key_name = "p5-key"
     
     # Security Group (autorise HTTP et stats)
     vpc_security_group_ids = [aws_security_group.p5_haproxy_sg.id]
     
     # Tags
     tags = {
       Name    = "p5-haproxy"
       Project = "p5-openclassrooms"
     }
     
     # User Data : Installer HAProxy
     user_data = <<-EOF
               #!/bin/bash
               sudo apt update -y
               sudo apt install -y haproxy
               sudo systemctl start haproxy
               sudo systemctl enable haproxy
               EOF
   }
   
   # Security Group pour HAProxy
   resource "aws_security_group" "p5_haproxy_sg" {
     name        = "p5-haproxy-sg"
     description = "Security Group pour HAProxy (Ports 80 et 8404)"
     vpc_id      = aws_vpc.p5_vpc.id
     
     # Autoriser HTTP (port 80)
     ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }
     
     # Autoriser les stats HAProxy (port 8404)
     ingress {
       from_port   = 8404
       to_port     = 8404
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }
     
     # Autoriser SSH (port 22)
     ingress {
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }
     
     # Autoriser tout le trafic sortant
     egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
     }
     
     tags = {
       Name    = "p5-haproxy-sg"
       Project = "p5-openclassrooms"
     }
   }
   ```

2. **Appliquer Terraform** :
   ```bash
   terraform apply -auto-approve
   ```

3. **Récupérer l'IP publique de HAProxy** :
   ```bash
   HAPROXY_IP=$(terraform output -raw haproxy_public_ip)
   echo "✅ HAProxy Public IP: $HAPROXY_IP"
   ```

---

### ✅ **Étape 4 : Dépllloyer la configuration HAProxy**

1. **Copier le fichier `haproxy.cfg` sur la VM HAProxy** :
   ```bash
   scp -i p5-key.pem haproxy.cfg ubuntu@$HAPROXY_IP:/tmp/
   ```

2. **Se connecter à la VM HAProxy** :
   ```bash
   ssh -i p5-key.pem ubuntu@$HAPROXY_IP
   ```

3. **Dépllloyer la configuration** :
   ```bash
   sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
   sudo chmod 644 /etc/haproxy/haproxy.cfg
   ```

4. **Tester la configuration** :
   ```bash
   sudo haproxy -c -f /etc/haproxy/haproxy.cfg
   ```
   **Résultat attendu** :
   ```
   Configuration file is valid
   ```

5. **Redémarrer HAProxy** :
   ```bash
   sudo systemctl restart haproxy
   ```

6. **Vérifier que HAProxy est démarré** :
   ```bash
   sudo systemctl status haproxy
   ```

---

### ✅ **Étape 5 : Tester le Load Balancing**

1. **Tester l'accès via HAProxy** :
   ```bash
   curl http://$HAPROXY_IP
   ```
   **Résultat attendu** :
   ```html
   <!DOCTYPE html>
   <html>
   <head>
   <title>Hello from NGINX!</title>
   ...
   <body>
   <h1>Hello from NGINX!</h1>
   <p>Server name: <strong>faf376c0f0b1</strong></p>
   <p>Server address: 10.0.1.123:80</p>
   </body>
   </html>
   ```

2. **Tester l'alternance des requêtes (OBLIGATOIRE pour OpenClassrooms)** :
   ```bash
   for i in {1..10}; do 
     curl -s http://$HAPROXY_IP | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//';
     echo "---";
   done
   ```
   **Résultat attendu** :
   ```
   faf376c0f0b1
   ---
   3a8f2b1c4d5e
   ---
   faf376c0f0b1
   ---
   3a8f2b1c4d5e
   ---
   faf376c0f0b1
   ```
   **✅ Les `Server name` doivent alterner entre les 2 conteneurs.**

3. **Vérifier les statistiques HAProxy** :
   ```bash
   curl http://$HAPROXY_IP:8404/stats
   ```
   **Résultat attendu** :
   - Les 2 serveurs backend (`nginx-hello-1` et `nginx-hello-2`) doivent être **UP**.
   - Le nombre de requêtes doit être réparti entre les 2 serveurs.

---

### ✅ **Étape 6 : Tester la tolérance aux pannes**

1. **Arrêter un conteneur `nginxdemos/hello`** :
   ```bash
   # Se connecter à la première VM backend
   ssh -i p5-key.pem ubuntu@$(aws ec2 describe-instances --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
   
   # Arrêter le conteneur
   docker stop nginx-hello
   ```

2. **Tester l'accès via HAProxy** :
   ```bash
   for i in {1..5}; do 
     curl -s http://$HAPROXY_IP | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//';
     echo "---";
   done
   ```
   **Résultat attendu** :
   - Toutes les requêtes doivent être servies par **le même conteneur** (celui qui est encore UP).
   - HAProxy a automatiquement détecté que le premier conteneur est **DOWN**.

3. **Vérifier les statistiques HAProxy** :
   ```bash
   curl http://$HAPROXY_IP:8404/stats
   ```
   **Résultat attendu** :
   - `nginx-hello-1` doit être marqué comme **DOWN**.
   - `nginx-hello-2` doit être marqué comme **UP**.

4. **Redémarrer le conteneur** :
   ```bash
   docker start nginx-hello
   ```

5. **Vérifier que le load balancing fonctionne à nouveau** :
   ```bash
   for i in {1..5}; do 
     curl -s http://$HAPROXY_IP | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//';
     echo "---";
   done
   ```
   **Résultat attendu** :
   - Les requêtes doivent à nouveau alterner entre les 2 conteneurs.

---

## ✅ **VÉRIFICATIONS FINALES (Checklist OpenClassrooms)**

### **Checklist de Vérification**

- [ ] **Préparation** :
  - [ ] 2 instances `nginxdemos/hello` déployées.
  - [ ] IPs privées des instances récupérées.
  - [ ] Configuration HAProxy générée (`haproxy.cfg`).

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès.
  - [ ] `terraform plan` affiche la création de la VM HAProxy.
  - [ ] `terraform apply` crée la VM avec succès.
  - [ ] IP publique de HAProxy récupérée.

- [ ] **HAProxy** :
  - [ ] HAProxy installé sur la VM.
  - [ ] Configuration HAProxy déployée.
  - [ ] Service HAProxy démarré.
  - [ ] Accès via HAProxy fonctionne.

- [ ] **Load Balancing** :
  - [ ] **Alternance des `Server name` vérifiée** (OBLIGATOIRE).
  - [ ] Statistiques HAProxy accessibles (`:8404/stats`).
  - [ ] Tolérance aux pannes testée.

- [ ] **Livrable** :
  - [ ] Fichier `haproxy.cfg` prêt à être livré.

---

## 📌 **LIVRABLES (Format OpenClassrooms)**

### **📁 Fichiers à livrer** :
```
P5_4091_Deployez_et_suivez_l_IaC_Mathias_SEGUIN-CADICHE/
└── Exercice_3/
    └── SEGUIN-CADICHE_Mathias_3_haproxy_cfg_<date>.cfg
```

### **📋 Contenu du livrable** :
| Fichier | Description | Format |
|---------|-------------|--------|
| `haproxy_cfg_<date>.cfg` | Configuration HAProxy pour `nginxdemos/hello` | CFG |

---

## ⚠️ **DÉPANNAGE**

### **Problèmes Courants et Solutions**

#### **1. Erreur : "Configuration file is invalid" (HAProxy)**
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
3. Vérifiez que les ports sont corrects (80 pour `nginxdemos/hello`).

---

#### **2. Erreur : "Connection refused" (HAProxy)**
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

#### **3. Erreur : "No server is available to handle this request" (HAProxy)**
**Symptômes** :
```
503 Service Unavailable
No server is available to handle this request.
```
**Solutions** :
1. Vérifiez que les conteneurs `nginxdemos/hello` sont en cours d'exécution :
   ```bash
   # Sur chaque VM backend
   docker ps
   ```
2. Vérifiez que HAProxy peut se connecter aux conteneurs :
   ```bash
   # Depuis la VM HAProxy
   nc -zv $NGINX_HELLO_1_IP 80
   nc -zv $NGINX_HELLO_2_IP 80
   ```
3. Vérifiez que le Security Group de HAProxy autorise le trafic **sortant** vers les VMs backend.

---

#### **4. Erreur : "All servers are DOWN" (Statistiques HAProxy)**
**Symptômes** :
- Dans les statistiques HAProxy (`http://$HAPROXY_IP:8404/stats`), les 2 serveurs backend sont marqués comme **DOWN**.

**Solutions** :
1. Vérifiez que les conteneurs `nginxdemos/hello` sont accessibles depuis HAProxy :
   ```bash
   # Depuis la VM HAProxy
   curl http://$NGINX_HELLO_1_IP:80
   curl http://$NGINX_HELLO_2_IP:80
   ```
2. Vérifiez que le Security Group des VMs backend autorise le trafic **entrant** depuis HAProxy (port 80).

---

#### **5. Les `Server name` ne changent pas**
**Symptômes** :
- Toutes les requêtes retournent le même `Server name`.

**Solutions** :
1. Vérifiez que l'algorithme de load balancing est bien **`roundrobin`** :
   ```bash
   grep "balance" /etc/haproxy/haproxy.cfg
   ```
2. Vérifiez que les 2 conteneurs sont bien **UP** dans les statistiques HAProxy.
3. Vérifiez que les 2 conteneurs répondent bien :
   ```bash
   curl http://$NGINX_HELLO_1_IP
   curl http://$NGINX_HELLO_2_IP
   ```

---

## 📚 **RESSOURCES UTILES**

- [Documentation HAProxy](https://www.haproxy.org/documentation/)
- [Image `nginxdemos/hello`](https://hub.docker.com/r/nginxdemos/hello)
- [Documentation Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🎉 **RÉSUMÉ**

✅ **2 instances `nginxdemos/hello` déployées**.
✅ **Configuration HAProxy générée** (`haproxy.cfg`).
✅ **VM HAProxy déployée** avec Terraform.
✅ **Load balancing fonctionnel** (alternance des `Server name`).
✅ **Statistiques HAProxy accessibles** (`:8404/stats`).
✅ **Tolérance aux pannes testée**.
✅ **Fichier `haproxy.cfg` prêt à être livré**.

**Exercice 3 terminé avec succès !** 🎉

---

---

**⚠️ Rappel** :
- **Nettoyez vos ressources AWS** après l'exercice pour éviter des coûts inutiles :
  ```bash
  cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/03_HAPROXY/
  terraform destroy -auto-approve
  ```
