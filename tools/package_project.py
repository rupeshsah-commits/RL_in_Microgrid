#!/usr/bin/env python3
"""Deterministic source ZIP; works from Git checkouts and extracted source packages."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {'.git', 'generated', 'results', '__pycache__', '.venv', 'distributions'}


def write(z, name, data):
    info = zipfile.ZipInfo('RL_in_Microgrid/' + name, date_time=(1980, 1, 1, 0, 0, 0))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    z.writestr(info, data, compresslevel=9)


def package(output, include_generated=False):
    output = output.resolve()
    assert not output.is_relative_to(ROOT) or output.is_relative_to(ROOT / 'distributions'), 'Use distributions/ or an external artifact folder'
    sources = sorted(p for p in ROOT.rglob('*') if p.is_file()
                     and not (set(p.relative_to(ROOT).parts) & EXCLUDED)
                     and p.suffix not in {'.pyc', '.slxc', '.zip'}
                     and p.name != 'PACKAGE_MANIFEST.json')
    if include_generated:
        reports = sorted((ROOT / 'generated').glob('*_build.json'))
        assert reports, 'No genuine MATLAB builder manifest found'
        for report in reports:
            meta = json.loads(report.read_text())
            path = ROOT / 'generated' / (meta['model'] + '.slx')
            assert meta['builtBy'] == 'MATLAB save_system'
            assert hashlib.sha256(path.read_bytes()).hexdigest() == meta['generatedSHA256']
            sources.extend([report, path])
    for p in sources:
        assert not p.is_symlink(), f'Symlink needs explicit review: {p}'
    manifest = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sources}
    assert len(manifest) == len(sources), 'Duplicate package paths'
    try:
        revision = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD'], stderr=subprocess.DEVNULL, text=True).strip()
        dirty = bool(subprocess.check_output(['git', '-C', str(ROOT), 'status', '--porcelain', '--', '.', ':!distributions'], text=True).strip())
    except subprocess.CalledProcessError:
        prior = ROOT / 'PACKAGE_MANIFEST.json'
        revision = json.loads(prior.read_text()).get('source_commit') if prior.is_file() else None
        dirty = None  # No Git metadata: source hashes below remain authoritative.
    metadata = {'source_commit': revision, 'source_working_tree_dirty': dirty,
                'runtime_validation': 'NOT RUN by cloud packager; inspect actual local reports separately',
                'sha256': manifest}
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w') as z:
        for p in sorted(sources):
            write(z, str(p.relative_to(ROOT)), p.read_bytes())
        write(z, 'PACKAGE_MANIFEST.json', (json.dumps(metadata, indent=2) + '\n').encode())
    with zipfile.ZipFile(output) as z:
        assert z.testzip() is None
        assert len(z.namelist()) == len(set(z.namelist())), 'Duplicate ZIP members'
        for name, digest in manifest.items():
            assert hashlib.sha256(z.read('RL_in_Microgrid/' + name)).hexdigest() == digest
    print(json.dumps({'archive': str(output), 'files': len(manifest),
                      'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--include-generated', action='store_true')
    args = parser.parse_args()
    package(args.output, args.include_generated)
