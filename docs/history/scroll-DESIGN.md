# Hanko Scroll: a calm bar that unrolls into a handscroll

Scroll starts over. Nothing is carried from Sheet except the name.

## What I took from Ryoku, and what I left

**From Ryoku Settings:** paper and ink, emphasis by inversion (the selected thing becomes a solid plate), a serif kept for titles, tracked mono for labels, and a kanji beside every Latin word.

**From ryoku.dev:** numbered kanji sections (`源 00 // …`), art dithered down to the ink colours, a red sun as the only colour, and hover reveals ("dimmed at rest, full colour when you point").

**What I left out:** Ryoku's bars (QS Bar, Sumi, Kairos, Shima), its exact palette, its marble artwork, and its poster ornaments.

## The idea

Two moods, one object.

- **At rest, the bar is calm.** It shows a single line of type and almost nothing competes for attention. This follows calm-technology practice: information lives in the periphery and comes to the centre only when you ask for it.
- **When asked, it unrolls a handscroll.** An *emakimono* is read by unrolling it about an arm's length at a time and panning through it. Every panel lives on one continuous scroll that drops from the bar: Time, Sound, Network, Power, Spaces and Inbox. You pan between them; you don't open six separate popups.

## The bar (sheet 02)

| Piece | What is fresh about it |
|---|---|
| **Seal** 印 | The seal is the active workspace, shown as its kanji numeral (壱 弐 参 …). Click it for the Omarchy menu; scroll on it to walk workspaces. |
| **Layout glyphs** 窓 | Each workspace is drawn as its real tiling in hairlines. The live one is outlined and its focused window filled. Hovering opens the glyph to show window names. |
| **Byline** 題 | The app name is set in serif italic, like an author's byline. The title follows in grotesk and the path recedes. |
| **Clock** 時 | Serif numerals with a red colon and a small-caps date. |
| **Now playing** | The underline under the song title is the progress bar. |
| **Glyph status** 音 網 電 | Kanji are the icons and the number is the state. Hover adds the Latin word, scroll changes the value. A glyph turns solid red only when it needs you; one that is off is dashed. |
| **Stamps** 報 | Notifications land as small stamped seals, slightly askew, newest on top. Hover fans them out; click opens the Inbox. |
| **The rod** 軸 | The bar's bottom edge is the scroll's roller. Hover raises the grip. Pull it down, press Super+Space, or click any glyph to unroll. |

## The handscroll (sheets 03 and 04)

- It hangs from the bar between two **rollers**. Sections curl under the rollers at the edges, so you always see the neighbouring sections.
- An **index plate** sits at the top: `時 01 TIME · 音 02 SOUND …`, with the current section inverted. A position bar runs along the foot with key hints (`H` `L` to pan, `Esc` to roll up).
- Each section follows ryoku.dev's grammar: a red kanji, `02 // SOUND`, a serif title, a mono caption and a large faint kanji watermark.
- Between sections are narrow **interludes**: dithered ink-wash slivers, like the painted gaps on a scroll.
- **Fresh controls:**
  - Sound uses a fader bank (master in seal red, muted channels drawn dashed) instead of sliders.
  - Time uses a horizontal day ribbon instead of a month grid.
  - Spaces shows a map of every workspace's real layout; click a window to jump to it.
  - Inbox shows notifications as stamped letters.

## Motion (sheet 05)

The motion follows real paper, with no springs and no blobs. The rod drops and the paper follows it (300 ms). Ink fades in after the paper has moved (200 ms, delayed 120 ms). Panning carries momentum and always snaps to a section (260 ms). A new stamp is pressed down oversized and tilted, then settles (140 ms); this is the only overshoot anywhere. With reduced motion on, every transition cuts straight to its end frame.

## Colour (sheet 06)

Hanko reads Omarchy's `colors.toml`:

- **Paper** is the theme's `background`.
- **Ink** is the theme's `foreground`, stepped toward the paper to four fixed contrasts (12, 9, 6.2 and 4.6 : 1).
- **Seal** is the theme's `red`.

The wallpaper plate uses the same three inks, so switching theme reprints the whole desk. Light themes need no special case.

## Type

- **Fraunces** for the clock, titles and bylines.
- **Space Grotesk** for language and values.
- **Your Omarchy monospace** for labels and keys.
- **Noto Sans JP / Noto Serif JP** for the kanji.

## How it plugs into Omarchy

Hanko is one `bar`-kind plugin (`hanko.bar`), built the same way as Omacale: `manifest.json` plus `Bar.qml`, installed into `~/.config/omarchy/plugins/hanko.bar` and switched on with `omarchy bar use hanko.bar`.

- The handscroll is a layer-shell surface owned by the bar.
- Its data comes from Omarchy's own services: audio, network, battery, media, notifications, Hyprland and Elsewhen.
- Third-party bar widgets get a section of their own on the scroll.

## Mockups

| File | Shows |
|---|---|
| `../mockups/scroll/01-desktop.webp` | The bar at rest on the signature theme, with a dithered marble plate |
| `../mockups/scroll/02-bar.webp` | Each bar component at rest and when touched |
| `../mockups/scroll/03-scroll-sound.webp` | The handscroll on Sound, with Time and Network curling at the edges |
| `../mockups/scroll/04-scroll-spaces-light.webp` | Spaces and Inbox on Flexoki Light |
| `../mockups/scroll/05-motion.webp` | Unroll, pan and stamp storyboards with their curves |
| `../mockups/scroll/06-themes.webp` | Six Omarchy themes |

`../mockups/scroll/source/` holds the HTML. `emaki.html` takes `?theme=&focus=&h=&ink=&nudge=&closed=&stamp=` to pose any frame.

The wallpaper art is procedural and made for these mockups; it is not part of the plugin.
