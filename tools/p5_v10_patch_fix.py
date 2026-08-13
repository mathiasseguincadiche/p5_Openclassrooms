from pathlib import Path

path = Path('tools/p5_v10_patch.py')
text = path.read_text(encoding='utf-8')
old = '''count = text.count(proof_line)
if count != 4:
    raise SystemExit(f'expected 4 proof anchors, got {count}')
text = text.replace(proof_line, replacement_line)
'''
new = '''count = text.count(proof_line)
if count != 3:
    raise SystemExit(f'expected 3 indented proof anchors, got {count}')
text = text.replace(proof_line, replacement_line)
proof_line_outer = '\\n    p5_record_step_proof "$key" "$label" "$status" "$rc" "$log_file" "$start_time" "$end_time"\\n'
replacement_outer = proof_line_outer + '    p5_finalize_step_observability "$key" "$status" "$rc" "$((end_time - start_time))" "$log_file" "$stable_log"\\n'
if text.count(proof_line_outer) != 1:
    raise SystemExit('expected one exact outer proof anchor')
text = text.replace(proof_line_outer, replacement_outer, 1)
'''
if old not in text:
    raise SystemExit('proof patch block not found')
path.write_text(text.replace(old, new, 1), encoding='utf-8', newline='\n')
