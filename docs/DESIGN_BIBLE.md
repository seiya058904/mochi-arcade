# Art direction — cream stationery

Two actual generated concepts were compared: warm gouache stationery and a
luminous jelly garden. The first was selected for its warmth, stronger objects
and reusable silhouettes. Dense floral scenery, castles and ornamental frames
were rejected to keep controls and landing targets readable.

## Tokens

| Token | Hex | Purpose |
| --- | --- | --- |
| Cream | #FCF7EE | Quiet paper background |
| Paper | #FFFDF8 | Controls, dialogs and light tiles |
| Cocoa | #634B40 | Primary text and outlines |
| Muted | #6E564A | Secondary captions |
| Peach | #F6D4C5 | Fruit Drop / Jelly Slice |
| Sky | #D7E9EF | Bubble Garden |
| Rose | #F0CBD0 | Cake Stack |
| Yolk | #F8E5B3 | Bouncy Balls |
| Pistachio | #DBE8CB | Tile Trio / Number Bloom |
| Lilac | #E5DCF0 | Mochi Hop |

- Nunito 650/850; Noto Sans SC 550/750 fallbacks. Variable font axes use actual
  OpenType integer tags (string dictionary keys silently left thin defaults).
- Design canvas 720x1280 with expansion; inset Android safe areas.
- 20/24/30/36 logical-pixel spacing; rounded panels, restrained warm shadows.
- Primary controls 76-88 logical pixels high; 2-column home, four card rows.
- Cream mochi bunny with cocoa linework, peach cheeks, pastel macarons.
- Generated card icons use individually inspected AtlasTexture bounds; generated
  rows are not assumed to be a perfect mathematical grid.
- Reusable original vector cake layers use icing drips, cream filling, crumb
  specks and offcut animation. Number tiles prioritize readable live numerals.
- Short 150 ms transitions, opt-in motion reduction; effects have an independent
  RNG so cosmetic settings never change rule randomness.
- Original synthesized glass/wood tones and a quiet pentatonic loop. No samples.

## First runtime review

Actual 450x800, 360x640 and 360x800 viewport captures reviewed. Fixed thin Latin
and Chinese variable fonts, clipped bunny sprite, and long dialog text sizing.
The complete 34-screen matrix now covers all eight games, three portrait ratios,
both languages, overlays, settings and offline licenses. Tall home cards fill the
available area; the wide 2048 board fits its footer. v1.0.0 Android layout and
expanded touch regions were reviewed on the 720x1280/320dpi API 34 hardware-GPU
AVD (see android-api34-final-splash-2026-10-22 evidence). Other cutouts, densities
and physical-phone geometry remain UNVERIFIED; that review does not certify a
new build automatically.

For v1.1.0, a separate 64-capture three-ratio EN/ZH desktop matrix and exact
signed API 34 software-emulator lifecycle/upgrade/load captures were reviewed.
Native startup video confirms the original boot artwork. See ITERATION_1.1.md;
other physical cutouts/densities and phone measurements remain unverified.
