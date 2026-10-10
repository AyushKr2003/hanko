# The right side · four studies

Asked for: "the right side looks too cramped … research, game principles, articles and papers, and come up with a better design with a Japanese touch; show me the design in images first". Then: "I like them all, add all".

The left and centre of the bar breathe; the right zone was five identical label-over-value cells, each carrying a mono label, a kanji, a value and its own ten-tick meter, then the indicator stamps with their names and the inbox: about thirty marks for five facts, all at one weight (`images/00-diagnosis.webp`). Each study below cures that a different way, from mild to radical. All four are values of `status` and presets built on the Hanko bar.

| Sheet | Study | `status` | Preset | Idea | Right zone |
|---|---|---|---|---|---|
| `01-ma.webp` | 間 Ma | `ma` | Ma | Three groups held apart by space (links, levels, marks); the kanji is the label; a two-pixel fill under each level instead of ten ticks | ≈ 500 px (−41%) |
| `02-shizuka.webp` | 静 Shizuka | `shizuka` | Shizuka | Quiet until something changes: network and battery stay, Bluetooth, volume and brightness wait as faint kanji and unfold for two seconds when they move; alerts stay open in red | ≈ 345 px (−59%) |
| `03-suji.webp` | 筋 Suji | `suji` | Suji | A kanji and one short brush line each, its length the level, the range dotted; the figure on reach | ≈ 469 px (−45%) |
| `04-inro.webp` | 印籠 Inrō | `inro` | Inrō | One ruled case of compartments, kanji over value, like a scorecard; fixed width | ≈ 333 px (−61%) |

`05-side-by-side.webp` stacks them under today's bar. `10-built-dark.webp` and `11-built-light.webp` are the harness renders of what was built (`tests/harness/params/right-side*.json`).

## The research behind them

- **Tufte, data-ink and sparklines.** Erase ink that repeats data: a number and a ten-tick meter say the same thing twice. Sparklines are "small, intense, simple, word-sized graphics" with a data-ink ratio of 1, no frames or ticks, scaled by the words around them (Suji; Ma's fill). [Sparkline theory and practice](https://www.edwardtufte.com/notebook/sparkline-theory-and-practice-edward-tufte/), [Above all else show the data](https://medium.com/plotly/above-all-else-show-the-data-1b8bbf05c2ae).
- **Weiser and Brown, *Designing Calm Technology* (Xerox PARC, 1995).** Calm technology lives in the periphery and moves to the centre only when something is unusual: the engine noise you notice only when it changes (Shizuka). [calmtech.com](https://calmtech.com/papers/designing-calm-technology), [Calm technology](https://en.wikipedia.org/wiki/Calm_technology).
- **Game HUDs.** Fagerholt and Lorentzon's diegetic / non-diegetic / spatial / meta model; recent work on HUD minimalism finds games moving from persistent dense overlays to state-dependent, selectively surfaced ones, and players linking minimal HUDs with immersion and preferring them. "Show on change" vitals and Dynamic HUD mods do exactly what Shizuka does. [Toward Minimalist HUDs?](https://bonndoc.ulb.uni-bonn.de/xmlui/handle/20.500.11811/14207), [Game UI Discoveries](https://www.gamedeveloper.com/design/game-ui-discoveries-what-players-want), [Dynamic HUD](https://mods.factorio.com/mod/dynamic-hud).
- **Gestalt.** Proximity groups more strongly than lines do (Ma), and a common region more strongly than five dividers (Inrō). Instrument clusters in racing and flight HUDs gather gauges in one place for the same reason.
- **Ma 間 and kanso 簡素.** The pause between things gives them meaning; keep what is essential. Not "remove everything": reduce to the essential components. [Integrating Ma into UX](https://uxplanet.org/integrating-japanese-ma-into-modern-ux-principles-9b0646d5b756), [On Japanese Minimalism](https://contempaesthetics.org/2020/09/24/on-japanese-minimalism/), [A perspective on ma](https://japanhousela.com/articles/a-perspective-on-the-japanese-concept-of-ma).

## Source

`source/kit.html` draws the six study sheets (`kit.html?c=0` … `c=5`), with the fonts from `assets/fonts/`. Rendered with headless Chromium at 2x:

```sh
chromium --headless=new --allow-file-access-from-files --hide-scrollbars --force-device-scale-factor=2 \
  --window-size=2048,1100 --screenshot=out.png "file://$PWD/kit.html?c=1"
```
