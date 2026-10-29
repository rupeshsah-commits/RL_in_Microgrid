#!/usr/bin/env python3
"""Inventory archived blocks/parameters without executing MATLAB or callbacks."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Load_Changes_AC_Droop_four_inverter.slx'


def audit():
    with zipfile.ZipFile(SOURCE) as z:
        assert z.testzip() is None
        xml = {n: ET.fromstring(z.read(n)) for n in z.namelist() if n.endswith('.xml')}
        systems = {Path(n).stem: node for n, node in xml.items() if '/systems/' in n}
        blocks = []

        def walk(ref, parent):
            for b in systems[ref].findall('Block'):
                path = parent + '/' + b.attrib['Name']
                ps = {p.attrib['Name']: p.text for p in b.iter('P')
                      if p.attrib.get('Name') not in ['GraphicalSettings', 'ScopeSpecificationString']}
                masks = {p.attrib['Name']: p.findtext('Value') for p in b.findall('./Mask/MaskParameter')}
                blocks.append({'path': path, 'type': b.attrib['BlockType'],
                               'sid': b.attrib['SID'], 'parameters': ps, 'mask': masks})
                sub = b.find('System')
                if sub is not None and 'Ref' in sub.attrib:
                    walk(sub.attrib['Ref'], path)
        walk('system_root', SOURCE.stem)
        configs = {n: {p.attrib['Name']: p.text for p in x.iter('P')
                      if p.attrib.get('Name') in ['SolverName', 'FixedStep', 'MaxStep', 'StartTime', 'StopTime']}
                   for n, x in xml.items() if 'configSet' in n}
        report = {'source': SOURCE.name, 'sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                  'runtime_validation': 'NOT RUN', 'archive_entries': len(z.namelist()),
                  'xml_documents': len(xml), 'block_count': len(blocks), 'solver_config_sets': configs,
                  'K_v_ref_occurrences': sum(z.read(n).count(b'K_v_ref') for n in xml), 'blocks': blocks}
    target = ROOT / 'docs' / 'model_inventory.json'
    target.write_text(json.dumps(report, indent=2) + '\n')
    print(f'{len(blocks)} blocks inventoried; {len(xml)} XML documents; runtime NOT RUN')


if __name__ == '__main__':
    audit()
