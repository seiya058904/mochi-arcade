# Asset provenance

Created for this project with built-in **image_gen** (not the API/CLI fallback).
The tool did not identify its model version. Exact prompts are retained in
`assets/source/prompts.json`. No external game image was supplied or traced.

| Asset | Source and decision | Processing / actual use |
| --- | --- | --- |
| concept-stationery.png | image_gen, 2026-10-21; selected direction | Concept only; excluded from APK |
| concept-garden.png | image_gen, 2026-10-21; rejected dense scenery | Concept only; excluded from APK |
| game-icons.png | image_gen original eight-object atlas | 1774x887 RGBA; alpha 0-255; transparent corner. Individual runtime atlas regions inspected and corrected. Used on all eight home cards. |
| mochi-bunny.png | image_gen original bunny/macaron | 1536x1024 RGBA; alpha 0-254; transparent corner. Original alpha retained. Used on home and Cake Stack. |
| fruit-characters.png | image_gen original eight-fruit atlas, 2026-10-22 | 1774x887 RGBA; alpha 0-255. Inspected individual bounds, runtime cropping only, foliage above circular body. Used by real RigidBody2D fruit. Prompt: assets/source/fruit-prompt.json. |
| bubble-characters.png | image_gen original five-symbol bubble atlas, 2026-10-22 | 1983x793 RGBA; alpha 0-255. Inspected square regions, mipmapped downsampling for small in-game circles. Symbols distinguish colors. Prompt: assets/source/bubble-prompt.json. |
| hop-bunny.png | image_gen original vanilla mochi bunny, 2026-10-22 | 1211x1299 RGBA. Inspected trimmed atlas region and ground contact. Runtime squish/stretch preserves the foot anchor. Prompt: assets/source/hop-prompts.json. |
| hop-platforms.png | image_gen four original sweet platforms, 2026-10-22 | 2172x724 RGBA. Individually bounded round platforms with a consistent top ellipse and short front wall. Mipmapped runtime atlas; top center agrees with projected landing coordinates. |
| trio-icons.png | image_gen eight original matching motifs, 2026-10-22 | 1774x887 RGBA; alpha 0-255. Individual bounds preserve yarn tail and butterfly wings. Distinct motifs appear on actual layered tiles and seven-slot tray; mipmapped. Prompt: assets/source/trio-prompt.json. |
| app-icon.svg / icon-background.svg | Original project vector illustration | Editable geometric bunny icon; no third-party tracing |
| Cake layers / UI / particle shapes | Original GDScript vector drawing | Resolution-independent game geometry and decoration |
| BGM / SFX | Original code synthesis in audio_manager.gd | No third-party samples; one music voice and eight pooled SFX voices |
| Nunito.ttf | google/fonts, ofl/nunito/Nunito[wght].ttf | SIL Open Font License; adjacent Nunito-OFL.txt preserved |
| NotoSansSC.ttf | google/fonts, ofl/notosanssc/NotoSansSC[wght].ttf | SIL Open Font License; adjacent NotoSansSC-OFL.txt preserved |

Font upstreams:
https://github.com/google/fonts/tree/main/ofl/nunito
https://github.com/google/fonts/tree/main/ofl/notosanssc

Generated assets are original project outputs, not a claim of exclusive rights
or a legal trademark clearance. No commercial game logos, sprites, music or
levels have been imported. Further gameplay sprites will be recorded as made.
