# Kaze 風 · the whole desk, in the way of the sword

Hanko made the bar. Kaze carries the same paper, ink and seal into every part of the computer: lock, windows, wallpaper, launcher, notifications, on-screen displays, terminal, sound and shutdown. The feeling to aim for is the one that *Ghost of Tsushima*, *Ghost of Yōtei*, *Sekiro: Shadows Die Twice* and *Assassin's Creed Shadows* give: stillness, then a sudden, exact action; a world that tells you things without boxes on the screen; rare moments of ceremony.

This file is three things:

1. **What the research found** (§1): how those games build that feeling, with sources.
2. **The design** (§2–§6): principles, the motion grammar, every surface of the desktop and what it becomes, and the list of things we refuse to do.
3. **The roadmap** (§7–§9): phases in the usual Hanko order (mockups first, then one surface per phase), what Omarchy allows for each one, risks and open questions.

Research written 2026-10-14. The mockups for every surface (KZ1) are in [§0](#0-the-mockups); nothing is built in QML yet.

---

## Contents

0. [The mockups](#0-the-mockups)
1. [What the research found](#1-what-the-research-found)
2. [What it means for a desktop: the seven principles](#2-what-it-means-for-a-desktop-the-seven-principles)
3. [Motion: Iai 居合, draw, cut, shake off, sheath](#3-motion-iai-居合-draw-cut-shake-off-sheath)
4. [Every surface, one by one](#4-every-surface-one-by-one)
5. [Sound 音](#5-sound-音)
6. [What we refuse to do (the anti-slop list)](#6-what-we-refuse-to-do-the-anti-slop-list)
7. [How each surface plugs into Omarchy](#7-how-each-surface-plugs-into-omarchy)
8. [Roadmap](#8-roadmap)
9. [Risks, things to verify, open questions](#9-risks-things-to-verify-open-questions)
10. [Sources](#10-sources)

---

## 0. The mockups

Fourteen sheets, drawn with the kit in `source/` (tokens, the bar, grass from a wind value; `source/shoot.sh` renders them with headless Chromium) on the user's own prints, re-inked. Pick, cut or change any of them before KZ2 starts.

| # | Sheet | What it shows |
|---|---|---|
| 01 | [The desk 机](images/01-desk.webp) | One evening: the printed wave, the grass leaning toward a new letter, the focus sweep, the bar as it is. |
| 02 | [Iai 居合](images/02-iai.webp) | The five beats on a millisecond ruler, each with its curve and frames, and the spring Kaze never uses. |
| 03 | [Sumizuri 墨摺](images/03-sumizuri.webp) | Five prints, original / dark rubbing / light ink print, the rule for which tone becomes paper, the sky by the hour. |
| 04 | [Kaze 風](images/04-kaze.webp) | Grass in four real winds, a gust toward a letter, where the wind state comes from, the frame budget, the edge-only variant. |
| 05 | [Ha 刃](images/05-ha.webp) | Hairline windows, the focus sweep, open and close, red breathing, workspaces rolling, the Hyprland settings. |
| 06 | [Taikan 体幹](images/06-taikan.webp) | Volume and brightness filling from the centre, the posture break, muted, crests for switches, the pill it replaces. |
| 07 | [Fumi 文](images/07-fumi.webp) | Letters as hanging strips: arriving, several, one opened, urgent, cut away. |
| 08 | [Battō 抜刀](images/08-batto.webp) | The launcher drawn from a line, kinds as crests, the jumping selection, the system menu, Enter as the cut. |
| 09 | [Taiji 対峙](images/09-taiji.webp) | The lock: still, drawing, deflected, fingerprint, and the diagonal cut onto the desk. |
| 10 | [Shiki 式](images/10-shiki.webp) | 終 written and sealed, 危 as a band, the table of the five ceremonies. |
| 11 | [Sumi 墨](images/11-sumi.webp) | The screen in ink with only the theme's red kept, what changes together, riding mode. |
| 12 | [Dōgu 道具](images/12-dogu.webp) | Greeting, prompt states, btop in four inks, the palette, the brush-tip cursors. |
| 13 | [Oto 音](images/13-oto.webp) | The six sounds as waveforms, and an hour at the desk (1.4 s of sound in 3600). |
| 14 | [Daylight 昼](images/14-light-settings.webp) | The desk on a light theme, and Settings › Kaze with every switch. |

What the mockups settled that the text above didn't:

- **Which tone becomes paper.** The print's mean brightness decides: above 0.5 the dark theme prints the negative (a rubbing), below it keeps the tones; the light theme does the opposite. A painting with a mount (the haboku) is cut from it first. No red is ever printed (sheet 03).
- **The focus sweep needs a faint start.** Bone and ink are too close to see a highlight on an ink edge, so the new edge starts in faint ink, the light runs round, and the edge settles to full ink (sheet 05).
- **Grass is clumps, not a comb.** Evenly spaced blades read as a barcode. Clumps of 3–8 blades fanning from one root, gaps between clumps and a few pampas plumes read as a field (sheet 04).
- **Windows don't move when the bar recedes.** Riding mode leaves the print showing where the bar was instead of reflowing every window (sheet 11).
- **The Settings page is "03 DESK › Kaze"**, next to Motion and Keys (sheet 14).

---

## 1. What the research found

These are the lessons, sorted by how much they matter to us. For each one: what the game does, and what to take from it (not copy).

### 1.1 The world is the interface (Ghost of Tsushima, Ghost of Yōtei)

- **Tsushima.** The Guiding Wind replaced the minimap and waypoints. Creative director Jason Connell: the wind began as an *aesthetic* goal ("a game where everything moves", after Kurosawa) and only later became navigation, when the team asked "how do we keep players in this world without putting much UI on screen". Game director Nate Fox: the wind "doesn't dominate your view".
- **Yōtei** goes further. Art director Joanna Wang: "the wind, the trees, and the light weren't decorative; they were the interface." Foxes lead to shrines, golden birds to secrets, fireflies and flowers along good paths, white strips on climbable rock. The devs "like having a clean screen … why would we muck it up with all this stuff on the screen if we can figure out other ways to guide you?" When you ride, the already small HUD disappears entirely.
- **Yōtei builds in layers of data.** Terrain first, then foliage, then audio and haptics *read the same map data* to decide what to play. Fauna follow rules (birds at forest edges, fish only in rivers).

**For us:** the desktop's ambient layer (wallpaper, the bar's edge, window borders) should *carry* information instead of adding boxes. And one shared state (time, season, weather, battery, focus) should drive every surface at once, the way Yōtei's data layers drive picture, sound and haptics.

### 1.2 Clean screen, show on change (both Ghosts, AC Shadows)

- Tsushima's HUD is "minimal and unobtrusive, allowing immersion while giving the player the information needed" (UI artist Mike Ackerman).
- AC Shadows players praise a HUD that is fully customisable (presets, transparency, ultra-wide layouts) and "shows information only when needed".
- The one accessibility complaint about Tsushima: small text in the screen corners.

**For us:** Hanko already does "show on change" in the bar (§9 "Bar feedback, after game HUDs" in HANDOFF). Kaze makes it the rule for the whole desk, plus a **riding mode**: when you are deep in one window, everything that isn't needed withdraws. Text never gets tiny to get out of the way; it leaves instead.

### 1.3 Kamon as the icon language (Ghost of Tsushima)

- Ackerman: Japanese family crests (kamon) "played a large role in developing the UI's aesthetic". Their "simplified, perspective-free, symmetrical shapes and bold lines" stay "easy to read even at small sizes". Gear icons were made by simplifying screenshots of each item into kamon form.
- Menu art: concept art and screenshots with values "crushed to create striking black and white images that are easy to read".

**For us:** every system icon Kaze draws (OSD, notifications, launcher categories, lock) is a kamon: symmetric, flat, one weight. Hanko already has a `Crest` part (kuyo, hishi, igeta, wa, moji…), so this extends it. And **crushed values** is how we treat the wallpaper (§4.3).

### 1.4 A mode is a re-tuned whole, not a filter (Kurosawa Mode)

- Kurosawa Mode is black and white with film grain, but Sucker Punch studied how deep the blacks and how bright the whites were in samurai films at each time of day, researched the film curves Kurosawa might have used, re-tuned lighting and **made the wind stronger**. It works across gameplay and cutscenes, and you can switch it any time.
- Connell, a sky painter by training: "90% of the colour and mood and emotion comes from your upper hemisphere."

**For us:** a focus mode (§4.12, Sumi 墨) changes several things together: the screen's tone curve, the grain, notifications held, the bar receding, the wind in the wallpaper. And the top of the screen (the bar and the sky of the wallpaper) sets the mood of the hour.

### 1.5 Show the state that decides the fight (Sekiro)

- Sekiro replaced stamina with **posture** (体幹), and reviewers note that posture is more prominent in the UI than health, because it is what decides the fight. Your posture bar sits at the bottom of the screen, the enemy's at the top. Posture fills from the centre outward.
- **One kanji, one warning.** 危 flashes for an attack you can't block. Players called it out: it's the same sign for every perilous attack, so it says "danger", not "do this". Without context, kanji confuse.
- **Death as ceremony.** 死 fills the screen. It became iconic (players made their own versions). Resurrection 回生 lets you rise where you fell.

**For us:** show the *one* reading that matters now, prominently, and keep the rest quiet. Fill from the centre out (no game we found uses it for volume or brightness). Single-kanji warnings, always with English beside them and one meaning each. And a few rare full-screen ceremonies (shutdown, critical battery, a finished update) that feel like an event because they are rare.

### 1.6 Seasons change the world (AC Shadows), the calendar breathes (Yōtei)

- AC Shadows has a seasonal cycle that changes the world and even gates content (a sumi-e painting of macaques that only bathe in hot springs in winter). Its hideout is a place you arrange yourself.
- Yōtei swaps Tsushima's autumn for "contrast and volatility": sudden snowstorms, shifting light.

**For us:** Hanko already knows the 24 sekki and 72 kō (`core/Leaf.js`). Kaze lets the microseason (七十二候) quietly set the wallpaper's treatment and the lock screen's line. No new colours (rule 1 stays): the season changes light and words, never the palette.

### 1.7 Stillness, then the cut (samurai film, the duel standoff, iai)

- Tsushima's standoffs were modelled directly on the last duel of *Sanjuro* (Nate Fox). Long stillness, wind, one decisive cut.
- Iaidō, the art of the drawn sword, has four beats: **nukitsuke** (draw and first cut), **kiritsuke** (the finishing cut), **chiburi** (shaking off the blade), **nōtō** (sheathing, slowly, ending in a click).
- **Jo-ha-kyū** (序破急), from Noh theatre: begin slowly, accelerate, end abruptly. It applies at every scale, from one breath to a whole performance.

**For us:** this is the motion language (§3). No bounce, no spring, no jelly. A held beat, a fast exact move, a hard stop. Closing is slower than opening, and ends in a "click".

### 1.8 Paint and the hand (Yōtei's sumi-e, Tsushima's Mythic Tales, Sekiro's lettering)

- Yōtei has sumi-e painting as an activity; reviewers single out its map, where "icons and your travel route appear like paintings". Tsushima's Mythic Tales are told over painted, ink-wash animation.
- Sekiro's logo is a custom, brush-tapered display treatment; its menus use plain, legible faces "prioritising readability on a TV across multiple languages".
- Yōtei's art director on proportion: "if there's a belt in the middle and it's too thick, it feels more Western." Small proportions decide authenticity.

**For us:** brush lives only in **large, single, real kanji** drawn as strokes that animate in stroke order. Everything else is Hanko's set type. Latin text is never set in a fake-brush font. And proportion is checked like Wang checks a belt: hairlines stay 1 px, plates stay flat, margins stay generous.

### 1.9 What people building "Japanese" UI on the web and in ricing do

- Japanese web practice (Designmodo's 2025 survey): WebGL, GSAP and Three.js heroes, "impressive without overwhelming users". Vertical type (tategaki) and *ma* (negative space as an element) used with one deep colour and a red accent.
- Motion-design practice (2026): motion works when it "clarifies hierarchy and resolves quickly, not when it delays meaning".
- Linux ricing: Hyprland's `screen_shader` takes any GLSL fragment shader (Omarchy ships 17 in `~/.config/hypr/shaders`, including sketch, newspaper and vignette). Animated shaders need a `time` uniform, and community reports say damage tracking must be off for it to tick, which costs power. Hyprland animations take bezier curves (`hl.curve`, `hl.animation` in Omarchy's Lua config). Real-time film grain is usually a luminance noise texture jittered every frame.
- The common "samurai rice" is a wallpaper of a katana at sunset, neon red on black, a brush font in the bar and sakura particles. That is the thing to avoid (§6).

---

## 2. What it means for a desktop: the seven principles

Hanko's six rules (one paper four inks one red; red means you or now; emphasis by inversion; three faces with fixed jobs; hairlines not shadows; one baseline) still hold everywhere. Kaze adds seven:

1. **風 The world speaks first.** If the ambient layer (wallpaper, border, edge) can say it, no box appears. A box appears only when you must act.
2. **間 Stillness is the default state.** Nothing moves unless something changed. Idle desktop = zero animation, zero redraws.
3. **抜 Fast to draw, slow to sheath.** Opening is quick and exact. Closing is unhurried and ends in a click. See §3.
4. **体幹 One reading at a time.** Whatever matters most right now is large; the rest is faint or gone. Like posture over health.
5. **紋 Every sign is a crest.** Icons are kamon: symmetric, flat, one weight, legible at 16 px. Kanji are real words, with English, one meaning each.
6. **式 Ceremony is rare.** A few events get a full-screen moment (shutdown, critical battery, a finished update). Everything else is quiet. Ceremonies are skippable and never block input for more than 1.2 s.
7. **一 One state, every sense.** Time, microseason, weather, focus and power are one shared state that the wallpaper, borders, bar, lock, sound and motion all read, so they always agree.

---

## 3. Motion: Iai 居合, draw, cut, shake off, sheath

One grammar for everything that moves: bar, panels, windows, launcher, notifications, lock. Five beats, each with a fixed job, duration and curve. Shared as tokens in `core/Motion.js` (QML) and as named curves in a Hyprland Lua file, so Quickshell surfaces and Hyprland windows move the same way.

| Beat | When | Duration | Curve (cubic-bezier) | What it looks like |
|---|---|---|---|---|
| **構 Kamae** (ready) | hover, keyboard focus, a hotkey held | 90 ms | `0.2, 0, 0, 1` | No movement. Ink steps up one tier (inkMuted → inkDim → ink). The blade is in hand. |
| **抜 Nuki** (draw) | anything opens | 160 ms, after a 30 ms hold | `0.05, 0.9, 0.1, 1` | Jo-ha-kyū compressed: a tiny still beat, a fast travel, a hard stop. **No overshoot.** A panel draws from a 1 px line (its edge) to full size along one axis only. |
| **斬 Kiri** (cut) | a commit: click, Enter, a selected result | 1 frame + 70 ms | step, then linear fade | A hairline flash across the thing chosen (the cut), or the plate inverting instantly. The response is immediate, never eased in. |
| **血振 Chiburi** (shake off) | after a cut or an open | 220 ms, starting 60 ms after | `0.25, 0.1, 0.25, 1` | Secondary things settle: labels and values fade in after the plate, a stray ink tick fades. Gives the action an after-image. |
| **納 Nōtō** (sheath) | anything closes | 240 ms | `0.7, 0, 0.84, 0`, then a 1 px snap | Slow start, accelerating into the edge it came from, ending in a 1 px "click" (and the sheath sound if sound is on). |

Rules:

- **No spring, no bounce, no wobble.** A swordsman doesn't wobble. (This is also the line between Kaze and Omacale's jelly windows.)
- **One axis per move.** Things slide *or* fade *or* grow, along the axis of their edge. Never scale from the centre with blur.
- **Closing is slower than opening** (240 vs 160 ms). Every other desktop does the opposite.
- **Everything ≤ 320 ms** (Hanko's existing cap), except ceremonies (≤ 1.2 s, skippable).
- **`Motion.still`** (Hanko's existing switch) cuts all of it to instant changes, and Kaze respects the system's reduced-motion wish.

Hyprland mapping (to verify against Hyprland's animation units: `speed` is in tenths of a second):

```lua
hl.curve("nuki", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
hl.curve("noto", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })
hl.curve("kamae", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 1.6, bezier = "nuki", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.4, bezier = "noto", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.0, bezier = "nuki", style = "slidefade 8%" })
hl.animation({ leaf = "border",     enabled = true, speed = 0.9, bezier = "kamae" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "nuki", style = "once" })
```

---

## 4. Every surface, one by one

Each surface gets a Japanese name that is the thing itself, an English name beside it, what it becomes, and why. Hanko's rule for Japanese touches still applies: kanji only where they mean something, large, with English, each one switchable off.

### 4.1 Boot · 押印 Ōin, the seal pressed (Plymouth, Limine) · *left out*

*The user chose to leave the boot screen out (§9). Kept here as a record of the idea.*


- Limine: paper-coloured background, ink text, no logo art. Only colours and the font.
- Plymouth: black-to-paper. The seal (the user's `sealGlyph`, default 鑑) is **pressed**: a red square grows from nothing over 6–8 frames with a slightly uneven ink spread (a pre-rendered image sequence, so it is the same every boot), then holds. Under it, a 1 px hairline draws left to right as the progress bar. The disk passphrase prompt, if any, is a single underline with dots.
- First words after the seal: the microseason, small, in English and Japanese (e.g. 菊花開 · *Chrysanthemums bloom*). It is the only line.

Why: the seal is Hanko's identity, and pressing it is a real, physical act. Starting the machine = putting your mark on the day.

### 4.2 Login and lock · 対峙 Taiji, the standoff (omarchy.lock)

- The screen is the wallpaper (§4.3), darkened to paper, with the living layer (§4.4) still moving: grass in the wind along the foot. Nothing else moves.
- Centre-left, set large: the time in Fraunces, the day, and the microseason. No avatar circle, no blurred card.
- **The stance.** When you start typing, a single horizontal hairline draws (nuki) under the time: the blade leaving the scabbard. Each character is a short ink tick on it, not a dot in a box.
- **A wrong password is a deflection.** One red notch sparks where the line ends, the line shudders 2 px once, and the ticks fade (chiburi). No red box, no shake of the whole form.
- **The right password is the cut.** A diagonal hairline crosses the screen in one frame (kiri), the two halves slide apart along it over 240 ms (nōtō in reverse), and the desktop is behind them.
- Fingerprint: the same, with a small 指 crest that inks in while the reader waits.

Why: Tsushima's standoff (stillness, wind, one cut) is the most "samurai" moment in any of these games, and unlocking is the one moment a day where a cut fits.

Constraint: only the view changes. The PAM flows, password and fingerprint, stay byte-for-byte Omarchy's (§7, §9).

### 4.3 Wallpaper · 墨刷 Sumizuri, ink printing

- The user already has ukiyo-e prints in the Hanko theme (`1-pines-night.jpg`, `2-great-wave.jpg`, `3-red-fuji.jpg`, `7-haboku.jpg`…). Kaze doesn't replace them; it **prints** them in the theme's inks.
- A shader maps luminance to the theme: shadows → paper, mids → the four ink tiers, highlights → ink, and the strongest reds → the seal red only. Values are crushed to 3–5 steps (Ackerman's "crushed values"), with a fixed paper grain. Any wallpaper and any Omarchy theme then match automatically.
- **Sky = mood of the hour** (Connell's upper hemisphere): the top 30% of the print brightens or deepens with the sun's height, a few percent only, re-rendered once every 15 minutes.
- The microseason picks the treatment's character: more grain and a cooler crush in 大寒, softer in 春分. Small, felt rather than seen.

Why: the theme stays the only source of colour (Hanko rule 1), and the wallpaper stops fighting the bar.

### 4.4 The living layer · 風 Kaze, the wind

The signature of the whole direction. A sparse layer of grass strokes (about 60–120 brush blades) along the bottom of the wallpaper, drawn in `inkFaint`, that bends in the wind.

- **The wind is real.** Direction and strength come from the actual weather (Hanko already reads it for the bar). A still day is still. A storm leans the grass hard.
- **The wind guides.** When something needs you (an urgent workspace, a notification that asks for action, a reminder), one gust runs through the grass *toward* where it is (bar end, monitor, workspace), once, then calms. Not an arrow, not a badge: the environment points, like Tsushima's wind.
- **It rests.** It runs at most 30 fps, only while visible, pauses when a window is fullscreen or on battery below 30%, and stops entirely when the wind is calm. Idle = 0 fps.
- Off switch: `kaze: off`. A lighter option, `kaze: edge`, draws the gust only along the bar's rod/rule.

Why: everyone else adds sakura particles as decoration. Here the moving thing is information (real weather, things that need you), which is exactly what Sucker Punch did and what no desktop does.

### 4.5 Windows · 刃 Ha, the edge (Hyprland)

- Rounding 0. Gaps 6/12. No shadows. Borders 1 px: focused `ink`, unfocused `ink` at 22%.
- **Focus is a gust.** When focus moves, the new window's border is a gradient that sweeps once (`borderangle … once`): a highlight passes around the edge like light on a blade, 600 ms, then the border is plain. The old window's border fades with kamae.
- Opening slides in from the nearest screen edge with nuki; closing slides out with nōtō. Workspaces slide like a scroll being rolled (Hanko's Scroll lineage).
- `dim_inactive` at 0.06: barely there, so the focused sheet reads as the lit one.
- Urgent window: border goes red and breathes slowly (Hanko's existing "never colour alone" rule).

### 4.6 The bar · 判子 Hanko

Already built. Kaze changes three things:

- Uses the shared Iai tokens (§3) instead of its own timings, so the bar and every other surface move alike.
- The rod/rule along its edge can carry the gust (§4.4) when the wallpaper layer is off.
- Riding mode (§4.13): it recedes to its hairline and returns on change or on the pointer.

### 4.7 On-screen display · 体幹 Taikan, posture (omarchy.osd)

- Volume, brightness, keyboard light: a **single hairline across the bottom-centre** of the screen, 30% of its width, that fills **from the centre outward** in both directions, like Sekiro's posture bar. Above it, small: the label in mono (VOL 音) and the value in Space Grotesk, rolling to the new number (Hanko's `RollText`).
- At 100% the two ends meet the line's end caps and the whole line inks to full for one frame (a "posture break", here meaning "can't go further"). Muted: the line goes red and collapses to the centre.
- Caps Lock, mic mute, power profile: a single kamon centred above the line with its word. No rounded rectangle, no blur card.
- Draws with nuki, sits 900 ms, sheathes with nōtō.

### 4.8 Notifications · 文 Fumi, letters

- A notification arrives as a **tanzaku**: a narrow vertical paper strip hanging from the bar's edge near the right end, carrying only the app's crest and the time, set vertically. The strip unrolls downward with nuki (scroll lineage). The wind gusts toward it if it asks for action.
- Hover or Super+N opens it sideways into a horizontal card: title in Space Grotesk, body set normally (Latin is never set vertically), actions as `//` inverted plates. Cards are hairline-framed paper, no shadow.
- Several notifications hang side by side like strips on a bamboo branch, newest nearest the bar's centre, at most five, then a count.
- Urgent: the strip's crest is the red seal. Critical (e.g. battery 5%) becomes a ceremony (§4.11).
- Dismiss: the strip is cut (a 1-frame diagonal hairline) and falls away with nōtō.

Why: every desktop slides a rounded toast in from the top-right. A hanging strip of paper is native to the Hanko/Scroll world and reads at a glance.

### 4.9 Launcher and menu · 抜刀 Battō, the draw (omarchy.menu, launcher)

- Opens as a **1 px vertical line** at the left third of the screen that draws open into a column (nuki, one axis). The scrim is paper at 40%, no blur.
- The query sits on an underline in Fraunces 28. Results in Space Grotesk; the selected one is an inverted ink plate with a `//` lead, and the selection moves instantly (kiri), never slides.
- Categories (apps, files, system, emoji, clipboard) are a column of small kamon down the left edge with their word.
- Enter = the cut: the plate flashes, the column sheathes.
- First pass: only Omarchy's theme TOMLs (`shell.launcher.toml`, `shell.menu.toml`) and fonts. Second pass: a full clone if the look needs more.

### 4.10 Terminal, prompt, editor, system monitor · 道具 Dōgu, the tools

- Alacritty/Ghostty/Kitty colours from the theme (Omarchy's templates do this), padding 14 px, the user's monospace.
- **Prompt:** one seal glyph, the path receding (last part in ink, the rest in inkFaint, like the bar's title), git state as a mono word, never powerline arrows or emoji. On an error, the seal turns red.
- **Greeting** (optional, replaces fastfetch): the seal, the microseason, the date in one line.
- btop, Neovim, lazygit: theme colours, with red reserved for errors and "now".
- Cursor: a small brush-tip cursor theme (Hanko's `pointer: brush` brought to the whole system through hyprcursor).

### 4.11 Ceremonies · 式 Shiki

Rare, full-screen, skippable (any key), ≤ 1.2 s, never during fullscreen apps except critical battery.

| Event | Kanji | What happens |
|---|---|---|
| Shutdown | 終 *end* | Paper fills the screen with nōtō; 終 is brushed in stroke order at 40% of screen height; the seal presses beside it; black. |
| Logout | 退 *withdraw* | Same, shorter. |
| Critical battery (≤ 5%) | 危 *danger* | 危 in red, with "Battery 5% · plug in" beside it. Once, then the bar keeps breathing red. |
| Update finished | 新 *new* | 新, with the version beside it, on next login only. |
| Session restored after a crash | 回生 *rise again* | Only if Omarchy's session restore applies. Small, the lock screen's corner. |

The brush strokes are real: drawn once as SVG paths in stroke order (from a calligrapher's reference or a stroke-order dataset such as KanjiVG, license checked), animated with stroke-dash in a QML `Shape`. Never a "brush" font.

### 4.12 Sumi mode · 墨, focus (screen shader + shell)

The Kurosawa Mode lesson: a whole re-tuned state, not a filter.

- A screen shader (`hanko-sumi.glsl`) turns the screen monochrome with a film S-curve, a fixed paper grain and a slight vignette, **and keeps the seal red** (pixels close to the theme's red keep their colour, so "you/now" survives).
- At the same time: notifications are held (Omarchy's DND proxy), the bar recedes to riding mode, the wind in the wallpaper strengthens a little (as Sucker Punch did), and sound goes quieter.
- Toggle: a binding (Super+Ctrl+S, to choose), the bar's seal menu, or a schedule.
- Static grain only by default, because animated grain needs damage tracking off (power cost).

### 4.13 Riding mode · 騎 Ki, when you are moving

Yōtei hides the HUD while you ride. Here: when a window is focused and you are typing for more than ~20 s, or a window is fullscreen, the bar recedes to its hairline (if `position` allows), the living layer pauses, and only red things (now, you) may show. The pointer touching the bar's edge, or any change that needs you, brings it back with nuki. Switchable, with a delay setting.

### 4.14 Screenshots and recordings · 写 Utsushi

- Capture: a single paper-white frame flash at 8% (the press), a 1 px frame drawn around the captured region with nuki, then the notification strip (§4.8) with the thumbnail.
- No sound by default; the shutter is the paper sound if sound is on.

---

## 5. Sound 音

Ghost of Tsushima and Sekiro rely heavily on sound (shakuhachi, biwa, the clash and click of steel). A desktop must be much quieter. Six sounds at most, **off by default**, each under 250 ms, mastered quiet (around −28 LUFS), played with `pw-play`:

| Sound | Event | Source idea |
|---|---|---|
| 納 sheath click | a panel closes | a real tsuba-to-koiguchi click, recorded or CC0 |
| 拍子木 hyoshigi | workspace change | two hardwood clappers, very short |
| 紙 paper | notification arrives | a paper strip unrolling |
| 鈴 suzu | reminder, urgent | a small bell, once |
| 墨 ink | screenshot | a brush touching paper |
| 鐘 bell | shutdown ceremony only | a distant temple bell, faded |

Rules: no music, no shakuhachi loops, no sound on every click, no sound while a fullscreen app runs. Licence of every file recorded in the credits.

---

## 6. What we refuse to do (the anti-slop list)

These are what "samurai theme" usually means, and what makes it look generated or cheap:

- Katana-at-sunset wallpapers, red-and-black gradients, neon "cyber Japan".
- Sakura or leaf particles as decoration. (Our only moving nature carries information, §4.4.)
- Brush-script fonts for Latin text, "Japanese-looking" faux fonts, random kanji as texture, kanji without a meaning or without English.
- Torii gates, ninja stars, oni masks as icons.
- Glow, bloom, glassmorphism, blur cards, drop shadows, gradients on UI.
- Rounded toasts from the top-right, bouncy docks, spring overshoot, jelly windows.
- Colour icons from three icon packs. Emoji as UI.
- Constant animation. A desktop that moves when nothing happened.
- Copying any game's assets, layouts, logos, sounds or the 死 screen itself. We take *ideas* (environment as interface, posture over health, ceremony, the standoff), never pixels.
- The "Kurosawa" name. The estate approved it for Sucker Punch; ours is Sumi 墨.

And the checks every mockup passes before it is built:

1. Could this be any other "Japanese theme"? If yes, cut or rethink.
2. Is every kanji a real word for the thing, with English beside it, at a readable size?
3. Does anything move while nothing changed?
4. Is there any colour that doesn't come from the theme? Any red that isn't "you" or "now"?
5. Does it work with `Motion.still` and with sound off?
6. Does it look right in a light theme too (Hanko supports light paper)?

---

## 7. How each surface plugs into Omarchy

Findings from the installed Omarchy (`/usr/share/omarchy/shell/README.md`, `services/PluginRegistry.qml`, `bin/omarchy-plugin-clone`, the theme folders).

- **Plugin kinds:** `bar`, `bar-widget`, `panel`, `overlay`, `menu`, `service`.
- **Cloning first-party plugins is the supported way to restyle them.** `omarchy plugin clone omarchy.osd` copies the plugin into `~/.config/omarchy/plugins/<user>.osd` with `"omarchy": { "clonedFrom": "omarchy.osd" }` in its manifest. Shortcuts and IPC calls made to the built-in id are then **routed to the clone**, and the registry gives the clone the source's host capabilities (`stampHostCapabilities`). So a Hanko-shipped plugin with `clonedFrom` set takes over that surface without changing any keybinding.
- **This includes the lock.** `omarchy.lock` is a `service` with the `authentication` capability, and a clone inherits it. That is powerful and must be handled with care (§9).
- **Themes** (`~/.config/omarchy/themes/<name>/`) carry `colors.toml`, `hyprland.lua`, `shell.bar.toml`, `shell.launcher.toml`, `shell.menu.toml`, `icons.theme`, `neovim.lua`, backgrounds and an `unlock.png`. Hooks run on `theme-set`, `font-set`, `post-boot`, `battery-low`.
- **Hyprland** is configured in Lua (`hl.config`, `hl.curve`, `hl.animation`). `looknfeel.lua` already loads a bar's own look file when that bar is active (Omacale does it with `pcall(dofile, …omacale.lua)`): Hanko can ship `style.lua` the same way.
- **Screen shaders** live in `~/.config/hypr/shaders/`, selected by `decoration.screen_shader` (managed by `omarchy-menu-shaders`).
- **Boot:** `/usr/share/omarchy/default/plymouth/` (a Plymouth script theme with PNGs) and `default/limine/`.

| Surface | Route | Effort |
|---|---|---|
| Motion tokens, windows, borders | `style.lua` (already Hanko's Hyprland file) loaded from `looknfeel.lua` + theme `hyprland.lua` | S |
| Wallpaper print + living layer | clone of `omarchy.background` (verify kind and how it draws) with a QML `ShaderEffect` | L |
| OSD 体幹 | `hanko.osd`, `clonedFrom: omarchy.osd` | M |
| Notifications 文 | `hanko.notifications`, `clonedFrom: omarchy.notifications` | L |
| Launcher/menu 抜刀 | theme TOMLs first; `hanko.menu` clone later | S → L |
| Lock 対峙 | `hanko.lock`, `clonedFrom: omarchy.lock`, view only | L, security review |
| Ceremonies 式 | a `hanko.shiki` overlay plugin + Omarchy hooks and power-menu commands | M |
| Sumi 墨 | a GLSL file + a toggle script + the bar | S |
| Terminal, prompt, cursor, btop, nvim | the theme folder, a starship config, a hyprcursor theme | M |
| Sound 音 | `pw-play` from the plugins, files in `assets/sound/` | S |

**Packaging.** A repo holds one manifest at its root, and the marketplace installs the bar from `main`. Proposed: keep `hanko.bar` as the marketplace plugin, and add a `plugins/` folder holding `hanko.osd`, `hanko.notifications`, `hanko.lock`, `hanko.shiki`…; `scripts/hanko install --desk` copies or links them into `~/.config/omarchy/plugins/` and enables each one the user picks. Also move the Hanko theme (now only in `~/.config/omarchy/themes/hanko_theme`) into the repo as `theme/`.

---

## 8. Roadmap

Same routine as every Hanko phase: design first with mockups, then one surface per phase on `dev`, each checked with `tests/run` and renders, ROADMAP/README/HANDOFF updated in the same commit. Status: ✅ done · 🔨 in progress · ⬜ not started.

### KZ0 · Research and plan ✅
This file.

### KZ1 · Mockups for every surface ✅
- An HTML kit under `docs/kaze/source/` (same approach as `docs/mockups/typeset/source/`: one CSS of tokens, Playwright to render).
- A sheet per surface: lock (idle, typing, wrong, right), wallpaper print (three prints × light/dark), living layer (calm, gust), windows (focus sweep), OSD (50%, 100%, muted), notifications (one, three, opened, urgent), launcher, ceremonies (終 危 新), Sumi mode, terminal.
- Motion studies as short WebM loops for the Iai beats, the lock cut and the gust.
- The user picks and trims before anything is built.
- Done: the fourteen sheets in §0 (motion studies as video loops are left for KZ2, where the real curves run).

### KZ2 · Iai, the shared motion ✅
- `core/Motion.js`: the five beats as tokens (durations, curves), unit-tested; the bar's existing timings move onto them.
- `style.lua` (Hanko's existing Hyprland file): the curves and animations of §3. `hanko desk on|off` adds or removes its `dofile` line in `looknfeel.lua`, whichever bar is in use.
- Done when: windows open with nuki and close with nōtō, and the bar and windows feel like one hand.
- Built: `core/Iai.js` (BEATS, ORDER, `qml()`, `total()`, `ease()`, `at()`, `hyprSpeed()`, 3 unit tests); `Motion.qml` exposes `kamae`, `nuki`/`nukiHold`/`nukiCurve`, `kiri`, `chiburi`/`chiburiDelay`, `noto`/`notoCurve`, and `sheetPrint` is now the draw (190 ms); sheets draw open and sheathe shut (`SheetView`, `SheetWindow`'s close timer and Inkan lift-off); the Motion timesheet lists the five beats first. Hyprland: Hanko already had `style.lua`, so its motion section became Iai (windows slide in on nuki and out on noto, no pop-in; fades, layers, workspaces and the border on the same curves), and a test keeps it in step with `Iai.js`. `hanko desk on|off|status` adds or removes one marked line in `looknfeel.lua`, independent of the bar.

### KZ3 · Ha 刃, windows ⬜
- The focus sweep (gradient border + `borderangle once`), urgent border breathing, workspace slide.
- Verify on hardware that `once` fires on each focus change, and the cost on a 4K screen.

### KZ4 · Sumizuri 墨刷, the printed wallpaper ⬜
- The duotone/crush shader in theme inks, paper grain, sky by the hour, season character.
- Render tests with the user's seven prints in dark and light themes.

### KZ5 · Kaze 風, the living layer ⬜
- Grass strokes from real weather; gusts toward what needs you; 0 fps when idle; pauses for fullscreen and low battery.
- Measure: CPU/GPU at rest and in a gust; must be unnoticeable.

### KZ6 · Taikan 体幹, the on-screen display ⬜
- `hanko.osd`: the centre-out hairline, rolling value, crest indicators, posture break at 100%, muted collapse.

### KZ7 · Fumi 文, notifications ⬜
- `hanko.notifications`: hanging tanzaku strips, sideways card, actions, cut-to-dismiss, the bar's inbox reading from the same source.

### KZ8 · Battō 抜刀, launcher and menu ⬜
- Theme TOMLs and fonts first (small). If the mockup needs the line-to-column draw and kamon categories, a `hanko.menu` clone.

### KZ9 · Taiji 対峙, the lock ⬜
- `hanko.lock`: `Service.qml` and every PAM path copied unchanged from Omarchy; only `LockView.qml` is ours. The standoff line, tick per character, deflection on a wrong password, the diagonal cut on success, fingerprint crest.
- A test that diffs our Service against Omarchy's on every run, and a `doctor` check that warns when Omarchy's lock changed upstream.
- Hardware test checklist: wrong password, right password, fingerprint, multiple monitors, suspend/resume while locked, the shell crashing while locked.

### KZ10 · Shiki 式, ceremonies ⬜
- `hanko.shiki` overlay: 終 退 危 新 回生 with stroke-order brush animation in QML `Shape`.
- (Boot 押印 is left out, §9.)

### KZ11 · Sumi 墨 and riding mode ⬜
- `hanko-sumi.glsl` (S-curve, grain, vignette, red kept), the toggle, DND, the bar receding, stronger wind.
- Riding mode in the bar with a delay setting.

### KZ12 · Dōgu 道具 and Oto 音, tools and sound ⬜
- Theme in the repo (`theme/`), starship prompt, greeting, btop/nvim/lazygit colours, brush cursor.
- The six sounds, off by default, with their licences.

### KZ13 · Kaze 風 settings page and install ⬜
- A Kaze page in Hanko's settings: every surface on or off with a live tile (no Save button, Undo with Ctrl+Z, as always), sound volume, riding delay, Sumi schedule.
- `scripts/hanko install --desk`, `uninstall --desk` (restores every built-in), `doctor` covering every clone.

Order rationale: motion first (everything depends on it), then the cheapest high-impact surfaces (windows, wallpaper), then the panels, then the risky lock, then the rest.

---

## 9. Risks, things to verify, open questions

**Risks**

- **The lock.** A clone inherits the `authentication` capability. Any bug in our view must never be able to unlock or crash the session open. Mitigation: keep Omarchy's service code identical (diff test), keep our view stateless, test the crash case, and make `uninstall --desk` restore `omarchy.lock` first.
- **Clones drift.** A clone doesn't update with Omarchy. When Omarchy changes the OSD or notifications, ours fall behind. Mitigation: keep each clone's data/service code as close to upstream as possible, only our view differs, and `hanko doctor` compares versions.
- **Power and performance.** The living layer and an animated screen shader cost GPU time and battery. Budgets: 0 fps at rest, ≤ 30 fps in a gust, static grain by default, everything paused on battery under 30% and for fullscreen apps.
- **Cultural care.** Yōtei's team worked with an Ainu advisor. We use only common, real words and seasons, check every kanji's meaning and stroke order, and avoid religious symbols as decoration.
- **Too much.** A whole-desktop theme can become tiring. Every surface is optional, and the default set should stay small (to decide after KZ1).

**To verify on a real machine**

1. That `omarchy.background` can be cloned and can host a `ShaderEffect` (or whether the wallpaper needs its own overlay layer under windows).
2. That Qt shaders for `ShaderEffect` in Omarchy's Quickshell need precompiled `.qsb` files, and how to ship them.
3. Hyprland `borderangle` with `once`: does it run on every focus change?
4. Whether Hyprland's screen shader gets a `time` uniform in the installed version, and the cost of `damage_tracking = 0`.
5. Whether screenshots and screen recordings capture before or after the screen shader (Sumi mode must not tint screenshots unless the user wants that).
6. That a third-party plugin with `clonedFrom` set, not made by `omarchy plugin clone`, is routed and stamped the same way (the code says yes; test it).

**Decisions (the user, 2026-10-14)**

1. Every surface is in scope, the lock included.
2. The boot screen (§4.1) is left out: no Plymouth or Limine work, nothing that needs sudo.
3. One repo for everything: `hanko.bar` at the root, the other surfaces under `plugins/`.
4. Sound is in (still off by default, one switch turns it on).
5. Kaze is the working name; it can change later.

---

## 10. Sources

Games and their makers:

- TechRadar, Ghost of Tsushima interview (Jason Connell on the Guiding Wind): https://www.techradar.com/news/ghost-of-tsushima-interview-nature-sprawls-in-ps4s-epic-samurai-swan-song
- Android Central, why Ghost of Tsushima has no waypoints: https://www.androidcentral.com/ghost-tsushima-creative-director-interview
- Geek Culture, interview with Nate Fox: https://geekculture.co/geek-interview-ghost-of-tsushima-nate-fox
- Mike Ackerman, Ghost of Tsushima UI (kamon icons, crushed values): https://mikeackerman.art/project/ghost-of-tsushima-ui
- Can I Play That, Ghost of Tsushima accessibility breakdown: https://caniplaythat.com/2020/05/18/ghost-of-tsushima-state-of-play-accessibility-breakdown/
- Inverse, Ghost of Tsushima's Kurosawa Mode: https://www.inverse.com/gaming/ghost-of-tsushima-gameplay-cinema-mode-kurosawa
- TheWrap, art director on Kurosawa Mode: https://www.thewrap.com/ghost-of-tsushima-art-director-says-yes-you-can-play-entire-game-in-kurosawa-mode/
- Den of Geek / Flicks, Kurosawa's influence and Connell on the sky: https://www.flicks.com.au/features/how-the-hit-ps4-game-ghost-of-tsushima-was-influenced-by-kurosawa-and-samurai-cinema/
- GamesRadar, Ghost of Yōtei's "living painting": https://www.gamesradar.com/games/open-world/ghost-of-yoteis-art-director-wanted-the-rpg-to-look-like-a-living-painting-but-the-detail-required-stresses-even-me-out-when-the-wind-blows-the-trees-know-how-strong-the-wind-is/
- GamesRadar, Ghost of Yōtei's clean screen: https://www.gamesradar.com/games/open-world/ghost-of-yotei-devs-like-having-a-clean-screen-free-of-mini-maps-and-yellow-paint-why-would-we-muck-it-up-with-all-this-stuff-on-the-screen-if-we-can-figure-out-other-ways-to-guide-you/
- Postmode, interview with Joanna Wang: https://postmode.substack.com/p/ghost-of-yotei-art-director-interview
- Gamer Braves, interview with Joanna Wang: https://www.gamerbraves.com/ghost-of-yotei-interview-sucker-punchs-art-director-on-designing-atsu-and-a-living-samurai-world/
- Kotaku, Ghost of Yōtei's wind: https://kotaku.com/ghost-yotei-graphics-ps5-open-world-wind-2000631510
- TechRadar, Ghost of Yōtei review (the painted map): https://www.techradar.com/gaming/ghost-of-yotei-review
- Game UI Database, Ghost of Yōtei: https://www.gameuidatabase.com/gameData.php?id=2187
- Game UI Database, Assassin's Creed Shadows: https://www.gameuidatabase.com/gameData.php?id=2093
- Ubisoft, Assassin's Creed Shadows accessibility spotlight: https://news.ubisoft.com/en-us/article/1Y0Q8goho9gJzCV2UBjyUJ/assassins-creed-shadows-accessibility-spotlight
- The Ones Who Came Before, interview with Simon Lemay-Comtois (seasons): https://www.theoneswhocamebefore.com/news/interview-with-simon-lemay-comtois:-associate-game-director
- Game Wisdom, Sekiro's combat (posture over health): https://game-wisdom.com/critical/breakdown-sekiros-combat-broken
- GameWith, Sekiro's kanji signs: https://gamewith.net/sekiro/article/show/8500
- Steam discussion, readability of Sekiro's kanji: https://steamcommunity.com/app/814380/discussions/0/1839063537792149131
- AV Club, death in Sekiro: https://www.avclub.com/sekiro-shadows-die-twice-death
- Made Good Designs, Sekiro's typography: https://madegooddesigns.com/?p=9925

Design and motion:

- No Film School, Mark Solomon on jo-ha-kyū: https://nofilmschool.com/mark-solomon-book
- Designmodo, Japanese web design: https://designmodo.com/japanese-web-design
- Digital Silk, kinetic typography: https://www.digitalsilk.com/web-design/web-trends/kinetic-typography/
- Design Society, kinetic typography studies in Japan: https://www.designsociety.org/publication/32530/kinetic_typography_studies_today_in_japan

Linux and shaders:

- Hyprshade (Hyprland screen shaders): https://pypi.org/project/hyprshade/0.6.2
- r/hyprland, time uniform in screen shaders: https://redlib.ssps.io/r/hyprland/comments/1j74137/loving_shaders
- Khronos forum, real-time film grain: https://community.khronos.org/t/film-grain-in-opengl/36953
- Godot Shaders, film grain (CC0): https://godotshaders.com/shader/film-grain-shader/
- Omarchy, installed: `/usr/share/omarchy/shell/README.md`, `/usr/share/omarchy/shell/services/PluginRegistry.qml`, `/usr/bin/omarchy-plugin-clone`, `/usr/share/omarchy/default/hypr/looknfeel.lua`
