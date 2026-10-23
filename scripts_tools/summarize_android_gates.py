"""A release gate summary succeeds only with four matching runs AND visual reviews."""
import argparse
import hashlib
import json
from pathlib import Path

GATES=('U110','U100','CLEAN','LOAD')


def summarize(root, sha, source, tool, profile):
    result={'status':'FAIL','apk_sha256':sha,'build_source':source,'tool_commit':tool,'profile':profile,'gates':{}}
    for gate in GATES:
        folder=Path(root)/('android-runtime-evidence-'+gate)
        try:
            report=json.loads((folder/'gate-report.json').read_text(encoding='utf-8'))
            assert report['gate']==gate and report['status']=='PASS_AUTOMATION_AWAITING_VISUAL_REVIEW'
            for key,value in [('apk_sha256',sha),('build_source',source),('tool_commit',tool),('profile',profile)]:
                assert report[key]==value,key+' mismatch'
            assert report['renderer'], 'Actual renderer missing'
            child=json.loads((folder/('upgrade/upgrade-report.json' if gate.startswith('U') else 'clean/report.json' if gate=='CLEAN' else 'load/load-report.json')).read_text(encoding='utf-8'))
            assert child['status'].startswith('PASS') and child['apk_sha256']==sha
            if gate.startswith('U'):
                assert len(child['semantics'])==8 and all(v['status']=='PASS' for v in child['semantics'].values())
            if gate=='LOAD':assert child['original_save_restored'] and child['original_backup_restored']
            review=json.loads((folder/'visual-review.json').read_text(encoding='utf-8'))
            assert review['status']=='PASS_REVIEWED' and review['apk_sha256']==sha and review['run_id']==report['run_id']
            actual={str(p.relative_to(folder)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in folder.rglob('*') if p.suffix in ('.png','.mp4') and 'review' not in p.parts}
            assert actual and review['files']==actual,'Visual review coverage or bytes mismatch'
            result['gates'][gate]={'status':'PASS','run_id':report['run_id'],'attempt':report['attempt'],'reviewed_files':len(actual)}
        except Exception as error:
            result['gates'][gate]={'status':'FAIL_OR_INCOMPLETE','error':str(error)}
    if all(v['status']=='PASS' for v in result['gates'].values()):result['status']='PASS'
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser()
    for name in ['root','sha','source','tool','profile']:p.add_argument('--'+name,required=True)
    args=p.parse_args();result=summarize(args.root,args.sha,args.source,args.tool,args.profile)
    (Path(args.root)/'release-gates.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2));raise SystemExit(0 if result['status']=='PASS' else 1)
