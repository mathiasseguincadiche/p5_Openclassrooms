#!/bin/bash
# =============================================================================
# SCRIPT : phase-0-preparation.sh
# DESCRIPTION : Phase 0 - Préparation de l'environnement pour le projet P5
# PROJET : Déployer et suivre l'infrastructure as code
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/../lib/colors.sh"
source "$(dirname "$0")/../lib/checks.sh"
source "$(dirname "$0")/../lib/prompts.sh"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================


# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
    echo ""
    title "AIDE : phase-0-preparation.sh"
    echo ""
    echo "Ce script prépare votre environnement pour le projet P5 OpenClassrooms."
    echo ""
    echo "Options :"
    echo "  --help, -h          Affiche cette aide"
    echo "  --check-only, -c    Vérifie uniquement l'environnement (sans installation)"
    echo "  --auto, -a          Mode automatique (pas de confirmation)"
    echo ""
}

# Installe un package si manquant
install_package() {
    local package="$1"
    local install_cmd="$2"
    local description="$3"

    if command_exists "$package"; then
        check "$description est déjà installé"
    else
        info "Installation de $description..."
        if eval "$install_cmd"; then
            success "$description installé avec succès"
        else
            error "Échec de l'installation de $description"
            exit 1
        fi
    fi
}

# Vérifie et installe tous les prérequis
check_and_install_prerequisites() {
    title "VÉRIFICATION ET INSTALLATION DES PRÉREQUIS"

    # 1. Identifier l'hôte d'exécution
    step 1 "Vérification de la VM"
    check_vm_devops || warning "L'hôte n'est pas nommé vm-devops ; poursuite après vérification des outils."

    # 2. Vérifier qu'on est dans le bon dossier
    step 2 "Vérification du dossier du projet"
    if [ -d "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR" || exit 1
        check "Dossier du projet trouvé"
    else
        error "Le dossier $PROJECT_DIR n'existe pas."
        info "Assurez-vous d'exécuter le script depuis le dépôt P5."
        exit 1
    fi

    # 3. Installer Terraform
    step 3 "Installation de Terraform"
    install_package "terraform" "sudo apt install -y terraform" "Terraform"

    # 4. Installer Ansible
    step 4 "Installation d'Ansible"
    install_package "ansible" "sudo apt install -y ansible" "Ansible"

    # 5. Installer AWS CLI
    step 5 "Installation d'AWS CLI"
    install_package "aws" "sudo apt install -y awscli" "AWS CLI"

    # 6. Installer Git
    step 6 "Installation de Git"
    install_package "git" "sudo apt install -y git" "Git"

    # 7. Installer Node.js et npm
    step 7 "Installation de Node.js et npm"
    install_package "node" "sudo apt install -y nodejs npm" "Node.js"
    install_package "npm" "sudo apt install -y npm" "npm"

    # 8. Installer Docker
    step 8 "Installation de Docker"
    install_package "docker" "sudo apt install -y docker.io" "Docker"

    # 9. Configurer AWS CLI
    step 9 "Configuration d'AWS CLI"
    if aws sts get-caller-identity >/dev/null 2>&1; then
        check "AWS CLI est déjà configuré"
    else
        info "Configuration d'AWS CLI..."
        aws configure
        if aws sts get-caller-identity >/dev/null 2>&1; then
            success "AWS CLI configuré avec succès"
        else
            error "Échec de la configuration d'AWS CLI"
            exit 1
        fi
    fi

    # 10. Vérifier que tout est installé
    step 10 "Vérification finale"
    echo ""
    info "Vérification des versions installées..."
    terraform -version 2>&1 | head -n1
    ansible --version 2>&1 | head -n1
    aws --version 2>&1 | head -n1
    git --version 2>&1 | head -n1
    node --version 2>&1
    npm --version 2>&1
    docker --version 2>&1 | head -n1

    success "Tous les prérequis sont installés et configurés !"
}

# Vérifie uniquement l'environnement (sans installation)
check_environment_only() {
    title "VÉRIFICATION DE L'ENVIRONNEMENT"
    local failures=0

    step 1 "Vérification de la VM"
    check_vm_devops || warning "Vous n'êtes pas sur la VM vm-devops ; ce nom d'hôte est facultatif."

    step 2 "Vérification du dossier du projet"
    check_project_dir || {
        warning "La structure du dépôt est incomplète"
        failures=$((failures + 1))
    }

    step 3 "Vérification des outils"
    check_terraform || { warning "Terraform n'est pas installé ou sa version est trop ancienne"; failures=$((failures + 1)); }
    check_ansible || { warning "Ansible n'est pas installé"; failures=$((failures + 1)); }
    check_aws_cli || { warning "AWS CLI n'est pas installé ou configuré"; failures=$((failures + 1)); }
    check_git || { warning "Git n'est pas installé"; failures=$((failures + 1)); }
    check_nodejs || { warning "Node.js ou npm n'est pas installé"; failures=$((failures + 1)); }
    check_docker || { warning "Docker n'est pas installé"; failures=$((failures + 1)); }

    echo ""
    if [ "$failures" -eq 0 ]; then
        success "L'environnement est prêt pour le projet !"
    else
        error "$failures prérequis obligatoire(s) manquent."
        return 1
    fi
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --check-only|-c)
            CHECK_ONLY=true
            shift
            ;;
        --auto|-a)
            AUTO_MODE=true
            BEGINNER_MODE=0
            shift
            ;;
        *)
            error "Option inconnue : $1"
            show_help
            exit 1
            ;;
    esac
done

# Afficher l'en-tête
title "PHASE 0 : PRÉPARATION DE L'ENVIRONNEMENT"
info "Durée estimée : 30 min - 1h"
info "Objectif : Configurer votre environnement pour le projet P5"
echo ""

# Exécuter en mode vérification uniquement
if [ "$CHECK_ONLY" = true ]; then
    check_environment_only
    exit 0
fi

# Exécuter en mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
    info "Mode automatique activé"
else
    info "Mode interactif activé (confirmation requise à chaque étape)"
    set_beginner_mode
fi

# Exécuter la vérification et installation
check_and_install_prerequisites

echo ""
title "PHASE 0 TERMINÉE"
info "Votre environnement est prêt pour la Phase 1 !"
info "Prochaine étape : ./scripts/runbook.sh → Option 1 (Exercice 1)"
