# 🔥 Exercice 1 : TERRAFORM + ANSIBLE (NGINX)

---

## 🎯 2.1. OBJECTIFS

**But principal** : Déployer 2 serveurs web (NGINX) dans AWS automatiquement, puis les configurer pour qu'ils affichent une page web.

**Compétences visées** :
- ✅ Maîtriser Terraform pour créer une infrastructure.
- ✅ Maîtriser Ansible pour configurer des serveurs.
- ✅ Comprendre le workflow IaC + Config Management.
- ✅ Savoir déployer un serveur web (NGINX).

**Résultat attendu** :
- ✅ 2 VMs EC2 en running dans AWS.
- ✅ NGINX installé et accessible sur les 2 VMs.
- ✅ Une page web "Welcome to nginx!" affichée.

---

## 🧠 2.2. CONCEPTS CLÉS À COMPRENDRE

### 🔹 1. Terraform (Infrastructure as Code)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Infrastructure as Code (IaC)** | Décrire ton infrastructure dans du code (fichiers .tf). | Automatise la création de serveurs, réseaux, etc. | Plan de construction pour une maison |
| **Provider** | Plugin Terraform pour interagir avec un cloud (ex : AWS). | Sans ça, Terraform ne sait pas comment créer des VMs dans AWS | Traducteur entre Terraform et AWS |
| **Resource** | Une ressource cloud (ex : VM, Security Group). | Définis ce que tu veux créer (ex : aws_instance) | Meuble dans une maison |
| **Variable** | Une valeur paramétrable (ex : aws_region). | Rends ton code générique (pas de valeur en dur) | Paramètre dans une fonction |
| **State (terraform.tfstate)** | Fichier qui mémorise l'état de ton infrastructure. | Terraform sait quelles ressources existent déjà | Liste de courses |
| **Plan (terraform plan)** | Simule les changements avant de les appliquer. | Évite les mauvaises surprises | Devis avant construction |
| **Apply (terraform apply)** | Applique les changements (crée/supprime des ressources). | Crée réellement les VMs dans AWS | Signer le devis et lancer les travaux |

---

### 🔹 2. Ansible (Configuration Management)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Inventory** | Fichier qui liste les serveurs à configurer. | Ansible sait sur quelles VMs travailler | Liste d'adresses de maisons à décorer |
| **Playbook** | Fichier YAML qui décrit des tâches à exécuter. | Ansible sait quoi faire sur chaque VM | Checklist de tâches pour un décorateur |
| **Module** | Action à exécuter (ex : apt, copy, service). | Installe des paquets, copie des fichiers, etc. | Outil (marteau, pinceau) |
| **Task** | Une tâche dans un playbook. | Décrit une action précise à faire | Étape dans la checklist |
| **Handler** | Tâche déclenchée automatiquement si un changement est détecté. | Ex : Redémarrer NGINX si sa config change | Détecteur de mouvement |
| **Become (sudo)** | Exécute la tâche en root. | Certains logiciels (ex : NGINX) ont besoin de droits admin | Demander au propriétaire |

---

### 🔹 3. NGINX (Serveur Web)

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Serveur Web** | Logiciel qui affiche des pages web (HTML, CSS, JS). | Sans ça, ton site n'est pas accessible | Serveur dans un restaurant |
| **Port 80 (HTTP)** | Port standard pour le trafic web non sécurisé. | Permet aux utilisateurs d'accéder à ton site | Porte d'entrée d'un magasin |
| **Page par défaut** | Page affichée si aucune URL spécifique n'est demandée. | Pour vérifier que NGINX est bien installé | Menu du jour |

---

## 🛠️ 2.3. PRÉPARATION

### ✅ Prérequis pour l'Exercice 1

- VM **vm-devops** (Ubuntu 26.04) créée et accessible en SSH.
- Terraform, Ansible, AWS CLI installés sur la VM.
- AWS CLI configuré avec vos clés (`aws configure`).
- Pack P5 décompressé dans `/home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/`.

---

### 📌 Commandes de vérification

```bash
# 1. Vérifiez que vous êtes sur la VM vm-devops
hostname
# → Doit afficher : vm-devops

# 2. Vérifiez que Terraform est installé
terraform -version
# → Doit afficher : Terraform v1.15.8 (ou supérieur)

# 3. Vérifiez que Ansible est installé
ansible --version
# → Doit afficher : ansible [core 2.15.x]

# 4. Vérifiez que AWS CLI est installé et configuré
aws --version
# → Doit afficher : aws-cli/2.x.x

aws sts get-caller-identity
# → Doit afficher votre UserId et Account (sans erreur)

# 5. Vérifiez que le pack P5 est présent
ls /home/devops/P5_OC_4091_PACK_COMPLET_V4_3_KVM/04_EXERCICES/01_TERRAFORM_ANSIBLE/
# → Doit lister : main.tf, terraform.tfvars.example, deploy.yml, etc.
```

---

## 🚀 2.4. ÉTAPES D'EXÉCUTION

### Étape 1 : Préparer l'environnement sur vm-devops

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
   sudo apt install -y terraform ansible awscli
   ```

4. **Vérifier les installations** (voir section [Commandes de vérification](#-commandes-de-vérification)).

---

### Étape 2 : Configurer AWS CLI

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

### Étape 3 : Déployer l'infrastructure avec Terraform

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
   **Notez les IPs publiques** des 2 instances NGINX pour l'étape suivante.

---

### Étape 4 : Configurer les serveurs avec Ansible

1. **Créer l'inventaire Ansible** (`hosts_aws`) :
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

2. **Tester la connexion Ansible** :
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

3. **Exécuter le playbook Ansible** :
   ```bash
   ansible-playbook -i hosts_aws deploy.yml
   ```
   **Résultat attendu** :
   - Toutes les tâches doivent être exécutées avec succès (`ok` ou `changed`).
   - Aucune erreur (`failed: 0`).

---

### Étape 5 : Vérifier le déploiement

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

3. **Tester l'accès aux pages web** :
   ```bash
   curl http://<IP_NGINX_1>
   curl http://<IP_NGINX_2>
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

---

## ✅ VÉRIFICATIONS

### Checklist de Vérification

- [ ] **Environnement** :
  - [ ] VM vm-devops accessible
  - [ ] Terraform, Ansible, AWS CLI installés
  - [ ] AWS CLI configuré avec les bonnes credentials

- [ ] **Terraform** :
  - [ ] `terraform init` exécuté avec succès
  - [ ] `terraform plan` affiche les bonnes ressources
  - [ ] `terraform apply` crée toutes les ressources
  - [ ] 2 instances EC2 en cours d'exécution

- [ ] **Ansible** :
  - [ ] Inventaire `hosts_aws` créé avec les bonnes IPs
  - [ ] `ansible all -i hosts_aws -m ping` retourne "pong" pour les 2 serveurs
  - [ ] Playbook `deploy.yml` exécuté avec succès

- [ ] **NGINX** :
  - [ ] NGINX installé sur les 2 serveurs
  - [ ] Service NGINX démarré
  - [ ] Page web accessible via `curl`

---

## 🛠️ DÉPANNAGE

### Problèmes Courants et Solutions

#### 1. Erreur : "No valid credential sources found" (Terraform)
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

#### 2. Erreur : "Permission denied (publickey)" (SSH)
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

#### 3. Erreur : "Connection timed out" (SSH)
**Symptômes** :
```
ssh: connect to host ... port 22: Connection timed out
```
**Solutions** :
1. Vérifiez que l'instance EC2 est en cours d'exécution (`Running`).
2. Vérifiez que l'instance a une **IP publique**.
3. Vérifiez que le Security Group autorise le port 22 depuis votre IP.
4. Vérifiez que l'instance est dans un **subnet public** avec une route vers l'Internet Gateway.

---

#### 4. Erreur : "No package named 'nginx'" (Ansible)
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

#### 5. Erreur : "Job for nginx.service failed" (Systemd)
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

## 📚 RESSOURCES UTILES

- [Documentation Terraform](https://developer.hashicorp.com/terraform/docs)
- [Documentation Ansible](https://docs.ansible.com)
- [Documentation AWS EC2](https://docs.aws.amazon.com/ec2/)
- [Documentation NGINX](https://nginx.org/en/docs/)

---

## 🎯 RÉSUMÉ

✅ **Infrastructure déployée** avec Terraform (VPC, subnets, Security Groups, 2 instances EC2)
✅ **NGINX installé et configuré** avec Ansible sur les 2 serveurs
✅ **Pages web accessibles** via HTTP sur les 2 serveurs
✅ **Toutes les vérifications** passées avec succès

**Exercice 1 terminé avec succès !** 🎉

---

**Prochaine étape** : [Exercice 2 - OpenSearch (ELK)](exercice-2.md)
