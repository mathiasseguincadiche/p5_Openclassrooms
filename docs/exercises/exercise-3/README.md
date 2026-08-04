# 🔧 Exercice 3 : Configuration avec Ansible

**Bienvenue dans l'Exercice 3 !**
Ici, vous allez apprendre à **automatiser la configuration de serveurs** avec **Ansible**. Cet exercice est conçu pour les **débutants en automatisation d'infrastructure** et couvre les bases d'Ansible : playbooks, inventaires, modules, et plus.

---

## 📌 Table des Matières

1. [🎯 Objectifs](#-objectifs)
2. [🛠️ Prérequis](#prerequis)
3. [📥 Préparation de l'Environnement](#-préparation-de-lenvironnement)
4. [📝 Étape 1 : Installer Ansible](#-étape-1--installer-ansible)
5. [📝 Étape 2 : Créer un Inventaire](#-étape-2--créer-un-inventaire)
6. [📝 Étape 3 : Créer un Playbook Simple](#-étape-3--créer-un-playbook-simple)
7. [📝 Étape 4 : Utiliser des Variables](#-étape-4--utiliser-des-variables)
8. [📝 Étape 5 : Utiliser des Templates (Jinja2)](#-étape-5--utiliser-des-templates-jinja2)
9. [📝 Étape 6 : Créer un Rôle Ansible](#-étape-6--créer-un-rôle-ansible)
10. [✅ Vérification](#-vérification)
11. [🔍 Résolution des Problèmes](#-résolution-des-problèmes)
12. [📚 Pour Aller Plus Loin](#-pour-aller-plus-loin)

---

## 🎯 Objectifs

À la fin de cet exercice, vous serez capable de :
✅ **Comprendre** les concepts de base d'Ansible (playbooks, inventaires, modules).
✅ **Installer** Ansible sur votre machine.
✅ **Créer** un inventaire pour cibler des serveurs.
✅ **Écrire** un playbook pour configurer des serveurs.
✅ **Utiliser** des variables et des templates (Jinja2).
✅ **Organiser** votre code avec des rôles Ansible.
✅ **Exécuter** des playbooks sur des serveurs distants.

---

<a id="prerequis"></a>

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir :

| Outil | Version | Vérification | Lien d'Installation |
|-------|---------|--------------|---------------------|
| **Python** | 3.8+ | `python3 --version` | [python.org](https://www.python.org/) |
| **pip** | - | `pip3 --version` | Inclus avec Python |
| **SSH** | - | `ssh -V` | Inclus avec Linux/macOS |
| **Serveurs distants** | - | - | 2-3 machines (ou conteneurs Docker) |

> **⚠️ Important** : Pour cet exercice, vous avez besoin de **serveurs distants** accessibles via SSH. Si vous n'en avez pas, vous pouvez utiliser :
>
> - Des **machines virtuelles** (VirtualBox, VMware).
> - Des **conteneurs Docker** avec SSH (ex: `ubuntu:latest`).
> - Des **instances cloud** (AWS EC2, Azure VM, GCP Compute Engine).

---

## 📥 Préparation de l'Environnement

### 1. Cloner le Dépôt du Projet P5

Si ce n'est pas déjà fait, clonez le dépôt :

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 2. Créer un Dossier pour l'Exercice

```bash
mkdir -p ~/p5-exercise-3 && cd ~/p5-exercise-3
```

### 3. Préparer des Serveurs de Test

Pour cet exercice, nous allons utiliser **2 conteneurs Docker** comme serveurs de test.

#### Option 1 : Utiliser des Conteneurs Docker (Recommandé pour les Débutants)

```bash
# Lancer 2 conteneurs Ubuntu avec SSH
for i in {1..2}; do
  docker run -d --name ansible-node-$i -p 222$i:22 ubuntu:latest tail -f /dev/null
  docker exec ansible-node-$i apt-get update && apt-get install -y openssh-server sudo
  docker exec ansible-node-$i echo 'root:password' | chpasswd
  docker exec ansible-node-$i mkdir /var/run/sshd
  docker exec ansible-node-$i /usr/sbin/sshd -D &
done
```

> **⚠️ Attention** : Cette méthode est **simplifiée** et **non sécurisée** (mot de passe root simple). Ne l'utilisez **pas en production** !

#### Option 2 : Utiliser des Machines Virtuelles ou des Serveurs Cloud

Si vous avez accès à des **machines virtuelles** ou des **serveurs cloud**, vous pouvez les utiliser. Assurez-vous que :

- Les serveurs ont **Python** installé (Ansible en a besoin).
- Vous avez un **accès SSH** avec des clés ou un mot de passe.

Exemple avec AWS EC2 :

```bash
# Lancer 2 instances EC2 (à adapter selon votre configuration)
# Remplacez les valeurs par les vôtres
aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 --count 2 --instance-type t2.micro --key-name ma-cle-ssh --security-group-ids sg-12345678
```

---

## 📝 Étape 1 : Installer Ansible

### 1. Installer Ansible avec pip

```bash
# Installer Ansible (nécessite Python 3.8+)
pip3 install ansible --user
```

> **💡 Explication** :
>
> - `pip3 install ansible` : Installe Ansible via pip (gestionnaire de paquets Python).
> - `--user` : Installe Ansible dans le répertoire utilisateur (pas besoin de `sudo`).

### 2. Vérifier l'Installation

```bash
# Vérifier la version d'Ansible
ansible --version
```

> **✅ Résultat attendu** : Vous devriez voir quelque chose comme :
>
> ```
> ansible [core 2.15.1]
>   config file = /home/user/.ansible.cfg
>   configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
>   ansible python module location = /home/user/.local/lib/python3.10/site-packages/ansible
>   ansible collection location = /home/user/.ansible/collections
>   executable location = /home/user/.local/bin/ansible
>   python version = 3.10.12 (main, Nov 20 2023, 00:00:00) [GCC 11.4.0]
> ```

### 3. Ajouter Ansible au PATH (si nécessaire)

Si la commande `ansible --version` ne fonctionne pas, ajoutez Ansible à votre `PATH` :

```bash
# Ajouter le répertoire de pip au PATH
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## 📝 Étape 2 : Créer un Inventaire

Un **inventaire** est un fichier qui liste les **serveurs** (ou nœuds) que vous souhaitez configurer avec Ansible. Il peut être au format **INI** ou **YAML**.

### 1. Créer un Fichier d'Inventaire INI

Créez un fichier `inventory.ini` :

```bash
nano inventory.ini
```

#### Si vous utilisez des conteneurs Docker

```ini
# =============================================
# Fichier d'inventaire Ansible (format INI)
# =============================================

# Groupe 1 : Serveurs web
[webservers]
ansible-node-1 ansible_host=localhost ansible_port=2221 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/test-key
ansible-node-2 ansible_host=localhost ansible_port=2222 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/test-key

# Groupe 2 : Tous les serveurs
[all:children]
webservers

# Variables pour le groupe webservers
[webservers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'

# =============================================
# Explications :
# - [webservers] : Nom du groupe.
# - ansible-node-1 : Nom du serveur dans le groupe.
# - ansible_host : Adresse IP ou nom d'hôte du serveur.
# - ansible_port : Port SSH (par défaut : 22).
# - ansible_user : Utilisateur SSH distant.
# - ansible_ssh_private_key_file : Clé privée réservée à l'environnement de test.
# - ansible_ssh_common_args : Options SSH supplémentaires.
# =============================================
```

#### Si vous utilisez des serveurs distants (ex: AWS EC2)

```ini
# =============================================
# Fichier d'inventaire Ansible pour des serveurs distants
# =============================================

# Groupe 1 : Serveurs web
[webservers]
server1 ansible_host=192.168.1.10 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ma-cle-ssh.pem
server2 ansible_host=192.168.1.11 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ma-cle-ssh.pem

# Groupe 2 : Base de données
[dbservers]
db-server ansible_host=192.168.1.12 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ma-cle-ssh.pem

# Groupe 3 : Tous les serveurs
[all:children]
webservers
dbservers

# Variables globales
[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# =============================================
# Explications :
# - ansible_ssh_private_key_file : Chemin vers la clé SSH privée.
# - [all:children] : Regroupe plusieurs groupes.
# - [all:vars] : Variables pour tous les serveurs.
# =============================================
```

> **⚠️ Sécurité** :
>
> - **Évitez de stocker des mots de passe en clair** dans l'inventaire. Utilisez plutôt des **clés SSH** ou **Ansible Vault**.
> - Pour les mots de passe, utilisez `ansible-vault` pour les chiffrer.

### 2. Tester la Connexion aux Serveurs

```bash
# Tester la connexion SSH à tous les serveurs
ansible -i inventory.ini all -m ping
```

> **💡 Explication** :
>
> - `ansible` : Commande principale d'Ansible.
> - `-i inventory.ini` : Spécifie le fichier d'inventaire.
> - `all` : Cible tous les serveurs dans l'inventaire.
> - `-m ping` : Utilise le module `ping` pour tester la connexion.

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```text
> ansible-node-1 | SUCCESS => {
>     "changed": false,
>     "ping": "pong"
> }
> ansible-node-2 | SUCCESS => {
>     "changed": false,
>     "ping": "pong"
> }
> ```
>
> ```

> **❌ Si vous voyez des erreurs** :
>
> - **`SSH Error`** : Vérifiez que les serveurs sont accessibles via SSH.
> - **`Authentication failed`** : Vérifiez le nom d'utilisateur et le mot de passe/clé SSH.
> - **`Connection refused`** : Vérifiez que le port SSH est ouvert (par défaut : 22).

---

## 📝 Étape 3 : Créer un Playbook Simple

Un **playbook** est un fichier YAML qui définit une série de **tâches** à exécuter sur des serveurs. Chaque tâche utilise un **module** Ansible (ex: `apt`, `yum`, `file`, `service`).

### 1. Créer un Playbook pour Installer Nginx

Créez un fichier `playbook.yml` :

```bash
nano playbook.yml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# Playbook Ansible : Installer et configurer Nginx
# =============================================

---
# Définition du playbook
- name: Installer et configurer Nginx sur les serveurs web
  # Cible : tous les serveurs dans le groupe "webservers"
  hosts: webservers
  # Exécute les tâches en tant que root (nécessaire pour installer des paquets)
  become: yes
  # Variables globales pour ce playbook
  vars:
    nginx_version: "1.18.*"

  # Liste des tâches à exécuter
  tasks:
    # --- Tâche 1 : Mettre à jour les paquets APT ---
    - name: Mettre à jour les paquets APT
      apt:
        update_cache: yes
        upgrade: dist
      # Cette tâche ne s'exécute que sur les systèmes Debian/Ubuntu
      when: ansible_os_family == "Debian"

    # --- Tâche 2 : Installer Nginx ---
    - name: Installer Nginx
      apt:
        name: "nginx={{ nginx_version }}"
        state: present
      when: ansible_os_family == "Debian"

    # --- Tâche 3 : Démarrer et activer Nginx ---
    - name: Démarrer et activer Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    # --- Tâche 4 : Vérifier que Nginx est en cours d'exécution ---
    - name: Vérifier que Nginx est en cours d'exécution
      uri:
        url: "http://{{ ansible_host }}"
        status_code: 200
      # Ignore les erreurs (au cas où Nginx n'est pas encore prêt)
      ignore_errors: yes

# =============================================
# Explications supplémentaires :
# - name : Nom de la tâche (affiché dans les logs).
# - apt : Module pour gérer les paquets APT (Debian/Ubuntu).
#   - update_cache : Met à jour le cache APT.
#   - upgrade : Met à jour tous les paquets.
#   - name : Nom du paquet à installer.
#   - state : État souhaité (present = installé, absent = désinstallé).
# - service : Module pour gérer les services.
#   - name : Nom du service.
#   - state : État souhaité (started, stopped, restarted).
#   - enabled : Active le démarrage automatique au boot.
# - uri : Module pour faire des requêtes HTTP.
#   - url : URL à tester.
#   - status_code : Code HTTP attendu.
# - when : Condition pour exécuter la tâche.
# - ignore_errors : Ignore les erreurs pour cette tâche.
# =============================================
```

> **💡 Explication des Modules** :
>
> | Module | Description | Exemple |
> |--------|-------------|---------|
> | `apt` | Gère les paquets APT (Debian/Ubuntu). | `apt: name=nginx state=present` |
> | `yum` | Gère les paquets YUM (RHEL/CentOS). | `yum: name=httpd state=present` |
> | `service` | Gère les services système. | `service: name=nginx state=started` |
> | `file` | Gère les fichiers et dossiers. | `file: path=/etc/nginx state=directory` |
> | `copy` | Copie des fichiers locaux vers les serveurs distants. | `copy: src=files/nginx.conf dest=/etc/nginx/nginx.conf` |
> | `template` | Copie et traite des fichiers Jinja2. | `template: src=templates/nginx.conf.j2 dest=/etc/nginx/nginx.conf` |
> | `uri` | Fait des requêtes HTTP. | `uri: url=http://example.com status_code=200` |
> | `command` | Exécute une commande shell. | `command: ls -la /etc/nginx` |
> | `shell` | Exécute une commande shell (avec variables). | `shell: echo $HOME` |

### 2. Exécuter le Playbook

```bash
# Exécuter le playbook avec l'inventaire
ansible-playbook -i inventory.ini playbook.yml
```

> **💡 Explication de la commande** :
>
> - `ansible-playbook` : Commande pour exécuter un playbook.
> - `-i inventory.ini` : Spécifie le fichier d'inventaire.
> - `playbook.yml` : Fichier du playbook à exécuter.

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> PLAY [Installer et configurer Nginx sur les serveurs web] *************************************
>
> TASK [Gathering Facts] *********************************************************************
> ok: [ansible-node-1]
> ok: [ansible-node-2]
>
> TASK [Mettre à jour les paquets APT] *********************************************************
> changed: [ansible-node-1]
> changed: [ansible-node-2]
>
> TASK [Installer Nginx] *********************************************************************
> changed: [ansible-node-1]
> changed: [ansible-node-2]
>
> TASK [Démarrer et activer Nginx] *************************************************************
> changed: [ansible-node-1]
> changed: [ansible-node-2]
>
> TASK [Vérifier que Nginx est en cours d'exécution] *******************************************
> ok: [ansible-node-1]
> ok: [ansible-node-2]
>
> PLAY RECAP ***********************************************************************************
> ansible-node-1 : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=1
> ansible-node-2 : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=1
> ```

> **💡 Explication des résultats** :
>
> - `ok` : Nombre de tâches réussies sans changement.
> - `changed` : Nombre de tâches qui ont apporté des changements.
> - `unreachable` : Nombre de serveurs inaccessibles.
> - `failed` : Nombre de tâches échouées.
> - `skipped` : Nombre de tâches ignorées (ex: condition `when` non remplie).

### 3. Vérifier que Nginx est Installé

```bash
# Vérifier que Nginx est installé sur les serveurs
ansible -i inventory.ini webservers -a "nginx -v"
```

> **✅ Résultat attendu** : Vous devriez voir la version de Nginx :
>
> ```
> ansible-node-1 | CHANGED | rc=0 >>
> nginx version: nginx/1.18.0 (Ubuntu)
> ansible-node-2 | CHANGED | rc=0 >>
> nginx version: nginx/1.18.0 (Ubuntu)
> ```

---

## 📝 Étape 4 : Utiliser des Variables

Les **variables** permettent de **personnaliser** vos playbooks et de les rendre plus **flexibles**.

### 1. Variables dans l'Inventaire

Modifiez le fichier `inventory.ini` pour ajouter des variables :

```bash
nano inventory.ini
```

Ajoutez une section `[webservers:vars]` :

```ini
[webservers]
ansible-node-1 ansible_host=localhost ansible_port=2221 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/test-key
ansible-node-2 ansible_host=localhost ansible_port=2222 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/test-key

# Variables pour le groupe webservers
[webservers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
custom_message="Bienvenue sur mon serveur Nginx !"
```

### 2. Variables dans le Playbook

Modifiez le fichier `playbook.yml` pour utiliser les variables :

```bash
nano playbook.yml
```

Remplacez le contenu par :

```yaml
---
- name: Installer et configurer Nginx avec des variables
  hosts: webservers
  become: yes

  tasks:
    - name: Mettre à jour les paquets APT
      apt:
        update_cache: yes
        upgrade: dist
      when: ansible_os_family == "Debian"

    - name: Installer Nginx
      apt:
        name: "nginx={{ nginx_version }}"
        state: present
      when: ansible_os_family == "Debian"

    - name: Démarrer et activer Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    # --- Nouvelle tâche : Créer un fichier de configuration personnalisé ---
    - name: Créer un fichier de configuration pour Nginx
      copy:
        dest: /etc/nginx/conf.d/custom.conf
        content: |
          server {
            listen 80;
            server_name localhost;

            location / {
              return 200 "{{ custom_message }}";
              add_header Content-Type text/plain;
            }
          }
      notify: Redémarrer Nginx

  # --- Handlers : Tâches déclenchées par des notifications ---
  handlers:
    - name: Redémarrer Nginx
      service:
        name: nginx
        state: restarted
```

> **💡 Explications** :
>
> - **Variables** : `{{ nginx_version }}` et `{{ custom_message }}` sont remplacées par les valeurs définies dans l'inventaire.
> - **`notify`** : Déclenche un **handler** (tâche spéciale) si la tâche change quelque chose.
> - **Handlers** : Tâches qui ne s'exécutent que si elles sont **notifiées** par une autre tâche.

### 3. Exécuter le Playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

### 4. Vérifier le Fichier de Configuration

```bash
# Vérifier que le fichier custom.conf a été créé
ansible -i inventory.ini webservers -a "cat /etc/nginx/conf.d/custom.conf"
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> ansible-node-1 | CHANGED | rc=0 >>
> server {
>   listen 80;
>   server_name localhost;
>
>   location / {
>     return 200 "Bienvenue sur mon serveur Nginx !";
>     add_header Content-Type text/plain;
>   }
> }
> ```

### 5. Tester le Message Personnalisé

```bash
# Tester le message personnalisé via curl
ansible -i inventory.ini webservers -a "curl -s http://localhost"
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> ansible-node-1 | CHANGED | rc=0 >>
> Bienvenue sur mon serveur Nginx !
> ```

---

## 📝 Étape 5 : Utiliser des Templates (Jinja2)

Ansible utilise **Jinja2** pour les **templates**, ce qui permet de générer des fichiers de configuration **dynamiques**.

### 1. Créer un Dossier `templates`

```bash
mkdir -p templates
```

### 2. Créer un Template pour Nginx

Créez un fichier `templates/nginx.conf.j2` :

```bash
nano templates/nginx.conf.j2
```

Ajoutez le contenu suivant :

```nginx
# =============================================
# Fichier de configuration Nginx généré par Ansible
# =============================================

# Nom du serveur
server {
    listen 80;
    server_name {{ server_name | default('localhost') }};

    # Racine du site
    root /var/www/html;
    index index.html;

    # Message personnalisé
    location / {
        return 200 "{{ custom_message | default('Bienvenue sur Nginx !') }}";
        add_header Content-Type text/plain;
    }

    # Page d'erreur personnalisée
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
```

> **💡 Explications Jinja2** :
>
> - `{{ variable }}` : Affiche la valeur de la variable.
> - `variable | default('valeur par défaut')` : Utilise une valeur par défaut si la variable n'est pas définie.
> - Les templates permettent de **générer des fichiers dynamiques** en fonction des variables.

### 3. Modifier le Playbook pour Utiliser le Template

Modifiez le fichier `playbook.yml` :

```bash
nano playbook.yml
```

Remplacez le contenu par :

```yaml
---
- name: Installer et configurer Nginx avec des templates
  hosts: webservers
  become: yes

  vars:
    server_name: "mon-serveur-web"

  tasks:
    - name: Mettre à jour les paquets APT
      apt:
        update_cache: yes
        upgrade: dist
      when: ansible_os_family == "Debian"

    - name: Installer Nginx
      apt:
        name: "nginx={{ nginx_version }}"
        state: present
      when: ansible_os_family == "Debian"

    - name: Créer le répertoire de configuration
      file:
        path: /etc/nginx/conf.d
        state: directory
        mode: '0755'

    # --- Nouvelle tâche : Copier le template ---
    - name: Copier le template de configuration Nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/conf.d/default.conf
      notify: Redémarrer Nginx

    - name: Supprimer le fichier de configuration par défaut
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      when: ansible_os_family == "Debian"
      notify: Redémarrer Nginx

    - name: Démarrer et activer Nginx
      service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Redémarrer Nginx
      service:
        name: nginx
        state: restarted
```

> **💡 Explications** :
>
> - **`template`** : Module pour copier et traiter un fichier Jinja2.
>   - `src` : Chemin vers le template local.
>   - `dest` : Chemin de destination sur le serveur distant.
> - **`file`** : Module pour gérer les fichiers et dossiers.
>   - `state: directory` : Crée un répertoire.
>   - `state: absent` : Supprime un fichier ou un répertoire.

### 4. Exécuter le Playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

### 5. Vérifier le Fichier de Configuration Généré

```bash
# Vérifier que le fichier a été généré correctement
ansible -i inventory.ini webservers -a "cat /etc/nginx/conf.d/default.conf"
```

> **✅ Résultat attendu** : Vous devriez voir le fichier de configuration avec les variables remplacées :
>
> ```
> ansible-node-1 | CHANGED | rc=0 >>
> # =============================================
> # Fichier de configuration Nginx généré par Ansible
> # =============================================
>
> # Nom du serveur
> server {
>     listen 80;
>     server_name mon-serveur-web;
>
>     # Racine du site
>     root /var/www/html;
>     index index.html;
>
>     # Message personnalisé
>     location / {
>         return 200 "Bienvenue sur mon serveur Nginx !";
>         add_header Content-Type text/plain;
>     }
>
>     # Page d'erreur personnalisée
>     error_page 404 /404.html;
>     location = /404.html {
>         internal;
>     }
>
>     # Logs
>     access_log /var/log/nginx/access.log;
>     error_log /var/log/nginx/error.log;
> }
> ```

---

## 📝 Étape 6 : Créer un Rôle Ansible

Les **rôles** permettent d'**organiser** votre code Ansible de manière **modulaire** et **réutilisable**. Un rôle contient :

- Des **tâches** (`tasks/`).
- Des **handlers** (`handlers/`).
- Des **variables** (`vars/`).
- Des **templates** (`templates/`).
- Des **fichiers statiques** (`files/`).

### 1. Créer la Structure d'un Rôle

```bash
# Créer un rôle nommé "nginx"
ansible-galaxy init roles/nginx
```

> **💡 Explication** :
>
> - `ansible-galaxy init` : Commande pour créer un rôle avec la structure standard.
> - `roles/nginx` : Chemin vers le rôle (créera un dossier `roles/nginx/`).

> **✅ Résultat attendu** : La structure suivante est créée :
>
> ```
> roles/
>   nginx/
>     ├── README.md
>     ├── defaults/
>     │   └── main.yml
>     ├── files/
>     ├── handlers/
>     │   └── main.yml
>     ├── meta/
>     │   └── main.yml
>     ├── tasks/
>     │   └── main.yml
>     ├── templates/
>     ├── tests/
>     │   ├── inventory
>     │   └── test.yml
>     └── vars/
>         └── main.yml
> ```

### 2. Déplacer le Template dans le Rôle

```bash
# Déplacer le template dans le rôle
mv templates/nginx.conf.j2 roles/nginx/templates/
```

### 3. Modifier les Tâches du Rôle

Modifiez le fichier `roles/nginx/tasks/main.yml` :

```bash
nano roles/nginx/tasks/main.yml
```

Remplacez le contenu par :

```yaml
# =============================================
# Tâches principales pour le rôle Nginx
# =============================================

- name: Mettre à jour les paquets APT
  apt:
    update_cache: yes
    upgrade: dist
  when: ansible_os_family == "Debian"

- name: Installer Nginx
  apt:
    name: "nginx={{ nginx_version | default('1.18.*') }}"
    state: present
  when: ansible_os_family == "Debian"

- name: Créer le répertoire de configuration
  file:
    path: /etc/nginx/conf.d
    state: directory
    mode: '0755'

- name: Copier le template de configuration Nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/conf.d/default.conf
  notify: Redémarrer Nginx

- name: Supprimer le fichier de configuration par défaut
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  when: ansible_os_family == "Debian"
  notify: Redémarrer Nginx

- name: Démarrer et activer Nginx
  service:
    name: nginx
    state: started
    enabled: yes
```

### 4. Modifier les Handlers du Rôle

Modifiez le fichier `roles/nginx/handlers/main.yml` :

```bash
nano roles/nginx/handlers/main.yml
```

Remplacez le contenu par :

```yaml
# =============================================
# Handlers pour le rôle Nginx
# =============================================

- name: Redémarrer Nginx
  service:
    name: nginx
    state: restarted
```

### 5. Modifier les Variables par Défaut du Rôle

Modifiez le fichier `roles/nginx/defaults/main.yml` :

```bash
nano roles/nginx/defaults/main.yml
```

Remplacez le contenu par :

```yaml
# =============================================
# Variables par défaut pour le rôle Nginx
# =============================================

# Version de Nginx à installer
nginx_version: "1.18.*"

# Nom du serveur
server_name: "localhost"

# Message personnalisé
custom_message: "Bienvenue sur mon serveur Nginx !"
```

### 6. Créer un Nouveau Playbook pour Utiliser le Rôle

Créez un fichier `playbook-roles.yml` :

```bash
nano playbook-roles.yml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# Playbook Ansible : Utiliser le rôle Nginx
# =============================================

---
- name: Appliquer le rôle Nginx aux serveurs web
  hosts: webservers
  become: yes

  # Variables spécifiques pour ce playbook
  vars:
    server_name: "mon-serveur-web-avec-role"
    custom_message: "Bienvenue sur mon serveur Nginx avec Ansible Roles !"

  # Liste des rôles à appliquer
  roles:
    - nginx

# =============================================
# Explications :
# - roles : Liste des rôles à appliquer.
# - Les variables définies ici écrasent celles des rôles.
# =============================================
```

### 7. Exécuter le Nouveau Playbook

```bash
ansible-playbook -i inventory.ini playbook-roles.yml
```

> **✅ Résultat attendu** : Le playbook devrait s'exécuter avec succès et configurer Nginx sur tous les serveurs.

### 8. Vérifier le Message Personnalisé

```bash
# Tester le message personnalisé via curl
ansible -i inventory.ini webservers -a "curl -s http://localhost"
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> ansible-node-1 | CHANGED | rc=0 >>
> Bienvenue sur mon serveur Nginx avec Ansible Roles !
> ```

---

## ✅ Vérification

Pour vérifier que vous avez **bien compris** cet exercice, répondez aux questions suivantes :

### 1. Qu'est-ce qu'Ansible ?

<details>
<summary>💡 Réponse</summary>
Ansible est un outil d'**automatisation de la configuration** et de **gestion de l'infrastructure**. Il permet de configurer des serveurs, de déployer des applications, et de gérer des tâches répétitives de manière **idempotente** (une tâche exécutée plusieurs fois donne le même résultat).
</details>

### 2. Qu'est-ce qu'un playbook Ansible ?

<details>
<summary>💡 Réponse</summary>
Un **playbook** est un fichier YAML qui définit une série de **tâches** à exécuter sur des serveurs. Chaque tâche utilise un **module** Ansible (ex: `apt`, `yum`, `file`, `service`).
</details>

### 3. Qu'est-ce qu'un inventaire Ansible ?

<details>
<summary>💡 Réponse</summary>
Un **inventaire** est un fichier qui liste les **serveurs** (ou nœuds) que vous souhaitez configurer avec Ansible. Il peut être au format **INI** ou **YAML** et contient des informations comme l'adresse IP, le port SSH, l'utilisateur, etc.
</details>

### 4. À quoi sert le module `apt` ?

<details>
<summary>💡 Réponse</summary>
Le module `apt` permet de **gérer les paquets APT** (Debian/Ubuntu). Il peut installer, désinstaller, ou mettre à jour des paquets.
</details>

### 5. À quoi sert le module `template` ?

<details>
<summary>💡 Réponse</summary>
Le module `template` permet de **copier et traiter un fichier Jinja2** sur les serveurs distants. Il remplace les variables par leurs valeurs et génère un fichier statique.
</details>

### 6. Qu'est-ce qu'un rôle Ansible ?

<details>
<summary>💡 Réponse</summary>
Un **rôle** est une collection de **tâches**, **handlers**, **variables**, **templates**, et **fichiers** organisés de manière modulaire. Les rôles permettent de **réutiliser** du code et de **structurer** vos playbooks.
</details>

### 7. À quoi sert `become: yes` ?

<details>
<summary>💡 Réponse</summary>
`become: yes` permet d'**exécuter les tâches en tant que root** (ou un autre utilisateur privilégié) sur les serveurs distants. Cela est nécessaire pour des tâches comme l'installation de paquets ou la gestion de services.
</details>

### 8. À quoi sert `notify` dans une tâche ?

<details>
<summary>💡 Réponse</summary>
`notify` permet de **déclencher un handler** (tâche spéciale) si la tâche actuelle **apporte un changement**. Les handlers ne s'exécutent qu'une seule fois, même s'ils sont notifiés plusieurs fois.
</details>

---

## 🔍 Résolution des Problèmes

Voici les **problèmes courants** et leurs solutions :

| **Problème** | **Cause Possible** | **Solution** |
|--------------|-------------------|--------------|
| `SSH Error: Connection refused` | Le serveur SSH n'est pas démarré ou le port est incorrect. | Vérifiez que le serveur est accessible (`ssh user@host -p port`). |
| `Authentication failed` | Mauvais nom d'utilisateur, mot de passe, ou clé SSH. | Vérifiez les identifiants dans l'inventaire. |
| `ModuleNotFoundError: No module named 'ansible'` | Ansible n'est pas installé. | Installez Ansible avec `pip3 install ansible --user`. |
| `ERROR! the playbook: playbook.yml could not be found` | Le fichier playbook n'existe pas ou le chemin est incorrect. | Vérifiez que vous êtes dans le bon dossier. |
| `TASK [Gathering Facts] ********************************************************* FAILED` | Ansible ne peut pas se connecter aux serveurs. | Vérifiez la connexion SSH et les identifiants. |
| `fatal: [server]: FAILED! => {"changed": false, "msg": "No package matching 'nginx' is available"}` | Le paquet Nginx n'existe pas pour votre distribution. | Vérifiez le nom du paquet (ex: `nginx` pour Ubuntu, `httpd` pour CentOS). |
| `Jinja2 Template Error` | Erreur de syntaxe dans le template Jinja2. | Vérifiez la syntaxe du template (ex: `{{ variable }}`). |
| `Permission denied` (Ansible) | L'utilisateur n'a pas les permissions pour exécuter la tâche. | Utilisez `become: yes` ou exécutez en tant que root. |

---

## 📚 Pour Aller Plus Loin

### Ressources Officielles

- [Documentation Ansible](https://docs.ansible.com)
- [Ansible pour Débutants](https://www.ansible.com/resources/get-started)
- [Galerie de Modules Ansible](https://galaxy.ansible.com/)

### Tutoriels

- [Ansible Get Started](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

### Livres

- [Ansible for DevOps](https://www.ansiblefordevops.com/) (Jeff Geerling)
- [Ansible: Up and Running](https://www.oreilly.com/library/view/ansible-up/9781491979798/) (Lorin Hochstein et René Moser)

### Prochains Exercices

- **[Exercice 2 : CI/CD avec GitHub Actions](../exercise-2/README.md)** : Si vous ne l'avez pas encore fait.
- **[Exercice 4 : Infrastructure as Code avec Terraform](../exercise-4/README.md)** : Provisionnez une infrastructure cloud.

---

## 🎉 Félicitations

Vous avez **terminé l'Exercice 3** ! 🎉
Vous savez maintenant :
✅ Installer et configurer **Ansible**.
✅ Créer un **inventaire** pour cibler des serveurs.
✅ Écrire un **playbook** pour configurer des serveurs.
✅ Utiliser des **variables** et des **templates Jinja2**.
✅ Organiser votre code avec des **rôles Ansible**.
✅ Exécuter des playbooks sur des **serveurs distants**.

**Passez à l'[Exercice 4](../exercise-4/README.md) pour apprendre à provisionner une infrastructure cloud avec Terraform !** 🚀
