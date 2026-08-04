#!/bin/bash
# =============================================================================
# FICHIER : checks.sh
# DESCRIPTION : Fonctions de vérification pour les scripts
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Charger les couleurs
source "$LIB_DIR/colors.sh"

# =============================================================================
# FONCTIONS DE VÉRIFICATION DES OUTILS
# =============================================================================

# Vérifie si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Vérifie si Terraform est installé
check_terraform() {
    if command_exists terraform; then
        version=$(terraform -version 2>&1 | head -n1 | cut -d' ' -f2 | tr -d 'v')
        if [ "$(printf '%s\n' "1.15.0" "$version" | sort -V | head -n1)" = "1.15.0" ]; then
            success "Terraform est installé (version: $version)"
            return 0
        else
            error "Terraform est installé mais la version est trop ancienne ($version). Version requise: >= 1.15.0"
            return 1
        fi
    else
        error "Terraform n'est pas installé. Installez-le avec: sudo apt install -y terraform"
        return 1
    fi
}

# Vérifie si Ansible est installé
check_ansible() {
    if command_exists ansible; then
        version=$(ansible --version 2>&1 | head -n1 | awk '{print $2}')
        if [[ "$version" =~ ^[0-9]+\. ]]; then
            success "Ansible est installé (version: $version)"
            return 0
        else
            error "Ansible est installé mais la version est trop ancienne ($version). Version requise: >= 2.15"
            return 1
        fi
    else
        error "Ansible n'est pas installé. Installez-le avec: sudo apt install -y ansible"
        return 1
    fi
}

# Vérifie si AWS CLI est installé et configuré
check_aws_cli() {
    if command_exists aws; then
        version=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2)
        success "AWS CLI est installé (version: $version)"

        # Vérifier la configuration
        if aws sts get-caller-identity >/dev/null 2>&1; then
            success "AWS CLI est configuré avec des credentials valides"
            return 0
        else
            error "AWS CLI est installé mais non configuré. Exécutez: aws configure"
            return 1
        fi
    else
        error "AWS CLI n'est pas installé. Installez-le avec: sudo apt install -y awscli"
        return 1
    fi
}

# Vérifie si Git est installé
check_git() {
    if command_exists git; then
        version=$(git --version 2>&1 | awk '{print $3}')
        success "Git est installé (version: $version)"
        return 0
    else
        error "Git n'est pas installé. Installez-le avec: sudo apt install -y git"
        return 1
    fi
}

# Vérifie si Node.js et npm sont installés
check_nodejs() {
    if command_exists node; then
        node_version=$(node --version 2>&1)
        success "Node.js est installé (version: $node_version)"
    else
        error "Node.js n'est pas installé. Installez-le avec: sudo apt install -y nodejs"
        return 1
    fi

    if command_exists npm; then
        npm_version=$(npm --version 2>&1)
        success "npm est installé (version: $npm_version)"
        return 0
    else
        error "npm n'est pas installé. Installez-le avec: sudo apt install -y npm"
        return 1
    fi
}

# Vérifie si Docker est installé
check_docker() {
    if command_exists docker; then
        version=$(docker --version 2>&1 | awk '{print $3}')
        success "Docker est installé (version: $version)"
        return 0
    else
        error "Docker n'est pas installé. Installez-le avec: sudo apt install -y docker.io"
        return 1
    fi
}

# =============================================================================
# FONCTIONS DE VÉRIFICATION DES PRÉREQUIS
# =============================================================================

# Vérifie si on est sur la VM vm-devops
check_vm_devops() {
    hostname=$(hostname)
    if [[ "$hostname" == "vm-devops" ]]; then
        success "Vous êtes sur la VM vm-devops"
        return 0
    else
        error "Vous n'êtes pas sur la VM vm-devops (hostname actuel: $hostname)"
        return 1
    fi
}

# Vérifie si on est dans le bon dossier
check_project_dir() {
    if [ -d "terraform/exercice-1" ] && [ -d "terraform/exercice-2" ] && \
       [ -d "terraform/exercice-3" ] && [ -d "ansible" ]; then
        success "Vous êtes dans le bon dossier du projet"
        return 0
    else
        error "Exécutez ce script depuis la racine du dépôt p5_Openclassrooms."
        return 1
    fi
}

# Vérifie si un fichier existe
check_file_exists() {
    if [ -f "$1" ]; then
        success "Le fichier $1 existe"
        return 0
    else
        error "Le fichier $1 n'existe pas"
        return 1
    fi
}

# Vérifie si un dossier existe
check_dir_exists() {
    if [ -d "$1" ]; then
        success "Le dossier $1 existe"
        return 0
    else
        error "Le dossier $1 n'existe pas"
        return 1
    fi
}

# =============================================================================
# FONCTIONS DE VÉRIFICATION DES RESSOURCES AWS
# =============================================================================

# Vérifie si un cluster OpenSearch existe
check_opensearch_domain() {
    domain_name="$1"
    if aws opensearch describe-domain --domain-name "$domain_name" >/dev/null 2>&1; then
        processing=$(aws opensearch describe-domain --domain-name "$domain_name" \
            --query "DomainStatus.Processing" --output text 2>/dev/null)
        endpoint=$(aws opensearch describe-domain --domain-name "$domain_name" \
            --query "DomainStatus.Endpoint" --output text 2>/dev/null)
        if [[ "$processing" == "False" && -n "$endpoint" && "$endpoint" != "None" ]]; then
            success "Le domaine OpenSearch $domain_name existe et est actif"
            return 0
        else
            info "Le domaine OpenSearch $domain_name existe mais sa préparation est encore en cours"
            return 1
        fi
    else
        error "Le domaine OpenSearch $domain_name n'existe pas"
        return 1
    fi
}

# Vérifie si des instances EC2 existent
check_ec2_instances() {
    project_tag="$1"
    instances=$(aws ec2 describe-instances --query "length(Reservations[].Instances[?Tags[?Key=='Project' && Value=='$project_tag']])" --output text 2>/dev/null)
    if [ "$instances" -gt 0 ]; then
        success "$instances instance(s) EC2 avec le tag Project=$project_tag existe(nt)"
        return 0
    else
        error "Aucune instance EC2 avec le tag Project=$project_tag n'existe"
        return 1
    fi
}

# =============================================================================
# FONCTIONS DE VÉRIFICATION DES SERVICES
# =============================================================================

# Vérifie si NGINX est installé et démarré
check_nginx() {
    ip="$1"
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 ubuntu@"$ip" "systemctl is-active --quiet nginx" 2>/dev/null; then
        success "NGINX est démarré sur $ip"
        return 0
    else
        error "NGINX n'est pas démarré sur $ip"
        return 1
    fi
}

# Vérifie si HAProxy est installé et démarré
check_haproxy() {
    ip="$1"
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 ubuntu@"$ip" "systemctl is-active --quiet haproxy" 2>/dev/null; then
        success "HAProxy est démarré sur $ip"
        return 0
    else
        error "HAProxy n'est pas démarré sur $ip"
        return 1
    fi
}

# Vérifie si un service répond sur un port
check_port() {
    ip="$1"
    port="$2"
    if nc -z -w 3 "$ip" "$port" 2>/dev/null; then
        success "Le port $port est ouvert sur $ip"
        return 0
    else
        error "Le port $port n'est pas ouvert sur $ip"
        return 1
    fi
}

# =============================================================================
# FONCTIONS DE VÉRIFICATION DES FICHIERS TERRAFORM
# =============================================================================

# Vérifie si Terraform a été initialisé
check_terraform_init() {
    dir="$1"
    if [ -d "$dir/.terraform" ]; then
        success "Terraform est initialisé dans $dir"
        return 0
    else
        error "Terraform n'est pas initialisé dans $dir. Exécutez: terraform init"
        return 1
    fi
}

# Vérifie si un state Terraform existe
check_terraform_state() {
    dir="$1"
    if [ -f "$dir/terraform.tfstate" ]; then
        success "Le state Terraform existe dans $dir"
        return 0
    else
        error "Le state Terraform n'existe pas dans $dir"
        return 1
    fi
}

# =============================================================================
# EXPORT DES FONCTIONS
# =============================================================================

export -f command_exists check_terraform check_ansible check_aws_cli check_git check_nodejs check_docker

export -f check_vm_devops check_project_dir check_file_exists check_dir_exists

export -f check_opensearch_domain check_ec2_instances

export -f check_nginx check_haproxy check_port

export -f check_terraform_init check_terraform_state
