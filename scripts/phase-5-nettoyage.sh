#!/bin/bash
# =============================================================================
# SCRIPT : phase-5-nettoyage.sh
# DESCRIPTION : Phase 5 - Nettoyage des ressources AWS
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/checks.sh"
source "$(dirname "$0")/utils/prompts.sh"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

PROJECT_TAG="p5-openclassrooms"

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
    echo ""
    title "AIDE : phase-5-nettoyage.sh"
    echo ""
    echo "Ce script supprime toutes les ressources AWS créées pour le projet P5."
    echo ""
    echo "Options :"
    echo "  --help, -h          Affiche cette aide"
    echo "  --auto, -a          Mode automatique (pas de confirmation)"
    echo "  --force, -f        Force le nettoyage (sans confirmation)"
    echo ""
}

# Nettoie les ressources de l'Exercice 1
cleanup_exercice_1() {
    step 1 "Nettoyage de l'Exercice 1 (Terraform + Ansible)"

    EXERCICE_1_DIR="$PROJECT_ROOT/terraform/exercice-1"

    if [ -d "$EXERCICE_1_DIR" ]; then
        cd "$EXERCICE_1_DIR" || {
            error "Impossible de se déplacer vers $EXERCICE_1_DIR"
            return 1
        }

        if check_terraform_state "."; then
            info "Suppression des ressources Terraform de l'Exercice 1..."
            if terraform destroy -auto-approve; then
                success "Ressources de l'Exercice 1 supprimées"
                rm -f terraform.tfstate terraform.tfstate.backup
            else
                error "Échec de la suppression des ressources de l'Exercice 1"
                return 1
            fi
        else
            info "Aucun state Terraform trouvé pour l'Exercice 1"
        fi

        cd - >/dev/null
    else
        info "Le dossier $EXERCICE_1_DIR n'existe pas"
    fi
}

# Nettoie les ressources de l'Exercice 2
cleanup_exercice_2() {
    step 2 "Nettoyage de l'Exercice 2 (OpenSearch)"

    EXERCICE_2_DIR="$PROJECT_ROOT/terraform/exercice-2"

    if [ -d "$EXERCICE_2_DIR" ]; then
        cd "$EXERCICE_2_DIR" || {
            error "Impossible de se déplacer vers $EXERCICE_2_DIR"
            return 1
        }

        if check_terraform_state "."; then
            info "Suppression du domaine OpenSearch..."
            if terraform destroy -auto-approve; then
                success "Domaine OpenSearch supprimé"
                rm -f terraform.tfstate terraform.tfstate.backup
            else
                error "Échec de la suppression du domaine OpenSearch"
                return 1
            fi
        else
            info "Aucun state Terraform trouvé pour l'Exercice 2"
        fi

        cd - >/dev/null
    else
        info "Le dossier $EXERCICE_2_DIR n'existe pas"
    fi
}

# Nettoie les ressources de l'Exercice 3
cleanup_exercice_3() {
    step 3 "Nettoyage de l'Exercice 3 (HAProxy)"

    EXERCICE_3_DIR="$PROJECT_ROOT/terraform/exercice-3"

    if [ -d "$EXERCICE_3_DIR" ]; then
        cd "$EXERCICE_3_DIR" || {
            error "Impossible de se déplacer vers $EXERCICE_3_DIR"
            return 1
        }

        if check_terraform_state "."; then
            info "Suppression des ressources Terraform de l'Exercice 3..."
            if terraform destroy -auto-approve; then
                success "Ressources de l'Exercice 3 supprimées"
                rm -f terraform.tfstate terraform.tfstate.backup
            else
                error "Échec de la suppression des ressources de l'Exercice 3"
                return 1
            fi
        else
            info "Aucun state Terraform trouvé pour l'Exercice 3"
        fi

        cd - >/dev/null
    else
        info "Le dossier $EXERCICE_3_DIR n'existe pas"
    fi
}

# Vérifie qu'il n'y a plus de ressources AWS
verify_cleanup() {
    step 4 "Vérification du nettoyage"

    info "Vérification qu'il n'y a plus de ressources AWS..."
    echo ""

    # Vérifier les instances EC2
    info "Vérification des instances EC2..."
    instances=$(aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=$PROJECT_TAG" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
        --query "length(Reservations[].Instances[])" --output text 2>/dev/null)
    if [ "$instances" -eq 0 ]; then
        check "Aucune instance EC2 avec le tag Project=$PROJECT_TAG"
    else
        error "Il reste $instances instance(s) EC2 avec le tag Project=$PROJECT_TAG"
        info "Exécutez : aws ec2 describe-instances --query \"Reservations[].Instances[?Tags[?Key=='Project' && Value=='$PROJECT_TAG']].[InstanceId, PublicIpAddress, State.Name]\" --output table"
    fi

    # Vérifier les domaines OpenSearch
    info "Vérification des domaines OpenSearch..."
    domains=$(aws opensearch list-domain-names --query "length(DomainNames[?starts_with(DomainName, 'p5-opensearch')])" --output text 2>/dev/null)
    if [ "$domains" -eq 0 ]; then
        check "Aucun domaine OpenSearch avec le préfixe p5-opensearch"
    else
        error "Il reste $domains domaine(s) OpenSearch avec le préfixe p5-opensearch"
        info "Exécutez : aws opensearch list-domain-names"
    fi

    echo ""
    if [ "$instances" -eq 0 ] && [ "$domains" -eq 0 ]; then
        success "Toutes les ressources AWS ont été supprimées"
    else
        warning "⚠️ Certaines ressources AWS n'ont pas été supprimées"
    fi
}

# Nettoie tout
cleanup_all() {
    title "NETTOYAGE COMPLET DES RESSOURCES AWS"
    warning "⚠️ ATTENTION : Ce script va SUPPRIMER TOUTES les ressources AWS du projet P5"

    # Nettoyer chaque exercice
    cleanup_exercice_1
    echo ""

    cleanup_exercice_2
    echo ""

    cleanup_exercice_3
    echo ""

    # Vérifier le nettoyage
    verify_cleanup
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
FORCE_MODE=false

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
        --force|-f)
            FORCE_MODE=true
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
title "PHASE 5 : NETTOYAGE DES RESSOURCES AWS"
info "Durée estimée : 30 min"
info "Objectif : Supprimer toutes les ressources AWS pour éviter des coûts inutiles"
echo ""

# Mode force (pas de confirmation)
if [ "$FORCE_MODE" = true ]; then
    warning "⚠️ MODE FORCE ACTIVÉ : Nettoyage sans confirmation"
    cleanup_all
    exit 0
fi

# Mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
    info "Mode automatique activé"
else
    info "Mode interactif activé (confirmation requise)"
    set_beginner_mode
fi

# Demander confirmation
warning "⚠️ ATTENTION : Ce script va SUPPRIMER TOUTES les ressources AWS du projet P5"
warning "Cette opération est IRRÉVERSIBLE !"

if confirm_strict "Voulez-vous VRAIMENT exécuter le nettoyage complet ?"; then
    cleanup_all
else
    info "Nettoyage annulé"
    exit 0
fi

echo ""
title "PHASE 5 TERMINÉE"
success "Nettoyage des ressources AWS terminé !"
info "Toutes les ressources ont été supprimées (ou devraient l'être)"
info "Vérifiez manuellement dans la console AWS si nécessaire"
