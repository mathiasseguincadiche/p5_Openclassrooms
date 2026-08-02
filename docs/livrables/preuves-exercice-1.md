# 🎯 Preuves Exercice 1 - Terraform + Ansible + NGINX

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce fichier doit **prouver que vous avez réalisé l'Exercice 1** avec succès. Il doit contenir :

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
cd terraform/exercice-1
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

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever need to destroy the infrastructure created by Terraform,
run "terraform destroy".
```

**Capture d'écran** :
- [captures/exercice-1/terraform-init.png](captures/exercice-1/terraform-init.png)

**Explication** : Cette commande initialise Terraform en téléchargeant les providers nécessaires (AWS dans ce cas).

---

### **2. Planification avec `terraform plan`**

**Commande exécutée** :
```bash
terraform plan
```

**Sortie attendue** :
```
Terraform used the selected providers or latest git version.

Terraform will perform the following actions:

  # aws_vpc.p5_vpc will be created
  + resource "aws_vpc" "p5_vpc" {
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      id                   = (known after apply)
      tags                 = {
        "Environment" = "dev"
        "Name"        = "p5-vpc-exercice-1"
        "Project"     = "p5-openclassrooms"
      }
    }

  # aws_subnet.public_subnet_a will be created
  + resource "aws_subnet" "public_subnet_a" {
      availability_zone       = "eu-west-3a"
      cidr_block              = "10.0.1.0/24"
      map_public_ip_on_launch = true
      tags                    = {
        "Environment" = "dev"
        "Name"        = "p5-public-subnet-a"
        "Project"     = "p5-openclassrooms"
      }
      vpc_id                  = (known after apply)
    }

  # ... (autres ressources)

Plan: 12 to add, 0 to change, 0 to destroy.
```

**Capture d'écran** :
- [captures/exercice-1/terraform-plan.png](captures/exercice-1/terraform-plan.png)

**Explication** : Cette commande montre les **12 ressources** qui seront créées par Terraform (VPC, subnets, Security Groups, instances EC2, etc.).

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

aws_vpc.p5_vpc: Creating...
aws_vpc.p5_vpc: Creation complete [id=vpc-xxxxx]
aws_subnet.public_subnet_a: Creating...
aws_subnet.public_subnet_a: Creation complete [id=subnet-xxxxx]
aws_subnet.public_subnet_b: Creating...
aws_subnet.public_subnet_b: Creation complete [id=subnet-xxxxx]
aws_internet_gateway.p5_igw: Creating...
aws_internet_gateway.p5_igw: Creation complete [id=igw-xxxxx]
... (toutes les ressources)

Apply complete! Resources: 12 added, 0 changed, 0 destroyed.
```

**Capture d'écran** :
- [captures/exercice-1/terraform-apply.png](captures/exercice-1/terraform-apply.png)

**Explication** : Cette commande **crée toutes les ressources** définies dans le code Terraform. À la fin, on voit que **12 ressources ont été créées**.

---

### **4. Vérification avec `terraform output`**

**Commande exécutée** :
```bash
terraform output
```

**Sortie attendue** :
```
nginx_1_public_ip = "52.47.123.45"
nginx_1_private_ip = "10.0.1.123"
nginx_2_public_ip = "3.235.67.89"
nginx_2_private_ip = "10.0.2.45"
nginx_1_url = "http://52.47.123.45"
nginx_2_url = "http://3.235.67.89"
```

**Capture d'écran** :
- [captures/exercice-1/terraform-output.png](captures/exercice-1/terraform-output.png)

**Explication** : Cette commande affiche les **IPs publiques et privées** des instances NGINX, ainsi que les URLs pour y accéder.

---

## 📋 **Preuves de Configuration Ansible**

### **1. Test de Connexion avec `ansible -m ping`**

**Commande exécutée** :
```bash
cd ansible
ansible -i inventories/exercice-1.ini nginx_servers -m ping
```

**Sortie attendue** :
```
nginx-1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
nginx-2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**Capture d'écran** :
- [captures/exercice-1/ansible-ping.png](captures/exercice-1/ansible-ping.png)

**Explication** : Cette commande vérifie que **Ansible peut se connecter** aux 2 serveurs NGINX via SSH.

---

### **2. Exécution du Playbook Ansible**

**Commande exécutée** :
```bash
ansible-playbook -i inventories/exercice-1.ini playbooks/deploy-nginx.yml -v
```

**Sortie attendue** :
```
PLAY [Deploy and configure NGINX on all web servers] *************************************

TASK [Gathering Facts] *************************************************************
ok: [nginx-1]
ok: [nginx-2]

TASK [Install required packages] ***************************************************
changed: [nginx-1]
changed: [nginx-2]

TASK [Add NGINX repository] ********************************************************
changed: [nginx-1]
changed: [nginx-2]

TASK [Install NGINX] ***************************************************************
changed: [nginx-1]
changed: [nginx-2]

... (autres tâches)

PLAY RECAP *********************************************************************
nginx-1                    : ok=12  changed=10  unreachable=0  failed=0
nginx-2                    : ok=12  changed=10  unreachable=0  failed=0
```

**Capture d'écran** :
- [captures/exercice-1/ansible-playbook.png](captures/exercice-1/ansible-playbook.png)

**Explication** : Cette commande **installe et configure NGINX** sur les 2 serveurs. On voit que **12 tâches ont été exécutées**, avec **10 changements** (les autres tâches étaient déjà à jour).

---

## 📋 **Preuves de Fonctionnement de NGINX**

### **1. Vérification du Service NGINX**

**Commande exécutée** :
```bash
ansible -i inventories/exercice-1.ini nginx_servers -a "systemctl status nginx"
```

**Sortie attendue** :
```
nginx-1 | CHANGED | rc=0 >>
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-01-01 12:00:00 UTC; 5min ago
     Docs: man:nginx(8)
 Main PID: 1234 (nginx)
    Tasks: 2 (limit: 1137)
   Memory: 4.3M
   CGroup: /system.slice/nginx.service
           ├─1234 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
           └─1235 nginx: worker process

nginx-2 | CHANGED | rc=0 >>
... (similaire pour nginx-2)
```

**Capture d'écran** :
- [captures/exercice-1/nginx-status.png](captures/exercice-1/nginx-status.png)

**Explication** : Cette commande montre que **NGINX est en cours d'exécution** (active: running) sur les 2 serveurs.

---

### **2. Vérification de la Version de NGINX**

**Commande exécutée** :
```bash
ansible -i inventories/exercice-1.ini nginx_servers -a "nginx -v"
```

**Sortie attendue** :
```
nginx-1 | CHANGED | rc=0 >>
nginx version: nginx/1.23.3

nginx-2 | CHANGED | rc=0 >>
nginx version: nginx/1.23.3
```

**Capture d'écran** :
- [captures/exercice-1/nginx-version.png](captures/exercice-1/nginx-version.png)

**Explication** : Cette commande montre que **NGINX version 1.23.3** est installé sur les 2 serveurs.

---

### **3. Accès à la Page Web NGINX**

**URL testées** :
- `http://52.47.123.45` (NGINX-1)
- `http://3.235.67.89` (NGINX-2)

**Capture d'écran** :
- [captures/exercice-1/nginx-page-1.png](captures/exercice-1/nginx-page-1.png) : Page affichée par NGINX-1
- [captures/exercice-1/nginx-page-2.png](captures/exercice-1/nginx-page-2.png) : Page affichée par NGINX-2

**Explication** : Ces captures montrent que **NGINX sert une page web** avec les informations du serveur (IP, hostname, version de NGINX, etc.).

**Contenu attendu de la page** :
```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>P5 OpenClassrooms - Exercice 1</title>
</head>
<body>
    <h1>✅ Bienvenue sur P5 OpenClassrooms !</h1>
    <p>Exercice 1 : Terraform + Ansible + NGINX</p>
    
    <div class="server-info">
        <h2>🖥️ Informations du Serveur</h2>
        <p><strong>Nom:</strong> [hostname]</p>
        <p><strong>IP Privée:</strong> [private_ip]</p>
        <p><strong>IP Publique:</strong> [public_ip]</p>
        <p><strong>Système:</strong> Amazon Linux 2</p>
        <p><strong>NGINX Version:</strong> 1.23.3</p>
    </div>
    
    <p>🎉 Déploiement réussi avec Terraform et Ansible !</p>
</body>
</html>
```

---

### **4. Vérification des Logs NGINX**

**Commande exécutée** :
```bash
ansible -i inventories/exercice-1.ini nginx_servers -a "tail /var/log/nginx/access.log"
```

**Sortie attendue** :
```
nginx-1 | CHANGED | rc=0 >>
192.168.1.1 - - [01/Jan/2024:12:00:00 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

nginx-2 | CHANGED | rc=0 >>
... (similaire pour nginx-2)
```

**Capture d'écran** :
- [captures/exercice-1/nginx-logs.png](captures/exercice-1/nginx-logs.png)

**Explication** : Cette commande montre que **les logs d'accès NGINX sont générés** et contiennent des informations sur les requêtes HTTP.

---

## 📋 **Preuves de Vérification AWS**

### **1. Vérification des Instances EC2**

**Commande AWS CLI exécutée** :
```bash
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,Tags[?Key==`Name`].Value | [0]]' --output table
```

**Sortie attendue** :
```
--------------------------------------------------------
|              DescribeInstances               |
+----------------------+----------------+----------+------+
|  i-0123456789abcdef0  |  52.47.123.45  |  running |  p5-nginx-1 |
|  i-0abcdef1234567890  |  3.235.67.89   |  running |  p5-nginx-2 |
+----------------------+----------------+----------+------+
```

**Capture d'écran** :
- [captures/exercice-1/aws-instances.png](captures/exercice-1/aws-instances.png)

**Explication** : Cette commande montre que **2 instances EC2 sont en cours d'exécution** avec les noms `p5-nginx-1` et `p5-nginx-2`.

---

### **2. Vérification du VPC et des Subnets**

**Commande AWS CLI exécutée** :
```bash
aws ec2 describe-vpcs --vpc-ids $(terraform -C terraform/exercice-1 output -raw vpc_id) --query 'Vpcs[0].[VpcId,CidrBlock,Tags[?Key==`Name`].Value | [0]]' --output table
```

**Sortie attendue** :
```
------------------------------------
|         DescribeVpcs         |
+----------------+-------------+------+
|  vpc-xxxxxxxxx  |  10.0.0.0/16  |  p5-vpc-exercice-1 |
+----------------+-------------+------+
```

**Capture d'écran** :
- [captures/exercice-1/aws-vpc.png](captures/exercice-1/aws-vpc.png)

**Explication** : Cette commande montre que **le VPC a été créé** avec le CIDR `10.0.0.0/16`.

---

### **3. Vérification du Security Group**

**Commande AWS CLI exécutée** :
```bash
aws ec2 describe-security-groups --group-ids $(terraform -C terraform/exercice-1 output -raw nginx_security_group_id) --query 'SecurityGroups[0].[GroupName,IpPermissions[].[FromPort,ToPort,IpProtocol,IpRanges[].CidrIp]]' --output table
```

**Sortie attendue** :
```
--------------------------------------------------
|       DescribeSecurityGroups        |
+-----------+--------------------------------------+
|  p5-nginx-sg  |  [[80,80,tcp,0.0.0.0/0],[22,22,tcp,192.168.1.1/32]]  |
+-----------+--------------------------------------+
```

**Capture d'écran** :
- [captures/exercice-1/aws-security-group.png](captures/exercice-1/aws-security-group.png)

**Explication** : Cette commande montre que **le Security Group autorise** :
- Le trafic HTTP (port 80) depuis n'importe où (`0.0.0.0/0`)
- Le trafic SSH (port 22) depuis votre IP (`192.168.1.1/32`)

---

## 📊 **Checklist de Vérification**

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès
  - [ ] `terraform plan` affiche 12 ressources à créer
  - [ ] `terraform apply` crée toutes les ressources
  - [ ] `terraform output` retourne les IPs publiques

- [ ] **AWS** :
  - [ ] 2 instances EC2 en cours d'exécution
  - [ ] VPC créé avec le bon CIDR
  - [ ] 2 subnets publics créés
  - [ ] Security Group configuré correctement

- [ ] **Ansible** :
  - [ ] Connexion SSH testée avec succès
  - [ ] Playbook exécuté sans erreur
  - [ ] NGINX installé sur les 2 serveurs

- [ ] **NGINX** :
  - [ ] Service NGINX démarré
  - [ ] Page web accessible via HTTP
  - [ ] Logs NGINX générés

---

## 📎 **Fichiers de Configuration**

Les fichiers de configuration utilisés pour cet exercice sont disponibles dans :

- **Terraform** : [terraform/exercice-1/](terraform/exercice-1/)
  - [main.tf](terraform/exercice-1/main.tf) : Configuration principale
  - [variables.tf](terraform/exercice-1/variables.tf) : Déclaration des variables
  - [outputs.tf](terraform/exercice-1/outputs.tf) : Sorties Terraform
  - [terraform.tfvars](terraform/exercice-1/terraform.tfvars) : Valeurs des variables

- **Ansible** : [ansible/](ansible/)
  - [inventories/exercice-1.ini](ansible/inventories/exercice-1.ini) : Inventaire
  - [playbooks/deploy-nginx.yml](ansible/playbooks/deploy-nginx.yml) : Playbook
  - [roles/nginx/](ansible/roles/nginx/) : Rôle NGINX

---

## 🎯 **Résumé**

✅ **Infrastructure déployée** avec Terraform (VPC, subnets, Security Groups, instances EC2)
✅ **NGINX installé et configuré** avec Ansible sur 2 serveurs
✅ **Pages web accessibles** via HTTP sur les 2 serveurs
✅ **Logs générés** et accessibles
✅ **Toutes les preuves collectées** (captures d'écran, sorties de commandes)

**Exercice 1 terminé avec succès !** 🎉

---

> *"Une image vaut mille mots, une preuve vaut mille explications."* — **Adaptation DevOps**
