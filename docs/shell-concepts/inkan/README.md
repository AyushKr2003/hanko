# Inkan 印 · the seal only

Shell concept 04 (`../images/inkan.webp`), drawn out in full before it is built. Asked for: "now I want to work on this Inkan … tell me the full plan", then "go with your idea and all".

Inkan is not a new design. It is a **form** of the Hanko bar: `form: inkan` takes the strip away and leaves one seal in a corner. Every style, sheet, hand and service stays; a preset, **Inkan 印**, is Kamon with `form: inkan`.

| Sheet | What it settles |
|---|---|
| `images/01-states.webp` | The seal at rest and what its carving reads: wear for the battery, chips for letters, an outline for do not disturb, a broken inner rule for offline; the hover reading |
| `images/02-no00.webp` | No. 00, the sheet the press prints: clock, workspaces with the active window, now playing, a row per sheet; a row opened (05 Power) with its `‹ NO. 00` crumb |
| `images/03-corners.webp` | `inkanAt` in the four corners, the sheet printing away from the shared edge; `form` per monitor |
| `images/04-press.webp` | The ink-press: hover, press, bloom, print, open, lift-off, with timings |
| `images/05-light.webp` | The same on a light theme |

What was built, from the harness (`tests/harness/params/inkan*.json`, scene `Inkan.qml`): `images/10-built-dark.webp` and `11-built-light.webp` (every state, the hover reading, No. 00 and a sheet opened from it in two corners), `12-presets.webp` (the Inkan card on Settings › Presets).

## The rules it keeps

- **Colour:** the plate is the theme's red, the carving its paper, the outline its ink. Wear is drawn as specks of the plate's own red over the carving, so it reads on any theme and needs no mask.
- **Red is you or now:** the seal is red already; what needs you turns red in the hover reading and on No. 00, as on the bar.
- **Hairlines, not shadows** on the seal; No. 00 is a sheet and keeps the sheets' shadow (Revision 2).

## The states (core/Inkan.js)

- **Wear** = the battery: `wear(pct, charging, present)` is 1 at 60 % and above, while charging and with no battery; below 60 % it falls to 0.3 at 0 %, which still leaves the glyph legible. `specks(seed)` are seeded clusters of blots, each with a threshold; a speck is drawn when its threshold is under `1 − wear`, so the carving wears away in the same places every time.
- **Chips** = letters: one corner (top right) for one or two, a second (bottom left) for three or more; deeper (34 % of the side, not 22 %) when one is urgent; none under do not disturb.
- **Do not disturb:** the seal rests as an outline in ink. **Offline:** the inner rule breaks along the foot.
- **The glyph:** `sealGlyph`, or the active workspace numeral under `seal: workspace`; `seal: carved` rests as the outline and presses red when letters wait. `seal: none` still draws the stamp (it is the only thing on screen).

## Hands on it

Click prints No. 00 (or, under `panels: scroll`, unrolls the scroll from the seal's edge). Right-click: Omarchy's menu. Middle: a terminal. Wheel: step workspaces. Hover: one line of reading toward the screen. Drag: follows the pointer and snaps to the nearest corner, saved for that monitor. While the screen is recorded or dictation runs, a thin red ring breathes around the seal. `omarchy-shell hanko press` does what a click does, for a keybinding.

## Source

`source/kit.html` draws the five sheets (`kit.html?c=1` … `c=5`) with the fonts from `assets/fonts/`. Rendered with headless Chromium at 2x, then cropped to the content:

```sh
chromium --headless=new --allow-file-access-from-files --hide-scrollbars --force-device-scale-factor=2 \
  --virtual-time-budget=3000 --window-size=2048,2600 --screenshot=out.png "file://$PWD/kit.html?c=1"
```
