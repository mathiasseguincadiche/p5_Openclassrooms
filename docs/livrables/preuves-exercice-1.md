# Preuves Exercice 1 : Terraform + Ansible (Déploiement de NGINX)

---

## 📌 Contexte
**But** : Déployer **2 serveurs web (NGINX)** dans AWS automatiquement avec Terraform, puis les configurer avec Ansible.
**Outils utilisés** : Terraform, Ansible, AWS CLI.

---

## 🔹 1. Préparation de l'environnement

### Installation des outils
**Commande** : `sudo apt update && sudo apt install -y terraform ansible awscli`

**Vérification des versions** :
```
$ terraform -version
Terraform v1.15.8

$ ansible --version
ansible [core 2.15.1]

$ aws --version
aws-cli/2.13.27
```

---

## 🔹 2. Configuration AWS

**Commande** : `aws sts get-caller-identity`

**Résultat** :
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/mathias"
}
```

---

## 🔹 3. Déploiement avec Terraform

### Plan Terraform (Simulation)
**Commande** : `terraform plan`

**Résultat** : [Copier-coller la sortie complète ici]

---

### Application Terraform (Création réelle)
**Commande** : `terraform apply -auto-approve`

**Résultat** : [Copier-coller la sortie complète ici]

---

### Vérification des instances EC2
**Commande** : `aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, PublicIpAddress, State.Name]" --output table`

**Résultat** : [Copier-coller la sortie ici]

---

## 🔹 4. Configuration avec Ansible

### Inventory Ansible
**Contenu de `hosts_aws`** :
```ini
[webservers]
54.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=p5-key.pem
54.123.45.68 ansible_user=ubuntu ansible_ssh_private_key_file=p5-key.pem
```

---

### Test de connexion
**Commande** : `ansible all -i hosts_aws -m ping`

**Résultat** : [Copier-coller la sortie ici]

---

### Exécution du playbook
**Commande** : `ansible-playbook -i hosts_aws deploy.yml`

**Résultat** : [Copier-coller la sortie ici]

---

## 🔹 5. Vérification NGINX

**Commande** : `curl http://54.123.45.67 && curl http://54.123.45.68`

**Résultat** : [Copier-coller la sortie HTML ici]

---

## ✅ Checklist de Vérification

- [ ] Terraform initialisé (`terraform init`)
- [ ] Plan Terraform vérifié (`terraform plan`)
- [ ] Infrastructure déployée (`terraform apply`)
- [ ] 2 instances EC2 en cours d'exécution
- [ ] Ansible connecté aux serveurs (`ansible -m ping`)
- [ ] NGINX installé et configuré
- [ ] Page web accessible via `curl`

---

**Conseil** : Conservez une copie de toutes les sorties de commandes pour vos preuves !
