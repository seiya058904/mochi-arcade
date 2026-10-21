# Decisions

1. **User naming wins:** Mochi Arcade, private `seiya058904/mochi-arcade`,
   `MochiArcade.apk`; no inherited Mellow Pocket branding in shipped product.
2. **Roster locked:** G06 Mochi Hop; no Color Maze and no ninth game.
3. **Single engine:** Godot 4.7.2 stable, GDScript, pure 2D Compatibility rendering.
4. **Portrait / offline:** 720x1280 reference, canvas_items + expand, responsive
   safe area layout; no accounts, ads, purchases, network dependency or WebView.
5. **Incremental integration:** stable shared shell, then Cake Stack + Number
   Bloom, followed by one fully tested game at a time.
6. **Android early:** reuse the existing isolated Android 34 AVD with no change
   to other projects; test x86_64 emulator and ship arm64 + x86_64 if size permits.
7. **Secrets:** release key outside repository; DPAPI or equivalent OS protection
   for password. Never put credentials in source, logs, CI or release assets.
8. **Truthful release:** desktop proof never substitutes for Android gestures;
   emulator results never claim physical-device performance.
