#!/bin/bash
# =============================================================================
# SCRIPT : Génération Automatique de l'Inventaire Ansible
# P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code
# 
# Ce script génère automatiquement les fichiers d'inventaire Ansible
# à partir des outputs Terraform.
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Chemins des dossiers
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$BASE_DIR/terraform"
ANSIBLE_DIR="$BASE_DIR/ansible"
INVENTORY_DIR="$ANSIBLE_DIR/inventories"

# -----------------------------------------------------------------------------
# Fonctions
# -----------------------------------------------------------------------------

# Fonction pour afficher un message d'erreur
error_exit() {
    echo -e "\033[0;31m[ERREUR]\033[0m $1" >&2
    exit 1
}

# Fonction pour afficher un message de succès
success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

# Fonction pour afficher un message d'information
info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Fonction pour générer l'inventaire de l'Exercice 1
generate_exercice_1_inventory() {
    info "Génération de l'inventaire pour l'Exercice 1..."
    
    # Récupérer les IPs depuis Terraform
    cd "$TERRAFORM_DIR/exercice-1" || error_exit "Impossible de se déplacer vers $TERRAFORM_DIR/exercice-1"
    
    NGINX_1_IP=$(terraform output -raw nginx_1_public_ip 2>/dev/null)
    NGINX_2_IP=$(terraform output -raw nginx_2_public_ip 2>/dev/null)
    
    if [ -z "$NGINX_1_IP" ] || [ -z "$NGINX_2_IP" ]; then
        error_exit "Impossible de récupérer les IPs des instances NGINX. Vérifiez que Terraform a été exécuté pour l'Exercice 1."
    fi
    
    # Créer le fichier d'inventaire
    cat > "$INVENTORY_DIR/exercice-1.ini" <<EOF
# =============================================================================
# EXERCICE 1 : Inventaire Ansible
# Généré automatiquement par : $0
# Date : $(date)
# =============================================================================

[nginx_servers]
nginx-1 ansible_host=$NGINX_1_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
nginx-2 ansible_host=$NGINX_2_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[nginx_servers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
    
    success "Inventaire pour l'Exercice 1 généré : $INVENTORY_DIR/exercice-1.ini"
    cd - >/dev/null
}

# Fonction pour générer l'inventaire de l'Exercice 2
generate_exercice_2_inventory() {
    info "Génération de l'inventaire pour l'Exercice 2..."
    
    # Récupérer les IPs depuis Terraform
    cd "$TERRAFORM_DIR/exercice-1" || error_exit "Impossible de se déplacer vers $TERRAFORM_DIR/exercice-1"
    
    NGINX_1_IP=$(terraform output -raw nginx_1_public_ip 2>/dev/null)
    NGINX_2_IP=$(terraform output -raw nginx_2_public_ip 2>/dev/null)
    
    cd "$TERRAFORM_DIR/exercice-2" || error_exit "Impossible de se déplacer vers $TERRAFORM_DIR/exercice-2"
    
    OPENSEARCH_IP=$(terraform output -raw opensearch_public_ip 2>/dev/null)
    
    if [ -z "$NGINX_1_IP" ] || [ -z "$NGINX_2_IP" ] || [ -z "$OPENSEARCH_IP" ]; then
        error_exit "Impossible de récupérer les IPs. Vérifiez que Terraform a été exécuté pour les Exercices 1 et 2."
    fi
    
    # Créer le fichier d'inventaire
    cat > "$INVENTORY_DIR/exercice-2.ini" <<EOF
# =============================================================================
# EXERCICE 2 : Inventaire Ansible
# Généré automatiquement par : $0
# Date : $(date)
# =============================================================================

[opensearch_servers]
opensearch ansible_host=$OPENSEARCH_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[nginx_servers]
nginx-1 ansible_host=$NGINX_1_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
nginx-2 ansible_host=$NGINX_2_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[all_servers:children]
opensearch_servers
nginx_servers

[all_servers:vars]
ansible_python_interpreter=/usr/bin/python3

[opensearch_servers:vars]
opensearch_version=2.11.1
opensearch_home=/usr/share/opensearch
opensearch_data_dir=/var/lib/opensearch
opensearch_logs_dir=/var/log/opensearch

[opensearch_servers:vars]
logstash_version=8.11.1

[nginx_servers:vars]
filebeat_version=8.11.1
logstash_host=$OPENSEARCH_IP
logstash_port=5044
EOF
    
    success "Inventaire pour l'Exercice 2 généré : $INVENTORY_DIR/exercice-2.ini"
    cd - >/dev/null
}

# Fonction pour générer l'inventaire de l'Exercice 3
generate_exercice_3_inventory() {
    info "Génération de l'inventaire pour l'Exercice 3..."
    
    # Récupérer les IPs depuis Terraform
    cd "$TERRAFORM_DIR/exercice-1" || error_exit "Impossible de se déplacer vers $TERRAFORM_DIR/exercice-1"
    
    NGINX_1_IP=$(terraform output -raw nginx_1_public_ip 2>/dev/null)
    NGINX_2_IP=$(terraform output -raw nginx_2_public_ip 2>/dev/null)
    
    cd "$TERRAFORM_DIR/exercice-3" || error_exit "Impossible de se déplacer vers $TERRAFORM_DIR/exercice-3"
    
    HAPROXY_IP=$(terraform output -raw haproxy_public_ip 2>/dev/null)
    
    if [ -z "$NGINX_1_IP" ] || [ -z "$NGINX_2_IP" ] || [ -z "$HAPROXY_IP" ]; then
        error_exit "Impossible de récupérer les IPs. Vérifiez que Terraform a été exécuté pour les Exercices 1 et 3."
    fi
    
    # Créer le fichier d'inventaire
    cat > "$INVENTORY_DIR/exercice-3.ini" <<EOF
# =============================================================================
# EXERCICE 3 : Inventaire Ansible
# Généré automatiquement par : $0
# Date : $(date)
# =============================================================================

[haproxy_servers]
haproxy ansible_host=$HAPROXY_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[nginx_servers]
nginx-1 ansible_host=$NGINX_1_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
nginx-2 ansible_host=$NGINX_2_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[all_servers:children]
haproxy_servers
nginx_servers

[all_servers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
    
    success "Inventaire pour l'Exercice 3 généré : $INVENTORY_DIR/exercice-3.ini"
    cd - >/dev/null
}

# Fonction pour générer tous les inventaires
generate_all_inventories() {
    generate_exercice_1_inventory
    echo
    generate_exercice_2_inventory
    echo
    generate_exercice_3_inventory
}

# -----------------------------------------------------------------------------
# Script Principal
# -----------------------------------------------------------------------------

echo "=========================================================================="
echo "  SCRIPT DE GÉNÉRATION DES INVENTAIRES ANSIBLE"
echo "  P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code"
echo "=========================================================================="
echo

# Vérifier que le script est exécuté depuis le bon dossier
if [ ! -d "$TERRAFORM_DIR" ] || [ ! -d "$ANSIBLE_DIR" ]; then
    error_exit "Ce script doit être exécuté depuis la racine du projet P5 OpenClassrooms."
fi

# Vérifier qu'au moins un argument est fourni
if [ $# -eq 0 ]; then
    echo "Usage: $0 [exercice-1|exercice-2|exercice-3|all]"
    echo
    echo "Exemples :"
    echo "  $0 exercice-1    # Génère l'inventaire pour l'Exercice 1"
    echo "  $0 exercice-2    # Génère l'inventaire pour l'Exercice 2"
    echo "  $0 exercice-3    # Génère l'inventaire pour l'Exercice 3"
    echo "  $0 all           # Génère tous les inventaires"
    echo
    exit 1
fi

# Créer le répertoire des inventaires s'il n'existe pas
mkdir -p "$INVENTORY_DIR" || error_exit "Impossible de créer le répertoire $INVENTORY_DIR"

# Traiter chaque argument
for exercice in "$@"; do
    case "$exercice" in
        exercice-1|1)
            generate_exercice_1_inventory
            ;;
        exercice-2|2)
            generate_exercice_2_inventory
            ;;
        exercice-3|3)
            generate_exercice_3_inventory
            ;;
        all|tout|*)
            generate_all_inventories
            ;;
    esac
done

echo
echo "=========================================================================="
echo "  GÉNÉRATION TERMINÉE AVEC SUCCÈS"
echo "=========================================================================="
