#!/bin/bash
# =============================================================================
# SCRIPT : phase-2-opensearch-kibana.sh
# DESCRIPTION : Phase 2 - Déploiement OpenSearch + Kibana + Dashboard
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

PHASE_DIR="$PROJECT_ROOT/terraform/exercice-2"
TERRAFORM_DIR="$PHASE_DIR"
DATA_DIR="$TERRAFORM_DIR/samples"
DOMAIN_NAME="p5-opensearch"

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
    echo ""
    title "AIDE : phase-2-opensearch-kibana.sh"
    echo ""
    echo "Ce script déploie OpenSearch + Kibana, charge les logs NGINX et crée un dashboard."
    echo ""
    echo "Options :"
    echo "  --help, -h          Affiche cette aide"
    echo "  --auto, -a          Mode automatique (pas de confirmation)"
    echo "  --destroy, -d       Supprime les ressources Terraform"
    echo ""
}

# Vérifie les prérequis pour la Phase 2
check_phase_2_prerequisites() {
    title "VÉRIFICATION DES PRÉREQUIS POUR LA PHASE 2"

    step 1 "Vérification de l'environnement"
    check_terraform || exit 1
    check_aws_cli || exit 1
    check_git || exit 1

    step 2 "Vérification du dossier du projet"
    check_dir_exists "$PHASE_DIR" || {
        error "Le dossier $PHASE_DIR n'existe pas"
        exit 1
    }

    step 3 "Vérification des fichiers Terraform"
    check_file_exists "$TERRAFORM_DIR/main.tf" || {
        error "Le fichier $TERRAFORM_DIR/main.tf n'existe pas"
        exit 1
    }

    step 4 "Vérification du fichier de logs"
    check_file_exists "$DATA_DIR/nginx-access.log.sample" || {
        warning "Le fichier $DATA_DIR/nginx-access.log.sample n'existe pas"
        info "Un fichier exemple sera utilisé à la place"
    }

    success "Tous les prérequis pour la Phase 2 sont validés !"
}

# Exécute Terraform init
run_terraform_init() {
    step 1 "Initialisation de Terraform"
    command "terraform init"
    if terraform -chdir="$TERRAFORM_DIR" init; then
        success "Terraform initialisé avec succès"
    else
        error "Échec de l'initialisation de Terraform"
        exit 1
    fi
}

# Exécute Terraform plan
run_terraform_plan() {
    step 2 "Vérification du plan Terraform"
    command "terraform plan"

    info "Vérification du plan Terraform..."
    if terraform -chdir="$TERRAFORM_DIR" plan; then
        success "Plan Terraform vérifié"
        warning "⚠️ Vérifiez que le plan contient la création d'un domaine OpenSearch avec Kibana activé"
        if ! prompt_to_continue; then
            exit 0
        fi
    else
        error "Échec de la vérification du plan Terraform"
        exit 1
    fi
}

# Exécute Terraform apply
run_terraform_apply() {
    step 3 "Application de Terraform"
    command "terraform apply -auto-approve"

    info "Déploiement du cluster OpenSearch (peut prendre 5-10 min)..."
    if terraform -chdir="$TERRAFORM_DIR" apply -auto-approve; then
        success "Cluster OpenSearch déployé avec succès"
    else
        error "Échec du déploiement Terraform"
        exit 1
    fi
}

# Récupère l'endpoint OpenSearch
get_opensearch_endpoint() {
    step 4 "Récupération de l'endpoint OpenSearch"
    command "terraform output opensearch_endpoint"

    info "Récupération de l'endpoint OpenSearch..."
    OPENSEARCH_ENDPOINT=$(terraform -chdir="$TERRAFORM_DIR" output -raw opensearch_endpoint 2>/dev/null)

    if [ -z "$OPENSEARCH_ENDPOINT" ]; then
        error "Impossible de récupérer l'endpoint OpenSearch"
        info "Vérifiez que l'output est défini dans $TERRAFORM_DIR/outputs.tf"
        exit 1
    fi

    success "Endpoint OpenSearch : $OPENSEARCH_ENDPOINT"
    echo "$OPENSEARCH_ENDPOINT" > /tmp/opensearch_endpoint.txt

    # Calculer l'URL Kibana
    KIBANA_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw opensearch_dashboards_endpoint 2>/dev/null)
    success "URL Kibana : $KIBANA_URL"
    echo "$KIBANA_URL" > /tmp/kibana_url.txt
}

# Vérifie que le cluster OpenSearch est actif
wait_for_opensearch() {
    step 5 "Attente que le cluster OpenSearch soit actif"

    info "Vérification de l'état du cluster OpenSearch..."
    for _ in {1..60}; do
        processing=$(aws opensearch describe-domain --domain-name "$DOMAIN_NAME" \
            --query "DomainStatus.Processing" --output text 2>/dev/null || true)
        endpoint=$(aws opensearch describe-domain --domain-name "$DOMAIN_NAME" \
            --query "DomainStatus.Endpoint" --output text 2>/dev/null || true)

        if [ "$processing" = "False" ] && [ -n "$endpoint" ] && [ "$endpoint" != "None" ]; then
            success "Le cluster OpenSearch est actif"
            return 0
        fi

        info "Le cluster est encore en cours de préparation. Nouvelle vérification dans 30 secondes..."
        sleep 30
    done

    error "Le cluster OpenSearch n'est pas devenu disponible dans le délai imparti"
    exit 1
}

# Confirme que la politique d'accès est gérée par Terraform
configure_access_policy() {
    step 6 "Vérification de la politique d'accès"
    success "La politique d'accès IP est déclarée et appliquée par Terraform"
}

# Teste l'accès à Kibana
test_kibana_access() {
    step 7 "Test de l'accès à Kibana"

    KIBANA_URL=$(cat /tmp/kibana_url.txt)
    info "Test de l'accès à Kibana : $KIBANA_URL"

    if curl --fail --silent --show-error --head "$KIBANA_URL" >/dev/null; then
        success "Kibana est accessible !"
        info "Ouvrez un navigateur et allez sur : $KIBANA_URL"
    else
        error "Kibana n'est pas accessible"
        info "Vérifiez :"
        info "  1. L'access policy est correctement configurée"
        info "  2. Le cluster OpenSearch est actif"
        info "  3. Votre IP publique n'a pas changé"
        exit 1
    fi
}

# Charge les logs NGINX dans OpenSearch
load_nginx_logs() {
    step 8 "Chargement des logs NGINX dans OpenSearch"

    OPENSEARCH_ENDPOINT=$(cat /tmp/opensearch_endpoint.txt)

    # Vérifier si jq est installé
    if ! command_exists jq; then
        info "Installation de jq..."
        sudo apt install -y jq || {
            error "Échec de l'installation de jq"
            exit 1
        }
    fi

    info "Chargement des logs dans OpenSearch..."
    info "Cela peut prendre quelques minutes selon la taille du fichier."

    # Utiliser le fichier de logs du projet ou un exemple
    LOGS_FILE="$DATA_DIR/nginx-access.log.sample"
    if [ ! -f "$LOGS_FILE" ]; then
        warning "Le fichier $LOGS_FILE n'existe pas. Utilisation d'un exemple."
        LOGS_FILE="/tmp/nginx-access.log"
        # Créer un fichier exemple si nécessaire
        if [ ! -f "$LOGS_FILE" ]; then
            info "Création d'un fichier de logs exemple..."
            cat > "$LOGS_FILE" <<'EOF'
192.168.1.1 - - [02/Aug/2026:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
192.168.1.2 - - [02/Aug/2026:10:00:01 +0000] "POST /api/data HTTP/1.1" 200 5678 "-" "Mozilla/5.0"
192.168.1.3 - - [02/Aug/2026:10:00:02 +0000] "GET /about HTTP/1.1" 200 3456 "-" "Mozilla/5.0"
EOF
        fi
    fi

    # Charger les logs ligne par ligne
    line_count=$(wc -l < "$LOGS_FILE")
    current_line=0

    while IFS= read -r line; do
        current_line=$((current_line + 1))
        progress_bar "Chargement des logs ($current_line/$line_count)" $((current_line * 100 / line_count))

        # Extraire les champs du log NGINX
        ip=$(echo "$line" | awk '{print $1}')
        date_time=$(echo "$line" | awk '{print $4,$5}' | tr -d '[]')
        request=$(echo "$line" | awk -F'"' '{print $2}')
        method=$(echo "$request" | awk '{print $1}')
        url=$(echo "$request" | awk '{print $2}')
        status=$(echo "$line" | awk '{print $9}')
        size=$(echo "$line" | awk '{print $10}')

        timestamp=$(date -u -d "${date_time/:/ }" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')
        [[ "$status" =~ ^[0-9]+$ ]] || status=0
        [[ "$size" =~ ^[0-9]+$ ]] || size=0

        # Créer un document JSON
        json_doc=$(jq -n \
            --arg ip "$ip" \
            --arg timestamp "$timestamp" \
            --arg method "$method" \
            --arg url "$url" \
            --argjson status "$status" \
            --argjson size "$size" \
            '{
            "@timestamp": $timestamp,
            "client_ip": $ip,
            "method": $method,
            "url": $url,
            "status": $status,
            "size": $size
        }')

        # Envoyer à OpenSearch
        if ! curl --fail --silent --show-error -X POST "$OPENSEARCH_ENDPOINT/nginx-access-$(date +%Y.%m.%d)/_doc" \
            -H "Content-Type: application/json" \
            -d "$json_doc" >/dev/null; then
            warning "Échec de l'envoi du log : $line"
        fi
    done < "$LOGS_FILE"

    success "Logs NGINX chargés dans OpenSearch"
}

# Vérifie que les logs sont chargés
verify_logs_loaded() {
    step 9 "Vérification que les logs sont chargés"

    OPENSEARCH_ENDPOINT=$(cat /tmp/opensearch_endpoint.txt)

    info "Vérification des indices OpenSearch..."
    if curl --fail --silent --show-error "$OPENSEARCH_ENDPOINT/_cat/indices?v" | grep -q "nginx-access"; then
        success "Les logs sont bien chargés dans OpenSearch"
        check "Index nginx-access-* trouvé"
    else
        error "Les logs ne sont pas chargés dans OpenSearch"
        exit 1
    fi
}

# Affiche les instructions pour Kibana
show_kibana_instructions() {
    step 10 "Instructions pour Kibana"

    KIBANA_URL=$(cat /tmp/kibana_url.txt)

    echo ""
    title "INSTRUCTIONS POUR CRÉER LE DASHBOARD KIBANA"
    step 10 "Création automatique du dashboard Kibana"

    KIBANA_URL=$(cat /tmp/kibana_url.txt)

    info "Vous pouvez créer le dashboard manuellement ou utiliser le script automatique."
    echo ""

    if confirm "Voulez-vous essayer de créer le dashboard automatiquement via l'API ?"; then
        info "Lancement du script de création automatique du dashboard..."
        if [ -f "$(dirname "$0")/utils/kibana-api.sh" ]; then
            if bash "$(dirname "$0")/utils/kibana-api.sh" --url "$KIBANA_URL" --auto; then
                success "Dashboard créé automatiquement !"
                info "Vérifiez dans Kibana que le dashboard contient bien les 3 diagrammes."
            else
                warning "Échec de la création automatique du dashboard."
                info "Vous devrez le créer manuellement."
            fi
        else
            error "Le script kibana-api.sh n'existe pas"
        fi
    fi

    echo ""
    title "INSTRUCTIONS POUR CRÉER LE DASHBOARD KIBANA (MANUELLEMENT)"
    echo ""
    info "1. Accédez à Kibana : $KIBANA_URL"
    info "2. Créez un Index Pattern :"
    info "   - Allez dans 'Stack Management' > 'Index Patterns'"
    info "   - Créez un index pattern : nginx-access*"
    info "   - Sélectionnez @timestamp comme champ de temps"
    echo ""
    info "3. Vérifiez les données dans 'Discover' :"
    info "   - Sélectionnez l'index pattern nginx-access*"
    info "   - Vous devriez voir vos logs NGINX"
    echo ""
    info "4. Créez les 3 diagrammes obligatoires :"
    info "   a) Diagramme 'Donut' : Répartition des verbes HTTP (field: method)"
    info "   b) Diagramme 'Histogram' : Quantité cumulée de données par tranche de 12h (field: size, interval: 12h)"
    info "   c) Diagramme 'Cumulative Histogram' : Top 5 des requêtes par tranche de 12h (field: url, size: 5, cumulative: ✅)"
    echo ""
    info "5. Créez un Dashboard avec les 3 diagrammes"
    echo ""
    info "6. Générez les 4 captures d'écran :"
    info "   - Dashboard complet"
    info "   - Diagramme Donut seul"
    info "   - Diagramme Histogram seul"
    info "   - Diagramme Histogramme cumulé seul"
    echo ""
    warning "⚠️ Ces captures sont OBLIGATOIRES pour le livrable OpenClassrooms"
}

# Supprime les ressources Terraform
destroy_terraform() {
    step 1 "Suppression des ressources Terraform"
    command "terraform destroy -auto-approve"

    warning "⚠️ ATTENTION : Cette opération va SUPPRIMER le cluster OpenSearch."
    if confirm_strict "Voulez-vous VRAIMENT supprimer les ressources ?"; then
        if terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve; then
            success "Ressources Terraform supprimées"
        else
            error "Échec de la suppression des ressources Terraform"
            exit 1
        fi
    fi
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false
DESTROY_MODE=false

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
        --destroy|-d)
            DESTROY_MODE=true
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
title "PHASE 2 : OPENSEARCH + KIBANA + DASHBOARD"
info "Durée estimée : 3-4h"
info "Objectif : Déployer OpenSearch + Kibana, charger les logs NGINX et créer un dashboard"
echo ""

# Mode destruction
if [ "$DESTROY_MODE" = true ]; then
    destroy_terraform
    exit 0
fi

# Vérifier les prérequis
check_phase_2_prerequisites

# Mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
    info "Mode automatique activé"
else
    info "Mode interactif activé (confirmation requise à chaque étape)"
    set_beginner_mode
fi

# Exécuter les étapes
run_terraform_init
prompt_to_continue

run_terraform_plan
prompt_to_continue

run_terraform_apply
prompt_to_continue

get_opensearch_endpoint
prompt_to_continue

wait_for_opensearch
prompt_to_continue

configure_access_policy
prompt_to_continue

test_kibana_access
prompt_to_continue

load_nginx_logs
prompt_to_continue

verify_logs_loaded
prompt_to_continue

show_kibana_instructions

echo ""
title "PHASE 2 TERMINÉE"
success "Cluster OpenSearch + Kibana déployé !"
info "Prochaine étape :"
info "  1. Suivez les instructions pour créer le dashboard dans Kibana"
info "  2. Générez les 4 captures d'écran"
info "  3. Passez à la Phase 3 : ./runbook.sh → Option 3"
