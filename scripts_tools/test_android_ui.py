"""Regress zero-exit/no-file dumps and false launcher success without a device."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from android_evidence import AdbEvidence
from android_ui import dump_hierarchy, require_foreground

VALID = '<hierarchy><node text="Mochi Arcade" bounds="[0,0][10,10]"/></hierarchy>'
PACKAGE = 'io.github.seiya058904.mochiarcade'


class Guest:
    def __init__(self, document=VALID, fault=None):
        self.document, self.fault = document, fault
        self.files = {'/sdcard/mochi-launcher.xml': VALID}  # Historical stale path.
        self.calls = []
        self.last_exit, self.last_stderr = None, ''

    def __call__(self, *parts, **kwargs):
        self.calls.append(parts)
        self.last_exit, self.last_stderr = 0, ''
        if parts[1] == 'test':
            self.last_exit = 0 if parts[-1] in self.files else 1
        elif parts[1] == 'uiautomator':
            self.last_stderr = 'ERROR: could not get idle state' if self.fault else ''
            if self.fault == 'timeout':
                raise subprocess.TimeoutExpired('dump', 15)
            if self.fault == 'dump': self.last_exit = 1
            if self.fault not in ('missing', 'dump'): self.files[parts[-1]] = self.document
            return 'UI hierchary dumped to: ' + parts[-1]
        elif parts[1] == 'cat':
            if self.fault == 'read': self.last_exit = 1; return ''
            return self.files[parts[-1]]
        elif parts[1] == 'dumpsys':
            return 'mResumedActivity: ActivityRecord{123 u0 com.android.launcher3/.Launcher t1}'
        elif parts[1] == 'rm':
            self.files.pop(parts[-1], None)
        return ''


class UiTests(unittest.TestCase):
    def test_package_version_text_handles_windows_adb_newlines_without_changing_bytes(self):
        # Windows adb shell returns CRLF; exact signed version checks still require
        # the complete version token, while save/APK binary reads must stay exact.
        with tempfile.TemporaryDirectory() as temp:
            recorder = AdbEvidence(temp)
            for ending in (b'\n', b'\r\n'):
                raw = ending.join((b'  versionCode=2 minSdk=24', b'  versionName=1.1.0', b'  enabled=true'))
                with patch('android_evidence.subprocess.run', return_value=subprocess.CompletedProcess([], 0, raw, b'')):
                    text = recorder('shell', 'dumpsys', 'package', PACKAGE)
                    self.assertIn('versionName=1.1.0\n', text)
                    self.assertNotIn('versionName=1.1.1\n', text)
                    self.assertEqual(recorder('shell', 'cat', 'save.json', binary=True), raw)

    def test_unexpected_existing_path_is_not_read_or_removed(self):
        with tempfile.TemporaryDirectory() as temp:
            guest = Guest(); guest.files['/sdcard/mochi-ui-collision.xml'] = VALID
            with patch('android_ui.uuid.uuid4') as token:
                token.return_value.hex = 'collision'
                with self.assertRaisesRegex(RuntimeError, 'occupied'):
                    dump_hierarchy(guest, Path(temp)/'launcher.xml')
            self.assertEqual(guest.files['/sdcard/mochi-ui-collision.xml'], VALID)
            self.assertFalse(any(call[1] in ('cat', 'rm', 'uiautomator') for call in guest.calls))

    def test_zero_exit_missing_file_never_reads_stale_local_or_remote_xml(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/'launcher.xml'; path.write_text(VALID)
            guest = Guest(fault='missing')
            with self.assertRaisesRegex(RuntimeError, 'produced no readable XML.*icon state UNVERIFIED'):
                dump_hierarchy(guest, path)
            self.assertFalse(path.exists())
            self.assertFalse(any(call[1] == 'cat' for call in guest.calls))
            evidence = json.loads(path.with_suffix('.capture.json').read_text())
            self.assertEqual(evidence['dump']['exit'], 0)
            self.assertIn('could not get idle', evidence['dump']['stderr'])
            self.assertIn('dumped to', evidence['dump']['stdout'])
            self.assertEqual(evidence['failed_stage'], 'existence')
            self.assertIn('launcher3', path.with_suffix('.foreground.txt').read_text())
            self.assertEqual(guest.files, {'/sdcard/mochi-launcher.xml': VALID})

    def test_empty_malformed_and_wrong_root_are_capture_failures(self):
        for document, stage in [('', 'empty'), ('  ', 'empty'), ('<hierarchy>', 'parse'), ('<html/>', 'parse')]:
            with self.subTest(document=document), tempfile.TemporaryDirectory() as temp:
                path = Path(temp)/'launcher.xml'
                with self.assertRaisesRegex(RuntimeError, 'icon state UNVERIFIED'):
                    dump_hierarchy(Guest(document), path)
                evidence = json.loads(path.with_suffix('.capture.json').read_text())
                self.assertEqual(evidence['failed_stage'], stage)
                self.assertEqual(evidence['status'], 'FAIL')
                self.assertEqual(path.read_text(), document)

    def test_dump_read_and_timeout_fail_without_retry(self):
        for fault, stage in [('dump', 'dump'), ('read', 'read'), ('timeout', 'dump')]:
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as temp:
                guest = Guest(fault=fault); path = Path(temp)/'launcher.xml'
                with self.assertRaises(RuntimeError): dump_hierarchy(guest, path)
                self.assertEqual(sum(call[1] == 'uiautomator' for call in guest.calls), 1)
                self.assertEqual(json.loads(path.with_suffix('.capture.json').read_text())['failed_stage'], stage)
                self.assertEqual(guest.files, {'/sdcard/mochi-launcher.xml': VALID})

    def test_valid_capture_is_fresh_and_old_remote_is_untouched(self):
        with tempfile.TemporaryDirectory() as temp:
            guest = Guest(); path = Path(temp)/'launcher.xml'
            for _ in range(2):
                self.assertEqual(dump_hierarchy(guest, path).find('node').get('text'), 'Mochi Arcade')
                self.assertEqual(json.loads(path.with_suffix('.capture.json').read_text())['status'], 'PASS')
            paths = [call[-1] for call in guest.calls if call[1] == 'uiautomator']
            self.assertEqual(len(set(paths)), 2)
            self.assertEqual(guest.files, {'/sdcard/mochi-launcher.xml': VALID})

    def test_foreground_requires_resumed_app_not_existing_pid_or_back_stack(self):
        for field in ('mResumedActivity:', 'topResumedActivity='):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as temp:
                path = Path(temp)/'foreground.txt'
                require_foreground(lambda *a, **kw: field + ' ActivityRecord{u0 ' + PACKAGE + '/.GodotApp}', PACKAGE, path)
                for text in ('mResumedActivity: com.android.launcher3/.Launcher\nHist #0: ' + PACKAGE + '/.GodotApp',
                             'mResumedActivity: prefix.' + PACKAGE + '/.GodotApp'):
                    with self.assertRaisesRegex(RuntimeError, 'foreground'):
                        require_foreground(lambda *a, **kw: text, PACKAGE, path)

    def test_recorder_retains_separate_stdout_stderr_and_timeout_output(self):
        with tempfile.TemporaryDirectory() as temp:
            recorder = AdbEvidence(temp)
            with patch('android_evidence.subprocess.run', return_value=subprocess.CompletedProcess([], 0, b'out', b'err')):
                recorder('shell', 'uiautomator', 'dump', '/sdcard/test.xml')
            with patch('android_evidence.subprocess.run', side_effect=subprocess.TimeoutExpired('adb', 15, output=b'partial', stderr=b'error')):
                with self.assertRaises(subprocess.TimeoutExpired):
                    recorder('shell', 'uiautomator', 'dump', '/sdcard/test.xml')
            events = [json.loads(line) for line in (Path(temp)/'adb-timeline.jsonl').read_text().splitlines()]
            self.assertEqual((events[0]['stdout'], events[0]['stderr'], events[0]['exit']), ('out', 'err', 0))
            self.assertEqual((events[1]['stdout'], events[1]['stderr'], events[1]['timeout']), ('partial', 'error', True))
            self.assertIsNone(recorder.last_exit)


if __name__ == '__main__': unittest.main()
