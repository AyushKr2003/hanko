# Koyomi 暦 · the Time sheet as an almanac, in every hand

Asked for: "redesign the time sheet in all styles … to show all the dates in a month like we have in Shōji … selectable, the current one or the new one … deep research from Ghost of Tsushima, Ghost of Yōtei, Assassin's Creed Shadows, Sekiro … with all months and the Japanese seasons, and if possible the weather", and "every scroll should feel fresh … not AI slop".

Before this, only the Shōji hand showed a whole month; the other six showed a week and the day's rulers. Now every hand draws the month as an almanac (koyomi 暦): six weeks, the solar terms and microseasons, the moon, the forecast, the twelve months with their old names, and a leaf for the picked day. Each hand draws it in its own craft and turns the month its own way. The old sheets stay one setting away (`calendar: week`).

Written 2026-10-23, built the same day (Koyomi 1–3 on `dev`).

---

## 0. The pictures

| | |
|---|---|
| [Ledger and Tanzaku](images/01-ledger-tanzaku.webp) | The printed almanac page; the pillar calendar of slips |
| [Shōgi and Soroban](images/02-shogi-soroban.webp) | The month as the board; the date set on the rods and the month as a tray of beads |
| [Odoshi and Kasumi](images/03-odoshi-kasumi.webp) | The month as a suit of armour; gold leaf laid along mist bands |
| [Shōji](images/04-shoji.webp) | The month behind a kumiko lattice, this month and the next |
| [Light paper, other months](images/05-light-other-months.webp) | August 40 days back, December, January 2027; weather off |

The month turning, frame by frame (45 ms apart, motion on, from `tests/harness/turn.py`): [Ledger](images/turn-1-ledger.webp) · [Tanzaku](images/turn-2-tanzaku.webp) · [Shōgi](images/turn-3-shogi.webp) · [Soroban](images/turn-4-soroban.webp) · [Odoshi](images/turn-5-odoshi.webp) · [Kasumi](images/turn-6-kasumi.webp) · [Shōji](images/turn-7-shoji.webp).

---

## 1. What the research found

This builds on the study already done for Kaze ([../kaze/README.md §1](../kaze/README.md#1-what-the-research-found)), which covered how these games make stillness then exact action, and a world that tells you things without boxes. This round asked a narrower question: **how do these games show time, season and weather?**

### 1.1 The season as a dial you read at a glance (Assassin's Creed Shadows)

Shadows has four real seasons that change the world (frozen ponds, tall grass to hide in, snow that shows footprints). The interface for them is small: on the map, a **compass ring fills as the season runs**, with marks at the half and at the change, and the season's symbol in the middle; when the ring is full you may hold "Change season" and a short cinematic turns the landscape. Players read it as "how far through the season am I", not as a date.

**Taken:** the season as a ring that fills, read at a glance, with the year's quarters marked. **Made our own:** the ring is the whole year of 72 kō starting at 立春, the 24 terms as ticks, the four seasons as hairline arcs parted at each 立, today a red notch (red means now) and the picked day an ink one (the Ledger's dial, `bar/parts/SeasonDial.qml`). Shōji uses its own ensō instead, closing as the season goes. **Refused:** a button to change the season; the sheet tells time, it doesn't set it.

### 1.2 Nature as the instrument (Ghost of Tsushima, Ghost of Yōtei)

Tsushima's Guiding Wind replaced the minimap; leaves and grass point the way, and the sound designers ran three splines toward the objective so you could hear it. Its menus are "minimal and unobtrusive" (UI artist Mike Ackerman); its icons are drawn after kamon, family crests, because their flat symmetric shapes read at small sizes; menu art was concept art with its values crushed to high-contrast black and white. Yōtei's art director Joanna Wang: the world is built in layers, terrain then foliage, and sound and haptics read the same data; "the wind, the trees and the light were the interface"; fireflies and flowers mark good paths. Yōtei's map is Atsu's own, its icons hand-drawn, its fog lifting as you travel.

**Taken:** one shared state drives everything, the way Yōtei's layers do: the same forecast puts weather on the days, words in the leaf and, in Tanzaku, a stir in the slips when the wind is up. Marks are single kanji you can read at 10 px, like kamon: 晴 曇 雨 雪 霧 雷 for the sky, the term's own name for a term. **Refused:** weather icons (suns, clouds, raindrops). A Japanese forecast prints one kanji; so do we.

### 1.3 Ceremony in a single written mark (Sekiro)

Sekiro writes its moments as kanji: 危 flashes red before an attack you must not block, 死 is brushed across the screen at death, 忍殺 at a deathblow, 回生 at resurrection. The mark is the event, not a label for it.

**Taken:** the solar term is written on the day it begins, as the thing itself (霜降 on 23 October), not a dot with a legend; in Shōgi it is a piece named for the term, written down it as two-character pieces (飛車, 角行) are. Today in Shōgi is the king, 玉, written red: you. **Refused:** a red that means anything but now or you (Hanko's rule 2), so terms and moons are always in ink.

### 1.4 The almanac itself (koyomi 暦)

Japanese calendars still print, beside the numbered month, its old name (wafū getsumei 和風月名: 睦月 Mutsuki, 如月 Kisaragi … 神無月 Kannazuki "the month without gods" … 師走 Shiwasu "the month the teachers run"), the 24 solar terms (sekki, about fifteen days each) and, on almanac calendars, the 72 microseasons (kō, about five days each, renamed for Japan by Shibukawa Shunkai in 1685), the moon's phase by its old names (三日月, 十三夜, 十六夜, 有明月), and the weekday in kanji. The pillar calendar (hashira-goyomi 柱暦) of Edo houses hung the year as tall narrow strips.

**Taken:** all of it, computed rather than tabled. The terms and kō come from the sun's ecliptic longitude (`core/Season.js`), so they land on the right day in any year (2026: 寒露 8 October, 霜降 23 October, 立冬 7 November); the moon from the mean synodic month (`core/Almanac.js`, within half a day). The pillar calendar became the Tanzaku hand. **Left out:** rokuyō (大安, 仏滅 …): it needs the old lunisolar month, and a wrong lucky day is worse than none.

### 1.5 Motion that is fresh every time

The motion research is the Kaze study's ([§3, Iai](../kaze/README.md#3-motion-iai-居合-draw-cut-shake-off-sheath)): a held beat, a fast travel, a dead stop, no bounce. What was new here is the user's ask that "every scroll should feel fresh". Two things from the interface-motion literature mattered:

- **Motion should start from what is on screen and say where it came from.** A turn knows its direction (on, or back), and every hand enters from that side.
- **Frequent actions must stay cheap.** The month is turned dozens of times in a session; each turn is under 0.7 s, the wheel turns a notch at a time (touchpad deltas added up to 120), and the clock's minute ticks never animate anything.

The freshness comes from each hand's turn being its own craft's gesture, not one transition reused seven times (§3).

Sources: [Android Central, Tsushima's director on the wind](https://www.androidcentral.com/ghost-tsushima-creative-director-interview) · [GameSpot, Tsushima's sound team](https://www.gamespot.com/articles/ghost-of-tsushima-sound-team-breaks-down-the-games/1100-6480186/) · [Mike Ackerman, Tsushima UI](https://mikeackerman.art/project/ghost-of-tsushima-ui) · [PlayStation Blog, Tsushima concept art](https://blog.playstation.com/2020/10/26/from-brush-to-blade-the-concept-art-process-behind-ghost-of-tsushima/) · [Postmode, Yōtei art director Joanna Wang](https://postmode.substack.com/p/ghost-of-yotei-art-director-interview) · [Press Start, Yōtei interview](https://press-start.com.au/features/2025/10/02/ghost-of-yotei-interview/) · [PlayStation Blog, Yōtei's hand-drawn map icons](https://blog.playstation.com/?p=407612) · [Ubisoft, changing seasons in Shadows](https://www.ubisoft.com/en-us/help/assassins-creed-shadows/gameplay/article/changing-seasons-in-assassin-s-creed-shadows/000111339) · [PC Gamer, Shadows' season compass](https://www.pcgamer.com/games/assassins-creed/ac-shadows-change-seasons/) · [TechRadar, Shadows' seasons and gameplay](https://www.techradar.com/gaming/consoles-pc/assassins-creed-shadows-open-world-will-feature-seasons-that-impact-combat-and-traversal) · [Game UI Database, Sekiro](https://www.gameuidatabase.com/gameData.php?id=39) · [nippon.com, Japan's 72 microseasons](https://www.nippon.com/en/features/h00124/) · [Tokyo Weekender, the 72 microseasons](https://www.tokyoweekender.com/japan-life/news-and-opinion/the-poetry-and-precision-of-japans-72-microseasons/) · [Open-Meteo forecast API](https://open-meteo.com/en/docs).

---

## 2. One model, seven hands

`core/Koyomi.js` (pure, tested) builds what every hand draws; `bar/sheets/KoyomiState.qml` holds it with the moves and the turn. Nothing in the model knows how a hand looks.

- **The month is always six weeks**, Monday first, the days of the months either side kept faint, so a turn never changes the sheet's height.
- **Each day:** its date (and in kanji, 二十三), weekday kanji, whether a kō or a solar term starts on it (the term's name), the new or full moon, the forecast if there is one, how far it is from today.
- **The year:** twelve months, each with its numbered kanji, old name, season and the terms that start in it.
- **The leaf** for the picked day: its date in words, "Today"/"In 28 days"; its season, term and kō with how far through each it is (day 14 of 15); the next term and how soon; the moon (age, old name, how much lit); the sky (today: the weather now with wind; ahead: the day's forecast).

| Hand | The month is… | Today | The picked day | The rest |
|---|---|---|---|---|
| **Ledger 帳** | a ruled table, the editorial page | a bone plate with the red notch | an ink frame that slides | the year's dial, the leaf, the twelve months as columns with their seasons ruled under them, Elsewhen |
| **Tanzaku 短冊** | a pillar calendar: a slip a day on one rail, right to left, the date written down it in kanji; a term's day hangs longer with the term below | inked and sealed | pulled down 16 px, as you'd pull a slip | the lead slip at the right end holds the picked day; the twelve months on their own rail, the season's months hanging longer |
| **Shōgi 将棋** | the board: weekdays as files, weeks as ranks (一 to 六) | the king 玉, red | a frame that slides square to square | the season and its six terms as short ranks with a piece where we are; the week ahead waits on the piece stand as its weather |
| **Soroban 算盤** | a tray of six wires, a bead a day in its weekday's place: counted (filled) when gone | a red bead | ringed | the date set on the rods (2026 · 10 · 23, the day red); the year, the season's terms and the term's kō as wires counted as far as we are |
| **Odoshi 縅** | a suit of armour: a lame of scales a week, a run a day, laced for the days gone | knotted red | framed | the crown plate holds the picked day; the year and the season's terms as short laced lames |
| **Kasumi 霞** | mist bands, a week each, gold leaf laid as far as the days have gone | sealed where the gold stops | underlined | the month's old name as the title slip; the year as twelve slips of mist |
| **Shōji 障子** | panes behind a kumiko lattice, on washi | an ensō | a brush stroke under it | the season as an ensō that closes as it goes; the kō written down the page; the year as twelve panes |

Every hand: terms in ink, moons as `bar/parts/MoonMark.qml` (the lit part in the lighter tone of whatever it sits on, so dark paper shows a bright full moon, and light paper shows ○ full and ● new as a printed calendar does), weather as one kanji and the high.

---

## 3. Turning the month, seven ways

A turn is the wheel (a notch is a month), `[` `]` or Page Up/Down (Shift or `{` `}`: a year), the foot's ‹ Month / Month ›, or a click on a month of the year. It knows its direction and each hand enters from that side. Only a real turn animates; the model is rebuilt every minute with the clock and that moves nothing. `motion: still` (and the system's reduce-motion) cuts each to its end frame.

| Hand | The gesture | Timing |
|---|---|---|
| Ledger | The compositor's galley: the weeks set in line by line, 14 px from the side the month came from | after the draw's held beat, 38 ms a line, Iai's draw curve |
| Tanzaku | Hanging the slips one after another in reading order, each dropping 18 px onto its cord | 16 ms a slip; the wind's sway after |
| Shōgi | Setting up the board: the pieces put down one by one, from 8 px above | 9 ms a square, after the held beat |
| Soroban | Gohasan 御破算, clearing the abacus: every bead swept to the wire's far end, then flicked back to its day in turn | 170 ms a flick, OutQuart, 11 ms apart |
| Odoshi | The plates of a suit falling into place as it is lifted on: the lames settle top to bottom, 12 px | 46 ms a lame |
| Kasumi | The mist moving: bands drift in 46 px from alternate sides, slower than any other hand | 560 ms + 50 ms a band, the unroll curve |
| Shōji | A door on its rail: the month slides behind the lattice, which stays | the skin's own open time and curve |

The picked day's mark (frame, ring, underline, brush) slides between days as the cursor does, and jumps during a turn.

**The wind (Tanzaku):** when the forecast has a wind, the slips stir on their cords, each a little out of step with the next, up to 1.4° at 25 km/h. No wind, no forecast or motion still: they hang straight.

### Fitting the screen

The almanac is the same height on every day and every month, in every hand: every line of text has a fixed number of lines (cut short with … rather than wrapped onto another), an empty sky keeps its room, and Elsewhen is a grid of cells, up to five across (`bar/sheets/KoyomiZones.qml`), not a line per city. `SheetWindow` hands each sheet the room it has (`feed.room`: the screen less the bar, Shōji's rail gap and the crop marks); `KoyomiState.fit()` shortens the week rows until the sheet fits, and on a screen too short even then turns `compact` on: the year is left out, Elsewhen kept to one row (the rest counted, "+2 more"), Shōgi's stand and terms' rank put away. Every part that moves on a turn is clipped to its own box, and a slip's paper clips what is written on it; the lead slip sets a long date (二十六日) smaller so it never runs into the term. `tests/koyomi.py` (run by `tests/run`) opens every hand on a day in every third kō and on months back and on, with 0, 5 and 7 cities, on 1080, 768 and 640 px screens, and fails on a sheet taller than its room, one whose height changes, or a part past its edges or cut off by its box (`--all` for every kō).

---

## 4. Weather

`services/Sky.qml` asks Open-Meteo for the weather now and sixteen days ahead (`current` and `daily` in one request, `timezone=auto`), at the place Omarchy's own weather panel has: `~/.local/state/omarchy/settings/weather.json`. Coordinates are used as they are; a name alone is found with Open-Meteo's geocoder; nothing at all, from the IP address through wttr.in, as Omarchy does. It asks only while the Time sheet is open as an almanac (and every half hour while it stays open), never while `weather: off`; the last answer is kept in `~/.local/state/hanko/sky.json` so a sheet opened offline still has a forecast. Fahrenheit where Omarchy's panel would use it (the place's country, else the locale).

WMO codes → 晴 clear/fair, 曇 partly cloudy/overcast, 霧 fog, 雨 drizzle/rain/showers, 雪 snow, 雷 thunder.

---

## 5. Settings and keys

Two settings beside the touches (like `hours` and `season`: global, kept by presets, resets and shuffles), on Settings › Sheets under Panel opacity:

- `calendar`: **`koyomi`** (the almanac, default) or `week` (the sheets as they were). `hanko style set calendar week`.
- `weather`: **`on`** or `off`. `hanko style set weather off`.

Keys on the almanac, beside Te's cursor (arrows walk the days, Enter picks one): Page Up/Down or `[` `]` a month, with Shift or `{` `}` a year, T or Home back to today. The wheel turns a month; a click picks a day or a month.

---

## 6. What we refused

- Weather icons, coloured season tints, a moon emoji. One kanji, one ink.
- Red for anything but now or you: terms, full moons and weekends stay ink.
- A transition shared by all seven hands. Each turn is its own craft's gesture.
- Springs and bounces on the turn (Kaze's rule): a held beat, a fast travel, a dead stop. Only the slips' sway is continuous, because it is the wind.
- Rokuyō and other values we can't compute exactly.
- A sheet that grows and shrinks as you turn it: always six weeks.

---

## 7. Code map

| File | What |
|---|---|
| `core/Koyomi.js` | the model: weeks, year, leaf, sheet, moves (`step`, `toMonth`), the weather (`url`, `forecast`, `sky`, `wind`, `geocode*`, `imperial`); 4 unit tests |
| `bar/sheets/KoyomiState.qml` | the model as state: moves, the wheel, keys, the turn (`dir`, `entering`, `turned`), the sky in words |
| `bar/sheets/{Ledger,Tanzaku,Shogi,Soroban,Odoshi,Kasumi,Shoji}Koyomi.qml` | the seven hands |
| `bar/parts/SeasonDial.qml`, `bar/parts/MoonMark.qml` | the year's dial; the moon on any paper |
| `bar/sheets/Bead.qml` | the abacus bead, shared with `SorobanHand` |
| `bar/sheets/Koma.qml` | a piece may carry a two-kanji name |
| `services/Sky.qml` | the forecast |
| `bar/sheets/SheetView.qml`, `ShojiPanel.qml` | choose the almanac when `calendar: koyomi` (660 px wide) |
| `Bar.qml` | `timePick` (days from today), the `pick` request, Sky's bindings |
| `tests/harness/params/koyomi-*.json` | renders: every hand, other months, light paper, weather off |
| `tests/harness/turn.py`, `scenes/KoyomiTurn.qml` | the turn frame by frame |
