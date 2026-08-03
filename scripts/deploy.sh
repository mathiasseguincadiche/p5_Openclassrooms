#!/bin/bash
# Script de déploiement complet pour p5_Openclassrooms

set -e

echo "=========================================="
echo "  Déploiement p5_Openclassrooms"
echo "=========================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 1. Initialisation Terraform
echo -e "${GREEN}Étape 1: Initialisation Terraform${NC}"
cd terraform
terraform init
terraform validate
cd ..

# 2. Plan Terraform
echo -e "${GREEN}Étape 2: Plan Terraform${NC}"
cd terraform
terraform plan -out=tfplan
cd ..

# 3. Application Terraform (commenté par défaut pour sécurité)
# echo -e "${GREEN}Étape 3: Application Terraform${NC}"
# cd terraform
# terraform apply -auto-approve
# cd ..

# 4. Exécution Ansible
echo -e "${GREEN}Étape 4: Exécution Ansible${NC}"
ansible-playbook ansible/playbooks/deploy.yml

echo -e "${GREEN}✅ Déploiement terminé!${NC}"
