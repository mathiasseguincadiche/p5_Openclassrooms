#!/bin/bash
# =============================================================================
# SCRIPT : run-all.sh
# DESCRIPTION : Script "one-click" pour exécuter tout le projet de A à Z
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# VERSION : 2.0 - Avec validation pré-exécution et gestion d'erreur robuste
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/prompts.sh"
source "$(dirname "$0")/utils/logging.sh"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

SCRIPTS_DIR="$(dirname "$0")"
LOG_FILE="/tmp/p5_automation_$(date +%Y%m%d_%H%M%S).log"

# Timeout pour les vérifications (en secondes)
CHECK_TIMEOUT=300
CHECK_INTERVAL=10

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
 echo ""
 title "AIDE : run-all.sh v2.0"
 echo ""
 echo "Ce script exécute automatiquement toutes les phases du projet P5."
 echo "Il inclut maintenant une validation pré-exécution et une gestion d'erreur robuste."
 echo ""
 echo "Options :"
 echo " --help, -h Affiche cette aide"
 echo " --auto, -a Mode automatique (pas de confirmation)"
 echo " --from PHASE Commence à partir de la phase spécifiée (0-5)"
 echo " --to PHASE Termine à la phase spécifiée (0-5)"
 echo " --validate, -v Valide les prérequis avant exécution"
 echo " --health-check, -c Exécute les health checks avant de commencer"
 echo " --wait, -w Attend que les ressources soient prêtes"
 echo " --force, -f Force l'exécution même si des erreurs sont détectées"
 echo ""
 echo "Exemples :"
 echo " ./run-all.sh --auto Exécute tout automatiquement"
 echo " ./run-all.sh --from 2 --to 4 Exécute les phases 2 à 4"
 echo " ./run-all.sh --health-check --auto Vérifie la santé puis exécute"
 echo " ./run-all.sh --validate --from 2 Exécute à partir de la phase 2"
}

# Initialise le système de logging
init_logging() {
 info "Initialisation du système de logging..."
 log_info "Initialisation logging"
 echo "" > "$LOG_FILE"
 echo "=== LOG DU PROJET P5 - $(date) ===" >> "$LOG_FILE"
 echo "Mode : ${AUTO_MODE:-interactif}" >> "$LOG_FILE"
 echo "Phases : ${FROM_PHASE} à ${TO_PHASE}" >> "$LOG_FILE"
 echo "" >> "$LOG_FILE"
}

# Log une action
log_action() {
 local phase="$1"
 local action="$2"
 local status="$3"
 local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 
 echo "[$timestamp] [PHASE $phase] [$status] $action" >> "$LOG_FILE"
}

# Vérifie les prérequis globaux
check_global_prerequisites() {
 title "VÉRIFICATION DES PRÉREQUIS GLOBAUX"
 log_info "Vérification prérequis globaux"
 
 local all_ok=true
 
 # Terraform
 if ! command -v terraform &> /dev/null; then
 error "Terraform n'est pas installé"
 log_error "Terraform non installé"
 all_ok=false
 else
 check "Terraform est installé ($(terraform --version | head -n1))"
 log_info "Terraform installé"
 fi
 
 # AWS CLI
 if ! command -v aws &> /dev/null; then
 error "AWS CLI n'est pas installé"
 log_error "AWS CLI non installé"
 all_ok=false
 else
 check "AWS CLI est installé ($(aws --version 2>&1 | head -n1))"
 log_info "AWS CLI installé"
 fi
 
 # Git
 if ! command -v git &> /dev/null; then
 error "Git n'est pas installé"
 log_error "Git non installé"
 all_ok=false
 else
 check "Git est installé ($(git --version))"
 log_info "Git installé"
 fi
 
 # Ansible
 if ! command -v ansible &> /dev/null; then
 error "Ansible n'est pas installé"
 log_error "Ansible non installé"
 all_ok=false
 else
 check "Ansible est installé ($(ansible --version | head -n1))"
 log_info "Ansible installé"
 fi
 
 # curl
 if ! command -v curl &> /dev/null; then
 error "curl n'est pas installé"
 log_error "curl non installé"
 all_ok=false
 else
 check "curl est installé"
 log_info "curl installé"
 fi
 
 # jq
 if ! command -v jq &> /dev/null; then
 warning "jq n'est pas installé (nécessaire pour certaines fonctionnalités)"
 log_warning "jq non installé"
 else
 check "jq est installé"
 log_info "jq installé"
 fi
 
 if [ "$all_ok" = true ]; then
 success "Tous les prérequis globaux sont validés"
 log_success "Tous les prérequis globaux validés"
 return 0
 else
 error "Certains prérequis globaux sont manquants"
 log_error "Prérequis globaux manquants"
 return 1
 fi
}

# Vérifie les fichiers du projet
check_project_files() {
 title "VÉRIFICATION DES FICHIERS DU PROJET"
 log_info "Vérification fichiers projet"
 
 local all_ok=true
 
 # Vérifier les scripts principaux
 for script in "phase-0-preparation.sh" "phase-1-terraform-ansible.sh" "phase-2-opensearch-kibana.sh" "phase-3-haproxy.sh" "phase-4-livrables.sh" "phase-5-nettoyage.sh"; do
 if [ -f "$SCRIPTS_DIR/$script" ]; then
 check "Script $script existe"
 log_info "Script $script existe"
 else
 error "Script $script introuvable"
 log_error "Script $script introuvable"
 all_ok=false
 fi
 done
 
 # Vérifier les utilitaires
 for util in "colors.sh" "prompts.sh" "checks.sh" "logging.sh" "kibana-api.sh" "capture-screenshots.sh" "health-checks.sh"; do
 if [ -f "$SCRIPTS_DIR/utils/$util" ]; then
 check "Utilitaire $util existe"
 log_info "Utilitaire $util existe"
 else
 error "Utilitaire $util introuvable"
 log_error "Utilitaire $util introuvable"
 all_ok=false
 fi
 done
 
 # Vérifier les dossiers Terraform
 for dir in "terraform/exercice-1" "terraform/exercice-2" "terraform/exercice-3"; do
 if [ -d "$dir" ]; then
 check "Dossier $dir existe"
 log_info "Dossier $dir existe"
 else
 error "Dossier $dir introuvable"
 log_error "Dossier $dir introuvable"
 all_ok=false
 fi
 done
 
 # Vérifier Ansible
 if [ -d "ansible" ]; then
 check "Dossier ansible existe"
 log_info "Dossier ansible existe"
 else
 error "Dossier ansible introuvable"
 log_error "Dossier ansible introuvable"
 all_ok=false
 fi
 
 if [ "$all_ok" = true ]; then
 success "Tous les fichiers du projet sont en place"
 log_success "Tous les fichiers projet validés"
 return 0
 else
 error "Certains fichiers du projet sont manquants"
 log_error "Fichiers projet manquants"
 return 1
 fi
}

# Exécute les health checks
run_health_checks() {
 info "Exécution des health checks..."
 log_info "Exécution health checks"
 
 if [ -f "$SCRIPTS_DIR/utils/health-checks.sh" ]; then
 if bash "$SCRIPTS_DIR/utils/health-checks.sh" --auto; then
 success "Health checks terminés avec succès"
 log_success "Health checks réussis"
 return 0
 else
 error "Certains health checks ont échoué"
 log_error "Health checks échoués"
 return 1
 fi
 else
 error "Script health-checks.sh introuvable"
 log_error "Script health-checks.sh introuvable"
 return 1
 fi
}

# Exécute une phase
run_phase() {
 local phase_num="$1"
 local phase_name="$2"
 local phase_script="$3"
 local phase_description="$4"
 
 echo ""
 title "PHASE $phase_num : $phase_name"
 info "Description : $phase_description"
 info "Script : $phase_script"
 echo ""
 
 # Vérifier que le script existe
 if [ ! -f "$phase_script" ]; then
 error "Script introuvable : $phase_script"
 log_action "$phase_num" "Script $phase_script introuvable" "ERREUR"
 return 1
 fi
 
 # Exécuter le script
 if [ "$AUTO_MODE" = true ]; then
 info "Exécution automatique de la Phase $phase_num..."
 log_action "$phase_num" "Début de l'exécution (mode automatique)" "INFO"
 
 if bash "$phase_script" --auto >> "$LOG_FILE" 2>&1; then
 success "Phase $phase_num terminée avec succès"
 log_action "$phase_num" "Exécution terminée" "SUCCÈS"
 return 0
 else
 error "Échec de la Phase $phase_num"
 log_action "$phase_num" "Exécution échouée" "ERREUR"
 
 # Afficher les dernières lignes du log pour le dépannage
 info "Dernières erreurs dans le log :"
 tail -n 20 "$LOG_FILE" | grep -E "(error|Error|ERREUR|échec|Échec)" || info "Aucune erreur évidente dans le log"
 
 return 1
 fi
 else
 info "Exécution interactive de la Phase $phase_num..."
 log_action "$phase_num" "Début de l'exécution (mode interactif)" "INFO"
 
 if bash "$phase_script"; then
 success "Phase $phase_num terminée avec succès"
 log_action "$phase_num" "Exécution terminée" "SUCCÈS"
 return 0
 else
 error "Échec de la Phase $phase_num"
 log_action "$phase_num" "Exécution échouée" "ERREUR"
 return 1
 fi
 fi
}

# Affiche un résumé final
show_final_summary() {
 echo ""
 title "RÉSUMÉ FINAL"
 echo ""
 
 info "Fichier de log : $LOG_FILE"
 info ""
 
 # Compter les succès et échecs
 successes=$(grep "SUCCÈS" "$LOG_FILE" | wc -l)
 errors=$(grep "ERREUR" "$LOG_FILE" | wc -l)
 
 info "Statistiques :"
 info "  ✅ Succès : $successes"
 info "  ❌ Échecs : $errors"
 echo ""
 
 if [ "$errors" -eq 0 ]; then
 success "Toutes les phases ont été exécutées avec succès !"
 log_action "FINAL" "Toutes les phases réussies" "SUCCÈS"
 else
 warning "Certaines phases ont échoué. Consultez le fichier de log pour plus de détails."
 log_action "FINAL" "Certaines phases échouées" "AVERTISSEMENT"
 fi
 
 echo ""
 info "Prochaines étapes :"
 info "  1. Vérifiez le fichier de log : $LOG_FILE"
 info "  2. Vérifiez les livrables dans le dossier 05_LIVRABLES/"
 info "  3. Exécutez les health checks : ./scripts/utils/health-checks.sh"
 info "  4. Nettoyez les ressources AWS si nécessaire (Phase 5)"
}

# Affiche un rapport d'erreur
show_error_report() {
 echo ""
 title "RAPPORT D'ERREUR"
 echo ""
 
 info "Les erreurs suivantes ont été détectées :"
 echo ""
 
 # Afficher les erreurs du log
 grep "ERREUR" "$LOG_FILE" | while read -r line; do
 error "$line"
 done
 
 echo ""
 info "Pour résoudre ces erreurs :"
 info "  1. Consultez le fichier de log complet : $LOG_FILE"
 info "  2. Exécutez les health checks : ./scripts/utils/health-checks.sh"
 info "  3. Corrigez les problèmes identifiés"
 info "  4. Réexécutez avec --force pour ignorer les erreurs"
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
FROM_PHASE=0
TO_PHASE=5
VALIDATE_MODE=false
HEALTH_CHECK_MODE=false
FORCE_MODE=false
WAIT_MODE=false

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
 --from)
 FROM_PHASE="$2"
 shift 2
 ;;
 --to)
 TO_PHASE="$2"
 shift 2
 ;;
 --validate|-v)
 VALIDATE_MODE=true
 shift
 ;;
 --health-check|-c)
 HEALTH_CHECK_MODE=true
 shift
 ;;
 --force|-f)
 FORCE_MODE=true
 shift
 ;;
 --wait|-w)
 WAIT_MODE=true
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
title "SCRIPT ONE-CLICK POUR LE PROJET P5 v2.0"
info "Objectif : Exécuter toutes les phases du projet de A à Z"
info "Nouveautés : Validation pré-exécution, health checks, gestion d'erreur robuste"
echo ""

# Initialiser le logging
init_logging

# Vérifier les prérequis globaux
if [ "$VALIDATE_MODE" = true ] || [ "$HEALTH_CHECK_MODE" = true ]; then
 info "Validation des prérequis activée..."
 log_info "Validation prérequis activée"
 
 if ! check_global_prerequisites; then
 if [ "$FORCE_MODE" = false ]; then
 error "La validation des prérequis a échoué"
 show_error_report
 exit 1
 else
 warning "La validation des prérequis a échoué, mais le mode --force est activé"
 log_warning "Validation prérequis échouée, mode force activé"
 fi
 fi

 # Vérifier les fichiers du projet
 if ! check_project_files; then
 if [ "$FORCE_MODE" = false ]; then
 error "La validation des fichiers du projet a échoué"
 show_error_report
 exit 1
 else
 warning "La validation des fichiers du projet a échoué, mais le mode --force est activé"
 log_warning "Validation fichiers échouée, mode force activé"
 fi
 fi
fi

# Exécuter les health checks si demandé
if [ "$HEALTH_CHECK_MODE" = true ]; then
 if ! run_health_checks; then
 if [ "$FORCE_MODE" = false ]; then
 error "Les health checks ont détecté des problèmes"
 show_error_report
 exit 1
 else
 warning "Les health checks ont détecté des problèmes, mais le mode --force est activé"
 log_warning "Health checks échoués, mode force activé"
 fi
 fi
fi

# Vérifier les prérequis de base (toujours)
if ! check_global_prerequisites; then
 error "Les prérequis de base ne sont pas remplis"
 log_error "Prérequis de base non remplis"
 exit 1
fi

# Définir les phases
PHASES=(
 "0:Préparation:scripts/phase-0-preparation.sh:Préparation de l'environnement"
 "1:Terraform+Ansible:scripts/phase-1-terraform-ansible.sh:Déploiement des VMs avec Terraform et configuration avec Ansible"
 "2:OpenSearch+Kibana:scripts/phase-2-opensearch-kibana.sh:Déploiement OpenSearch + Kibana + Dashboard"
 "3:HAProxy:scripts/phase-3-haproxy.sh:Déploiement du load balancer HAProxy"
 "4:Livrables:scripts/phase-4-livrables.sh:Génération des livrables OpenClassrooms"
 "5:Nettoyage:scripts/phase-5-nettoyage.sh:Nettoyage des ressources AWS"
)

# Exécuter les phases
for phase in "${PHASES[@]}"; do
 phase_num=$(echo "$phase" | cut -d: -f1)
 phase_name=$(echo "$phase" | cut -d: -f2)
 phase_script=$(echo "$phase" | cut -d: -f3)
 phase_description=$(echo "$phase" | cut -d: -f4-)
 
 # Vérifier si on doit exécuter cette phase
 if [ "$phase_num" -ge "$FROM_PHASE" ] && [ "$phase_num" -le "$TO_PHASE" ]; then
 if [ "$phase_num" -eq 0 ] || [ "$phase_num" -ge "$FROM_PHASE" ]; then
 info "Début de la Phase $phase_num : $phase_name"
 log_info "Début Phase $phase_num"
 
 if run_phase "$phase_num" "$phase_name" "$SCRIPTS_DIR/$phase_script" "$phase_description"; then
 # Succès, continuer
 continue
 else
 # Échec
 if [ "$FORCE_MODE" = false ]; then
 error "Arrêt de l'exécution en raison d'une erreur dans la Phase $phase_num"
 log_action "FINAL" "Arrêt après Phase $phase_num" "ERREUR"
 show_error_report
 exit 1
 else
 warning "La Phase $phase_num a échoué, mais le mode --force est activé. Continuation..."
 log_warning "Phase $phase_num échouée, mode force activé"
 fi
 fi
 fi
 done

# Afficher le résumé final
show_final_summary

echo ""
title "PROJET P5 TERMINÉ"
success "Toutes les phases sélectionnées ont été exécutées !"
info "Fichier de log complet : $LOG_FILE"
