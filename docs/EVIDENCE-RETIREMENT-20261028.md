# One-time evidence cleanup — 2026-10-28

The owner explicitly requested removal of unnecessary historical validation logs,
screenshots and evidence. The selected `.local/` and `docs/evidence/` files were
sent to the Windows Recycle Bin with per-file SHA-256 verification. Ten screenshots
used by the current README were retained byte-for-byte. Source, production assets,
APK files, signing material and toolchain files were preserved.

This is a one-time cleanup, not a 48-hour retention policy for Mochi Arcade.
The dashboard repository alone has that ongoing policy. Previously tracked raw
evidence remains available in Git at `5cc3141e3aefaed58fd94f820d1693be572b57d1`;
existing reports describe historical tests, not tests rerun during this cleanup.
No release, tag, remote history or published asset was changed.

The existing runtime and signing limitations still apply. No gameplay or Android
test was run for this evidence-only change. Future validation should generate new
evidence instead of relying on removed working-tree artifacts.
