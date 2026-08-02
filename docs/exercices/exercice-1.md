# Exercice 1 : TERRAFORM + ANSIBLE + ANGULAR (Aligné 100% avec OpenClassrooms)

---

## 📌 **OBJECTIFS (Conforme aux consignes OpenClassrooms)**

**But principal** : Déployer **2 serveurs web (NGINX + Application Angular)** dans AWS automatiquement avec Terraform, puis les configurer avec Ansible.

**Compétences visées** :
- ✅ Maîtriser Terraform pour créer une infrastructure.
- ✅ Maîtriser Ansible pour configurer des serveurs.
- ✅ Déployer une **application Angular** sur un serveur NGINX.
- ✅ Comprendre le workflow **IaC + Config Management + Déploiement d'applications**.

**Résultat attendu** (selon OpenClassrooms) :
- ✅ **2 VMs EC2 en running** dans AWS.
- ✅ **NGINX installé** sur les 2 serveurs.
- ✅ **Application Angular** (depuis le repo officiel OpenClassrooms) **installée et servie par NGINX**.
- ✅ **Configuration NGINX** pour servir l'application Angular (pas juste la page par défaut).
- ✅ **Playbook Ansible (`deploy.yml`)** incluant :
  - Installation de NGINX.
  - Installation de l'application Angular.
  - Configuration de NGINX pour Angular.
  - Handler pour redémarrer NGINX si la config change.

---

## 📚 **CONCEPTS CLÉS À COMPRENDRE**

### 🔹 1. Terraform (Infrastructure as Code)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Infrastructure as Code (IaC)** | Décrire ton infrastructure dans du code (fichiers `.tf`). | Automatise la création de serveurs, réseaux, etc. | Plan de construction pour une maison |
| **Provider** | Plugin Terraform pour interagir avec un cloud (ex : AWS). | Sans ça, Terraform ne sait pas comment créer des VMs dans AWS | Traducteur entre Terraform et AWS |
| **Resource** | Une ressource cloud (ex : VM, Security Group). | Définit ce que tu veux créer (ex : `aws_instance`) | Meuble dans une maison |
| **Variable** | Une valeur paramétrable (ex : `aws_region`). | Rends ton code générique (pas de valeur en dur) | Paramètre dans une fonction |
| **State (terraform.tfstate)** | Fichier qui mémorise l'état de ton infrastructure. | Terraform sait quelles ressources existent déjà | Liste de courses |
| **Plan (terraform plan)** | Simule les changements avant de les appliquer. | Évite les mauvaises surprises | Devis avant construction |
| **Apply (terraform apply)** | Applique les changements (créé/supprime des ressources). | Crée réellement les VMs dans AWS | Signer le devis et lancer les travaux |

---

### 🔹 2. Ansible (Configuration Management)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Inventory** | Fichier qui liste les serveurs à configurer. | Ansible sait sur quelles VMs travailler | Liste d'adresses de maisons à décorer |
| **Playbook** | Fichier YAML qui décrit des tâches à exécuter. | Ansible sait quoi faire sur chaque VM | Checklist de tâches pour un décorateur |
| **Module** | Action à exécuter (ex : `apt`, `copy`, `service`). | Installe des paquets, copie des fichiers, etc. | Outil (marteau, pinceau) |
| **Task** | Une tâche dans un playbook. | Décrit une action précise à faire | Étape dans la checklist |
| **Handler** | Tâche déclenchée automatiquement si un changement est détecté. | Ex : Redémarrer NGINX si sa config change | Détecteur de mouvement |
| **Become (sudo)** | Exécute la tâche en root. | Certains logiciels (ex : NGINX) ont besoin de droits admin | Demander au propriétaire |

---

### 🔹 3. NGINX (Serveur Web)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Serveur Web** | Logiciel qui affiche des pages web (HTML, CSS, JS). | Sans ça, ton site n'est pas accessible | Serveur dans un restaurant |
| **Port 80 (HTTP)** | Port standard pour le trafic web non sécurisé. | Permet aux utilisateurs d'accéder à ton site | Porte d'entrée d'un magasin |
| **Virtual Host** | Configuration pour servir plusieurs sites sur un même serveur. | Permet d'héberger plusieurs applications | Plusieurs menus dans un même restaurant |
| **Static Files** | Fichiers HTML, CSS, JS servis directement par NGINX. | Permet de servir une application Angular (qui est statique après build) | Plat prêt à être servi |

---

### 🔹 4. Angular (Application Frontend)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Angular** | Framework JavaScript pour créer des applications web dynamiques. | Permet de créer des interfaces riches et réactives | Recette de cuisine pour un plat complexe |
| **Build (`ng build`)** | Compile l'application Angular en fichiers statiques (HTML, CSS, JS). | NGINX peut servir ces fichiers directement | Préparer un plat avant de le servir |
| **`dist/`** | Dossier contenant les fichiers statiques générés par le build. | Contient tout ce que NGINX doit servir | Plat prêt à être servi |
| **`index.html`** | Point d'entrée de l'application Angular. | Première page chargée par le navigateur | Entrée du menu |

---

## 🛠️ **PRÉPARATION**

### ✅ Prérequis pour l'Exercice 1

- VM **vm-devops** (Ubuntu 26.04) créée et accessible en SSH.
- Terraform, Ansible, AWS CLI installés sur la VM.
- AWS CLI configuré avec vos clés (`aws configure`).
- **Git** installé (`sudo apt install -y git`).
- **Node.js et npm** installés (`sudo apt install -y nodejs npm`).
- Pack P5 décompressé dans `/home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/`.

---

### 📁 **Fichiers nécessaires**

1. **Cloner l'application Angular** (depuis le repo officiel OpenClassrooms) :
   ```bash
   # Depuis la VM vm-devops
   cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/01_TERRAFORM_ANSIBLE/
   
   # Cloner le repo Angular (remplacez par l'URL officielle OpenClassrooms)
   git clone https://github.com/OpenClassrooms-P5/oc-p5-angular-app.git angular-app
   
   # Vérifier que le repo a bien été cloné
   ls angular-app/
   ```
   **Résultat attendu** :
   ```
   angular-app/
   ├── src/
   ├── package.json
   ├── angular.json
   └── ...
   ```

2. **Créer un dossier pour les fichiers Ansible** :
   ```bash
   mkdir -p files/
   ```

---

### 🔍 **Commandes de vérification**

```bash
# 1. Vérifiez que vous êtes sur la VM vm-devops
hostname
# ✅ Doit afficher : vm-devops

# 2. Vérifiez que Terraform est installé
terraform -version
# ✅ Doit afficher : Terraform v1.15.8 (ou supérieur)

# 3. Vérifiez que Ansible est installé
ansible --version
# ✅ Doit afficher : ansible [core 2.15.x]

# 4. Vérifiez que AWS CLI est installé et configuré
aws --version
# ✅ Doit afficher : aws-cli/2.x.x

aws sts get-caller-identity
# ✅ Doit afficher votre UserId et Account (sans erreur)

# 5. Vérifiez que Git est installé
git --version
# ✅ Doit afficher : git version 2.x.x

# 6. Vérifiez que Node.js et npm sont installés
node --version
# ✅ Doit afficher : v16.x.x ou supérieur

npm --version
# ✅ Doit afficher : 8.x.x ou supérieur

# 7. Vérifiez que le repo Angular a été cloné
ls /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/01_TERRAFORM_ANSIBLE/angular-app/
# ✅ Doit lister les fichiers du projet Angular
```

---

## 🚀 **ÉTAPES D'EXÉCUTION**

---

### ✅ **Étape 1 : Préparer l'environnement sur vm-devops**

1. **Se connecter à la VM vm-devops** :
   ```bash
   ssh devops@<IP_VM_DEVOPS>
   ```

2. **Mettre à jour les packages** :
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Installer les outils nécessaires** :
   ```bash
   sudo apt install -y terraform ansible awscli git nodejs npm
   ```

4. **Vérifier les installations** (voir section [Commandes de vérification](#commandes-de-vérification)).

---

### ✅ **Étape 2 : Configurer AWS CLI**

1. **Configurer les credentials AWS** :
   ```bash
   aws configure
   ```
   - **AWS Access Key ID** : [Votre Access Key]
   - **AWS Secret Access Key** : [Votre Secret Key]
   - **Default region name** : `us-east-1` (OBLIGATOIRE)
   - **Default output format** : `json`

2. **Vérifier la configuration** :
   ```bash
   aws sts get-caller-identity
   ```

---

### ✅ **Étape 3 : Déployer l'infrastructure avec Terraform**

1. **Aller dans le dossier de l'Exercice 1** :
   ```bash
   cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/01_TERRAFORM_ANSIBLE/
   ```

2. **Initialiser Terraform** :
   ```bash
   terraform init
   ```
   **Résultat attendu** :
   ```
   Terraform has been successfully initialized!
   ```

3. **Vérifier le plan** :
   ```bash
   terraform plan
   ```
   **Ce que vous devriez voir** :
   - Liste des ressources à créer (VPC, subnets, Security Groups, instances EC2, etc.)
   - Message : `Plan: X to add, 0 to change, 0 to destroy.`

4. **Appliquer le plan** :
   ```bash
   terraform apply -auto-approve
   ```
   **Résultat attendu** :
   ```
   Apply complete! Resources: X added, 0 changed, 0 destroyed.
   ```

5. **Récupérer les IPs des instances** :
   ```bash
   terraform output
   ```
   **Notez les IPs publiques** des 2 instances pour l'étape suivante.

---

### ✅ **Étape 4 : Configurer les serveurs avec Ansible**

#### **1. Créer l'inventaire Ansible (`hosts_aws`)** :
```bash
nano hosts_aws
```
**Contenu** :
```ini
[webservers]
<IP_NGINX_1> ansible_user=ubuntu ansible_ssh_private_key_file=p5-key.pem
<IP_NGINX_2> ansible_user=ubuntu ansible_ssh_private_key_file=p5-key.pem
```
Remplacez `<IP_NGINX_1>` et `<IP_NGINX_2>` par les IPs publiques de vos instances.

#### **2. Tester la connexion Ansible** :
```bash
ansible all -i hosts_aws -m ping
```
**Résultat attendu** :
```
<IP_NGINX_1> | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
<IP_NGINX_2> | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

#### **3. Créer le fichier de configuration NGINX pour Angular** :
```bash
mkdir -p files/
nano files/nginx-angular.conf
```
**Contenu** (`files/nginx-angular.conf`) :
```nginx
server {
    listen 80;
    server_name _;

    root /var/www/angular-app/dist;
    index index.html;

    # Gérer les routes Angular (pour le routage côté client)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Désactiver le logging pour les fichiers statiques (optionnel)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        access_log off;
        expires max;
    }

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

#### **4. Exécuter le playbook Ansible (`deploy.yml`)** :
```bash
ansible-playbook -i hosts_aws deploy.yml
```
**Résultat attendu** :
- Toutes les tâches doivent être exécutées avec succès (`ok` ou `changed`).
- Aucune erreur (`failed: 0`).

---

### ✅ **Étape 5 : Vérifier le déploiement**

1. **Vérifier que NGINX est installé** :
   ```bash
   ansible all -i hosts_aws -a "nginx -v"
   ```
   **Résultat attendu** :
   ```
   <IP_NGINX_1> | CHANGED | rc=0 >>
   nginx version: nginx/1.18.0 (Ubuntu)
   
   <IP_NGINX_2> | CHANGED | rc=0 >>
   nginx version: nginx/1.18.0 (Ubuntu)
   ```

2. **Vérifier que NGINX est démarré** :
   ```bash
   ansible all -i hosts_aws -a "systemctl status nginx"
   ```
   **Résultat attendu** :
   ```
   <IP_NGINX_1> | CHANGED | rc=0 >>
   ● nginx.service - A high performance web server and a reverse proxy server
      Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
      Active: active (running) since Mon 2026-08-02 12:00:00 UTC; 5min ago
   
   <IP_NGINX_2> | CHANGED | rc=0 >>
   ... (similaire)
   ```

3. **Vérifier que l'application Angular est servie** :
   ```bash
   curl http://<IP_NGINX_1> | grep -i "angular"
   curl http://<IP_NGINX_2> | grep -i "angular"
   ```
   **Résultat attendu** :
   - Le contenu de l'application Angular doit être affiché (pas juste "Welcome to nginx!").
   - Vous devriez voir des balises HTML spécifiques à votre application (ex : `<app-root>`, `<title>Mon App Angular</title>`).

4. **Vérifier dans un navigateur** :
   - Ouvrez un navigateur et allez sur :
     **`http://<IP_NGINX_1>`** et **`http://<IP_NGINX_2>`**
   - **✅ Vous devriez voir votre application Angular s'afficher correctement.**

---

## 📝 **PLAYBOOK ANSIBLE (`deploy.yml`) - VERSION COMPLÈTE**

> **⚠️ Ce playbook est conforme aux consignes OpenClassrooms.**

**Contenu du fichier `ansible/playbooks/deploy.yml`** :
```yaml
---
# =============================================================================
# PLAYBOOK ANSIBLE : Déploiement NGINX + Application Angular
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

- name: Déployer NGINX et l'application Angular
  hosts: webservers
  become: true
  
  tasks:
    # ===========================================================================
    # 1. Installation des dépendances système
    # ===========================================================================
    - name: Mettre à jour l'index des packages
      apt:
        update_cache: yes
      
    - name: Installer Git
      apt:
        name: git
        state: present
      
    - name: Installer Node.js et npm
      apt:
        name: ["nodejs", "npm"]
        state: present
      
    - name: Installer NGINX
      apt:
        name: nginx
        state: present

    # ===========================================================================
    # 2. Cloner et builder l'application Angular
    # ===========================================================================
    - name: Cloner le dépôt Angular
      git:
        repo: "https://github.com/OpenClassrooms-P5/oc-p5-angular-app.git"
        dest: /var/www/angular-app
        version: main
        force: yes
      
    - name: Installer les dépendances Angular
      npm:
        path: /var/www/angular-app
      
    - name: Builder l'application Angular (mode production)
      command: npm run build -- --prod
      args:
        chdir: /var/www/angular-app
      
      # ===========================================================================
      # 3. Configurer NGINX pour servir Angular
      # ===========================================================================
    - name: Copier la configuration NGINX pour Angular
      copy:
        src: files/nginx-angular.conf
        dest: /etc/nginx/sites-available/default
      notify: Reload NGINX
      
    - name: Supprimer le fichier par défaut de NGINX
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      
    - name: Activer la configuration NGINX
      file:
        src: /etc/nginx/sites-available/default
        dest: /etc/nginx/sites-enabled/default
        state: link
      notify: Reload NGINX
      
    - name: Supprimer le fichier default NGINX (si présent)
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      when: false  # Désactivé car déjà géré ci-dessus

    # ===========================================================================
    # 4. Copier les fichiers build d'Angular vers NGINX
    # ===========================================================================
    - name: Copier les fichiers Angular vers le dossier web de NGINX
      copy:
        src: /var/www/angular-app/dist/
        dest: /var/www/html/
        remote_src: yes
        owner: www-data
        group: www-data
        mode: '0755'
      
    - name: S'assurer que le dossier dist existe
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    # ===========================================================================
    # 5. Démarrer et activer NGINX
    # ===========================================================================
    - name: Démarrer NGINX
      service:
        name: nginx
        state: started
        enabled: yes

  # ===========================================================================
  # HANDLERS (Tâches déclenchées automatiquement)
  # ===========================================================================
  handlers:
    - name: Reload NGINX
      service:
        name: nginx
        state: reloaded
```

---

## ✅ **VÉRIFICATIONS FINALES (Checklist OpenClassrooms)**

### **Checklist de Vérification**

- [ ] **Environnement** :
  - [ ] VM vm-devops accessible
  - [ ] Terraform, Ansible, AWS CLI, Git, Node.js, npm installés
  - [ ] AWS CLI configuré avec les bonnes credentials

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès
  - [ ] `terraform plan` affiche les bonnes ressources
  - [ ] `terraform apply` crée toutes les ressources
  - [ ] **2 instances EC2 en cours d'exécution**

- [ ] **Ansible** :
  - [ ] Inventaire `hosts_aws` créé avec les bonnes IPs
  - [ ] `ansible all -i hosts_aws -m ping` retourne "pong" pour les 2 serveurs
  - [ ] Playbook `deploy.yml` exécuté avec succès

- [ ] **Application Angular** :
  - [ ] **Repo Angular cloné** sur les 2 serveurs
  - [ ] **Dépendances installées** (`npm install`)
  - [ ] **Build exécuté** (`npm run build -- --prod`)
  - [ ] **Fichiers build copiés** vers `/var/www/html/`

- [ ] **NGINX** :
  - [ ] **NGINX installé** sur les 2 serveurs
  - [ ] **Configuration NGINX pour Angular** appliquée
  - [ ] **Service NGINX démarré** et activé au démarrage
  - [ ] **Application Angular accessible** via `http://<IP>` (pas "Welcome to nginx!")

---

## 📌 **LIVRABLES (Format OpenClassrooms)**

### **📁 Fichiers à livrer** :
```
P5_4091_Deployez_et_suivez_l_IaC_Mathias_SEGUIN-CADICHE/
└── Exercice_1/
    ├── SEGUIN-CADICHE_Mathias_1_fichiers_terraform_<date>/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    └── SEGUIN-CADICHE_Mathias_1_playbook_ansible_<date>.yml
```

### **📋 Contenu des livrables** :
| Fichier | Description | Format |
|---------|-------------|--------|
| `fichiers_terraform_<date>/` | Tous les fichiers Terraform utilisés | Dossier |
| `playbook_ansible_<date>.yml` | Playbook Ansible (`deploy.yml`) | YAML |

---

## ⚠️ **DÉPANNAGE**

### **Problèmes Courants et Solutions**

#### **1. Erreur : "No valid credential sources found" (Terraform)**
**Symptômes** :
```
Error: No valid credential sources found
```
**Solutions** :
1. Vérifiez que `aws configure` a été exécuté.
2. Vérifiez que vos credentials sont corrects :
   ```bash
   aws sts get-caller-identity
   ```
3. Si vous utilisez un profil spécifique, spécifiez-le :
   ```bash
   export AWS_PROFILE=mon-profil
   ```

---

#### **2. Erreur : "Permission denied (publickey)" (SSH)**
**Symptômes** :
```
Permission denied (publickey).
```
**Solutions** :
1. Vérifiez que la clé SSH `p5-key.pem` existe et est accessible.
2. Vérifiez que le Security Group autorise le port 22 depuis votre IP.
3. Vérifiez que l'utilisateur est `ubuntu` (pour Ubuntu 26.04).
4. Testez la connexion manuellement :
   ```bash
   ssh -i p5-key.pem ubuntu@<IP>
   ```

---

#### **3. Erreur : "No package named 'nginx'" (Ansible)**
**Symptômes** :
```
TASK [Install NGINX] ***************************************************************
fatal: [IP]: FAILED! => {"changed": false, "msg": "No package named 'nginx'"}
```
**Solutions** :
1. Mettez à jour la liste des packages :
   ```bash
   ansible all -i hosts_aws -a "sudo apt update" --become
   ```
2. Installez NGINX manuellement pour tester :
   ```bash
   ssh -i p5-key.pem ubuntu@<IP>
   sudo apt update
   sudo apt install -y nginx
   ```

---

#### **4. Erreur : "Job for nginx.service failed" (Systemd)**
**Symptômes** :
```
Job for nginx.service failed because the control process exited with error code.
```
**Solutions** :
1. Vérifiez la configuration NGINX :
   ```bash
   sudo nginx -t
   ```
2. Vérifiez les logs NGINX :
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```
3. Redémarrez NGINX manuellement :
   ```bash
   sudo systemctl restart nginx
   ```

---

#### **5. Erreur : "npm: command not found" (Ansible)**
**Symptômes** :
```
TASK [Installer les dépendances Angular] *****************************************
fatal: [IP]: FAILED! => {"changed": false, "msg": "npm: command not found"}
```
**Solutions** :
1. Installez Node.js et npm manuellement :
   ```bash
   ssh -i p5-key.pem ubuntu@<IP>
   sudo apt update
   sudo apt install -y nodejs npm
   ```
2. Vérifiez que Node.js et npm sont installés :
   ```bash
   node --version
   npm --version
   ```

---

#### **6. Erreur : "angular-app repository not found" (Git)**
**Symptômes** :
```
fatal: repository 'https://github.com/OpenClassrooms-P5/oc-p5-angular-app.git' not found
```
**Solutions** :
1. **Utilisez le repo officiel OpenClassrooms** (demandez l'URL à votre mentor).
2. **Alternative** : Utilisez un repo Angular générique pour tester :
   ```bash
   git clone https://github.com/angular/angular.git angular-app --depth 1
   ```
   (Mais cela ne sera pas conforme aux consignes OpenClassrooms).

---

#### **7. Erreur : "403 Forbidden" (NGINX)**
**Symptômes** :
```
403 Forbidden
```
**Solutions** :
1. Vérifiez les permissions du dossier `/var/www/html/` :
   ```bash
   sudo chown -R www-data:www-data /var/www/html/
   sudo chmod -R 755 /var/www/html/
   ```
2. Vérifiez que le fichier `index.html` existe :
   ```bash
   ls -la /var/www/html/index.html
   ```
3. Redémarrez NGINX :
   ```bash
   sudo systemctl restart nginx
   ```

---

## 📚 **RESSOURCES UTILES**

- [Documentation Terraform](https://developer.hashicorp.com/terraform/docs)
- [Documentation Ansible](https://docs.ansible.com)
- [Documentation AWS EC2](https://docs.aws.amazon.com/ec2/)
- [Documentation NGINX](https://nginx.org/en/docs/)
- [Documentation Angular](https://angular.io/docs)
- [Tutoriel : Déployer Angular avec NGINX](https://angular.io/guide/deployment)

---

## 🎉 **RÉSUMÉ**

✅ **Infrastructure déployée** avec Terraform (VPC, subnets, Security Groups, 2 instances EC2)
✅ **Application Angular clonée et buildée** sur les 2 serveurs
✅ **NGINX installé et configuré** pour servir Angular
✅ **Playbook Ansible complet** (installation NGINX + Angular + config)
✅ **Application accessible** via HTTP sur les 2 serveurs
✅ **Toutes les vérifications** passées avec succès

**Exercice 1 terminé avec succès !** 🎉

---

**Prochaine étape** : [Exercice 2 - OpenSearch + Kibana (ELK)](exercice-2.md)

---

**⚠️ Rappel** :
- **Nettoyez vos ressources AWS** après l'exercice pour éviter des coûts inutiles :
  ```bash
  cd /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/01_TERRAFORM_ANSIBLE/
  terraform destroy -auto-approve
  ```
