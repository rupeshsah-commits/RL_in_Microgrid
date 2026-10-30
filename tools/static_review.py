#!/usr/bin/env python3
"""Inspect SLX ZIP/XML only. Does not claim Simulink model validity."""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Load_Changes_AC_Droop_four_inverter.slx'
EXPECTED_SHA256 = '3ca2e549c1606e2d371ce172c16f06c50f1d0f3ee690d6c7a8b004fee8cd3123'


def params(node):
    return {p.attrib['Name']: p.text for p in node.findall('P')}


def inspect():
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    assert digest == EXPECTED_SHA256, 'Original model changed; investigate before updating the recorded hash'
    report = {'original': SOURCE.name, 'sha256': digest,
              'runtime_validation': 'PENDING: MATLAB/Simulink not installed or run',
              'static_checks': [], 'secondary_connections': [], 'controller_scripts': {}}
    with zipfile.ZipFile(SOURCE) as z:
        assert z.testzip() is None
        xml = {n: ET.fromstring(z.read(n)) for n in z.namelist() if n.endswith('.xml')}
        report['xml_files_parsed'] = len(xml)
        report['archive_entries'] = len(z.namelist())
        report['static_checks'] += ['ZIP CRC integrity', 'All XML parsed']
        root = xml['simulink/systems/system_root.xml']
        report['root_callbacks'] = {p.attrib['Name']: p.text for p in xml['simulink/blockdiagram.xml'].iter('P') if p.attrib.get('Name', '').endswith('Fcn') and p.text}
        dg_blocks = [b for b in root.findall('Block') if b.attrib['Name'] in ['DG1', 'DG2', 'DG3', 'DG4']]
        assert len(dg_blocks) == 4
        for dg in dg_blocks:
            ref = dg.find('System').attrib['Ref']
            system = xml[f'simulink/systems/{ref}.xml']
            blocks = {b.attrib['Name']: b for b in system.findall('Block')}
            sid_to_name = {b.attrib['SID']: b.attrib['Name'] for b in system.findall('Block')}
            for gain, target in [('Gain', 'Sum2'), ('Gain9', 'Sum6')]:
                assert params(blocks[gain])['Gain'] == '5'
                sid = blocks[gain].attrib['SID']
                lines = [l for l in system.findall('Line') if params(l).get('Src') == f'{sid}#out:1']
                assert len(lines) == 1 and not lines[0].findall('Branch')
                dest = params(lines[0])['Dst']
                target_sid, port = dest.split('#in:')
                assert sid_to_name[target_sid] == target and port == '2'
                assert params(blocks[target])['Inputs'] == '|-++'
                report['secondary_connections'].append(f"{dg.attrib['Name']}/{gain} -> {target}/2 (+)")
            if dg.attrib['Name'] == 'DG1':
                step = params(blocks['Step'])
                assert step['Before'] == step['After'] == '338.8460811'
            else:
                assert params(blocks['Constant1'])['Value'] == '338.8460811'
            assert params(blocks['Constant5'])['Value'] == '2*pi*60'
        tags = {params(b).get('GotoTag') for b in root.findall('Block') if b.attrib['BlockType'] == 'Goto'}
        assert {f'{prefix}{i}' for prefix in ['w','Vd'] for i in range(1,5)} <= tags
        loads = {b.attrib['Name']: b for b in root.findall('Block')}
        assert any(p.attrib.get('Name') == 'ActivePower' and p.text == '20e3' for p in loads['Load 5'].iter('P'))
        assert any(p.attrib.get('Name') == 'SwitchTimes' and p.text == '[6]' for p in loads['Three-Phase Breaker1'].iter('P'))
        for n, node in xml.items():
            if 'stateflow/chart_' in n:
                report['controller_scripts'][n] = [p.text for p in node.iter('P') if p.attrib.get('Name') == 'script']
        report['static_checks'] += ['Eight additive secondary injection points', 'Eight measurement tags',
                                    '60 Hz and 338.8460811 V references', 'Switched Load 5 and 6 s breaker event']
        report['saved_release'] = 'R2025a Update 1 (25.1.0.2973910)'
        report['external_library_reference'] = 'MGLib/Subsystem: resolution must be checked locally'
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    result = json.dumps(inspect(), indent=2) + '\n'
    if args.report:
        args.report.write_text(result)
    print(result)
