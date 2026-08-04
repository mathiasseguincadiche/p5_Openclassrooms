#!/bin/bash
# =============================================================================
# SCRIPT : runbook.sh
# DESCRIPTION : Script maître pour lancer le projet P5 OpenClassrooms
# PROJET : Déployer et suivre l'infrastructure as code
# AUTEUR : Mathias SEGUIN-CADICHE
# =============================================================================

SCRIPTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPTS_DIR/.." && pwd)"

# Charger les bibliothèques partagées
source "$SCRIPTS_DIR/lib/colors.sh"
source "$SCRIPTS_DIR/lib/checks.sh"
source "$SCRIPTS_DIR/lib/prompts.sh"

cd "$PROJECT_ROOT" || exit 1

# =============================================================================
# FONCTIONS PRINCIPALES
# =============================================================================

# Affiche le menu principal
show_main_menu() {
    clear
    title "P5 OpenClassrooms - Déployer et suivre l'infrastructure as code"
    echo ""
    info "Bienvenue dans le runbook interactif pour votre projet P5."
    info "Ce script va vous guider pas à pas pour réaliser le projet."
    echo ""

    show_menu "MENU PRINCIPAL" \
        "0:Préparation de l'environnement (Phase 0)" \
        "1:Exercice 1 - Terraform + Ansible + interface web (Phase 1)" \
        "2:Exercice 2 - OpenSearch + Kibana + Dashboard (Phase 2)" \
        "3:Exercice 3 - HAProxy + nginxdemos/hello (Phase 3)" \
        "4:Générer les livrables (Phase 4)" \
        "5:Nettoyer les ressources AWS (Phase 5)" \
        "6:Exécuter tout le projet (Phases 0-5)" \
        "7:Vérifier l'environnement" \
        "8:Quitter"
}

# Exécute la Phase 0 : Préparation
run_phase_0() {
    title "PHASE 0 : PRÉPARATION DE L'ENVIRONNEMENT"
    info "Ce script va vérifier et configurer votre environnement."

    if confirm "Voulez-vous exécuter la Phase 0 ?"; then
        command "Exécution : ./scripts/phases/phase-0-preparation.sh"
        ./scripts/phases/phase-0-preparation.sh
    fi
}

# Exécute la Phase 1 : Exercice 1
run_phase_1() {
    title "PHASE 1 : EXERCICE 1 - TERRAFORM + ANSIBLE + INTERFACE WEB"
    info "Ce script va déployer 2 VMs AWS avec NGINX + interface web P5."

    if confirm "Voulez-vous exécuter la Phase 1 ?"; then
        command "Exécution : ./scripts/phases/phase-1-terraform-ansible.sh"
        ./scripts/phases/phase-1-terraform-ansible.sh
    fi
}

# Exécute la Phase 2 : Exercice 2
run_phase_2() {
    title "PHASE 2 : EXERCICE 2 - OPENSEARCH + KIBANA + DASHBOARD"
    info "Ce script va déployer OpenSearch + Kibana et créer un dashboard avec 3 diagrammes."

    if confirm "Voulez-vous exécuter la Phase 2 ?"; then
        command "Exécution : ./scripts/phases/phase-2-opensearch-kibana.sh"
        ./scripts/phases/phase-2-opensearch-kibana.sh
    fi
}

# Exécute la Phase 3 : Exercice 3
run_phase_3() {
    title "PHASE 3 : EXERCICE 3 - HAPROXY + NGINXDEMOS/HELLO"
    info "Ce script va déployer HAProxy devant 2 instances de nginxdemos/hello."

    if confirm "Voulez-vous exécuter la Phase 3 ?"; then
        command "Exécution : ./scripts/phases/phase-3-haproxy.sh"
        ./scripts/phases/phase-3-haproxy.sh
    fi
}

# Exécute la Phase 4 : Livrables
run_phase_4() {
    title "PHASE 4 : GÉNÉRATION DES LIVRABLES"
    info "Ce script va générer les livrables au format OpenClassrooms."

    if confirm "Voulez-vous exécuter la Phase 4 ?"; then
        command "Exécution : ./scripts/phases/phase-4-livrables.sh"
        ./scripts/phases/phase-4-livrables.sh
    fi
}

# Exécute la Phase 5 : Nettoyage
run_phase_5() {
    title "PHASE 5 : NETTOYAGE DES RESSOURCES AWS"
    warning "⚠️ ATTENTION : Ce script va SUPPRIMER toutes vos ressources AWS."

    if confirm_strict "Voulez-vous VRAIMENT exécuter la Phase 5 ?"; then
        command "Exécution : ./scripts/phases/phase-5-nettoyage.sh"
        ./scripts/phases/phase-5-nettoyage.sh
    fi
}

# Exécute toutes les phases
run_all_phases() {
    title "EXÉCUTION COMPLÈTE DU PROJET (PHASES 0-5)"
    warning "⚠️ Ce script va exécuter TOUTES les phases du projet."
    warning "Assurez-vous d'avoir le temps et les ressources nécessaires."

    if confirm_strict "Voulez-vous VRAIMENT exécuter toutes les phases ?"; then
        run_phase_0
        run_phase_1
        run_phase_2
        run_phase_3
        run_phase_4
        # Ne pas exécuter automatiquement la Phase 5 (nettoyage)
        warning "⚠️ Pensez à exécuter la Phase 5 (nettoyage) à la fin !"
    fi
}

# Vérifie l'environnement
check_environment() {
    title "VÉRIFICATION DE L'ENVIRONNEMENT"
    info "Vérification des outils et prérequis..."
    echo ""

    check_vm_devops
    check_terraform
    check_ansible
    check_aws_cli
    check_git
    check_nodejs
    check_docker

    echo ""
    if confirm "Voulez-vous exécuter une vérification plus détaillée ?"; then
        ./scripts/phases/phase-0-preparation.sh --check-only
    fi
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Vérifier que les scripts existent
for script in phase-0-preparation.sh phase-1-terraform-ansible.sh phase-2-opensearch-kibana.sh phase-3-haproxy.sh phase-4-livrables.sh phase-5-nettoyage.sh; do
    if [ ! -f "$SCRIPTS_DIR/phases/$script" ]; then
        error "Le script $script n'existe pas. Vérifiez que tous les scripts sont présents."
        exit 1
    fi
done

# Boucle principale
while true; do
    show_main_menu
    choice=$(show_menu "MENU PRINCIPAL" \
        "0:Préparation de l'environnement (Phase 0)" \
        "1:Exercice 1 - Terraform + Ansible + interface web (Phase 1)" \
        "2:Exercice 2 - OpenSearch + Kibana + Dashboard (Phase 2)" \
        "3:Exercice 3 - HAProxy + nginxdemos/hello (Phase 3)" \
        "4:Générer les livrables (Phase 4)" \
        "5:Nettoyer les ressources AWS (Phase 5)" \
        "6:Exécuter tout le projet (Phases 0-5)" \
        "7:Vérifier l'environnement" \
        "8:Quitter")

    case "$choice" in
        0)
            run_phase_0
            ;;
        1)
            run_phase_1
            ;;
        2)
            run_phase_2
            ;;
        3)
            run_phase_3
            ;;
        4)
            run_phase_4
            ;;
        5)
            run_phase_5
            ;;
        6)
            run_all_phases
            ;;
        7)
            check_environment
            ;;
        8)
            title "AU REVOIR !"
            info "Bonne continuation avec votre projet P5 OpenClassrooms !"
            exit 0
            ;;
        *)
            error "Choix invalide"
            ;;
    esac

    echo ""
    if confirm "Voulez-vous retourner au menu principal ?"; then
        continue
    else
        exit 0
    fi
done
