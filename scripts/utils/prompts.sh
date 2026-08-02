#!/bin/bash
# =============================================================================
# FICHIER : prompts.sh
# DESCRIPTION : Fonctions pour interagir avec l'utilisateur (confirmations, choix, etc.)
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# Charger les couleurs
source "$(dirname "$0")/colors.sh"

# =============================================================================
# FONCTIONS DE CONFIRMATION
# =============================================================================

# Demande une confirmation à l'utilisateur (Oui/Non)
# $1 : Message à afficher
# Retourne 0 si Oui, 1 si Non
confirm() {
    local message="$1"
    local default="${2:-y}"  # Par défaut : Oui
    
    question "$message (O/n) "
    read -r -n 1 response
    echo
    
    case "$response" in
        [oOyY])
            return 0
            ;;
        [nN])
            return 1
            ;;
        *)
            if [[ "$default" == "y" ]]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Demande une confirmation stricte (Oui/Non, pas de défaut)
# $1 : Message à afficher
# Retourne 0 si Oui, 1 si Non
confirm_strict() {
    local message="$1"
    
    while true; do
        question "$message (O/n) "
        read -r -n 1 response
        echo
        
        case "$response" in
            [oOyY])
                return 0
                ;;
            [nN])
                return 1
                ;;
            *)
                warning "Veuillez répondre par O ou n"
                ;;
        esac
    done
}

# =============================================================================
# FONCTIONS DE CHOIX
# =============================================================================

# Demande à l'utilisateur de choisir parmi plusieurs options
# $1 : Message à afficher
# $2... : Options (séparées par des espaces)
# Retourne l'option choisie
choose() {
    local message="$1"
    shift
    local options=("$@")
    local choice
    
    echo
    question "$message"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}"
    done
    
    while true; do
        read -r -p "Votre choix [1-${#options[@]}] : " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            error "Choix invalide. Veuillez entrer un nombre entre 1 et ${#options[@]}"
        fi
    done
}

# =============================================================================
# FONCTIONS POUR LES SCRIPTS INTERACTIFS
# =============================================================================

# Affiche un menu et attend le choix de l'utilisateur
# $1 : Titre du menu
# $2... : Options (format: "clé:description")
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    local choice
    
    title "$title"
    
    for i in "${!options[@]}"; do
        local key=$(echo "${options[$i]}" | cut -d':' -f1)
        local desc=$(echo "${options[$i]}" | cut -d':' -f2-)
        echo "  $key. $desc"
    done
    
    echo
    while true; do
        read -r -p "Votre choix : " choice
        for option in "${options[@]}"; do
            local key=$(echo "$option" | cut -d':' -f1)
            if [[ "$choice" == "$key" ]]; then
                echo "$choice"
                return 0
            fi
        done
        error "Choix invalide. Veuillez réessayer."
    done
}

# Affiche une barre de progression
# $1 : Message
# $2 : Pourcentage (0-100)
progress_bar() {
    local message="$1"
    local percent="$2"
    local width=50
    local completed=$((percent * width / 100))
    local remaining=$((width - completed))
    
    info "$message"
    printf "["
    printf "${GREEN}%${completed}s${NC}" | tr ' ' '='
    printf "${RED}%${remaining}s${NC}" | tr ' ' ' '
    printf "] %d%%\n" "$percent"
}

# Affiche un compte à rebours
# $1 : Secondes
countdown() {
    local seconds="$1"
    while [ "$seconds" -gt 0 ]; do
        printf "\r${YELLOW}Attente : %d secondes${NC}" "$seconds"
        sleep 1
        seconds=$((seconds - 1))
    done
    echo
}

# =============================================================================
# FONCTIONS POUR LES MODES D'EXÉCUTION
# =============================================================================

# Vérifie si le mode débutant est activé
# Si BEGINNER_MODE=1, demande confirmation à chaque étape
BEGINNER_MODE=1

# Active/désactive le mode débutant
set_beginner_mode() {
    BEGINNER_MODE=1
    info "Mode débutant activé : confirmation requise à chaque étape"
}

set_expert_mode() {
    BEGINNER_MODE=0
    info "Mode expert activé : pas de confirmation requise"
}

# Demande si l'utilisateur veut continuer (en mode débutant)
prompt_to_continue() {
    if [ "$BEGINNER_MODE" -eq 1 ]; then
        confirm "Voulez-vous continuer ?"
        return $?
    else
        return 0
    fi
}

# =============================================================================
# EXPORT DES FONCTIONS
# =============================================================================

export BEGINNER_MODE

export -f confirm confirm_strict choose show_menu

export -f progress_bar countdown

export -f set_beginner_mode set_expert_mode prompt_to_continue
