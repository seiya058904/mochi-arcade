"""Fail-closed preservation of this job's two synthetic application save files."""
import hashlib
import json
from pathlib import Path
import time

NAMES = ('save.json', 'save.backup.json')


class SaveRestoration:
    def __init__(self, output, read, metadata, write, remove, stop):
        self.output = Path(output)
        self.read, self.metadata, self.write, self.remove, self.stop = read, metadata, write, remove, stop
        self.originals, self.details, self.phases = {}, {}, {}
        self.captured = False

    def phase(self, name, action):
        start = time.monotonic()
        try:
            value = action()
            self.phases[name] = {'status': 'PASS'}
            return True, value
        except Exception as error:
            self.phases[name] = {'status': 'FAIL', 'error': str(error)}
            return False, None
        finally:
            self.phases[name]['seconds'] = round(time.monotonic()-start, 3)
            self.save_report()

    def save_report(self):
        (self.output/'restoration.json').write_text(json.dumps({
            'captured': self.captured, 'originals': self.details, 'phases': self.phases
        }, indent=2)+'\n', encoding='utf-8')

    def capture(self):
        self.output.mkdir(parents=True, exist_ok=True)
        for name in NAMES:
            def one():
                contents = self.read(name)  # None means a positively observed absent file.
                meta = self.metadata(name) if contents is not None else None
                self.originals[name] = contents
                self.details[name] = {'exists': contents is not None, 'metadata': meta,
                                      'sha256': hashlib.sha256(contents).hexdigest() if contents is not None else None}
                if contents is not None:
                    path = self.output/('original-'+name)
                    path.write_bytes(contents)
                    assert path.read_bytes() == contents, 'Host preservation failed'
            ok, _ = self.phase('capture-'+name, one)
            if not ok:
                raise RuntimeError('Cannot preserve both originals; no fixture injection permitted')
        self.captured = True
        self.save_report()

    def restore(self):
        if not self.captured:
            self.phases['restore'] = {'status': 'NOT_RUN', 'reason': 'Both originals not captured; no injection allowed'}
            self.save_report()
            return False
        stopped, _ = self.phase('stop-app-and-confirm-no-pid', self.stop)
        if not stopped:
            self.phases['restore'] = {'status': 'NOT_RUN', 'reason': 'App stop not confirmed; unsafe to write'}
            self.save_report()
            return False
        good = True
        for name in NAMES:
            original = self.originals[name]
            def put():
                if original is None:
                    self.remove(name)
                else:
                    self.write(name, original)
            ok, _ = self.phase('write-'+name, put)
            good = good and ok
        for name in NAMES:
            def check():
                assert self.read(name) == self.originals[name], 'Original bytes/existence mismatch'
                if self.originals[name] is not None:
                    assert self.metadata(name) == self.details[name]['metadata'], 'Original owner/mode changed'
            ok, _ = self.phase('verify-'+name, check)
            good = good and ok
        self.phases['restore'] = {'status': 'PASS' if good else 'FAIL'}
        self.save_report()
        return good
