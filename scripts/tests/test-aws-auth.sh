#!/usr/bin/env bash
# Teste aws-auth.sh sans contacter AWS.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
AUTH_SCRIPT="$PROJECT_ROOT/scripts/commands/aws-auth.sh"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
TRACE_FILE="$TMP_DIR/aws-trace.log"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN" "$TMP_DIR/logs-console" "$TMP_DIR/logs-remote" \
    "$TMP_DIR/logs-login-fail" "$TMP_DIR/logs-root"

cat > "$FAKE_BIN/wslview" <<'EOF'
#!/usr/bin/bash
exit 1
EOF
chmod +x "$FAKE_BIN/wslview"

cat > "$FAKE_BIN/rundll32.exe" <<'EOF'
#!/usr/bin/bash
set -euo pipefail
printf 'rundll32.exe protocol=%s url=%s\n' "${1:-<absent>}" "${2:-<absente>}" >> "${P5_TEST_TRACE:?}"
# Simule un lanceur Windows qui reste vivant après l'ouverture du navigateur.
sleep 3
exit 0
EOF
chmod +x "$FAKE_BIN/rundll32.exe"

cat > "$FAKE_BIN/explorer.exe" <<'EOF'
#!/usr/bin/bash
set -euo pipefail
printf 'explorer.exe url=%s\n' "${1:-<absente>}" >> "${P5_TEST_TRACE:?}"
exit 0
EOF
chmod +x "$FAKE_BIN/explorer.exe"

cat > "$FAKE_BIN/gio" <<'EOF'
#!/usr/bin/bash
set -euo pipefail
printf 'gio-inattendu %s\n' "$*" >> "${P5_TEST_TRACE:?}"
exit 99
EOF
chmod +x "$FAKE_BIN/gio"

cat > "$FAKE_BIN/aws" <<'EOF'
#!/usr/bin/bash
set -euo pipefail
printf 'aws' >> "${P5_TEST_TRACE:?}"
printf ' %q' "$@" >> "$P5_TEST_TRACE"
printf '\n' >> "$P5_TEST_TRACE"
args="$*"

if [[ "$args" == '--version' ]]; then
    printf '%s\n' 'aws-cli/2.36.21 Python/3.13.0 Linux/6.8 exe/x86_64.ubuntu.24'
    exit 0
fi

if [[ "$args" == *'configure list-profiles'* ]]; then
    printf '%s\n' 'p5-signin' 'p5-lab'
    exit 0
fi

if [[ "$args" == *'configure get '* ]]; then
    if [[ "$args" == *'login_session'* && "$args" == *'p5-signin'* ]]; then
        printf '%s\n' 'arn:aws:iam::123456789012:user/devops'
    fi
    exit 0
fi

if [[ "$args" == *'configure set '* ]]; then
    exit 0
fi

if [[ "$args" == *' login '* || "$args" == login* ]]; then
    printf 'browser=%s\n' "${BROWSER:-<absent>}" >> "${P5_TEST_TRACE:?}"
    if [[ "${P5_FAKE_OPEN_BROWSER:-0}" == 1 ]]; then
        start_ms="$(date +%s%3N)"
        python3 - <<'PY'
import webbrowser

url = 'https://us-east-1.signin.aws.amazon.com/v1/authorize?state=test-wsl-browser'
raise SystemExit(0 if webbrowser.open(url) else 1)
PY
        end_ms="$(date +%s%3N)"
        elapsed_ms=$((end_ms - start_ms))
        printf 'webbrowser_elapsed_ms=%s\n' "$elapsed_ms" >> "${P5_TEST_TRACE:?}"
        if ((elapsed_ms >= 1000)); then
            printf 'Le helper navigateur a bloqué webbrowser.open pendant %s ms.\n' "$elapsed_ms" >&2
            exit 98
        fi
    fi
    if [[ "${P5_FAKE_LOGIN_FAIL:-0}" == 1 ]]; then
        exit 1
    fi
    exit 0
fi

if [[ "$args" == *'configure export-credentials'* ]]; then
    cat <<'JSON'
{"Version":1,"AccessKeyId":"ASIAEXAMPLE","SecretAccessKey":"secret","SessionToken":"token","Expiration":"2026-08-10T12:00:00Z"}
JSON
    exit 0
fi

if [[ "$args" == *'sts get-caller-identity'* ]]; then
    if [[ "${P5_FAKE_ROOT:-0}" == 1 ]]; then
        cat <<'JSON'
{"UserId":"123456789012","Account":"123456789012","Arn":"arn:aws:iam::123456789012:root"}
JSON
    else
        cat <<'JSON'
{"UserId":"AIDAEXAMPLE","Account":"123456789012","Arn":"arn:aws:iam::123456789012:user/devops"}
JSON
    fi
    exit 0
fi

printf 'Commande AWS factice non gérée : %s\n' "$args" >&2
exit 1
EOF
chmod +x "$FAKE_BIN/aws"

export PATH="$FAKE_BIN:/usr/bin:/bin"
export P5_TEST_TRACE="$TRACE_FILE"
export P5_LOG_DIR="$TMP_DIR/logs-console"
export WSL_DISTRO_NAME=Ubuntu
export P5_FAKE_OPEN_BROWSER=1
: > "$TRACE_FILE"

OUTPUT="$(/usr/bin/bash "$AUTH_SCRIPT" \
    --mode console \
    --profile p5-lab \
    --source-profile p5-signin \
    --region us-east-1 \
    --yes 2>&1)"

unset P5_FAKE_OPEN_BROWSER

grep -Fq 'AWS PRÊT' <<<"$OUTPUT"
grep -Fq 'CALLBACK LOCALHOST WINDOWS/WSL2' <<<"$OUTPUT"
grep -Fq 'aucune copie de code d’autorisation n’est nécessaire' <<<"$OUTPUT"
grep -Fq 'helper navigateur Windows via la variable BROWSER' <<<"$OUTPUT"
grep -Fq 'helper est lancé en arrière-plan' <<<"$OUTPUT"
grep -Fq 'login --profile p5-signin --region us-east-1' "$TRACE_FILE"
grep -Eq '^browser=.*/p5-windows-browser %s &$' "$TRACE_FILE"
grep -Fq 'rundll32.exe protocol=url.dll,FileProtocolHandler url=https://us-east-1.signin.aws.amazon.com/v1/authorize?state=test-wsl-browser' "$TRACE_FILE"
grep -Eq '^webbrowser_elapsed_ms=[0-9]+$' "$TRACE_FILE"
if grep -Fq 'gio-inattendu' "$TRACE_FILE"; then
    printf 'KO  le mode console WSL2 retombe encore sur gio malgré BROWSER.\n' >&2
    exit 1
fi
if grep -Fq 'login --remote' "$TRACE_FILE"; then
    printf 'KO  le mode console WSL2 utilise encore --remote.\n' >&2
    exit 1
fi
grep -Fq 'configure set credential_process' "$TRACE_FILE"
grep -Fq 'configure export-credentials --profile p5-signin --format process' "$TRACE_FILE"

export P5_LOG_DIR="$TMP_DIR/logs-remote"
: > "$TRACE_FILE"
REMOTE_OUTPUT="$(/usr/bin/bash "$AUTH_SCRIPT" \
    --mode console-remote \
    --profile p5-lab \
    --source-profile p5-signin \
    --region us-east-1 \
    --yes 2>&1)"

grep -Fq 'AWS PRÊT' <<<"$REMOTE_OUTPUT"
grep -Fq 'REPLI CROSS-DEVICE' <<<"$REMOTE_OUTPUT"
grep -Fq 'login --remote --profile p5-signin --region us-east-1' "$TRACE_FILE"
grep -Fq 'code d’autorisation à usage unique' <<<"$REMOTE_OUTPUT"

export P5_LOG_DIR="$TMP_DIR/logs-login-fail"
export P5_FAKE_LOGIN_FAIL=1
set +e
LOGIN_FAIL_OUTPUT="$(/usr/bin/bash "$AUTH_SCRIPT" \
    --mode console \
    --profile p5-lab \
    --source-profile p5-signin \
    --region us-east-1 \
    --yes 2>&1)"
LOGIN_FAIL_RC=$?
set -e
unset P5_FAKE_LOGIN_FAIL

if ((LOGIN_FAIL_RC == 0)); then
    printf 'KO  un échec aws login a été accepté.\n' >&2
    exit 1
fi
grep -Fq 'callback localhost a échoué' <<<"$LOGIN_FAIL_OUTPUT"
grep -Fq 'SignInLocalDevelopmentAccess' <<<"$LOGIN_FAIL_OUTPUT"
grep -Fq -- '--mode console-remote' <<<"$LOGIN_FAIL_OUTPUT"

export P5_LOG_DIR="$TMP_DIR/logs-root"
export P5_FAKE_ROOT=1
set +e
ROOT_OUTPUT="$(/usr/bin/bash "$AUTH_SCRIPT" \
    --mode console \
    --profile p5-lab \
    --source-profile p5-signin \
    --region us-east-1 \
    --yes 2>&1)"
ROOT_RC=$?
set -e
unset P5_FAKE_ROOT
unset WSL_DISTRO_NAME

if ((ROOT_RC == 0)); then
    printf 'KO  une session root AWS a été acceptée.\n' >&2
    exit 1
fi
grep -Fq 'refuse volontairement une session AWS root' <<<"$ROOT_OUTPUT"

printf 'OK  authentification AWS localhost WSL2, navigateur Windows non bloquant, repli remote et refus root validés sans contacter AWS.\n'