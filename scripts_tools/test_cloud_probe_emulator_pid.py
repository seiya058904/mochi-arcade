import unittest
from cloud_probe_emulator_pid import is_owned_qemu


class CloudProbeOwnershipTest(unittest.TestCase):
    def test_only_exact_avd_and_qemu_match(self):
        self.assertTrue(is_owned_qemu([b'/sdk/qemu-system-x86_64', b'-avd', b'Mochi_CI_API34']))
        self.assertFalse(is_owned_qemu([b'/sdk/qemu-system-x86_64', b'-avd', b'Mochi_CI_API34-other']))
        self.assertFalse(is_owned_qemu([b'/bin/unrelated', b'-avd', b'Mochi_CI_API34']))
        self.assertFalse(is_owned_qemu([b'/sdk/qemu-system-x86_64', b'-avd']))


if __name__ == '__main__':
    unittest.main()
