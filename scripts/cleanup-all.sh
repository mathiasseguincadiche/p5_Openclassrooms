#!/bin/bash
# =============================================================================
# SCRIPT DE NETTOYAGE COMPLET
# P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code
# 
# Ce script supprime TOUTES les ressources AWS créées pour les 3 exercices
# ⚠️ ATTENTION : Ce script est DESTRUCTIF et IRREVERSIBLE !
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Chemins des dossiers Terraform
TERRAFORM_EX1="terraform/exercice-1"
TERRAFORM_EX2="terraform/exercice-2"
TERRAFORM_EX3="terraform/exercice-3"

# -----------------------------------------------------------------------------
# Fonctions
# -----------------------------------------------------------------------------

# Fonction pour afficher un message de confirmation
confirm() {
    local message="$1"
    read -p "$message (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 1
    fi
}

# Fonction pour afficher un message d'erreur
error_exit() {
    echo -e "${RED}[ERREUR]${NC} $1" >&2
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

# Fonction pour supprimer les ressources d'un exercice
cleanup_exercice() {
    local exercice="$1"
    local terraform_dir="$2"
    local exercice_name="$3"
    
    info "Nettoyage de l'Exercice $exercice : $exercice_name"
    
    # Vérifier que le dossier Terraform existe
    if [ ! -d "$terraform_dir" ]; then
        info "Le dossier $terraform_dir n'existe pas. Passage à l'exercice suivant."
        return 0
    fi
    
    # Aller dans le dossier Terraform
    cd "$terraform_dir" || error_exit "Impossible de se déplacer vers $terraform_dir"
    
    # Vérifier que le state existe
    if [ ! -f "terraform.tfstate" ]; then
        info "Aucun state Terraform trouvé pour $exercice_name. Passage à l'exercice suivant."
        cd - >/dev/null
        return 0
    fi
    
    # Afficher les ressources qui seront supprimées
    info "Ressources à supprimer pour $exercice_name :"
    terraform state list 2>/dev/null | while read -r resource; do
        echo "  - $resource"
    done
    
    # Demander confirmation
    confirm "Voulez-vous vraiment supprimer toutes les ressources de l'Exercice $exercice ?"
    
    # Supprimer les ressources
    info "Suppression des ressources Terraform pour $exercice_name..."
    terraform destroy -auto-approve || error_exit "Échec de la suppression des ressources Terraform pour $exercice_name"
    
    # Supprimer le state local
    rm -f terraform.tfstate terraform.tfstate.backup
    
    success "Toutes les ressources de l'Exercice $exercice ont été supprimées."
    
    cd - >/dev/null
}

# Fonction pour vérifier qu'il n'y a plus de ressources
verify_cleanup() {
    info "Vérification qu'il n'y a plus de ressources AWS..."
    
    # Vérifier les instances EC2
    local instances=$(aws ec2 describe-instances --query 'length(Reservations[*].Instances[?Tags[?Key==`Project` && Value==`p5-openclassrooms`]])' 2>/dev/null)
    if [ "$instances" -ne 0 ]; then
        error_exit "Il reste $instances instances EC2 avec le tag Project=p5-openclassrooms. Vérifiez manuellement."
    fi
    
    # Vérifier les VPC
    local vpcs=$(aws ec2 describe-vpcs --query 'length(Vpcs[?Tags[?Key==`Project` && Value==`p5-openclassrooms`]])' 2>/dev/null)
    if [ "$vpcs" -ne 0 ]; then
        error_exit "Il reste $vpcs VPC avec le tag Project=p5-openclassrooms. Vérifiez manuellement."
    fi
    
    # Vérifier les Security Groups
    local sgs=$(aws ec2 describe-security-groups --query 'length(SecurityGroups[?Tags[?Key==`Project` && Value==`p5-openclassrooms`]])' 2>/dev/null)
    if [ "$sgs" -ne 0 ]; then
        error_exit "Il reste $sgs Security Groups avec le tag Project=p5-openclassrooms. Vérifiez manuellement."
    fi
    
    # Vérifier les Elastic IP
    local eips=$(aws ec2 describe-addresses --query 'length(Addresses[?Tags[?Key==`Project` && Value==`p5-openclassrooms`]])' 2>/dev/null)
    if [ "$eips" -ne 0 ]; then
        error_exit "Il reste $eips Elastic IP avec le tag Project=p5-openclassrooms. Vérifiez manuellement."
    fi
    
    success "Aucune ressource AWS avec le tag Project=p5-openclassrooms n'a été trouvée."
}

# -----------------------------------------------------------------------------
# Script Principal
# -----------------------------------------------------------------------------

echo "=========================================================================="
echo "  SCRIPT DE NETTOYAGE COMPLET - P5 OpenClassrooms"
echo "=========================================================================="
echo

# Afficher un avertissement
 echo -e "${RED}⚠️  ATTENTION : Ce script va SUPPRIMER TOUTES les ressources AWS${NC}"
echo -e "${RED}   créées pour les 3 exercices du projet P5.${NC}"
echo -e "${RED}   Cette opération est IRREVERSIBLE !${NC}"
echo

# Demander confirmation finale
confirm "Voulez-vous vraiment exécuter le nettoyage complet ?"

echo

# Nettoyer chaque exercice
cleanup_exercice "1" "$TERRAFORM_EX1" "Terraform + Ansible + NGINX"
echo

cleanup_exercice "2" "$TERRAFORM_EX2" "OpenSearch (ELK)"
echo

cleanup_exercice "3" "$TERRAFORM_EX3" "HAProxy (Load Balancer)"
echo

# Vérifier le nettoyage
verify_cleanup
echo

# Message final
echo "=========================================================================="
echo -e "${GREEN}✅ NETTOYAGE TERMINÉ AVEC SUCCÈS${NC}"
echo "=========================================================================="
echo
echo "Toutes les ressources AWS ont été supprimées."
echo "Vous pouvez vérifier manuellement dans la console AWS :"
echo "  - https://console.aws.amazon.com/ec2/v2/home?region=eu-west-3#Instances"
echo "  - https://console.aws.amazon.com/vpc/home?region=eu-west-3#vpcs:"
echo
echo "Bonne continuation avec vos projets DevOps ! 🚀"
