"""Prove that test tools T still exercise the exact runtime/export inputs from S."""
import json
import os
from pathlib import Path
import subprocess
from release_identity import build_inputs

source=os.environ['MOCHI_STAGED_SOURCE_SHA'];sha=os.environ['MOCHI_STAGED_APK_SHA256']
build_inputs(sha,source)
subprocess.run(['git','fetch','--no-tags','--depth=1','origin',source],check=True)
def tree(ref):
    raw=subprocess.check_output(['git','ls-tree','-r',ref,'--','scripts','scenes','assets','project.godot','export_presets.cfg'],encoding='utf-8')
    return dict((line.split('\t',1)[1],line.split('\t',1)[0].split()[2]) for line in raw.splitlines())
original=tree(source);current=tree('HEAD')
assert original and original==current,'Candidate source has runtime/assets/export drift'
out=Path('.local/android-runtime');out.mkdir(parents=True,exist_ok=True)
(out/'source-equivalence.json').write_text(json.dumps({'status':'PASS','S':source,'T':os.environ['GITHUB_SHA'],
    'apk_sha256':sha,'runtime_git_blob_ids':original},indent=2)+'\n',encoding='utf-8')
