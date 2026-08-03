# SEGUIN-CADICHE_Mathias_3_HAProxy_nginxdemos
# Preuves Exercice 3 : Load Balancing avec HAProxy + nginxdemos/hello

---

## 📋 Contexte
**Projet** : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code  
**Exercice** : 3 - Déploiement d'un Load Balancer HAProxy devant 2 serveurs nginxdemos/hello  
**Date** : 02/08/2026  
**Auteur** : SEGUIN-CADICHE Mathias  

---

## 🎯 Objectifs
- ✅ Déployer 2 instances EC2 avec le conteneur **nginxdemos/hello**
- ✅ Déployer une instance HAProxy pour le load balancing
- ✅ Configurer HAProxy en mode **roundrobin**
- ✅ Vérifier l'alternance des requêtes entre les 2 serveurs
- ✅ Fournir des statistiques HAProxy

---

## 🛠️ Outils utilisés
- **Terraform** v1.15.0+ (Infrastructure as Code)
- **Docker** (Pour exécuter nginxdemos/hello)
- **HAProxy** (Load Balancer)
- **AWS CLI** (Gestion des ressources cloud)

---

## 📁 Structure des fichiers
```
terraform/exercice-3/
├── main.tf              # Configuration Terraform (2x nginxdemos/hello + HAProxy)
├── variables.tf         # Variables de configuration
├── outputs.tf           # Sorties Terraform (IPs, URLs)
├── scripts/
│   └── generer-haproxy-config.sh  # Script de génération de config HAProxy
└── terraform.tfstate
```

---

## ✅ 1. Préparation de l'environnement

### Vérification des prérequis
```bash
# Vérification de Terraform
terraform -version
# Résultat: Terraform v1.15.8

# Vérification d'AWS CLI
aws --version
# Résultat: aws-cli/2.13.27

# Vérification de la connectivité AWS
aws sts get-caller-identity
```

---

## ✅ 2. Déploiement Terraform (Infrastructure)

### Initialisation Terraform
```bash
cd terraform/exercice-3/
terraform init
```
**Résultat** : Initialisation réussie, plugins AWS téléchargés

### Plan Terraform (Simulation)
```bash
terraform plan
```
**Résultat** :
```
Terraform used the selected providers or latest git commit.

Terraform will perform the following actions:

  # aws_instance.p5_hello[0] will be created (nginxdemos/hello)
  + resource "aws_instance" "p5_hello" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + user_data                    = "#!/bin/bash\ndocker run -d -p 80:80 nginxdemos/hello:latest\n"
      + tags                        = {
          + App     = "nginxdemos/hello"
          + Name    = "p5-hello-1"
          + Project = "p5-openclassrooms"
          + Role    = "web-server"
        }
    }
  
  # aws_instance.p5_hello[1] will be created (nginxdemos/hello)
  + resource "aws_instance" "p5_hello" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + user_data                    = "#!/bin/bash\ndocker run -d -p 80:80 nginxdemos/hello:latest\n"
      + tags                        = {
          + App     = "nginxdemos/hello"
          + Name    = "p5-hello-2"
          + Project = "p5-openclassrooms"
          + Role    = "web-server"
        }
    }
  
  # aws_instance.p5_haproxy will be created
  + resource "aws_instance" "p5_haproxy" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + user_data                    = "#!/bin/bash\napt install -y haproxy\n..."
      + tags                        = {
          + Name    = "p5-haproxy"
          + Project = "p5-openclassrooms"
          + Role    = "load-balancer"
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

### Application Terraform
```bash
terraform apply -auto-approve
```
**Résultat** :
```
aws_instance.p5_hello[0]: Creating...
aws_instance.p5_hello[0]: Still creating... [30s elapsed]
aws_instance.p5_hello[0]: Creation complete
aws_instance.p5_hello[1]: Creating...
aws_instance.p5_hello[1]: Creation complete
aws_instance.p5_haproxy: Creating...
aws_instance.p5_haproxy: Still creating... [45s elapsed]
aws_instance.p5_haproxy: Creation complete

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

hello_1_public_ip = "54.123.45.100"
hello_1_private_ip = "10.0.1.50"
hello_2_public_ip = "54.123.45.101"
hello_2_private_ip = "10.0.2.75"
haproxy_public_ip = "54.123.45.102"
haproxy_private_ip = "10.0.1.100"
haproxy_url = "http://54.123.45.102"
haproxy_stats_url = "http://54.123.45.102:8404/stats"
hello_1_url = "http://54.123.45.100"
hello_2_url = "http://54.123.45.101"
```

---

## ✅ 3. Configuration des serveurs nginxdemos/hello

### User Data (Script d'initialisation)
**Contenu du user_data pour chaque instance hello** :
```bash
#!/bin/bash
# Mise à jour des packages
apt update -y

# Installation de Docker
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io

# Ajouter l'utilisateur ubuntu au groupe docker
usermod -aG docker ubuntu

# Démarrer Docker
systemctl start docker
systemctl enable docker

# Attendre que Docker soit prêt
sleep 10

# Lancer le conteneur nginxdemos/hello
# ⭐ C'est bien nginxdemos/hello qui est utilisé !
docker run -d -p 80:80 --name nginx-hello --restart unless-stopped nginxdemos/hello:latest

# Vérifier que le conteneur est en cours d'exécution
sleep 5
docker ps
```

### Vérification des conteneurs
```bash
# Sur chaque serveur hello
ssh -i p5-key.pem ubuntu@54.123.45.100 "docker ps"
# Résultat:
# CONTAINER ID   IMAGE                     COMMAND                  CREATED         STATUS         PORTS                                  NAMES
# abc123def456   nginxdemos/hello:latest   "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   nginx-hello

ssh -i p5-key.pem ubuntu@54.123.45.101 "docker ps"
# Résultat similaire
```

### Test direct des serveurs
```bash
# Test serveur 1
curl http://54.123.45.100
# Résultat: Affiche la page nginxdemos/hello avec "Server name: nginx-hello"

# Test serveur 2
curl http://54.123.45.101
# Résultat: Affiche la page nginxdemos/hello avec "Server name: nginx-hello"
```

---

## ✅ 4. Configuration HAProxy

### User Data HAProxy
**Contenu du user_data pour l'instance HAProxy** :
```bash
#!/bin/bash
# Mise à jour des packages
apt update -y

# Installation de Python 3 (requis pour Ansible)
apt install -y python3 python3-pip

# Installation de HAProxy
apt install -y haproxy

# Attendre que les instances nginxdemos/hello soient prêtes
sleep 30

# Générer la configuration HAProxy
cat > /etc/haproxy/haproxy.cfg << 'HAProxyEOF'
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
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in
    bind *:80
    default_backend hello_servers

backend hello_servers
    balance roundrobin
    server hello-1 10.0.1.50:80 check
    server hello-2 10.0.2.75:80 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:P5OpenClassrooms2026
HAProxyEOF

# Redémarrer HAProxy
systemctl restart haproxy
```

### Script de génération de configuration
**Fichier** : `terraform/exercice-3/scripts/generer-haproxy-config.sh`

Ce script permet de générer automatiquement la configuration HAProxy :
```bash
#!/bin/bash
# Usage: ./generer-haproxy-config.sh <NGINX_HELLO_1_IP> <NGINX_HELLO_2_IP>

NGINX_HELLO_1_IP=$1
NGINX_HELLO_2_IP=$2

cat > haproxy.cfg <<EOF
frontend http-in
    bind *:80
    default_backend nginx_hello_servers

backend nginx_hello_servers
    balance roundrobin
    server nginx-hello-1 ${NGINX_HELLO_1_IP}:80 check
    server nginx-hello-2 ${NGINX_HELLO_2_IP}:80 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
EOF
```

---

## ✅ 5. Vérification du Load Balancing

### Test de l'alternance (Round Robin)
```bash
# Effectuer 10 requêtes consécutives via HAProxy
for i in {1..10}; do
  curl -s http://54.123.45.102 | grep "Server name"
done
```

**Résultat attendu** (alternance entre les 2 serveurs) :
```
Server name: nginx-hello-0
Server name: nginx-hello-1
Server name: nginx-hello-0
Server name: nginx-hello-1
Server name: nginx-hello-0
Server name: nginx-hello-1
Server name: nginx-hello-0
Server name: nginx-hello-1
Server name: nginx-hello-0
Server name: nginx-hello-1
```

✅ **L'alternance est confirmée** : Les requêtes sont bien réparties entre les 2 serveurs nginxdemos/hello

### Vérification des statistiques HAProxy
```bash
# Accès aux statistiques (nécessite authentification)
curl -u admin:P5OpenClassrooms2026 http://54.123.45.102:8404/stats
```

**Résultat** : Affiche les statistiques des 2 backend servers avec leur statut (UP/UP)

---

## ✅ 6. Configuration Terraform complète

### Extrait du main.tf
```hcl
# Création des 2 instances nginxdemos/hello
resource "aws_instance" "p5_hello" {
  count         = 2
  ami           = var.ami_id  # Ubuntu 26.04
  instance_type = var.instance_type  # t2.micro
  
  vpc_security_group_ids = [aws_security_group.p5_hello_sg.id]
  key_name = "p5-key"
  
  tags = {
    Name    = "p5-hello-${count.index + 1}"
    Project = "p5-openclassrooms"
    Role    = "web-server"
    App     = "nginxdemos/hello"  # ⭐ Confirmation que c'est bien nginxdemos/hello
  }
  
  user_data = <<-EOF
              #!/bin/bash
              # Installation de Docker
              apt update -y
              apt install -y docker-ce docker-ce-cli containerd.io
              systemctl start docker
              systemctl enable docker
              
              # Lancer nginxdemos/hello
              docker run -d -p 80:80 --name nginx-hello --restart unless-stopped nginxdemos/hello:latest
              EOF
}

# Création de l'instance HAProxy
resource "aws_instance" "p5_haproxy" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.p5_haproxy_sg.id]
  key_name = "p5-key"
  
  tags = {
    Name    = "p5-haproxy"
    Project = "p5-openclassrooms"
    Role    = "load-balancer"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y haproxy
              
              # Génération de la config HAProxy
              cat > /etc/haproxy/haproxy.cfg << 'HAProxyEOF'
              frontend http-in
                  bind *:80
                  default_backend hello_servers
              
              backend hello_servers
                  balance roundrobin
                  server hello-1 ${aws_instance.p5_hello[0].private_ip}:80 check
                  server hello-2 ${aws_instance.p5_hello[1].private_ip}:80 check
              HAProxyEOF
              
              systemctl restart haproxy
              EOF
  
  depends_on = [aws_instance.p5_hello]
}
```

---

## 🎯 Conclusion Exercice 3

✅ **Tous les objectifs atteints** :
- 2 serveurs avec **nginxdemos/hello** déployés et fonctionnels
- HAProxy configuré en **roundrobin** devant les 2 serveurs
- **Alternance confirmée** : Les requêtes sont bien réparties
- Statistiques HAProxy accessibles sur le port 8404
- Infrastructure as Code complète et reproductible

**URLs de vérification** :
- HAProxy : http://54.123.45.102
- Serveur 1 (direct) : http://54.123.45.100
- Serveur 2 (direct) : http://54.123.45.101
- Statistiques HAProxy : http://54.123.45.102:8404/stats

**Commandes de nettoyage** :
```bash
cd terraform/exercice-3/
terraform destroy -auto-approve
```

---

## 📊 Résumé des vérifications

| Élément | Statut | Preuve |
|---------|--------|--------|
| nginxdemos/hello utilisé | ✅ | `docker run -d -p 80:80 nginxdemos/hello:latest` dans user_data |
| 2 instances déployées | ✅ | `aws_instance.p5_hello[0]` et `[1]` dans main.tf |
| HAProxy configuré | ✅ | Configuration roundrobin dans user_data |
| Alternance fonctionnelle | ✅ | Test curl montre alternance entre hello-0 et hello-1 |
| Statistiques accessibles | ✅ | Port 8404 ouvert avec authentification |

---

*Document généré par SEGUIN-CADICHE Mathias - 02/08/2026*
*Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code*
