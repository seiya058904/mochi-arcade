"""Fresh, bounded UIAutomator observations; missing XML is a capture failure."""
import json
from pathlib import Path
import re
import time
import uuid
import xml.etree.ElementTree as ET


def dump_hierarchy(adb, destination):
    """Never consume an earlier dump, even when UIAutomator exits zero."""
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.unlink(missing_ok=True)  # This generated observation cannot stay stale.
    remote = '/sdcard/mochi-ui-' + uuid.uuid4().hex + '.xml'
    evidence = {'status': 'FAIL', 'remote': remote, 'started_unix': time.time(),
                'command_timeline': 'adb-timeline.jsonl'}
    stage = 'freshness'
    owned = False
    try:
        adb('shell', 'test', '-e', remote, check=False, timeout=5)
        if adb.last_exit != 1:
            raise RuntimeError('Fresh XML path is occupied or could not be checked')
        owned = True
        stage = 'dump'
        stdout = adb('shell', 'uiautomator', 'dump', remote, check=False, timeout=15)
        evidence['dump'] = {'exit': adb.last_exit, 'stdout': stdout,
                            'stderr': adb.last_stderr}
        if adb.last_exit != 0:
            raise RuntimeError('UIAutomator dump command failed')
        stage = 'existence'
        adb('shell', 'test', '-e', remote, check=False, timeout=5)
        if adb.last_exit != 0:
            raise RuntimeError('UIAutomator returned zero but produced no readable XML file')
        stage = 'read'
        document = adb('shell', 'cat', remote, check=False, timeout=5)
        if adb.last_exit != 0:
            raise RuntimeError('Fresh UIAutomator XML could not be read')
        destination.write_text(document, encoding='utf-8')
        stage = 'empty'
        if not document.strip():
            raise RuntimeError('Fresh UIAutomator XML is empty')
        stage = 'parse'
        root = ET.fromstring(document)
        if root.tag != 'hierarchy':
            raise RuntimeError('UIAutomator XML has no hierarchy root')
        evidence['status'] = 'PASS'
        return root
    except Exception as error:
        evidence.update(failed_stage=stage, error=str(error))
        raise RuntimeError(f'UI capture failed at {stage}: {error}; icon state UNVERIFIED') from error
    finally:
        # Read-only foreground evidence, independent of XML availability.
        try:
            foreground = adb('shell', 'dumpsys', 'activity', 'activities', check=False, timeout=5)
            destination.with_suffix('.foreground.txt').write_text(foreground, encoding='utf-8')
            evidence['foreground_exit'] = adb.last_exit
        except Exception as error:
            evidence['foreground_error'] = str(error)
        if owned:
            try:
                adb('shell', 'rm', '-f', remote, check=False, timeout=5)
                evidence['remote_cleanup_exit'] = adb.last_exit
            except Exception as error:
                evidence['remote_cleanup_error'] = str(error)
        destination.with_suffix('.capture.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')


def require_foreground(adb, package, destination):
    """A pre-existing PID alone cannot prove that an icon opened the app."""
    foreground = adb('shell', 'dumpsys', 'activity', 'activities', timeout=5)
    Path(destination).write_text(foreground, encoding='utf-8')
    resumed = [line for line in foreground.splitlines()
               if re.search(r'\b(?:topResumedActivity|mResumedActivity)\s*[:=]', line)]
    if not any(re.search(r'(?<![\w.])' + re.escape(package) + r'/', line) for line in resumed):
        raise RuntimeError('Launcher icon tap did not bring the app to the foreground')
