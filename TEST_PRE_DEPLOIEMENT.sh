#!/bin/bash
# =============================================================================
# SCRIPT DE TEST PRE-DEPLOIEMENT
# Ce script vérifie que ton environnement est prêt pour le projet P5 OpenClassrooms
# Exécute-le AVANT de commencer le déploiement
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Fonctions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

title() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

# Vérifier si on est dans le bon dossier
if [ ! -f "README.md" ] || [ ! -d "terraform" ] || [ ! -d "ansible" ] || [ ! -d "scripts" ]; then
    echo -e "${RED}Erreur: Ce script doit être exécuté depuis la racine du projet p5_Openclassrooms${NC}"
    exit 1
fi

clear
title "TEST PRE-DEPLOIEMENT - P5 OpenClassrooms"
info "Ce script vérifie que ton environnement est prêt pour le déploiement"
echo ""

# =============================================================================
# TEST 1: Vérification des outils installés
# =============================================================================
title "TEST 1: Vérification des outils installés"

# Terraform
if command -v terraform >/dev/null 2>&1; then
    VERSION=$(terraform --version | head -1)
    pass "Terraform est installé ($VERSION)"
else
    fail "Terraform N'EST PAS installé (requis: >= 1.15.0)"
    warning "  Installation: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli"
fi

# Ansible
if command -v ansible >/dev/null 2>&1; then
    VERSION=$(ansible --version | head -1)
    pass "Ansible est installé ($VERSION)"
else
    fail "Ansible N'EST PAS installé (requis: >= 2.10)"
    warning "  Installation: https://docs.ansible.com/ansible/latest/installation_guide/index.html"
fi

# Docker
if command -v docker >/dev/null 2>&1; then
    VERSION=$(docker --version)
    pass "Docker est installé ($VERSION)"
else
    fail "Docker N'EST PAS installé (requis: >= 20.10)"
    warning "  Installation: https://docs.docker.com/get-docker/"
fi

# AWS CLI
if command -v aws >/dev/null 2>&1; then
    VERSION=$(aws --version)
    pass "AWS CLI est installé ($VERSION)"
else
    warning "AWS CLI N'EST PAS installé (optionnel mais recommandé)"
    warning "  Installation: https://aws.amazon.com/cli/"
    pass "AWS CLI est optionnel"
fi

# Git
if command -v git >/dev/null 2>&1; then
    VERSION=$(git --version)
    pass "Git est installé ($VERSION)"
else
    fail "Git N'EST PAS installé (requis: >= 2.0)"
    warning "  Installation: https://git-scm.com/"
fi

# Python 3
if command -v python3 >/dev/null 2>&1; then
    VERSION=$(python3 --version)
    pass "Python 3 est installé ($VERSION)"
else
    fail "Python 3 N'EST PAS installé (requis: >= 3.8)"
    warning "  Installation: https://www.python.org/downloads/"
fi

# yamllint (optionnel)
if command -v yamllint >/dev/null 2>&1; then
    VERSION=$(yamllint --version)
    pass "yamllint est installé ($VERSION)"
else
    warning "yamllint N'EST PAS installé (optionnel)"
    warning "  Installation: pip install yamllint"
    pass "yamllint est optionnel"
fi

# =============================================================================
# TEST 2: Vérification de la configuration AWS
# =============================================================================
title "TEST 2: Vérification de la configuration AWS"

# Vérifier les variables d'environnement
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    pass "Variables d'environnement AWS configurées"
else
    warning "Variables d'environnement AWS non configurées"
    warning "  Tu peux les configurer avec:"
    warning "    export AWS_ACCESS_KEY_ID='ta_cle'"
    warning "    export AWS_SECRET_ACCESS_KEY='ton_secret'"
    warning "    export AWS_DEFAULT_REGION='us-east-1'"
fi

# Vérifier ~/.aws/credentials
if [ -f "$HOME/.aws/credentials" ]; then
    pass "Fichier ~/.aws/credentials existe"
else
    warning "Fichier ~/.aws/credentials non trouvé"
    warning "  Tu peux le créer avec:"
    warning "    mkdir -p ~/.aws"
    warning "    echo '[default]' > ~/.aws/credentials"
    warning "    echo 'aws_access_key_id = ta_cle' >> ~/.aws/credentials"
    warning "    echo 'aws_secret_access_key = ton_secret' >> ~/.aws/credentials"
    warning "    chmod 600 ~/.aws/credentials"
fi

# Vérifier ~/.aws/config
if [ -f "$HOME/.aws/config" ]; then
    pass "Fichier ~/.aws/config existe"
else
    warning "Fichier ~/.aws/config non trouvé"
    warning "  Tu peux le créer avec:"
    warning "    echo '[default]' > ~/.aws/config"
    warning "    echo 'region = us-east-1' >> ~/.aws/config"
    warning "    echo 'output = json' >> ~/.aws/config"
fi

# =============================================================================
# TEST 3: Vérification des clés SSH
# =============================================================================
title "TEST 3: Vérification des clés SSH"

# Vérifier la clé privée
if [ -f "$HOME/.ssh/p5-key" ]; then
    pass "Clé SSH privée p5-key existe"
else
    warning "Clé SSH privée p5-key non trouvée"
    warning "  Tu peux la créer avec:"
    warning "    ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key"
fi

# Vérifier la clé publique
if [ -f "$HOME/.ssh/p5-key.pub" ]; then
    pass "Clé SSH publique p5-key.pub existe"
else
    warning "Clé SSH publique p5-key.pub non trouvée"
fi

# Vérifier les permissions
if [ -f "$HOME/.ssh/p5-key" ]; then
    PERMS=$(stat -c %a "$HOME/.ssh/p5-key")
    if [ "$PERMS" = "600" ]; then
        pass "Permissions de la clé SSH privée sont correctes (600)"
    else
        fail "Permissions de la clé SSH privée sont incorrectes ($PERMS, attendu: 600)"
        warning "  Correction: chmod 600 ~/.ssh/p5-key"
    fi
fi

# =============================================================================
# TEST 4: Vérification de la structure du projet
# =============================================================================
title "TEST 4: Vérification de la structure du projet"

# Vérifier les dossiers principaux
for dir in terraform ansible scripts docs; do
    if [ -d "$dir" ]; then
        pass "Dossier $dir/ existe"
    else
        fail "Dossier $dir/ MANQUANT"
    fi
done

# Vérifier les fichiers essentiels
for file in terraform/main.tf terraform/variables.tf terraform/outputs.tf \
            ansible/playbooks/deploy.yml ansible/requirements.yml \
            scripts/deploy.sh scripts/validate.sh scripts/clean.sh \
            scripts/runbook.sh; do
    if [ -f "$file" ]; then
        pass "Fichier $file existe"
    else
        fail "Fichier $file MANQUANT"
    fi
done

# =============================================================================
# TEST 5: Vérification de la syntaxe des scripts
# =============================================================================
title "TEST 5: Vérification de la syntaxe des scripts"

SCRIPT_ERRORS=0
for script in scripts/*.sh scripts/utils/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            pass "Syntaxe OK: $script"
        else
            fail "Erreur de syntaxe: $script"
            SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
        fi
    fi
done

if [ $SCRIPT_ERRORS -eq 0 ]; then
    info "Tous les scripts ont une syntaxe valide"
fi

# =============================================================================
# TEST 6: Vérification des fichiers Terraform
# =============================================================================
title "TEST 6: Vérification des fichiers Terraform"

# Vérifier que terraform est installé avant de continuer
if ! command -v terraform >/dev/null 2>&1; then
    warning "Terraform non installé - validation Terraform ignorée"
else
    # Valider chaque exercice
    for exercice in exercice-1 exercice-2 exercice-3; do
        if [ -d "terraform/$exercice" ]; then
            cd terraform/$exercice
            if terraform validate 2>/dev/null; then
                pass "Terraform valide: $exercice"
            else
                fail "Erreur Terraform: $exercice"
            fi
            cd ../..
        fi
    done
fi

# =============================================================================
# TEST 7: Vérification des fichiers YAML
# =============================================================================
title "TEST 7: Vérification des fichiers YAML"

# Vérifier que yamllint est installé
if ! command -v yamllint >/dev/null 2>&1; then
    warning "yamllint non installé - validation YAML ignorée"
else
    YAML_ERRORS=0
    for yaml_file in ansible/playbooks/*.yml ansible/requirements.yml; do
        if [ -f "$yaml_file" ]; then
            if yamllint "$yaml_file" 2>/dev/null; then
                pass "YAML valide: $yaml_file"
            else
                fail "Erreur YAML: $yaml_file"
                YAML_ERRORS=$((YAML_ERRORS + 1))
            fi
        fi
    done
    
    if [ $YAML_ERRORS -eq 0 ]; then
        info "Tous les fichiers YAML sont valides"
    fi
fi

# =============================================================================
# TEST 8: Vérification des permissions des scripts
# =============================================================================
title "TEST 8: Vérification des permissions des scripts"

NON_EXECUTABLE=0
for script in scripts/*.sh scripts/utils/*.sh setup-and-run.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            pass "Permissions OK: $script"
        else
            fail "Non exécutable: $script"
            NON_EXECUTABLE=$((NON_EXECUTABLE + 1))
        fi
    fi
done

if [ $NON_EXECUTABLE -gt 0 ]; then
    warning "Correction: chmod +x scripts/*.sh scripts/utils/*.sh"
fi

# =============================================================================
# TEST 9: Vérification des variables Terraform
# =============================================================================
title "TEST 9: Vérification des variables Terraform"

# Vérifier si your_ip_cidr est configuré
if grep -r "your_ip_cidr" terraform/ >/dev/null 2>&1; then
    warning "La variable 'your_ip_cidr' doit être configurée"
    warning "  Crée un fichier terraform.tfvars dans chaque exercice avec:"
    warning "    your_ip_cidr = \"TON_IP/32\""
    warning "  Pour trouver ton IP: curl ifconfig.me"
fi

# Vérifier si ssh_public_key_path est configuré
if grep -r "ssh_public_key_path" terraform/ >/dev/null 2>&1; then
    warning "La variable 'ssh_public_key_path' doit être configurée"
    warning "  Dans terraform.tfvars:"
    warning "    ssh_public_key_path = \"~/.ssh/p5-key.pub\""
fi

# =============================================================================
# RÉSULTATS FINAUX
# =============================================================================
title "RÉSULTATS FINAUX"

echo ""
echo -e "Tests exécutés: ${TOTAL_TESTS}"
echo -e "${GREEN}Tests réussis: ${PASSED_TESTS}${NC}"
echo -e "${RED}Tests échoués: ${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}${BLUE}==========================================${NC}"
    echo -e "${GREEN}✓ TON ENVIRONNEMENT EST PRÊT !${NC}"
    echo -e "${GREEN}${BLUE}==========================================${NC}"
    echo ""
    echo "Tu peux maintenant lancer le déploiement avec:"
    echo "  ./scripts/runbook.sh"
    echo ""
    echo "Ou directement un exercice avec:"
    echo "  ./scripts/phase-1-terraform-ansible.sh"
    echo ""
    echo "N'oublie pas de:"
    echo "  1. Configurer tes variables AWS"
    echo "  2. Configurer ta clé SSH"
    echo "  3. Nettoyer après chaque test (./scripts/phase-5-nettoyage.sh --auto)"
    echo ""
    exit 0
else
    echo -e "${RED}${BLUE}==========================================${NC}"
    echo -e "${RED}✗ DES PROBLÈMES ONT ÉTÉ DÉTECTÉS${NC}"
    echo -e "${RED}${BLUE}==========================================${NC}"
    echo ""
    echo "Corrige les problèmes indiqués ci-dessus avant de continuer."
    echo ""
    echo "Pour relancer ce test:"
    echo "  ./TEST_PRE_DEPLOIEMENT.sh"
    echo ""
    exit 1
fi
