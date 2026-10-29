#!/usr/bin/env python3
"""Extract MATLAB Function code templates for syntax checks without MATLAB."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def extract(output):
    code = (ROOT / 'residual_rl' / 'build_residual_model.m').read_text()
    pattern = r"chart\((?:iface|model),'([^']+)',sprintf\(\[(.*?)\](?:,p)?\)\);"
    found = list(re.finditer(pattern, code, re.S))
    assert len(found) == 5, 'Unexpected template structure: inspect new builder templates'
    for match in found:
        chunks = re.findall(r"'((?:''|[^'])*)'", match[2])
        text = ''.join(x.replace("''", "'") for x in chunks)
        # This verifies syntax of template code, not constant struct types/dimensions.
        text = text.replace(r'\n', '\n').replace('%s', 'struct()')
        folder = output / match[1]
        folder.mkdir(parents=True, exist_ok=True)
        (folder / 'f.m').write_text(text + '\n')
    print(f'{len(found)} generated-code templates extracted; parameter typing remains pending MATLAB')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    extract(parser.parse_args().output)
