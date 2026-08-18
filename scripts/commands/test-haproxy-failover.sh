#!/usr/bin/env bash
# Démonstration contrôlée de la panne et de la reprise d'un backend HAProxy.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$PROJECT_ROOT/scripts/lib/p5-runtime.sh"
CONFIG_FILE="$PROJECT_ROOT/environment/aws-readiness.env"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-3"
SSH_KEY=""
SSH_USER="ubuntu"
BACKEND=1
REQUESTS=6
WAIT_DOWN=30
WAIT_UP=30
APPLY=false
HAPROXY_URL=""
BACKEND_IP=""
OBSERVED_UNIQUE_COUNT=0

# shellcheck source=../lib/p5-runtime.sh
source "$LIB_FILE"
p5_session_start "test-haproxy-failover"

show_help() {
    cat <<'HELP'
Usage: test-haproxy-failover.sh [options]

Options:
  --backend 1|2        backend dont le conteneur sera arrêté (défaut : 1)
  --url URL            URL HTTP de HAProxy si Terraform ne doit pas être utilisé
  --backend-host IP    IPv4 publique du backend ciblé si Terraform ne doit pas être utilisé
  --requests N         requêtes par phase (défaut : 6)
  --ssh-key CHEMIN     clé SSH privée ; sinon configuration locale du lab
  --ssh-user NOM       utilisateur SSH (défaut : ubuntu)
  --wait-down SEC      délai maximal pour observer le retrait (défaut : 30)
  --wait-up SEC        délai maximal pour observer la reprise (défaut : 30)
  --proof-dir CHEMIN   dossier local des preuves techniques
  --apply              exécuter réellement l'arrêt et le redémarrage
  -h, --help           afficher cette aide

Par défaut, HAProxy et le backend sont lus depuis Terraform. Si une valeur est
indisponible en usage manuel, le script explique son rôle et le format attendu.
Sans --apply, aucune connexion SSH n'est effectuée. Les délais --wait-* sont des
bornes maximales : le test continue dès que l'état HAProxy attendu est observé.
HELP
}

while (($# > 0)); do
    case "$1" in
        --backend)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --backend.'; exit 2; }
            BACKEND="$2"
            shift 2
            ;;
        --url)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --url.'; exit 2; }
            HAPROXY_URL="$2"
            shift 2
            ;;
        --backend-host)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --backend-host.'; exit 2; }
            BACKEND_IP="$2"
            shift 2
            ;;
        --requests)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --requests.'; exit 2; }
            REQUESTS="$2"
            shift 2
            ;;
        --ssh-key)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-key.'; exit 2; }
            SSH_KEY="$2"
            shift 2
            ;;
        --ssh-user)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --ssh-user.'; exit 2; }
            SSH_USER="$2"
            shift 2
            ;;
        --wait-down)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --wait-down.'; exit 2; }
            WAIT_DOWN="$2"
            shift 2
            ;;
        --wait-up)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --wait-up.'; exit 2; }
            WAIT_UP="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { p5_error 'Valeur manquante pour --proof-dir.'; exit 2; }
            PROOF_DIR="$2"
            shift 2
            ;;
        --apply)
            APPLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            p5_error "Option inconnue : $1"
            show_help >&2
            exit 2
            ;;
    esac
done

[[ "$BACKEND" == 1 || "$BACKEND" == 2 ]] || {
    p5_error '--backend doit valoir 1 ou 2.'
    exit 2
}
for value in "$REQUESTS" "$WAIT_DOWN" "$WAIT_UP"; do
    [[ "$value" =~ ^[1-9][0-9]*$ ]] || {
        p5_error 'Les nombres de requêtes et délais doivent être positifs.'
        exit 2
    }
done

for command_name in terraform curl awk; do
    command -v "$command_name" >/dev/null 2>&1 || {
        p5_error "Commande requise absente : $command_name"
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
done

if [[ -z "$SSH_KEY" && -r "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    SSH_KEY="${P5_SSH_KEY_PATH:-}"
    if [[ -z "$SSH_KEY" ]]; then
        PUBLIC_KEY_PATH="${P5_SSH_PUBLIC_KEY_PATH:-$HOME/.ssh/p5-key.pub}"
        SSH_KEY="${PUBLIC_KEY_PATH%.pub}"
    fi
fi
SSH_KEY="${SSH_KEY:-$HOME/.ssh/p5-key}"
SSH_KEY="${SSH_KEY/#\~/$HOME}"

if [[ "$APPLY" == true ]]; then
    command -v ssh >/dev/null 2>&1 || {
        p5_error 'Commande requise absente : ssh'
        p5_action 'Lancez : bash scripts/commands/p5.sh prepare'
        exit 1
    }
    if [[ ! -f "$SSH_KEY" ]]; then
        p5_unknown 'Clé SSH privée pour le backend HAProxy' "fichier absent : $SSH_KEY" \
            'Indiquez la clé privée correspondant aux EC2 de l’exercice 3.'
        p5_prompt_value SSH_KEY \
            'Chemin de la clé SSH privée' \
            'Le test réel doit arrêter puis redémarrer le conteneur sur un backend.' \
            'chemin absolu vers un fichier existant' "$HOME/.ssh/p5-key" '' p5_validate_existing_file \
            "Saisissez-la ici, ou relancez avec : --ssh-key $HOME/.ssh/p5-key"
    fi
fi

if [[ -z "$HAPROXY_URL" ]]; then
    HAPROXY_URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-3" \
        output -raw haproxy_url 2>/dev/null || true)"
    if ! p5_validate_http_url "${HAPROXY_URL%/}"; then
        p5_unknown 'URL HAProxy' \
            'la sortie Terraform haproxy_url n’est pas disponible' \
            'Pour le parcours normal, relancez p5.sh ex3. Pour un diagnostic manuel, saisissez l’URL du load balancer.'
        p5_prompt_value HAPROXY_URL \
            'URL HTTP de HAProxy' \
            'Le test envoie des requêtes avant, pendant et après la panne.' \
            'URL HTTP complète sans chemin' 'http://198.51.100.60' '' p5_validate_http_url \
            'Saisissez-la ici, ou relancez avec : --url http://198.51.100.60'
    fi
fi
HAPROXY_URL="${HAPROXY_URL%/}"

if [[ -z "$BACKEND_IP" ]]; then
    BACKEND_IP="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-3" \
        output -raw "hello_${BACKEND}_public_ip" 2>/dev/null || true)"
    if ! p5_validate_ipv4 "$BACKEND_IP"; then
        p5_unknown "IPv4 publique du backend $BACKEND" \
            "la sortie Terraform hello_${BACKEND}_public_ip n’est pas disponible" \
            'Pour le parcours normal, relancez p5.sh ex3. Pour un diagnostic manuel, saisissez l’IPv4 du backend réellement ciblé.'
        p5_prompt_value BACKEND_IP \
            "IPv4 publique du backend $BACKEND" \
            'Cette adresse est utilisée uniquement pour la connexion SSH qui arrête/redémarre nginx-hello.' \
            'IPv4 seule' '198.51.100.61' '' p5_validate_ipv4 \
            'Saisissez-la ici, ou relancez avec : --backend-host 198.51.100.61'
    fi
fi

if ! p5_validate_http_url "$HAPROXY_URL"; then
    p5_error "URL HAProxy invalide : $HAPROXY_URL"
    exit 1
fi
if ! p5_validate_ipv4 "$BACKEND_IP"; then
    p5_error "Adresse publique du backend invalide : $BACKEND_IP"
    exit 1
fi

umask 077
mkdir -p "$PROOF_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SUMMARY_LOG="$PROOF_DIR/${TIMESTAMP}-failover-backend-${BACKEND}.log"
SSH_OPTIONS=(
    -i "$SSH_KEY"
    -o BatchMode=yes
    -o ConnectTimeout=10
    -o StrictHostKeyChecking=accept-new
)
BACKEND_STOPPED=false

restore_backend() {
    if [[ "$BACKEND_STOPPED" == true ]]; then
        printf '\nRestauration de sécurité du backend %s\n' "$BACKEND" >&2
        ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$BACKEND_IP" \
            'sudo docker start nginx-hello >/dev/null' || true
    fi
}
trap restore_backend EXIT INT TERM

observe_backends() {
    local verbose="$1"
    local response server_name
    local -A servers=()

    for ((request_number = 1; request_number <= REQUESTS; request_number++)); do
        response="$(curl -fsS --max-time 10 "$HAPROXY_URL/")" || return 1
        server_name="$(awk -F': ' '/^Server name:/ {print $2; exit}' <<< "$response")"
        [[ -n "$server_name" ]] || return 1
        servers["$server_name"]=1
        if [[ "$verbose" == true ]]; then
            printf '  %02d  %s\n' "$request_number" "$server_name"
        fi
        sleep 0.3
    done

    OBSERVED_UNIQUE_COUNT="${#servers[@]}"
}

phase_matches() {
    local expected_min="$1"
    local expected_max="$2"
    observe_backends false || return 1
    ((OBSERVED_UNIQUE_COUNT >= expected_min && OBSERVED_UNIQUE_COUNT <= expected_max))
}

probe_phase() {
    local phase="$1"
    local expected_min="$2"
    local expected_max="$3"

    printf '\nPhase : %s\n' "$phase"
    observe_backends true || {
        printf '  KO  impossible d’obtenir une série de réponses HAProxy valide\n' >&2
        return 1
    }
    if ((OBSERVED_UNIQUE_COUNT < expected_min || OBSERVED_UNIQUE_COUNT > expected_max)); then
        printf '  KO  %s backend(s) observé(s), attendu entre %s et %s\n' \
            "$OBSERVED_UNIQUE_COUNT" "$expected_min" "$expected_max" >&2
        return 1
    fi
    printf '  OK  %s backend(s) distinct(s)\n' "$OBSERVED_UNIQUE_COUNT"
}

wait_for_phase() {
    local phase="$1"
    local expected_min="$2"
    local expected_max="$3"
    local timeout="$4"
    local deadline=$((SECONDS + timeout))

    printf '\nAttente bornée : %s (maximum %s s)\n' "$phase" "$timeout"
    while ((SECONDS <= deadline)); do
        if phase_matches "$expected_min" "$expected_max"; then
            if probe_phase "$phase" "$expected_min" "$expected_max"; then
                return 0
            fi
        fi
        sleep 2
    done
    printf '  KO  état HAProxy attendu non observé avant expiration du délai de %s s\n' \
        "$timeout" >&2
    return 1
}

{
    printf 'Test contrôlé HAProxy : panne et reprise\n'
    printf '  HAProxy         : %s\n' "$HAPROXY_URL"
    printf '  Backend ciblé   : %s (%s)\n' "$BACKEND" "$BACKEND_IP"
    printf '  Conteneur       : nginx-hello\n'

    probe_phase 'avant la panne' 2 2

    if [[ "$APPLY" != true ]]; then
        printf '\nSimulation terminée. Relancez avec --apply pour arrêter le conteneur.\n'
        exit 0
    fi

    printf '\nArrêt du conteneur sur le backend %s\n' "$BACKEND"
    ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$BACKEND_IP" \
        'sudo docker stop nginx-hello >/dev/null'
    BACKEND_STOPPED=true

    wait_for_phase 'pendant la panne' 1 1 "$WAIT_DOWN"

    printf '\nRedémarrage du conteneur sur le backend %s\n' "$BACKEND"
    ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$BACKEND_IP" \
        'sudo docker start nginx-hello >/dev/null'
    BACKEND_STOPPED=false

    wait_for_phase 'après la reprise' 2 2 "$WAIT_UP"

    printf '\nVerdict : BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES\n'
    printf 'Preuve locale : %s\n' "$SUMMARY_LOG"
} 2>&1 | tee "$SUMMARY_LOG"

if [[ "$APPLY" == true && "${P5_ORCHESTRATED:-0}" == 1 ]]; then
    bash "$SCRIPT_DIR/verify-aws-exercise-state.sh" --exercise 3
fi
