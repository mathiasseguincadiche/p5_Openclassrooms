#!/bin/bash
# =============================================================================
# FICHIER : colors.sh
# DESCRIPTION : Définition des couleurs pour les messages dans les scripts
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# Couleurs ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# =============================================================================
# FONCTIONS D'AFFICHAGE
# =============================================================================

# Affiche un message d'erreur
error() {
    echo -e "${RED}[❌ ERREUR]${NC} $1"
}

# Affiche un message de succès
success() {
    echo -e "${GREEN}[✅ SUCCÈS]${NC} $1"
}

# Affiche un message d'information
info() {
    echo -e "${BLUE}[ℹ️ INFO]${NC} $1"
}

# Affiche un message d'avertissement
warning() {
    echo -e "${YELLOW}[⚠️ ATTENTION]${NC} $1"
}

# Affiche un titre de section
title() {
    echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}\n"
}

# Affiche une sous-section
subsection() {
    echo -e "${BOLD}${MAGENTA}--- $1 ---${NC}"
}

# Affiche une commande à exécuter
command() {
    echo -e "${BOLD}${WHITE}👉 $1${NC}"
}

# Affiche un résultat
result() {
    echo -e "${GREEN}$1${NC}"
}

# Affiche une étape
step() {
    echo -e "${BOLD}${YELLOW}[Étape $1]${NC} $2"
}

# Affiche une vérification
check() {
    echo -e "${BOLD}${CYAN}[✓]${NC} $1"
}

# Affiche une question (pour confirmation)
question() {
    echo -e "${BOLD}${YELLOW}[?]${NC} $1"
}

# =============================================================================
# EXPORT DES FONCTIONS POUR LES AUTRES SCRIPTS
# =============================================================================

export RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD UNDERLINE NC

export -f error success info warning title subsection command result step check question
