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

## Current playable development scope

All eight games have executable rules, integration tests, real rendered screenshots
and playable input paths. Hosted Android development builds have completed all
eight touch/lifecycle paths. Intermittent surface recovery, performance acceptance
and final signed-byte Android verification remain release blockers; this is not
an accepted stable release.

## Non-negotiable proof

Headless rules, real Godot rendering, native desktop input, Android system input,
physical-device performance and release publication are distinct evidence types.
No Android touch evidence means no stable Release, regardless of desktop quality.
