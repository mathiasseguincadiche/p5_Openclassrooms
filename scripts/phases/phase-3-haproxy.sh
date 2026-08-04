#!/bin/bash
# =============================================================================
# SCRIPT : phase-3-haproxy.sh
# DESCRIPTION : Phase 3 - Déploiement HAProxy + nginxdemos/hello
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

# Charger les bibliothèques partagées
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/checks.sh"
source "$SCRIPT_DIR/../lib/prompts.sh"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

PHASE_DIR="$PROJECT_ROOT/terraform/exercice-3"
TERRAFORM_DIR="$PHASE_DIR"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
HAPROXY_CONFIG="$SCRIPTS_DIR/haproxy.cfg"

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
    echo ""
    title "AIDE : phase-3-haproxy.sh"
    echo ""
    echo "Ce script déploie HAProxy devant 2 instances de nginxdemos/hello."
    echo ""
    echo "Options :"
    echo "  --help, -h          Affiche cette aide"
    echo "  --auto, -a          Mode automatique (pas de confirmation)"
    echo "  --destroy, -d       Supprime les ressources Terraform"
    echo ""
}

# Vérifie les prérequis pour la Phase 3
check_phase_3_prerequisites() {
    title "VÉRIFICATION DES PRÉREQUIS POUR LA PHASE 3"

    step 1 "Vérification de l'environnement"
    check_terraform || exit 1
    check_ansible || exit 1
    check_aws_cli || exit 1
    check_docker || exit 1

    if [ -z "${HAPROXY_STATS_PASSWORD:-}" ]; then
        error "Définissez HAPROXY_STATS_PASSWORD avant le déploiement (16 caractères minimum)."
        info "Exemple : export HAPROXY_STATS_PASSWORD='une-phrase-secrete-longue'"
        exit 1
    fi

    if [ "${#HAPROXY_STATS_PASSWORD}" -lt 16 ]; then
        error "HAPROXY_STATS_PASSWORD doit contenir au moins 16 caractères."
        exit 1
    fi

    export TF_VAR_haproxy_stats_password="$HAPROXY_STATS_PASSWORD"

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

    step 4 "Vérification des IPs des VMs de l'Exercice 1"
    if [ -f "/tmp/vm1_ip.txt" ] && [ -f "/tmp/vm2_ip.txt" ]; then
        check "IPs des VMs de l'Exercice 1 sauvegardées"
    else
        warning "Les IPs des VMs de l'Exercice 1 ne sont pas sauvegardées"
        info "Vous devrez les récupérer manuellement"
    fi

    success "Tous les prérequis pour la Phase 3 sont validés !"
}

# Exécute Terraform init
run_terraform_init() {
    step 1 "Initialisation de Terraform"
    command "terraform init"
    if terraform -chdir="$TERRAFORM_DIR" init; then
        success "Terraform initialisé avec succès"
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
        warning "⚠️ Vérifiez que le plan contient :"
        info "  - 2 VMs backend pour nginxdemos/hello"
        info "  - 1 VM pour HAProxy"
        info "  - Les Security Groups nécessaires"
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

# Récupère les IPs des VMs backend
get_backend_ips() {
    step 4 "Récupération des IPs des VMs backend"
    command "terraform output"

    info "Récupération des IPs privées et publiques des VMs backend..."

    BACKEND_1_PRIVATE_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw hello_1_private_ip 2>/dev/null)
    BACKEND_2_PRIVATE_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw hello_2_private_ip 2>/dev/null)
    BACKEND_1_PUBLIC_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw hello_1_public_ip 2>/dev/null)
    BACKEND_2_PUBLIC_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw hello_2_public_ip 2>/dev/null)

    if [ -z "$BACKEND_1_PRIVATE_IP" ] || [ -z "$BACKEND_2_PRIVATE_IP" ] || \
       [ -z "$BACKEND_1_PUBLIC_IP" ] || [ -z "$BACKEND_2_PUBLIC_IP" ]; then
        error "Impossible de récupérer les IPs des VMs backend"
        exit 1
    fi

    success "IPs des VMs backend :"
    info "  Backend 1 : privée $BACKEND_1_PRIVATE_IP, publique $BACKEND_1_PUBLIC_IP"
    info "  Backend 2 : privée $BACKEND_2_PRIVATE_IP, publique $BACKEND_2_PUBLIC_IP"

    # Sauvegarder les IPs
    echo "$BACKEND_1_PRIVATE_IP" > /tmp/backend_1_private_ip.txt
    echo "$BACKEND_2_PRIVATE_IP" > /tmp/backend_2_private_ip.txt
    echo "$BACKEND_1_PUBLIC_IP" > /tmp/backend_1_public_ip.txt
    echo "$BACKEND_2_PUBLIC_IP" > /tmp/backend_2_public_ip.txt
}

# Génère la configuration HAProxy
generate_haproxy_config() {
    step 5 "Génération de la configuration HAProxy"

    BACKEND_1_IP=$(cat /tmp/backend_1_private_ip.txt)
    BACKEND_2_IP=$(cat /tmp/backend_2_private_ip.txt)

    command "./scripts/tools/generer-haproxy-config.sh $BACKEND_1_IP $BACKEND_2_IP"

    info "Génération de la configuration HAProxy..."
    if [ -f "$SCRIPTS_DIR/tools/generer-haproxy-config.sh" ]; then
        if bash "$SCRIPTS_DIR/tools/generer-haproxy-config.sh" "$BACKEND_1_IP" "$BACKEND_2_IP" "$HAPROXY_CONFIG"; then
            success "Configuration HAProxy générée"
            info "Le fichier a été créé sans afficher le mot de passe dans les logs."
        else
            error "Échec de la génération de la configuration HAProxy"
            exit 1
        fi
    else
        error "Le script generer-haproxy-config.sh n'existe pas"
        exit 1
    fi
}

# Récupère l'IP de HAProxy
get_haproxy_ip() {
    step 6 "Récupération de l'IP de HAProxy"
    command "terraform output haproxy_public_ip"

    info "Récupération de l'IP publique de HAProxy..."
    HAPROXY_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw haproxy_public_ip 2>/dev/null)

    if [ -z "$HAPROXY_IP" ]; then
        error "Impossible de récupérer l'IP de HAProxy"
        exit 1
    fi

    success "IP de HAProxy : $HAPROXY_IP"
    echo "$HAPROXY_IP" > /tmp/haproxy_ip.txt
}

# Déploie la configuration HAProxy sur la VM
deploy_haproxy_config() {
    step 7 "Déploiement de la configuration HAProxy"

    HAPROXY_IP=$(cat /tmp/haproxy_ip.txt)

    info "Copie de la configuration HAProxy sur la VM..."
    if scp -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new "$HAPROXY_CONFIG" ubuntu@"$HAPROXY_IP":/tmp/haproxy.cfg; then
        check "Fichier haproxy.cfg copié sur la VM"
    else
        error "Échec de la copie du fichier haproxy.cfg"
        exit 1
    fi

    info "Déploiement de la configuration HAProxy..."
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new ubuntu@"$HAPROXY_IP" \
        "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg && \
         sudo chmod 644 /etc/haproxy/haproxy.cfg"; then
        check "Configuration HAProxy déployée"
    else
        error "Échec du déploiement de la configuration HAProxy"
        exit 1
    fi
}

# Teste la configuration HAProxy
test_haproxy_config() {
    step 8 "Test de la configuration HAProxy"

    HAPROXY_IP=$(cat /tmp/haproxy_ip.txt)

    info "Test de la configuration HAProxy..."
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new ubuntu@"$HAPROXY_IP" \
        "sudo haproxy -c -f /etc/haproxy/haproxy.cfg"; then
        success "Configuration HAProxy valide"
    else
        error "Configuration HAProxy invalide"
        exit 1
    fi
}

# Redémarre HAProxy
restart_haproxy() {
    step 9 "Redémarrage de HAProxy"

    HAPROXY_IP=$(cat /tmp/haproxy_ip.txt)

    info "Redémarrage de HAProxy..."
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new ubuntu@"$HAPROXY_IP" \
        "sudo systemctl restart haproxy"; then
        success "HAProxy redémarré"
    else
        error "Échec du redémarrage de HAProxy"
        exit 1
    fi
}

# Vérifie le load balancing
verify_load_balancing() {
    step 10 "Vérification du load balancing"

    HAPROXY_IP=$(cat /tmp/haproxy_ip.txt)

    info "Test de l'alternance des Server name (10 requêtes)..."
    echo ""

    for i in {1..10}; do
        server_name=$(curl -s "http://$HAPROXY_IP" | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//')
        if [ -n "$server_name" ]; then
            echo "Requête $i : Server name = $server_name"
        else
            warning "Requête $i : Aucun Server name trouvé"
        fi
    done

    echo ""
    warning "⚠️ Vérifiez que les Server name ALTERNENT entre les 2 conteneurs"
    info "Si c'est le cas, le load balancing fonctionne correctement !"
}

# Teste la tolérance aux pannes
test_fault_tolerance() {
    step 11 "Test de la tolérance aux pannes"

    HAPROXY_IP=$(cat /tmp/haproxy_ip.txt)
    BACKEND_1_IP=$(cat /tmp/backend_1_public_ip.txt)

    info "Arrêt du conteneur nginxdemos/hello sur la VM backend 1..."
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new ubuntu@"$BACKEND_1_IP" \
        "docker stop nginx-hello"; then
        check "Conteneur nginxdemos/hello arrêté sur $BACKEND_1_IP"
    else
        warning "Impossible d'arrêter le conteneur sur $BACKEND_1_IP"
    fi

    info "Test de l'accès via HAProxy après l'arrêt du conteneur..."
    for i in {1..5}; do
        server_name=$(curl -s "http://$HAPROXY_IP" | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//')
        if [ -n "$server_name" ]; then
            echo "Requête $i : Server name = $server_name"
        else
            warning "Requête $i : Aucun Server name trouvé"
        fi
    done

    info "Toutes les requêtes devraient être servies par le même conteneur (celui qui est encore UP)"

    info "Redémarrage du conteneur..."
    if ssh -i "$HOME/.ssh/p5-key" -o StrictHostKeyChecking=accept-new ubuntu@"$BACKEND_1_IP" \
        "docker start nginx-hello"; then
        check "Conteneur nginxdemos/hello redémarré"
    else
        warning "Impossible de redémarrer le conteneur sur $BACKEND_1_IP"
    fi
}

# Affiche les instructions pour les livrables
show_livrables_instructions() {
    step 12 "Instructions pour les livrables"

    echo ""
    title "LIVRABLES POUR L'EXERCICE 3"
    echo ""
    info "1. Récupérez le fichier haproxy.cfg :"
    info "   cp $HAPROXY_CONFIG /chemin/vers/vos/livrables/SEGUIN-CADICHE_Mathias_3_haproxy_cfg_$(date +%d%m%Y).cfg"
    echo ""
    info "2. Nommez le fichier selon le format OpenClassrooms :"
    info "   SEGUIN-CADICHE_Mathias_3_haproxy_cfg_<date>.cfg"
    echo ""
    warning "⚠️ Ce fichier est OBLIGATOIRE pour le livrable OpenClassrooms"
}

# Supprime les ressources Terraform
destroy_terraform() {
    step 1 "Suppression des ressources Terraform"
    command "terraform destroy -auto-approve"

    warning "⚠️ ATTENTION : Cette opération va SUPPRIMER toutes les ressources de l'Exercice 3."
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
title "PHASE 3 : HAPROXY + NGINXDEMOS/HELLO"
info "Durée estimée : 2-3h"
info "Objectif : Déployer HAProxy devant 2 instances de nginxdemos/hello"
echo ""

# Mode destruction
if [ "$DESTROY_MODE" = true ]; then
    destroy_terraform
    exit 0
fi

# Vérifier les prérequis
check_phase_3_prerequisites

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

get_backend_ips
prompt_to_continue

generate_haproxy_config
prompt_to_continue

get_haproxy_ip
prompt_to_continue

deploy_haproxy_config
prompt_to_continue

test_haproxy_config
prompt_to_continue

restart_haproxy
prompt_to_continue

verify_load_balancing
prompt_to_continue

test_fault_tolerance
prompt_to_continue

show_livrables_instructions

echo ""
title "PHASE 3 TERMINÉE"
success "HAProxy déployé devant 2 instances de nginxdemos/hello !"
info "Prochaine étape :"
info "  1. Vérifiez que l'alternance des Server name fonctionne"
info "  2. Récupérez le fichier haproxy.cfg pour le livrable"
info "  3. Passez à la Phase 4 : ./scripts/runbook.sh → Option 4"
