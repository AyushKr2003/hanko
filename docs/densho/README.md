# Densho 伝書 · the handscroll, redrawn

A design proposal for `panels: scroll`, asked for after the scroll was judged
"not looking good". Nothing here is built yet; pick, cut or change any of it
first.

| Sheet | What it shows |
|---|---|
| [01 · The scroll](images/01-scroll.webp) | The whole scroll on the desk: spines instead of sliced neighbours, rollers that count sections, kasumi mist bands. |
| [02 · Nagare 流](images/02-motion.webp) | How it moves: ink that thins at speed, a landing that keeps your speed, two-finger panning, the seal press. |
| [03 · Fude-iri 筆入](images/03-brush.webp) | How a section arrives: a dry brush writes the title on, tied to scroll position, not a timer. |
| [04 · Kaze-michi 風道](images/04-wind.webp) | The wind shows the way: a gust of ink fibres toward whatever needs you, in place of the index plate. |
| [05 · Aburidashi 炙出](images/05-secrets.webp) | Letters in secret ink that read when warmed by the pointer; a red seam across a section at fault. |
| [06 · Mokuroku 目録](images/06-mokuroku.webp) | The scroll in a licence scroll's order (house, techniques, seal), Iai opening, jumps as a stance, roll-up seals it. |

Research behind it: Ryoku's grammar as everywhere in Hanko; emakimono reading
and kasumi; mokuroku licence scrolls and ninja aburidashi; the ideas (not the
look) of Ghost of Tsushima and Ghost of Yōtei: wind instead of HUD, the brush,
a mend that shows; and interruptible, velocity-carrying motion.

`source/` draws the sheets on the Kaze kit (`../kaze/source/kaze.css`,
`kaze.js`); `source/shoot.sh` renders them with headless Chromium.
