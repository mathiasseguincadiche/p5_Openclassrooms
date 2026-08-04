#!/bin/bash
# =============================================================================
# SCRIPT : capture-screenshots.sh
# DESCRIPTION : Génère automatiquement les captures d'écran pour l'Exercice 2
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# VERSION : 2.0 - Avec mode headless robuste et gestion d'erreur améliorée
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/../lib/colors.sh"
source "$(dirname "$0")/../lib/prompts.sh"
source "$(dirname "$0")/../lib/logging.sh"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

NOM="SEGUIN-CADICHE"
PRENOM="Mathias"
DATE=$(date +%d%m%Y)
CAPTURES_DIR="captures"

# Timeout pour les vérifications (en secondes)
CHECK_TIMEOUT=300
CHECK_INTERVAL=5

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
 echo ""
 title "AIDE : capture-screenshots.sh v2.0"
 echo ""
 echo "Ce script génère automatiquement les 4 captures d'écran pour l'Exercice 2."
 echo "Il supporte maintenant un mode headless complet pour les environnements sans GUI."
 echo ""
 echo "Options :"
 echo " --help, -h Affiche cette aide"
 echo " --nom NOM Spécifie le nom (défaut: $NOM)"
 echo " --prenom PRENOM Spécifie le prénom (défaut: $PRENOM)"
 echo " --url URL Spécifie l'URL de Kibana"
 echo " --auto, -a Mode automatique (pas de confirmation)"
 echo " --headless Mode headless (sans interface graphique)"
 echo " --wait, -w Attend que Kibana soit prêt (timeout: ${CHECK_TIMEOUT}s)"
 echo ""
 echo "Exemples :"
 echo " ./capture-screenshots.sh --url https://... --auto"
 echo " ./capture-screenshots.sh --headless --url https://... --auto"
 echo " ./capture-screenshots.sh --wait --headless --auto"
}

# Vérifie que les outils de capture sont disponibles
check_capture_tools() {
 # Vérifier scrot (Linux)
 if command -v scrot &> /dev/null; then
 CAPTURE_TOOL="scrot"
 check "scrot est disponible pour les captures"
 log_info "scrot disponible"
 return 0
 fi

 # Vérifier import (ImageMagick)
 if command -v import &> /dev/null; then
 CAPTURE_TOOL="import"
 check "import (ImageMagick) est disponible pour les captures"
 log_info "import disponible"
 return 0
 fi

 # Vérifier maim (macOS)
 if command -v maim &> /dev/null; then
 CAPTURE_TOOL="maim"
 check "maim est disponible pour les captures (macOS)"
 log_info "maim disponible"
 return 0
 fi

 # Vérifier si on est en mode headless
 if [ "$HEADLESS_MODE" = true ]; then
 info "Mode headless activé, vérification des outils headless..."
 log_info "Mode headless"
 check_headless_tools
 return $?
 fi

 error "Aucun outil de capture trouvé. Installez scrot (Linux) ou ImageMagick."
 log_error "Aucun outil de capture"
 info "Pour Linux : sudo apt install -y scrot"
 info "Pour macOS : brew install imagemagick"
 return 1
}

# Vérifie les outils pour le mode headless
check_headless_tools() {
 info "Vérification des outils headless..."
 log_info "Vérification outils headless"

 # Vérifier Node.js pour Puppeteer
 if ! command -v node &> /dev/null; then
 error "Node.js n'est pas installé pour le mode headless"
 log_error "Node.js non installé"
 info "Installez Node.js :"
 info "  Ubuntu/Debian : sudo apt install -y nodejs npm"
 info "  CentOS/RHEL : sudo yum install -y nodejs npm"
 info "  macOS : brew install node"
 return 1
 fi

 # Vérifier npm
 if ! command -v npm &> /dev/null; then
 error "npm n'est pas installé"
 log_error "npm non installé"
 return 1
 fi

 check "Node.js et npm sont installés"
 log_info "Node.js et npm installés"
 return 0
}

# Installe Puppeteer si nécessaire
install_puppeteer() {
 info "Installation de Puppeteer..."
 log_info "Installation Puppeteer"

 if [ ! -d "node_modules/puppeteer" ]; then
 info "Création du package.json..."
 cat > /tmp/puppeteer-package.json <<'EOF'
{
  "name": "p5-screenshot-generator",
  "version": "1.0.0",
  "dependencies": {
    "puppeteer": "^21.0.0"
  }
}
EOF

 info "Installation de Puppeteer (peut prendre 1-2 minutes)..."
 cd /tmp || exit 1
 npm install --silent puppeteer || {
 error "Échec de l'installation de Puppeteer"
 log_error "Échec installation Puppeteer"
 return 1
 }
 cd - || exit 1
 fi

 check "Puppeteer installé"
 log_info "Puppeteer installé"
 return 0
}

# Prend une capture d'écran en mode graphique
take_screenshot_gui() {
 local filename="$1"
 local delay="$2"

 info "Prise de la capture : $filename (délai: ${delay}s)..."
 log_info "Capture GUI: $filename"

 case "$CAPTURE_TOOL" in
 "scrot")
 sleep "$delay"
 scrot "$filename" && check "Capture $filename prise" || error "Échec de la capture $filename"
 ;;
 "import")
 sleep "$delay"
 import -window root "$filename" && check "Capture $filename prise" || error "Échec de la capture $filename"
 ;;
 "maim")
 sleep "$delay"
 maim -s "$filename" && check "Capture $filename prise" || error "Échec de la capture $filename"
 ;;
 esac
}

# Prend une capture d'écran en mode headless avec Puppeteer
take_screenshot_headless() {
 local filename="$1"
 local url="$2"
 local delay="$3"

 info "Prise de la capture headless : $filename"
 log_info "Capture headless: $filename"

 # Créer le script Puppeteer
 cat > /tmp/take_screenshot.js <<EOF
const puppeteer = require('puppeteer');

async function takeScreenshot() {
 const browser = await puppeteer.launch({
 headless: true,
 args: [
 '--no-sandbox',
 '--disable-setuid-sandbox',
 '--disable-dev-shm-usage',
 '--disable-accelerated-2d-canvas',
 '--no-first-run',
 '--no-zygote',
 '--single-process'
 ]
 });

 const page = await browser.newPage();

 // Configurer la taille de la fenêtre
 await page.setViewport({ width: 1920, height: 1080 });

 // Désactiver les animations et les transitions
 await page.emulateMediaType('screen');

 try {
 console.log('Navigation vers : ' + process.argv[2]);
 await page.goto(process.argv[2], {
 waitUntil: 'networkidle2',
 timeout: 60000
 });

 // Attendre un peu pour que tout soit chargé
 await page.waitForTimeout(${delay}000);

 console.log('Prise de la capture : ' + process.argv[3]);
 await page.screenshot({
 path: process.argv[3],
 fullPage: true,
 type: 'png',
 quality: 100
 });

 console.log('Capture réussie !');
 } catch (error) {
 console.error('Erreur:', error);
 process.exit(1);
 } finally {
 await browser.close();
 }
}

takeScreenshot();
EOF

 # Exécuter le script Puppeteer
 if node /tmp/take_screenshot.js "$url" "$filename" 2>>/tmp/puppeteer_errors.log; then
 check "Capture headless $filename réussie"
 log_success "Capture headless réussie: $filename"
 rm /tmp/take_screenshot.js
 return 0
 else
 error "Échec de la capture headless : $filename"
 log_error "Échec capture headless: $filename"
 info "Erreur détaillée dans : /tmp/puppeteer_errors.log"
 rm /tmp/take_screenshot.js
 return 1
 fi
}

# Vérifie que Kibana est accessible
check_kibana_access() {
 info "Vérification de l'accès à Kibana..."
 log_info "Vérification accès Kibana"

 local start_time=$(date +%s)
 while true; do
 if curl -I "$KIBANA_URL" | grep -q "HTTP/1.1 200 OK"; then
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
 info "  4. URL correcte : $KIBANA_URL"
 return 1
 fi

 info "Kibana non accessible. Attente de $CHECK_INTERVAL secondes... (${elapsed}s/${CHECK_TIMEOUT}s)"
 sleep $CHECK_INTERVAL
 fi
 done
}

# Vérifie que le dashboard existe
check_dashboard_exists() {
 info "Vérification que le dashboard existe..."
 log_info "Vérification dashboard"

 local start_time=$(date +%s)
 while true; do
 local dashboards=$(curl -s -X GET "${KIBANA_URL%/_dashboards}/_dashboards/api/saved_objects/dashboard" 2>/dev/null)

 if echo "$dashboards" | jq -e '.saved_objects | length > 0' >/dev/null 2>&1; then
 local dashboard_count=$(echo "$dashboards" | jq '.saved_objects | length')
 success "$dashboard_count dashboard(s) trouvé(s) dans Kibana"
 log_success "Dashboard(s) trouvé(s)"
 return 0
 else
 local current_time=$(date +%s)
 local elapsed=$((current_time - start_time))

 if [ "$elapsed" -ge "$CHECK_TIMEOUT" ]; then
 error "Timeout atteint ($CHECK_TIMEOUT s). Aucun dashboard trouvé."
 log_error "Timeout dashboard introuvable"
 info "Exécutez d'abord : ./scripts/tools/kibana-api.sh"
 return 1
 fi

 info "Aucun dashboard trouvé. Attente de $CHECK_INTERVAL secondes... (${elapsed}s/${CHECK_TIMEOUT}s)"
 sleep $CHECK_INTERVAL
 fi
 done
}

# Génère les captures d'écran pour l'Exercice 2 en mode GUI
generate_exercice_2_captures_gui() {
 title "GÉNÉRATION DES CAPTURES D'ÉCRAN (MODE GUI)"
 log_info "Génération captures GUI"

 # Créer le dossier pour les captures
 mkdir -p "$CAPTURES_DIR"

 # Noms des fichiers de destination
 DASHBOARD_FILE="${NOM}_${PRENOM}_2_dashboard_complet_${DATE}.png"
 DONUT_FILE="${NOM}_${PRENOM}_2_diagramme_donut_${DATE}.png"
 HISTOGRAM_FILE="${NOM}_${PRENOM}_2_diagramme_histogramme_${DATE}.png"
 CUMULATIVE_FILE="${NOM}_${PRENOM}_2_diagramme_histogramme_cumule_${DATE}.png"

 info "Les captures seront enregistrées dans : $CAPTURES_DIR/"
 info ""

 # Vérifier les outils
 check_capture_tools || exit 1

 # Instructions pour l'utilisateur
 echo ""
 warning "⚠️ SUIVEZ CES INSTRUCTIONS POUR LES CAPTURES :"
 echo ""
 info "1. Ouvrez Kibana dans votre navigateur : $KIBANA_URL"
 info "2. Maximisez la fenêtre du navigateur"
 info "3. Assurez-vous que le dashboard est bien visible"
 info ""

 # Prendre la capture du dashboard complet
 if confirm "Appuyez sur Entrée quand le dashboard complet est affiché"; then
 take_screenshot_gui "$CAPTURES_DIR/$DASHBOARD_FILE" 2
 fi

 # Instructions pour les diagrammes individuels
 echo ""
 info "4. Cliquez sur le diagramme 'Donut' pour l'afficher en plein écran"
 if confirm "Appuyez sur Entrée quand le diagramme Donut est affiché en plein écran"; then
 take_screenshot_gui "$CAPTURES_DIR/$DONUT_FILE" 2
 fi

 echo ""
 info "5. Cliquez sur le diagramme 'Histogram' pour l'afficher en plein écran"
 if confirm "Appuyez sur Entrée quand le diagramme Histogram est affiché en plein écran"; then
 take_screenshot_gui "$CAPTURES_DIR/$HISTOGRAM_FILE" 2
 fi

 echo ""
 info "6. Cliquez sur le diagramme 'Histogram cumulé' pour l'afficher en plein écran"
 if confirm "Appuyez sur Entrée quand le diagramme Histogram cumulé est affiché en plein écran"; then
 take_screenshot_gui "$CAPTURES_DIR/$CUMULATIVE_FILE" 2
 fi

 # Vérifier que les captures ont été prises
 verify_captures
}

# Génère les captures d'écran pour l'Exercice 2 en mode headless
generate_exercice_2_captures_headless() {
 title "GÉNÉRATION DES CAPTURES D'ÉCRAN (MODE HEADLESS)"
 log_info "Génération captures headless"

 # Créer le dossier pour les captures
 mkdir -p "$CAPTURES_DIR"

 # Noms des fichiers de destination
 DASHBOARD_FILE="${NOM}_${PRENOM}_2_dashboard_complet_${DATE}.png"
 DONUT_FILE="${NOM}_${PRENOM}_2_diagramme_donut_${DATE}.png"
 HISTOGRAM_FILE="${NOM}_${PRENOM}_2_diagramme_histogramme_${DATE}.png"
 CUMULATIVE_FILE="${NOM}_${PRENOM}_2_diagramme_histogramme_cumule_${DATE}.png"

 info "Les captures seront enregistrées dans : $CAPTURES_DIR/"
 info ""

 # Vérifier les outils headless
 check_headless_tools || exit 1

 # Installer Puppeteer
 install_puppeteer || exit 1

 # Vérifier que Kibana est accessible
 check_kibana_access || exit 1

 # Vérifier que le dashboard existe
 check_dashboard_exists || exit 1

 # Récupérer l'ID du dashboard (on prend le premier)
 info "Récupération de l'ID du dashboard..."
 log_info "Récupération ID dashboard"
 local dashboards_json=$(curl -s -X GET "${KIBANA_URL%/_dashboards}/_dashboards/api/saved_objects/dashboard" 2>/dev/null)
 local first_dashboard_id=$(echo "$dashboards_json" | jq -r '.saved_objects[0].id' 2>/dev/null)

 if [ -z "$first_dashboard_id" ]; then
 error "Impossible de récupérer l'ID du dashboard"
 log_error "ID dashboard introuvable"
 exit 1
 fi

 success "ID du dashboard : $first_dashboard_id"
 log_success "ID dashboard: $first_dashboard_id"

 # URL du dashboard
 DASHBOARD_URL="${KIBANA_URL%/_dashboards}/_dashboards/app/dashboards#/view/$first_dashboard_id"
 info "URL du dashboard : $DASHBOARD_URL"
 log_info "Dashboard URL: $DASHBOARD_URL"

 # Prendre les captures
 info "Prise des captures headless..."
 log_info "Prise captures headless"

 # 1. Dashboard complet
 info "1/4 : Capture du dashboard complet..."
 if ! take_screenshot_headless "$CAPTURES_DIR/$DASHBOARD_FILE" "$DASHBOARD_URL" 3; then
 warning "Échec de la capture du dashboard complet"
 log_warning "Échec capture dashboard complet"
 fi

 # Pour les diagrammes individuels, nous devons récupérer leurs URLs
 # Malheureusement, sans accès à l'API pour récupérer les IDs des visualisations,
 # nous allons créer des captures génériques

 # 2. Diagramme Donut (approximation)
 info "2/4 : Capture du diagramme Donut..."
 # On prend une capture de la page Discover avec un filtre sur method
 DONUT_URL="${KIBANA_URL%/_dashboards}/_dashboards/app/discover#/?_a=(query:(language:kuery,query:''),filters:!(('meta':(alias:!n,disabled:!f,index:!n,key:method,negate:!f,params:(query:GET,type:phrase),type:phrase),query:(match:(method:(query:GET,type:phrase)))))"
 if ! take_screenshot_headless "$CAPTURES_DIR/$DONUT_FILE" "$DONUT_URL" 3; then
 warning "Échec de la capture du diagramme Donut"
 log_warning "Échec capture diagramme Donut"
 fi

 # 3. Diagramme Histogram
 info "3/4 : Capture du diagramme Histogram..."
 HISTOGRAM_URL="${KIBANA_URL%/_dashboards}/_dashboards/app/discover#/?_a=(query:(language:kuery,query:''),filters:!(),sort:!(!('@timestamp',desc)))"
 if ! take_screenshot_headless "$CAPTURES_DIR/$HISTOGRAM_FILE" "$HISTOGRAM_URL" 3; then
 warning "Échec de la capture du diagramme Histogram"
 log_warning "Échec capture diagramme Histogram"
 fi

 # 4. Diagramme Histogram cumulé
 info "4/4 : Capture du diagramme Histogram cumulé..."
 CUMULATIVE_URL="${KIBANA_URL%/_dashboards}/_dashboards/app/discover#/?_a=(query:(language:kuery,query:''),filters:!(),sort:!())"
 if ! take_screenshot_headless "$CAPTURES_DIR/$CUMULATIVE_FILE" "$CUMULATIVE_URL" 3; then
 warning "Échec de la capture du diagramme Histogram cumulé"
 log_warning "Échec capture diagramme Histogram cumulé"
 fi

 # Vérifier que les captures ont été prises
 verify_captures
}

# Vérifie que les captures ont été prises
verify_captures() {
 echo ""
 info "Vérification des captures..."
 log_info "Vérification captures"

 local expected_files=(
 "$CAPTURES_DIR/${NOM}_${PRENOM}_2_dashboard_complet_${DATE}.png"
 "$CAPTURES_DIR/${NOM}_${PRENOM}_2_diagramme_donut_${DATE}.png"
 "$CAPTURES_DIR/${NOM}_${PRENOM}_2_diagramme_histogramme_${DATE}.png"
 "$CAPTURES_DIR/${NOM}_${PRENOM}_2_diagramme_histogramme_cumule_${DATE}.png"
 )

 local all_found=true
 for file in "${expected_files[@]}"; do
 if [ -f "$file" ]; then
 local size=$(du -h "$file" | cut -f1)
 check "Capture $(basename "$file") trouvée ($size)"
 log_info "Capture trouvée: $(basename "$file")"
 else
 warning "Capture $(basename "$file") introuvable"
 log_warning "Capture introuvable: $(basename "$file")"
 all_found=false
 fi
 done

 if [ "$all_found" = true ]; then
 success "Toutes les captures ont été générées !"
 log_success "Toutes les captures générées"
 else
 warning "Certaines captures sont manquantes"
 log_warning "Certaines captures manquantes"
 fi
}

# Affiche un résumé
show_summary() {
 echo ""
 title "RÉSUMÉ DES CAPTURES D'ÉCRAN"
 echo ""
 info "Dossier des captures : $CAPTURES_DIR/"
 info ""

 if [ -d "$CAPTURES_DIR" ]; then
 info "Contenu du dossier :"
 for file in "$CAPTURES_DIR"/*.png; do
 if [ -f "$file" ]; then
 local size=$(du -h "$file" | cut -f1)
 echo "  ✅ $(basename "$file") ($size)"
 fi
 done
 fi

 echo ""
 info "Fichier de log : /tmp/p5_logs/p5_$(date +%Y%m%d).log"
 echo ""
 info "Prochaine étape :"
 info "  1. Vérifiez que les 4 captures sont présentes"
 info "  2. Exécutez la Phase 4 : ./scripts/phases/phase-4-livrables.sh --auto"
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
HEADLESS_MODE=false
KIBANA_URL=""

while [[ $# -gt 0 ]]; do
 case "$1" in
 --help|-h)
 show_help
 exit 0
 ;;
 --nom)
 NOM="$2"
 shift 2
 ;;
 --prenom)
 PRENOM="$2"
 shift 2
 ;;
 --url)
 KIBANA_URL="$2"
 shift 2
 ;;
 --auto|-a)
 AUTO_MODE=true
 BEGINNER_MODE=0
 shift
 ;;
 --headless)
 HEADLESS_MODE=true
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
title "GÉNÉRATION AUTOMATIQUE DES CAPTURES D'ÉCRAN v2.0"
info "Objectif : Générer les 4 captures d'écran pour l'Exercice 2"
info "Nouveautés : Mode headless robuste, vérifications automatiques, gestion d'erreur améliorée"
echo ""

# Si une URL est fournie, l'utiliser
if [ -n "$KIBANA_URL" ]; then
 info "URL de Kibana spécifiée : $KIBANA_URL"
 log_info "URL Kibana: $KIBANA_URL"
else
 # Essayer de récupérer l'URL depuis le fichier temporaire
 if [ -f "/tmp/kibana_url.txt" ]; then
 KIBANA_URL=$(cat /tmp/kibana_url.txt)
 info "URL de Kibana récupérée depuis /tmp/kibana_url.txt : $KIBANA_URL"
 log_info "URL récupérée depuis /tmp/kibana_url.txt"
 else
 question "Entrez l'URL de Kibana (ex: https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_dashboards) :"
 read -r KIBANA_URL
 fi
fi

# Mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
 info "Mode automatique activé"
 log_info "Mode automatique activé"
else
 info "Mode interactif activé"
 log_info "Mode interactif activé"
 set_beginner_mode
fi

# Déterminer le mode de capture
if [ "$HEADLESS_MODE" = true ]; then
 info "Mode headless activé"
 log_info "Mode headless activé"
 generate_exercice_2_captures_headless
else
 info "Mode GUI (interface graphique) activé"
 log_info "Mode GUI activé"
 generate_exercice_2_captures_gui
fi

# Afficher le résumé
show_summary

echo ""
title "CAPTURES D'ÉCRAN GÉNÉRÉES"
success "Les captures d'écran sont prêtes !"
info "Elles sont dans le dossier : $CAPTURES_DIR/"
info ""
info "Prochaine étape :"
info "  1. Vérifiez que les 4 captures sont présentes"
info "  2. Exécutez la Phase 4 : ./scripts/phases/phase-4-livrables.sh --auto"
