# 🎭 Configuration Ansible du projet P5

Ce dossier configure les instances de l'exercice 1 après leur création par
Terraform. Le playbook installe NGINX, déploie l'interface web statique et
active la configuration du site.

## 🗂️ Structure

```text
ansible/
├── README.md
├── files/
│   ├── web-app/index.html
│   └── nginx-web-app.conf
├── inventories/hosts_aws.example
├── playbooks/deploy.yml
└── requirements.yml
```

## 🚀 Utilisation

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le fichier `hosts_aws` réel est ignoré par Git. Utilisez uniquement des adresses
et des chemins de clés correspondant à votre environnement.

## ✅ Validation

```bash
ansible-playbook \
  --syntax-check \
  --inventory ansible/inventories/hosts_aws.example \
  ansible/playbooks/deploy.yml
```

La CI vérifie également la configuration NGINX dans un conteneur officiel.
