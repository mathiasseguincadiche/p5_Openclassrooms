# 🏗️ Infrastructure Terraform du projet P5

Ce dossier contient les trois modules racines correspondant aux livrables du
projet. Chaque exercice possède son propre état Terraform et doit être exécuté
depuis son dossier.

| Module | Objectif |
| --- | --- |
| `exercice-1/` | VPC, deux instances NGINX et déploiement Ansible |
| `exercice-2/` | Domaine Amazon OpenSearch et chargement des logs |
| `exercice-3/` | Deux backends `nginxdemos/hello` et HAProxy |

## ✅ Validation

```bash
for module in terraform/exercice-{1,2,3}; do
  terraform -chdir="$module" init -backend=false
  terraform -chdir="$module" validate
done
```

Les valeurs locales doivent être copiées depuis `terraform.tfvars.example`
vers un fichier `terraform.tfvars` non versionné.
