# Mochi Arcade — product contract

Eight original, instantly available offline games in one portrait Android app.
Play sessions last two to five minutes, with immediate retry, no accounts,
advertisements, purchases, stamina systems or remote services.

The roster is Fruit Drop, Bubble Garden, Cake Stack, Bouncy Balls (paddle version),
Tile Trio, Mochi Hop (hold/release), Number Bloom (standard 2048) and Jelly Slice
(default endless Zen mode). Full gameplay acceptance remains in SOURCE_TASK.md.

Home has eight illustrated cards. Every scene shares a back/pause header,
record/score summary, help, retry/undo, result dialog and local settings.
Game rules live in individual scenes and do not depend on another game's state.

## Released product and current iteration

All eight games have executable rules, integration tests, real rendered screenshots
and playable input paths. v1.0.0 was publicly released on 2026-10-22 after signed
hardware-GPU API 34 emulator acceptance and the explicitly scoped hosted llvmpipe
A14 exception. Physical-phone quantitative performance remains UNVERIFIED.
The 1.1.0 source iteration adds save-failure feedback/recovery, terminal Number
Bloom Undo and fewer idle canvas rebuilds. Its own signed-byte Android upgrade
and runtime gates must pass before a new stable release; old acceptance is not
new-version evidence. See ITERATION_1.1.md and RELEASE_CHECKLIST.md.

## Non-negotiable proof

Headless rules, real Godot rendering, native desktop input, Android system input,
physical-device performance and release publication are distinct evidence types.
No Android touch evidence means no stable Release, regardless of desktop quality.
