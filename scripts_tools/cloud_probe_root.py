"""Read-only identity and root diagnostic on the existing isolated hosted AVD."""
import json
from pathlib import Path
from android_evidence import AdbEvidence, require_owned

out = Path('.local/android-runtime')
out.mkdir(parents=True, exist_ok=True)
adb = AdbEvidence(out / 'root-probe')
report = {'status': 'FAIL'}
try:
    require_owned(adb)
    report['avd_ownership'] = 'PASS'
    report['build_type'] = adb('shell', 'getprop', 'ro.build.type')
    report['api_level'] = adb('shell', 'getprop', 'ro.build.version.sdk')
    report['abi'] = adb('shell', 'getprop', 'ro.product.cpu.abi')
    assert report['api_level'] == '34' and report['abi'] == 'x86_64'
    report['adb_root'] = adb('root', timeout=30)
    adb('wait-for-device', timeout=60)
    report['uid'] = adb('shell', 'id', '-u')
    assert report['uid'] == '0', 'ADB did not become root'
    report['status'] = 'PASS_ROOT_ON_ISOLATED_AVD'
finally:
    (out / 'root-probe-report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
