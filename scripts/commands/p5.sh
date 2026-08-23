#!/usr/bin/env bash
# Orchestrateur convergent du projet P5 OpenClassrooms.
# Toutes les opérations P5 s'exécutent dans Ubuntu 26.04 sous WSL2 ; Windows,
# le VHDX et la stack DevOps commune restent gérés par Windows_11_Pro_Custom.
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
  menu         afficher le centre de commande interactif (défaut)
  inspect      observer l'état réel sans aucune mutation
  prepare      inspecter puis converger le runtime P5 dans WSL2, AWS, tfvars et garde-fous
  status       lancer les contrôles de préparation sans mutation
  ex1          converger Terraform + Ansible + NGINX + Angular puis vérifier
  ex2          converger OpenSearch, données et Dashboards as Code puis vérifier
  ex3          converger HAProxy + 2 backends puis tester panne/reprise
  all          exécuter prepare + ex1 + ex2 + ex3 + diagnostics
  diagnostics  collecter diagnostics et structure des preuves/livrables
  finalize     contrôler les livrables et collecter les diagnostics complets
  cleanup      détruire AWS dans l'ordre prévu puis auditer le nettoyage
  logs         afficher les journaux disponibles
  guide        expliquer quel parcours choisir selon votre situation
  docs         afficher la carte de la documentation P5
  help         afficher cette aide

Options globales:
  --yes              confirmer automatiquement les mutations automatisables
                     (jamais les preuves manuelles ni la destruction finale)
  --full-validation  inclure OpenSearch local dans la validation du dépôt

Principe :
  inspecter -> comparer -> corriger uniquement le delta -> vérifier -> journaliser.

Un `terraform plan` vide n'est jamais appliqué. Un runtime P5 déjà conforme dans
la distribution WSL2 `Ubuntu` n'est pas modifié inutilement. Le P5 ne crée, ne
déplace et ne supprime jamais la distribution ou son VHDX. Les tests fonctionnels restent rejoués afin de
vérifier l'état réel. Une valeur d'infrastructure nécessaire à `all` doit provenir
de Terraform ; si elle n'est pas vérifiable, l'orchestrateur s'arrête et indique
la source à réparer.

Exemples:
  bash scripts/commands/p5.sh inspect
  bash scripts/commands/p5.sh all
  bash scripts/commands/p5.sh all --yes
  bash scripts/commands/p5.sh status
  bash scripts/commands/p5.sh diagnostics
  bash scripts/commands/p5.sh docs
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
        menu|inspect|prepare|status|ex1|ex2|ex3|all|diagnostics|finalize|cleanup|logs|guide|docs)
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
export P5_ORCHESTRATED=1
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
    bash "$SCRIPT_DIR/bootstrap-wsl2.sh" --check-only
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
            p5_ok 'Runtime P5 déjà convergé dans WSL2 : aucune installation nécessaire.'
            return 0
            ;;
        *)
            p5_warn 'Le runtime P5 dans WSL2 présente un ou plusieurs écarts par rapport à l’état cible.'
            ;;
    esac

    if ! p5_confirm 'Converger uniquement les dépendances P5 manquantes ou incorrectes dans WSL2 ?'; then
        p5_error 'Le runtime P5 dans WSL2 doit être convergé avant de poursuivre.'
        return 1
    fi

    p5_run_step 'bootstrap' 'Converger le runtime P5 dans WSL2' \
        bash "$SCRIPT_DIR/bootstrap-wsl2.sh"
    load_nvm_if_present
    p5_ok 'Runtime P5 convergé et utilisable dans WSL2.'
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

    p5_run_step "tf-ex${exercise}-state-backup-before" \
        "Terraform exercice $exercise — sauvegarder le state avant mutation" \
        bash "$SCRIPT_DIR/snapshot-terraform-state.sh" \
        --exercise "$exercise" --label before-apply

    p5_run_step "tf-ex${exercise}-apply" "Terraform exercice $exercise — appliquer le delta sauvegardé" \
        terraform -chdir="$module_dir" apply -input=false -auto-approve tfplan
    rm -f "$plan_file"

    p5_run_step "tf-ex${exercise}-state-backup-after" \
        "Terraform exercice $exercise — sauvegarder le state convergé" \
        bash "$SCRIPT_DIR/snapshot-terraform-state.sh" \
        --exercise "$exercise" --label after-apply

    p5_run_step "tf-ex${exercise}-post-plan" \
        "Terraform exercice $exercise — prouver l’absence de delta après apply" \
        terraform -chdir="$module_dir" plan -input=false -detailed-exitcode

    p5_run_step "tf-ex${exercise}-output" "Terraform exercice $exercise — outputs convergés" \
        terraform -chdir="$module_dir" output
}

wait_for_ssh_ex1() {
    load_lab_config
    local ip="$1"
    local public_key private_key attempt
    if ! p5_validate_ipv4 "$ip"; then
        p5_authoritative_unknown 'Adresse publique EC2 Angular' \
            'la valeur transmise par Terraform n’est pas une IPv4 valide' \
            'Relancez l’exercice 1 et consultez le log tf-ex1-output.'
        return 1
    fi
    public_key="${P5_SSH_PUBLIC_KEY_PATH:-~/.ssh/p5-key.pub}"
    public_key="${public_key/#\~/$HOME}"
    private_key="${P5_SSH_KEY_PATH:-${public_key%.pub}}"
    private_key="${private_key/#\~/$HOME}"
    if [[ ! -f "$private_key" ]]; then
        p5_unknown 'Clé SSH privée du lab' "fichier absent : $private_key" \
            'Relancez : bash scripts/commands/p5.sh prepare ; le configurateur proposera de créer ou renseigner la clé.'
        return 1
    fi
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
    p5_action "Vérifiez Security Group, route Internet, IP $ip et le log de l’étape wait-ssh-ex1."
    return 1
}

wait_for_http_url() {
    local url="$1" label="$2" attempt
    if ! p5_validate_http_url "$url"; then
        p5_authoritative_unknown "URL HTTP $label" \
            'la valeur transmise par Terraform n’est pas une URL HTTP/HTTPS valide' \
            'Relancez l’exercice Terraform concerné et consultez son log tf-ex*-output.'
        return 1
    fi
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
    p5_action 'Consultez le log de cette étape avant toute modification manuelle.'
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
    p5_header 'PHASE 0 — INSPECTER PUIS CONVERGER LE LAB P5 DANS WSL2'
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
    p5_ok 'Phase 0 terminée : runtime WSL2 observé et prérequis P5 convergés.'
}

run_status() {
    p5_header 'STATUT — OBSERVATION ET CONTRÔLES SANS MUTATION'
    run_inspect

    local rc
    set +e
    toolchain_state >/dev/null 2>&1
    rc=$?
    set -e
    if [[ "$rc" != 0 ]]; then
        p5_warn 'Runtime P5 non convergé dans WSL2 ; `prepare` pourra corriger uniquement les écarts P5.'
        return 1
    fi
    load_nvm_if_present

    if [[ ! -r "$CONFIG_FILE" ]]; then
        p5_warn 'Configuration AWS locale absente ; aucune connexion n’est déclenchée par status.'
        p5_action 'Pour la renseigner : bash scripts/commands/p5.sh prepare'
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

    local web_ip="" web_url=""
    p5_terraform_output web_ip "$PROJECT_ROOT/terraform/exercice-1" web_public_ip \
        'IPv4 publique EC2 Angular' p5_validate_ipv4 \
        'Relancez l’exercice 1 et consultez le log tf-ex1-output.'
    p5_terraform_output web_url "$PROJECT_ROOT/terraform/exercice-1" web_url \
        'URL publique Angular/NGINX' p5_validate_http_url \
        'Relancez l’exercice 1 et consultez le log tf-ex1-output.'

    p5_run_step 'inventory' 'Vérifier/converger l’inventaire Ansible depuis Terraform' \
        bash "$SCRIPT_DIR/generate-ansible-inventory.sh"
    p5_run_step 'wait-ssh-ex1' 'Vérifier la disponibilité SSH de l’EC2' wait_for_ssh_ex1 "$web_ip"
    p5_run_step 'ansible-ping' 'Vérifier la cible avec Ansible' \
        ansible all -i "$INVENTORY_FILE" -m ping
    p5_run_step 'ansible-deploy' 'Converger Angular et NGINX avec Ansible' \
        ansible-playbook -i "$INVENTORY_FILE" "$PROJECT_ROOT/ansible/playbooks/deploy.yml"
    p5_run_step 'ansible-idempotence' 'Prouver l’état convergé du playbook Ansible' verify_ansible_idempotence
    p5_run_step 'verify-angular' 'Vérifier Angular derrière NGINX' \
        bash "$SCRIPT_DIR/verify-angular-deployment.sh" --url "$web_url"
    p5_run_step 'nginx-traffic' 'Rejouer le trafic NGINX de preuve' \
        bash "$SCRIPT_DIR/generate-nginx-traffic.sh" --url "$web_url" --requests 96
    p5_run_step 'nginx-log-collect' 'Actualiser la collecte des vrais logs NGINX' \
        bash "$SCRIPT_DIR/collect-nginx-access-log.sh" \
        --host "$web_ip" \
        --output "$PROJECT_ROOT/proofs/runtime/exercice-2/nginx-access-real.log"
    p5_ok 'Exercice 1 convergé et état fonctionnel revérifié.'
}

run_ex2() {
    p5_header 'EXERCICE 2 — CONVERGER OPENSEARCH + DONNÉES + DASHBOARDS AS CODE'
    load_lab_config
    local real_log="$PROJECT_ROOT/proofs/runtime/exercice-2/nginx-access-real.log"

    if terraform_state_has_resources 2; then
        p5_info 'État exercice 2 existant : Terraform, OpenSearch et Dashboards seront réconciliés.'
    else
        p5_run_step 'precheck-ex2' 'Précontrôle exercice 2' \
            bash "$SCRIPT_DIR/pre-deployment-check.sh" --stage exercice-2
    fi

    terraform_apply_exercise 2 'Amazon OpenSearch'

    local opensearch_endpoint="" dashboards_url="" dashboard_id="" dashboard_direct_url=""
    p5_terraform_output opensearch_endpoint "$PROJECT_ROOT/terraform/exercice-2" opensearch_endpoint \
        'Endpoint Amazon OpenSearch' p5_validate_http_url \
        'Relancez l’exercice 2 et consultez le log tf-ex2-output.'
    p5_terraform_output dashboards_url "$PROJECT_ROOT/terraform/exercice-2" opensearch_dashboards_endpoint \
        'URL OpenSearch Dashboards' p5_validate_http_url \
        'Relancez l’exercice 2 et consultez le log tf-ex2-output.'

    p5_run_step 'opensearch-sample-preview' 'Valider le jeu reproductible OpenSearch' \
        bash "$SCRIPT_DIR/import-opensearch-data.sh"
    if [[ -s "$real_log" ]]; then
        p5_run_step 'opensearch-real-preview' 'Valider les vrais logs NGINX avant réconciliation' \
            bash "$SCRIPT_DIR/import-opensearch-data.sh" --input "$real_log"
    else
        p5_warn "Log NGINX réel absent : $real_log"
        p5_action 'Relancez l’exercice 1 pour produire et collecter les vrais logs NGINX.'
    fi

    if ! p5_confirm 'Converger uniquement le template/documents OpenSearch manquants ou différents ?'; then
        p5_error 'La convergence des données OpenSearch est requise pour valider l’exercice 2.'
        return 1
    fi
    p5_run_step 'opensearch-sample-import' 'Réconcilier le jeu reproductible avec OpenSearch' \
        bash "$SCRIPT_DIR/import-opensearch-data.sh" --endpoint "$opensearch_endpoint" --apply
    if [[ -s "$real_log" ]]; then
        p5_run_step 'opensearch-real-import' 'Réconcilier les vrais logs NGINX avec OpenSearch' \
            bash "$SCRIPT_DIR/import-opensearch-data.sh" --input "$real_log" \
            --endpoint "$opensearch_endpoint" --apply
    fi
    p5_run_step 'opensearch-verify' 'Vérifier mappings et agrégations OpenSearch' \
        bash "$SCRIPT_DIR/verify-opensearch-data.sh" --endpoint "$opensearch_endpoint"

    p5_run_step 'dashboards-assets-preview' 'Générer et valider le bundle OpenSearch Dashboards' \
        bash "$SCRIPT_DIR/sync-opensearch-dashboards.sh"

    if ! p5_confirm 'Réconcilier les Saved Objects OpenSearch Dashboards versionnés du P5 ?'; then
        p5_error 'Le dashboard versionné est requis pour valider complètement l’exercice 2.'
        return 1
    fi
    p5_run_step 'dashboards-assets-sync' \
        'Créer/réconcilier l’index pattern, les trois visualisations et le dashboard' \
        bash "$SCRIPT_DIR/sync-opensearch-dashboards.sh" \
        --endpoint "$opensearch_endpoint" \
        --dashboards-url "$dashboards_url" \
        --apply

    dashboard_id="$(jq -r '.dashboard.id' \
        "$PROJECT_ROOT/terraform/exercice-2/opensearch/dashboards/p5-dashboard.json")"
    dashboard_direct_url="${dashboards_url%/}/app/dashboards#/view/$dashboard_id"

    p5_manual_checkpoint 'Contrôle visuel OpenSearch Dashboards' \
        "Ouvrir le dashboard déjà généré : $dashboard_direct_url" \
        'Vérifier le donut des méthodes HTTP.' \
        'Vérifier la somme de bytes_sent par tranches de 12 h.' \
        'Vérifier le top 5 url_path par tranches de 12 h.' \
        'Vérifier la lisibilité du dashboard complet et la plage temporelle.' \
        'Enregistrer les captures nécessaires aux livrables.'
    p5_ok 'Exercice 2 convergé : infrastructure, données et Dashboard as Code vérifiés.'
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

    local haproxy_url="" backend_1_ip=""
    p5_terraform_output haproxy_url "$PROJECT_ROOT/terraform/exercice-3" haproxy_url \
        'URL publique HAProxy' p5_validate_http_url \
        'Relancez l’exercice 3 et consultez le log tf-ex3-output.'
    p5_terraform_output backend_1_ip "$PROJECT_ROOT/terraform/exercice-3" hello_1_public_ip \
        'IPv4 publique du backend HAProxy 1' p5_validate_ipv4 \
        'Relancez l’exercice 3 et consultez le log tf-ex3-output.'

    p5_run_step 'wait-haproxy' 'Vérifier la disponibilité HTTP de HAProxy' \
        wait_for_http_url "$haproxy_url" HAProxy
    p5_run_step 'haproxy-roundrobin' 'Revérifier le round-robin HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-roundrobin.sh" --url "$haproxy_url" --requests 12
    p5_run_step 'haproxy-failover-preview' 'Observer le scénario de panne HAProxy avant mutation temporaire' \
        bash "$SCRIPT_DIR/test-haproxy-failover.sh" \
        --url "$haproxy_url" --backend-host "$backend_1_ip"
    if ! p5_confirm 'Rejouer le test réel d’arrêt puis de reprise d’un backend pour vérifier la résilience actuelle ?'; then
        p5_error 'Le test réel de failover est requis pour une validation actuelle de l’exercice 3.'
        return 1
    fi
    p5_run_step 'haproxy-failover' 'Tester la panne et la réintégration HAProxy' \
        bash "$SCRIPT_DIR/test-haproxy-failover.sh" \
        --url "$haproxy_url" --backend-host "$backend_1_ip" --apply
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

show_docs() {
    p5_header 'CARTE DE LA DOCUMENTATION P5'
    cat <<'DOCS'
JE DÉBUTE
  docs/01-parcours-debutant.md
  → comprendre le parcours, les étapes et les règles essentielles.

JE VEUX EXÉCUTER LE PROJET
  docs/RUNBOOK_EXECUTION_GUIDEE.md
  → procédure opératoire A → Z avec commandes et verdicts attendus.

JE VEUX UTILISER LE MENU
  docs/CENTRE_DE_COMMANDE.md
  → explication de chaque option, risques, mutations et commandes CLI.

JE VEUX COMPRENDRE L'ARCHITECTURE
  docs/architecture-et-flux.md

JE SUIS BLOQUÉ
  docs/troubleshooting.md
  puis : bash scripts/commands/p5.sh inspect
         bash scripts/commands/p5.sh logs
         bash scripts/commands/p5.sh diagnostics

JE PRÉPARE LA SOUTENANCE
  docs/RUNBOOK_SOUTENANCE.md
  docs/validation-preuves-nettoyage.md
  docs/livrables/README.md

PORTAIL COMPLET
  docs/README.md
DOCS
}

show_guidance() {
    while true; do
        p5_header 'QUE DOIS-JE FAIRE MAINTENANT ?'
        cat <<'GUIDE'
  1  C'est ma première exécution du projet
  2  J'ai déjà commencé et je veux reprendre
  3  Je veux seulement vérifier mon environnement
  4  Je veux travailler sur l'exercice 1
  5  Je veux travailler sur l'exercice 2
  6  Je veux travailler sur l'exercice 3
  7  Je prépare mes preuves / ma soutenance
  8  Quelque chose ne fonctionne pas
  9  Je veux fermer le lab et nettoyer AWS
  0  Retour au centre de commande
GUIDE
        printf '\nVotre situation : '
        local choice
        read -r choice
        case "$choice" in
            1)
                cat <<'TXT'

Parcours recommandé dans la distribution Ubuntu sous WSL2 :
  1. bash scripts/commands/p5.sh inspect
  2. bash scripts/commands/p5.sh prepare
  3. bash scripts/commands/p5.sh status
  4. bash scripts/commands/p5.sh all

Pour un parcours guidé complet, `all` conserve les confirmations de sécurité.
TXT
                ;;
            2)
                cat <<'TXT'

Reprise recommandée :
  1. bash scripts/commands/p5.sh inspect
  2. bash scripts/commands/p5.sh all

Ne supprimez jamais un terraform.tfstate pour forcer une reprise. Terraform
recalcule le delta et l'orchestrateur réutilise l'état existant.
TXT
                ;;
            3)
                cat <<'TXT'

Contrôles sans mutation AWS :
  bash scripts/commands/p5.sh inspect
  bash scripts/commands/p5.sh status
TXT
                ;;
            4) printf '\nCommande : bash scripts/commands/p5.sh ex1\n' ;;
            5) printf '\nCommande : bash scripts/commands/p5.sh ex2\n' ;;
            6) printf '\nCommande : bash scripts/commands/p5.sh ex3\n' ;;
            7)
                cat <<'TXT'

Préparation soutenance :
  bash scripts/commands/p5.sh finalize

Puis consulter :
  docs/RUNBOOK_SOUTENANCE.md
  docs/validation-preuves-nettoyage.md
  docs/livrables/README.md
TXT
                ;;
            8)
                cat <<'TXT'

Diagnostic recommandé, sans destruction AWS :
  bash scripts/commands/p5.sh inspect
  bash scripts/commands/p5.sh logs
  bash scripts/commands/p5.sh diagnostics

Puis consulter : docs/troubleshooting.md
TXT
                ;;
            9)
                cat <<'TXT'

Nettoyage final :
  bash scripts/commands/p5.sh cleanup

Cette commande est destructive pour les ressources AWS suivies par Terraform.
La confirmation forte `DETRUIRE` reste obligatoire dans le moteur de nettoyage.
TXT
                ;;
            0) return 0 ;;
            *) p5_warn 'Choix inconnu.' ;;
        esac
        printf '\nAppuyez sur Entrée pour continuer...'
        read -r _
    done
}

menu_action_profile() {
    local level="$1"
    local local_mutation="$2"
    local aws_mutation="$3"
    local cost="$4"
    local command="$5"
    p5_header "ACTION — $level"
    printf 'Mutation locale : %s\n' "$local_mutation"
    printf 'Mutation AWS    : %s\n' "$aws_mutation"
    printf 'Coût AWS        : %s\n' "$cost"
    printf 'Commande CLI    : %s\n' "$command"
}

menu_execute() {
    local title="$1"
    local level="$2"
    local local_mutation="$3"
    local aws_mutation="$4"
    local cost="$5"
    local command="$6"
    local next_step="$7"
    shift 7

    menu_action_profile "$level" "$local_mutation" "$aws_mutation" "$cost" "$command"
    if "$@"; then
        p5_header 'RÉSULTAT'
        p5_ok "$title terminé sans erreur signalée."
        p5_action "Étape recommandée : $next_step"
    else
        local rc=$?
        p5_header 'RÉSULTAT'
        p5_warn "$title s'est arrêté avec le code $rc."
        p5_action 'Consultez les logs, puis relancez inspect avant toute correction manuelle.'
    fi
}

run_menu() {
    while true; do
        p5_header 'P5 OPENCLASSROOMS — CENTRE DE COMMANDE'
        cat <<'MENU'
 DÉMARRER / REPRENDRE
 ------------------------------------------------------------
  1  Inspecter ma situation actuelle
  2  Préparer / configurer le lab P5 dans WSL2
  3  Vérifier si je suis prêt à déployer

 EXERCICES
 ------------------------------------------------------------
  4  Exercice 1 — Terraform + Ansible + Angular/NGINX
  5  Exercice 2 — OpenSearch + logs + Dashboards as Code
  6  Exercice 3 — HAProxy + haute disponibilité

 PARCOURS COMPLET
 ------------------------------------------------------------
  7  Exécuter le projet complet de A à Z
  8  Reprendre un projet déjà commencé

 VALIDATION / SOUTENANCE
 ------------------------------------------------------------
  9  Vérifier les preuves et livrables
 10  Diagnostic complet
 11  Consulter les journaux

 AIDE
 ------------------------------------------------------------
 12  Que dois-je faire maintenant ?
 13  Afficher la documentation / Runbook
 14  Afficher l'aide des commandes

 MAINTENANCE
 ------------------------------------------------------------
 15  Nettoyer les ressources AWS

  0  Quitter
MENU
        printf '\nVotre choix : '
        local choice
        read -r choice
        case "$choice" in
            1) menu_execute 'Inspection' 'OBSERVATION' 'NON' 'NON' 'NON' \
                'bash scripts/commands/p5.sh inspect' 'Préparer ou vérifier le lab.' run_inspect ;;
            2) menu_execute 'Préparation du lab' 'CONVERGENCE' 'OUI, si delta' 'OUI, budget/config si delta' 'POSSIBLE' \
                'bash scripts/commands/p5.sh prepare' 'Lancer status puis l’exercice 1.' run_prepare ;;
            3) menu_execute 'Contrôle de préparation' 'OBSERVATION' 'NON' 'NON' 'NON' \
                'bash scripts/commands/p5.sh status' 'Corriger uniquement les écarts signalés, ou lancer ex1.' run_status ;;
            4) menu_execute 'Exercice 1' 'DÉPLOIEMENT' 'OUI' 'OUI' 'OUI' \
                'bash scripts/commands/p5.sh ex1' 'Passer à l’exercice 2.' run_ex1 ;;
            5) menu_execute 'Exercice 2' 'DÉPLOIEMENT' 'OUI' 'OUI' 'OUI' \
                'bash scripts/commands/p5.sh ex2' 'Passer à l’exercice 3.' run_ex2 ;;
            6) menu_execute 'Exercice 3' 'DÉPLOIEMENT / TEST DE RÉSILIENCE' 'OUI' 'OUI' 'OUI' \
                'bash scripts/commands/p5.sh ex3' 'Finaliser les preuves et livrables.' run_ex3 ;;
            7) menu_execute 'Parcours complet' 'DÉPLOIEMENT COMPLET' 'OUI' 'OUI' 'OUI' \
                'bash scripts/commands/p5.sh all' 'Finaliser les preuves puis nettoyer AWS après la soutenance.' run_all ;;
            8) menu_execute 'Reprise du projet' 'REPRISE CONVERGENTE' 'OUI, si delta' 'OUI, si delta' 'POSSIBLE' \
                'bash scripts/commands/p5.sh all' 'Poursuivre jusqu’au dernier exercice requis.' run_all ;;
            9) menu_execute 'Finalisation' 'VALIDATION / PREUVES' 'OUI, fichiers de preuves' 'NON' 'NON' \
                'bash scripts/commands/p5.sh finalize' 'Relire les livrables et préparer la soutenance.' run_finalize ;;
            10) menu_execute 'Diagnostic complet' 'DIAGNOSTIC' 'OUI, journaux/preuves' 'NON' 'NON' \
                'bash scripts/commands/p5.sh diagnostics' 'Consulter troubleshooting.md si un KO subsiste.' run_diagnostics ;;
            11) show_logs ;;
            12) show_guidance ;;
            13) show_docs ;;
            14) show_help ;;
            15) menu_execute 'Nettoyage AWS' 'DESTRUCTION' 'OUI' 'OUI — DESTRUCTIF' 'ARRÊT DES COÛTS' \
                'bash scripts/commands/p5.sh cleanup' 'Vérifier le verdict NETTOYAGE AWS COMPLET.' run_cleanup ;;
            0|q|quit|exit) return 0 ;;
            *) p5_warn 'Choix inconnu.' ;;
        esac
        printf '\nAppuyez sur Entrée pour revenir au centre de commande...'
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
    diagnostics) run_diagnostics ;;
    finalize) run_finalize ;;
    cleanup) run_cleanup ;;
    logs) show_logs ;;
    guide) show_guidance ;;
    docs) show_docs ;;
esac

p5_latest_log_hint
