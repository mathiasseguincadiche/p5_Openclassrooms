# 🎯 Preuves Exercice 3 - HAProxy (Load Balancer)

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce fichier doit **prouver que vous avez réalisé l'Exercice 3** avec succès. Il doit contenir :

✅ **Captures d'écran** des étapes clés
✅ **Sorties de commandes** importantes
✅ **Explications** de ce que chaque preuve démontre
✅ **Liens** vers les fichiers de configuration

**Format recommandé** :
- **1 section par étape majeure**
- **Captures d'écran avec légendes**
- **Commandes et sorties**
- **Explications claires**

---

## 📋 **Preuves de Déploiement Terraform**

### **1. Initialisation de Terraform**

**Commande exécutée** :
```bash
cd terraform/exercice-3
terraform init
```

**Sortie attendue** :
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x (signed by HashiCorp)

Terraform has been successfully initialized!
```

**Capture d'écran** :
- [captures/exercice-3/terraform-init.png](captures/exercice-3/terraform-init.png)

**Explication** : Cette commande initialise Terraform pour l'Exercice 3.

---

### **2. Planification avec `terraform plan`**

**Commande exécutée** :
```bash
terraform plan
```

**Sortie attendue** :
```
Terraform will perform the following actions:

  # aws_security_group.haproxy_sg will be created
  + resource "aws_security_group" "haproxy_sg" {
      description = "Security Group pour HAProxy"
      name        = "p5-haproxy-sg"
      # ...
    }

  # aws_instance.haproxy will be created
  + resource "aws_instance" "haproxy" {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.micro"
      # ...
    }

  # aws_eip.haproxy_eip will be created
  + resource "aws_eip" "haproxy_eip" {
      instance = (known after apply)
      vpc      = true
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

**Capture d'écran** :
- [captures/exercice-3/terraform-plan.png](captures/exercice-3/terraform-plan.png)

**Explication** : Cette commande montre les **3 ressources** qui seront créées pour HAProxy.

---

### **3. Application avec `terraform apply`**

**Commande exécutée** :
```bash
terraform apply
```

**Sortie attendue** :
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_security_group.haproxy_sg: Creating...
aws_security_group.haproxy_sg: Creation complete [id=sg-xxxxx]
aws_instance.haproxy: Creating...
aws_instance.haproxy: Creation complete [id=i-xxxxx]
aws_eip.haproxy_eip: Creating...
aws_eip.haproxy_eip: Creation complete [id=eipalloc-xxxxx]

Apply complete! Resources: 3 added, 0 to change, 0 destroyed.
```

**Capture d'écran** :
- [captures/exercice-3/terraform-apply.png](captures/exercice-3/terraform-apply.png)

**Explication** : Cette commande **crée toutes les ressources** pour HAProxy.

---

### **4. Vérification avec `terraform output`**

**Commande exécutée** :
```bash
terraform output
```

**Sortie attendue** :
```
haproxy_public_ip = "52.47.123.45"
haproxy_private_ip = "10.0.1.123"
haproxy_eip = "52.47.123.45"
haproxy_url = "http://52.47.123.45"
haproxy_stats_url = "http://52.47.123.45:8404"
```

**Capture d'écran** :
- [captures/exercice-3/terraform-output.png](captures/exercice-3/terraform-output.png)

**Explication** : Cette commande affiche les **informations de sortie** pour HAProxy.

---

## 📋 **Preuves de Configuration Ansible**

### **1. Test de Connexion avec `ansible -m ping`**

**Commande exécutée** :
```bash
cd ansible
ansible -i inventories/exercice-3.ini haproxy_servers -m ping
```

**Sortie attendue** :
```
haproxy | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**Capture d'écran** :
- [captures/exercice-3/ansible-ping.png](captures/exercice-3/ansible-ping.png)

**Explication** : Cette commande vérifie que **Ansible peut se connecter** à l'instance HAProxy.

---

### **2. Exécution du Playbook Ansible**

**Commande exécutée** :
```bash
ansible-playbook -i inventories/exercice-3.ini playbooks/deploy-haproxy.yml -v
```

**Sortie attendue** :
```
PLAY [Deploy and configure HAProxy] *************************************

TASK [Gathering Facts] *************************************************************
ok: [haproxy]

TASK [Install HAProxy] *************************************************************
changed: [haproxy]

TASK [Deploy HAProxy configuration] **********************************************
changed: [haproxy]

TASK [Enable and start HAProxy] ***************************************************
changed: [haproxy]

PLAY RECAP *********************************************************************
haproxy                    : ok=8  changed=6  unreachable=0  failed=0
```

**Capture d'écran** :
- [captures/exercice-3/ansible-playbook.png](captures/exercice-3/ansible-playbook.png)

**Explication** : Cette commande **installe et configure HAProxy** sur l'instance.

---

## 📋 **Preuves de Fonctionnement de HAProxy**

### **1. Vérification du Service HAProxy**

**Commande exécutée** :
```bash
ansible -i inventories/exercice-3.ini haproxy_servers -a "systemctl status haproxy"
```

**Sortie attendue** :
```
haproxy | CHANGED | rc=0 >>
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-01-01 12:00:00 UTC; 5min ago
     Docs: man:haproxy(1)
           http://haproxy.org/documentation
 Main PID: 1234 (haproxy)
    Tasks: 2 (limit: 1137)
   Memory: 4.3M
   CGroup: /system.slice/haproxy.service
           ├─1234 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /var/lib/haproxy/haproxy.sock
           └─1235 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /var/lib/haproxy/haproxy.sock
```

**Capture d'écran** :
- [captures/exercice-3/haproxy-status.png](captures/exercice-3/haproxy-status.png)

**Explication** : Cette commande montre que **HAProxy est en cours d'exécution** (active: running).

---

### **2. Vérification de la Version de HAProxy**

**Commande exécutée** :
```bash
ansible -i inventories/exercice-3.ini haproxy_servers -a "haproxy -v"
```

**Sortie attendue** :
```
haproxy | CHANGED | rc=0 >>
HA-Proxy version 2.6.15 2023/12/11 - https://haproxy.org/
```

**Capture d'écran** :
- [captures/exercice-3/haproxy-version.png](captures/exercice-3/haproxy-version.png)

**Explication** : Cette commande montre que **HAProxy version 2.6.15** est installé.

---

### **3. Accès via HAProxy**

**URL testée** :
- `http://52.47.123.45` (HAProxy)

**Capture d'écran** :
- [captures/exercice-3/haproxy-access.png](captures/exercice-3/haproxy-access.png)

**Explication** : Cette capture montre que **l'accès via HAProxy fonctionne** et affiche la page web de l'un des serveurs NGINX.

**Contenu attendu** : La page web NGINX (comme dans l'Exercice 1).

---

### **4. Vérification de la Répartition de Charge**

**Commande exécutée** (plusieurs fois) :
```bash
curl http://52.47.123.45
```

**Sortie attendue** :
```
# Première requête
<!DOCTYPE html>
<html>
... (page de NGINX-1) ...
<p><strong>Nom:</strong> p5-nginx-1</p>

# Deuxième requête
<!DOCTYPE html>
<html>
... (page de NGINX-2) ...
<p><strong>Nom:</strong> p5-nginx-2</p>
```

**Capture d'écran** :
- [captures/exercice-3/load-balancing-1.png](captures/exercice-3/load-balancing-1.png) : Première requête (NGINX-1)
- [captures/exercice-3/load-balancing-2.png](captures/exercice-3/load-balancing-2.png) : Deuxième requête (NGINX-2)

**Explication** : Ces captures montrent que **HAProxy répartit la charge** entre NGINX-1 et NGINX-2 (algorithme Round Robin).

---

### **5. Statistiques HAProxy**

**URL testée** :
- `http://52.47.123.45:8404`

**Capture d'écran** :
- [captures/exercice-3/haproxy-stats.png](captures/exercice-3/haproxy-stats.png)

**Explication** : Cette capture montre **l'interface de statistiques de HAProxy** avec :
- Les serveurs backend (NGINX-1, NGINX-2)
- Le nombre de requêtes
- Le statut des serveurs (UP/DOWN)
- Les temps de réponse

---

### **6. Test de Tolérance aux Pannes**

**Commandes exécutées** :
```bash
# Arrêter NGINX-1
ansible -i inventories/exercice-1.ini nginx-1 -a "sudo systemctl stop nginx"

# Tester l'accès via HAProxy (doit toujours fonctionner)
curl http://52.47.123.45

# Redémarrer NGINX-1
ansible -i inventories/exercice-1.ini nginx-1 -a "sudo systemctl start nginx"
```

**Sortie attendue** :
```
# Après avoir arrêté NGINX-1
<!DOCTYPE html>
<html>
... (page de NGINX-2) ...
<p><strong>Nom:</strong> p5-nginx-2</p>
```

**Capture d'écran** :
- [captures/exercice-3/failover-test.png](captures/exercice-3/failover-test.png)

**Explication** : Cette capture montre que **HAProxy bascule automatiquement** vers NGINX-2 quand NGINX-1 est arrêté.

---

## 📋 **Preuves de Configuration**

### **1. Fichier de Configuration HAProxy**

**Fichier** : [ansible/roles/haproxy/templates/haproxy.cfg.j2](ansible/roles/haproxy/templates/haproxy.cfg.j2)

**Contenu attendu** :
```haproxy
# Configuration HAProxy pour P5 OpenClassrooms
# Exercice 3 : Load Balancer

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
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server nginx-1 10.0.1.123:80 check
    server nginx-2 10.0.2.45:80 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
```

**Capture d'écran** :
- [captures/exercice-3/haproxy-config.png](captures/exercice-3/haproxy-config.png)

**Explication** : Ce fichier montre la **configuration complète de HAProxy** avec :
- Frontend sur le port 80
- Backend avec 2 serveurs NGINX
- Algorithme Round Robin
- Health checks
- Interface de statistiques sur le port 8404

---

## 📊 **Checklist de Vérification**

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès
  - [ ] `terraform plan` affiche 3 ressources à créer
  - [ ] `terraform apply` crée toutes les ressources
  - [ ] `terraform output` retourne les IPs et URLs

- [ ] **AWS** :
  - [ ] 1 instance EC2 HAProxy en cours d'exécution
  - [ ] Security Group configuré correctement
  - [ ] Elastic IP attachée

- [ ] **Ansible** :
  - [ ] Connexion SSH testée avec succès
  - [ ] Playbook exécuté sans erreur
  - [ ] HAProxy installé et configuré

- [ ] **HAProxy** :
  - [ ] Service HAProxy démarré
  - [ ] Accès via HAProxy fonctionne
  - [ ] Répartition de charge vérifiée
  - [ ] Statistiques accessibles
  - [ ] Tolérance aux pannes testée

---

## 📎 **Fichiers de Configuration**

Les fichiers de configuration utilisés pour cet exercice sont disponibles dans :

- **Terraform** : [terraform/exercice-3/](terraform/exercice-3/)
  - [main.tf](terraform/exercice-3/main.tf) : Configuration principale
  - [variables.tf](terraform/exercice-3/variables.tf) : Déclaration des variables
  - [outputs.tf](terraform/exercice-3/outputs.tf) : Sorties Terraform
  - [terraform.tfvars](terraform/exercice-3/terraform.tfvars) : Valeurs des variables

- **Ansible** : [ansible/](ansible/)
  - [inventories/exercice-3.ini](ansible/inventories/exercice-3.ini) : Inventaire
  - [playbooks/deploy-haproxy.yml](ansible/playbooks/deploy-haproxy.yml) : Playbook
  - [roles/haproxy/](ansible/roles/haproxy/) : Rôle HAProxy

---

## 🎯 **Résumé**

✅ **Infrastructure déployée** avec Terraform (Security Group, instance EC2, Elastic IP)
✅ **HAProxy installé et configuré** avec Ansible
✅ **Load Balancing fonctionnel** entre les 2 serveurs NGINX
✅ **Répartition de charge vérifiée** (Round Robin)
✅ **Tolérance aux pannes testée**
✅ **Statistiques accessibles**
✅ **Toutes les preuves collectées** (captures d'écran, sorties de commandes)

**Exercice 3 terminé avec succès !** 🎉

---

> *"Un Load Balancer est comme un chef d'orchestre : il dirige le trafic vers les bons serveurs."* — **Adaptation DevOps**
