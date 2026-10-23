"""Launch only the disposable hosted AVD and retain its actual exit signal."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time

assert os.environ.get('GITHUB_ACTIONS')=='true'
assert Path(os.environ['ANDROID_AVD_HOME']).resolve().is_relative_to(Path(os.environ['RUNNER_TEMP']).resolve())
assert sys.argv[2:4]==['-avd','Mochi_CI_API34']
out=Path('.local/android-runtime')
with (out/'emulator.log').open('wb') as log:
    process=subprocess.Popen(sys.argv[1:],stdout=log,stderr=subprocess.STDOUT)
    (out/'emulator.pid').write_text(str(process.pid)+'\n')
    while process.poll() is None:
        try:
            state=Path(f'/proc/{process.pid}/status').read_text()
            fields={line.split(':',1)[0]:line.split(':',1)[1].strip() for line in state.splitlines() if ':' in line}
            with (out/'emulator-process.jsonl').open('a') as stream:
                stream.write(json.dumps({'monotonic':time.monotonic(),'pid':process.pid,
                    'state':fields.get('State'),'rss':fields.get('VmRSS'),'threads':fields.get('Threads')})+'\n')
        except FileNotFoundError:pass
        time.sleep(2)
    code=process.wait()
    (out/'emulator-exit.json').write_text(json.dumps({'pid':process.pid,'exit_code':code,
        'signal':-code if code<0 else None,'monotonic':time.monotonic()},indent=2)+'\n')
