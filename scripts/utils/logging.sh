#!/bin/bash
# =============================================================================
# SCRIPT : logging.sh
# DESCRIPTION : Système de logging pour le projet P5
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# Charger les couleurs
source "$(dirname "$0")/colors.sh"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

# Dossier des logs
LOG_DIR="/tmp/p5_logs"
LOG_FILE="$LOG_DIR/p5_$(date +%Y%m%d).log"

# =============================================================================
# FONCTIONS
# =============================================================================

# Initialise le système de logging
init_logging() {
 mkdir -p "$LOG_DIR"
 
 # Créer un nouveau fichier de log si ce n'est pas déjà fait aujourd'hui
 if [ ! -f "$LOG_FILE" ]; then
 echo "=== LOG DU PROJET P5 - $(date) ===" > "$LOG_FILE"
 echo "" >> "$LOG_FILE"
 fi
}

# Log une action avec timestamp
log() {
 local level="$1"
 local message="$2"
 local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 
 # Déterminer la couleur en fonction du niveau
 case "$level" in
 "INFO")
 color="blue"
 ;;
 "SUCCESS")
 color="green"
 ;;
 "WARNING")
 color="yellow"
 ;;
 "ERROR")
 color="red"
 ;;
 "DEBUG")
 color="cyan"
 ;;
 *)
 color="white"
 ;;
 esac
 
 # Afficher sur la console
 echo -e "${!color}[$timestamp] [$level] $message${NC}"
 
 # Écrire dans le fichier de log
 echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Log une info
log_info() {
 log "INFO" "$1"
}

# Log un succès
log_success() {
 log "SUCCESS" "$1"
}

# Log un avertissement
log_warning() {
 log "WARNING" "$1"
}

# Log une erreur
log_error() {
 log "ERROR" "$1"
}

# Log un debug
log_debug() {
 log "DEBUG" "$1"
}

# Affiche le fichier de log
show_log() {
 if [ -f "$LOG_FILE" ]; then
 echo ""
 title "FICHIER DE LOG : $LOG_FILE"
 echo ""
 tail -n 50 "$LOG_FILE"
 else
 info "Aucun fichier de log trouvé"
 fi
}

# Affiche les statistiques des logs
show_log_stats() {
 if [ -f "$LOG_FILE" ]; then
 echo ""
 title "STATISTIQUES DES LOGS"
 echo ""
 
 total=$(wc -l < "$LOG_FILE")
 info "Total des lignes : $total"
 
 info "Répartition par niveau :"
 for level in "INFO" "SUCCESS" "WARNING" "ERROR"; do
 count=$(grep "\[$level\]" "$LOG_FILE" | wc -l)
 info "  $level : $count"
 done
 
 # Afficher les dernières erreurs
 errors=$(grep "\[ERROR\]" "$LOG_FILE" | tail -n 5)
 if [ -n "$errors" ]; then
 echo ""
 warning "Dernières erreurs :"
 echo "$errors"
 fi
 else
 info "Aucun fichier de log trouvé"
 fi
}

# Nettoie les anciens logs
clean_old_logs() {
 info "Nettoyage des anciens logs..."
 find "$LOG_DIR" -name "*.log" -mtime +7 -delete
 log_success "Ancien logs supprimés"
}

# =============================================================================
# PROGRAMME PRINCIPAL (si exécuté directement)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
 # Afficher l'aide si des arguments sont passés
 if [ $# -gt 0 ]; then
 case "$1" in
 --help|-h)
 echo ""
 title "AIDE : logging.sh"
 echo ""
 echo "Ce script fournit des fonctions de logging pour le projet P5."
 echo ""
 echo "Fonctions disponibles :"
 echo "  init_logging Initialise le système de logging"
 echo "  log_info MESSAGE Log une information"
 echo "  log_success MESSAGE Log un succès"
 echo "  log_warning MESSAGE Log un avertissement"
 echo "  log_error MESSAGE Log une erreur"
 echo "  log_debug MESSAGE Log un message de debug"
 echo "  show_log Affiche le fichier de log"
 echo "  show_log_stats Affiche les statistiques des logs"
 echo "  clean_old_logs Nettoie les anciens logs"
 echo ""
 ;;
 --stats)
 init_logging
 show_log_stats
 ;;
 --show)
 init_logging
 show_log
 ;;
 --clean)
 clean_old_logs
 ;;
 *)
 error "Option inconnue : $1"
 ;;
 esac
 exit 0
 fi

 # Initialiser et afficher les stats
 init_logging
 show_log_stats
fi
