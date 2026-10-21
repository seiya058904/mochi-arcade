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
