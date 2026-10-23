"""Capture this disposable runner before releasing only its own emulator/Xvfb."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time
from android_evidence import diagnose

out=Path('.local/android-runtime');out.mkdir(parents=True,exist_ok=True)
report={'diagnostics':diagnose(out/'final-host'),'process_release':{},
        'runner':{key:os.environ.get(key) for key in ['ImageOS','ImageVersion','RUNNER_OS','RUNNER_ARCH']}}
for name in ['emulator','xvfb']:
    path=out/(name+'.pid')
    if not path.exists():continue
    pid=int(path.read_text().strip())
    try:
        command=Path(f'/proc/{pid}/cmdline').read_bytes().replace(b'\0',b' ').decode(errors='replace')
        assert ('Mochi_CI_API34' in command if name=='emulator' else 'Xvfb' in command),'PID ownership changed'
        os.kill(pid,signal.SIGTERM)
        deadline=time.monotonic()+10
        while Path(f'/proc/{pid}').exists() and time.monotonic()<deadline:time.sleep(.2)
        if Path(f'/proc/{pid}').exists():
            os.kill(pid,signal.SIGKILL)
            report['process_release'][name]='OWNED_PROCESS_KILLED_AFTER_DIAGNOSTICS'
        else:report['process_release'][name]='TERMINATED'
    except FileNotFoundError:report['process_release'][name]='ALREADY_EXITED_SIGNAL_UNVERIFIED'
    except Exception as error:report['process_release'][name]={'status':'FAIL','error':str(error)}
(out/'host-release.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
