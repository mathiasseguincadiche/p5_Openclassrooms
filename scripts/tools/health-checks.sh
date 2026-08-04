#!/bin/bash
# =============================================================================
# SCRIPT : health-checks.sh
# DESCRIPTION : Vérifie l'état de santé de toutes les ressources du projet P5
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# VERSION : 1.0
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/../lib/colors.sh"
source "$(dirname "$0")/../lib/prompts.sh"
source "$(dirname "$0")/../lib/logging.sh"

UTILS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$UTILS_DIR/../.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

# Timeout pour les vérifications (en secondes)
CHECK_TIMEOUT=60
CHECK_INTERVAL=5

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
 echo ""
 title "AIDE : health-checks.sh"
 echo ""
 echo "Ce script vérifie l'état de santé de toutes les ressources du projet P5."
 echo ""
 echo "Options :"
 echo " --help, -h Affiche cette aide"
 echo " --auto, -a Mode automatique (pas de confirmation)"
 echo " --phase PHASE Vérifie seulement une phase spécifique (0-5)"
 echo " --quick Mode rapide (vérifications de base seulement)"
 echo " --wait, -w Attend que les ressources soient prêtes"
 echo ""
 echo "Exemples :"
 echo " ./health-checks.sh Vérifie tout"
 echo " ./health-checks.sh --phase 2 Vérifie seulement la Phase 2"
 echo " ./health-checks.sh --auto --wait Vérifie tout automatiquement en attendant"
}

# Vérifie les outils de base
check_basic_tools() {
 title "VÉRIFICATION DES OUTILS DE BASE"
 log_info "Vérification outils de base"

 local all_ok=true

 # Terraform
 if command -v terraform &> /dev/null; then
 check "Terraform est installé ($(terraform --version | head -n1))"
 log_info "Terraform installé"
 else
 error "Terraform n'est pas installé"
 log_error "Terraform non installé"
 all_ok=false
 fi

 # AWS CLI
 if command -v aws &> /dev/null; then
 check "AWS CLI est installé ($(aws --version 2>&1 | head -n1))"
 log_info "AWS CLI installé"
 else
 error "AWS CLI n'est pas installé"
 log_error "AWS CLI non installé"
 all_ok=false
 fi

 # Git
 if command -v git &> /dev/null; then
 check "Git est installé ($(git --version))"
 log_info "Git installé"
 else
 error "Git n'est pas installé"
 log_error "Git non installé"
 all_ok=false
 fi

 # Ansible
 if command -v ansible &> /dev/null; then
 check "Ansible est installé ($(ansible --version | head -n1))"
 log_info "Ansible installé"
 else
 error "Ansible n'est pas installé"
 log_error "Ansible non installé"
 all_ok=false
 fi

 # curl
 if command -v curl &> /dev/null; then
 check "curl est installé"
 log_info "curl installé"
 else
 error "curl n'est pas installé"
 log_error "curl non installé"
 all_ok=false
 fi

 # jq
 if command -v jq &> /dev/null; then
 check "jq est installé"
 log_info "jq installé"
 else
 warning "jq n'est pas installé (nécessaire pour certaines fonctionnalités)"
 log_warning "jq non installé"
 fi

 if [ "$all_ok" = true ]; then
 success "Tous les outils de base sont installés"
 log_success "Tous les outils de base installés"
 return 0
 else
 error "Certains outils de base sont manquants"
 log_error "Outils de base manquants"
 return 1
 fi
}

# Vérifie la Phase 0 (Préparation)
check_phase_0() {
 title "VÉRIFICATION DE LA PHASE 0 (PRÉPARATION)"
 log_info "Vérification Phase 0"

 local all_ok=true

 # Vérifier que le dossier du projet existe
 if [ -f "$PROJECT_ROOT/README.md" ]; then
 check "Dossier du projet existe"
 log_info "Dossier projet existe"
 else
 error "Dossier du projet introuvable"
 log_error "Dossier projet introuvable"
 all_ok=false
 fi

 # Vérifier les scripts
 for script in "phase-0-preparation.sh" "phase-1-terraform-ansible.sh" "phase-2-opensearch-kibana.sh" "phase-3-haproxy.sh" "phase-4-livrables.sh" "phase-5-nettoyage.sh"; do
 if [ -f "$(dirname "$0")/../$script" ]; then
 check "Script $script existe"
 log_info "Script $script existe"
 else
 error "Script $script introuvable"
 log_error "Script $script introuvable"
 all_ok=false
 fi
 done

 # Vérifier les utilitaires
 for util in "colors.sh" "prompts.sh" "checks.sh" "logging.sh" "kibana-api.sh" "capture-screenshots.sh"; do
 if [ -f "$(dirname "$0")/$util" ]; then
 check "Utilitaire $util existe"
 log_info "Utilitaire $util existe"
 else
 error "Utilitaire $util introuvable"
 log_error "Utilitaire $util introuvable"
 all_ok=false
 fi
 done

 if [ "$all_ok" = true ]; then
 success "Phase 0 : Tous les fichiers sont en place"
 log_success "Phase 0 OK"
 return 0
 else
 error "Phase 0 : Certains fichiers sont manquants"
 log_error "Phase 0 KO"
 return 1
 fi
}

# Vérifie la Phase 1 (Terraform + Ansible)
check_phase_1() {
 title "VÉRIFICATION DE LA PHASE 1 (TERRAFORM + ANSIBLE)"
 log_info "Vérification Phase 1"

 local all_ok=true

 # Vérifier les fichiers Terraform
 if [ -d "terraform/exercice-1" ]; then
 check "Dossier terraform/exercice-1 existe"
 log_info "Dossier terraform/exercice-1 existe"

 for file in "main.tf" "variables.tf" "outputs.tf"; do
 if [ -f "terraform/exercice-1/$file" ]; then
 check "Fichier $file existe"
 log_info "Fichier $file existe"
 else
 error "Fichier terraform/exercice-1/$file introuvable"
 log_error "Fichier $file introuvable"
 all_ok=false
 fi
 done
 else
 error "Dossier terraform/exercice-1 introuvable"
 log_error "Dossier terraform/exercice-1 introuvable"
 all_ok=false
 fi

 # Vérifier les fichiers Ansible
 if [ -d "ansible" ]; then
 check "Dossier ansible existe"
 log_info "Dossier ansible existe"

 if [ -f "ansible/playbooks/deploy.yml" ]; then
 check "Playbook deploy.yml existe"
 log_info "Playbook deploy.yml existe"
 else
 error "Playbook deploy.yml introuvable"
 log_error "Playbook deploy.yml introuvable"
 all_ok=false
 fi
 else
 error "Dossier ansible introuvable"
 log_error "Dossier ansible introuvable"
 all_ok=false
 fi

 # Vérifier si Terraform a été initialisé
 if [ -d "terraform/exercice-1/.terraform" ]; then
 check "Terraform a été initialisé"
 log_info "Terraform initialisé"
 else
 info "Terraform n'a pas encore été initialisé"
 log_info "Terraform non initialisé"
 fi

 if [ "$all_ok" = true ]; then
 success "Phase 1 : Configuration valide"
 log_success "Phase 1 OK"
 return 0
 else
 error "Phase 1 : Configuration invalide"
 log_error "Phase 1 KO"
 return 1
 fi
}

# Vérifie la Phase 2 (OpenSearch + Kibana)
check_phase_2() {
 title "VÉRIFICATION DE LA PHASE 2 (OPENSEARCH + KIBANA)"
 log_info "Vérification Phase 2"

 local all_ok=true

 # Vérifier les fichiers Terraform pour OpenSearch
 if [ -d "terraform/exercice-2" ]; then
 check "Dossier terraform/exercice-2 existe"
 log_info "Dossier terraform/exercice-2 existe"

 for file in "main.tf" "variables.tf" "outputs.tf"; do
 if [ -f "terraform/exercice-2/$file" ]; then
 check "Fichier $file existe"
 log_info "Fichier $file existe"
 else
 error "Fichier terraform/exercice-2/$file introuvable"
 log_error "Fichier $file introuvable"
 all_ok=false
 fi
 done
 else
 error "Dossier terraform/exercice-2 introuvable"
 log_error "Dossier terraform/exercice-2 introuvable"
 all_ok=false
 fi

 # Vérifier les fichiers de logs
 if [ -d "terraform/exercice-2/samples" ]; then
 check "Dossier terraform/exercice-2/samples existe"
 log_info "Dossier data existe"

 if [ -f "terraform/exercice-2/samples/nginx-access.log.sample" ]; then
 check "Fichier nginx-access.log.sample existe"
 log_info "Fichier nginx-access.log.sample existe"
 else
 warning "Fichier nginx-access.log introuvable (un exemple sera créé)"
 log_warning "Fichier nginx-access.log introuvable"
 fi
 else
 warning "Dossier terraform/exercice-2/samples introuvable"
 log_warning "Dossier data introuvable"
 fi

 # Vérifier si OpenSearch est déployé
 if [ -f "/tmp/opensearch_endpoint.txt" ]; then
 local endpoint=$(cat /tmp/opensearch_endpoint.txt)
 info "Endpoint OpenSearch : $endpoint"
 log_info "Endpoint OpenSearch: $endpoint"

 # Vérifier si le cluster est accessible
 if curl -I "$endpoint" | grep -q "HTTP/1.1 200 OK"; then
 check "Cluster OpenSearch est accessible"
 log_info "Cluster OpenSearch accessible"

 # Vérifier si Kibana est accessible
 local kibana_url="${endpoint}/_dashboards"
 if curl -I "$kibana_url" | grep -q "HTTP/1.1 200 OK"; then
 check "Kibana est accessible"
 log_info "Kibana accessible"

 # Vérifier si les logs sont chargés
 if curl -s -X GET "$endpoint/_cat/indices?v" | grep -q "nginx-access"; then
 check "Index nginx-access existe"
 log_info "Index nginx-access existe"

 local doc_count=$(curl -s -X GET "$endpoint/nginx-access-*/_count" | jq -r '.count // "0"' 2>/dev/null)
 if [ "$doc_count" -gt 0 ]; then
 check "Index contient $doc_count documents"
 log_info "Index contient $doc_count documents"
 else
 warning "Index nginx-access est vide"
 log_warning "Index vide"
 fi
 else
 warning "Index nginx-access introuvable"
 log_warning "Index introuvable"
 fi
 else
 warning "Kibana n'est pas accessible"
 log_warning "Kibana non accessible"
 fi
 fi
 else
 info "Cluster OpenSearch n'a pas encore été déployé"
 log_info "Cluster non déployé"
 fi

 if [ "$all_ok" = true ]; then
 success "Phase 2 : Configuration valide"
 log_success "Phase 2 OK"
 return 0
 else
 error "Phase 2 : Configuration invalide"
 log_error "Phase 2 KO"
 return 1
 fi
}

# Vérifie la Phase 3 (HAProxy)
check_phase_3() {
 title "VÉRIFICATION DE LA PHASE 3 (HAPROXY)"
 log_info "Vérification Phase 3"

 local all_ok=true

 # Vérifier les fichiers Terraform pour HAProxy
 if [ -d "terraform/exercice-3" ]; then
 check "Dossier terraform/exercice-3 existe"
 log_info "Dossier terraform/exercice-3 existe"

 for file in "main.tf" "variables.tf" "outputs.tf"; do
 if [ -f "terraform/exercice-3/$file" ]; then
 check "Fichier $file existe"
 log_info "Fichier $file existe"
 else
 error "Fichier terraform/exercice-3/$file introuvable"
 log_error "Fichier $file introuvable"
 all_ok=false
 fi
 done
 else
 error "Dossier terraform/exercice-3 introuvable"
 log_error "Dossier terraform/exercice-3 introuvable"
 all_ok=false
 fi

 # Vérifier si HAProxy est déployé
 if [ -f "/tmp/haproxy_url.txt" ]; then
 local haproxy_url=$(cat /tmp/haproxy_url.txt)
 info "URL HAProxy : $haproxy_url"
 log_info "URL HAProxy: $haproxy_url"

 if curl -I "$haproxy_url" | grep -q "HTTP/1.1 200 OK"; then
 check "HAProxy est accessible"
 log_info "HAProxy accessible"
 else
 warning "HAProxy n'est pas accessible"
 log_warning "HAProxy non accessible"
 fi
 else
 info "HAProxy n'a pas encore été déployé"
 log_info "HAProxy non déployé"
 fi

 if [ "$all_ok" = true ]; then
 success "Phase 3 : Configuration valide"
 log_success "Phase 3 OK"
 return 0
 else
 error "Phase 3 : Configuration invalide"
 log_error "Phase 3 KO"
 return 1
 fi
}

# Vérifie la Phase 4 (Livrables)
check_phase_4() {
 title "VÉRIFICATION DE LA PHASE 4 (LIVRABLES)"
 log_info "Vérification Phase 4"

 local all_ok=true

 # Vérifier si les captures existent
 if [ -d "captures" ]; then
 check "Dossier captures existe"
 log_info "Dossier captures existe"

 local capture_count=$(find captures -name "*.png" -o -name "*.jpg" | wc -l)
 if [ "$capture_count" -ge 4 ]; then
 check "$capture_count captures trouvées"
 log_info "$capture_count captures trouvées"
 else
 warning "Seulement $capture_count captures trouvées (4 attendues)"
 log_warning "Captures manquantes"
 all_ok=false
 fi
 else
 info "Dossier captures n'existe pas encore"
 log_info "Dossier captures inexistant"
 fi

 # Vérifier si les livrables ont été générés
 if [ -d "05_LIVRABLES" ]; then
 check "Dossier 05_LIVRABLES existe"
 log_info "Dossier 05_LIVRABLES existe"

 for dir in "Exercice_1" "Exercice_2" "Exercice_3"; do
 if [ -d "05_LIVRABLES/$dir" ]; then
 check "Dossier $dir existe"
 log_info "Dossier $dir existe"
 else
 warning "Dossier 05_LIVRABLES/$dir introuvable"
 log_warning "Dossier $dir introuvable"
 fi
 done

 # Vérifier le fichier ZIP
 if ls 05_LIVRABLES/*.zip 1> /dev/null 2>&1; then
 check "Fichier ZIP trouvé"
 log_info "Fichier ZIP trouvé"
 else
 info "Aucun fichier ZIP trouvé"
 log_info "Aucun fichier ZIP"
 fi
 else
 info "Dossier 05_LIVRABLES n'existe pas encore"
 log_info "Dossier 05_LIVRABLES inexistant"
 fi

 if [ "$all_ok" = true ]; then
 success "Phase 4 : Livrables valides"
 log_success "Phase 4 OK"
 return 0
 else
 error "Phase 4 : Livrables incomplets"
 log_error "Phase 4 KO"
 return 1
 fi
}

# Vérifie la Phase 5 (Nettoyage)
check_phase_5() {
 title "VÉRIFICATION DE LA PHASE 5 (NETTOYAGE)"
 log_info "Vérification Phase 5"

 info "La Phase 5 consiste à nettoyer les ressources AWS."
 info "Cette vérification confirme que les scripts de nettoyage existent."
 log_info "Vérification scripts nettoyage"

 if [ -f "$(dirname "$0")/../phase-5-nettoyage.sh" ]; then
 check "Script phase-5-nettoyage.sh existe"
 log_info "Script phase-5-nettoyage.sh existe"
 success "Phase 5 : Script de nettoyage disponible"
 log_success "Phase 5 OK"
 return 0
 else
 error "Script phase-5-nettoyage.sh introuvable"
 log_error "Script phase-5-nettoyage.sh introuvable"
 return 1
 fi
}

# Affiche un rapport complet
show_report() {
 echo ""
 title "RAPPORT DE SANTÉ DU PROJET P5"
 echo ""

 info "Date : $(date)"
 info "Fichier de log : /tmp/p5_logs/p5_$(date +%Y%m%d).log"
 echo ""

 info "Résumé par phase :"
 for phase in {0..5}; do
 local status="❌"
 local color="red"

 if [ "${PHASE_RESULTS[$phase]}" = "0" ]; then
 status="✅"
 color="green"
 fi

 case $phase in
 0) phase_name="Préparation" ;;
 1) phase_name="Terraform+Ansible" ;;
 2) phase_name="OpenSearch+Kibana" ;;
 3) phase_name="HAProxy" ;;
 4) phase_name="Livrables" ;;
 5) phase_name="Nettoyage" ;;
 esac

 echo -e "  ${!color}$status Phase $phase : $phase_name${NC}"
 done

 echo ""

 # Compter les succès et échecs
 local successes=0
 local failures=0
 for result in "${PHASE_RESULTS[@]}"; do
 if [ "$result" = "0" ]; then
 successes=$((successes + 1))
 else
 failures=$((failures + 1))
 fi
 done

 info "Statistiques :"
 info "  ✅ Phases réussies : $successes/6"
 info "  ❌ Phases échouées : $failures/6"
 echo ""

 if [ "$failures" -eq 0 ]; then
 success "Toutes les phases sont en bon état !"
 log_success "Toutes les phases OK"
 else
 warning "Certaines phases nécessitent votre attention"
 log_warning "Certaines phases KO"
 fi

 echo ""
 info "Recommandations :"
 if [ "${PHASE_RESULTS[0]}" != "0" ]; then
 info "  → Exécutez : ./scripts/phases/phase-0-preparation.sh"
 fi
 if [ "${PHASE_RESULTS[1]}" != "0" ]; then
 info "  → Exécutez : ./scripts/phases/phase-1-terraform-ansible.sh"
 fi
 if [ "${PHASE_RESULTS[2]}" != "0" ]; then
 info "  → Exécutez : ./scripts/phases/phase-2-opensearch-kibana.sh"
 fi
 if [ "${PHASE_RESULTS[3]}" != "0" ]; then
 info "  → Exécutez : ./scripts/phases/phase-3-haproxy.sh"
 fi
 if [ "${PHASE_RESULTS[4]}" != "0" ]; then
 info "  → Exécutez : ./scripts/phases/phase-4-livrables.sh"
 fi
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
QUICK_MODE=false
WAIT_MODE=false
TARGET_PHASE=""

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
 --phase)
 TARGET_PHASE="$2"
 shift 2
 ;;
 --quick)
 QUICK_MODE=true
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

# Initialiser le logging
init_logging

# Afficher l'en-tête
title "VÉRIFICATION DE SANTÉ DU PROJET P5"
info "Objectif : Vérifier l'état de toutes les ressources et configurations"
echo ""

# Déclarer un tableau pour stocker les résultats
declare -A PHASE_RESULTS

# Vérifier les outils de base
if [ "$QUICK_MODE" != true ]; then
 check_basic_tools
 PHASE_RESULTS[-1]=0
fi

# Vérifier toutes les phases ou une phase spécifique
if [ -z "$TARGET_PHASE" ]; then
 # Vérifier toutes les phases
 for phase in {0..5}; do
 case $phase in
 0) check_phase_0 ;;
 1) check_phase_1 ;;
 2) check_phase_2 ;;
 3) check_phase_3 ;;
 4) check_phase_4 ;;
 5) check_phase_5 ;;
 esac
 PHASE_RESULTS[$phase]=$?

 # Si on est en mode interactif, demander si on continue
 if [ "$AUTO_MODE" != true ] && [ "$phase" -lt 5 ]; then
 prompt_to_continue
 fi
done
else
 # Vérifier seulement la phase spécifiée
 case $TARGET_PHASE in
 0) check_phase_0 ;;
 1) check_phase_1 ;;
 2) check_phase_2 ;;
 3) check_phase_3 ;;
 4) check_phase_4 ;;
 5) check_phase_5 ;;
 *)
 error "Phase inconnue : $TARGET_PHASE"
 show_help
 exit 1
 ;;
 esac
 PHASE_RESULTS[$TARGET_PHASE]=$?
fi

# Afficher le rapport
show_report

echo ""
title "VÉRIFICATION TERMINÉE"
success "La vérification de santé est terminée !"
info "Consultez le rapport ci-dessus pour voir l'état de chaque phase."
info "Fichier de log complet : /tmp/p5_logs/p5_$(date +%Y%m%d).log"
