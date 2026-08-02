# Journal de session - Projet P5 OpenClassrooms
## Déployer et suivre l'infrastructure as code

---

### 📅 [Date du jour]

- **[Heure]-[Heure]** : [Description de l'action].
  - Commande exécutée : [commande].
  - Résultat : [résultat].

---

### Exemple :

### 📅 Vendredi 02/08/2026

- **10:00-11:00** : Configuration de KVM et création de la VM `vm-devops` (Ubuntu 26.04).
  - Vérification de KVM avec `virsh list --all`.
  - Création de la VM avec `virt-manager` (4 Go RAM, 2 vCPU, 20 Go disque).
  - Connexion SSH avec `ssh devops@<IP_VM>`.

- **11:00-12:00** : Installation de Terraform, Ansible, AWS CLI sur `vm-devops`.
  - Vérification des versions avec `terraform -version`, `ansible --version`, `aws --version`.

- **14:00-18:00** : **Exercice 1 - Terraform + Ansible (NGINX)**
  - Déploiement de 2 VMs EC2 avec `terraform apply`.
  - Installation de NGINX avec `ansible-playbook deploy.yml`.
  - Vérification avec `curl http://<IP_VM1>` et `curl http://<IP_VM2>`.

---

### 📅 [Ajoutez vos propres entrées ici]

- **[]-[]** : []
  - Commande exécutée : []
  - Résultat : []

---

**Conseil** : Mettez à jour ce journal **après chaque session** pour ne rien oublier !
