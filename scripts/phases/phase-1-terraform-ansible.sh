#!/bin/bash
# =============================================================================
# SCRIPT : phase-1-terraform-ansible.sh
# DESCRIPTION : Phase 1 - Déploiement avec Terraform + Ansible + interface web
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/../lib/colors.sh"
source "$(dirname "$0")/../lib/checks.sh"
source "$(dirname "$0")/../lib/prompts.sh"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

PHASE_DIR="$PROJECT_ROOT/terraform/exercice-1"
TERRAFORM_DIR="$PHASE_DIR"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
HOSTS_FILE="$ANSIBLE_DIR/inventories/hosts_aws"
PLAYBOOK_FILE="deploy.yml"

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
    echo ""
    title "AIDE : phase-1-terraform-ansible.sh"
    echo ""
    echo "Ce script déploie 2 VMs AWS avec NGINX + interface web P5."
    echo ""
    echo "Options :"
    echo "  --help, -h          Affiche cette aide"
    echo "  --auto, -a          Mode automatique (pas de confirmation)"
    echo "  --destroy, -d       Supprime les ressources Terraform"
    echo ""
}

# Vérifie les prérequis pour la Phase 1
check_phase_1_prerequisites() {
    title "VÉRIFICATION DES PRÉREQUIS POUR LA PHASE 1"

    step 1 "Vérification de l'environnement"
    check_terraform || exit 1
    check_ansible || exit 1
    check_aws_cli || exit 1
    check_git || exit 1
    check_nodejs || exit 1

    step 2 "Vérification du dossier du projet"
    check_dir_exists "$PHASE_DIR" || {
        error "Le dossier $PHASE_DIR n'existe pas"
        exit 1
    }

    step 3 "Vérification des fichiers Terraform"
    check_file_exists "$TERRAFORM_DIR/main.tf" || {
        error "Le fichier $TERRAFORM_DIR/main.tf n'existe pas"
        exit 1
    }

    step 4 "Vérification des fichiers Ansible"
    check_file_exists "$ANSIBLE_DIR/playbooks/$PLAYBOOK_FILE" || {
        error "Le fichier $ANSIBLE_DIR/playbooks/$PLAYBOOK_FILE n'existe pas"
        exit 1
    }

    success "Tous les prérequis pour la Phase 1 sont validés !"
}

# Exécute Terraform init
run_terraform_init() {
    step 1 "Initialisation de Terraform"
    command "terraform init"
    if terraform -chdir="$TERRAFORM_DIR" init; then
        success "Terraform initialisé avec succès"
        check_terraform_init "."
    else
        error "Échec de l'initialisation de Terraform"
        exit 1
    fi
}

# Exécute Terraform plan
run_terraform_plan() {
    step 2 "Vérification du plan Terraform"
    command "terraform plan"

    info "Vérification du plan Terraform..."
    if terraform -chdir="$TERRAFORM_DIR" plan; then
        success "Plan Terraform vérifié"
        warning "⚠️ Vérifiez que le plan ne contient que les ressources attendues (2 VMs, VPC, etc.)"
        if ! prompt_to_continue; then
            exit 0
        fi
    else
        error "Échec de la vérification du plan Terraform"
        exit 1
    fi
}

# Exécute Terraform apply
run_terraform_apply() {
    step 3 "Application de Terraform"
    command "terraform apply -auto-approve"

    info "Déploiement des ressources Terraform (peut prendre 5-10 min)..."
    if terraform -chdir="$TERRAFORM_DIR" apply -auto-approve; then
        success "Ressources Terraform déployées avec succès"
    else
        error "Échec du déploiement Terraform"
        exit 1
    fi
}

# Récupère les IPs des VMs
get_vm_ips() {
    step 4 "Récupération des IPs des VMs"
    command "terraform output"

    info "Récupération des IPs publiques des VMs..."
    VM1_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw nginx_1_public_ip 2>/dev/null)
    VM2_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw nginx_2_public_ip 2>/dev/null)

    if [ -z "$VM1_IP" ] || [ -z "$VM2_IP" ]; then
        error "Impossible de récupérer les IPs des VMs"
        info "Vérifiez que les outputs sont définis dans $TERRAFORM_DIR/outputs.tf"
        exit 1
    fi

    success "IPs récupérées :"
    info "  VM 1 : $VM1_IP"
    info "  VM 2 : $VM2_IP"

    # Sauvegarder les IPs dans un fichier
    echo "$VM1_IP" > /tmp/vm1_ip.txt
    echo "$VM2_IP" > /tmp/vm2_ip.txt
}

# Crée l'inventaire Ansible
create_ansible_inventory() {
    step 5 "Création de l'inventaire Ansible"

    VM1_IP=$(cat /tmp/vm1_ip.txt)
    VM2_IP=$(cat /tmp/vm2_ip.txt)

    command "nano $HOSTS_FILE"
    info "Création de l'inventaire Ansible..."

    mkdir -p "$(dirname "$HOSTS_FILE")"
    cat > "$HOSTS_FILE" <<EOF
[webservers]
${VM1_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${HOME}/.ssh/p5-key
${VM2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${HOME}/.ssh/p5-key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

    success "Inventory Ansible créé : $HOSTS_FILE"
    info "Contenu :"
    cat "$HOSTS_FILE"
}

# Teste la connexion Ansible
test_ansible_connection() {
    step 6 "Test de la connexion Ansible"
    command "ansible all -i $HOSTS_FILE -m ping"

    info "Test de la connexion Ansible..."
    if ansible all -i "$HOSTS_FILE" -m ping; then
        success "Connexion Ansible réussie pour les 2 VMs"
    else
        error "Échec de la connexion Ansible"
        info "Vérifiez :"
        info "  1. La clé SSH ~/.ssh/p5-key existe"
        info "  2. Le Security Group autorise le port 22"
        info "  3. Les VMs sont en cours d'exécution"
        exit 1
    fi
}

# Exécute le playbook Ansible
run_ansible_playbook() {
    step 7 "Exécution du playbook Ansible"
    command "ansible-playbook -i $HOSTS_FILE $ANSIBLE_DIR/playbooks/$PLAYBOOK_FILE"

    info "Exécution du playbook Ansible (peut prendre 10-15 min)..."
    if ansible-playbook -i "$HOSTS_FILE" "$ANSIBLE_DIR/playbooks/$PLAYBOOK_FILE"; then
        success "Playbook Ansible exécuté avec succès"
    else
        error "Échec de l'exécution du playbook Ansible"
        exit 1
    fi
}

# Vérifie le déploiement
verify_deployment() {
    step 8 "Vérification du déploiement"

    VM1_IP=$(cat /tmp/vm1_ip.txt)
    VM2_IP=$(cat /tmp/vm2_ip.txt)

    info "Vérification de NGINX sur les 2 VMs..."

    # Vérifier NGINX sur VM1
    if curl --fail --silent --head "http://$VM1_IP" >/dev/null; then
        check "NGINX répond sur $VM1_IP"
    else
        warning "NGINX ne répond pas sur $VM1_IP"
    fi

    # Vérifier NGINX sur VM2
    if curl --fail --silent --head "http://$VM2_IP" >/dev/null; then
        check "NGINX répond sur $VM2_IP"
    else
        warning "NGINX ne répond pas sur $VM2_IP"
    fi

    # Vérifier que l'interface P5 est servie
    info "Vérification que l'interface web P5 est servie..."
    if curl --fail --silent "http://$VM1_IP" | grep -q "Projet P5"; then
        check "Interface web P5 servie sur $VM1_IP"
    else
        warning "L'interface web P5 n'est pas servie sur $VM1_IP (page par défaut NGINX ?)"
    fi

    if curl --fail --silent "http://$VM2_IP" | grep -q "Projet P5"; then
        check "Interface web P5 servie sur $VM2_IP"
    else
        warning "L'interface web P5 n'est pas servie sur $VM2_IP (page par défaut NGINX ?)"
    fi

    success "Vérification du déploiement terminée !"
}

# Supprime les ressources Terraform
destroy_terraform() {
    step 1 "Suppression des ressources Terraform"
    command "terraform destroy -auto-approve"

    warning "⚠️ ATTENTION : Cette opération va SUPPRIMER toutes les ressources Terraform."
    if confirm_strict "Voulez-vous VRAIMENT supprimer les ressources ?"; then
        if terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve; then
            success "Ressources Terraform supprimées"
        else
            error "Échec de la suppression des ressources Terraform"
            exit 1
        fi
    fi
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
DESTROY_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --auto|-a)
            AUTO_MODE=true
            BEGINNER_MODE=0
            shift
            ;;
        --destroy|-d)
            DESTROY_MODE=true
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
title "PHASE 1 : TERRAFORM + ANSIBLE + ANGULAR"
info "Durée estimée : 4-5h"
info "Objectif : Déployer 2 VMs AWS avec NGINX + interface web P5"
echo ""

# Mode destruction
if [ "$DESTROY_MODE" = true ]; then
    destroy_terraform
    exit 0
fi

# Vérifier les prérequis
check_phase_1_prerequisites

# Mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
    info "Mode automatique activé"
else
    info "Mode interactif activé (confirmation requise à chaque étape)"
    set_beginner_mode
fi

# Exécuter les étapes
run_terraform_init
prompt_to_continue

run_terraform_plan
prompt_to_continue

run_terraform_apply
prompt_to_continue

get_vm_ips
prompt_to_continue

create_ansible_inventory
prompt_to_continue

test_ansible_connection
prompt_to_continue

run_ansible_playbook
prompt_to_continue

verify_deployment

echo ""
title "PHASE 1 TERMINÉE"
success "2 VMs AWS déployées avec NGINX + interface web P5 !"
info "Prochaine étape : ./scripts/runbook.sh → Option 2 (Exercice 2)"
info "N'oubliez pas de noter les IPs des VMs pour l'Exercice 3 !"
