# Infrastructure Terraform du P5 — parcours AWS

Les trois dossiers correspondent aux trois exercices officiels et à la
réalisation **100 % AWS** retenue pour ce projet. Terraform n’a pas le même rôle
dans chacun d’eux.

| Dossier | Rôle | Choix du dépôt |
| --- | --- | --- |
| `exercice-1/` | Cœur du livrable IaC | VPC, deux sous-réseaux et une cible EC2 pour Ansible |
| `exercice-2/` | Monitoring Cloud retenu | Domaine Amazon OpenSearch limité à une adresse `/32` |
| `exercice-3/` | Disponibilité Cloud retenue | Une EC2 HAProxy et deux EC2 `nginxdemos/hello` dans le VPC de l’exercice 1 |

Chaque module possède son propre état. Exécutez les commandes dans le dossier
concerné et ne versionnez jamais `terraform.tfvars` ni les fichiers d’état.

```bash
cp terraform/exercice-1/terraform.tfvars.example \
  terraform/exercice-1/terraform.tfvars
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 plan
terraform -chdir=terraform/exercice-1 apply
```

La région et le type d’instance sont configurables. Vérifiez toujours les
quotas et les coûts de votre compte. Détruisez l’exercice 3 avant l’exercice 1,
car il réutilise le réseau et la paire de clés créés par l’exercice 1.
