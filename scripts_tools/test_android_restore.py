"""Failure paths must retain evidence and must never write into a live app."""
import json
import hashlib
from pathlib import Path
import tempfile
import unittest
from android_restore import SaveRestoration
from summarize_android_gates import summarize, GATES, GAMES


class RestorationTests(unittest.TestCase):
    def test_missing_or_unreviewed_gates_never_pass(self):
        with tempfile.TemporaryDirectory() as root:
            self.assertEqual(summarize(root,'a','b','c','swiftshader')['status'],'FAIL')

    def test_complete_gates_require_matching_identity_review_and_restoration(self):
        with tempfile.TemporaryDirectory() as root:
            def write(path,value):
                path.parent.mkdir(parents=True,exist_ok=True)
                path.write_text(json.dumps(value),encoding='utf-8')
            for gate in GATES:
                folder=Path(root)/('android-runtime-evidence-'+gate)
                write(folder/'gate-report.json',{'gate':gate,'status':'PASS_AUTOMATION_AWAITING_VISUAL_REVIEW',
                    'apk_sha256':'a','build_source':'b','tool_commit':'c','profile':'swiftshader','renderer':['SwiftShader'],
                    'run_id':'1','attempt':'1','clean_uninstall':'PASS_PACKAGE_AND_DATA_ABSENT'})
                write(folder/'source-equivalence.json',{'status':'PASS','S':'b','T':'c','apk_sha256':'a'})
                write(folder/'host-release.json',{'process_release':{'emulator':'TERMINATED'}})
                child={'status':'PASS_TEST','apk_sha256':'a'}
                if gate.startswith('U'):
                    child.update(semantics={g:{'status':'PASS'} for g in GAMES},predecessor_tag='v1.1.0' if gate=='U110' else 'v1.0.0')
                    name='upgrade/upgrade-report.json'
                elif gate=='CLEAN':
                    child['game_checks']={g:{'background_cycles':[{'visible':True,'checkpoint_equal':True}]*3,
                        'round_restored_after_force_stop':True,'restart_zero_score':True} for g in GAMES}
                    name='clean/report.json'
                else:
                    child.update(original_save_restored=True,original_backup_restored=True,
                                 loads={g:{'status':'PASS'} for g in ['bouncy_balls','jelly_slice']})
                    name='load/load-report.json'
                write(folder/name,child)
                (folder/'capture.png').write_bytes(b'synthetic review fixture')
                write(folder/'visual-review.json',{'status':'PASS_REVIEWED','apk_sha256':'a','run_id':'1',
                    'files':{'capture.png':hashlib.sha256(b'synthetic review fixture').hexdigest()}})
            self.assertEqual(summarize(root,'a','b','c','swiftshader')['status'],'PASS')
            for target, key, value in [('U110/gate-report.json','apk_sha256','wrong'),
                                       ('CLEAN/visual-review.json','status','AWAITING_VISUAL_REVIEW'),
                                       ('LOAD/load/load-report.json','original_backup_restored',False)]:
                path=Path(root)/('android-runtime-evidence-'+target)
                original=json.loads(path.read_text());changed=dict(original);changed[key]=value
                write(path,changed)
                self.assertEqual(summarize(root,'a','b','c','swiftshader')['status'],'FAIL')
                write(path,original)
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
