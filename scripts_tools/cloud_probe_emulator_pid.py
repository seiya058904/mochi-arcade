"""Identify only the current isolated AVD's emulator for existing cleanup."""
from pathlib import Path
from android_evidence import AdbEvidence, require_owned

def is_owned_qemu(args):
    if not args or not Path(args[0].decode(errors='replace')).name.startswith('qemu-system-'):
        return False
    return any(args[i:i + 2] == [b'-avd', b'Mochi_CI_API34'] for i in range(len(args) - 1))


def main():
    out = Path('.local/android-runtime')
    adb = AdbEvidence(out / 'ownership')
    require_owned(adb)
    matches = []
    for path in Path('/proc').glob('[0-9]*/cmdline'):
        try:
            args = path.read_bytes().split(b'\0')
        except OSError:
            continue
        if is_owned_qemu(args):
            matches.append(int(path.parent.name))
    assert len(matches) == 1, f'Expected exactly one owned AVD process, found {len(matches)}'
    (out / 'emulator.pid').write_text(str(matches[0]) + '\n', encoding='ascii')
    print('Identified isolated AVD emulator process:', matches[0])


if __name__ == '__main__':
    main()
