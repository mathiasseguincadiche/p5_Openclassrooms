#!/usr/bin/env bash
# Orchestrateur convergent du projet P5 OpenClassrooms.
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
P5 OpenClassrooms — centre de commande convergent

Usage:
  bash scripts/commands/p5.sh [commande] [options]

Commandes:
  menu       afficher le menu interactif (défaut)
  inspect    observer l'état réel sans aucune mutation
  prepare    inspecter puis converger VM, AWS, tfvars et garde-fous
  status     lancer les contrôles de préparation sans mutation
  ex1        converger Terraform + Ansible + NGINX + Angular puis vérifier
  ex2        converger OpenSearch, données et vérifier les agrégations
  ex3        converger HAProxy + 2 backends puis tester panne/reprise
  all        exécuter prepare + ex1 + ex2 + ex3 + diagnostics
  finalize   contrôler les livrables et collecter les diagnostics complets
  cleanup    détruire AWS dans l'ordre prévu puis auditer le nettoyage
  logs       afficher les journaux disponibles
  help       afficher cette aide

Options globales:
  --yes              confirmer automatiquement les mutations automatisables
                     (jamais les preuves manuelles ni la destruction finale)
  --full-validation  inclure OpenSearch local dans la validation du dépôt

Principe :
  inspecter -> comparer -> corriger uniquement le delta -> vérifier -> journaliser.

Un `terraform plan` vide n'est jamais appliqué. Une VM déjà conforme n'est pas
réinstallée. Les tests fonctionnels restent rejoués afin de vérifier l'état réel.

Exemples:
  bash scripts/commands/p5.sh inspect
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
        menu|inspect|prepare|status|ex1|ex2|ex3|all|finalize|cleanup|logs)
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

load_nvm_if_present() {
    export NVM_DIR="$HOME/.nvm"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
    fi
}

toolchain_state() {
    bash "$SCRIPT_DIR/bootstrap-ubuntu-server.sh" --check-only
}

ensure_toolchain() {
    local rc
    set +e
    toolchain_state
    rc=$?
    set -e
    case "$rc" in
        0)
            load_nvm_if_present
            p5_ok 'VM déjà convergée : aucune installation nécessaire.'
            return 0
            ;;
        90)
            p5_header 'RECONNEXION REQUISE'
            p5_action 'Les outils sont déjà installés ; seul le groupe Docker n’est pas actif dans ce shell.'
            p5_action 'Déconnectez-vous de la VM, reconnectez-vous, puis relancez exactement la même commande P5.'
            return 90
            ;;
        *)
            p5_warn 'La VM présente un ou plusieurs écarts par rapport à l’état cible P5.'
            ;;
    esac

    if ! p5_confirm 'Converger uniquement les outils/versions manquants ou incorrects ?'; then
        p5_error 'La VM doit être convergée avant de poursuivre.'
        return 1
    fi

    p5_run_step_allow '0 90' 'bootstrap' 'Converger le socle DevOps de la VM' \
        bash "$SCRIPT_DIR/bootstrap-ubuntu-server.sh"
    rc="$P5_LAST_STEP_RC"
    load_nvm_if_present
    if [[ "$rc" == 90 ]]; then
        p5_header 'RECONNEXION REQUISE'
        p5_action 'La convergence a ajouté votre utilisateur au groupe Docker.'
        p5_action 'Reconnectez-vous puis relancez exactement la même commande P5.'
        p5_latest_log_hint
        return 90
    fi
    p5_ok 'VM convergée et utilisable dans ce shell.'
}

terraform_state_has_resources() {
    local exercise="$1"
    local module_dir="$PROJECT_ROOT/terraform/exercice-$exercise"
    [[ -f "$module_dir/terraform.tfstate" ]] || return 1
    terraform -chdir="$module_dir" state list 2>/dev/null | grep -q .
}

run_inspect() {
    p5_run_step 'inspect-state' 'Observer l’état réel sans mutation' \
        bash "$SCRIPT_DIR/inspect-state.sh"
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
    local plan_rc

    load_lab_config
    p5_run_step "tf-ex${exercise}-init" "Terraform exercice $exercise — vérifier/initialiser les providers" \
        terraform -chdir="$module_dir" init -input=false

    p5_run_step_allow '0 2' "tf-ex${exercise}-plan" \
        "Terraform exercice $exercise — rafraîchir AWS et calculer le delta" \
        terraform -chdir="$module_dir" plan -input=false -detailed-exitcode -out=tfplan
    plan_rc="$P5_LAST_STEP_RC"

    p5_run_step "tf-ex${exercise}-show" "Terraform exercice $exercise — afficher l’état/delta calculé" \
        terraform -chdir="$module_dir" show -no-color tfplan

    if [[ "$plan_rc" == 0 ]]; then
        rm -f "$plan_file"
        p5_ok "Terraform exercice $exercise : infrastructure déjà conforme — aucun apply."
        p5_run_step "tf-ex${exercise}-output" "Terraform exercice $exercise — relire les outputs existants" \
            terraform -chdir="$module_dir" output
        return 0
    fi

    p5_warn "Terraform exercice $exercise a détecté un delta réel avec AWS."
    if ! p5_confirm "Appliquer uniquement ce delta pour l'exercice $exercise ($label) ?"; then
        p5_warn "Convergence Terraform exercice $exercise annulée par l'opérateur."
        return 130
    fi

    p5_run_step "tf-ex${exercise}-apply" "Terraform exercice $exercise — appliquer le delta sauvegardé" \
        terraform -chdir="$module_dir" apply -input=false -auto-approve tfplan
    rm -f "$plan_file"

    p5_run_step "tf-ex${exercise}-post-plan" \
        "Terraform exercice $exercise — prouver l’absence de delta après apply" \
        terraform -chdir="$module_dir" plan -input=false -detailed-exitcode

    p5_run_step "tf-ex${exercise}-output" "Terraform exercice $exercise — outputs convergés" \
        terraform -chdir="$module_dir" output
}

wait_for_ssh_ex1() {
    load_lab_config
    local ip public_key private_key attempt
    ip="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-1" output -raw web_public_ip)"
    public_key="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
    public_key="${public_key/#\~/$HOME}"
    private_key="${P5_SSH_KEY_PATH:-${public_key%.pub}}"
    private_key="${private_key/#\~/$HOME}"
    local ssh_options=(-i "$private_key" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)

    printf 'Vérification de la cible SSH %s\n' "$ip"
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
    local module="$1" output_name="$2" label="$3" url attempt
    url="$(terraform -chdir="$module" output -raw "$output_name")"
    printf 'Vérification HTTP : %s\n' "$url"
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

verify_ansible_idempotence() {
    local recap_file rc
    recap_file="$(mktemp)"
    set +e
    ansible-playbook -i "$INVENTORY_FILE" \
        "$PROJECT_ROOT/ansible/playbooks/deploy.yml" 2>&1 | tee "$recap_file"
    rc=${PIPESTATUS[0]}
    set -e
    if ((rc != 0)); then
        rm -f "$recap_file"
        return "$rc"
    fi
    if ! grep -Eq 'changed=0.*unreachable=0.*failed=0' "$recap_file" \
        || grep -Eq 'changed=[1-9][0-9]*|unreachable=[1-9][0-9]*|failed=[1-9][0-9]*' "$recap_file"; then
        p5_error 'La seconde exécution Ansible ne prouve pas un état convergé sans changement.'
        rm -f "$recap_file"
        return 1
    fi
    rm -f "$recap_file"
    p5_ok 'Idempotence Ansible confirmée : changed=0, unreachable=0, failed=0.'
}

run_prepare() {
    p5_header 'PHASE 0 — INSPECTER PUIS CONVERGER LE LAB'
    run_inspect
    ensure_toolchain

    local configure_args=()
    if [[ "$ASSUME_YES" == true ]]; then
        configure_args+=(--yes)
    fi
    p5_run_step 'configure-lab' 'Réconcilier authentification/configuration AWS locale' \
        bash "$SCRIPT_DIR/configure-lab.sh" "${configure_args[@]}"

    load_lab_config
    if bash "$SCRIPT_DIR/setup-aws-guardrails.sh" --check >/dev/null 2>&1; then
        p5_ok "Budget AWS '$P5_BUDGET_NAME' déjà conforme — aucune mutation."
    else
        p5_run_step 'budget-preview' 'Observer le delta du garde-fou de budget AWS' \
            bash "$SCRIPT_DIR/setup-aws-guardrails.sh"
        if p5_confirm "Converger uniquement les écarts du budget AWS '$P5_BUDGET_NAME' ?"; then
            p5_run_step 'budget-apply' 'Converger le garde-fou de budget AWS' \
                bash "$SCRIPT_DIR/setup-aws-guardrails.sh" --apply
        else
            p5_error 'Le budget AWS conforme est requis par le contrôle AWS Ready.'
            return 1
        fi
    fi

    if terraform_state_has_resources 1; then
        p5_info 'État Terraform exercice 1 détecté : mode reprise/réconciliation.'
        run_validation
        p5_run_step 'aws-ready-resume' 'Contrôler AWS en mode lab existant' \
            bash "$SCRIPT_DIR/check-aws-readiness.sh" --stage exercice-3
    else
        p5_run_step 'precheck-initial' 'Précontrôle complet avant le premier déploiement' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage initial
        if [[ "$FULL_VALIDATION" == true ]]; then
            run_validation
        fi
    fi

    P5_PREPARED_THIS_RUN=true
    p5_ok 'Phase 0 terminée : état observé et prérequis convergés.'
}

run_status() {
    p5_header 'STATUT — OBSERVATION ET CONTRÔLES SANS MUTATION'
    run_inspect

    local rc
    set +e
    toolchain_state >/dev/null 2>&1
    rc=$?
    set -e
    if [[ "$rc" == 90 ]]; then
        p5_warn 'VM installée mais reconnexion requise pour Docker.'
        return 90
    fi
    if [[ "$rc" != 0 ]]; then
        p5_warn 'VM non convergée ; `prepare` pourra corriger uniquement les écarts.'
        return 1
    fi
    load_nvm_if_present

    if [[ ! -r "$CONFIG_FILE" ]]; then
        p5_warn 'Configuration AWS locale absente ; aucune connexion n’est déclenchée par status.'
        return 0
    fi

    load_lab_config
    p5_run_step 'tfvars-status' 'Vérifier la synchronisation des tfvars' \
        bash "$SCRIPT_DIR/sync-terraform-tfvars.sh" --check
    p5_run_step 'budget-status' 'Vérifier le garde-fou de budget sans mutation' \
        bash "$SCRIPT_DIR/setup-aws-guardrails.sh" --check

    if terraform_state_has_resources 1; then
        p5_run_step 'aws-status-resume' 'Contrôler AWS en mode lab existant' \
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
    p5_header 'EXERCICE 1 — CONVERGER TERRAFORM + ANSIBLE + ANGULAR + NGINX'
    load_lab_config
    if [[ "$P5_PREPARED_THIS_RUN" != true ]] && ! terraform_state_has_resources 1; then
        p5_run_step 'precheck-ex1' 'Précontrôle exercice 1' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage initial
    elif terraform_state_has_resources 1; then
        p5_info 'État exercice 1 existant : Terraform calculera le delta au lieu de recréer.'
    fi

    p5_run_step 'angular-build' 'Vérifier/converger l’artefact Angular' \
        bash "$SCRIPT_DIR/prepare-angular-artifact.sh"
    terraform_apply_exercise 1 'VPC + EC2 Angular'
    p5_run_step 'inventory' 'Vérifier/converger l’inventaire Ansible depuis Terraform' \
        bash "$SCRIPT_DIR/generate-ansible-inventory.sh"
    p5_run_step 'wait-ssh-ex1' 'Vérifier la disponibilité SSH de l’EC2' wait_for_ssh_ex1
    p5_run_step 'ansible-ping' 'Vérifier la cible avec Ansible' \
        ansible all -i "$INVENTORY_FILE" -m ping
    p5_run_step 'ansible-deploy' 'Converger Angular et NGINX avec Ansible' \
        ansible-playbook -i "$INVENTORY_FILE" "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
    p5_run_step 'ansible-idempotence' 'Prouver l’état convergé du playbook Ansible' verify_ansible_idempotence
    p5_run_step 'verify-angular' 'Vérifier Angular derrière NGINX' \
        bash "$SCRIPT_DIR/verify-angular-deployment.sh"
    p5_run_step 'nginx-traffic' 'Rejouer le trafic NGINX de preuve' \
        bash "$SCRIPT_DIR/generate-nginx-traffic.sh" --requests 96
    p5_run_step 'nginx-log-collect' 'Actualiser la collecte des vrais logs NGINX' \
        bash "$SCRIPT_DIR/collect-nginx-access-log.sh" \
        --output "$PROJECT_ROOT/proofs/runtime/exercice-2/nginx-access-real.log"
    p5_ok 'Exercice 1 convergé et état fonctionnel revérifié.'
}

run_ex2() {
    p5_header 'EXERCICE 2 — CONVERGER OPENSEARCH + DONNÉES + PREUVES'
    load_lab_config
    local real_log="$PROJECT_ROOT/proofs/runtime/exercice-2/nginx-access-real.log"

    if terraform_state_has_resources 2; then
        p5_info 'État exercice 2 existant : Terraform et OpenSearch seront réconciliés.'
    else
        p5_run_step 'precheck-ex2' 'Précontrôle exercice 2' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage exercice-2
    fi

    terraform_apply_exercise 2 'Amazon OpenSearch'
    p5_run_step 'opensearch-sample-preview' 'Valider le jeu reproductible OpenSearch' \
        bash "$SCRIPT_DIR/import-opensearch-data.sh"
    if [[ -s "$real_log" ]]; then
        p5_run_step 'opensearch-real-preview' 'Valider les vrais logs NGINX avant réconciliation' \
            bash "$SCRIPT_DIR/import-opensearch-data.sh" --input "$real_log"
    else
        p5_warn "Log NGINX réel absent : $real_log"
    fi

    if ! p5_confirm 'Converger uniquement le template/documents OpenSearch manquants ou différents ?'; then
        p5_error 'La convergence des données OpenSearch est requise pour valider l’exercice 2.'
        return 1
    fi
    p5_run_step 'opensearch-sample-import' 'Réconcilier le jeu reproductible avec OpenSearch' \
        bash "$SCRIPT_DIR/import-opensearch-data.sh" --apply
    if [[ -s "$real_log" ]]; then
        p5_run_step 'opensearch-real-import' 'Réconcilier les vrais logs NGINX avec OpenSearch' \
            bash "$SCRIPT_DIR/import-opensearch-data.sh" --input "$real_log" --apply
    fi
    p5_run_step 'opensearch-verify' 'Vérifier mappings et agrégations OpenSearch' \
        bash "$SCRIPT_DIR/verify-opensearch-data.sh"

    local dashboards_url
    dashboards_url="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-2" output -raw opensearch_dashboards_endpoint)"
    p5_manual_checkpoint 'Dashboard OpenSearch' \
        "Ouvrir : $dashboards_url" \
        'Vérifier/créer le donut des méthodes HTTP.' \
        'Vérifier/créer la somme de bytes_sent par tranches de 12 h.' \
        'Vérifier/créer le top 5 url_path par tranches de 12 h.' \
        'Enregistrer les captures nécessaires aux livrables.'
    p5_ok 'Exercice 2 convergé côté infrastructure/données et preuve visuelle confirmée.'
}

run_ex3() {
    p5_header 'EXERCICE 3 — CONVERGER HAPROXY + DEUX BACKENDS'
    load_lab_config
    if terraform_state_has_resources 3; then
        p5_info 'État exercice 3 existant : Terraform calculera uniquement le delta.'
    else
        p5_run_step 'precheck-ex3' 'Précontrôle exercice 3' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage exercice-3
    fi

    terraform_apply_exercise 3 'HAProxy + 2 serveurs nginxdemos/hello'
    p5_run_step 'wait-haproxy' 'Vérifier la disponibilité HTTP de HAProxy' \
        wait_for_http_output "$PROJECT_ROOT/terraform/exercice-3" haproxy_url HAProxy
    p5_run_step 'haproxy-roundrobin' 'Revérifier le round-robin HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-roundrobin.sh" --requests 12
    p5_run_step 'haproxy-failover-preview' 'Observer le scénario de panne HAProxy avant mutation temporaire' \
        bash "$SCRIPT_DIR/test-haproxy-failover.sh"
    if ! p5_confirm 'Rejouer le test réel d’arrêt puis de reprise d’un backend pour vérifier la résilience actuelle ?'; then
        p5_error 'Le test réel de failover est requis pour une validation actuelle de l’exercice 3.'
        return 1
    fi
    p5_run_step 'haproxy-failover' 'Tester la panne et la réintégration HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-failover.sh" --apply
    p5_ok 'Exercice 3 convergé ; round-robin, panne et reprise revérifiés.'
}

run_diagnostics() {
    p5_run_step 'diagnostics' 'Collecter les diagnostics complets et les preuves' \
        bash "$SCRIPT_DIR/collect-diagnostics.sh" --complet --avec-preuves
    p5_run_step 'livrables-structure' 'Contrôler la structure des livrables' \
        bash "$SCRIPT_DIR/prepare-livrables.sh" --structure-only
}

run_finalize() {
    p5_header 'FINALISATION — PREUVES ET LIVRABLES'
    run_diagnostics
    if p5_run_step 'livrables-strict' 'Contrôle strict des livrables avant remise' \
        bash "$SCRIPT_DIR/prepare-livrables.sh"; then
        p5_ok 'Livrables prêts pour relecture finale.'
    else
        p5_warn 'Le contrôle strict signale encore des éléments à compléter.'
        p5_action 'Complétez uniquement les preuves/captures indiquées dans le log, puis relancez finalize.'
        return 1
    fi
}

run_all() {
    p5_header 'MODE CONVERGENT — PROJET P5 DE BOUT EN BOUT'
    run_prepare
    run_ex1
    run_ex2
    run_ex3
    run_diagnostics
    p5_header 'DÉPLOIEMENT CONVERGÉ ET VÉRIFIÉ'
    p5_ok 'Les trois exercices correspondent à l’état attendu et les tests actuels sont validés.'
    p5_info 'Les ressources AWS restent actives pour la démonstration et la soutenance.'
    p5_info 'Une nouvelle exécution recalculera les écarts au lieu de tout refaire.'
}

run_cleanup() {
    p5_header 'NETTOYAGE AWS — ORDRE 3 → 2 → 1'
    load_lab_config
    p5_warn 'Cette commande ne détruit que les ressources encore suivies par Terraform.'
    p5_run_step 'destroy-aws' 'Détruire les ressources AWS P5 encore présentes' \
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
        | sort -r | sed -n '1,80p'
}

run_menu() {
    while true; do
        p5_header 'CENTRE DE COMMANDE'
        cat <<'MENU'
  1  Inspecter l'état actuel — aucune mutation
  2  Préparer / converger le lab
  3  Exercice 1 — Terraform / Ansible / Angular
  4  Exercice 2 — OpenSearch / dashboard
  5  Exercice 3 — HAProxy
  6  Tout exécuter de A à Z
  7  Statut / contrôles sans mutation
  8  Finaliser les livrables
  9  Afficher les logs
  0  Nettoyer AWS
  q  Quitter
MENU
        printf '\nVotre choix : '
        local choice
        read -r choice
        case "${choice,,}" in
            1) run_inspect ;;
            2) run_prepare ;;
            3) run_ex1 ;;
            4) run_ex2 ;;
            5) run_ex3 ;;
            6) run_all ;;
            7) run_status ;;
            8) run_finalize ;;
            9) show_logs ;;
            0) run_cleanup ;;
            q|quit|exit) return 0 ;;
            *) p5_warn 'Choix inconnu.' ;;
        esac
        printf '\nAppuyez sur Entrée pour revenir au menu...'
        read -r _
    done
}

case "$COMMAND" in
    menu) run_menu ;;
    inspect) run_inspect ;;
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
