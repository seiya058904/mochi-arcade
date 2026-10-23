"""Failure paths must retain evidence and must never write into a live app."""
import json
from pathlib import Path
import tempfile
import unittest
from android_restore import SaveRestoration
from summarize_android_gates import summarize


class RestorationTests(unittest.TestCase):
    def test_missing_or_unreviewed_gates_never_pass(self):
        with tempfile.TemporaryDirectory() as root:
            self.assertEqual(summarize(root,'a','b','c','swiftshader')['status'],'FAIL')
    def setup_case(self, root, fault=None, absent=False):
        files = {'save.json': b'new primary', 'save.backup.json': None if absent else b'older backup'}
        writes = []
        def read(name):
            if fault == 'backup-read' and name == 'save.backup.json': raise OSError('offline/read denied')
            if fault == 'mismatch' and writes: return b'incorrect'
            return files[name]
        def write(name, value):
            writes.append(name); files[name] = value
        def remove(name):
            writes.append(name); files[name] = None
        def stop():
            if fault in ['offline', 'stop-timeout']: raise TimeoutError(fault)
        obj=SaveRestoration(root,read,lambda name:'10141:10141:600',write,remove,stop)
        return obj,files,writes

    def test_success_and_original_absence(self):
        for absent in [False,True]:
            with self.subTest(absent=absent),tempfile.TemporaryDirectory() as root:
                obj,files,writes=self.setup_case(root,absent=absent)
                obj.capture();before=dict(files)
                files.update({'save.json':b'fixture','save.backup.json':b'fixture backup'})
                self.assertTrue(obj.restore());self.assertEqual(files,before)
                report=json.loads((Path(root)/'restoration.json').read_text())
                self.assertEqual(report['originals']['save.backup.json']['exists'],not absent)
                self.assertEqual((Path(root)/'original-save.json').read_bytes(),before['save.json'])

    def test_backup_read_failure_prevents_capture(self):
        with tempfile.TemporaryDirectory() as root:
            obj,files,writes=self.setup_case(root,'backup-read')
            with self.assertRaises(RuntimeError):obj.capture()
            self.assertFalse(obj.restore());self.assertEqual(writes,[])
            self.assertEqual(json.loads((Path(root)/'restoration.json').read_text())['phases']['capture-save.backup.json']['status'],'FAIL')

    def test_offline_and_stop_timeout_never_write(self):
        for fault in ['offline','stop-timeout']:
            with self.subTest(fault=fault),tempfile.TemporaryDirectory() as root:
                obj,files,writes=self.setup_case(root,fault);obj.capture()
                self.assertFalse(obj.restore());self.assertEqual(writes,[])
                self.assertEqual(obj.phases['restore']['status'],'NOT_RUN')

    def test_mismatch_fails_both_verifications_and_records(self):
        with tempfile.TemporaryDirectory() as root:
            obj,files,writes=self.setup_case(root,'mismatch');obj.capture()
            self.assertFalse(obj.restore())
            self.assertEqual(obj.phases['verify-save.json']['status'],'FAIL')
            self.assertEqual(obj.phases['verify-save.backup.json']['status'],'FAIL')
            self.assertEqual(json.loads((Path(root)/'restoration.json').read_text())['phases']['restore']['status'],'FAIL')


if __name__=='__main__': unittest.main()
