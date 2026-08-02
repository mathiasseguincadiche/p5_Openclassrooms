#!/bin/bash
# =============================================================================
# SCRIPT : kibana-api.sh
# DESCRIPTION : Crée automatiquement le dashboard Kibana via l'API OpenSearch
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# VERSION : 2.0 - Avec vérifications avancées et gestion d'erreur robuste
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/prompts.sh"
source "$(dirname "$0")/logging.sh"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

# URL de base pour l'API Kibana (OpenSearch Dashboards)
KIBANA_BASE_URL=""

# Nom de l'index pattern
INDEX_PATTERN="nginx-access*"

# Nom du dashboard
DASHBOARD_NAME="P5_NGINX_Logs_Dashboard"

# Timeout pour les vérifications (en secondes)
CHECK_TIMEOUT=300
CHECK_INTERVAL=10

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
 echo ""
 title "AIDE : kibana-api.sh v2.0"
 echo ""
 echo "Ce script crée automatiquement le dashboard Kibana via l'API OpenSearch."
 echo "Il vérifie automatiquement que tous les prérequis sont remplis."
 echo ""
 echo "Options :"
 echo " --help, -h Affiche cette aide"
 echo " --url URL Spécifie l'URL de Kibana"
 echo " --index-pattern PATTERN Spécifie l'index pattern (défaut: $INDEX_PATTERN)"
 echo " --dashboard-name NAME Spécifie le nom du dashboard (défaut: $DASHBOARD_NAME)"
 echo " --auto, -a Mode automatique (pas de confirmation)"
 echo " --force, -f Force la création (écrase si existe)"
 echo " --wait, -w Attend que les logs soient chargés (timeout: ${CHECK_TIMEOUT}s)"
 echo ""
 echo "Exemple :"
 echo " ./kibana-api.sh --url https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_dashboards"
 echo " ./kibana-api.sh --url https://... --auto --wait"
}

# Vérifie que curl est installé
check_curl() {
 if ! command -v curl &> /dev/null; then
 error "curl n'est pas installé. Installez-le avec : sudo apt install -y curl"
 log_error "curl non installé"
 exit 1
 fi
 log_info "curl est installé"
}

# Vérifie que jq est installé
check_jq() {
 if ! command -v jq &> /dev/null; then
 info "Installation de jq..."
 log_info "Installation de jq"
 sudo apt install -y jq || {
 error "Échec de l'installation de jq"
 log_error "Échec installation jq"
 exit 1
 }
 log_info "jq installé"
 fi
}

# Configure l'URL de Kibana
configure_kibana_url() {
 if [ -z "$KIBANA_BASE_URL" ]; then
 # Essayer de récupérer l'URL depuis le fichier temporaire
 if [ -f "/tmp/kibana_url.txt" ]; then
 KIBANA_BASE_URL=$(cat /tmp/kibana_url.txt)
 info "URL de Kibana récupérée depuis /tmp/kibana_url.txt : $KIBANA_BASE_URL"
 log_info "URL récupérée depuis /tmp/kibana_url.txt"
 else
 # Demander à l'utilisateur
 question "Entrez l'URL de Kibana (ex: https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_dashboards) :"
 read -r KIBANA_BASE_URL
 fi
 fi
 
 # Vérifier que l'URL se termine par /_dashboards
 if [[ ! "$KIBANA_BASE_URL" == *"_dashboards"* ]]; then
 KIBANA_BASE_URL="${KIBANA_BASE_URL}/_dashboards"
 info "URL corrigée : $KIBANA_BASE_URL"
 log_info "URL corrigée: $KIBANA_BASE_URL"
 fi
 
 # Extraire l'URL de base (sans /_dashboards)
 BASE_URL=$(echo "$KIBANA_BASE_URL" | sed 's|/_dashboards$||')
 API_URL="$BASE_URL"
 
 # Sauvegarder l'URL pour les autres scripts
 echo "$KIBANA_BASE_URL" > /tmp/kibana_url.txt
 echo "$BASE_URL" > /tmp/opensearch_endpoint.txt
 log_info "URLs sauvegardées dans /tmp/"
}

# Vérifie que Kibana est accessible
check_kibana_access() {
 info "Vérification de l'accès à Kibana..."
 log_info "Vérification accès Kibana"
 
 local start_time=$(date +%s)
 while true; do
 if curl -k -I "$KIBANA_BASE_URL" | grep -q "HTTP/1.1 200 OK"; then
 success "Kibana est accessible"
 log_success "Kibana accessible"
 return 0
 else
 local current_time=$(date +%s)
 local elapsed=$((current_time - start_time))
 
 if [ "$elapsed" -ge "$CHECK_TIMEOUT" ]; then
 error "Timeout atteint ($CHECK_TIMEOUT s). Kibana n'est pas accessible."
 log_error "Timeout accès Kibana"
 info "Vérifiez :"
 info "  1. Le cluster OpenSearch est-il actif ?"
 info "  2. L'access policy est-elle correctement configurée ?"
 info "  3. Votre IP est-elle autorisée ?"
 info "  4. URL correcte : $KIBANA_BASE_URL"
 exit 1
 fi
 
 info "Kibana non accessible. Attente de $CHECK_INTERVAL secondes... (${elapsed}s/${CHECK_TIMEOUT}s)"
 sleep $CHECK_INTERVAL
 fi
 done
}

# Vérifie que l'index existe et contient des données
check_index_exists() {
 info "Vérification de l'existence de l'index $INDEX_PATTERN..."
 log_info "Vérification index $INDEX_PATTERN"
 
 local start_time=$(date +%s)
 while true; do
 local index_response=$(curl -k -s -X GET "$API_URL/_cat/indices/$INDEX_PATTERN?v" 2>/dev/null)
 
 if echo "$index_response" | grep -q "nginx-access"; then
 success "Index $INDEX_PATTERN trouvé"
 log_success "Index trouvé"
 return 0
 else
 local current_time=$(date +%s)
 local elapsed=$((current_time - start_time))
 
 if [ "$WAIT_MODE" = true ] && [ "$elapsed" -lt "$CHECK_TIMEOUT" ]; then
 info "Index non trouvé. Attente de $CHECK_INTERVAL secondes... (${elapsed}s/${CHECK_TIMEOUT}s)"
 info "Astuce : Exécutez d'abord phase-2-opensearch-kibana.sh pour charger les logs"
 sleep $CHECK_INTERVAL
 continue
 fi
 
 error "Index $INDEX_PATTERN introuvable dans OpenSearch"
 log_error "Index $INDEX_PATTERN introuvable"
 info "Solutions :"
 info "  1. Exécutez : ./scripts/phase-2-opensearch-kibana.sh"
 info "  2. Vérifiez que les logs ont été chargés"
 info "  3. Utilisez --wait pour attendre automatiquement"
 exit 1
 fi
 done
}

# Vérifie que l'index contient des données
check_index_has_data() {
 info "Vérification que l'index contient des données..."
 log_info "Vérification données dans l'index"
 
 local start_time=$(date +%s)
 while true; do
 local count_response=$(curl -k -s -X GET "$API_URL/$INDEX_PATTERN/_count" 2>/dev/null)
 local doc_count=$(echo "$count_response" | jq -r '.count // "0"' 2>/dev/null)
 
 if [ "$doc_count" -gt 0 ]; then
 success "Index contient $doc_count documents"
 log_success "Index contient $doc_count documents"
 return 0
 else
 local current_time=$(date +%s)
 local elapsed=$((current_time - start_time))
 
 if [ "$WAIT_MODE" = true ] && [ "$elapsed" -lt "$CHECK_TIMEOUT" ]; then
 info "Aucune donnée trouvée. Attente de $CHECK_INTERVAL secondes... (${elapsed}s/${CHECK_TIMEOUT}s)"
 info "Astuce : Les logs sont en cours de chargement par phase-2-opensearch-kibana.sh"
 sleep $CHECK_INTERVAL
 continue
 fi
 
 error "L'index $INDEX_PATTERN est vide (0 document)"
 log_error "Index vide"
 info "Solutions :"
 info "  1. Vérifiez que les logs NGINX ont été chargés"
 info "  2. Exécutez : ./scripts/phase-2-opensearch-kibana.sh"
 info "  3. Utilisez --wait pour attendre automatiquement"
 exit 1
 fi
 done
}

# Vérifie que les champs requis existent dans l'index
check_required_fields() {
 info "Vérification des champs requis dans l'index..."
 log_info "Vérification champs requis"
 
 local required_fields=("@timestamp" "method" "url" "status" "size" "client_ip")
 local missing_fields=()
 
 for field in "${required_fields[@]}"; do
 if ! curl -k -s -X GET "$API_URL/$INDEX_PATTERN/_mapping" | jq -e ".$INDEX_PATTERN.mappings.properties.\"$field\"" >/dev/null 2>&1; then
 missing_fields+=("$field")
 fi
 done
 
 if [ ${#missing_fields[@]} -eq 0 ]; then
 success "Tous les champs requis sont présents"
 log_success "Tous les champs requis présents"
 return 0
 else
 error "Champs manquants : ${missing_fields[*]}"
 log_error "Champs manquants: ${missing_fields[*]}"
 info "Vérifiez le format de vos logs NGINX"
 info "Format attendu : IP - - [DATE] \"METHOD URL HTTP/1.1\" STATUS SIZE"
 exit 1
 fi
}

# Vérifie si le dashboard existe déjà
check_dashboard_exists() {
 local existing_dashboard=$(curl -k -s -X GET "$API_URL/api/saved_objects/dashboard" | \
 jq -r ".saved_objects[] | select(.attributes.title == \"$DASHBOARD_NAME\") | .id" 2>/dev/null)
 
 if [ -n "$existing_dashboard" ]; then
 if [ "$FORCE_MODE" = true ]; then
 warning "Dashboard $DASHBOARD_NAME existe déjà (ID: $existing_dashboard). Mode --force activé, écrasement."
 log_warning "Dashboard existe, écrasement forcé"
 return 1
 else
 warning "Dashboard $DASHBOARD_NAME existe déjà (ID: $existing_dashboard)"
 log_warning "Dashboard existe déjà"
 if confirm "Voulez-vous le recréer (écraser l'existant) ?"; then
 FORCE_MODE=true
 return 1
 else
 info "Utilisation du dashboard existant : $KIBANA_BASE_URL/app/dashboards#/view/$existing_dashboard"
 log_info "Utilisation dashboard existant"
 exit 0
 fi
 fi
 fi
 return 0
}

# Crée un index pattern
create_index_pattern() {
 info "Création de l'index pattern : $INDEX_PATTERN"
 log_info "Création index pattern $INDEX_PATTERN"
 
 # Vérifier si l'index pattern existe déjà
 local existing_pattern=$(curl -k -s -X GET "$API_URL/api/saved_objects/index-pattern" | \
 jq -r ".saved_objects[] | select(.attributes.title == \"$INDEX_PATTERN\") | .id" 2>/dev/null)
 
 if [ -n "$existing_pattern" ]; then
 info "Index pattern $INDEX_PATTERN existe déjà (ID: $existing_pattern)"
 log_info "Index pattern existe déjà"
 return 0
 fi
 
 # Créer l'index pattern
 response=$(curl -k -s -X POST "$API_URL/api/saved_objects/index-pattern" \
 -H "Content-Type: application/json" \
 -H "kbn-xsrf: true" \
 -d "{
 \"attributes\": {
 \"title\": \"$INDEX_PATTERN\",
 \"timeFieldName\": \"@timestamp\"
 }
 }")
 
 if echo "$response" | jq -e ".id" >/dev/null 2>&1; then
 success "Index pattern créé : $INDEX_PATTERN"
 log_success "Index pattern créé"
 else
 error "Échec de la création de l'index pattern"
 log_error "Échec création index pattern"
 info "Réponse : $response"
 exit 1
 fi
}

# Crée une visualisation (diagramme)
create_visualization() {
 local vis_type="$1"
 local vis_name="$2"
 local vis_json="$3"
 
 info "Création de la visualisation : $vis_name (type: $vis_type)"
 log_info "Création visualisation $vis_name"
 
 # Vérifier si la visualisation existe déjà
 local existing_vis=$(curl -k -s -X GET "$API_URL/api/saved_objects/visualization" | \
 jq -r ".saved_objects[] | select(.attributes.title == \"$vis_name\") | .id" 2>/dev/null)
 
 if [ -n "$existing_vis" ] && [ "$FORCE_MODE" != true ]; then
 info "Visualisation $vis_name existe déjà (ID: $existing_vis)"
 log_info "Visualisation existe déjà"
 echo "$existing_vis"
 return 0
 fi
 
 response=$(curl -k -s -X POST "$API_URL/api/saved_objects/visualization" \
 -H "Content-Type: application/json" \
 -H "kbn-xsrf: true" \
 -d "$vis_json")
 
 if echo "$response" | jq -e ".id" >/dev/null 2>&1; then
 success "Visualisation créée : $vis_name"
 log_success "Visualisation $vis_name créée"
 echo "$response" | jq -r ".id"
 else
 error "Échec de la création de la visualisation : $vis_name"
 log_error "Échec création visualisation $vis_name"
 info "Réponse : $response"
 exit 1
 fi
}

# Crée le diagramme Donut (Répartition des verbes HTTP)
create_donut_chart() {
 info "Création du diagramme Donut : Répartition des verbes HTTP"
 log_info "Création diagramme Donut"
 
 donut_json=$(jq -n --arg title "Répartition des verbes HTTP" \
 --arg index "$INDEX_PATTERN" \
 '{
 "attributes": {
 "title": $title,
 "visState": "{\"type\":\"pie\",\"params\":{\"type\":\"pie\",\"addTooltip\":true,\"addLegend\":true,\"isDonut\":true,\"labels\":{\"show\":true,\"truncate\":100,\"values\":true},\"dimensions\":{\"width\":600,\"height\":400},\"metrics\":[{\"type\":\"count\",\"id\":\"1\"}],\"buckets\":[{\"type\":\"terms\",\"id\":\"2\",\"field\":\"method\",\"size\":5,\"order\":\"desc\",\"orderBy\":\"1\"}],\"query\":{\"language\":\"kuery\",\"query\":\"\"}},\"aggs\":[]},\"uiStateJSON\":\"{}\"}",
 "searchSourceJSON": "{\"index\":$index,\"query\":{\"language\":\"kuery\",\"query\":\"\"}}",
 "savedSearchId": null
 }
 }')
 
 create_visualization "pie" "Répartition des verbes HTTP" "$donut_json"
}

# Crée le diagramme Histogram (Quantité cumulée de données par tranche de 12h)
create_histogram_chart() {
 info "Création du diagramme Histogram : Quantité cumulée de données par tranche de 12h"
 log_info "Création diagramme Histogram"
 
 histogram_json=$(jq -n --arg title "Quantité cumulée de données par tranche de 12h" \
 --arg index "$INDEX_PATTERN" \
 '{
 "attributes": {
 "title": $title,
 "visState": "{\"type\":\"histogram\",\"params\":{\"type\":\"histogram\",\"grid\":{\"categoryLines\":false,\"valueAxis\":\"\"},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{\"axis\":{\"show\":true},\"labels\":{\"show\":true,\"truncate\":100},\"title\":{\"text\":\"Tranches de 12h\"}}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{\"axis\":{\"show\":true},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"Quantité cumulée de données (octets)\"}}}],\"seriesParams\":[{\"show\":\"total\",\"type\":\"histogram\",\"mode\":\"stacked\",\"series\":[{\"id\":\"1\",\"label\":\"Quantité cumulée\",\"color\":\"#34130C\",\"splitMode\":\"filters\",\"filter\":\"\",\"metrics\":[{\"type\":\"sum\",\"id\":\"1\"}],\"separateAxis\":0,\"axisPosition\":\"left\"}],\"add_time_marker\":false,\"threshold_line\":{\"show\":false},\"add_legend\":true,\"legend_position\":\"right\",\"times\":[],\"add_tooltip\":true,\"scale\":\"linear\",\"mode\":\"grouped\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"sum\",\"schema\":\"metric\",\"params\":{\"field\":\"size\",\"customLabel\":\"Quantité cumulée\"}}],\"buckets\":[{\"id\":\"2\",\"enabled\":true,\"type\":\"date_histogram\",\"schema\":\"segment\",\"params\":{\"field\":\"@timestamp\",\"useNormalizedEsInterval\":true,\"interval\":\"12h\",\"drop_last_bucket\":false,\"min_doc_count\":1,\"extended_bounds\":{}}}],\"query\":{\"language\":\"kuery\",\"query\":\"\"}},\"uiStateJSON\":\"{}\"}",
 "searchSourceJSON": "{\"index\":$index,\"query\":{\"language\":\"kuery\",\"query\":\"\"}}",
 "savedSearchId": null
 }
 }')
 
 create_visualization "histogram" "Quantité cumulée de données par tranche de 12h" "$histogram_json"
}

# Crée le diagramme Histogram cumulé (Top 5 des requêtes par tranche de 12h)
create_cumulative_histogram() {
 info "Création du diagramme Histogram cumulé : Top 5 des requêtes par tranche de 12h"
 log_info "Création diagramme Histogram cumulé"
 
 cumulative_json=$(jq -n --arg title "Top 5 des requêtes par tranche de 12h (cumul)" \
 --arg index "$INDEX_PATTERN" \
 '{
 "attributes": {
 "title": $title,
 "visState": "{\"type\":\"histogram\",\"params\":{\"type\":\"histogram\",\"grid\":{\"categoryLines\":false,\"valueAxis\":\"\"},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{\"axis\":{\"show\":true},\"labels\":{\"show\":true,\"truncate\":100},\"title\":{\"text\":\"Tranches de 12h\"}}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{\"axis\":{\"show\":true},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"Nombre de requêtes\"}}}],\"seriesParams\":[{\"show\":\"total\",\"type\":\"histogram\",\"mode\":\"stacked\",\"series\":[{\"id\":\"1\",\"label\":\"Requête 1\",\"color\":\"#34130C\",\"splitMode\":\"filters\",\"filter\":\"url:\"\/index.html\"\",\"metrics\":[{\"type\":\"count\",\"id\":\"1\"}],\"separateAxis\":0,\"axisPosition\":\"left\"},{\"id\":\"2\",\"label\":\"Requête 2\",\"color\":\"#68BC00\",\"splitMode\":\"filters\",\"filter\":\"url:\"\/about\"\",\"metrics\":[{\"type\":\"count\",\"id\":\"1\"}],\"separateAxis\":0,\"axisPosition\":\"left\"},{\"id\":\"3\",\"label\":\"Requête 3\",\"color\":\"#2090C0\",\"splitMode\":\"filters\",\"filter\":\"url:\"\/contact\"\",\"metrics\":[{\"type\":\"count\",\"id\":\"1\"}],\"separateAxis\":0,\"axisPosition\":\"left\"},{\"id\":\"4\",\"label\":\"Requête 4\",\"color\":\"#E56FA8\",\"splitMode\":\"filters\",\"filter\":\"url:\"\/products\"\",\"metrics\":[{\"type\":\"count\",\"id\":\"1\"}],\"separateAxis\":0,\"axisPosition\":\"left\"},{\"id\":\"5\",\"label\":\"Requête 5\",\"color\":\"#D93F3C\",\"splitMode\":\"filters\",\"filter\":\"url:\"\/api\"\",\"metrics\":[{\"type\":\"count\",\"id\":\"1\"}],\"separateAxis\":0,\"axisPosition\":\"left\"}],\"add_time_marker\":false,\"threshold_line\":{\"show\":false},\"add_legend\":true,\"legend_position\":\"right\",\"times\":[],\"add_tooltip\":true,\"scale\":\"linear\",\"mode\":\"grouped\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"field\":\"_count\",\"customLabel\":\"Nombre de requêtes\"}}],\"buckets\":[{\"id\":\"2\",\"enabled\":true,\"type\":\"date_histogram\",\"schema\":\"segment\",\"params\":{\"field\":\"@timestamp\",\"useNormalizedEsInterval\":true,\"interval\":\"12h\",\"drop_last_bucket\":false,\"min_doc_count\":1,\"extended_bounds\":{}}}],\"query\":{\"language\":\"kuery\",\"query\":\"\"},\"uiStateJSON\":\"{}\"}",
 "searchSourceJSON": "{\"index\":$index,\"query\":{\"language\":\"kuery\",\"query\":\"\"}}",
 "savedSearchId": null
 }
 }')
 
 create_visualization "histogram" "Top 5 des requêtes par tranche de 12h (cumul)" "$cumulative_json"
}

# Crée le dashboard avec les 3 visualisations
create_dashboard() {
 info "Création du dashboard : $DASHBOARD_NAME"
 log_info "Création dashboard $DASHBOARD_NAME"
 
 # Récupérer les IDs des visualisations
 DONUT_ID=$(curl -k -s -X GET "$API_URL/api/saved_objects/visualization" | \
 jq -r ".saved_objects[] | select(.attributes.title == \"Répartition des verbes HTTP\") | .id")
 
 HISTOGRAM_ID=$(curl -k -s -X GET "$API_URL/api/saved_objects/visualization" | \
 jq -r ".saved_objects[] | select(.attributes.title == \"Quantité cumulée de données par tranche de 12h\") | .id")
 
 CUMULATIVE_ID=$(curl -k -s -X GET "$API_URL/api/saved_objects/visualization" | \
 jq -r ".saved_objects[] | select(.attributes.title == \"Top 5 des requêtes par tranche de 12h (cumul)\") | .id")
 
 if [ -z "$DONUT_ID" ] || [ -z "$HISTOGRAM_ID" ] || [ -z "$CUMULATIVE_ID" ]; then
 error "Impossible de récupérer les IDs des visualisations"
 log_error "IDs visualisations introuvables"
 info "Vérifiez que les visualisations ont été créées"
 exit 1
 fi
 
 # Créer le dashboard
 dashboard_json=$(jq -n --arg title "$DASHBOARD_NAME" \
 --arg donut_id "$DONUT_ID" \
 --arg histogram_id "$HISTOGRAM_ID" \
 --arg cumulative_id "$CUMULATIVE_ID" \
 '{
 "attributes": {
 "title": $title,
 "visState": "{\"type\":\"dashboard\",\"params\":{\"useMargins\":true,\"grid\":{\"categoryLines\":false,\"valueAxis\":\"\"}},\"panelsJSON\":\"[{\"version\":\"7.10.0\",\"type\":\"visualization\",\"gridData\":{\"x\":0,\"y\":0,\"w\":12,\"h\":6,\"i\":\"1\"},\"panelIndex\":\"1\",\"id\":$donut_id},{\"version\":\"7.10.0\",\"type\":\"visualization\",\"gridData\":{\"x\":12,\"y\":0,\"w\":12,\"h\":6,\"i\":\"2\"},\"panelIndex\":\"2\",\"id\":$histogram_id},{\"version\":\"7.10.0\",\"type\":\"visualization\",\"gridData\":{\"x\":0,\"y\":6,\"w\":24,\"h\":6,\"i\":\"3\"},\"panelIndex\":\"3\",\"id\":$cumulative_id}]\",\"uiStateJSON\":\"{}\"}",
 "searchSourceJSON": "{\"index\":\"$INDEX_PATTERN\",\"query\":{\"language\":\"kuery\",\"query\":\"\"}}",
 "savedSearchId": null
 }
 }')
 
 response=$(curl -k -s -X POST "$API_URL/api/saved_objects/dashboard" \
 -H "Content-Type: application/json" \
 -H "kbn-xsrf: true" \
 -d "$dashboard_json")
 
 if echo "$response" | jq -e ".id" >/dev/null 2>&1; then
 success "Dashboard créé : $DASHBOARD_NAME"
 log_success "Dashboard $DASHBOARD_NAME créé"
 DASHBOARD_ID=$(echo "$response" | jq -r ".id")
 info "ID du dashboard : $DASHBOARD_ID"
 info "URL du dashboard : $KIBANA_BASE_URL/app/dashboards#/view/$DASHBOARD_ID"
 log_info "Dashboard URL: $KIBANA_BASE_URL/app/dashboards#/view/$DASHBOARD_ID"
 else
 error "Échec de la création du dashboard"
 log_error "Échec création dashboard"
 info "Réponse : $response"
 exit 1
 fi
}

# Affiche un résumé
show_summary() {
 echo ""
 title "RÉSUMÉ DU DASHBOARD KIBANA"
 echo ""
 info "Dashboard : $DASHBOARD_NAME"
 info "URL : $KIBANA_BASE_URL/app/dashboards#/view/$DASHBOARD_ID"
 info ""
 info "Visualisations créées :"
 info "  ✅ Diagramme Donut : Répartition des verbes HTTP"
 info "  ✅ Diagramme Histogram : Quantité cumulée de données par tranche de 12h"
 info "  ✅ Diagramme Histogram cumulé : Top 5 des requêtes par tranche de 12h"
 info ""
 info "Fichier de log : /tmp/p5_logs/p5_$(date +%Y%m%d).log"
 echo ""
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
FORCE_MODE=false
WAIT_MODE=false

while [[ $# -gt 0 ]]; do
 case "$1" in
 --help|-h)
 show_help
 exit 0
 ;;
 --url)
 KIBANA_BASE_URL="$2"
 shift 2
 ;;
 --index-pattern)
 INDEX_PATTERN="$2"
 shift 2
 ;;
 --dashboard-name)
 DASHBOARD_NAME="$2"
 shift 2
 ;;
 --auto|-a)
 AUTO_MODE=true
 BEGINNER_MODE=0
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

# Initialiser le logging
init_logging

# Afficher l'en-tête
title "CRÉATION AUTOMATIQUE DU DASHBOARD KIBANA v2.0"
info "Objectif : Créer le dashboard avec les 3 diagrammes obligatoires via l'API OpenSearch"
info "Nouveautés : Vérification automatique des prérequis, mode --wait, gestion d'erreur améliorée"
echo ""

# Vérifier les dépendances
check_curl
check_jq

# Configurer l'URL de Kibana
configure_kibana_url

# Vérifier l'accès à Kibana
check_kibana_access

# Vérifier que l'index existe
check_index_exists

# Vérifier que l'index contient des données
check_index_has_data

# Vérifier que les champs requis existent
check_required_fields

# Vérifier si le dashboard existe déjà
check_dashboard_exists

# Mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
 info "Mode automatique activé"
 log_info "Mode automatique activé"
else
 info "Mode interactif activé"
 log_info "Mode interactif activé"
 set_beginner_mode
fi

# Créer l'index pattern
create_index_pattern
prompt_to_continue

# Créer les 3 visualisations
create_donut_chart
prompt_to_continue

create_histogram_chart
prompt_to_continue

create_cumulative_histogram
prompt_to_continue

# Créer le dashboard
create_dashboard

# Afficher le résumé
show_summary

echo ""
title "DASHBOARD KIBANA CRÉÉ AVEC SUCCÈS"
success "Le dashboard a été créé avec succès dans Kibana !"
info ""
info "Prochaine étape :"
info "  1. Vérifiez que le dashboard contient bien les 3 diagrammes"
info "  2. Prenez les 4 captures d'écran (dashboard + 3 diagrammes)"
info "  3. Utilisez : ./scripts/utils/capture-screenshots.sh --auto"
info "  4. Placez-les dans le dossier courant pour la Phase 4"
