#!/usr/bin/env python3
"""Package source and original models with a verified SHA-256 manifest."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {'.git', 'generated', 'results', '__pycache__', '.venv'}


def package(output):
    output = output.resolve()
    assert not output.is_relative_to(ROOT), 'Store artifact outside checkout'
    sources = sorted(p for p in ROOT.rglob('*') if p.is_file()
                     and not (set(p.relative_to(ROOT).parts) & EXCLUDED)
                     and p.suffix not in {'.pyc', '.slxc', '.zip'})
    for p in sources:
        assert not p.is_symlink(), f'Symlink needs explicit review: {p}'
    manifest = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sources}
    revision = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD'], text=True).strip()
    metadata = {'git_head': revision, 'runtime_validation': 'PENDING; MATLAB/Simulink not run',
                'sha256': manifest}
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in sources:
            z.write(p, 'RL_in_Microgrid/' + str(p.relative_to(ROOT)))
        z.writestr('RL_in_Microgrid/PACKAGE_MANIFEST.json', json.dumps(metadata, indent=2) + '\n')
    with zipfile.ZipFile(output) as z:
        assert z.testzip() is None
        for name, digest in manifest.items():
            assert hashlib.sha256(z.read('RL_in_Microgrid/' + name)).hexdigest() == digest
    print(json.dumps({'archive': str(output), 'files': len(manifest),
                      'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    package(parser.parse_args().output)
