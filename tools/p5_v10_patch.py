from pathlib import Path

runtime = Path('scripts/lib/p5-runtime.sh')
text = runtime.read_text(encoding='utf-8')

old = '''    export P5_LOG_DIR P5_STEP_PROOF_DIR P5_STEP_PROOF_MANIFEST

    umask 077
    mkdir -p "$P5_LOG_DIR" "$P5_STEP_PROOF_DIR"
'''
new = '''    export P5_LOG_DIR P5_STEP_PROOF_DIR P5_STEP_PROOF_MANIFEST

    P5_STABLE_LOG_ROOT="${P5_STABLE_LOG_ROOT:-$P5_PROJECT_ROOT/logs/scripts}"
    P5_EVENT_LOG="${P5_EVENT_LOG:-$P5_LOG_DIR/events.log}"
    P5_SUMMARY_LOG="${P5_SUMMARY_LOG:-$P5_LOG_DIR/summary.log}"
    export P5_STABLE_LOG_ROOT P5_EVENT_LOG P5_SUMMARY_LOG

    umask 077
    mkdir -p "$P5_LOG_DIR" "$P5_STEP_PROOF_DIR" "$P5_STABLE_LOG_ROOT"
    touch "$P5_EVENT_LOG"
    chmod 600 "$P5_EVENT_LOG"
'''
if old not in text:
    raise SystemExit('runtime session anchor not found')
text = text.replace(old, new, 1)

start = text.index('p5_command_preview() {')
end = text.index('\n}\n\np5_slug()', start) + 3
replacement = r'''p5_sensitive_name() {
    local name="${1,,}"
    [[ "$name" == *password* \
        || "$name" == *passwd* \
        || "$name" == *secret* \
        || "$name" == *token* \
        || "$name" == *credential* \
        || "$name" == *api-key* \
        || "$name" == *apikey* ]]
}

p5_redact_stream() {
    sed -E \
        -e 's/(AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN|OPENROUTER_API_KEY|GITHUB_TOKEN|GH_TOKEN)=([^[:space:]]+)/\1=<REDACTED>/g' \
        -e 's/(sk-or-[A-Za-z0-9_-]{12,}|github_pat_[A-Za-z0-9_]{12,}|glpat-[A-Za-z0-9_-]{12,})/<REDACTED>/g' \
        -e 's/([Bb]earer[[:space:]]+)[A-Za-z0-9._~+\/-]{12,}/\1<REDACTED>/g'
}

p5_command_preview() {
    local arg key redact_next=0
    printf '       Commande :'
    for arg in "$@"; do
        if ((redact_next)); then
            printf ' %q' '<REDACTED>'
            redact_next=0
            continue
        fi
        if [[ "$arg" == *=* ]]; then
            key="${arg%%=*}"
            if p5_sensitive_name "$key"; then
                arg="${key}=<REDACTED>"
            fi
        elif [[ "$arg" == --* ]] && p5_sensitive_name "$arg"; then
            redact_next=1
        fi
        printf ' %q' "$arg"
    done
    printf '\n'
}'''
text = text[:start] + replacement + text[end:]

marker = '''p5_prepare_step_file() {
'''
helpers = r'''p5_stable_log_for_command() {
    local key="$1"
    shift
    local candidate rel safe_key
    for candidate in "$@"; do
        if [[ "$candidate" == "$P5_PROJECT_ROOT/"* && -f "$candidate" ]]; then
            rel="${candidate#"$P5_PROJECT_ROOT/"}"
        elif [[ "$candidate" == scripts/* && -f "$P5_PROJECT_ROOT/$candidate" ]]; then
            rel="$candidate"
        else
            continue
        fi
        case "$rel" in
            *.sh|*.py)
                rel="${rel#scripts/}"
                rel="${rel%.*}"
                mkdir -p "$P5_STABLE_LOG_ROOT/$(dirname -- "$rel")"
                printf '%s/%s.log\n' "$P5_STABLE_LOG_ROOT" "$rel"
                return 0
                ;;
        esac
    done
    safe_key="$(p5_slug "$key")"
    mkdir -p "$P5_STABLE_LOG_ROOT/external"
    printf '%s/external/%s.log\n' "$P5_STABLE_LOG_ROOT" "$safe_key"
}

p5_refresh_summary() {
    local validated failed
    validated="$(awk -F '\t' '$2 == "VALIDE" {count++} END {print count+0}' "$P5_EVENT_LOG" 2>/dev/null || printf 0)"
    failed="$(awk -F '\t' '$2 == "ECHEC" {count++} END {print count+0}' "$P5_EVENT_LOG" 2>/dev/null || printf 0)"
    {
        printf 'run_id=%s\n' "$P5_RUN_ID"
        printf 'validated_steps=%s\n' "$validated"
        printf 'failed_steps=%s\n' "$failed"
        printf 'result=%s\n' "$(if ((failed == 0)); then printf OK; else printf KO; fi)"
        printf 'updated_at=%s\n' "$(date -u --iso-8601=seconds)"
    } > "$P5_SUMMARY_LOG"
    chmod 600 "$P5_SUMMARY_LOG"
}

p5_finalize_step_observability() {
    local key="$1" status="$2" rc="$3" duration="$4" step_log="$5" stable_log="$6"
    local utc
    utc="$(date -u --iso-8601=seconds)"
    mkdir -p "$(dirname -- "$stable_log")"
    {
        printf '\n===============================================================================\n'
        printf '[RUN] %s | step=%s | status=%s | rc=%s | duration_s=%s\n' \
            "$P5_RUN_ID" "$key" "$status" "$rc" "$duration"
        cat "$step_log"
    } | p5_redact_stream >> "$stable_log"
    chmod 600 "$stable_log"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$utc" "$status" "$key" "$rc" "$duration" "$stable_log" >> "$P5_EVENT_LOG"
    chmod 600 "$P5_EVENT_LOG"
    p5_refresh_summary
}

'''
if marker not in text:
    raise SystemExit('runtime helper anchor not found')
text = text.replace(marker, helpers + marker, 1)

text = text.replace(
    '''    local log_file start_time end_time rc status
    p5_prepare_step_file "$key"
    log_file="$P5_CURRENT_STEP_LOG"
''',
    '''    local log_file stable_log start_time end_time rc status
    p5_prepare_step_file "$key"
    log_file="$P5_CURRENT_STEP_LOG"
    stable_log="$(p5_stable_log_for_command "$key" "$@")"
'''
)
text = text.replace(
    '''    "$@" > >(tee "$log_file") 2>&1
    rc=$?
''',
    '''    "$@" 2>&1 | p5_redact_stream | tee "$log_file"
    rc=${PIPESTATUS[0]}
'''
)
proof_line = '        p5_record_step_proof "$key" "$label" "$status" "$rc" "$log_file" "$start_time" "$end_time"\n'
replacement_line = proof_line + '        p5_finalize_step_observability "$key" "$status" "$rc" "$((end_time - start_time))" "$log_file" "$stable_log"\n'
count = text.count(proof_line)
if count != 4:
    raise SystemExit(f'expected 4 proof anchors, got {count}')
text = text.replace(proof_line, replacement_line)

hint = '''    printf 'Preuves par étape        : %s\\n' "$P5_STEP_PROOF_DIR"
    printf 'Manifeste des preuves    : %s\\n' "$P5_STEP_PROOF_MANIFEST"
'''
hint_new = hint + '''    printf 'Journaux par script      : %s\\n' "$P5_STABLE_LOG_ROOT"
    printf 'Résumé factuel du run    : %s\\n' "$P5_SUMMARY_LOG"
'''
if hint not in text:
    raise SystemExit('runtime hint anchor not found')
text = text.replace(hint, hint_new, 1)
runtime.write_text(text, encoding='utf-8', newline='\n')

inspect = Path('scripts/commands/inspect-state.sh')
it = inspect.read_text(encoding='utf-8')
anchor = '''INVENTORY_FILE="$PROJECT_ROOT/ansible/inventories/hosts_aws"
'''
repl = anchor + '''TFVARS_RC=1
AWS_RC=1
SSH_PAIR_READY=0
'''
if anchor not in it:
    raise SystemExit('inspect init anchor not found')
it = it.replace(anchor, repl, 1)
it = it.replace(
    '''    if [[ -f "$PRIVATE_KEY" && -f "$PUBLIC_KEY" ]]; then
        printf '  OK  paire de clés SSH locale présente.\\n'
''',
    '''    if [[ -f "$PRIVATE_KEY" && -f "$PUBLIC_KEY" ]]; then
        SSH_PAIR_READY=1
        printf '  OK  paire de clés SSH locale présente.\\n'
''',
    1,
)
old_end = '''printf '\\nVerdict : ÉTAT OBSERVÉ — aucune mutation, aucune valeur inventée.\\n'
'''
new_end = r'''STATE_FILES="$(find "$PROJECT_ROOT/terraform" -maxdepth 2 -type f -name 'terraform.tfstate' 2>/dev/null | wc -l)"
RUNTIME_PROOFS=0
if [[ -d "$PROJECT_ROOT/proofs/runtime" ]]; then
    RUNTIME_PROOFS="$(find "$PROJECT_ROOT/proofs/runtime" -type f 2>/dev/null | wc -l)"
fi
if ((VM_RC == 0 && TFVARS_RC == 0 && AWS_RC == 0 && SSH_PAIR_READY == 1)); then
    CLASSIFICATION='READY_CANDIDATE'
elif ((VM_RC != 0 && STATE_FILES == 0 && RUNTIME_PROOFS == 0)) && [[ ! -r "$CONFIG_FILE" ]]; then
    CLASSIFICATION='FIRST_RUN'
else
    CLASSIFICATION='PARTIAL'
fi
printf '\nClassification : %s\n' "$CLASSIFICATION"
case "$CLASSIFICATION" in
    FIRST_RUN)
        printf '  Première préparation détectée : aucun état P5 persistant exploitable n’a été trouvé.\n'
        printf '  Prochaine action : bash scripts/commands/p5.sh prepare\n'
        ;;
    PARTIAL)
        printf '  État partiel détecté : les éléments déjà conformes seront conservés et seuls les écarts seront convergés.\n'
        printf '  Prochaine action : bash scripts/commands/p5.sh prepare\n'
        ;;
    READY_CANDIDATE)
        printf '  Socle prêt candidat : outils, configuration, SSH et identité AWS sont actuellement vérifiables.\n'
        printf '  Prochaine action : bash scripts/commands/p5.sh status pour revalider sans mutation.\n'
        ;;
esac
printf '\nVerdict : ÉTAT OBSERVÉ — aucune mutation, aucune valeur inventée.\n'
'''
if old_end not in it:
    raise SystemExit('inspect verdict anchor not found')
it = it.replace(old_end, new_end, 1)
inspect.write_text(it, encoding='utf-8', newline='\n')

test = Path('scripts/tests/test-convergence-contract.sh')
tt = test.read_text(encoding='utf-8')
tt = tt.replace(
    '''export P5_STEP_PROOF_DIR="$TMP_DIR/runtime-proofs"
export P5_SESSION_ACTIVE=1
''',
    '''export P5_STEP_PROOF_DIR="$TMP_DIR/runtime-proofs"
export P5_STABLE_LOG_ROOT="$TMP_DIR/stable-logs"
export P5_SESSION_ACTIVE=1
''',
    1,
)
anchor = '''printf '  OK  journaux et preuves numérotés de manière stable.\\n'

printf '\\nVerdict : CONTRAT DE CONVERGENCE P5 RESPECTÉ.\\n'
'''
addition = r'''printf '  OK  journaux et preuves numérotés de manière stable.\n'
[[ -f "$P5_STABLE_LOG_ROOT/external/first.log" ]]
[[ -f "$P5_EVENT_LOG" ]]
[[ -f "$P5_SUMMARY_LOG" ]]
grep -Fq 'validated_steps=2' "$P5_SUMMARY_LOG"
printf '  OK  journal persistant et résumé factuel du run présents.\n'

PREVIEW="$(p5_command_preview command --api-token supersecret-value)"
! grep -Fq 'supersecret-value' <<<"$PREVIEW"
grep -Fq '<REDACTED>' <<<"$PREVIEW"
p5_run_step 'secret-output' 'sortie sensible' \
    bash -c 'printf "AWS_SECRET_ACCESS_KEY=supersecret-value\\n"' >/dev/null
! grep -Fq 'supersecret-value' "$P5_LAST_STEP_LOG"
grep -Fq '<REDACTED>' "$P5_LAST_STEP_LOG"
printf '  OK  aperçu de commande et sorties sensibles nettoyés avant journalisation.\n'

grep -Fq "CLASSIFICATION='FIRST_RUN'" scripts/commands/inspect-state.sh
grep -Fq "CLASSIFICATION='PARTIAL'" scripts/commands/inspect-state.sh
grep -Fq "CLASSIFICATION='READY_CANDIDATE'" scripts/commands/inspect-state.sh
printf '  OK  classification machine-first explicite.\n'

printf '\nVerdict : CONTRAT DE CONVERGENCE P5 RESPECTÉ.\n'
'''
if anchor not in tt:
    raise SystemExit('convergence test anchor not found')
tt = tt.replace(anchor, addition, 1)
test.write_text(tt, encoding='utf-8', newline='\n')
