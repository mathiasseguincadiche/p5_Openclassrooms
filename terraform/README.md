# 🏗️ Infrastructure Terraform du projet P5

Ce dossier contient trois modules racines indépendants. Chaque exercice possède
son propre état, ses variables et ses sorties Terraform.

| Module | Objectif | Automatisation |
| --- | --- | --- |
| [`exercice-1/`](./exercice-1/) | VPC, deux EC2 et NGINX | [Phase 1](../scripts/phases/phase-1-terraform-ansible.sh) |
| [`exercice-2/`](./exercice-2/) | Domaine Amazon OpenSearch | [Phase 2](../scripts/phases/phase-2-opensearch-kibana.sh) |
| [`exercice-3/`](./exercice-3/) | Deux backends et HAProxy | [Phase 3](../scripts/phases/phase-3-haproxy.sh) |

## 🚀 Préparation d'un module

```bash
cp terraform/exercice-1/terraform.tfvars.example terraform/exercice-1/terraform.tfvars
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 validate
terraform -chdir=terraform/exercice-1 plan -out=tfplan
```

Relisez toujours le plan avant de l'appliquer.

## ✅ Validation globale

```bash
for module in terraform/exercice-{1,2,3}; do
  terraform -chdir="$module" init -backend=false
  terraform -chdir="$module" validate
done
```

## ⚠️ États et secrets

- Les fichiers `terraform.tfvars` réels ne sont pas versionnés.
- Les states et plans ne sont pas versionnés.
- Les clés SSH privées restent hors du dépôt.
- Chaque module doit être détruit depuis le même état qui l'a créé.
