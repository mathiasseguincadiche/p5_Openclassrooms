#!/usr/bin/env bash
# Démonstration contrôlée de la panne et de la reprise d'un backend HAProxy.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROOF_DIR="$PROJECT_ROOT/proofs/runtime/exercice-3"
SSH_KEY="${HOME}/.ssh/p5-key"
SSH_USER="ubuntu"
BACKEND=1
REQUESTS=6
WAIT_DOWN=12
WAIT_UP=10
APPLY=false

show_help() {
    cat <<'HELP'
Usage: test-haproxy-failover.sh [options]

Options:
  --backend 1|2        backend dont le conteneur sera arrêté (défaut : 1)
  --requests N         requêtes par phase (défaut : 6)
  --ssh-key CHEMIN     clé SSH privée (défaut : ~/.ssh/p5-key)
  --ssh-user NOM       utilisateur SSH (défaut : ubuntu)
  --wait-down SEC      attente après l'arrêt (défaut : 12)
  --wait-up SEC        attente après la reprise (défaut : 10)
  --proof-dir CHEMIN   dossier local des preuves techniques
  --apply              exécuter réellement l'arrêt et le redémarrage
  -h, --help           afficher cette aide

Le trap de sortie tente toujours de redémarrer le conteneur arrêté.
HELP
}

while (($# > 0)); do
    case "$1" in
        --backend)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --backend.\n' >&2; exit 2; }
            BACKEND="$2"
            shift 2
            ;;
        --requests)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --requests.\n' >&2; exit 2; }
            REQUESTS="$2"
            shift 2
            ;;
        --ssh-key)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --ssh-key.\n' >&2; exit 2; }
            SSH_KEY="$2"
            shift 2
            ;;
        --ssh-user)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --ssh-user.\n' >&2; exit 2; }
            SSH_USER="$2"
            shift 2
            ;;
        --wait-down)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --wait-down.\n' >&2; exit 2; }
            WAIT_DOWN="$2"
            shift 2
            ;;
        --wait-up)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --wait-up.\n' >&2; exit 2; }
            WAIT_UP="$2"
            shift 2
            ;;
        --proof-dir)
            [[ $# -ge 2 ]] || { printf 'Valeur manquante pour --proof-dir.\n' >&2; exit 2; }
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
            printf 'Option inconnue : %s\n' "$1" >&2
            show_help >&2
            exit 2
            ;;
    esac
done

[[ "$BACKEND" == 1 || "$BACKEND" == 2 ]] || {
    printf '%s\n' '--backend doit valoir 1 ou 2.' >&2
    exit 2
}
for value in "$REQUESTS" "$WAIT_DOWN" "$WAIT_UP"; do
    [[ "$value" =~ ^[1-9][0-9]*$ ]] || {
        printf 'Les nombres de requêtes et délais doivent être positifs.\n' >&2
        exit 2
    }
done

for command_name in terraform curl ssh awk; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Commande requise absente : %s\n' "$command_name" >&2
        exit 1
    }
done
[[ -f "$SSH_KEY" ]] || { printf 'Clé SSH absente : %s\n' "$SSH_KEY" >&2; exit 1; }

HAPROXY_URL="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-3" \
    output -raw haproxy_url 2>/dev/null || true)"
BACKEND_IP="$(terraform -chdir="$PROJECT_ROOT/terraform/exercice-3" \
    output -raw "hello_${BACKEND}_public_ip" 2>/dev/null || true)"
if [[ ! "$HAPROXY_URL" =~ ^http://[A-Za-z0-9.-]+(:[0-9]+)?$ ]]; then
    printf 'Sortie Terraform haproxy_url invalide.\n' >&2
    exit 1
fi
if [[ ! "$BACKEND_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    printf 'Adresse publique du backend invalide.\n' >&2
    exit 1
fi

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

probe_phase() {
    local phase="$1"
    local expected_min="$2"
    local expected_max="$3"
    local response server_name
    local -A servers=()

    printf '\nPhase : %s\n' "$phase"
    for ((request_number = 1; request_number <= REQUESTS; request_number++)); do
        response="$(curl -fsS --max-time 10 "$HAPROXY_URL/")"
        server_name="$(awk -F': ' '/^Server name:/ {print $2; exit}' <<< "$response")"
        [[ -n "$server_name" ]] || {
            printf '  KO  réponse sans Server name\n' >&2
            return 1
        }
        servers["$server_name"]=1
        printf '  %02d  %s\n' "$request_number" "$server_name"
        sleep 0.3
    done

    local unique_count="${#servers[@]}"
    if ((unique_count < expected_min || unique_count > expected_max)); then
        printf '  KO  %s backend(s) observé(s), attendu entre %s et %s\n' \
            "$unique_count" "$expected_min" "$expected_max" >&2
        return 1
    fi
    printf '  OK  %s backend(s) distinct(s)\n' "$unique_count"
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
    sleep "$WAIT_DOWN"

    probe_phase 'pendant la panne' 1 1

    printf '\nRedémarrage du conteneur sur le backend %s\n' "$BACKEND"
    ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$BACKEND_IP" \
        'sudo docker start nginx-hello >/dev/null'
    BACKEND_STOPPED=false
    sleep "$WAIT_UP"

    probe_phase 'après la reprise' 2 2

    printf '\nVerdict : BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES\n'
    printf 'Preuve locale : %s\n' "$SUMMARY_LOG"
} 2>&1 | tee "$SUMMARY_LOG"
