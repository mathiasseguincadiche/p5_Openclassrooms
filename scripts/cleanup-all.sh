#!/bin/bash
# =============================================================================
# SCRIPT DE NETTOYAGE COMPLET
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
#
# Ce script supprime TOUTES les ressources AWS créées pour les 3 exercices.
# ⚠️ ATTENTION : Ce script est DESTRUCTIF et IRREVERSIBLE !
# =============================================================================

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Chemins des dossiers (adaptés à votre environnement)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

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

# Fonction pour nettoyer un exercice
cleanup_exercice() {
    local exercice="$1"
    local dir="$2"
    local name="$3"

    info "Nettoyage de l'Exercice $exercice : $name"

    # Vérifier que le dossier existe
    if [ ! -d "$dir" ]; then
        info "Le dossier $dir n'existe pas. Passage à l'exercice suivant."
        return 0
    fi

    # Aller dans le dossier
    cd "$dir" || error_exit "Impossible de se déplacer vers $dir"

    # Vérifier que le state existe
    if [ ! -f "terraform.tfstate" ]; then
        info "Aucun state Terraform trouvé pour $name. Passage à l'exercice suivant."
        cd - >/dev/null
        return 0
    fi

    # Afficher les ressources qui seront supprimées
    info "Ressources à supprimer pour $name :"
    terraform state list 2>/dev/null | while read -r resource; do
        echo "  - $resource"
    done

    # Demander confirmation
    confirm "Voulez-vous vraiment supprimer toutes les ressources de l'Exercice $exercice ?"

    # Supprimer les ressources
    info "Suppression des ressources Terraform pour $name..."
    terraform destroy -auto-approve || error_exit "Échec de la suppression des ressources Terraform pour $name"

    # Supprimer le state local
    rm -f terraform.tfstate terraform.tfstate.backup

    success "Toutes les ressources de l'Exercice $exercice ont été supprimées."

    cd - >/dev/null
}

# Fonction pour vérifier le nettoyage
verify_cleanup() {
    info "Vérification qu'il n'y a plus de ressources AWS..."

    # Vérifier les instances EC2
    local instances
    instances=$(aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=p5-openclassrooms" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
        --query 'length(Reservations[].Instances[])' --output text 2>/dev/null)
    if [ "$instances" -ne 0 ]; then
        error_exit "Il reste $instances instances EC2 avec le tag Project=p5-openclassrooms. Vérifiez manuellement."
    fi

    # Vérifier les domaines OpenSearch
    local domains
    domains=$(aws opensearch list-domain-names \
        --query 'length(DomainNames[?starts_with(DomainName, `p5-opensearch`)])' \
        --output text 2>/dev/null)
    if [ "$domains" -ne 0 ]; then
        error_exit "Il reste $domains domaines OpenSearch avec le préfixe p5-opensearch. Vérifiez manuellement."
    fi

    success "Aucune ressource AWS avec le tag Project=p5-openclassrooms n'a été trouvée."
}

# Script Principal
echo "=========================================================================="
echo "  SCRIPT DE NETTOYAGE COMPLET - Projet P5 OpenClassrooms"
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
cleanup_exercice "1" "$PROJECT_ROOT/terraform/exercice-1" "Terraform + Ansible (NGINX)"
echo

cleanup_exercice "2" "$PROJECT_ROOT/terraform/exercice-2" "OpenSearch (ELK)"
echo

cleanup_exercice "3" "$PROJECT_ROOT/terraform/exercice-3" "HAProxy (Load Balancer)"
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
echo "  - https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances"
echo "  - https://console.aws.amazon.com/aos/home?region=us-east-1#opensearch/domains"
echo
echo "Bonne continuation avec vos projets DevOps ! 🚀"
