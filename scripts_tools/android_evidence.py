"""Bounded, read-only observations for the job-owned Android acceptance guest."""
import json
import os
from pathlib import Path
import subprocess
import time

PACKAGE = 'io.github.seiya058904.mochiarcade'


def require_owned(adb):
    assert os.environ.get('GITHUB_ACTIONS') == 'true', 'Only the isolated hosted job is authorized'
    assert Path(os.environ['ANDROID_AVD_HOME']).resolve().is_relative_to(Path(os.environ['RUNNER_TEMP']).resolve())
    assert adb('emu', 'avd', 'name').splitlines()[0] == 'Mochi_CI_API34'
    assert adb('shell', 'getprop', 'ro.kernel.qemu') == '1'
    assert adb('shell', 'getprop', 'ro.build.type') == 'userdebug'


class AdbEvidence:
    def __init__(self, output, serial='emulator-5554', timeout=30):
        self.output = Path(output)
        self.output.mkdir(parents=True, exist_ok=True)
        self.serial, self.timeout, self.phase = serial, timeout, 'initialization'
        self.app_pid = 'UNOBSERVED'
        self.last_exit = None

    def __call__(self, *parts, data=None, binary=False, timeout=None, check=True):
        args = list(map(str, parts))
        start = time.monotonic()
        event = {'phase': self.phase, 'monotonic_start': start, 'command': args,
                 'app_pid_last_observed': self.app_pid, 'emulator_pid': os.environ.get('MOCHI_EMULATOR_PID'),
                 'exit': None, 'timeout': False}
        try:
            result = subprocess.run(['adb', '-s', self.serial, *args], input=data,
                                    capture_output=True, timeout=timeout or self.timeout)
            event['exit'] = result.returncode
            self.last_exit = result.returncode
            if args[:2] == ['shell', 'pidof']:
                self.app_pid = result.stdout.decode(errors='replace').strip() or 'ABSENT'
            if check and result.returncode:
                raise RuntimeError(f'ADB {args}: {result.stderr.decode(errors="replace")}')
            return result.stdout if binary else result.stdout.decode(errors='replace').strip()
        except subprocess.TimeoutExpired:
            event['timeout'] = True
            raise
        finally:
            event['seconds'] = round(time.monotonic() - start, 3)
            with (self.output/'adb-timeline.jsonl').open('a', encoding='utf-8') as log:
                log.write(json.dumps(event) + '\n')


def diagnose(output, serial='emulator-5554'):
    """Each probe stands alone; never restart, kill, change permissions or repair."""
    output = Path(output); output.mkdir(parents=True, exist_ok=True)
    prefix = ['adb', '-s', serial]
    probes = {
        'transport': ['adb', 'devices', '-l'],
        'light-shell': prefix + ['shell', 'echo', 'MOCHI_PROBE'],
        'app-pid': prefix + ['shell', 'pidof', PACKAGE],
        'activity-manager': prefix + ['shell', 'dumpsys', 'activity', 'processes'],
        'surface-flinger': prefix + ['shell', 'dumpsys', 'SurfaceFlinger', '--list'],
        'guest-processes': prefix + ['shell', 'ps', '-A', '-T'],
        'guest-anr-index': prefix + ['shell', 'ls', '-l', '/data/anr', '/data/tombstones'],
        'guest-logcat': prefix + ['logcat', '-d', '-v', 'threadtime'],
        'host-processes': ['ps', '-eo', 'pid,ppid,stat,etimes,rss,vsz,wchan:32,comm'],
        'host-memory': ['free', '-m'],
        'host-disk': ['df', '-h'],
    }
    pid = os.environ.get('MOCHI_EMULATOR_PID', '')
    if pid.isdigit():
        probes['emulator-threads'] = ['ps', '-L', '-p', pid, '-o', 'pid,tid,stat,wchan:40,comm']
        probes['emulator-status'] = ['cat', f'/proc/{pid}/status']
        probes['emulator-kernel-stack'] = ['sudo', '-n', 'cat', f'/proc/{pid}/stack']
    report = {}
    for name, command in probes.items():
        start = time.monotonic()
        try:
            r = subprocess.run(command, capture_output=True, timeout=5)
            (output/(name+'.txt')).write_bytes(r.stdout+r.stderr)
            report[name] = {'status': 'OBSERVED' if r.returncode == 0 else 'NOT_AVAILABLE', 'exit': r.returncode}
        except Exception as error:
            report[name] = {'status': 'NOT_AVAILABLE', 'error': str(error)}
        report[name]['seconds'] = round(time.monotonic()-start, 3)
    (output/'diagnostics.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    return report
