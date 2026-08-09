#!/usr/bin/env bash
# Orchestrateur terminal du projet P5 OpenClassrooms.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
INVENTORY_FILE="$PROJECT_ROOT/ansible/inventories/hosts_aws"
COMMAND=""
ASSUME_YES=false
FULL_VALIDATION=false
P5_PREPARED_THIS_RUN=false

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"

show_help() {
    cat <<'HELP'
P5 OpenClassrooms — centre de commande

Usage:
  bash scripts/commands/p5.sh [commande] [options]

Commandes:
  menu       afficher le menu interactif (défaut)
  prepare    configurer le lab, les tfvars, le budget et les contrôles AWS
  status     lancer les contrôles de préparation sans créer de ressource
  ex1        déployer Terraform + Ansible + NGINX + Angular
  ex2        déployer OpenSearch, importer les données et valider les agrégations
  ex3        déployer HAProxy + 2 backends et tester panne/reprise
  all        exécuter prepare + ex1 + ex2 + ex3 + diagnostics
  finalize   contrôler les livrables et collecter les diagnostics complets
  cleanup    détruire AWS dans l'ordre prévu puis auditer le nettoyage
  logs       afficher les journaux disponibles
  help       afficher cette aide

Options globales:
  --yes              confirmer automatiquement les mutations automatisables
                     (jamais les preuves manuelles ni la destruction finale)
  --full-validation  inclure OpenSearch local dans la validation du dépôt

Exemples:
  bash scripts/commands/p5.sh
  bash scripts/commands/p5.sh all
  bash scripts/commands/p5.sh all --yes
  bash scripts/commands/p5.sh status
  bash scripts/commands/p5.sh cleanup

Logs:
  chaque exécution crée logs/<UTC>/p5.log et un fichier .log par étape.
HELP
}

while (($# > 0)); do
    case "$1" in
        --yes)
            ASSUME_YES=true
            export P5_ASSUME_YES=1
            shift
            ;;
        --full-validation)
            FULL_VALIDATION=true
            shift
            ;;
        -h|--help|help)
            COMMAND=help
            shift
            ;;
        menu|prepare|status|ex1|ex2|ex3|all|finalize|cleanup|logs)
            if [[ -n "$COMMAND" ]]; then
                p5_error "Plusieurs commandes fournies : $COMMAND et $1"
                exit 2
            fi
            COMMAND="$1"
            shift
            ;;
        *)
            p5_error "Argument inconnu : $1"
            show_help >&2
            exit 2
            ;;
    esac
done

COMMAND="${COMMAND:-menu}"
if [[ "$COMMAND" == help ]]; then
    show_help
    exit 0
fi

p5_session_start 'p5'
cd "$PROJECT_ROOT"

load_lab_config() {
    [[ -r "$CONFIG_FILE" ]] || {
        p5_error "Configuration absente : $CONFIG_FILE"
        p5_action "Exécutez : bash scripts/commands/p5.sh prepare"
        return 1
    }
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    export AWS_PROFILE AWS_REGION AWS_SDK_LOAD_CONFIG=1
}

toolchain_ready() {
    local command_name
    for command_name in git python3 terraform ansible-playbook aws curl jq ssh docker node npm shellcheck yamllint; do
        command -v "$command_name" >/dev/null 2>&1 || return 1
    done
}

ensure_toolchain() {
    if toolchain_ready; then
        p5_ok 'Socle DevOps détecté.'
        return 0
    fi

    p5_warn 'Le socle DevOps complet n’est pas encore disponible sur cette VM.'
    p5_action 'Le bootstrap peut installer les outils et versions attendus par le projet.'
    if ! p5_confirm 'Lancer le bootstrap Ubuntu du P5 maintenant ?'; then
        p5_error 'Le socle DevOps est requis avant de poursuivre.'
        return 1
    fi

    p5_run_step 'bootstrap' 'Installer le socle DevOps de la VM' \
        bash "$SCRIPT_DIR/bootstrap-ubuntu-server.sh"
    p5_header 'RECONNEXION REQUISE'
    p5_action 'Le bootstrap a modifié les groupes Docker et le shell Node/NVM.'
    p5_action 'Déconnectez-vous de la VM, reconnectez-vous, puis relancez exactement la même commande P5.'
    p5_latest_log_hint
    return 90
}

terraform_state_has_resources() {
    local exercise="$1"
    local module_dir="$PROJECT_ROOT/terraform/exercice-$exercise"
    [[ -f "$module_dir/terraform.tfstate" ]] || return 1
    terraform -chdir="$module_dir" state list 2>/dev/null | grep -q .
}

run_validation() {
    if [[ "$FULL_VALIDATION" == true ]]; then
        p5_run_step 'validate-full' 'Validation locale complète avec OpenSearch' \
            env P5_FULL_INTEGRATION=1 bash "$SCRIPT_DIR/validate.sh"
    else
        p5_run_step 'validate' 'Validation locale du dépôt' \
            bash "$SCRIPT_DIR/validate.sh"
    fi
}

terraform_apply_exercise() {
    local exercise="$1"
    local label="$2"
    local module_dir="$PROJECT_ROOT/terraform/exercice-$exercise"
    local plan_file="$module_dir/tfplan"

    load_lab_config
    p5_run_step "tf-ex${exercise}-init" "Terraform exercice $exercise — init" \
        terraform -chdir="$module_dir" init -input=false
    p5_run_step "tf-ex${exercise}-plan" "Terraform exercice $exercise — plan" \
        terraform -chdir="$module_dir" plan -input=false -out=tfplan
    p5_run_step "tf-ex${exercise}-show" "Terraform exercice $exercise — afficher le plan" \
        terraform -chdir="$module_dir" show -no-color tfplan

    if ! p5_confirm "Appliquer le plan Terraform de l'exercice $exercise ($label) ?"; then
        p5_warn "Application Terraform exercice $exercise annulée par l'opérateur."
        return 130
    fi

    p5_run_step "tf-ex${exercise}-apply" "Terraform exercice $exercise — apply" \
        terraform -chdir="$module_dir" apply -input=false -auto-approve tfplan
    rm -f "$plan_file"
    p5_run_step "tf-ex${exercise}-output" "Terraform exercice $exercise — outputs" \
        terraform -chdir="$module_dir" output
}

wait_for_ssh_ex1() {
    load_lab_config
    local ip public_key private_key attempt
    ip="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" \
        output -raw web_public_ip)"
    public_key="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
    public_key="${public_key/#\~/$HOME}"
    private_key="${P5_SSH_KEY_PATH:-${public_key%.pub}}"
    private_key="${private_key/#\~/$HOME}"

    local ssh_options=(
        -i "$private_key"
        -o BatchMode=yes
        -o ConnectTimeout=5
        -o StrictHostKeyChecking=accept-new
    )

    printf 'Attente de la cible SSH %s\n' "$ip"
    for ((attempt = 1; attempt <= 48; attempt++)); do
        if ssh "${ssh_options[@]}" "ubuntu@$ip" \
            'command -v python3 >/dev/null && cloud-init status --wait >/dev/null 2>&1' \
            >/dev/null 2>&1; then
            printf 'SSH prêt après %s tentative(s).\n' "$attempt"
            return 0
        fi
        printf '  tentative %02d/48 : instance pas encore prête\n' "$attempt"
        sleep 5
    done
    p5_error 'La cible EC2 de l’exercice 1 ne répond pas correctement en SSH.'
    return 1
}

wait_for_http_output() {
    local module="$1"
    local output_name="$2"
    local label="$3"
    local url attempt
    url="$(terraform -chdir="$module" output -raw "$output_name")"
    printf 'Attente HTTP : %s\n' "$url"
    for ((attempt = 1; attempt <= 60; attempt++)); do
        if curl -fsS --max-time 5 "$url/" >/dev/null 2>&1; then
            printf '%s disponible après %s tentative(s).\n' "$label" "$attempt"
            return 0
        fi
        printf '  tentative %02d/60 : service pas encore prêt\n' "$attempt"
        sleep 5
    done
    p5_error "$label n'est pas devenu accessible : $url"
    return 1
}

run_prepare() {
    p5_header 'PHASE 0 — Préparer le lab'
    ensure_toolchain

    local configure_args=()
    if [[ "$ASSUME_YES" == true ]]; then
        configure_args+=(--yes)
    fi
    p5_run_step 'configure-lab' 'Configurer automatiquement le lab local' \
        bash "$SCRIPT_DIR/configure-lab.sh" "${configure_args[@]}"

    load_lab_config
    p5_run_step 'budget-preview' 'Prévisualiser le garde-fou de budget AWS' \
        bash "$SCRIPT_DIR/setup-aws-guardrails.sh"
    if p5_confirm "Créer ou mettre à jour le budget AWS '$P5_BUDGET_NAME' ?"; then
        p5_run_step 'budget-apply' 'Appliquer le garde-fou de budget AWS' \
            bash "$SCRIPT_DIR/setup-aws-guardrails.sh" --apply
    else
        p5_error 'Le budget AWS est requis par le contrôle AWS Ready.'
        return 1
    fi

    if terraform_state_has_resources 1; then
        p5_warn 'Un état Terraform de l’exercice 1 existe déjà : mode reprise activé.'
        run_validation
        p5_run_step 'aws-ready-resume' 'Contrôler AWS en mode reprise' \
            bash "$SCRIPT_DIR/check-aws-readiness.sh" --stage exercice-3
    else
        p5_run_step 'precheck-initial' 'Précontrôle complet avant le premier déploiement' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage initial
        if [[ "$FULL_VALIDATION" == true ]]; then
            run_validation
        fi
    fi

    P5_PREPARED_THIS_RUN=true
    p5_ok 'Phase 0 terminée : environnement prêt pour Terraform.'
}

run_status() {
    p5_header 'STATUT — contrôles sans mutation AWS'
    ensure_toolchain

    if [[ ! -r "$CONFIG_FILE" ]]; then
        p5_run_step 'setup-status' 'Contrôle local de la VM et du dépôt' \
            bash "$SCRIPT_DIR/setup.sh" --check-only
        p5_warn 'environment/aws-readiness.env absent : exécutez prepare pour la partie AWS.'
        return 0
    fi

    load_lab_config
    p5_run_step 'tfvars-status' 'Vérifier la synchronisation des tfvars' \
        bash "$SCRIPT_DIR/sync-terraform-tfvars.sh" --check

    if terraform_state_has_resources 1; then
        p5_run_step 'aws-status-resume' 'Contrôle AWS en mode lab existant' \
            bash "$SCRIPT_DIR/check-aws-readiness.sh" --stage exercice-3
        run_validation
    else
        p5_run_step 'precheck-status' 'Précontrôle complet avant déploiement' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage initial
        if [[ "$FULL_VALIDATION" == true ]]; then
            run_validation
        fi
    fi
}

run_ex1() {
    p5_header 'EXERCICE 1 — Terraform + Ansible + Angular + NGINX'
    load_lab_config

    if [[ "$P5_PREPARED_THIS_RUN" != true ]] && ! terraform_state_has_resources 1; then
        p5_run_step 'precheck-ex1' 'Précontrôle exercice 1' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage initial
    elif terraform_state_has_resources 1; then
        p5_info 'État Terraform exercice 1 détecté : vérification/reprise du déploiement.'
    fi

    p5_run_step 'angular-build' 'Construire l’artefact Angular reproductible' \
        bash "$SCRIPT_DIR/prepare-angular-artifact.sh"
    terraform_apply_exercise 1 'VPC + EC2 Angular'
    p5_run_step 'inventory' 'Générer automatiquement l’inventaire Ansible' \
        bash "$SCRIPT_DIR/generate-ansible-inventory.sh"
    p5_run_step 'wait-ssh-ex1' 'Attendre la disponibilité SSH de l’EC2' \
        wait_for_ssh_ex1
    p5_run_step 'ansible-ping' 'Tester la cible avec Ansible' \
        ansible all -i "$INVENTORY_FILE" -m ping
    p5_run_step 'ansible-deploy' 'Déployer Angular et NGINX avec Ansible' \
        ansible-playbook -i "$INVENTORY_FILE" "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
    p5_run_step 'verify-angular' 'Vérifier Angular derrière NGINX' \
        bash "$SCRIPT_DIR/verify-angular-deployment.sh"
    p5_run_step 'nginx-traffic' 'Générer le trafic NGINX de démonstration' \
        bash "$SCRIPT_DIR/generate-nginx-traffic.sh" --requests 96
    p5_run_step 'nginx-log-collect' 'Collecter les vrais logs NGINX' \
        bash "$SCRIPT_DIR/collect-nginx-access-log.sh" \
        --output "$PROJECT_ROOT/proofs/runtime/exercice-2/nginx-access-real.log"
    p5_ok 'Exercice 1 opérationnel et preuves runtime collectées.'
}

run_ex2() {
    p5_header 'EXERCICE 2 — OpenSearch + données + dashboard'
    load_lab_config

    if terraform_state_has_resources 2; then
        p5_info 'État Terraform exercice 2 détecté : vérification/reprise du déploiement.'
    else
        p5_run_step 'precheck-ex2' 'Précontrôle exercice 2' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage exercice-2
    fi

    terraform_apply_exercise 2 'Amazon OpenSearch'
    p5_run_step 'opensearch-import-preview' 'Valider la conversion des données OpenSearch' \
        bash "$SCRIPT_DIR/import-opensearch-data.sh"
    if ! p5_confirm 'Importer le jeu de données reproductible dans OpenSearch ?'; then
        p5_error 'L’import OpenSearch est nécessaire pour valider l’exercice 2.'
        return 1
    fi
    p5_run_step 'opensearch-import' 'Importer les données dans OpenSearch' \
        bash "$SCRIPT_DIR/import-opensearch-data.sh" --apply
    p5_run_step 'opensearch-verify' 'Vérifier mappings et agrégations OpenSearch' \
        bash "$SCRIPT_DIR/verify-opensearch-data.sh"

    local dashboards_url
    dashboards_url="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-2" \
        output -raw opensearch_dashboards_endpoint)"
    p5_manual_checkpoint 'Dashboard OpenSearch' \
        "Ouvrir : $dashboards_url" \
        'Créer le donut des méthodes HTTP.' \
        'Créer la somme de bytes_sent par tranches de 12 h.' \
        'Créer le top 5 url_path par tranches de 12 h.' \
        'Enregistrer les captures nécessaires aux livrables.'
    p5_ok 'Exercice 2 validé côté données ; checkpoint dashboard confirmé.'
}

run_ex3() {
    p5_header 'EXERCICE 3 — HAProxy + deux backends'
    load_lab_config

    if terraform_state_has_resources 3; then
        p5_info 'État Terraform exercice 3 détecté : vérification/reprise du déploiement.'
    else
        p5_run_step 'precheck-ex3' 'Précontrôle exercice 3' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage exercice-3
    fi

    terraform_apply_exercise 3 'HAProxy + 2 serveurs nginxdemos/hello'
    p5_run_step 'wait-haproxy' 'Attendre la disponibilité HTTP de HAProxy' \
        wait_for_http_output "$PROJECT_ROOT/terraform/exercice-3" haproxy_url HAProxy
    p5_run_step 'haproxy-roundrobin' 'Valider le round-robin HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-roundrobin.sh" --requests 12
    p5_run_step 'haproxy-failover-preview' 'Prévisualiser le scénario de panne HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-failover.sh"
    if ! p5_confirm 'Exécuter réellement l’arrêt puis la reprise d’un backend ?'; then
        p5_error 'Le test réel de failover est requis pour la preuve de l’exercice 3.'
        return 1
    fi
    p5_run_step 'haproxy-failover' 'Tester la panne et la réintégration HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-failover.sh" --apply
    p5_ok 'Exercice 3 : round-robin, panne et reprise validés.'
}

run_diagnostics() {
    p5_run_step 'diagnostics' 'Collecter les diagnostics complets et les preuves' \
        bash "$SCRIPT_DIR/collect-diagnostics.sh" --complet --avec-preuves
    p5_run_step 'livrables-structure' 'Contrôler la structure des livrables' \
        bash "$SCRIPT_DIR/prepare-livrables.sh" --structure-only
}

run_finalize() {
    p5_header 'FINALISATION — preuves et livrables'
    run_diagnostics
    if p5_run_step 'livrables-strict' 'Contrôle strict des livrables avant remise' \
        bash "$SCRIPT_DIR/prepare-livrables.sh"; then
        p5_ok 'Livrables prêts pour relecture finale.'
    else
        p5_warn 'Le contrôle strict des livrables signale encore des éléments à compléter.'
        p5_action 'Complétez uniquement les preuves réelles/captures indiquées dans le log, puis relancez finalize.'
        return 1
    fi
}

run_all() {
    p5_header 'MODE ACCÉLÉRÉ — projet P5 de bout en bout'
    run_prepare
    run_ex1
    run_ex2
    run_ex3
    run_diagnostics
    p5_header 'DÉPLOIEMENT COMPLET'
    p5_ok 'Les trois exercices techniques sont déployés et validés.'
    p5_info 'Les ressources AWS restent actives pour la démonstration et la soutenance.'
    p5_info 'Exécutez finalize après insertion des captures/preuves dans les livrables.'
    p5_info 'Exécutez cleanup uniquement lorsque la démonstration est terminée.'
}

run_cleanup() {
    p5_header 'NETTOYAGE AWS — ordre 3 → 2 → 1'
    load_lab_config
    p5_warn 'Cette commande détruit les ressources Terraform du projet.'
    p5_run_step 'destroy-aws' 'Détruire les ressources AWS du P5' \
        bash "$SCRIPT_DIR/destroy-aws.sh"
    p5_run_step 'cleanup-audit' 'Auditer les ressources AWS restantes' \
        bash "$SCRIPT_DIR/check-aws-cleanup.sh"
    p5_ok 'Nettoyage AWS audité.'
}

show_logs() {
    p5_header 'LOGS P5'
    if [[ ! -d "$PROJECT_ROOT/logs" ]]; then
        p5_info 'Aucun répertoire de logs pour le moment.'
        return 0
    fi
    find "$PROJECT_ROOT/logs" -type f -name '*.log' \
        -printf '%TY-%Tm-%Td %TH:%TM:%TS  %p\n' 2>/dev/null \
        | sort -r \
        | sed -n '1,80p'
}

run_menu() {
    while true; do
        p5_header 'CENTRE DE COMMANDE'
        cat <<'MENU'
  1  Préparer le lab
  2  Exercice 1 — Terraform / Ansible / Angular
  3  Exercice 2 — OpenSearch / dashboard
  4  Exercice 3 — HAProxy
  5  Tout exécuter de A à Z
  6  Statut / contrôles
  7  Finaliser les livrables
  8  Afficher les logs
  9  Nettoyer AWS
  q  Quitter
MENU
        printf '\nVotre choix : '
        local choice
        read -r choice
        case "${choice,,}" in
            1) run_prepare ;;
            2) run_ex1 ;;
            3) run_ex2 ;;
            4) run_ex3 ;;
            5) run_all ;;
            6) run_status ;;
            7) run_finalize ;;
            8) show_logs ;;
            9) run_cleanup ;;
            q|quit|exit) return 0 ;;
            *) p5_warn 'Choix inconnu.' ;;
        esac
        printf '\nAppuyez sur Entrée pour revenir au menu...'
        read -r _
    done
}

case "$COMMAND" in
    menu) run_menu ;;
    prepare) run_prepare ;;
    status) run_status ;;
    ex1) run_ex1 ;;
    ex2) run_ex2 ;;
    ex3) run_ex3 ;;
    all) run_all ;;
    finalize) run_finalize ;;
    cleanup) run_cleanup ;;
    logs) show_logs ;;
esac

p5_latest_log_hint
