# ⚙️ Déploiement Ansible

Le playbook principal configure les instances de l'Exercice 1 et publie
l'interface statique présente dans `files/web-app/` derrière NGINX.

```text
ansible/
├── files/
│   ├── web-app/index.html
│   └── nginx-web-app.conf
├── inventories/hosts_aws.example
├── playbooks/deploy.yml
└── requirements.yml
```

Copiez l'inventaire exemple vers un fichier local non versionné, puis lancez :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le fichier réel `ansible/inventories/hosts_aws` est exclu de Git.
