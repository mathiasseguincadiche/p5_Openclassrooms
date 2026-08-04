# 📁 Templates Ansible

**Bienvenue dans la section des templates Ansible !**
Ici, vous trouverez des **fichiers de configuration prêts à l'emploi** pour Ansible, **commentés et expliqués** pour automatiser la configuration de vos serveurs.

---

## 📌 Table des Matières

1. [Playbook Ansible](#-playbook-ansible)
2. [Fichier d'Inventaire](#-fichier-dinventaire)
3. [Bonnes Pratiques](#-bonnes-pratiques)

---

## 📄 Playbook Ansible

**Fichier** : [`playbook.yml`](playbook.yml)

**Description** : Template de **playbook Ansible** pour configurer un serveur avec des tâches courantes :

- Mise à jour des paquets.
- Installation de logiciels (Nginx, Docker, etc.).
- Configuration de services.
- Gestion de fichiers et de templates.

**Cas d'Usage** :

- Configuration de serveurs web (Nginx, Apache).
- Installation de Docker et Docker Compose.
- Déploiement d'applications.
- Automatisation de tâches système.

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/ansible/playbook.yml ./playbook.yml

# 2. Créez un fichier d'inventaire (ex: inventory.ini)
cp TEMPLATES/ansible/inventories/hosts_aws.example.ini ./inventory.ini

# 3. Personnalisez le playbook et l'inventaire

# 4. Exécutez le playbook
ansible-playbook -i inventory.ini playbook.yml
```

---

## 📄 Fichier d'Inventaire

**Fichier** : [`inventory.ini`](inventory.ini)

**Description** : Template de **fichier d'inventaire** pour cibler vos serveurs. Il permet de :

- Définir des **groupes de serveurs** (ex: webservers, dbservers).
- Spécifier des **variables** pour chaque groupe ou serveur.
- Configurer les **accès SSH** (utilisateur, clé, port).

**Cas d'Usage** :

- Cibler des serveurs spécifiques pour l'exécution de playbooks.
- Organiser vos serveurs par environnement (dev, staging, prod).
- Définir des variables globales ou spécifiques à un groupe.

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/ansible/inventories/hosts_aws.example.ini ./inventory.ini

# 2. Personnalisez le fichier avec vos serveurs

# 3. Testez la connexion aux serveurs
ansible -i inventory.ini all -m ping
```

---

## 🌟 Bonnes Pratiques

### 1. Organisez votre Code avec des Rôles

- Utilisez des **rôles Ansible** pour structurer votre code de manière modulaire.
- Un rôle contient :
  - `tasks/` : Tâches principales.
  - `handlers/` : Handlers (tâches déclenchées par des notifications).
  - `templates/` : Templates Jinja2.
  - `files/` : Fichiers statiques.
  - `vars/` : Variables.
  - `defaults/` : Variables par défaut.

Exemple de structure :

```bash
roles/
  webserver/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    │   └── nginx.conf.j2
    ├── files/
    ├── vars/
    │   └── main.yml
    └── defaults/
        └── main.yml
```

### 2. Utilisez des Variables

- **Évitez de hardcoder** des valeurs dans les playbooks.
- Utilisez des **variables** dans :
  - L'inventaire (`group_vars/`, `host_vars/`).
  - Les playbooks (`vars:`).
  - Les rôles (`defaults/`, `vars/`).

Exemple :

```yaml
# Dans group_vars/webservers.yml
nginx_version: "1.18.*"

# Dans le playbook
- name: Installer Nginx
  apt:
    name: "nginx={{ nginx_version }}"
    state: present
```

### 3. Utilisez des Templates (Jinja2)

- Utilisez des **templates Jinja2** pour générer des fichiers de configuration dynamiques.
- Exemple :

```yaml
- name: Configurer Nginx
  template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
```

### 4. Utilisez des Handlers

- Les **handlers** sont des tâches qui ne s'exécutent que si elles sont **notifiées** par une autre tâche.
- Exemple :

```yaml
- name: Redémarrer Nginx
  service:
    name: nginx
    state: restarted

- name: Configurer Nginx
  copy:
    src: files/nginx.conf
    dest: /etc/nginx/nginx.conf
  notify: Redémarrer Nginx
```

### 5. Utilisez des Tags

- Ajoutez des **tags** aux tâches pour exécuter seulement certaines parties d'un playbook.
- Exemple :

```yaml
- name: Installer Nginx
  apt:
    name: nginx
    state: present
  tags: install

- name: Configurer Nginx
  template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags: config
```

```bash
# Exécuter seulement les tâches avec le tag 'install'
ansible-playbook playbook.yml --tags "install"
```

### 6. Vérifiez avec `--check`

- Utilisez `--check` pour **simuler** l'exécution d'un playbook sans appliquer les changements.
- Exemple :

```bash
ansible-playbook playbook.yml --check
```

### 7. Utilisez Ansible Vault pour les Secrets

- **Ne stockez jamais** de secrets en clair dans les playbooks ou l'inventaire.
- Utilisez **Ansible Vault** pour chiffrer les fichiers sensibles.

Exemple :

```bash
# Chiffrer un fichier
ansible-vault encrypt secrets.yml

# Éditer un fichier chiffré
ansible-vault edit secrets.yml

# Exécuter un playbook avec un fichier chiffré
ansible-playbook playbook.yml --ask-vault-pass
```

### 8. Documentez vos Playbooks

- Ajoutez des **commentaires** dans vos playbooks pour expliquer chaque tâche.
- Utilisez des **noms de tâches clairs**.

Exemple :

```yaml
- name: Mettre à jour les paquets APT et installer Nginx
  apt:
    update_cache: yes
    name: nginx
    state: present
```

---

## 📚 Ressources

- [Documentation Ansible](https://docs.ansible.com)
- [Ansible pour Débutants](https://www.ansible.com/resources/get-started)
- [Galerie de Modules Ansible](https://galaxy.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Bonne utilisation des templates Ansible !** 🚀
