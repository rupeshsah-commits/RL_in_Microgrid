#!/usr/bin/env python3
"""Source-only checks; not a MATLAB test runner. Never print potential secrets."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {'.git', 'generated', 'results', 'distributions', '__pycache__'}
REQUIRED = ['RUN_ME_FIRST.m', 'RUN_SMOKE_TEST.m', 'RUN_TRAINING.m', 'RUN_EVALUATION.m']
REQUIRED += ['docs/' + n + '.md' for n in ['MODEL_AUDIT', 'CONTROL_EQUATIONS',
 'OBSERVATION_ACTION_SPEC', 'LOCAL_EXECUTION_GUIDE', 'TROUBLESHOOTING',
 'EXPERIMENT_PROTOCOL', 'JOURNAL_CLAIMS_AND_LIMITATIONS']]
EXPECTED = {'Load_Changes_AC_Droop_four_inverter.slx':
 '3ca2e549c1606e2d371ce172c16f06c50f1d0f3ee690d6c7a8b004fee8cd3123',
 'Fault_RLready_AC_Droop_four_Inverters.slx':
 '1710a983a0748f55290301f55f6958e6149d033e8e6ba6bc3074113fbf7510b0'}


def check():
    files = sorted(p for p in ROOT.rglob('*') if p.is_file()
                   and not (set(p.relative_to(ROOT).parts) & EXCLUDED))
    for name in REQUIRED:
        assert (ROOT / name).is_file(), f'Missing required file: {name}'
    for name, expected in EXPECTED.items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == expected
    seen = {}; duplicates = []; abs_paths = []; suspicious = []
    secret_patterns = [r'gh[pousr]_[A-Za-z0-9]{30,}', r'github_pat_[A-Za-z0-9_]{30,}',
                       r'AKIA[A-Z0-9]{16}', r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----']
    for p in files:
        name = str(p.relative_to(ROOT)); digest = hashlib.sha256(p.read_bytes()).hexdigest()
        if digest in seen and p.stat().st_size:
            duplicates.append((seen[digest], name))
        seen[digest] = name
        if p.suffix in {'.m', '.py', '.md', '.json', '.yml', '.yaml'}:
            text = p.read_text()
            # Inventory records path components, not developer filesystem paths.
            if re.search(r'/(?:workspace|home|Users)/[A-Za-z0-9_.-]+', text):
                abs_paths.append(name)
            if any(re.search(pattern, text) for pattern in secret_patterns):
                suspicious.append(name)
    assert not duplicates, f'Duplicate source files: {duplicates}'
    assert not abs_paths, f'Accidental absolute paths need review: {abs_paths}'
    assert not suspicious, f'Potential credential material found in: {suspicious}'
    git_probe = subprocess.run(['git', '-C', str(ROOT), 'rev-parse', '--is-inside-work-tree'], capture_output=True, text=True)
    git_status = 'NOT RUN (no Git metadata in extracted source package)'
    if git_probe.returncode == 0 and git_probe.stdout.strip() == 'true':
        subprocess.run(['git', '-C', str(ROOT), 'diff', '--check'], check=True)
        git_status = 'PASS'
    print(json.dumps({'source_files_checked': len(files), 'original_SLX_hashes': 'PASS',
                      'required_files': 'PASS', 'duplicate_files': 'PASS',
                      'absolute_paths': 'PASS', 'secret_pattern_scan': 'PASS (bounded pattern scan, not proof)',
                      'git_diff_check': git_status, 'MATLAB_runtime': 'NOT RUN'}, indent=2))


if __name__ == '__main__':
    check()
