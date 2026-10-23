"""One independent acceptance gate on one predeclared job-owned AVD."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from android_capture import capture_png
from android_evidence import AdbEvidence, PACKAGE, require_owned, diagnose

ACTIVITY = PACKAGE + '/com.godot.game.GodotAppLauncher'


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--gate',choices=['DIAG','U110','U100','CLEAN','LOAD'],required=True)
    parser.add_argument('--apk',type=Path,required=True)
    parser.add_argument('--release',action='store_true')
    args=parser.parse_args()
    out=Path('.local/android-runtime');out.mkdir(parents=True,exist_ok=True)
    adb=AdbEvidence(out/'gate')
    def shell(*parts,**kwargs):return adb('shell',*parts,**kwargs)
    report={'status':'FAIL','gate':args.gate,'tool_commit':os.environ.get('GITHUB_SHA'),
            'build_source':os.environ.get('MOCHI_STAGED_SOURCE_SHA') or os.environ.get('GITHUB_SHA'),
            'run_id':os.environ.get('GITHUB_RUN_ID'),'attempt':os.environ.get('GITHUB_RUN_ATTEMPT'),
            'apk_sha256':hashlib.sha256(args.apk.read_bytes()).hexdigest(),
            'profile':os.environ.get('MOCHI_EMULATOR_GPU'),'children':{},'visual_review':'PENDING'}
    stream=None;stream_file=None
    def child(name,command):
        adb.phase=name
        start=time.monotonic()
        r=subprocess.run([sys.executable,'scripts_tools/'+command[0],*map(str,command[1:])])
        report['children'][name]={'exit':r.returncode,'seconds':round(time.monotonic()-start,3)}
        assert r.returncode==0,name+' failed; original report retained'
    def stop():
        shell('am','force-stop',PACKAGE,timeout=40)
        assert shell('pidof',PACKAGE,check=False)=='' and adb.last_exit==1
        assert shell('echo','STOPPED')=='STOPPED'
    def fresh():
        assert shell('pm','path',PACKAGE,check=False)=='' and adb.last_exit in (0,1)
        result=shell('sh','-c',f"'if [ -e /data/user/0/{PACKAGE} ]; then echo EXISTS; else echo ABSENT; fi'")
        assert result=='ABSENT','Independent gate has pre-existing application data'
    def uninstall():
        stop()
        assert 'Success' in adb('uninstall',PACKAGE,timeout=120)
        fresh()
    def launch():
        assert 'Status: ok' in shell('am','start','-W','-n',ACTIVITY)
        time.sleep(5)
        assert shell('pidof',PACKAGE)
    def tap(x,y):
        shell('input','tap',x,y);time.sleep(.6)
    def shot(name):
        data,frame=capture_png(adb('exec-out','screencap',binary=True))
        (out/(name+'.png')).write_bytes(data)
        report.setdefault('frames',{})[name]=dict(frame,sha256=hashlib.sha256(data).hexdigest())
        assert frame['has_visible_content'],name+' blank'
    def install_baseline(apk,label):
        adb.phase=label+'-baseline'
        fresh()
        assert 'Success' in adb('install','--no-incremental',str(apk),timeout=120)
        launch()
        shell('uiautomator','dump','/sdcard/mochi-gate-window.xml')
        xml=shell('cat','/sdcard/mochi-gate-window.xml')
        (out/(label+'-window.xml')).write_text(xml,encoding='utf-8')
        for node in ET.fromstring(xml).iter('node'):
            if node.get('text','').upper()=='GOT IT':
                b=list(map(int,re.findall(r'\d+',node.attrib['bounds'])));tap((b[0]+b[2])//2,(b[1]+b[3])//2)
        shot(label+'-home')
        tap(650,70);tap(608,360);tap(608,360)  # Two real settings commits create both files.
        shell('input','keyevent','KEYCODE_BACK');time.sleep(.8)
        stop()
        for name in ['save.json','save.backup.json']:
            data=adb('shell','cat',f'/data/user/0/{PACKAGE}/files/{name}',binary=True)
            assert json.loads(data)['version']==1
            (out/(label+'-baseline-'+name)).write_bytes(data)
        report.setdefault('baselines',{})[label]={'status':'PASS','source':'This fresh AVD, actual settings inputs'}
    def bouncy_control(apk,label):
        install_baseline(apk,label)
        launch();tap(530,620);tap(360,775)
        shell('input','swipe',360,1060,500,1060,300)
        for n in range(3):
            adb.phase=label+'-background-'+str(n+1)
            pid=shell('pidof',PACKAGE)
            shell('input','keyevent','KEYCODE_HOME');time.sleep(.8);launch()
            assert shell('pidof',PACKAGE)==pid
            shot(label+'-return-'+str(n+1))
            tap(360,679)
        stop();report.setdefault('controls',{})[label]={'status':'PASS_THREE_RETURNS_AND_STOP',
                                                       'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest()}
    try:
        deadline=time.monotonic()+240
        while time.monotonic()<deadline:
            if shell('getprop','sys.boot_completed',check=False,timeout=10)=='1':break
            time.sleep(3)
        else:raise RuntimeError('Boot incomplete after 240 seconds')
        require_owned(adb)
        time.sleep(15)
        adb('root');adb('wait-for-device')
        assert shell('id','-u')=='0'
        assert '720x1280' in shell('wm','size')
        shell('input','keyevent','KEYCODE_WAKEUP');shell('wm','dismiss-keyguard')
        stream_file=(out/'gate-stream-logcat.txt').open('wb')
        stream=subprocess.Popen(['adb','-s','emulator-5554','logcat','-v','threadtime'],stdout=stream_file,stderr=subprocess.STDOUT)
        renderer=shell('dumpsys','SurfaceFlinger')
        (out/'renderer.txt').write_text(renderer,encoding='utf-8')
        report['renderer']=[line for line in renderer.splitlines() if 'GLES:' in line]
        if report['profile']=='swiftshader':
            assert any('swiftshader' in line.lower() for line in report['renderer']),'Requested renderer not observed'
        fresh()
        release=['--release'] if args.release else []
        if args.gate in ['U110','U100']:
            assert args.release and os.environ.get('MOCHI_STAGED_SOURCE_SHA')
            predecessor='v1.1.0' if args.gate=='U110' else 'v1.0.0'
            child('predecessor',['android_smoke.py','--apk','dist/MochiArcade-predecessor.apk','--output',str(out/'old-version'),'--release'])
            child('upgrade',['android_upgrade.py','--apk',str(args.apk),'--old-evidence',str(out/'old-version'),'--output',str(out/'upgrade'),
                             '--predecessor',predecessor,'--source',os.environ['MOCHI_STAGED_SOURCE_SHA'],'--sha256',os.environ['MOCHI_STAGED_APK_SHA256']])
        elif args.gate=='CLEAN':
            child('clean',['android_smoke.py','--apk',str(args.apk),'--output',str(out/'clean'),*release])
            uninstall();report['clean_uninstall']='PASS_PACKAGE_AND_DATA_ABSENT'
        elif args.gate=='LOAD':
            install_baseline(args.apk,'candidate')
            child('load',['android_load.py','--apk',str(args.apk),'--output',str(out/'load'),*release])
        else:
            assert args.release
            bouncy_control(Path('dist/MochiArcade-predecessor.apk'),'public-1.1.0')
            uninstall()
            bouncy_control(args.apk,'candidate')
            child('diagnostic-load',['android_load.py','--apk',str(args.apk),'--output',str(out/'load'),'--release'])
        report['status']='PASS_AUTOMATION_AWAITING_VISUAL_REVIEW'
    except Exception as error:
        report['error']=str(error)
        report['diagnostics']=diagnose(out/'gate-failure')
    finally:
        if stream is not None:
            stream.terminate()
            try:stream.wait(timeout=10)
            except subprocess.TimeoutExpired:stream.kill();stream.wait(timeout=10)
        if stream_file is not None:stream_file.close()
        (out/'gate-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(json.dumps(report,indent=2))
    return 0 if report['status'].startswith('PASS') else 1


if __name__=='__main__':raise SystemExit(main())
