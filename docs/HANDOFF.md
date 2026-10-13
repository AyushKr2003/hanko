# Hanko handoff: everything a fresh session needs

This file is the single source a new Claude session (or a person) reads to pick up Hanko exactly where it was left. It covers the brief, every branch, the design, the Omarchy plugin contract, the code, the dev environment, the conventions, what each finished phase built, and detailed instructions for every remaining phase.

Last updated: 2026-10-13, after Kōsei 校正, Typesetting as a proof (§9 "Kōsei 校正"; design in `docs/settings-kosei/`); before that, after Inkan 印, the seal only (`form: inkan`, §9 "Inkan 印"; design in `docs/shell-concepts/inkan/`); before that 2026-10-11, after the Hanko preset was renamed Kamon 家紋 (§9, "Kamon 家紋"), Settings › Presets 型 (every preset as a live specimen, its own page; §9 "Presets 型, a page of their own") and the right-side studies (Ma, Shizuka, Suji, Inrō: four `status` values and four presets, §9 "The right side, four ways"); before that, 2026-10-09, the Hanko preset became the user's own bar (§9, "The Hanko preset is the user's bar"), and before that Shōji was folded into Hanko (S1–S5): one design, Hanko. Shōji's panels are a seventh sheet hand (S1), its framed overview is `overview: framed` (S2), its bar parts are Hanko values with season, numerals and grain as settings (S3), Shōji is a preset that a saved Shōji design loads as (S4), and the design switch is gone (S5). The plan is in §10, "Shōji into Hanko".

**Read order for a fresh session:** this file, then [ROADMAP.md](ROADMAP.md), then [COMPONENTS.md](COMPONENTS.md) (the full spec of every option), then the code. Keep this file current: update §9 (status) and §12 (known issues) at the end of every phase, in the same commit.

---

## Contents

1. [The brief](#1-the-brief)
2. [How the user likes to work](#2-how-the-user-likes-to-work)
3. [Repository and branches](#3-repository-and-branches)
4. [Hard rules (commits, git, privacy)](#4-hard-rules-commits-git-privacy)
5. [The design in one page](#5-the-design-in-one-page)
6. [How a bar plugin plugs into Omarchy](#6-how-a-bar-plugin-plugs-into-omarchy)
7. [Code map](#7-code-map)
8. [Dev environment from scratch](#8-dev-environment-from-scratch)
9. [Phase status and what each phase built](#9-phase-status-and-what-each-phase-built)
10. [Instructions for the remaining phases (5–10)](#10-instructions-for-the-remaining-phases-510)
11. [The per-phase routine](#11-the-per-phase-routine)
12. [Known issues and things to verify on a real machine](#12-known-issues-and-things-to-verify-on-a-real-machine)
13. [QML pitfalls already hit](#13-qml-pitfalls-already-hit)
14. [Reference material](#14-reference-material)

---

## 1. The brief

- **What:** Hanko (判子, the personal seal stamped on a document) is a premium **bar plugin for Omarchy** (the Arch + Hyprland setup by DHH, `github.com/omacom/omarchy`). Plugin id `hanko.bar`, kind `bar`: it replaces Omarchy's whole bar.
- **Style source:** the **Settings app of Ryoku** (`github.com/Ryoku-dev/ryoku`, branch `unstable-dev`) and the visual design of **ryoku.dev**. Not Ryoku's bars (QS Bar, Sumi, Kairos, Shima).
- **Must be original.** Take Ryoku's *grammar* (one paper colour, warm ink in four contrast tiers, hairlines not shadows, emphasis by inversion with a `//` lead, a serif only for titles, tracked mono labels, a kanji gloss beside Latin labels). Do not copy its palette, its fonts-as-brand, its ornaments (barcodes, registration backdrops) or any of its bars. No generic "AI look": no floating pills, glow, coloured icon soup.
- **Premium and interactive:** strong interaction (click, scroll, hover all do something meaningful), print-like motion.
- **Owner:** Ayush (GitHub `AyushKr2003`).

## 2. How the user likes to work

These come from the user's own messages and reactions:

- **Design first, with many mockup images.** Each design direction (Sheet, then Scroll, then Typeset) got a full set of rendered mockups; all three now live on the `docs` branch. The user picks a direction, then asks for the next.
- **Build step by step, not all at once.** Verbatim: *"work on this properly with roadmap and all in step by step … no need to do all at once and commit after a part is done."* One phase (or a clear part of a phase) per commit, pushed right away.
- **Work happens on `dev`.** Verbatim: *"merge this branch in main and from there create a new branch name dev and start working in that."* Do not merge `dev` into `main` again unless the user asks.
- **Read the real docs.** The user pointed at the Omarchy manual and its third-party plugin docs. Base every integration decision on the Omarchy source, not on guesses.
- **Integration references are not design references.** Shibumi-Shell, `AyushKr2003/omacale` and ruixen-shell show how plugins talk to Omarchy; never borrow their look.
- **"good" / "go on" means keep going** to the next phase without asking.
- **Show renders.** Every phase reply carries a render of what was built (the harness PNG), since there is no Omarchy machine in the cloud session.
- **Before writing a lot of new code after a long stretch, the user may ask for a write-up like this one.** Keep it updated.
- **Redesigns are explored on their own branches first, built on `dev` only once chosen.** The user asked for a premium redesign "as a simple person would see it" (`design`, Margin), got a second take (`design2`, Leaf), then asked for "a Japanese touch" (`design3`, Shōji), then for "a uniform for all designs so we can twist whatever design we want" (`revision1`, Kata). They liked all three; Kata was built, and later Margin and Leaf were removed, leaving Hanko and Shōji.
- **Japanese touches must mean something.** Kanji only where they are the thing itself (a season, a panel's sign, the seal), large, with English beside; Mincho only at 18 px and up; each touch switchable off. The old tiny kanji glosses were judged noise in the audits.
- **When the user leaves a decision open and says "start", pick a sensible default, say so, and keep going.** For Kata: Classic stays the default design; Shōji's variants were to be built first (all three landed together in K3).
- **Naming:** the bar is called **Hanko** in the UI, README and CLI. Older docs below say "Classic" for it, from when Shōji was a second design; since "Shōji into Hanko" (§9, §10) there is one design, and Shōji is a preset, a sheet hand and option values.
- **Pushing straight to `dev` works** in cloud sessions (the user said: push to dev, or make a branch from dev if that is refused).
- **Settings have no Save button.** Verbatim: *"in setting you don't keep the save button"*. Every change applies and is kept at once, with Undo (Ctrl+Z). Keep it that way for any new setting.

## 3. Repository and branches

Repo: **`AyushKr2003/hanko`** (private). In cloud sessions it was checked out at `/tmp/claude-0/hanko`.

| Branch | What it holds |
|---|---|
| `main` | The released state. Updated only when the user asks (by merging `dev`). |
| **`dev`** | **All current work.** The active branch. |
| `docs` | Every design direction in one place: Sheet, Scroll and Typeset, each with its mockups, HTML source, README and changelog. |
| `design`, `design2`, `design3` | Three redesign proposals asked for by the user: Margin, Leaf and Shōji (docs, images and an HTML prototype each; no QML). |
| `revision1` | Kata 型: one engine for all three designs (`docs/kata/`). Its spec is copied onto `dev`, where it is being built (K1–K7 in ROADMAP). |
| `revision2` | Classic polished, not redesigned (asked for: "polish it as a senior would a junior's design"). Merged into `dev` (`d565381`); new work goes on `dev`. |

The design directions, in the order they were drawn:

1. **Sheet**: the bar as a printed running head. Seal, label-over-value cells, tick meters, the 24-hour day rule along the foot, folio workspaces, flush sheets that drop from a cell. 5 mockups. Lives on as the Sheet preset.
2. **Scroll**: a calm one-line bar that unrolls into a horizontal handscroll (emakimono) holding every panel, with rollers, an index plate and dithered interludes (since replaced by the `interlude` setting). Workspace-numeral seal, real-layout workspace glyphs, serif byline, kanji glyph status, notification stamps, the rod. 6 mockups. Lives on as the Scroll preset.
3. **Typeset** (chosen): the two merged; every part of the bar is a setting, with a Typesetting 組版 settings page. 19 mockups in `docs/mockups/typeset/`, spec in `docs/COMPONENTS.md`, overview in `docs/DESIGN.md`. This is the spec the plugin implements.

Older commit messages call these designs beta1, alpha1 and gama1.

A future design direction (if the user asks for one) gets a plain descriptive name, a full set of mockups under `docs/mockups/<name>/`, a design doc, and lands on the `docs` branch.

## 4. Hard rules (commits, git, privacy)

- **Commit message trailer** (every commit, exactly these two lines at the end):
  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01ANerSjChq6Gi7H1fd3vhH3
  ```
  A new session gets its own attribution lines from its system prompt; use those if they differ.
- **No model names or ids** in commits, PR text, code comments or any repo file.
- **Commit messages:** `Phase N: <short title>` then a blank line and a plain-language paragraph or two on what the phase does for the user.
- **Push with** `git push -u origin dev`. The git proxy in cloud sessions **rejects tag pushes**; use branches, never tags.
- **Only this repo.** Do not use GitHub's `create_repository` or any `search_*` tool. Reference repos are cloned read-only into a scratch folder (§8).
- **The repo is private.** Never publish its content anywhere outside the project.
- **Project chat (Claude projects):** replies go through the thread's `reply` tool. A thread can hold at most 24 attached outputs; the Hanko thread is at that limit, so link files by path (`/mnt/project-files/...`) in the text instead of attaching them. Renders are copied to `/mnt/project-files/ryoku-shell/typeset/phaseN-render.png`.

## 5. The design in one page

Full spec: [COMPONENTS.md](COMPONENTS.md). This is the summary a builder needs in their head.

### The six rules every option keeps

1. **One paper, four inks, one red.** All colour comes from the Omarchy theme. Paper = `background`; ink = `foreground` stepped toward the paper to contrasts of **12, 9, 6.2 and 4.6 : 1** (`ink`, `inkDim`, `inkMuted`, `inkFaint`); seal = the theme's `red`. No option may introduce a colour.
2. **Red means "you" or "now".** The seal, the now-notch, an urgent workspace, a muted master, an unread dot, a low battery, being offline. Nothing else is red.
3. **Emphasis is inversion.** The selected thing becomes a solid ink ("bone") plate, often with a `//` lead.
4. **Three typefaces with fixed jobs.** Fraunces (serif) for time, titles, bylines; Space Grotesk for values and language; the user's Omarchy monospace for labels; Noto Sans/Serif CJK JP for kanji.
5. **Hairlines, not shadows.** Dividers, frames and edges are 1 px ink lines.
6. **One baseline.** Every zone sits on the same text baseline at every height.

### The twenty-six settings (`core/Style.js` `OPTIONS`; **bold** = Kamon default)

Values marked † are the right-side studies (`docs/right-side/`, §9 "The right side, four ways"). Values marked ‡ came from Shōji (S3 of "Shōji into Hanko", §10), drawn with its parts in its skin.

| Zone | Key | Options |
|---|---|---|
| Left | `seal` | **`stamp`**, `workspace`, `carved`‡, `none` (plus free-text `sealGlyph`, default 鑑; the four Kan 鑑 漢 観 寛 offered) |
| Left | `spaces` | `folio`, `layout`, **`kanji`**, `dots`, `brush`‡ |
| Left | `title` | `cell`, **`byline`**, `ink`‡, `none` |
| Centre | `clock` | **`stacked`**, `inline`, `mono`, `season`‡ |
| Centre | `clockAt` | **`center`**, `right` |
| Centre | `media` | `cell`, **`underline`**, `ink`‡, `none` |
| Right | `status` | **`cells`**, `glyphs`, `numerals`, `ink`‡, `ma`†, `shizuka`†, `suji`†, `inro`† |
| Right | `meters` | **`ticks`**, `off` |
| Right | `notif` | `count`, **`stamps`**, `seal`‡ |
| Right | `bluetooth` | **`device`**, `marks`, `count`, `off` (added after Typeset; `on` reads as `device`) |
| Right | `indicators` | `all`, **`active`** (added after Typeset; Omarchy's six indicators as stamps) |
| Right | `indicatorStyle` | `icon`, `kanji`, `iconname`, **`kanjiname`** (added after Typeset; `full` reads as `iconname`) |
| Edge | `edge` | `hairline`, `dayrule`, `rod`, **`rodrule`** |
| Edge | `rules` | **`on`**, `off` |
| Edge | `pointer` | **`plain`**, `brush`‡ (added with Shōji) |
| Frame | `height` | `32`, `36`, **`40`**, `44` |
| Frame | `surface` | **`solid`**, `glass`, `inset`, `washi`‡ |
| Frame | `position` | **`top`**, `bottom` |
| Frame | `form` | **`bar`**, `inkan` (Inkan 印, the seal only: `docs/shell-concepts/inkan/`) |
| Frame | `inkanAt` | `top-left`, `top-right`, `bottom-left`, **`bottom-right`** (where Inkan's seal sits) |
| Panels | `panels` | **`sheets`**, `scroll` |
| Panels | `interlude` | `ma`, `hairline`, `folio`, `kotoba`, `tsugime`, **`seal`**, `jiku`, `fuda`, `su` (added after Typeset; what sits between scroll sections) |
| Panels | `endleaf` | `okugaki`, **`koyomi`**, `kiki`, `shimai`, `iro`, `dougu`, `shuchu`, `hikae`, `batsu` (added after Typeset; the leaf right of Inbox on the scroll) |
| Panels | `sides` | `bare`, **`curl`** (added after Typeset; the scroll's left and right edges, in place of the rollers) |
| Panels | `guides` | `both`, `tabs`, `foot`, **`none`** (added after Typeset; the scroll's index plate and position bar) |

### Presets

| Setting | Quiet | Islet | Shōji | **Kamon** (default) |
|---|---|---|---|---|
| seal | stamp | workspace | carved | stamp |
| spaces | dots | kanji | brush | kanji |
| title | none | byline | ink | byline |
| clock | inline | inline | season | stacked |
| clockAt | center | center | center | center |
| media | none | underline | ink | underline |
| status | numerals | glyphs | ink | cells |
| meters | off | ticks | off | ticks |
| notif | count | stamps | seal | stamps |
| bluetooth | off | marks | device | device |
| indicators | active | active | active | active |
| indicatorStyle | icon | icon | icon | kanjiname |
| edge | hairline | rodrule | hairline | rodrule |
| rules | off | off | off | on |
| pointer | plain | plain | brush | plain |
| height | 32 | 36 | 40 | 40 |
| surface | glass | inset | washi | solid |
| position | top | top | top | top |
| panels | sheets | scroll | sheets | sheets |
| interlude | ma | fuda | ma | seal |
| endleaf | batsu | dougu | koyomi | koyomi |
| sides | bare | curl | bare | curl |
| guides | both | both | both | none |

The four right-side studies are presets too (**Ma**, **Shizuka**, **Suji**, **Inrō**): the Kamon column with `status` set to `ma`, `shizuka`, `suji`, `inro`, `meters: off`, `indicatorStyle: kanji`; Ma also has `rules: off`, `height: 36` and `interlude: fuda` (the user's own bar). Sheet, Scroll and Instrument were taken out (aliases: Sheet and Instrument load Kamon, Scroll loads Islet). **Inkan** 印 is Kamon with `form: inkan` (its own group on the Presets page). COMPONENTS.md §4 has the table.

### Where options interact (COMPONENTS.md §3)

- `height: 32`: two-line cells (title, media, status, inbox count) collapse to one line, label then value; the stacked clock puts the date beside the time; the seal shrinks to 22 px. *(Done.)*
- `status: numerals` + `ticks`: a five-tick ruler after each quantity. `glyphs` + `ticks`: a four-tick ruler; network keeps its name, no bars. *(Done.)*
- `clockAt: right`: clock goes after notifications with a divider; the centre is left empty on purpose. *(Done.)*
- `edge: dayrule|rodrule` + `clockAt: right`: the now-notch stays at the real hour, no longer under the clock. *(Done: the notch always sits at the hour.)*
- `position: bottom`: `dayrule`, `rod`, `rodrule` draw along the bar's **top** side; the scroll unrolls **upward** and its index plate moves to the bottom; sheets rise instead of drop. *(Phases 5–7.)*
- `surface: inset`: the edge runs inside the frame, 10 px from each end (rod 14 px, as the kit draws it); a `hairline` edge is dropped since the frame is one. `glass`: stamps, seal and inverted plates stay opaque; only the paper is translucent. *(Done.)*
- `seal: workspace` + `spaces: kanji`: the active kanji shows twice, intentionally.
- `seal: none`: left zone starts at 14 px padding, first divider dropped.
- `title: none` + `media: none`: identity, clock and status only (Quiet).
- `panels: sheets` + `edge: rod`: dragging the rod opens the sheet for the cell under the pointer; `Super+Space` opens Time. `panels: scroll` without a rod edge: `Super+Space` or a click on any status, clock or stamp unrolls the scroll; hovering the bottom edge shows a thin pull tab. *(Phases 6–7.)*

### Config file

`~/.config/hanko/style.json` (XDG_CONFIG_HOME aware), outside the plugin folder so updates never touch it:

```jsonc
{ "preset": "Hanko", "edits": { "clock": "inline" }, "sealGlyph": "鑑", "motion": "paper",
  "hidden": ["tray", "hosted:omarchy.weather"],
  "monitors": { "DP-2": { "height": 32, "spaces": "dots" } } }
```

Resolution: preset → `edits` → `monitors[name]`. Invalid keys/values are dropped with a warning (`Typeset.warnings`).

### Mockups

`docs/mockups/typeset/*.webp` (19 sheets; index in COMPONENTS.md §8) are the visual target for every phase. Compare each phase's render against the matching sheet. The HTML kit that drew them is `docs/mockups/typeset/source/` (`cat.html`, `desk.html`, `studio.html`, `typeset.css`, `typeset.js`, `shootq.mjs`), rendered with Node + Playwright:

```sh
cd docs/mockups/typeset/source
node shootq.mjs "file://$PWD/cat.html?page=status&theme=gruvbox" out.png
node shootq.mjs "file://$PWD/desk.html?preset=Quiet&o={\"spaces\":\"kanji\"}&panel=sheet-time" out.png
```

`cat.html` pages: `identity | time | status | signals | edge | frame | presets | shuffle | themes`. `desk.html` takes `preset`, `theme`, `o` (JSON overrides), `panel` (`sheet-sound`, `sheet-time`, `scroll-0`…`scroll-5`) and `wins=1`. When a phase needs a detail the sheets don't show (sheet contents, scroll sections), read the HTML/CSS in this kit: it is the exact design.

Sheet and Scroll mockups: `docs/mockups/sheet/`, `docs/mockups/scroll/`.

## 6. How a bar plugin plugs into Omarchy

Facts from the Omarchy source (`manual/32-shell-plugins.md`, `docs/omarchy-shell.md`, `shell/shell.qml`, `shell/services/Plugin*.qml`, `shell/plugins/`). Re-check them against the current Omarchy source before relying on them; Omarchy moves fast.

### Loading

- Omarchy's desktop is **one long-running Quickshell process**, `omarchy-shell`. A bar plugin runs inside it. **Never start a second Quickshell.**
- Plugin = folder with `manifest.json` at its root, in `~/.config/omarchy/plugins/hanko.bar/`. Our manifest: `schemaVersion: 1`, `id: "hanko.bar"`, `kinds: ["bar"]`, `entryPoints.bar: "Bar.qml"`, version `0.1.0`, author `AyushKr2003`.
- `omarchy plugin add <git-url>` installs; `omarchy bar use hanko.bar` selects it (sets `bar.id` in `shell.json`); `omarchy plugin validate .` checks the manifest like the shell does. Saving a file in the plugin folder hot-reloads it. If the bar fails to load, the shell falls back to `omarchy.bar`.

### What the host injects into `Bar.qml`

`omarchyPath`, `shell`, `manifest`, `barWidgetRegistry`, `pluginRegistry`, `barConfig`. A third-party bar gets **facades**:

- `shell` is a `PluginShellApi` (`shell/services/PluginShellApi.qml`): `firstPartyServiceFor(id)`, `pluginShellForBarEntry(owner, module)`, `summon(id, json)`, `hide(id)`, `toggle(id, json)`, `isPluginOpen(id)`, `updateEntryInline(id, settings)`, `mutateShellConfig(fn)`.
- `firstPartyServiceFor(id)` returns a narrow proxy (`shell/services/PluginFirstPartyServiceApi.qml`) **only** for `omarchy.idle`, `omarchy.media`, `omarchy.nightlight`, `omarchy.notifications`. The proxy has: `stayAwake`, `enabled`, `doNotDisturb`, `activePlayer`, `sourcePlayers`, `setIdleEnabled(v)`, `setNightlight(v)`, `setDoNotDisturb(v)`, `runAction(action, showFeedback, playerKey)` (`playPause|next|previous`), `playerKey(p)`, `selectPlayer(key)`. **There is no proxy for audio, network, battery or the notification list.** The notifications proxy gives do-not-disturb only.
- `barConfig` is a detached copy of `shell.json`'s `bar:` subtree (`position`, `layout.left|center|right` arrays of `{id, ...}`, `transparent`, …).

### What the host reads back from the bar

Properties `barHidden`, `barSize`, `position`, `fontFamily`; functions if present:

- `summonBarWidget(id)`, `hideBarWidget(id)`, `isBarWidgetOpen(id)`: **the host routes `shell toggle <id>` for any plugin whose kinds include `bar-widget` (and not panel/overlay/menu) to these.** Omarchy's `omarchy.audio`, `omarchy.network`, `omarchy.power` and `omarchy.clock` panels are all kind `["bar-widget"]`. So when Hanko is the bar, `omarchy-shell shell toggle omarchy.audio` (and the Omarchy hotkeys that do the same) **only work if Hanko implements `summonBarWidget`**. See §12, issue 1.
- `panelWidgetIdAt(section, index)`: used by `omarchy-shell shell togglePanelAt right N` (Omarchy's hotkeys in `default/hypr/bindings/utilities.lua`).
- `toggleTransparency()`: called by IPC `shell toggleBarTransparency`.
- `debugBarGeometry()`.
- Reference implementation of all of these in a third-party bar: `omacale/Bar.qml` (around line 263) and `omacale/modules/bar/BarWidgetSlot.qml` / `PluginBarFacade.qml`.

### Hiding

`omarchy toggle bar` writes `~/.local/state/omarchy/toggles/bar-off`, then calls IPC `omarchy.bar syncHidden`. Hanko registers that IPC target and also watches the toggles directory. *(Done in Phase 1.)*

### Data sources Hanko uses (and why)

| Data | Source | Action |
|---|---|---|
| Workspaces, windows, monitors | `Quickshell.Hyprland` (`Hyprland.workspaces/toplevels/monitors`, `toplevel.lastIpcObject` = `at`, `size`, `floating`, `focusHistoryID`, `workspace`; monitor `lastIpcObject` = `x,y,width,height,scale,transform,reserved[l,t,r,b]`), refreshed with `Hyprland.refreshToplevels()` / `refreshMonitors()` on `rawEvent` | `Hyprland.dispatch('hl.dsp.focus({ workspace = "3" })')` (**Lua dispatch syntax**; values escaped with `luaStr`); `"r+1"`/`"r-1"` to step |
| Media | `omarchy.media` proxy `activePlayer`, else `Quickshell.Services.Mpris` | proxy `runAction`, else MPRIS directly |
| Volume | `Quickshell.Services.Pipewire` `defaultAudioSink`, resolved through any DSP sink to the physical one with `omarchy-audio-output-sink` (same as Omarchy's audio panel); `PwObjectTracker` binds it | `omarchy-audio-output-volume +5 / -5 / mute-toggle` (shows Omarchy's OSD) |
| Battery | `Quickshell.Services.UPower` `displayDevice` (`isPresent`, `isLaptopBattery`, `percentage` 0..1), `UPower.onBattery` | — |
| Network | `omarchy-network-status` (prints `kind\tname\tsignal\tfreq`, kind = `wifi|ethernet|disconnected`), polled every 3 s | — |
| Brightness | `brightnessctl -m -c backlight` only when `/sys/class/backlight/*` exists (laptops) | `omarchy-brightness-display +5% / 5%-` |
| Notifications | Omarchy's notification service writes each live toast to `~/.local/state/omarchy/notifications/*.json` and keeps the last 10 in `…/notifications/history/*.json`, one compact JSON object per file (`{id, originalId, app, appIcon, summary, body, image, glyph, execArgv, urgency (2 = critical), expireTimeout, timestamp}`). Hanko reads both with `awk 1`. DND from the proxy, else `~/.local/state/omarchy/notifications.json` `{dnd}` | `omarchy-shell notifications showHistory` (replays recent as toasts), `toggleDnd`, `clear`, `isDnd`; proxy `setDoNotDisturb` |
| Omarchy menu | — | `omarchy-shell shell toggle omarchy.menu '{"menu":"root"}'` |
| Terminal | — | `xdg-terminal-exec` |
| 12/24 h | `barConfig.layout.*[]` entry with `id: "omarchy.clock"` and its `format` | — |
| Weather (scroll leaf) | Same as Omarchy's weather panel: place from `~/.local/state/omarchy/settings/weather.json` `{name, latitude, longitude}` (FileView), else `curl https://wttr.in/?format=j1` `nearest_area`; forecast `curl` Open-Meteo (`Weather.url`); units from the `omarchy.weather` entry's `unit`, else country, else `Qt.locale().name`. Every `refreshMinutes` (default 15), only while the scroll is open; the last answer is kept on failure | — |
| Theme | `qs.Commons` `Color.foreground`, `Color.background`, `Color.urgent` (= theme red); live on theme switch. `Style.font.family` (mono), `Style.font.body` (base size; Hanko scales by `body/12`) | — |

Other Omarchy panels that exist (`shell/plugins/panels/`): audio, bluetooth, clock, disk-speedtest, dropbox, elsewhen, monitor, network, power, speedtest, tailscale, weather, wifiqr.

### Fonts

Every kanji is drawn in **Yuji Boku**, a brush face bundled as `assets/fonts/YujiBoku.ttf` (SIL OFL), subset to the kanji and kana in Hanko's sources plus the four Kan (re-subset with `pyftsubset` when new kanji are added; anything missing falls back to the system's `noto-fonts-cjk`, which Omarchy installs). `Type.jp` and `Type.jpSerif` both resolve to it (`Type.brush`). Hanko also bundles **Fraunces** (+ Italic) and **Space Grotesk** under `assets/fonts/` (SIL OFL, licence files alongside) and loads them with `FontLoader`. The mono face is `Style.font.family` (what `omarchy font set` controls).

## 7. Code map

Everything is plain QML/JS, no build step.

```
manifest.json            plugin manifest (hanko.bar, kind bar)
style.lua                Hyprland look'n'feel for windows (dofile'd from ~/.config/hypr/looknfeel.lua)
Bar.qml                  entry point: injected props, host contract, per-screen windows,
                         hiding, proxy bindings, `hanko` IPC
bar/
  BarWindow.qml          one layer-shell PanelWindow per screen (namespace "hanko-bar",
                         WlrLayer.Top, exclusive, parks off-screen when hidden);
                         feeds BarSurface with live data and routes its signals to services
  BarSurface.qml         PURE QtQuick: everything drawn inside the bar, from a resolved
                         style + plain data. The test harness renders this directly.
                         Left Row (Seal, Divider, Workspaces, Divider, WindowTitle),
                         centre Clock, right Row (NowPlaying, Divider, StatusRow, Divider,
                         Inbox, Divider, right Clock), hairline edge.
                         Inline component Divider { ruled }.
  Seal.qml               stamp | workspace (kanji numeral) | none
  Workspaces.qml         folio | layout | kanji | dots, urgent dot, click + wheel
  WindowTitle.qml        cell | byline | none (+ compact one-line cell)
  Clock.qml              stacked | inline | mono, timeFormat, colon inked
  FadeText.qml           a Text whose new value fades through (Motion.fade)
  NowPlaying.qml         underline (progress underline) | cell | none
  StatusRow.qml          cells | glyphs | numerals × ticks | off; Wi-Fi bars; red rule
  Inbox.qml              count | stamps (tilted seals, fan on hover), DND state
  SheetWindow.qml        the layer a sheet is printed on (see Phase 6 in §9); under
                         Inkan it prints from the seal and lifts off
  SealWindow.qml         Inkan's layer: the seal in its corner, no exclusive zone, input
                         only on the seal (mask); press, drag to a corner, hover reading
  InkanSeal.qml          Inkan's seal, pure: plate, chips, inner rule, glyph, wear specks,
                         the recording ring, press and bloom
  InkanReading.qml       the hover line beside the seal, pure
  ScrollWindow.qml       the layer the handscroll unrolls on (see Phase 7 in §9)
  OverviewWindow.qml     the layer the workspace overview 一覧 is laid on, one per screen
  overview/              OverviewView, OverviewPage (grid); DynamicView, DynamicCell,
                         DesktopStrip (dynamic, Ryoku's) — all pure
  SettingsWindow.qml     the settings window (see Phase 8 in §9)
  settings/              SettingsPage, SettingsCard, Segmented, Plate, PreviewBar,
                         PresetsPage; Typesetting's proof: Galley (the bar in two
                         lines, numbered), TypeCase (a part's case), Specimen (one
                         way, the real bar cropped to the part) (all pure); the
                         plates ProfilePlate, AboutPlate, CreditsPlate with their art
                         (SealImpression, HangingScroll) and parts (PlateEyebrow,
                         PlateSpine, LeaderRow)
  parts/                 Shōji's parts (Kata K3), pure, each takes `skin` (Skin.js):
                         Surface, Fibres, Divider, Selection,
                         KataSlider, Ring, KataSeal, UnreadMark, PointerMark, Sign,
                         Letter, Hold, Choice, KataSwitch, Icon, InkShape
  HostedSlot.qml         one hosted widget from the registry (see Phase 9 in §9)
  HostBar.qml            the `bar` facade hosted widgets see
  Marks.qml              Hanko's own indicators, keyboard, mic and tray marks
  scroll/                ScrollView, ScrollSection, ListRow, Fader, SignalBars, Interlude;
                         Time/Sound/Network/Power/Display/Spaces/InboxSection (all pure)
  sheets/                SheetView, SheetCard, SheetHead, GroupHead, SheetRow, Ruler,
                         SheetButton, ActionBar; TimeSheet, SoundSheet, NetworkSheet,
                         PowerSheet, DisplaySheet, InboxSheet (all pure); the Tanzaku
                         sheets; HandSheet + ShogiHand, SorobanHand, OdoshiHand,
                         KasumiHand (one per craft hand, drawing core/Hands.js's model);
                         ShojiPanel (the Shōji hand's frame: washi, rail, sign) and its
                         Time/Sound/Network/Bluetooth/Power/Display/LettersPanel, with
                         KataList, Figure, Heading, SessionRow (moved from bar/kata/)
  Edge.qml               hairline | dayrule | rod | rodrule, mirrored at the bottom,
                         inset-aware; rod grip lifts on hover, drag emits pulled()
core/
  Ink.qml   (singleton)  paper, ink, inkDim, inkMuted, inkFaint, seal, bone, boneInk,
                         line, lineSoft, lineStrong, light, alpha(), paperAt()
  Type.qml  (singleton)  FontLoaders; display (Fraunces), text (Space Grotesk), mono,
                         jp, jpSerif; scale (Omarchy's body / 12 × typeSize); px();
                         the type scale: tag label eyebrow figure note value row byline
                         clock title hero gloss glossMid glossBig, track*, labelWeight,
                         valueWeight, valueAxes, axes(size, wght) for Fraunces
  Motion.qml (singleton) every timing and curve (Scroll mockup 05); still (motion: still
                         or Omarchy's reduced motion), live (awake and not still), ms()
  Skin.js                SHOJI (Shōji's part variants), fromStyle(style) (the skin for a
                         resolved style: its season, numerals, grain, panel opacity),
                         skin(k) → tokens for the parts: radius/radiusRow/radiusChip,
                         joints, open/openCurve/leave/leaveCurve, settle, opacity, grain,
                         season, kanjiNumerals, gap, travels; TEMPOS, RADII, OPACITY
  Season.js              SEKKI (24), KO (72), sunLongitude, koIndex, at(date), label(date,
                         off|kanji|english): exact, from the sun (Leaf.js's are date tables)
  Brush.js               stroke(w, h, seed), kasure(w, h, seed), enso(v, size, width, seed):
                         SVG paths for PathSvg
  Typeset.qml (singleton) style.json FileView + watch; doc, warnings, current,
                         ownsPosition; styleFor(monitor), set, applyPreset, reset,
                         setSealGlyph, shuffle, serialized; debounced save (200 ms)
  Style.js               OPTIONS, KEYS, PRESETS, PRESET_NAMES, DEFAULT_PRESET, coerce,
                         normalize, resolve(doc, monitor), withSetting, withPreset,
                         shuffled(doc, rng), combinations(); MOTIONS (motion and
                         sealGlyph sit beside the edits, outside the twenty-two)
  InkMath.js             hexToRgb, mix, luminance, contrast, tier, isLight, ramp (TIERS)
  Title.js               appName (NAMES map, reverse-DNS), describe(cls, title) →
                         {app, head, dir, leaf}, findPath, tildify
  Spaces.js              numeral (壱 弐 参…), folio, layoutOf(windows, area),
                         usableArea(monitor), list(workspaces, activeId, min=5)
  Inkan.js               Inkan 印: wear (battery), specks/worn, chips (letters), carving,
                         live (recording), reading (hover line), rows (No. 00), place,
                         sheetPlace, nearest (drag), CORNERS, SIZE, MARGIN, SHEET_GAP
  Sheets.js              SHEETS (key, kanji, width, anchor cells, Omarchy ids), ALL (No. 00), forCell,
                         forOmarchyId, step (Tab), panelAt, place (x + tear)
  Hosted.js              which layout entries are drawn, own, or hosted
  Extras.js              indicators, keyboard (hyprctl devices), tray rows
  Settings.js            RAIL, CARDS, MOTION_CARD/ROWS, PRESET_BLURBS, GLYPHS, nameOf,
                         changes, status, search; the proof: PROOF, WAYS, ALSO,
                         PANELS_CARD, proofEdits/Matches/Step/PartOf, SAMPLE_INDICATORS
  Scroll.js              SECTIONS, layout, centred, nearest, clampTrack, landing,
                         position, forCell; BAYER/fbm noise for the settings plate
  Time.js                heading, ribbon, isoWeek, Elsewhen zones + date probe rows
  Sound.js / Net.js / Power.js / Display.js   plain rows for those sheets
  Edge.js                dayFraction, hourTicks, at (pixel snap), span (rod/inset
                         padding), pulled(dy, atBottom), PULL_THRESHOLD 24
  Status.js              ticks, bars, network, volume, battery (LOW_BATTERY 15),
                         brightness, stampGlyph (+ STAMP_KANJI), tilt, notifications,
                         count2
  qmldir                 singletons Ink, Type, Typeset
services/
  Hypr.qml  (singleton)  workspaces/windows per monitor, spacesFor(screen), activeWindow,
                         focusWorkspace, stepWorkspace, openMenu, openTerminal
  Media.qml (singleton)  proxy | MPRIS, `now` = {title, artist, progress, playing}, act()
  Status.qml (singleton) volume, battery, network, brightness, notifications,
                         doNotDisturb; act(name, how) for click/middle/right/up/down
  Extras.qml (singleton) indicators, keyboard, mic and tray for Marks
  Zones/Sound/Net/Power/Display.qml (singletons) data for the sheets, gathered only while
                         their sheet is open (`wanted`, bound in Bar.qml)
  qmldir                 singletons Hypr, Media, Status, Zones, Sound, Net, Power
scripts/hanko            CLI: install | dev | uninstall | style get|doc|set|preset|reset|
                         shuffle | doctor (style commands go over IPC `omarchy-shell hanko …`;
                         uninstall restores the bar saved in ~/.local/state/hanko/previous-bar)
assets/fonts/            Fraunces.ttf, Fraunces-Italic.ttf, SpaceGrotesk.ttf + OFL texts
tests/
  run                    unit tests → manifest check → qmllint → renders (--quick skips renders)
  unit.mjs               Node tests for core/*.js (60 tests)
  harness/render.py      PySide6 offscreen renderer (QT_SCALE_FACTOR=2)
  harness/scenes/Strips.qml  a sheet of labelled BarSurface strips from a params JSON
  harness/params/*.json  one per phase (phase1, phase2, phase2-light, phase3, phase4, phase5, phase5-light); a strip may set `now` (its own time) and `backdrop: true` (stripes behind the bar, for glass)
  harness/stubs/         fake Quickshell, Quickshell.Io/Hyprland/Wayland/Services.*,
                         qs.Commons, just enough to lint and render
docs/                    ROADMAP, COMPONENTS (spec), DESIGN, HANDOFF (this), history/,
                         mockups/{sheet,scroll,typeset}
```

**IPC target `hanko`** (Bar.qml): `press` (Inkan's seal: No. 00, or lift it off), `version`, `styleGet`, `styleDoc`, `styleSet(key, value)`, `stylePreset(name)`, `styleReset`, `styleShuffle`, `warnings` (Kata's `design*` and `touch` went with the design switch; `styleSet season english` and `stylePreset shoji` do their work). All typed, all return strings.

**Data flow:** services (live Quickshell data) → `BarWindow` (per screen, picks `Typeset.styleFor(screen.name)`) → `BarSurface` props (plain JS objects) → components. Components never import services. This is what lets the harness render any state, and it is the pattern to keep for every new part.

**Params JSON shape for the harness** (`tests/harness/params/*.json`): `{ title, width, theme: {foreground, background, red}, now, spaces, window, media, volume, network, battery, brightness, notifications, dnd, strips: [ { label, doc: {preset?, edits}, …any per-strip override of the sheet-level values… } ] }`.

## 8. Dev environment from scratch

There is **no Omarchy machine** in the cloud session. Everything is verified with unit tests, `qmllint`, and offscreen renders compared by eye against the Typeset mockups.

```sh
# 1. The repo (cloud sessions used /tmp/claude-0/hanko)
git clone -b dev https://github.com/AyushKr2003/hanko.git && cd hanko

# 2. Read-only references, in a scratch folder (cloud used /tmp/claude-0/src)
mkdir -p ../src && cd ../src
git clone -q --depth 1 -b unstable-dev https://github.com/Ryoku-dev/ryoku.git
for r in omacom/omarchy AyushKr2003/omacale HANCORE-linux/Shibumi-Shell gitcoder89431/ruixen-shell; do
  git clone -q --depth 1 https://github.com/$r.git
done
cd ../hanko

# 3. Qt for lint and renders
apt-get install -y libegl1 libgl1 libxkbcommon0 libfontconfig1 libdbus-1-3   # (apt-get update first if it fails)
python3 -m pip install PySide6-Essentials

# 4. Fonts for the harness (Noto JP + a mono face); Fraunces/Space Grotesk come from assets/
mkdir -p ../hfonts && cd ../hfonts
curl -sSfL -o NotoSerifJP.ttf   "https://raw.githubusercontent.com/google/fonts/main/ofl/notoserifjp/NotoSerifJP%5Bwght%5D.ttf"
curl -sSfL -o NotoSansJP.ttf    "https://raw.githubusercontent.com/google/fonts/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf"
curl -sSfL -o JetBrainsMono.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"
cd ../hanko
export HANKO_HARNESS_FONTS=$PWD/../hfonts

# 5. Run everything
tests/run            # unit, manifest, qmllint, renders → tests/out/*.png
tests/run --quick    # unit + lint only
OMARCHY_SRC=../src/omarchy tests/run   # use Omarchy's real manifest validator
```

**Expected lint output:** only these stub-typing warnings, which are fine: `core/Type.qml` `Member "family"/"body" not found on type "QObject"`, and `Member "values" not found` in `services/Hypr.qml`, `Media.qml`, `Status.qml`. Anything else is new and must be fixed. `bar/BarWindow.qml` warnings are filtered (the stubs don't model layer-shell attached properties).

**Lint does not catch everything.** A render failing to load is the real check (it caught the `gc` id clash). Always run the full `tests/run`, then open `tests/out/phaseN.png` and compare with the Typeset mockup.

**On a real Omarchy machine** (the user's): `scripts/hanko dev` symlinks the checkout and selects it (edits hot-reload), `scripts/hanko style preset Sheet` switches look, `scripts/hanko uninstall` restores the previous bar, `scripts/hanko doctor` checks the install. Logs: `journalctl --user -f` or the omarchy-shell log for QML errors.

## 9. Phase status and what each phase built

Status lives in [ROADMAP.md](ROADMAP.md) too (✅ / 🔨 / ⬜); keep both in sync.

### Phase 0 · Roadmap and scaffolding ✅ (`5bb25e3`, roadmap `4abd0cb`)
- `docs/ROADMAP.md`, Node tests for style resolution and the ink ramp, `qmllint` with stubs, the PySide6 offscreen render harness.

### Phase 1 · A bar that loads ✅ (`101a6b6`)
- `manifest.json`, `Bar.qml`, `core/` singletons (Ink, Type, Typeset), bundled fonts.
- One `PanelWindow` per screen via `Variants` over `Quickshell.screens`; reserves its height (`ExclusionMode.Auto`), parks at a negative margin when hidden (`ExclusionMode.Ignore`).
- Host contract: `barHidden`, `barSize` (= `Type.px(height)`, 0 when hidden), `position` (Hanko's own when the style sets it, else `barConfig.position`, top/bottom only), `fontFamily` (= mono).
- Seal (`stamp`) and stacked clock on paper with a hairline edge.
- `scripts/hanko` CLI and the `hanko` IPC target.

### Phase 2 · Left zone ✅ (`49e1d5b`)
- `services/Hypr.qml`; `Seal` all three modes (click = menu, right-click = terminal, wheel = step workspace); `Workspaces` all four modes from real Hyprland data (layout mode draws each workspace's real tiling scaled into a 24×15 glyph, focused window filled; urgent red dot); `WindowTitle` cell/byline/none with `Title.js` app-name cleanup and receding path, `~` for home.
- Renders: `phase2.json`, `phase2-light.json` (Flexoki-light-like theme).

### Phase 3 · Centre ✅ (`528154b`)
- `Clock` stacked/inline/mono, at centre or right; follows Omarchy's 12/24-hour clock format.
- `services/Media.qml` + `NowPlaying` underline/cell/none; paused media dims a tier; click = play/pause, middle = next, wheel = previous/next; position ticks every second while playing.

### Phase 4 · Right zone ✅ (`bb1cc08`)
- `core/Status.js`, `services/Status.qml`, `bar/StatusRow.qml`, `bar/Inbox.qml`.
- Status cells/glyphs/numerals × ticks/off, Wi-Fi bars, brightness on laptops, charging shows 充 instead of 電, the red rule (muted, battery ≤ 15 % and draining, offline).
- Notifications count (`INBOX 03` + red dot; `QUIET 静` + hollow ring under DND) and stamps (up to 3, tilt −6…6° from a hash, newest on top, fan out on hover, urgent ones solid; grey under DND). Click = `showHistory`, right/middle = toggle DND.
- Status clicks called `omarchy-shell shell toggle omarchy.audio|…` as a stand-in; Phase 6 replaced that with Hanko's own sheets.

### Phase 5 · Edge and frame ✅ (`7834503`)
- `core/Edge.js` (+5 unit tests) and `bar/Edge.qml`, replacing the plain hairline. All four edges from the kit's CSS (`scroll.css` `.rod`, `sheet-parts.css` `.dayrule`, `typeset.css` `.rodrule`): day rule = base `line`, spent part `lineStrong`, ticks 3 px (6/12/18 h 5 px, `lineStrong`), red now-notch 2×7 px with a 3 px head; rod = 2 px `lineStrong`, 6 px `inkMuted` caps, 34×4 paper grip; rodrule adds the spent part in `inkMuted`, ticks above the rod and an 8 px notch. Nothing changes the bar's height (the kit draws edges inside the bar), so `barSize` is unchanged. The rod sits 2 px up so its caps fit inside the window.
- At `position: bottom` the edge is mirrored as a whole onto the top side.
- Rod interaction: an 8 px band along the edge; hover lifts the grip 2 px, pressing inks the rod, a drag of 24 px (scaled) away from the bar emits `pulled()` → `BarSurface.edgePulled` → `Bar.edgePulled(screenName)`, which has no receiver until Phase 7.
- Inset: `BarWindow` sets 8 px margins on the anchored edge and both sides (hidden: parks at `-(height + 8)`); the paper gets a 1 px `Ink.line` frame with 7 px corners (the kit's `typeset.css`; COMPONENTS.md says 3 px, the rendered sheets show 7, the sheets won).
- Transparency: `Bar.transparent` follows `barConfig.transparent`; `toggleTransparency()` writes `bar.transparent` through `shell.mutateShellConfig` exactly like Omarchy's own bar (falls back to a session-only flip). `BarWindow.shown` turns `solid` into `glass` while it is on; glass and inset are left alone. style.json is never written.
- Blur: Omarchy requests no blur for its own bar (no layer rule in `default/hypr/apps/omarchy-shell.lua`), so Hanko doesn't either; README documents a `hl.layer_rule` for namespace `hanko-bar`.
- Harness: `phase5.json` (every edge × top/bottom, day rule at 00:30/06:00/21:44, rodrule + clock right, rules off, four heights, three surfaces over a backdrop, inset bottom and inset hairline, four presets) and `phase5-light.json`.

### Phase 6 · Sheets ✅ (`f847cf5` time, `e17e2ff` sound, `1cff267` network/power/inbox)
- **Host contract** in `Bar.qml`: `summonBarWidget(id)` (opens, never toggles), `hideBarWidget`, `isBarWidgetOpen`, `panelWidgetIdAt("right", N)` (counts distinct Omarchy panels among `BarSurface.rightCells`). Mapping in `core/Sheets.js`: `omarchy.clock`/`omarchy.elsewhen` → time, `omarchy.audio` → sound, `omarchy.network` → network, `omarchy.power` → power. State: `Bar.sheet`, `sheetScreen`, `timeShift`; `openSheet/closeSheet/toggleSheet/cycleSheet/sheetRequest`. IPC `hanko sheet <name>` / `hanko sheetClose`.
- **Clicks**: `BarWindow.cellClicked` sends a left click on the clock, a status cell or the inbox to `toggleSheet`; other buttons and the wheel keep their Phase 3–4 actions. `panels: scroll` opens sheets until Phase 7.
- **`bar/SheetWindow.qml`** (one per screen, inside `BarWindow`): Omarchy's `KeyboardPanel` pattern. Full-screen layer `hanko-sheet` on `WlrLayer.Overlay`, input mask minus the bar strip, Exclusive keyboard for 75 ms then OnDemand, a closer `MouseArea` behind the sheet, clear twins on other screens. Keeps the last sheet mapped 220 ms so it can un-print.
- **`bar/sheets/`** (pure): `SheetView` (Loader per key, 180 ms reveal, Esc/Tab), `SheetCard` (paper, three hairlines, bone tear, crop marks, clip reveal), `SheetHead`, `GroupHead` (summary or clickable `actions`), `SheetRow` (lead, bone selection, note, `trailing` slot), `Ruler` (41 ticks, one needle; dashed when muted), `SheetButton` (plain/ghost/plate/on), `ActionBar` (note gives way to buttons); contents `TimeSheet`, `SoundSheet`, `NetworkSheet`, `PowerSheet`, `InboxSheet`, each its own component for Phase 7 to reuse.
- **Data**: `core/Time.js` + `services/Zones.qml` (Elsewhen zones from `barConfig`, offsets by a `date` probe, as Elsewhen does); `core/Sound.js` + `services/Sound.qml` (plain node copies only; actions re-find nodes by id+name; availability via `omarchy-audio-sink-availability`); `core/Net.js` + `services/Net.qml` (nmcli terse output every 5 s while open; connect = `connection up` / `device wifi connect` / `nmtui-connect` in a terminal when a password is needed); `core/Power.js` + `services/Power.qml` (`omarchy-battery-status --shell`, `omarchy-powerprofiles-list/set`, `omarchy-brightness-display N%`); Inbox reads `Status.notifications` (now with `body`, deduped live/history) and `Status.age`.
- Omarchy no longer ships wiremix, so the Sound foot is Mute mic + Next output instead of the mockup's Settings/Mixer. No shadow under sheets (rule 5), though the kit drew one.
- Harness: `tests/harness/scenes/Sheets.qml` (a bar with a sheet placed by `Sheets.place`), params `phase6.json` (time, sound) and `phase6-b.json` (network, power, inbox); a params file picks its scene with `"scene"`. Unit tests: 43.

### Phase 7 · The handscroll ✅ (`5354f5e` paper, `34576c4` window and wiring)
- **`core/Scroll.js`** (+ tests): `SECTIONS` (time, sound, network, power, spaces, inbox; widths 600/660/540/420/700/560 at 12 px base, `INTERLUDE` 70), `layout(scale)`, `centred(i, viewW)` (track x putting a section in the middle), `nearest`, `clampTrack`, `landing(x, velocity)` (carry 0.18 s of speed, then nearest), `position(i)` (foot bar), `forCell`, and `sliver(w, h, seed)` (the kit's fbm + Bayer dither, as 0/1).
- **`bar/scroll/`** (pure): `ScrollView` (paper, its `sides` (bare, or a 22 px curl at each edge; the rollers with caps are gone), 120 px curls, index plate, foot with keys and position bar, `reveal` and `ink` 0..1; a pan `MouseArea` behind the sections emits `dragged(dx)`, `released(velocity)`, `stepped(±1)`), `ScrollSection` (red kanji, `02 // SOUND`, 46 px serif title, mono caption, 230 px watermark), `ListRow` (index, name/detail, note, bone plate, `leading`/`trailing` components), `Fader`, `SignalBars`, `Interlude` (Canvas painting `sliver` in `Ink.ink`), and the sections (eight since the Bluetooth panel). Sections send the same requests as the sheets (`Bar.sheetRequest`), plus `spaces` (`window` address → `Hypr.focusWindow`, `workspace` id) and `sound`/`input` (mic level).
- **`bar/ScrollWindow.qml`**: SheetWindow's layer pattern (namespace `hanko-scroll`). Width = screen minus 6.9 % each side (min 16 px), height 460 px scaled. Motion: `reveal` 300 ms bezier(.2,.9,.25,1), `ink` 120 ms delay + 200 ms bezier(.4,0,.2,1), `trackX` 260 ms bezier(.16,1,.3,1) except while dragging; closing reverses in 220/100 ms and unmaps after 320 ms. `Style.reduceMotion` (Omarchy's animations-off flag, from `qs.Commons`) sets every duration to 0. Keys: `H`/`L`/arrows/Tab pan, `1`–`6` jump, `Esc` rolls up; the wheel steps once per 260 ms.
- **State and routing** (`Bar.qml`): `scrollOpen`, `scrollScreen`, `scrollSection`; `openScroll/closeScroll/toggleScroll/scrollTo/stepScroll`; `openPanel/panelOpen/closePanel` pick sheet or scroll by the screen's `panels` style, so `summonBarWidget` and friends serve both. A sheet and the scroll never show together. `BarWindow.cellClicked` unrolls at the cell's section under `panels: scroll`; `rodPulled(x)` (Edge now reports where the pull started; `BarSurface.cellAt(x)`) unrolls the scroll, or under sheets drops the sheet of the cell under the pointer (Time otherwise). Every sheet service is `wanted` while the scroll is out. IPC `hanko scroll` (toggle, any `panels`) and `hanko scrollTo <section>`.
- **No `Super+Space`**: Omarchy binds it (and every `Super+…+Space`) already, and has no plugin hook for binds; README documents `o.bind("SUPER + CTRL + U", "Hanko scroll", "omarchy-shell hanko scroll")`.
- `Spaces.layoutOf` carries each window's `name` (`Title.appName`) and `address`. `Time.ribbon` takes a day count and names the months around it; `Time.ordinal`, `Time.counted`, `Time.dayAcross` (tomorrow/yesterday for a city). `Sound.sheet` adds `inputLevel` and each output's `bus`.
- Harness: `phase7.json` and `phase7-light.json` (the `Sheets` scene takes `scroll: true`, `current`, `reveal`, `ink`). `tests/run` now lints `bar/sheets` and `bar/scroll` too. Unit tests: 48.
- Not done from the Scroll motion sheet: the rod "lifting into a roller" as the paper drops (the paper simply unrolls under the bar) and the stamp press (done in Phase 10).

### Phase 8 · Settings window and CLI parity ✅ (`56cd19f` page, `0555318` window and CLI)
- **Draft** in `core/Typeset.qml`: `draft` (null or a document), `live = draft || doc`; `current`, `styleFor` and `ownsPosition` read `live`, so the real bar shows every edit at once. `draftSet(key, value)` (also `sealGlyph`), `draftPreset`, `draftMonitor`, `draftClearMonitor`, `draftReset` (edits dropped, glyph and monitors kept), `draftShuffle`, `save()` (commits the draft through the usual debounced write), `revert()`. `setFor(monitor, key, value)` saves a per-monitor value at once (CLI). A CLI `style set` while a draft is open changes `doc` but the bar keeps showing the draft until Save/Revert.
- **`core/Settings.js`** (+ tests): `RAIL` (four groups, eight pages), `CARDS` (six cards, every one of the settings once (16 since Bluetooth), plus the seal glyph), `PRESET_BLURBS`, `GLYPHS` (鑑 漢 観 寛; was 印 力 侍 A, then "…" for your own), `optionsFor`, `selected`, `changes(saved, draft, resolve)` (settings that resolve differently + glyph + each differing monitor), `status(n)`, `presetLine(doc)`, `matches(row, query)` and `pageMatches` for search. `core/Style.js` gained `withMonitorSetting(doc, monitor, key, value)` (drops an override equal to what the monitor would get anyway).
- **`bar/settings/`** (pure): `SettingsPage` (rail with masthead, search, groups, Advanced switch; page with eyebrow `鑑 BAR · PRESET · HANKO + EDITS`, 44 px title, preview over `Plate`, preset cards, a 3×2 `Grid` of `SettingsCard`s with each row of cards as tall as its tallest, an Advanced card with a glyph field, monitors and raw JSON; Presets page with six `BarSurface` strips and Shuffle; honest text for Colour, Widgets, Sheets, Scroll, Motion, Keys; action bar), `SettingsCard`, `Segmented`, `Plate` (dithered orb). Signals: `settingPicked`, `presetPicked`, `resetToPreset`, `revert`, `save`, `pagePicked`, `queryEdited`, `advancedToggled`, `monitorCleared`, `shuffle`. Note: `set` can't be a QML signal name.
- **`bar/SettingsWindow.qml`**: a Quickshell `FloatingWindow` (as Omarchy's dev gallery), 1600×900 scaled, min 420×360. `SettingsPage` reflows to any size (a tiled window ignores the minimum): cards go 3→2→1 columns (400 px each), presets 6→3→2, overrides 2→1, a card row stacks its control under its name when narrow, the preview bar lays out at least 1240 px wide and scales down, the rail narrows under 1100 px and folds to glyphs under 760 px (the search moves onto the page), and the rail scrolls on short windows; `/` searches, `Ctrl+S` saved (since K7 there is no Save: see K7 below), `Esc` clears the search then closes. `Bar.settingsOpen`, `openSettings()`, `closeSettings()`. IPC `hanko settings` and `hanko styleSetFor <monitor> <key> <value>`.
- **CLI** (`scripts/hanko`): `settings`, `scroll`, `style set --monitor NAME K V`, `menu add|remove`. Omarchy has no plugin hook for menu entries, but merges `~/.config/omarchy/extensions/omarchy-menu.jsonc`; `menu add` (explicit, never automatic) puts one marked line (`// hanko.bar`) right after the opening brace and keeps a `.bak`; `menu remove` deletes exactly that line.
- Harness: `tests/harness/scenes/Settings.qml`, params `phase8` (Hanko + 2 edits), `phase8-light`, `phase8-advanced` (Islet, 侍, DP-2 override), `phase8-presets`. `tests/run` lints `bar/settings` too. Unit tests: 53.

### Display panel 明 ✅ (asked for by the user after Phase 9)
- The LUM cell's own panel, as a sheet and as scroll section 05 (now 06, after Bluetooth). It also answers `omarchy.monitor` (Omarchy's Display panel, `Super+Ctrl+D`), so `omarchy.monitor` moved from hosted to `Hosted.DRAWN`. Brightness left the Power sheet.
- `core/Display.js` (+ tests): `monitors(hyprctl monitors all -j)` (focused first; "Built-in · eDP-1" for `^(eDP|LVDS|DSI)-`, model + name otherwise; "2560×1440 · 144 Hz · ×1.25"), `brightness(text)`, `target(list, picked)` (picked if on, else focused, else first on), `sheet(...)`. `services/Display.qml`: `hyprctl monitors all -j` and `omarchy-brightness-display --monitor NAME` every 5 s while open (and on monitor events); `setBrightness` sends `omarchy-brightness-display --no-osd --monitor NAME N%` at most every 120 ms; night light through `Extras.nightProxy`; "Monitors ›" opens `~/.config/hypr/monitors.lua` with `omarchy-launch-editor`.
- `bar/sheets/DisplaySheet.qml` (big number + ruler + Night button, monitors with the chosen one inverted, a click chooses which monitor the ruler drives; Up/Down, N) and `bar/scroll/DisplaySection.qml` (Light and Night faders beside the monitors). `Sheets.SHEETS.display` anchors to `brightness`, then `battery`, then `volume` (desktops have no LUM cell); SheetWindow tries every anchor in turn. `Fader.valueText` for a switch.
- To verify on hardware: DDC brightness on an external monitor (it can be slow or unavailable: the ruler then shows "—"), the internal panel's backlight, picking another monitor, and night light through the proxy.

### Bluetooth panel 藍 ✅ (asked for by the user after the Display panel)
- A `BT 藍` cell on the bar, a sheet (04), scroll section 04 (the scroll now has eight: Time, Sound, Network, Bluetooth, Power, Display, Spaces, Inbox; `1`–`8` jump) and a sixteenth setting, `bluetooth: on|off`, in the settings page's Right card (Quiet turns it off; the other presets on; 5,971,968 combinations). It answers `omarchy.bluetooth` too, so that moved from hosted to `Hosted.DRAWN`. Sheets renumbered: Power 05, Display 06, Inbox 08.
- `core/Blue.js` (+ tests): `human(name)` (drops names that are an address or a UUID), `kind(icon)`, `row(d)` ("Headphones · 80%", note Connected/Paired/Pairing), `lists(devices)` (connected, known = paired, found; by name), `cell(present, powered, devices)` (null with no adapter; device name `+N`, its battery as the meter, else On/Off), `action(row)` (disconnect, connect, pair), `sheet(...)`.
- `services/Blue.qml`: `Quickshell.Bluetooth`'s default adapter; devices copied into plain objects (as Omarchy's panel warns, live BlueZ objects can die mid-Repeater); `powered`, `scanning`; discovery only while `wanted` (Bar.qml: the Bluetooth sheet or the scroll is open). Actions through Omarchy's scripts: `omarchy-bluetooth-power on|off` (persists, unlike BlueZ's Powered) and `omarchy-bluetooth-device pair|connect|disconnect|forget ADDRESS` (address and action validated). Middle- or right-click on the cell toggles power.
- `StatusRow` order: cells read NET, BT, VOL, LUM, BAT; glyphs and numerals VOL, NET, BT, LUM, BAT. The settings preview gets the BT cell as well.
- `bar/sheets/BluetoothSheet.qml` (Connected inverted, Known ≤ 4, Nearby ≤ 4 with "Looking…"; foot and `P` toggle power) and `bar/scroll/BluetoothSection.qml` (up to five rows, connected on a plate; "Bluetooth is off · Turn on" when off). Harness stub `tests/harness/stubs/Quickshell/Bluetooth`, params `bluetooth.json`; phase6-b, phase7, phase7-light and phase8 carry Bluetooth. Unit tests: 62.

### Phase 9 · Hosting other widgets ✅
- **The user chose** (asked at the start of the phase): Hanko draws its own keyboard-layout and microphone marks rather than hosting Omarchy's.
- **`core/Hosted.js`** (+ tests): `DRAWN` (ids Hanko already is: menu, workspaces, active-window, clock, elsewhen, audio, network, power, media, notifications, spacer), `OWN` (tray, indicators, keyboard-layout, microphone → Hanko's own marks), `hosted(barConfig, has, allowMultiple)` (everything else that the registry has, in layout order, once unless `allowMultiple`; key `id#n` for repeats), `own(barConfig)` (which own marks the layout asks for; Omarchy's defaults when the layout lists nothing), `cell`/`idOfCell`. `Sheets.panelAt` counts `hosted:<id>` cells in place.
- **Hosting**: `Bar.hostedEntries` (from the injected `barWidgetRegistry`, which the host keeps live), `bar/HostedSlot.qml` (creates the widget with `bar`, `moduleName`, `settings` as initial properties, like omacale; rebuilds only on a different Component; collapses to zero width rather than hiding, since hiding a parent on its child's visibility latches), `bar/HostBar.qml` (the `PluginBarApi` facade: Hanko's ink, mono face, `barSize` = bar height, popouts coordinated through `Bar.requestHostedPopout/releaseHostedPopout`, `shell` = `pluginShellForBarEntry(pluginId, moduleName)`, tooltips are no-ops). One popout at a time across sheets, scroll and hosted panels. `summonBarWidget/hideBarWidget/isBarWidgetOpen` fall through to a hosted widget's `open()/close()/opened` for its id (bluetooth, monitor, weather…).
- **Own marks**: `core/Extras.js` (+ tests: `indicators(state)`, `moduleJson`, `keyboard(hyprctl devices)`, `tray(items)`), `services/Extras.qml` (pgrep for gpu-screen-recorder every 2 s; `omarchy-voxtype-status` stream; `omarchy-reminder show --json` every minute; the idle and nightlight proxies; `hyprctl -j devices` on `activelayout`; `Pipewire.defaultAudioSource`; `SystemTray.items`), `bar/Marks.qml` (pure). Actions: indicator click turns it off / opens its tool (as Omarchy's do), keyboard click/right-click `hyprctl switchxkblayout all next|prev`, mic click `omarchy-audio-input-mute`, wheel ±5 %, middle opens Sound; tray left `activate()` (or the menu when `onlyMenu`), right `display()` (Quickshell's platform menu), middle `secondaryActivate()`, wheel `scroll()`. Do-not-disturb had no mark then; the indicator stamps (below) added one.
- **Room**: `BarSurface.extrasRoom` (right edge to the centre clock, less status, inbox and the right clock) bounds the marks and hosted row; `mediaRoom` is what's left for now playing (hidden under 90 px). Order of giving way: media, then the tray folds (`盆` + count, a click unfolds it for 8 s), then hosted widgets drop out whole (`HostedSlot.fits`, measured from the cells before it). Natural widths are measured apart (`Marks.fullWidth`, each cell's `naturalWidth`) so folding never feeds back into its own decision.
- Harness: `tests/harness/widgets/FakeWidget.qml` (an Omarchy-style widget reading `bar.barForeground`/`fontFamily`), `phase9.json` (indicators, keyboard, mic, tray, hosted, everything at once in five presets). Unit tests: 58.

### Phase 10 · Motion ✅ and per-monitor overrides ✅ (release: the user's, after testing)
- **`core/Motion.qml`**: the timings from Scroll's sheet 05 (unroll 300, roll up 220, ink 200 after 120, pan 260, stamp 140 with the only overshoot `[0.3, 1.4, 0.5, 1]`, sheet print 180, plate slide 160, value fade 140, now-notch creep 1200) and their curves. `still` = harness `forceStill`, Omarchy's `Style.reduceMotion`, or `style.motion === "still"`; `ms(v)` gives 0 when still. `awake` turns on 1.5 s after start and `live = awake && !still` gates the Behaviours that would otherwise slide in from 0 while the bar lays out.
- **Where it moves**: Workspaces folio/kanji draw one bone plate behind the row that slides to the live cell (`liveCell` from `spaces`, not `itemAt(i).on`, which lint can't type); dots stretch. Segmented controls (settings) slide their plate the same way. `FadeText` on every reading, the numerals and the clock. The Edge notches creep (`Notch.creeps`). Inbox stamps: `known` (keys of what was on the bar, refreshed with `Qt.callLater` after the delegates build) and `primed`; a stamp that wasn't known runs `press` 0→1 (scale 1.45→1, −12°→0, opacity). SheetView prints in `Motion.sheetPrint` (`print` is not a legal QML property name). ScrollWindow uses the shared curves. The few remaining fixed Behaviours (grip, sheet foot, index plate, settings rail) switch off when still.
- **`motion` in style.json** (`paper` | `still`), beside `sealGlyph`: `normalize` keeps it, `withSetting(doc, "motion" | "sealGlyph", v)` sets either (so `hanko style set motion still` works through the same IPC), presets, resets and shuffles keep it, and `Settings.changes` counts it. Not in `OPTIONS`, not counted.
- **Settings**: the Motion 動 page (the switch as a `SettingsCard` with `MOTION_CARD`, then the timings table read from `Motion`; "cut" when still; a red line when Omarchy's animations are off). Advanced's per-monitor block: a Segmented of monitor names (`overrideMonitor`, first by default), the override count and Clear, then every setting in two columns (down each column) with its value *for that monitor* (`S.resolve(draft, monitor)`); a red tick marks an override; picking the general value drops it. `monitorPicked(monitor, key, value)` → `Typeset.draftMonitor`. `scrollToEnd()` for the harness.
- Harness: `phase10.json` (Motion page), `phase10-still.json` (light, still), `phase10-monitors.json` (Advanced, DP-2 with three overrides; `settings.scrollEnd`). Unit tests: 63.
- **Left for the user** (they asked to do the release themselves after testing): the README install guide with screenshots, the manifest version, the CHANGELOG release entry, the omarchyplugins.com listing, and merging into `main`.

### Visibility 部品 ✅ (asked for by the user after Phase 10)
- **Anything on the bar can be hidden.** `style.json` `hidden`: a sorted list of part names, beside `sealGlyph` and `motion` (no preset sets it; presets, shuffles, resets and Reset to preset keep it; `Settings.changes` counts it as one change). Parts: `seal spaces title clock media network bluetooth volume brightness battery notif edge keyboard mic tray`, plus `indicator:<key>`, `tray:<item id>`, `hosted:<widget id>`.
- **`core/Style.js`**: `SHOW_OPTIONS`, `OFF` (parts a setting can leave out: seal/title/media none, bluetooth off), `PARTS`, `isPart(p)` (a fixed name or `indicator:|tray:|hosted:<id>`; anything else is refused, and dropped from the file with a warning), `normalizeHidden`, `shows(style, part)` (not hidden and not left out), `withShown(doc, part, shown|hidden)`; `withSetting(doc, "show:<part>", v)` routes there, so the settings cards, the search, the draft and `hanko style set show:mic hidden` need nothing new. Showing a part its setting leaves out sets it back (the preset's way, else the first that draws); picking a drawing way for a hidden OFF part un-hides it.
- **The bar** (`BarSurface.shown(part)`): seal/spaces/title/media get mode `none`; StatusRow gets null readings; `shownIndicators`, `shownTray` (whole tray, then per app), `shownHosted`; Inbox, both clocks and the Edge (`Edge.shown`) hide; `fixedRight`, `zoneStart`, the title's `maxWidth`, `rightCells` and `cellAt` follow what is actually shown. A sheet whose cell is hidden falls back to the right side.
- **Settings**: the Widgets 部品 page (was a placeholder): Show all + a count, then `Settings.visibilityCards(ctx)` as SettingsCards (`show:` rows, `shown | hidden`; SettingsCard reads them with `S.shows`). `ctx` comes from SettingsWindow: `Bar.own`, `Extras.INDICATORS`, `Extras.tray`, `Bar.hostedEntries` (now with `name` = displayName, `description`, `firstParty`). A search stays on the Widgets page when you are on it. `Typeset.draftShowAll()`.
- **IPC / CLI**: `omarchy-shell hanko hide|show <part>`, `scripts/hanko hide|show <part>`.
- **The settings window reflows** (same session): see the SettingsWindow entry in §7. Unit tests: 66.

### Bluetooth cell styles 藍 ✅ (asked for by the user after Visibility)
- `bluetooth` is now `device | marks | count | off` (`Style.ALIASES` maps the old `on` to `device` in `coerce`). Presets: Scroll and Islet `marks`, Quiet `off`, the rest `device`. 11,943,936 combinations.
- `core/Blue.js`: `KIND_MARKS` + `mark(icon)` (耳 響 鍵 鼠 話 遊 機, else 器), `LOW = 0.15`; `cell()` also returns `devices: [{name, kind, mark, level, low}]` (by name; empty when off), `count` ("02") and `needsYou` (any device low).
- `bar/StatusRow.qml`: `btStyle`; the `BtValue` component draws `marks` (boxed in cells, the charge filling the box from the bottom; a low device sealed red; unboxed in glyphs with a 2 px charge rule; ≤ 4 then `+N`, none `—`) and `count` (FadeText count, ≤ 6 dots of 4 px, red when low). The meter is hidden for those styles. `BarSurface` passes `style.bluetooth`.
- Params `bluetooth-styles.json` (18 strips: styles × status modes, low device, five devices, none, off, 32 px).

### Weather leaf 天 ✅ (asked for by the user after Visibility)
- Fills the bare paper left of Time on the scroll. Data like Omarchy's weather panel (see §6 data sources); the detailed design was chosen over omacale's (its own config) and a minimal line.
- `core/Weather.js` (+ 5 tests): `location`, `area`, `url`, `imperial`, `condition` (WMO code → word + kanji), `compass`, `leaf(raw, place, imperial, now)` (the whole reading), `curve`, `range`, `leafWidth(viewW, timeW, interlude, scale)` (≤ 400, 0 under 240).
- `services/Weather.qml` (singleton): `wanted` (Bar.qml: `scrollOpen`), `barConfig`, `reading`; curl processes for wttr.in and Open-Meteo; a 60 s timer, fetching when the answer is older than `refreshMinutes`.
- `bar/scroll/WeatherLeaf.qml` (a ScrollSection: Canvas day graph, now-notch, hours, sun line, three day rows). `ScrollView` places it and an Interlude at `xs[0] - interlude - width` (track x is negative; the view clips). `ScrollWindow` feeds `weather` and `weatherShown`. Part `weather` in `Style.PARTS`; a row in the Widgets page's Centre card.
- Params `weather.json` (1920 wide: rain by day °C, clear night °F, Islet with snow, offline, hidden, panned to Sound) and `weather-light.json`. Unit tests: 72.

### Scroll dividers 間 ✅ (asked for by the user after the weather leaf)
- The dithered interludes looked busy, so nine divider designs were drawn (docs branch, `docs/revision1/`) and all nine shipped as a seventeenth setting, `interlude`: `ma | hairline | folio | kotoba | tsugime | seal | jiku | fuda | su` (間 罫 柱 詞 継 鑑 軸 札 数). Default and Hanko `seal`; Sheet and Instrument `folio`; Scroll `kotoba`; Quiet `ma`; Islet `fuda`. 107,495,424 combinations.
- `bar/scroll/Interlude.qml` draws every style from `style`, `seed`, `next`/`prev` and `s`; `ScrollView.divider` feeds both interludes (and the weather leaf's). `ScrollWindow` passes `style.interlude`. The dither (`Scroll.sliver`) is gone; `Scroll.fbm`/`BAYER` stay for the settings Plate.
- `core/Settings.js`: `INTERLUDES`, `interludeOf`, `interludeLabels`; the Panels card row "Scroll dividers" shows kanji (`Segmented.labels`). The Scroll 巻 settings page is a gallery of nine live tiles; a click picks one.
- Params `interludes.json`, `interludes-light.json`, `interlude-settings.json`.

### Scroll end leaf 跋 ✅ (asked for by the user after the dividers)
- The paper right of 08 Inbox was bare. Nine leaf designs were drawn (docs branch, `docs/revision2/`); the user liked all nine, so they shipped as an eighteenth setting, `endleaf`: `okugaki | koyomi | kiki | shimai | iro | dougu | shuchu | hikae | batsu` (奥 暦 機 終 色 具 集 控 跋). Default and Hanko `koyomi`; Sheet `shimai`; Scroll `okugaki`; Quiet `batsu`; Instrument `kiki`; Islet `dougu`. 967,458,816 combinations.
- `core/Leaf.js` (+ 7 tests): `KINDS`, `colophon(raw, extra)`, `almanac(date)` (month grid, the 24 `SEKKI` and 72 `KO` by start date, `moon()` from the mean synodic month), `cpuTimes`/`cpuBusy`/`memory`/`temperature`/`disk`/`top`/`machine`, `SESSION` (Omarchy's system menu commands), `themes`/`themeWindow`/`themesView`, `TOOLS` (Omarchy's utility bindings), `focusState`/`focusStep`/`focusView` (25 + 5 min, 4 a day), `notes`/`toggled`/`notesView`, `clipboard`, `afterword`, `sample(now)` (the gallery's and harness's reading).
- `services/Leaf.qml` (singleton): `wanted` and `kind` (Bar.qml: `scrollOpen`, the scroll screen's `endleaf`), `reading`. Reads only for the kind shown and only while the scroll is out, except a CPU sample a minute while `kiki` is chosen and the focus timer's 1 s tick while one runs. Actions: `sessionAct`, `setTheme`, `openThemes`, `runTool`, `focusAct`, `toggleNote`, `editNotes`, `copyClip`.
- `bar/scroll/EndLeaf.qml` (a ScrollSection per kind, plus the batsu afterword). `ScrollView.endleaf` + `endWidth` (`Weather.leafWidth` with Inbox's width) places it and an Interlude (its `after` names the leaf) right of Inbox. `ScrollWindow` feeds `leaf`, `endShown`, `font`, `version`, `preset`, `switches`, `sealGlyph`. `Bar.leafRequest` handles its clicks (stay awake through `Extras.idleProxy`, night light through `Display`, silence through `Status`). Part `endleaf`; a row in the Widgets page's Centre card; the Scroll 巻 settings page has an "After Inbox" gallery of nine live tiles; `Settings.ENDLEAVES` / `endleafLabels` for the Typesetting row.
- Params `endleaves.json`, `endleaves-light.json`, `endleaf-settings.json`. Unit tests: 79.

### Inbox and network fixes ✅ (`6b47a25`, `1e06e1b`)
- The inbox read `00` whenever no toast was on screen: one `awk` over `notifications/*.json` and `history/*.json` died on the unmatched first glob (gawk treats a missing file as fatal). `services/Status.qml` now loops over both globs.
- The Network sheet and scroll section listed only the joined network: `nmcli … --rescan no` reads NetworkManager's cache, which it barely refreshes while connected. `services/Net.qml` rescans when either opens and every 30 s while open.
- The sheet still opened with one network: `nmcli device wifi rescan` returns at once and the scan lands 5–8 s later, after the 1.5 s re-read and usually after the sheet is closed. Opening and Rescan now run `nmcli … device wifi list --rescan yes` (`Net.fresh`, which waits for the scan and prints it), and `core/Net.js` `remember(seen, rows, now)` keeps every network seen in the last `KEEP_MS` (5 min; only the latest reading says which is in use), so the sheet and the scroll section show the same list. Unit tests: 82.

### Indicator stamps 鑑 ✅ (asked for by the user after the end leaf)
- All six of Omarchy's indicators (`omarchy.indicators`: recording, dictation, reminder, stay awake, night light, and the new do not disturb) as 18 px stamps in `bar/Marks.qml`, before the inbox. On: pressed with the stamp press, askew by `Status.tilt(key)`. Off: a faint outline; a click switches it on, as on Omarchy's bar. Hover straightens them and opens the hovered one's name to the left.
- Two settings (twenty in all, 7,739,670,528 combinations): `indicators: all | active` and `indicatorStyle: icon | kanji | iconname | kanjiname`. Icons are the Nerd Font codepoints Omarchy's own indicators use (`Extras.INDICATORS[].icon`; an hourglass while transcribing). Kanji stamps that are on are small seals like `bar/Seal.qml` (red plate, inner rule, Noto Serif CJK in paper); off they match the icon stamps. Names are in small caps, red only for a recording or live dictation. Presets: Sheet all/kanji, Scroll active/kanji, Hanko all/icon, Quiet active/icon, Instrument all/iconname, Islet active/icon.
- `core/Extras.js` `indicators(state, all)` marks each `on`; `services/Extras.qml` returns all six, `dnd` set by `Bar.qml` from `Status.doNotDisturb` (reading `Status` from inside the Extras singleton gave `undefined` at load), and `indicatorAction` toggles each the way Omarchy's does.
- The hover name sits outside the marks over a blank `BarSurface` keeps in the right zone (`marks.nameWidth`), capped at the real gap before the zone (`nameRoom`). Growing inside the marks made the stamps jump for a frame before the right-anchored row moved them back, so the hover dropped and the name flickered.
- Unit tests: 80.

### Type scale 組 ✅ (asked for by the user after the indicator stamps)
- Screenshots of the real bar (1920×1080 at scale 1, 12 px Omarchy font) showed the 8 px labels and 8.5 px kanji as smudge: the mockups and the harness render at 2x, so they never showed it. About 25 sizes became one scale in `core/Type.qml` (sizes in its comment and in COMPONENTS.md §1): bar labels 8 → 10, section heads 9.5–10 → 11, captions 9 → 10, descriptions 10.5–11.5 → 12, row names 13–14.5 → 14, sheet and settings titles 38/44 → 40 (settings compact keeps 34/44), clock 21/23 → 22. Floors keep `tag`/`label`/`eyebrow` legible at `typeSize: small`.
- Kanji glosses beside labels stay small (`Type.gloss` 9, the user asked for them not to grow); glosses on their own are 11, section kanji 13.
- Small text that was `inkFaint` is `inkMuted`; labels are `Type.labelWeight` (Medium; JetBrains Mono Nerd Font has no Medium cut, so it falls back to Regular there); bar values are Medium through both `font.weight` and `font.variableAxes: Type.valueAxes` (Space Grotesk is variable and ignored the weight alone).
- Fraunces: every use sets `font.weight: Font.Normal` and `font.variableAxes: Type.axes(<its size>)` (opsz follows the size). The window title's app name rendered bold for lack of `Font.Normal`.
- `typeSize` (`small | regular | large` = 0.9 / 1 / 1.15) sits beside `motion` in style.json (`Style.TYPE_SIZES`, `TYPE_SCALE`; kept through presets, shuffles and resets, counted by `Settings.changes`); it multiplies `Type.scale`, so the bar's height grows with it. A Type size row in the Frame card; `hanko style set typeSize large`. Global, not per monitor (every component reads the one `Type` singleton).
- `tests/run` renders phase4, phase6, phase7 and phase8 again at `QT_SCALE_FACTOR=1` into `tests/out/1x/`. Compare those, not only the 2x ones, after any type change.
- Also fixed: a duplicated `id: cell` in `bar/Marks.qml` (the indicator stamp is now `ind`) that the newer qmllint reports as an error.
- Unit tests: 81.

### Scroll sides ✅ (asked for by the user after the type scale)
- The user found the rollers with caps at the scroll's two edges heavy. Ten alternatives were drawn (docs branch, `docs/revision3/`); the user picked 02 Bare and 04 Curl, which shipped as a twenty-first setting, `sides: bare | curl`. 15,479,341,056 combinations.
- The rollers and the paper's side hairlines are removed from `ScrollView.qml`; `curl` draws two 22 px gradient strips (ink at 0.16, 0.05, 0.02, 0 inward). Default, Scroll, Hanko and Islet `curl`; Sheet, Quiet and Instrument `bare`.
- A Panels row "Scroll sides" in Typesetting; `hanko style set sides bare`.
- Unit tests: 83. Params: `sides.json`, `sides-light.json` (Sheets scene, three desks).

### Scroll guides ✅ (asked for by the user after the scroll sides)
- A twenty-second setting, `guides: both | tabs | foot | none`, shows the index plate (the tabs) and the foot (keys and position bar) together, either one, or neither. 61,917,364,224 combinations.
- `ScrollView.qml` sets `visible` on `plate` and `foot`; nothing else moves. Every preset is `both`.
- A Panels row "Scroll guides" in Typesetting; `hanko style set guides tabs`.
- Unit tests: 84. Params: `guides.json`, `guides-light.json` (Sheets scene, four desks).

### Profile 印影, About 由来, Credits 謝辞 ✅ (asked for by the user: "like the profile page of the Ryoku settings")
- Studied Ryoku's `hub/quickshell/pages/ProfilePage.qml` and `CreditsPage.qml` (branch `unstable-dev`) for the grammar only: a full-bleed poster page, the identity monumental over a watermark kanji, live stats as callouts pinned to the hero by leaders, dossier small print as label-leader-value rows, a palette strip, a rotated spine, EDIT with eye chips and inline text; Credits as editorial type lines that invert on hover and one bone placard. Their art (the marble bust, the tree), barcode and wave gif are not used: Hanko's art is drawn in code (`SealImpression`, a worn seal of your glyph; `Plate` as a whole moon; `HangingScroll`, a kakejiku with a dithered landscape and a small red seal).
- Rail: `00 YOU` Profile, `05 HANKO` About and Credits (`Settings.PLATES`). On a plate the page's Flickable hides and a Loader (`plateLoader`; never name it `plate`, which shadowed `SmallButton.plate` and filled every button) shows the plate; the action bar hides unless there are changes to save.
- `core/Profile.js` (+ tests): `PROBE` (one `sh -c`: user, host, kernel, uptime, `omarchy-theme-current`, `omarchy-version`, Hyprland tag, pacman count, install date, machine-id), `parseMachine`, `fv`, `uptime`, `edition` (FNV over machine-id + install date, four digits), `combination` (the resolved style as a mixed-radix number: "No. 28,195,854,781 of 61,917,364,224"), `vitals(barData)`, `specs`, `PROJECTS`, `PROOFREADERS`, `facts`, `LINEAGE`, `BLOCKS`.
- `services/Machine.qml` runs the probe while the settings window is visible (and each minute). `core/Dossier.qml` keeps `~/.config/hanko/profile.json` (`name`, `tagline`, `hidden` blocks), written at once, not a draft.
- Canvas `fillText` could not find "Noto Serif CJK JP" by name in the harness, so glyphs on the art are real `Text` items over the canvas.
- Params: `profile`, `profile-edit` (EDIT, palette hidden), `profile-light`, `about`, `about-light`, `credits`, `credits-light` (Settings scene; `settings.machine`, `settings.profile`, `settings.editing`). Unit tests: 89.
- **Responsive (asked for after the plates: the art went translucent behind the text on small windows and blocks ran into each other).** Each plate has two layouts and nothing is ever drawn under the type. Profile: *poster* when the plate is at least 1000 px wide and the seal gets at least 280 px in the room right of the readings and their leaders, under EDIT and over the day rule (`posterSeal`); otherwise *stacked*, one column with the seal beside the readings (or above them, readings in two columns, under 520 px). Its blocks are inline components (`Head`, `LiveHead`, `Callout`, `SpecsBlock`, `PaletteBlock`, `EditionLine`, `DayRule`) placed by either layout; EDIT's eye chips sit on a block's top right corner, and the edit strip gets its own band under the page. About and Credits: the moon / hanging scroll sits in its own room right of the column when there is at least 260 / 240 px of it, else small beside the title, or not at all under 420 px of column. Every plate scrolls when the window is too short instead of piling blocks up. `PlateSpine.length` lets a plate drop the spine on a short window. Save image grabs the whole page, also what is scrolled away.
- The Settings scene takes `settings.width` / `settings.height`; params `profile-narrow`, `profile-short`, `about-narrow`, `credits-narrow`, `credits-mid` render the other layouts.

### Window style 窓 ✅ (asked for by the user: "make the hyprland window look match the bar")
- `style.lua` at the plugin root, modelled on Omacale's `omacale.lua`: `pcall(dofile, …)` from `~/.config/hypr/looknfeel.lua` (the user's already had the line), so it re-reads on every `hyprctl reload` and loads after the theme's `hyprland.lua` (Omarchy requires `omarchy.current.theme.hyprland` at the end of `default.hypr.omarchy`, before the user's files).
- Colours: `$XDG_STATE_HOME/omarchy/current/theme/colors.toml` `foreground`, `background`, `red` (else `color1`, as Omarchy's `Color.qml` picks `urgent`). Active border ink, inactive `Ink.line` (foreground at 22%), `border_size` 1.
- Surface from `~/.config/hanko/style.json` (`edits.surface`, else the preset's; the preset table copies `core/Style.js` and must be kept in step). `inset`: rounding 7 like `BarSurface`'s frame; otherwise 0. Gaps 8 out / 4 in for every surface.
- Shadow, `shadow_style` at the top of the file. Default `paper`: black, range 14, power 3, offset 3 5, 55% focused and 25% unfocused, so windows read as sheets on a desk and the focused one sits higher. `print`: hard black offset (`sharp`, range 0, offset 4 4, 85%), focused only. `seal`: the same in seal red. `none`: hairlines only. The first version shipped `seal`; the user asked for black, and red under every focused window spent the colour that means "you". Hyprland multiplies the shadow by window opacity. On a dark wallpaper the black shadow mostly disappears. Checked on Hyprland 0.56.2: `hyprctl configerrors` clean, and `paper` and `seal` checked on screen.
- Groupbar: no gradients, mono 10, 1 px indicator, ink / line / muted text. Animations from `core/Motion.qml` (speed = ms / 100): windows in 180 ms on the unroll curve with `popin 96%`, out 140 ms, moves and workspaces 260 ms on the pan curve (workspaces `slide`), border and fades 140 ms; `motion: still` sets `animations.enabled = false`.
- Per-monitor overrides are ignored (Hyprland's decoration is global). The shell does not push changes: a style or theme change reaches the windows on the next `hyprctl reload` (`omarchy theme set` runs one).

### Kata 型 K1 · the design resolver ✅ (asked for by the user after the three redesigns)
- **The idea** (`docs/kata/README.md`): Margin, Leaf and Shōji share the skeleton and differ in a dozen parts, so a design is a preset over parts. Settings stay three levels: pick a design, borrow a part, or write `style.json`.
- **`core/Kata.js`** (pure; 10 tests): `PARTS` (`surface arrive pointer select slider ring seal unread sign`, partners `corner divider tempo` with `follows`), `AUTO`, `TOUCHES` (`season numerals grain`), `DESIGNS`, `DESIGN_NAMES` (`classic` first; `DEFAULT_DESIGN = classic`, so nothing changes for existing users), `clean` (drops unknown designs/parts/values with warnings; `Shōji` reads as `shoji`), `resolve(doc, monitor)` → `{ design, classic, <part>, touches, borrowed, warnings }` (monitor's design wins on that monitor; borrows and touches merge), `withDesign` (drops borrows, keeps touches; Classic removes the key), `withBorrow` (own part or `auto` gives it back), `withTouch`, `surprised(doc, rng)`, `describe(style)` ("Shōji with Margin's slider, Leaf's seal", parts in `PART_KEYS` order).
- **`core/Style.js`**: `KATA_KEYS`; `normalize` carries `design`, `borrow`, `touches` (top level and inside `monitors[name]`, kept out of `cleanEdits`, so no warnings); `resolve` doesn't copy them into the Typeset style; `withPreset` returns to Classic (a Typeset preset is the Classic design).
- **`core/Typeset.qml`**: `kata`, `kataFor(name)`, `designNames`, `kataParts`, `describeDesign()`, `setDesign / borrow / touch / surprise` and `draftDesign / draftBorrow / draftTouch / draftSurprise`; `reset()` and `draftReset()` keep the Kata keys (`_keep`); `_load` adds Kata's warnings.
- **IPC / CLI**: see §7; `scripts/hanko design [name]`, `hanko borrow <part> <value|auto>`, `hanko touch <key> <value>`.
- Nothing on screen changes yet: the bar still draws the Classic Typeset bar for every design until K4. Unit tests: 107.

### Kata 型 K2 · skin and tokens ✅
- **`core/Skin.js`** (3 tests with K2): `skin(kata)` turns a resolved design into plain tokens; components take it as a `skin` prop. `TEMPOS` (spring 240 / snap 220 / jo-ha-kyū 340, leaves 140–160, `Easing.BezierSpline` control points), `RADII` (soft 16/10/7, cut 0), `SETTLE`, opacity (washi 0.86), `gap` (fold −1 overlaps the bar's line, slip 0, slide 6), `travels` (slide). Chosen over a `Skin.qml` singleton so a monitor with its own design (`monitors[name].design`) gets its own skin.
- **`core/Brush.js`**: `stroke`, `kasure`, `enso`, deterministic by seed, paths rounded to 0.1 px.
- **`core/InkMath.js` `kata(fg, bg)`** and **`Ink.qml`**: `ink2` (7:1 or 80% of the theme's, ≥ 5.6), `ink3` (4.6), `ink4` (2.05), `kLine`, `lift`, `paper2`, `sunk`, `cut`, `edge`, `edgeSide`, `shade`, `shade2`, `shadeIn`, `scoreDark`, `scoreLight`. Existing tokens untouched.
- **`Type.axes(size, wght, soft)`**: optional SOFT axis. Unit tests: 110.

### Kata 型 K3 · the parts in QML ✅
- **`bar/parts/`**, every variant of every part (they were small enough to do all three designs at once, so K6 shrinks to the whole-screen pieces). Each takes `skin` (from `Skin.js`) and is pure:
  - `Surface` (`hangs` squares and opens the top edge for a panel coming out of the bar; `lifted` = Leaf's height 2): paper's soft shadow and card's hard shadows are stacked/offset `Rectangle`s, never blur; washi is `skin.opacity` paper with `Fibres` and a top light. `Fibres` is one `Canvas` per surface, fixed seed, fibre count by area (a tiled `toDataURL` version recursed until the stack overflowed).
  - `Divider` (`bleed` reaches the frame; lattice draws its two joints), `Selection` (`inverts` for the plate; slides on `y` with the skin's tempo), `KataSlider` (ticks on whole pixels; drag + wheel emit `moved(v)`; brush = `InkShape` of `Brush.stroke` + kasure lines), `Ring` (glyph rounded or cut by `corner`; ensō with a faint ring at bar size so 12% still reads), `KataSeal` (carved edge from `Brush.rough`; the press animation when `on` turns true), `UnreadMark` (fills its card or desk cell; `small` for desks), `PointerMark` (give it `target` and `lineY`; label for crop marks), `Sign` (eyebrow / index tabs with `picked(key)` / tategaki: one `Text` per kanji, Latin rotated 90°), `InkShape` (a `Shape` + `PathSvg`, `CurveRenderer`).
  - Named `KataSeal`/`KataSlider` so they never shadow `bar/Seal.qml`. Item already has FINAL `baseline`, `right`, `bottom`: don't name properties that (hit here twice).
- **`core/Brush.js` `rough(w, h, r, seed, jitter)`**: a carved outline.
- **Harness**: `scenes/Kata.qml` (every part × each design, then a panel built only from parts; `designs` in params takes any style docs, so mixes render too), `params/kata-parts.json`, `kata-parts-light.json`. `tests/run` lints `bar/parts/`. Unit tests: 110.

### Kata 型 K4 · the Kata bar ✅
- **`bar/KataBar.qml`**, pure like BarSurface (same props for the data it uses, same signals, `anchorFor`, `cellAt`, `rightCells`), taking `skin` and the Typeset `style` (height, sealGlyph, hidden). Left: the seal (`KataSeal`, on when there are notifications and DND is off; left-click `inboxAction("click")`, middle `inboxAction("middle")`, right the Omarchy menu), desks (an ink plate for tint/plate, a brush mark for wash, both sliding; `UnreadMark small` on urgent; click, right-click overview, wheel steps), an interval, then app + document (`Title.describe`; italic on card). Centre: Fraunces time with the skin's SOFT, the date, the season (`Season.label`, kanji in Gothic). Right: now playing (gives way when there's no room), Wi-Fi (its name on reach), volume (wheel → `statusAction("volume", "up"|"down")`), battery (`Ring`; red with `needsYou`), all with the `PointerMark` over them (`hoverCell` points from the harness).
- **`BarWindow`**: `kata = Typeset.kataFor(screenName)`, `skin = Skin.skin(kata)`; `classicSurface` (BarSurface) or `kataSurface` (KataBar) by `kata.classic`; `surface` is whichever shows, which `SheetWindow` (now `required property var surface`) and `Bar.panelWidgetIdAt` use. So Kata's cells open the existing sheets and scroll; Kata panels come in K5.
- **`core/Season.js`** (1 test): exact sekki and kō from the solar longitude, checked on the 2027 solstice boundary. **`bar/parts/Icon.qml`**: wifi (arcs by level), offline, volume, muted, bolt on one grid.
- **Pitfalls hit**: `mapToItem` is not a binding dependency (the pointer stuck at its first, unlaid-out position; read the positions it uses in the binding); property names can't start upper case (`KAN`); `font.pixelSize` is an int.
- Harness `scenes/KataBars.qml` + `kata-bars.json` (each design, quiet, alerts, reach, two mixes), `kata-bars-light.json`; renders in `docs/kata/images/k4-*.webp`. Unit tests: 111.
- **To verify on hardware**: `hanko design shoji` switching the live bar (and back with `hanko design classic`), HoverHandler reaching the cells on a layer-shell surface, sheets dropping under the Kata cells, the seal opening Inbox, and the washi Fibres Canvas cost at 4K.

### Kata 型 K5 · Kata's panels ✅
- **`bar/kata/KataPanelView.qml`**: the frame around one panel, pure like `SheetView` and fed the same `feed`; requests name their sheet, so `Bar.sheetRequest` handles them unchanged. Bluetooth opens Connections and Display opens Power (`panel` maps the sheet key). Width from the panel (Time is 640 with the season touch, else 420; Letters 420; the rest 400) plus 52 for a tategaki column. Arrival by `reveal` with the skin's tempo: fold scales from the bar's line (`Joins` draw the concave corners when corners are soft), slip comes out of a clipped well from under the bar, slide comes in from the cell's side. Signs: eyebrow at the top, index tabs hanging from the foot (`pickSheet`), tategaki on the right.
- **Panels** (`bar/kata/`), each a Column of parts and plain data: `TimePanel` (the day as "Thursday, *the eighth*", month grid with today as an ink plate or in an ensō `Ring`, the kō in tategaki with its sekki when `season` is on, other cities), `SoundPanel` (hero figure, `KataSlider`, Plays on in a `KataList`, app rows with thin sliders, the microphone switch), `NetworkPanel` (Wi-Fi switch, the network's name as the hero, nearby, Bluetooth with its devices through `Blue.js` actions), `PowerPanel` (`Ring`/figure hero, the blurb, brightness, `Choice` power mode, `SessionRow`: lock and sleep at once, restart and shut down held 600 ms with a red soak), `LettersPanel` (Quiet switch, cards with `UnreadMark`, show recent again, clear all). Helpers `KataList` (a `Selection` slides to the chosen row; plate inverts the text), `Figure`, `Heading`. New parts `KataSwitch`, `Choice`, `Joins`.
- **`SheetWindow`**: `kata` when the screen's design isn't Classic; then `KataPanelView` shows instead of `SheetView` (`view` is whichever), hung by `skin.gap`, `side` from the cell's half of the screen, `Behavior on x` when `skin.travels` so Shōji's panel slides along the bar to the next cell. Tab walks Time, Sound, Network, Power, Letters (`win.cycle`); the tabs open their sheet with `bar.openSheet`. The handscroll and the overview are still Classic's.
- Harness `scenes/KataPanels.qml` (panels × style docs) + `kata-panels.json` (each design) and `kata-panels-light.json` (three mixes); renders in `docs/kata/images/k5-*.webp`. `tests/run` lints `bar/kata/`. Unit tests: 111.
- **To verify on hardware**: fold's scale and slip's clipped well on a real layer surface, the slide travelling between cells, the panel's keyboard focus after the prime (Esc, Tab, Up/Down on Sound), session holds, and Bluetooth actions from Connections. Not in yet: weather on Time, Power's quick chips.

### Kata 型 K6 · the second wave ✅
- **`core/Kata.js`**: `notify` (cards · Margin, tickets · Leaf, rows · Shōji), `overview` (miniatures, contact, framed), `hold` (soak · Leaf, stroke · Shōji; Margin uses soak, as the spec says it shares Leaf's). Twelve main parts now; Surprise draws from all twelve. `Skin.skin` passes them through. 1 test (112).
- **`bar/parts/Letter.qml`**: one notification. Cards follow the pointer sideways and are put away past 35% of their width (clipped to the panel while swiped); tickets have a stub with the age beyond a perforation (holes and two notches), and pulling down 26 px tears it; rows sit between `Divider`s with the `UnreadMark`. Signals `dismissed` and `opened` (replay). `LettersPanel` uses it and asks `("inbox", "dismiss", letter)`; `Bar.qml` keeps `setAside` (timestamp|app|summary) and `lettersShown()` filters the feed; Clear all empties it. Omarchy has no per-letter delete a bar can call, so a put-away letter comes back after a shell restart.
- **`bar/parts/Hold.qml`**: the hold-to-confirm button (600 ms fill, 200 ms drain; `hold: false` is a plain button; `progress` for the harness). `SessionRow` is four `Hold`s.
- **Overview**: `OverviewPage.skin` / `variant`; `OverviewView.skin`; `OverviewWindow` passes `barWindow.skin` and always shows the grid under a Kata design (`dynamic` is Classic's). Miniatures: soft corners, the number in Fraunces, "2 windows" in words. Contact: paper2, hard card shadow, sprocket holes down the left, mono `03A` (▸ on the live frame), crop marks round the live frame. Framed: washi at the skin's opacity, a lattice line inside the edge and under the folio, the kanji numeral over the figure.
- Harness `scenes/KataWave.qml` (letters with one mid-swipe or mid-tear, holds mid-press) + `kata-wave.json` / `kata-wave-light.json`; `scenes/Overview.qml` takes `design` (a style doc) and draws `KataBar` + the design's pages: `overview-margin|leaf|shoji|kata-light.json`. Renders `docs/kata/images/k6-*.webp`.
- **To verify on hardware**: a swipe and a tear with a real pointer (the MouseArea takes the drag before the panel's own), the hold on a touchpad press, and the contact sheet's sprocket column at small page sizes.

### Kata 型 K7 · Settings › Design 意匠, and no Save ✅
- **The user asked for no Save button.** The settings window now keeps every change as it is made: each handler in `SettingsWindow` calls the matching `Typeset.draft*()` and then `Typeset.keep()`, which commits the draft (the usual debounced write) and pushes the document it replaces onto `Typeset.history` (50 deep). `Typeset.undo()` commits the last one back; Ctrl+Z and the action bar's Undo call it; `Bar.closeSettings()` forgets the history. The draft model stays underneath (so the window code barely changed), it just never lingers. `SettingsPage`: `undoCount` replaces Save/Revert, the action bar says `Settings.status(n)` ("Saved · every change is kept as you make it" / "Saved · 3 changes · Ctrl+Z undoes"), Reset to preset only on Typesetting. Text fields (the seal glyph) keep each keystroke, so Undo walks them back one at a time.
- **`bar/settings/DesignPage.qml`** (rail `design`, first under 01 BAR, and the page the window opens on): four design cards (2 or 1 across) with the bar drawn at 1240 px and scaled in (`BarSurface` for Classic, `KataBar` with that design's skin and your touches), ON YOUR BAR on the current one; the mix in Fraunces italic (`K.describe`), Back to the design (drops borrows; faint when none) and Surprise me; then one row per main part (`K.MAIN_PARTS`, twelve) with a tile per variant, each drawn by **`bar/settings/PartPreview.qml`** with the skin that borrow would give (`K.withBorrow` on the doc, Margin's under Classic, where the rows are dimmed and explained); the touches with `Segmented` (season labels from `Season.at(now)`). Signals `designPicked`, `borrowPicked`, `touchPicked`, `surprise`, `backToDesign`, wired through `SettingsPage` to `Typeset.draftDesign/draftBorrow/draftTouch/draftSurprise` + `keep()`.
- `core/Settings.js`: `design` in `RAIL`, `status(n)` reworded (tests updated). Harness `design-settings.json` (Shōji with two borrows, 3 changes to undo), `design-settings-light.json` (Classic), `design-settings-narrow.json` (Leaf at 620 px); renders `docs/kata/images/k7-*.webp`, the first also in the README. Unit tests: 112.
- **To verify on hardware**: Ctrl+Z reaching the window when a text field has focus (the field may take it first), the debounced write keeping up with Surprise clicked quickly, and the design cards' bars at 1x.

### Kata 型 · Bluetooth ✅ (asked for after K7: "in all this 3 design the bluetooth and its panel is not present")
- **`KataBar`**: `bluetooth` (the `Blue.cell` shape, as BarSurface gets it; `BarWindow` passes `Blue.cell`), a `btCell` between Wi-Fi and volume: `Icon` `bluetooth` / `bluetoothOff` (new `rune` path), the first connected device's charge as a figure, red with `needsYou` (low charge), its name sliding out on reach. Hidden with `style.bluetooth: off` or the part hidden. `rightCells` and `anchorFor` know `bluetooth`, so a click opens the Bluetooth panel (Sheets anchors) and Omarchy's Bluetooth hotkey reaches it.
- **`bar/kata/BluetoothPanel.qml`**: switch (`("bluetooth", "power", on)`), the hero (connected device's name in Fraunces, `blurb`, its charge on a 48 px `Ring`, red at `Blue.LOW`), Connected / Your devices / Nearby as `KataList`s, a click runs `Blue.action` (disconnect / connect / pair) through `("bluetooth", "device", …)`; P toggles. `Blue.wanted` already follows `sheet === "bluetooth"`, so scanning runs while it is open. `Blue.row()` gains `level` (0..100 or -1).
- `NetworkPanel` lost its Bluetooth section and is signed Network 繋; `KataPanelView` maps `bluetooth` to its own panel (藍), Leaf's tabs and `SheetWindow.kataOrder` include it (six panels).
- Harness: `kata-panels*.json` add the Bluetooth row; `kata-bars.json` adds pointing at Bluetooth, Bluetooth off and a headset at 9%. Renders refreshed (`k4-*`, `k5-*`) plus `docs/kata/images/k8-bluetooth.webp`.
- **To verify on hardware**: the rune at 1x, scanning starting when the panel opens from the Kata cell, and pairing a device that asks for a PIN (none is shown, as with the Classic sheet).

### Panel opacity 透け ✅ (asked for: "all panel should has the opacity so we can adjust")
- **`core/Style.js`**: `panelOpacity` beside motion and type size (not one of the twenty-two, no preset sets it, reset and presets keep it; `Typeset._keep` lists it). `normalizeOpacity`: 30..100, anything else (missing, 0, "auto") means the design's own and drops the key. `withSetting(doc, "panelOpacity", "70" | "auto")`, so the CLI's `style set` and IPC work too. `resolve()` gives `panelOpacity` (0 for auto). 1 test (113).
- **Kata**: `Skin.skin(kata, panelOpacity)` overrides `opacity`; `BarWindow` passes `shown.panelOpacity`, so the panels, the overview's skin and every part get it. `Surface` now draws every kind at `skin.opacity` (paper and card too, not only washi), a hanging paper sheet squares its top corners with `topLeftRadius`/`topRightRadius` instead of an overlapping cover (which doubled up once translucent), and its shadows fade with `shadowOpacity` (full at 86%, gone at 50%), since they sit under the whole sheet.
- **Classic**: `SheetView.paperOpacity` → `SheetCard`, `ScrollView.paperOpacity` (the paper and its edge fades); `SheetWindow` and `ScrollWindow` set them from `barWindow.shown.panelOpacity`.
- **Settings › Design**: a Panel opacity row (a `KataSlider` in the current design's slider part mapped onto 30..100, the figure, Auto). `SettingsWindow` calls `Typeset.keep("panelOpacity")`; `keep(tag)` folds repeats of one tag within 1.5 s into one history step, so a drag is one Undo.
- Inner pieces drawn on `Ink.paper` (Leaf's letter cards and tickets, the scroll's name tab) stay solid, like cards on glass. Hyprland blurs nothing behind `hanko-sheet` yet; a layer rule for it would be the next step if the user wants frosted panels.
- Harness `kata-panels-opacity.json`, `sheet-opacity.json`; render `docs/kata/images/k9-panel-opacity.webp`.

### Revision 2 · Classic polished ✅ (`d565381`, on `dev`; asked for: "polish the classic as much as possible, as a senior polishes a junior's design")
Same design, same layout and data; only the finish of Classic's sheets changed. Images: `docs/revision2/images/r2-sheets.webp`, `r2-sheets-light.webp`.
- **`SheetHead`**: the eyebrow's rule now ends in the sheet's folio (`No. 02`, from `Sheets.js` `no`; each sheet passes `sheet: "<key>"`); the sheet's kanji sits large and faint behind the title (Noto Serif CJK Black at 84 px, 5.5% dark / 7% light), the way the scroll already marks its sections; the title elides before it; the blurb is a standfirst in Fraunces italic 15 instead of grotesk.
- **`GroupHead`**: the hairline under a group thickens to a 2 px `inkMuted` underscore beneath the head's own words.
- **`SheetRow`**: hover is a 6% bone tint plus a 2 px ink bar growing at the leading edge (where `//` stands when selected).
- **`Ruler`**: the needle has a head (a 3 px cap, like a gauge pointer), eases to a new value (not while dragging), and a muted channel's needle turns `inkMuted` (the master stays red).
- **`SheetCard`**: a soft 7-layer shadow under the free sides only (never on the bar; gone below 50% panel opacity), the tear is 2 px with a faint fall-off either side, and the crop marks are two arms set off the trim like a printer's instead of a `+` on the corner.
- **`ActionBar`**: the foot is a colophon strip, 3.5% bone (5% on light paper). **`SheetButton`**: radius 2, plates lighten on hover, outlines darken, and a press sinks it a pixel.
- **Time**: the ribbon hangs from its head's rule (the doubled rule and its gap are gone), cells are 50 px, and today's plate carries a 2 px red notch (red means now). **Sound** and **Display**: the hero figure has tabular digits and a small raised `%`.
- No colour animations on plates: the harness (and a sheet opening) caught them mid-fade.
- Harness `r2-sheets-light.json` (Sound, Time, Network, Inbox on light paper).

### Classic bar polish ✅ (asked for: "polish the bar I use", the user's `style.json` on `dev`)
The user runs Classic on the Hanko preset with `panels: sheets`, `indicators: active`, `indicatorStyle: kanjiname`, `interlude: fuda`, the dynamic overview, Omarchy's agents and weather widgets hidden, and panel opacity at 100. Harness `my-bar.json` renders exactly that (with Bluetooth, and with night light, a reminder and a tray); image `docs/revision2/images/r2-bar.webp`.
- **Red means now, again**: kanji indicator seals that are on are carved in ink (`Ink.bone` plate, `boneInk` kanji and inner rule); only a `red` mark (recording, dictation) stays a red seal. With the seal, the letters' stamps and two marks on, the bar had five red things and none stood out.
- **Tabular figures** on status values (`StatusRow` `Value`) and the stacked and inline clock: 61 → 62 or 21:49 → 21:50 no longer nudges the cells after it.
- **Quieter rules** between groups (`BarSurface` `Divider`) and between status cells: 42% of the bar's height, centred, at 13% bone (16% on light paper), instead of near full height at 22%.
- **Hover plates**: a reading under the pointer sits on a faint 3 px-radius plate, so you see which cell a click or scroll will reach.
- **Urgent workspace dot**: 7 px with a 1.5 px paper ring (was 5 px with a 2 px ring: a 1 px red speck at 1x).
- **Fix**: `Marks.nameWidth` carried the tray's width since the indicator stamps landed (`c15ddf9`), so the bar kept a permanent blank as wide as the tray left of the marks and pushed what is playing out early. The tray's share is back in `fullWidth`, where folding it is decided.

### Bar feedback, after game HUDs ✅ (asked for: "research how games make this kind of experience and polish it further")
What was taken from game UI (Ghost of Tsushima's minimal HUD, Persona and Metaphor's menus, HUD practice: show on change, juice, never colour alone) and fitted to Hanko's motion rules (paper, not glow; everything under 320 ms; `Motion.still` cuts it all):
- **Counters run up** (`bar/RollText.qml`): a whole-number reading rolls through the numbers to its new value (120 ms + 6 ms a step, ≤ 320 ms, OutCubic); anything else fades through as `FadeText` did. Used for the status values in cells mode.
- **Meters fill tick by tick**: each `Ticks` tick changes 15 ms after its neighbour, starting from where the last fill ended (≤ 150 ms of stagger + 80 ms).
- **Show on change**: a reading that changes inks its label (VOL 音) up to full ink for 900 ms and settles back; hovering does the same, with the plate.
- **Press**: the plate deepens and the cell's text sinks a pixel while held.
- **Needs you, twice**: a red reading (low battery, offline) also breathes slowly (opacity 1 ↔ 0.5, 1.1 s each way), so it isn't told by colour alone.
- **Fix**: `SignalBars` anchored each bar to a parent a Repeater hadn't given it yet (a warning per bar, on every bar build); they are placed by `y` now.
- **Test**: `tests/motion.py` drives `tests/harness/scenes/MotionProbe.qml` with motion on (renders are end frames) and checks that 40 → 62 passes through the numbers, lands on 62, a word fades through, and nothing warns. `tests/run` runs it, `--quick` too.

### Bar, a more natural pass ✅ (asked for: "more research, make it look more natural and premium; position and style may change")
Research behind it: NN/g on grouping by proximity instead of borders, Japanese *ma* and *kanso* in UI (space as an element, keep only what serves), menu-bar and ricing practice (one accent, reduced chrome), and game HUDs (show on demand). Changes, all Classic:
- **Rodrule as ink** (`Edge.qml`): the hours to come are a 1 px hairline with 6% fades at both ends (no end caps on the rodrule; `rod` keeps its roller and caps); the spent part is a 2 px stroke going from nothing at midnight to `inkDim` at the now-notch; ticks ahead of now are `line`, behind it `lineStrong`; the grip appears only on hover or drag (still always on `rod`).
- **Readings as one group** (`StatusRow`): in `cells` mode the hairlines between NET, BT, VOL, BAT are gone and a 22 px gap holds them (the zones' dividers stay, per `rules`). The BT cell's charge meter is half length.
- **Workspace tiles** (`Workspaces` layout): windows are solid tiles (focused ink, others 38% on the active page, 16% elsewhere) without outlines; an inactive page's frame is `lineSoft`.
- Harness `my-bar-light.json`; images `docs/revision2/images/r2-bar.webp`, `r2-bar-light.webp`.

### Profile, About and Credits redesigned ✅ (asked for: "more polish, especially the profile page; research, refine and redesign it to look premium")
Research behind it: the Japanese seal registration certificate (印鑑登録証明書: the registered impression beside the holder's name, address and birth date, with an issue date and number), the colophon page at the back of a Japanese book (奥付), Müller-Brockmann's modular grid (alignment to shared anchors, hierarchy by scale and weight, whitespace as an element), and game status screens (stats in a row, figures large). Critique of what was there: the seal bled off the right edge and hid its own frame, its hairline leaders pointed at arbitrary spots on it, a large void sat between the name and the small print, and the day rule floated alone.
- **Profile** (`ProfilePlate.qml`, poster layout rewritten): a two-column grid. Left: `Head` over a `SectionLabel` (登録 REGISTER), the specs and the palette. Right: `Impression`, the seal at 74% of a ruled square on a 田字格 practice grid (the `watermark` block now draws the grid; the old giant glyph is gone), turned 3°, crop marks off each corner, captioned `印影 · PRESSED <since> · VERMILION ON PAPER` and `NO. <edition>`; its eye chips sit under the caption. Across the foot: `LiveBand` (脈 · LIVE FROM THE BAR with its rule) of `StatCell`s, figures in Fraunces 40 with `tnum`, a hairline gauge from the new `level` on `Profile.vitals()` (sound, network bars, power). Then a rule, the edition left and the day right, on one line. The band and foot sit on the page's floor and extra height opens above them. The leaders `Canvas` and `Callout` are gone. The stacked layout uses the same `Impression` and `StatCell`s (two or three to a row).
- **About**: 判子 and Hanko on one line, `SectionLabel`s (仕組 HOW IT IS MADE, 系譜 DRAWN THREE WAYS), tighter fact rows, the lineage as three columns with hairlines, and a `Colophon` component: a ruled 奥付 box, its title in a notch of the top rule, faces left and inks (hex and contrast) right; under the moon on a wide page, in the column otherwise.
- **Credits**: 感謝 and Gratitude on one line; credits under `Profile.CREDIT_GROUPS` (Foundation 礎, Lineage 系譜, Type 活字; every project has a `group`, `creditsIn(group)`; a unit test checks they partition); the proofreaders on a ruled card stamped 校 in red with the name in Fraunces, instead of the bone placard.
- `bar/settings/SectionLabel.qml` is shared by the three. Images `docs/revision2/images/r2-profile.webp`, `r2-profile-light.webp`, `r2-about.webp`, `r2-credits.webp`.

### Profile: the seal becomes a signed work ✅ (asked for: "the red hanko seal does not look good; remove it, something new or a better style")
Research: a work of Japanese calligraphy is signed with a rakkan (落款), the signature and usually two seals at a margin, a hakubun (白文, characters cut white, the red filling the ground) for the name and a shubun (朱文, characters standing in red) for the pen name; seals are placed so they balance the work rather than compete with it.
- **`bar/settings/Shikishi.qml`** replaces `SealImpression.qml` (deleted): your seal glyph written large in ink (Noto Serif CJK Black, 60% of the box, a little right of centre) and, down the left margin, the signature (your name and `machine.since`, Fraunces italic, turned 90°) over two vector seals: a square hakubun with your initial cut white, and a round shubun with the glyph in vermilion. No dithering, no tilt; the plate's only red is these two small marks.
- The `Impression` box, its practice grid, crop marks and eye chips are unchanged; its caption reads `書 · INK ON PAPER · SIGNED WITH TWO SEALS` and `NO. <edition>`.
- Images `docs/revision2/images/r2-profile.webp`, `r2-profile-light.webp` refreshed.

### Kan 鑑 and a brush for every kanji ✅ (asked for: "印 looks like 'Ep'; use a complex Kan instead; draw the kanji like calligraphy art, across the whole bar")
Research: seal shops carve in tensho (篆書) or kaisho; no free (OFL) tensho font with kanji exists (the ones found are commercial), so the bar is written with an OFL brush face instead. Yuji Boku, Syuku and Mai share their kanji; Boku was taken.
- **The seal glyph** defaults to **鑑** (as in 印鑑, the registered seal; also mirror, model). Settings › Typesetting's seal-glyph choice offers the four Kan: 鑑 漢 観 寛 (and `…` for any other). Every `"印"` fallback, the settings window's mark, the Kata seal, the overview and the Profile's work follow it; the Kata part label for the seal is 鑑. Compound words (印影 and the like) are unchanged. The user's `style.json` on dev is set to 鑑.
- **`Type.brush`** (Yuji Boku, `assets/fonts/YujiBoku.ttf`, 620 KB subset, `YujiBoku-OFL.txt`); `Type.jp` and `Type.jpSerif` resolve to it, so every kanji in the bar, sheets, scroll, overview, settings and plates is brushed. Glosses grew a step (`gloss` 11, `glossMid` 12) because the brush's hairlines vanished at 9 px on a 1x panel.
- **Profile's work** (`Shikishi`): the glyph brushed at 62% of the box, turned 2°, over four faint offset copies (a bleed into the paper); the round shubun is brushed too.
- Credits list Yuji Boku (Kinuta Font Factory) under Type; Noto CJK now covers what the brush lacks.

### Plainer kanji on the bar ✅ (asked for: "in the bar cells and active indicators, kanji with fewer strokes so they look clean; leave the workspace numerals")
The brush face drew the dense glosses (接続, 藍, 電, 録, 醒, 静) as smudges at gloss size. On the bar itself each is now the plainest kanji that still says it:
- **Cells** (`StatusRow.items`, `jp` and `glyph`): NET 波 (waves), BT 双 (a pair, as devices pair), VOL 耳 (ear), LUM 光 (light), BAT 力 (power; 充 while charging); BT and VOL were 青 and 音 for a day, then matched to the others' open shapes at the user's ask. The glyphs status style and Islet use the same.
- **Indicators** (`core/Extras.js`): 写 recording, 言 dictation, 予 reminder, 目 stay awake, 月 night light, 休 do not disturb.
- **Inbox** count mode: 文 (休 under do not disturb). Mic 声 and the tray's 盆 were already plain; the workspace numerals (壱 弐 参 …) are unchanged.
- The sheets, scroll and settings keep their fuller heads (網 藍 音 電 明 報). `Settings.js`, `Style.js` text, fixtures and the indicator unit test follow; the brush subset was re-cut to include the new kanji.

### Sheet hands: Ledger 帳, Prose 文 (and Dial, since replaced by Tanzaku) ✅ (asked for: "two more sheets for every bar cell after intensive research, chosen in the existing Settings tab")
Research: Teenage Engineering's OP-1 (a whole-screen graphic per mode, four parameters always visible, nothing nested, monospace type), Nothing OS quick settings (circular and pill tiles, a 2x2 tile for Bluetooth), and "mad libs" forms (fields completing a sentence; Luke Wroblewski reported 25–40% better completion in one test, with the caveat that prose scans slower than columns, which is why every Prose sheet keeps an index list under its sentence).
- **`core/Style.js`**: `SHEET_STYLES` (ledger, dial, prose), `SHEET_KEYS` (the seven sheets), `sheetStyles` in style.json holding only the non-ledger ones (`normalizeSheetStyles`), `resolve()` gives the full map as `style.sheetStyles`, `withSetting(doc, "sheetStyle:<sheet>|all", hand)`. Beside the twenty-two (presets and reset keep it); `Typeset._keep` lists it. 1 test (114).
- **`bar/sheets/SheetView.qml`**: `styles` picks the component per sheet (`hand`); SheetWindow passes `barWindow.shown.sheetStyles`, the harness `desk.style.sheetStyles`.
- **Dial parts**: `DialGauge` (Canvas arc, 135° to 405°, drag and wheel, `moved(v)`), `DialHero` (gauge or a `face` component, title, mono lines, quick buttons), `TileSection` (labelled grid), `Tile` (mark, name, detail, note, `level` gauge, bone plate when selected, red when urgent). Sheets `TimeDial` (a Canvas clock face, day round the rim), `SoundDial`, `NetworkDial`, `BluetoothDial`, `PowerDial`, `DisplayDial` (brightness never under 1%), `InboxDial`.
- **Prose parts**: `ProseText` (StyledText with `word(action, label)`, `em()`, `red()`; links underlined, `picked(action)`), `ProseIndex` and `IndexRow` (mono number, a bone plate on the one in use, red when urgent, dotted leader, note). Sheets `TimeProse`, `SoundProse`, `NetworkProse`, `BluetoothProse`, `PowerProse`, `DisplayProse`, `InboxProse`.
- `SheetHead.compact` keeps the eyebrow and folio only, for Dial and Prose.
- **Settings › Sheets** (`bar/settings/SheetsPage.qml`, replacing the placeholder): three hand cards (a click sets every sheet), a row per sheet with a Ledger · Dial · Prose segmented choice, and a live preview of the sheet last touched in its hand, in a room fixed to the widest sheet (500 px) so hovering another row never resizes the list or shifts its buttons, fed by `SettingsPage.sheetFeed` (SettingsWindow builds it as SheetWindow does).
- Harness `sheets-dial.json`, `sheets-prose.json` (all seven sheets in each hand), `sheets-settings.json`. Images `docs/revision2/images/r2-sheets-dial.webp`, `r2-sheets-prose.webp`, `r2-sheets-settings.webp`.

### Tanzaku 短冊 replaces Dial ✅ (asked for: "the dial is not good; research a premium look, not AI slop; something new and unique")
Why: an arc gauge and a tile grid are what every dashboard has; nothing about them is Hanko's. Research: tanzaku, the poem slips (museum pieces 35.7–36 × 5.2–5.9 cm; cut eight from a sheet of kaishi since about the 14th century; hung at Tanabata), JLReq on vertical setting (Latin turned sideways, short figures set upright as tate-chū-yoko), and Kenya Hara's emptiness (the empty part of the rail as room, not lack).
- **Parts**: `Tanzaku` (cord, slip, kanji head, sideways name clipped to the slip, upright figure at the foot, `level` as hang length between half and full `reach`, bone plate and a red seal when selected, the seal hanging under an urgent one, dashed edges, a 1.8° swing on hover with an OutBack settle), `LeadStrip` (88 px, brushed kanji, Fraunces figure, a wash down to the level with an inked edge, pulled to set by drag or wheel; caption only in the room below the wash), `TanzakuRail` (a rod with knots, a right-to-left Row), `TanzakuFoot` (the hint line).
- **Sheets**: `TimeTanzaku` (a week of slips headed by weekday kanji, today sealed, past dashed; zones and ‹ week › under the rail), `SoundTanzaku`, `NetworkTanzaku`, `BluetoothTanzaku`, `PowerTanzaku`, `DisplayTanzaku`, `InboxTanzaku`. Dial's files are deleted (`DialGauge`, `DialHero`, `TileSection`, `Tile`, the seven `*Dial`).
- **Style.js**: the hands are `ledger | tanzaku | prose`; a saved `dial` (or `sheetStyle:x dial` from a script) is read as `tanzaku`. Test updated (114).
- Settings › Sheets names the hand 短冊 Tanzaku. Harness `sheets-tanzaku.json` (was `sheets-dial.json`); image `docs/revision2/images/r2-sheets-tanzaku.webp`.

### Margin and Leaf removed ✅ (asked for: "remove the Margin and Leaf designs completely")
Two designs are left: Hanko (Classic, the Typeset bar, still the default) and Shōji. With one Kata design there is nothing to borrow from, so borrowing went too. Shōji renders exactly as before: every Shōji harness render (`kata-*`, `overview-shoji`, `overview-kata-light`) and the Classic overview were compared pixel by pixel with the previous code and are identical.
- **`core/Kata.js`**: `DESIGNS` and `DESIGN_NAMES` are `classic` and `shoji`; `PARTS` keeps one variant per part, Shōji's (washi, slide, brush, wash, brush, enso, carved, stamp, tategaki, rows, framed, stroke; partners cut, lattice, johakyu), and `AUTO` follows. Classic resolves Shōji's parts (it used Margin's), still unused. `RETIRED` maps `margin` and `leaf` to `classic`, so a style.json (or a monitor's override) naming them loads as Hanko with no warning; `withDesign` refuses them, so `hanko design margin` says unknown. `withBorrow`, `surprised` and `MAIN_PARTS`-driven mixing are gone; `resolve()` no longer returns `borrowed`; a saved `borrow` is dropped quietly by `clean()` (it was valid when written) and by every Kata edit; `describe()` is the design's label.
- **`core/Skin.js`**: only `johakyu`, `cut` and washi's 0.86 are left; `dividerWidth` and `soft` (the SOFT axis, 0 for Shōji, Fraunces' default anyway) are gone; `gap` is 6 for slide, else 0.
- **QML**: every part in `bar/parts/` draws Shōji's variant only (`Surface` lost `hangs`/`lifted`, `Sign` its eyebrow and tabs, `Letter` the swipe and the tear, `PointerMark` its `label`, `Fibres` the card grain); `Joins.qml` (Margin's fold) is deleted. `KataPanelView` slides only (no fold, slip, tabs, eyebrow, `atBottom` or `pickSheet`); `PowerPanel` and `TimePanel` always use the ensō; `Heading`, `SessionRow`, `KataList` and `KataBar` lost Leaf's caps, gaps, plate and card edges; `OverviewPage` keeps Classic and `framed` (miniatures and contact sheets gone). `Bar.setAside` / `lettersShown` and the `dismiss` request are gone: only a swiped card or torn ticket set a letter aside. `Ink.qml` lost Leaf's `cut`, `edge`, `edgeSide`, `shade`, `shade2`, `shadeIn` and the score's two tones.
- **Settings › Design**: two cards, Hanko and Shōji; the mix line, Back to …, Surprise me and the twelve borrow rows are gone, and with them `bar/settings/PartPreview.qml` and the `borrowPicked` / `surprise` / `backToDesign` signals. The touches and Panel opacity stay; the opacity slider is Shōji's brush on either design and reads 100% on Hanko's Auto. `Typeset` lost `borrow`, `surprise` and their draft twins (`_keep` no longer keeps `borrow`); IPC lost `borrow` and `design surprise`, the CLI `hanko borrow`.
- **Left in place**: `core/Style.js` still lists `borrow` in `KATA_KEYS` and carries it through `normalize` (another change was in that file at the time); harmless, since Kata ignores it, and a cleanup for later. `docs/kata/README.md` and its prototype stay as the revision-1 proposal, with a note on top.
- Harness: `overview-margin.json` and `overview-leaf.json` deleted; `kata-bars`, `kata-panels`, `kata-panels-light`, `kata-panels-opacity`, `kata-parts`, `kata-parts-light`, `kata-wave`, `kata-wave-light`, `overview-kata-light`, `design-settings`, `design-settings-narrow` show Shōji (and Hanko) only. Images: `docs/kata/images/04-margin`, `05-leaf`, `07-mixes`, `08-mix-light` deleted; `k3`–`k9` re-rendered.
- Unit tests rewritten for two designs, plus one that a saved Margin or Leaf loads as Hanko and a saved `borrow` is ignored (113 tests).

### Mon 紋 replaces Prose ✅ (asked for: "remove the prose; research ancient Japanese culture, rōnin, samurai, ninja, and come up with something unique, stylish and premium")
Why a crest book: what a samurai carried into the field was his house's mark. The sashimono banner on his back and the crest on his kimono said whom he served, and a rōnin was a samurai with no lord's crest left to bear, so "the one you bear" is the selected choice. Research: kamon are drawn with compass and ruler only (Bridges 2018 on their geometric construction; the kuyō 九曜 nine-star crest of the Hosokawa and others; 引両 bars, 菱, 井桁, 輪違い); monchō, the crest books that listed them a page at a time; sashimono and battle banners; rakkan (the artist's seal) for the red; ninja manuals (Bansenshukai) were considered for a scroll-of-secrets hand and set aside, since a hidden-ink look would hide what a sheet must show; gunbai and tsuba were studied as shapes and found too close to a dial.
- **`core/Mon.js`**: `ORDER` (the six plain crests: bars 1/2/3, hishi, igeta, wa), `at(i)` (wraps, negative too, so neighbours never repeat), `WEEKDAYS`. 1 test (114).
- **Parts**: `Crest` (a Canvas kamon: `kind` kuyo/hours/bars/hishi/igeta/wa/moji, `level`, `count`, `glyph`, `inked` (a seal-red disc with the crest cut out in paper), `urgent`, `faint`, `turn`), `CrestCell` (a crest of at most 54 px with its name and a mono note, turns 30° on hover), `MonHero` (a 132 px crest, set by a click on a star or the wheel in eight steps; Fraunces figure, italic title, mono lines, buttons), `MonPage` (brush kanji, label, rule and summary over a grid of crests).
- **Sheets**: `TimeMon`, `SoundMon`, `NetworkMon`, `BluetoothMon`, `PowerMon`, `DisplayMon`, `InboxMon`. Prose's files are deleted (the seven `*Prose`, `ProseText`, `ProseIndex`, `IndexRow`).
- **Style.js**: the hands are `ledger | tanzaku | mon`; a saved `prose` is read as `ledger` (and `dial` still as `tanzaku`).
- Settings › Sheets names the hand 紋 Mon. Yuji Boku re-subset for the new kanji. Harness `sheets-mon.json` (`sheets-prose.json` deleted); image `docs/revision2/images/r2-sheets-mon.webp` (`r2-sheets-prose.webp` deleted).

### Mon 紋 taken out ✅ (asked for: "Mon is not looking good; remove it and come up with more designs")
The seven `*Mon` sheets, `Crest`, `CrestCell`, `MonHero`, `MonPage`, `core/Mon.js`, `sheets-mon.json` and `r2-sheets-mon.webp` are deleted. `SHEET_STYLES` is `ledger | tanzaku`; a saved `mon` (like `prose`) loads as a ledger, and `sheetStyle:x mon` is refused. Test updated (113). The research for it stays above. The next third hand is chosen from rendered design studies before it is built for all seven sheets.

### Sheet hands: Shōgi 将棋, Soroban 算盤, Odoshi 縅, Kasumi 霞 ✅ (asked for: "make the sheet for all cell sheets in Shōgi, Soroban, Odoshi and Kasumi … give all these 4 options in the Sheets tab in settings")
All four studies were built, each for all seven sheets; the hands are now `ledger | tanzaku | shogi | soroban | odoshi | kasumi`.
- **`core/Hands.js`** (+ 4 tests, 117 in all): `HANDS`, `model(sheet, feed, now, lib)` turns any sheet's feed into one model: `hero` (mark, name, figure, unit, line, caption, red, level, `rank` when its level is a row of its own, `set` when you can set it, `min`, `scales`), `levels` and `choices` (rows: name, mark, detail, note, figure, level, count, lead, muted, urgent, selected, dashed, `set`, `click`), `choicesLabel`/`choicesMark`, `inline` (short choices: Time's week), `tally` (what the abacus counts when not the rows), `lines`, `hint`, `note`, `buttons`, `keys`. `ranks(m)` puts the hero first for hands that draw it as a row; `setArg(set, v)` builds the request (`stream` gets `{id, name, value}`). `lib` is `{ T: Time.js, St: Status.js, B: Blue.js }`, passed in because core modules don't import each other. Every request is one the Ledger already sends; nothing new in `Bar.sheetRequest`. Letters' freshness wanes over `FRESH_MS` (8 h).
- **`bar/sheets/`**: `HandSheet` (the frame: eyebrow, the hand's body as default property, lines, a wrapping hint, ActionBar from `model.buttons`, Up/Down/Left/Right and letter keys from `model.keys`; `act(o)`, `pick(row, v)`), `ShogiHand` (+ `Koma`, moved from the studies; pale wood with an inked edge on light paper), `SorobanHand` (inline `Bead`; a click on a bead flicks it), `OdoshiHand` (+ `Lame`: `count`, `marks` for a lame of days drawn as runs of normal scales, `stitched`, `settable`), `KasumiHand` (+ `MistBand`: settable by click, drag or wheel from the side it drifts in from; the shortest band fits its name), `FigureHero` (Shōgi and Soroban's hero).
- **`SheetView`**: `handModel` (built when the hand is one of `Hands.HANDS`) and one component per craft hand, not one per sheet.
- **`core/Style.js`**: `SHEET_STYLES` has the four; nothing else changed (saved files, `sheetStyle:<sheet>|all <hand>` work as before).
- **Settings › Sheets**: six hand cards, three to a row (two under 720 px), the per-sheet Segmented with six plain names; the blurb names all six.
- Yuji Boku re-subset from the full Google Fonts file with fontTools (`pyftsubset --layout-features='*' --name-IDs='*' --notdef-outline`, the old cmap plus every kanji in the sources): 将棋 算盤 縅 駒台 内 外 均 省 速 式 年 were missing (514 glyphs, 659 KB).
- Studies deleted (`tests/harness/studies/`, `scenes/Studies.qml`, `params/studies-sound.json`); `r2-studies-sound.webp` stays as the record. Harness `sheets-shogi`, `sheets-soroban`, `sheets-odoshi`, `sheets-kasumi` (all seven sheets each), `sheets-hands-light` (two sheets per hand on Flexoki light); `sheets-settings` now saves a mix of hands. Images `docs/revision2/images/r2-sheets-<hand>.webp`, `r2-sheets-hands-light.webp`, `r2-sheets-settings.webp`.
- Departures from the studies, and why, are in [revision2/sheet-hands.md](revision2/sheet-hands.md) under each study ("Built:").

Below is the study write-up as it was before the pick:
- **Shōgi 将棋**: a level is a rank of nine squares and its piece (a pentagonal koma) stands on the square of its level; file numbers ９..１ over the board, rank numerals 一二三 down its side, hoshi dots; outputs wait on the piece stand (komadai), the one playing promoted (its character red, as a promoted piece's reverse is written); a muted app's piece is turned away (the opponent's).
- **Soroban 算盤**: each level counted in beads on two rods (tens, units): the heaven bead is five, earth beads one, counted when pushed to the beam; unit dots part readings; the master's beads red.
- **Odoshi 縅**: armour lacing; a crown plate (kanmuri-ita) holds the master; each choice a lame of kozane laced densely in scarlet (kebiki, hi-odoshi) to its level and sparsely beyond (sugake); the output in use laced in full with hishinui cross-knots at its foot.
- **Kasumi 霞**: the suyari-gasumi mist bands of Yamato-e scrolls and gold screens; each choice a band of gold leaf as long as its level, drifting from alternate sides; the one in use gilded whole and sealed.
The research, each study's strengths and weaknesses, the rejected hands and sources are in [revision2/sheet-hands.md](revision2/sheet-hands.md).
(All four were built; see the entry above.)

### Shōji into Hanko · S1, Shōji as a sheet hand ✅
The first of five steps (plan below, in §10). Shōji's panels are a seventh sheet hand, `shoji` 障子, on the Hanko bar.
- **Moved** (`git mv`, no edits): `bar/kata/{Time,Sound,Network,Bluetooth,Power,Letters}Panel`, `KataList`, `Figure`, `Heading`, `SessionRow` into `bar/sheets/`; `KataPanelView` became `bar/sheets/ShojiPanel.qml`. `bar/kata/` is gone (and from `tests/run`'s lint list). The old Shōji design still prints the same panels through `SheetWindow.kataView`: `kata-panels.png` is pixel-identical before and after.
- **`ShojiPanel.ownDisplay`**: Display opens its own panel (明 Display); without it (the Shōji design, whose bar has no LUM cell) Display still opens Power, which then shows brightness. As a sheet hand it is always on, so Power there is battery, mode and session only.
- **`bar/sheets/DisplayPanel.qml`** (new): the brightness figure (scroll it), `KataSlider` (never under 1%), night light on `KataSwitch`, Monitors with "Arrange ›" (`edit`), a `KataList` of monitors (a click picks an enabled one); Up/Down, N. Same requests as `DisplaySheet`.
- **`SheetView`**: `skin`, `side`, `rail` (`hand === "shoji"`). A Shōji sheet shows a `ShojiPanel` instead of the `SheetCard`; width and height follow the panel.
- **`SheetWindow`**: passes `barWindow.skin` (Kata resolves Shōji's parts and touches even under the Hanko design, so the hand wears Shōji's skin, your touches and Panel opacity); `railGap` hangs a Shōji sheet `skin.gap` below the bar; `Behavior on x` slides it along the rail when another cell is clicked; `place()` sets its `side`. Tab walks every sheet, Display included.
- **`Style.js`**: `SHEET_STYLES` has `shoji`. **Settings › Sheets**: a seventh card; the preview scales a panel wider than its room (Time with the season is 732 px) and gets the skin from the draft (`Sk.skin(K.resolve(doc), panelOpacity)`).
- Harness: `Sheets` scene passes the skin and the rail gap; `sheets-shoji.json` (all seven), `sheets-hands-light.json` adds Shōji Display and Time, `sheets-settings.json` has Inbox in Shōji. Images `docs/revision2/images/r2-sheets-shoji.webp`, light and settings refreshed. Unit test updated (117).

### Shōji into Hanko · S2, the framed overview ✅
- `Style.js` `OVERVIEWS` and `Settings.js` `OVERVIEW_OPTIONS` gain `framed` (the Panels card row offers grid · dynamic · framed; `hanko style set overview framed`). `Overview.js` `LAYOUTS` stays grid/dynamic: framed is the grid, printed another way.
- `OverviewWindow.framed` = the Shōji design or `overview: framed`; `dynamic` only when not framed; the view gets `barWindow.skin` when framed. Kata resolves Shōji's parts under the Hanko design too, so the skin's `overview` is `framed` and `OverviewPage` prints washi pages in lattice frames unchanged (the pages match the Shōji design's render; only the bar above differs).
- Harness: the `Overview` scene prints framed pages under the Hanko bar for `overview.layout: "framed"`; params `overview-framed.json` (dark) and `overview-framed-light.json` (Rosé Pine Dawn); image `docs/revision2/images/r2-overview-framed.webp`. Unit test extended (117).

### Shōji into Hanko · S3, Shōji's bar parts as Hanko options ✅
- **`core/Style.js`**: new values `seal: carved`, `spaces: brush`, `title: ink`, `clock: season`, `media: ink`, `status: ink`, `notif: seal`, `surface: washi` (the `none` options stay last), and a twenty-third setting, `pointer: plain | brush` (every preset `plain`, so no preset looks different: phase4, phase5, phase9 and bluetooth-styles render pixel-identical to before). 1,304,596,316,160 combinations. Shōji's touches are global settings beside `typeSize`: `SEASONS`, `NUMERALS`, `GRAINS`, `TOUCH_DEFAULTS` (kanji, arabic, fine: Shōji's), `normalizeTouch` (an old `touches` object is read in; `KATA_KEYS` is `design`, `borrow`; `touches` is dropped from the top and from monitors), `resolve()` gives `season`, `numerals`, `grain`, `withSetting` takes them. `Typeset._keep` keeps them.
- **`core/Kata.js`**: `touchesOf(doc)` reads the top-level keys over a legacy `touches`; touches are global (a monitor's own touches are gone); `withTouch` writes the top-level key and folds an old `touches` in, so the Design page's touch rows still work until S5.
- **`core/Settings.js`**: rows `numerals` (Left), `season` (Centre), `pointer` (Edge), `grain` (Frame); `TOUCH_OPTIONS`; details mention Shōji's values. `Settings.changes` counts the touches (they resolve).
- **`BarSurface`**: `skin` = `Sk.skin(K.resolve({ design: "shoji", season, numerals, grain }), panelOpacity)`, so every Shōji value draws in Shōji's skin with your touches; `surface: washi` adds `Fibres` to the paper; `lettersOnSeal` (`notif: seal` with a seal showing) hides the inbox, gives the seal the count, makes it the inbox (left opens, middle is DND, right the Omarchy menu) and anchors the inbox sheet under it; `pointer: brush` is a `HoverHandler` and a `PointerMark` over the cells (`pointables`, `pointedRect`), at the foot (near the top at `position: bottom`); `pointAt` (a cell name) points for the harness. The parts are imported `as Parts` (unqualified, `parts/Divider` shadowed BarSurface's own inline `Divider`).
- **Components**: `Seal` `carved` (KataSeal, pressed red with the count only under `notif: seal`); `Workspaces` `brush` (a cell per desk, `PointerMark` under `liveCell`, `UnreadMark` on urgent, `numerals`); `WindowTitle` `ink`; `NowPlaying` `ink`; `Clock` `season` (`Season.label(now, season)`); `StatusRow` `ink` (a branch in `Reading`; items carry `src`, their raw reading; the battery a `Ring`; brightness a new `sun` in `Icon`; names on reach; no meters). `StatusRow` now signals `_cellsChanged()` when a cell reports itself, so bindings that look cells up (the pointer) re-run.
- Harness `shoji-parts.json` and `shoji-parts-light.json` (Strips: each value alone, the touches, pointing at cells, every value together at 40 and 32 px and at the bottom); `Strips` passes `pointAt`. Images `docs/revision2/images/r2-shoji-parts.webp`, `r2-shoji-parts-light.webp`. Unit tests: Kata touch tests rewritten, one for the Shōji values (118).

### Shōji into Hanko · S4, the Shōji preset and migration ✅
- **`core/Style.js`**: `PRESETS["Shōji"]` (carved, brush, ink, season, center, ink, ink, ticks off, notif seal, device, indicators active, icon, hairline, rules off, pointer brush, 40, washi, top, sheets, ma, koyomi, bare, both); `PRESET_NAMES` has seven. `PRESET_BESIDE["Shōji"]`: `withPreset` also sets every sheet to the `shoji` hand and `overview: framed` (kept afterwards). `presetName` folds case and the macron (`foldName`), so `shoji`, `SHOJI`, `Shōji` all work.
- **Migration** in `normalize`: a top-level `design` of Shōji runs `fromShojiDesign` first: preset Shōji, only the `height`, `position`, `bluetooth` edits kept (`SHOJI_KEPT_EDITS`, what `KataBar` honoured), every sheet still on the ledger to `shoji` (a hand you picked stays), `overview: framed`; `design` and `borrow` dropped. A monitor whose `design` differs from the file's gets that preset's values under its own overrides (`designOf`). `normalize` never writes `design` again, so Kata always resolves classic and `KataBar`, `SheetWindow.kataView` and the Kata overview are unreachable (removed in S5). `kataOf` is gone.
- **`Typeset.draftDesign` / `setDesign`** (Settings › Design, IPC `design`, `hanko design`) apply the Hanko or Shōji preset (`presetForDesign`); the Design page lights the card for the preset in use. Its two card previews now both follow the document (so both show Shōji under the Shōji preset); the page goes in S5.
- **Settings**: `PRESET_BLURBS` gains Shōji ("washi and the seasons"); the preset row holds all seven at 1000 px and up, else four, then two.
- **Compared** with the Shōji design (`kata-bars.png`) in the same eight states (`shoji-preset.json`; `pointAt` now also brings out an ink cell's name, via `StatusRow.reachKey`): the same seal, count, desks, title, clock and season, media, icons, ensō, red states, names on reach and brush pointer. Differences: Shōji drew one hairline between now playing and the status icons and none elsewhere, the preset has none (`rules: off`; `on` rules every group); the left end starts 4 px further left (Hanko's 6 px margin against Shōji's 10 px plus cell padding); indicators show as Hanko's stamps when on (Shōji had none); the preset gains what `KataBar` lacked (tray, keyboard and mic marks, hosted widgets, a brightness cell on laptops, the scroll, per-monitor settings).
- Tests: the per-preset arrays gain Shōji's value; the Kata normalize test is the migration test; one for the preset (spellings, sheet hands, overview, values) (119). Harness `shoji-preset.json`; image `docs/revision2/images/r2-shoji-preset.webp` (beside `docs/kata/images/k4-bars.webp`).

### Shōji into Hanko · S5, removal ✅
- **Deleted**: `bar/KataBar.qml`, `bar/settings/DesignPage.qml`, `core/Kata.js`; harness scenes `KataBars`, `KataPanels`, `KataWave` and params `kata-bars*`, `kata-panels*`, `kata-wave*`, `design-settings*`, `overview-shoji`, `overview-kata-light` (replaced by `shoji-preset`, `sheets-shoji`, `overview-framed*`). `Kata.qml` is now `scenes/Parts.qml` (params `parts.json`, `parts-light.json`; `styles: [style doc]` per column in place of `designs`).
- **`core/Skin.js`**: `SHOJI` (the part variants Kata held) and `fromStyle(style)`; `BarSurface`, `BarWindow` (`skin`, for the sheet hand and the framed overview), `SheetsPage` and the scenes use it.
- **Windows**: `BarWindow` draws `BarSurface` only (`surface`); `SheetWindow` lost `kata`, `kataView`, `kataOrder` (Tab is `bar.cycleSheet` everywhere); `OverviewWindow.framed` is `overview: framed` alone.
- **`Typeset`**: `kata`, `kataFor`, `designNames`, `kataParts`, `describeDesign`, `setDesign`, `touch`, `draftDesign`, `draftTouch` and the Kata warnings are gone; `_keep` no longer keeps `design`. `Style.js` still reads a saved `design` (the S4 migration) and never writes it.
- **IPC / CLI**: `designGet`, `design`, `designDescribe`, `touch` and `scripts/hanko design|touch` are removed, as the user chose (no alias); `hanko style preset shoji`, `hanko style set season english`.
- **Settings**: the rail's Design page and `Settings.rail()`/`HANKO_ONLY` are gone (every page shows; the window opens on Typesetting); Panel opacity moved to Settings › Sheets (the brush slider, the figure, Auto) as `SheetsPage.opacityPicked` → `settingPicked("panelOpacity")`.
- **Panels**: `ShojiPanel.ownDisplay` is gone (Display always opens its own panel); `PowerPanel` lost its brightness slider.
- The window files lint with the same warnings as before. Unit tests: the eight Kata design tests are removed; the migration, preset and skin tests use `Style.js` and `Skin.fromStyle` (111).

### The Hanko preset is the user's bar ✅ (asked for: "the Hanko preset … the same as the one I have running, with its modifications")
- `core/Style.js` `PRESETS.Hanko` now holds the user's running edits: `seal: stamp`, `spaces: kanji`, `indicators: active`, `indicatorStyle: kanjiname`, `panels: sheets`, `guides: none` (the rest was already theirs). Since Hanko is `DEFAULT_PRESET`, these are the new defaults too. The seal glyph (寛 on their machine) stays outside presets, default 鑑.
- COMPONENTS.md (defaults, preset table, the Hanko blurb) and §5 here follow. Five unit tests that pinned the old Hanko values were updated (a switch to Scroll now moves 13 settings, not 10). Unit tests: 111.
- The user's `~/.config/hanko/style.json` still lists those six as edits; they now equal the preset, so they change nothing.

### The right side, four ways ✅ (asked for: "the right side looks too cramped … research game principles, articles, papers … a better design with a Japanese touch; show me the design in images first", then "I like them all, add all")
- **Design first**: six study sheets drawn in HTML (`docs/right-side/source/kit.html`, rendered with headless Chromium) on the user's real bar: a diagnosis (five identical cells, about thirty marks for five facts, ≈ 846 px) and four cures, Ma 間, Shizuka 静, Suji 筋 and Inrō 印籠, with the research (Tufte's data-ink and sparklines, Weiser and Brown's calm technology, game HUD minimalism and show-on-change, Gestalt proximity and common region, ma and kanso). `docs/right-side/README.md` has it all with sources.
- **`core/Style.js`**: `status` gains `ma`, `shizuka`, `suji`, `inro` (2,609,192,632,320 combinations); four presets on the Hanko bar (`Ma`, `Shizuka`, `Suji`, `Inrō`; marks as kanji stamps, meters off; Ma also `rules: off`, `interlude: ma`); `PRESET_GROUPS` (Bars, Right-side studies) for the Presets page.
- **`core/Status.js`**: `short(name)` (a short all-caps brand dropped, first word kept, the next when the first is under five letters: OPPO Enco Buds2 → Enco Buds2, Infinix NOTE 50S 5G → Infinix) and `fill(key, src)` (0..1 for every reading: network by bars, Bluetooth by charge or full when connected, volume empty when muted).
- **`bar/StatusRow.qml`**: items carry `brief`, `fill`, `link`; the studies use the cells' order. `ma`: kanji + figure, signal bars for Wi-Fi, a 2 px fill under each level, a 30 px pause where links end. `shizuka`: a clipped body that draws out from under its kanji (180 ms in, 240 ms out), unfolded for network and battery, anything needing you, a fresh change (held 2 s instead of 0.9 s) or while a `HoverHandler` sees the pointer on the zone; five ticks while a level is open. `suji`: a 30 px line, 3 px stroke over a dotted range, the figure crossfading into its place on reach. `inro`: a hairline case (`caseHeight`) with 1 px walls, compartments `kanji over value`, a bone plate under the pointer, one line at 32 px. `reachKey` (the harness's `pointAt`) stands for the pointer in all four.
- Harness `right-side.json` and `right-side-light.json`: today's bar, each study at rest, reached and with a low battery, all four at 32 px, and `status: inro` on the Hanko preset with named stamps. Images `docs/right-side/images/10-built-dark.webp`, `11-built-light.webp`. Unit tests: 113.
- **Harness note**: PySide6 6.12 resolves `Color` (qs.Commons stub) to something else and every colour comes out undefined (green renders, the motion probe fails); 6.10.1 renders as before. Pin `PySide6-Essentials==6.10.1` until the stub is renamed or qualified.

### Presets 型, a page of their own ✅ (asked for: "the presets in the Typesetting tab all move to a new page named Presets, and add these 4 designs there too")
- **`core/Settings.js`**: `RAIL` gains `presets` (Presets 型) as the first page of `01 BAR`; `pageInfo` falls back to Typesetting by key. `PRESET_KANJI` (判 帳 巻 素 計 島 障子 間 静 筋 印籠), `PRESET_FACTS` and `presetFacts(style)` (status, clock, height, surface, panels as one line), `presetMatches(name, query, PRESETS)` (name with or without the macron, kanji, blurb, any value set).
- **`bar/settings/PresetsPage.qml`** (pure): `Style.PRESET_GROUPS` gives the order and numbering of one list under a single label (Bars · 11; the studies' own label and note were taken out at the user's request), a card per preset: number, Fraunces name, kanji (red when in use), blurb, the facts in tracked caps, and a `PreviewBar` of `S.resolve(S.withPreset(doc, name))` laid out at 1600 px (`minDesign`) so a full bar never meets its clock, on bare paper (the dithered `Plate` moon was taken out of Presets and Typesetting at the user's request; About still draws it). In use: a red square, IN USE in bone, `N EDITS`; others: USE › on hover, a click emits `presetPicked` (the one in use ignores clicks). Filtered by the search field; "No preset matches" when nothing does.
- **`bar/settings/PreviewBar.qml`**: the inline `PreviewBar` from SettingsPage, now a file with `barData` and `minDesign`.
- **`SettingsPage`**: the preset grid is gone from Typesetting; in its place a preset line (PRESET Hanko 判 + N edits · ALL 11 PRESETS ›, which opens Presets). The eyebrow names the preset on both pages; the action bar shows Shuffle on Presets and Reset to preset on both. **`SettingsWindow`**: typing a search on Presets stays there (it filters the cards).
- Harness `presets.json`, `presets-light.json` (Suji in use), `presets-narrow.json`, `presets-search.json` (`glass` leaves Quiet). Images `docs/right-side/images/12-presets-page.webp`, `13-presets-page-light.webp`. Unit tests: 114.

### Kamon 家紋, the preset that was Hanko ✅ (asked for: "I don't want the Hanko name on the preset", then picked Kamon from a list)
- **`core/Style.js`**: the `Hanko` preset is `Kamon` (same values; `DEFAULT_PRESET`), first in `PRESET_GROUPS`. `PRESET_ALIASES` (`hanko` → `Kamon`) is read by `presetName`, so a style.json that says `"preset": "Hanko"`, `hanko style preset hanko` and the IPC load Kamon with no warning; a saved file is written back as Kamon on the next change. A file naming the old Classic/Hanko design loads as Kamon. The plugin, its settings window and About keep the name Hanko.
- **`core/Settings.js`**: blurb "the family crest", kanji 家紋; searching "hanko" on Presets finds it.
- Unit tests: one for the alias (115). Harness params that say `"preset": "Hanko"` were left as they are; they exercise the alias.

### Fewer presets; Ma is the user's bar ✅ (asked for: "remove Instrument and sheet and scroll ... update the ma with my current settings ... move the kamon to last")
- **`core/Style.js`**: Sheet, Scroll and Instrument are gone (eight presets). `PRESET_ALIASES` maps `sheet` and `instrument` to Kamon and `scroll` to Islet, so old style.json files and harness params still load. Ma takes the user's edits: `height: 36`, `interlude: fuda`. Order: Quiet, Islet, Shōji, Kamon, then Ma, Shizuka, Suji, Inrō.
- **`core/Settings.js`**: their blurbs and kanji removed. Unit tests updated (116).

### Inkan 印, the seal only ✅ (asked for: "now I want to work on this Inkan … tell me the full plan", then "go with your idea and all")
- **I0 · design** (`docs/shell-concepts/inkan/`): five sheets drawn in HTML (`source/kit.html`) before any code: the seal's states, No. 00, the corners and a form per monitor, the ink-press, a light theme. The kit draws the wear with the same seeded specks as `core/Inkan.js`.
- **I1 · model**: `form: bar | inkan` and `inkanAt: top-left | top-right | bottom-left | bottom-right` (26 settings, 31,310,311,587,840 combinations; a shuffle never touches either), the **Inkan** preset (Kamon + `form: inkan`, its own group "The seal only" on Presets). `core/Inkan.js` (+5 tests): wear from the battery (1 at ≥ 60 %, charging or no battery; 0.3 at empty), seeded `specks` and `worn`, `chips` (1 for 1–2 letters, 2 for 3+, deep when urgent, none under DND), `carving` (glyph = sealGlyph, or the workspace numeral under `seal: workspace`; `outline` when quiet or `seal: carved` with no letters; `broken` offline; `live` recording/dictation), `reading`, `rows`, `place`, `sheetPlace`, `nearest`. Lists from QML are counted by length (`Array.isArray` is false for a model's nested list: the chips vanished in the first render).
- **I2 · the seal**: `bar/InkanSeal.qml` (Canvas plate with chips and inner rule, glyph, a Canvas of specks in `Ink.seal` over it; rest tilt −1.5° straightened on hover; `pressed` 0.92 on the stamp curve; `bloom` pool) and `bar/InkanReading.qml`. Harness scene `Inkan.qml`, params `inkan.json`, `inkan-light.json`.
- **I3 · the layer**: `bar/SealWindow.qml` per screen inside `BarWindow`: `WlrLayer.Top`, namespace `hanko-seal`, `ExclusionMode.Ignore`, anchored to its corner, wide enough for the reading, `mask: Region { item: sealArea }`. `BarWindow.parked` (hidden or inkan) parks the strip; `BarSurface` invisible. `Bar.barSize` is 0 under `form: inkan` (read from `Typeset.current`, so a per-monitor-only Inkan still reports the bar). Click = `Bar.pressSeal`, right = menu, middle = terminal, wheel = workspaces.
- **I4 · No. 00**: `Sheets.ALL` (kept out of `SHEETS` so Settings › Sheets doesn't list it; `byKey` and `step` know it), `bar/sheets/AllSheet.qml` (always the ledger hand). `SheetWindow` under Inkan: `Inkan.sheetPlace` from the seal, `atBottom` from the corner, the mask subtracts the seal (a click there lifts the sheet off), a `‹ NO. 00` crumb and Backspace when `Bar.sheetFrom === "all"`; `feed.all` carries the rows, spaces, window and media. `Bar.sheetRequest("all", open|workspace|media|menu|settings)`, `backSheet`, Tab includes No. 00 only under Inkan. `ScrollWindow` under Inkan unrolls from the seal's edge (`strip` = margin + seal + gap). On the bar, `hanko press` prints No. 00 from the bar's seal (`BarSurface.anchorFor("seal")`).
- **I5 · ink-press**: `SealWindow.press()` when something prints from it (sink 140 ms, bloom 200 in / 400 out); `SheetWindow.printed` delays the print by the stamp under Inkan and `lift` (220 ms, 6 px away from the seal, fading) replaces the un-print.
- **I6 · settings and CLI**: Form and Seal corner rows in the Frame card; `PreviewBar` draws the seal and its reading under Inkan (Typesetting and the Inkan card); `Settings.presetFacts` names form, corner and panels; `scripts/hanko press`, `scripts/hanko inkan [on|off]`; README key `SUPER + ALT + I` (free in Omarchy; `SUPER + CTRL + I` is taken). The CLI's help now prints the header comment however long it is.
- **I7 · drag and ring**: drag the seal (8 px threshold): it follows inside its layer, the reading says where it will go, and on release `Bar.moveSeal` saves the nearest corner for that monitor (`setFor`), or for the style with one screen. Recording or dictation draws a breathing red ring and leads the reading in red.
- Unit tests: 121.

### Kōsei 校正, Typesetting as a proof ✅ (asked for: "all are just crumbled in Typesetting … take your time, research how people create this kind of experience, then come up with something unique and premium, not AI slop")
- The six cards of 33 segmented controls are gone. Research (configurators, FFXIV/WoW HUD edit modes, thumbnails-with-text studies) and renders in `docs/settings-kosei/`.
- **Galley** (`bar/settings/Galley.qml`): one `BarSurface` (opacity 0, measured) at the screen's width (`barData.screenWidth`, 1920 by default); two `Line`s draw the same bar cropped, split 28 px before the centre clock (45 % with the clock at the right), at one scale ≤ 1. Brackets on hover and on the open part; numbers in the margin under each placed part (bone plate with its name when open, a red dot when edited). Anywhere off a part = Frame. Under `form: inkan`, a small screen with `InkanSeal` and `InkanReading` in its corner.
- **Case** (`TypeCase.qml`): heading (number, Fraunces name, kanji), edits with PUT BACK (sets the preset's value), specimens per `cast` setting (2–4 across; wide parts get wider tiles), then `also` rows (Segmented; the glyph as four red stones and …, which opens Advanced).
- **Specimen** (`Specimen.qml`): a `BarSurface` 1920 wide with the one setting changed, cropped to `partRect(part)` ± 16 px and enlarged up to 1.6×; edge = a 2.2× close-up of the foot around the hour with the bar above faded out; surface = the left 300 px over a hatch (glass shows through); form = a schematic screen. Hover emits `tried` → `SettingsPage.trial` → `proofStyle` on the galley; click emits `picked`.
- Both measure 30 ms after `layoutTick` changes (a Row places children in a later pass; a binding over `mapToItem` latched half-laid-out positions and cropped the wrong part). `BarSurface.partRect(part)` and `layoutTick` are new.
- `SettingsPage`: `part` (+ `partPicked`, `stepPart`, `pickPartAt`), `trial`, `litParts` (search), `partShown` (the first lit part when the open one isn't), `editedParts`, `proofData` (sample stamps when none is on). The preset chip sits beside the title. `SettingsWindow`: ← → and 1–0 on Typesetting; `screenWidth` and `indicators` in `barData`.
- Panels open as, Scroll sides, Scroll guides and Overview are `Settings.PANELS_CARD` at the top of Scroll 巻.
- Harness: `proof.json` (Ma, Status), `proof-light`, `proof-inkan`, `proof-narrow` (820 px), `proof-frame`, `proof-trial` (Inrō tried). Unit tests: 121.

## 10. Instructions for the remaining phase (10)

### Shōji into Hanko: the plan (asked for; S1 done, S2–S5 to do)

The user asked for Shōji to stop being a separate design: "Shōji should be part of Hanko … we can tweak Hanko to get the Shōji design, and all its sheets move to the sheets in Hanko". There will be one design, Hanko. Shōji becomes (1) a sheet hand, (2) new option values on Hanko's settings, so each Shōji part can be mixed in alone, and (3) a preset that sets them all. Picking the Shōji preset must reproduce today's Shōji, which then also gains what `KataBar` never had: indicators, tray, hosted widgets, keyboard and mic marks, the brightness cell, the edge, the scroll, every setting and per-monitor overrides.

**The user's decisions** (2026-10-09): build a new Shōji Display panel (done in S1); keep Shōji's rail (done in S1); remove `hanko design` (no alias); go step by step, one commit per step, showing renders before the next.

**Mapping of Shōji's bar parts** (S3), all drawn from the existing `bar/parts/` with the skin `BarWindow` already resolves:

| Shōji part | Hanko setting |
|---|---|
| washi surface, fibres | `surface: washi` (new; panel opacity 86% unless set) + global `grain: smooth \| fine \| toothy` |
| carved seal, pressed red with the letter count | `seal: carved` |
| the seal is the inbox | `notif: seal` (the count on the seal; the inbox cell goes) |
| desks with a brush mark under the current, 未 on unread | `spaces: brush` + global `numerals: arabic \| kanji` |
| time, date and the season | `clock: season` + global `season: off \| kanji \| english` (the Shōji Time panel reads it too) |
| icon and figure, name on reach, battery as an ensō | `status: ink` (meters do not apply) |
| brush mark under the hovered cell | new setting `pointer: plate \| brush` |
| window title, now playing | the closest existing values; add `ink` to each if they differ on screen |
| framed overview | `overview: framed` (S2) |
| no edge | the preset sets `edge: hairline`, `rules: off` |

`season`, `numerals`, `grain` sit beside `motion` and `typeSize` (global, kept by presets, resets and shuffles, counted by `Settings.changes`), replacing Kata's `touches`. New options change `combinations()` and `Profile.combination`.

**Steps**, each a commit pushed to `dev`, with renders dark and light:
- **S2 · overview** ✅ (see §9).
- **S3 · bar parts** ✅ (see §9). `title: ink` and `media: ink` were added as the plan allowed; the skin is built in `BarSurface` itself, not passed from `BarWindow`.
- **S4 · preset and migration** ✅ (see §9).
- **S5 · removal** ✅ (see §9): `KataBar.qml`, Settings › Design (`DesignPage.qml`, its rail entry, `designPicked`/`touchPicked`), `SheetWindow.kataView` and `kataOrder`, `OverviewWindow.kata`, the Kata `design`/`touches` resolution (keep a small skin-from-style helper), IPC `designGet`/`design`/`designDescribe`/`touch`, `scripts/hanko design` and `touch` (removed, no alias), `Typeset.setDesign`/`touch`/`kata`, Kata harness scenes (`KataBars`, `KataPanels`, `KataWave`, `design-settings*`), and `ShojiPanel.ownDisplay` (always on). Panel opacity moves to Settings › Sheets. Docs: README (the "Two designs" line and its image), ROADMAP, COMPONENTS, CHANGELOG, this file; `docs/kata/` stays as history.

Each phase: read the matching Typeset mockups and the HTML kit first, keep `BarSurface` pure (data in, signals out), add services for live data, add a `tests/harness/params/phaseN.json` covering every option and state, and follow §11.

### Kata 型 (history)

Kata is finished and folded away: Shōji is part of Hanko (§9, "Shōji into Hanko"), `core/Kata.js`, `KataBar` and Settings › Design are gone, and `bar/parts/` are Shōji's parts drawn in `Skin.fromStyle(style)`. The notes below are the instructions as they were. The spec is `docs/kata/README.md`; the HTML prototype that shows every part and panel in every design is `docs/kata/prototype/` (open `playground.html` or `desk.html?design=shoji&panel=sound`; `kata.js` holds the panel markup to port). The prototype still shows Margin and Leaf, which were removed (see §9, "Margin and Leaf removed"); only Shōji is built. Shōji's own prototype is on `design3` (`docs/design3/`). Rules that hold for every Kata phase:

- Content is written **once**, against `bar/parts/` and plain data; it never asks which design is active. If it needs to, a part is missing: add it to `core/Kata.js` `PARTS` (with Shōji's variant and unit tests), to `Skin.js` if it needs tokens, and a component in `bar/parts/`.
- Every part takes `skin` (from `Skin.skin(kata)`); BarWindow builds one per screen (`win.skin`). Use `Ink.ink2/ink3/ink4/kLine/lift/paper2/sunk`; never pick a colour.
- Red means "for you" only. Figures in Fraunces with `Type.axes(size, wght)` and `tnum`; words in Space Grotesk; kanji `Type.jpSerif` at ≥ 18 px, `Type.jp` below.
- Motion through the skin: `skin.open/openCurve` to arrive, `leave/leaveCurve` to go, `settle` inside; `Motion.ms()` and `Motion.live` as everywhere (the harness forces still).
- Add a harness scene or params per phase, render dark and light, and save the renders to `docs/kata/images/k<N>-*.webp`.

*(K5 and K6 below are the original instructions, both done; the Margin and Leaf variants they name were removed later.)*

**K5 · Kata's panels.** One `bar/KataPanelWindow.qml` (a layer surface per screen, `hanko-panel` namespace, the `SheetWindow` pattern for input mask, focus prime and click-away) that BarWindow uses instead of `SheetWindow`/`ScrollWindow` when `!kata.classic` (keep Classic on the old ones). Placement from `surface.anchorFor(cell)`; hanging by `skin.gap` (fold −1 overlaps the bar's line and draws the concave joins when corners are soft; slip 0, clipped so it comes from under the bar; slide 6 px below). Arrival by `skin.arrive`: fold = scale-y from the top plus a clip and a fading crease band; slip = translate up from behind the bar; slide = translate in from the side the cell is on, and when `skin.travels` a second cell **moves the same panel** along the bar (animate `x`/`width`, swap content). Frame: `Surface` (`hangs` for fold/slip) and, for `sign: tategaki`, a 52 px `Sign` column on the right; `sign: tabs` hangs `Sign` tabs from the foot (Time, Sound, Network, Power, Letters; `picked` switches); `sign: eyebrow` puts `Sign` at the top of the content. Panels as `bar/kata/SoundPanel.qml`, `TimePanel`, `NetworkPanel`, `PowerPanel`, `LettersPanel`, each a pure Column fed by the data the Classic sheets already use (`core/Sound.js`, `Time.js`, `Net.js`, `Power.js`, `Blue.js`, `Status.notifications`, `services/Weather.qml`, `Season.at()` for Time's kō) and emitting the same actions the sheets do (read `bar/sheets/*Sheet.qml` and how `Bar.qml` wires them; reuse those handlers). Layouts to copy from the prototype: Sound = hero figure + `KataSlider` + "Plays on" list with `Selection` + app rows with thin sliders + mic row; Power = `Ring` hero (ensō or figure + glyph) + "About N left" + brightness slider + a segmented power mode + quick chips + session actions with hold-to-confirm; Letters = notifications with `UnreadMark`, Quiet switch, actions; Time = the day in a serif sentence, a month grid (today ringed by an ensō when `ring: enso`), Shōji's kō in tategaki when `season` is on, weather, other cities; Network = Wi-Fi hero name, nearby list, Bluetooth. Keyboard: Esc closes, Tab walks the cells in `rightCells` order. Harness: a scene with each panel × each design (dark), and a light mix.

**K6 · the whole-screen pieces.** Second-wave parts with the same mechanism (add each to `PARTS` with variants and tests): `notify` (Margin cards with swipe, Leaf tickets that tear at a perforation, Shōji rows with 未), `overview` (Margin miniatures, Leaf contact sheet, Shōji framed desks with both numerals; reuse `OverviewWindow`'s data and keys), `hold` (Leaf's ink soak for session actions, which Margin and Shōji share). Then the overview and notifications use them when `!kata.classic`.

**K7 · Settings › Design** ✅ — done; see §9.

### Workspace overview 一覧 ✅ (asked for by the user: "a workspace overview like we have in Ryoku")
- Studied Ryoku's `shell/quickshell/shell/modules/overview/` (Overview, WorkspaceCell, OverviewSurface) for the idea, and took the **working principle** from the user's own `AyushKr2003/omarchy-overview` (after Shanu-Kumawat/quickshell-overview), which runs on real Omarchy: a full-screen Overlay layer on every screen, the keyboard (Exclusive) on the focused monitor only, a `HyprlandFocusGrab` that closes it on click-away (armed 120 ms after mapping), a fixed rows × columns grid holding the group of ids the live workspace is in with empty rows folded, arrows/hjkl that switch the real workspace while it stays open, digits that jump in the group, the wheel walking the group, live `ScreencopyView` snapshots found through `ToplevelManager.toplevels` and each one's attached `HyprlandToplevel.address`, a click to go, middle-click to close a window, drag to move it with `hl.dsp.window.move({ window = "address:…", workspace = "N", follow = false })`. Ryoku's desktop strip is left out (Omarchy has no desktops).
- Hanko's look: a sheet of the theme's paper (94 %) under the bar strip (the mask leaves the bar working), a register line `── 一覧 · OVERVIEW · DP-1`, a Fraunces title, the time and `05 SPACES · 10 WINDOWS`; each workspace a page with a folio band (number, kanji numeral, window count, urgent dot; the live page's number on a bone plate with `//`), its windows at their real fractions as hairline frames over an ink fallback (the app name in Fraunces italic), the snapshot over it and a mono name tab (bone for the focused one, ◇ for floating); bare pages show their kanji large and faint; every page lies on the desk with `style.lua`'s "paper" shadow, as Hyprland draws it (offset 3, 5, a dense band then a short fade), cast in ink so it reads on the dark sheet: 55 % under the live page, 25 % under the rest; a drop target is framed in red; the carried window is a paper tab with an ink print. The keys run along the foot. Pages print in with `Motion.unroll`.
- `core/Overview.js` (+ tests): `ROWS` 2, `COLUMNS` 5, `group`, `pages(spaces, activeId, rows, cols, fold)`, `rowsShown`, `fit` (largest page at the monitor's aspect), `step` (arrows, wrapping in the group), `jump`, `wheel`, `visibleWindows` (fullscreen alone, floats last), `summary`, `KEYS`.
- `services/Hypr.qml`: each workspace also carries `all` (floating windows too, with `title` and `fullscreen`; `Spaces.layoutOf(…, keepFloating)`), and `refresh()`, `moveWindow`, `closeWindow`, `toplevelFor(address)`, `aspectFor(screen)`. `Bar.qml`: `overviewOpen`, `openOverview` (closes a sheet, the scroll and hosted popouts), `closeOverview`, `toggleOverview`, IPC `hanko overview`; sheets and the scroll close it. Right-click on the bar's workspaces toggles it (`Workspaces.overviewRequested`).
- Harness: `scenes/Overview.qml` (the bar over the sample plate, the view on top), params `overview`, `overview-light` (rows not folded), `overview-narrow` (1100 × 720, 16:10). `tests/run` lints `bar/overview`; a `ToplevelManager` stub. Unit tests: 94.

### Overview: Ryoku's dynamic layout and a setting ✅ (asked for by the user: "the exact overview UI as in Ryoku, dynamic workspaces and a plus, and in settings a toggle")
- `overview: grid | dynamic` in style.json, beside the counted settings like `typeSize` (normalize, resolve, `withSetting`; presets, resets and shuffles keep it; Typeset's reset paths carry it). A row "Overview" in the Panels card (`Settings.optionsFor("overview")`). Default `grid`, the printed pages.
- `dynamic` is Ryoku's `shell/modules/overview` rebuilt in Hanko's QML, same layout, numbers and gestures: the mark top left (the seal glyph on red, OVERVIEW, DESKTOP 01), the desktop strip top centre (122 × 58 cards, a dot per workspace, a NEW card with a +), the viewed desktop's busy workspaces and the live one as mini-desktops over the dimmed wallpaper (`~/.local/state/omarchy/current/background`), packed into centred rows at the largest size that fits (`O.lay`, 132–460 px, steps of 6), then one + cell for the first free id (`O.newWsId`); a mono ordinal chip, the apps' icons (`DesktopEntries.heuristicLookup` + `Quickshell.iconPath`; the app name when there is none), window tiles with live snapshots, ✕ on hover, hard black offset shadows that deepen as a cell lifts, staggered entrance. Keys as Ryoku: Tab/arrows/wheel move a selection without switching, Alt+Tab steps desktops, Enter or a click goes and closes, right-click goes, drag moves a window to a cell or to a desktop (its lowest workspace), Esc dismisses. Colours come from the theme: Ryoku's vermilion is `Ink.seal`, its creams the ink tiers, its cards `Qt.tint(paper, ink 3 %)`; fills are opaque so the hard shadow never shows through on a light theme.
- `core/Overview.js` (+ tests): `PER_DESKTOP` 10, `deskOf`, `deskList`, `deskDots`, `newWsId`, `slots`, `packRows`, `lay`, `cycle`, `DYNAMIC_HINT`, `LAYOUTS`. Hypr workspaces carry `monitor`, windows `cls`; the dynamic view shows only this screen's workspaces.
- `OverviewWindow.qml` holds both views and picks by `Typeset.current.overview`; `dynamicKey()` has Ryoku's keys, the grid keeps its live-switching arrows. Params `overview-dynamic`, `-light`, `-narrow` (`overview.layout`, `overview.selected`). Unit tests: 97.

### Phase 10 · Motion and release

Items 1 and 2 are done (§9). Items 3 and 4 wait for the user.

1. ~~The Scroll motion spec across the bar: inversion plates slide between items (one indicator, like Ryoku's rail); values crossfade; the now-notch creeps; a new stamp is pressed down oversized and tilted, then settles (140 ms, the only overshoot anywhere); sheets print top-down (~180 ms). A global **reduced motion** switch (Motion 動 page + style key, outside the 18 settings) that cuts every transition to its end frame.~~
2. ~~Per-monitor override UI on the settings page (Advanced).~~
3. README install guide (screenshots from renders), `manifest.json` version `0.1.0` → release version, CHANGELOG entry, listing on omarchyplugins.com (ask the user before publishing anything; the repo is private).
4. Merge `dev` into `main` **only when the user asks**.

## 11. The per-phase routine

1. `update_status` checklist in the thread (project sessions), then read the target sheets and HTML.
2. Read the Omarchy source for every data source and action you'll touch (§6 lists where).
3. Pure logic → `core/*.js` with unit tests in `tests/unit.mjs` (load it with the `load()` helper at the top of that file).
4. Components → `bar/*.qml`, pure: props in, signals out. Services → `services/*.qml` singletons registered in `services/qmldir`. Wire in `BarSurface` (props/signals) and `BarWindow` (services → props, signals → service actions).
5. Add stubs under `tests/harness/stubs/` for any new Quickshell module/type you import, just enough for lint and render.
6. Add `tests/harness/params/phaseN.json` (every option × state, plus presets) and, if needed, pass new fields through `tests/harness/scenes/Strips.qml` (use its `pick(strip, key)` helper).
7. `tests/run`; fix every new lint warning; open `tests/out/phaseN.png` and compare with the Typeset mockup; iterate until it matches.
8. Update `docs/ROADMAP.md` (phase ✅), `README.md` (status "phase N of 10" and the "Right now it draws…" sentence), and this file (§9, §12, "Last updated").
9. Commit (`Phase N: …` + trailer), `git push -u origin dev`.
10. Copy the render to `/mnt/project-files/ryoku-shell/typeset/phaseN-render.png`; reply to the user with what's new, how to try it, what to check on their machine, and what's next. Update project memory.

## 12. Known issues and things to verify on a real machine

1. ~~Status clicks don't open Omarchy's panels under Hanko.~~ **Fixed in Phase 6:** Hanko implements `summonBarWidget`/`hideBarWidget`/`isBarWidgetOpen`/`panelWidgetIdAt` and answers with its own sheets. Omarchy bar-widget panels Hanko has no sheet for (bluetooth, monitor, weather, tailscale, dropbox, agents) still log "summon: no live bar widget" until Phase 9 hosts them.
2. **Notification files are an internal Omarchy format**, not a plugin API. If Omarchy changes paths or fields, the inbox breaks silently (shows `00`). Verify on the user's machine; consider asking Omarchy for a proxy property later.
3. **Roadmap said network via `Quickshell.Networking`**; Phase 4 used `omarchy-network-status` instead (it matches what Omarchy shows and needs no extra module). Polls every 3 s.
4. **Not implemented yet from the spec:** `layout` workspaces "hover opens it to show window names"; glyph status "dashed when off" and "hover adds the Latin word".
5. **Unverified on hardware:** layer-shell behaviour at each height, `ExclusionMode` when hidden, multi-monitor per-monitor overrides, the DSP sink resolution, brightness on laptops, FileView watching a directory (`Bar.qml` hiding), Omarchy's clock format detection, Fraunces variable axes rendering in the real Qt.
6. `tests/run` does not set `HANKO_HARNESS_FONTS` itself; export it (§8) or kanji/mono may fall back to whatever the container has.
7. **Phase 5 to verify on hardware:** the inset exclusive zone (Hyprland should add the 8 px margin to it; if windows touch the frame, set `exclusiveZone` explicitly), the blur rule's field names in Hyprland's Lua config (`blur`, `ignore_alpha`), `toggleTransparency` round-tripping through `mutateShellConfig` for a third-party bar, and the rod's 8 px drag band not swallowing clicks meant for cells above it.
8. **Phase 6 to verify on hardware:** the sheet layer's input mask (clicks on the bar strip must reach the bar under it, so a second cell switches sheets in one click), the 75 ms Exclusive keyboard prime (Esc/Tab/arrows must work when a hotkey opens a sheet), the dismiss twins on other monitors, `Pipewire.preferredDefaultAudioSink` + `omarchy-audio-output-set-default` from the Sound sheet, nmcli parsing on a real scan (`FREQ` prints "5180 MHz"), `omarchy-powerprofiles-set` with the ac/battery key, `shell.summon("omarchy.speedtest"|"omarchy.wifiqr")` being allowed for a third-party bar (the host's `barPluginMayControl` says yes for panel kinds), and `omarchy-shell notifications dismissAll`.
9. **Phase 7 to verify on hardware:** the pan `MouseArea` sitting under the sections (a drag that starts on a fader or the ribbon must move that control, not the paper), wheel stepping on a touchpad (one section per 260 ms), `Behavior` on the window's `trackX` (a `PanelWindow` property, not an Item's), the Interlude Canvas cost at each theme switch, `hl.dsp.focus({ window = "address:0x…" })` from the Spaces map, and `Style.reduceMotion` existing in the user's Omarchy (`qs.Commons`).
10. **Phase 8 to verify on hardware:** the `FloatingWindow` tiling or floating sensibly (add an Omarchy window rule for title "Hanko settings" if it should float), keyboard focus landing in the window so `/`, `Ctrl+Z` and `Esc` work, the window manager's close running `closeSettings`, Omarchy's menu parser accepting the `// hanko.bar` line comment and the 印 icon in the menu font, and Canvas cost of `Plate` at 1600 px.
11. **Phase 9 to verify on hardware:** a real hosted widget's panel (Bluetooth, monitor, weather) opening under Hanko's bar through `HostBar` (its KeyboardPanel reads `bar.barSize`, `bar.position`, `bar.clickTargets`), `pluginShellForBarEntry` returning a shell for those entries, the `hosted:` cells counting right in `togglePanelAt`, tray icons inked by `MultiEffect` colorization (symbolic and full-colour), `item.display()` menus placing under the cell, the voxtype and reminder commands on a machine that has them, and the right zone's giving-way order on a narrow laptop screen.
12. **Bluetooth to verify on hardware:** `Quickshell.Bluetooth` property names on the user's Quickshell (`deviceName`, `batteryAvailable`, `battery`, `bonded`, `pairing`, adapter `discovering`), discovery starting and stopping with the panel, `omarchy-bluetooth-device` pairing a device that needs a PIN (Hanko has no PIN prompt; Omarchy's script may ask on its own), and the cell on a desktop without an adapter (it should not appear).
13. **Phase 10 to verify on hardware:** that nothing slides in at login (Behaviours wait 1.5 s; raise `Motion._wake` if a slow start still shows it), FadeText not flickering while a volume wheel spins (each step restarts the fade), the stamp press on a real notification (and not on every inbox reload: the key is timestamp + app + summary), the notch creep after suspend (a big jump creeps for 1.2 s, by design), `Style.reduceMotion` being the right name in the user's `qs.Commons`, and the per-monitor grid at 1200 px wide.
14. **Weather leaf to verify on hardware:** `curl` present and Open-Meteo and wttr.in reachable, `weather.json` at `~/.local/state/omarchy/settings/` on the user's Omarchy, the leaf's width on the user's screen (left out under about 1600 px of scroll), and the °F rule matching Omarchy's panel.
15. **Bluetooth styles to verify on hardware:** the device `icon` names BlueZ reports (they pick the mark; unknown kinds get 器) and the marks' baseline beside the other cells in the user's fonts.
16. **Scroll dividers to verify on hardware:** each style's spacing at the user's scale, the `su` numerals and `kotoba` lines in the user's Fraunces and Noto CJK, and the gallery tiles at small window widths.
17. **End leaf to verify on hardware:** `omarchy-theme-set` with the display name, `omarchy-shell shell summon omarchy.image-picker '{"source":"themes"}'` from a third-party bar, `idleProxy.setIdleEnabled` toggling stay awake, `top -b -n2 -o %CPU` column numbers on the user's procps, hwmon names for the CPU temperature, `omarchy-launch-editor` opening notes.md, `omarchy-clipboard-paste-text --copy-only --history-index N`, `notify-send` for the focus timer, and the hold-to-press seals not firing on a click.
18. **Indicator stamps:** twice, right after a shell restart with do not disturb on and an `indicatorStyle` change, only the stamp that was on showed (the five off ones were gone, though `indicators` was `all`). It never came back in later runs and nothing in the log explains it. Also verify the Nerd Font icons in the user's mono font, and the hover name on a crowded bar (it is cut short when there is no room, and the marks' `clip` can hide it when the zone overflows).

19. **Type scale to verify:** the bar at 36 px with label over value (about 30 px of type), `typeSize: large` with a 44 px bar (51 px), and the Medium values in another mono face. After a shell restart the window title stayed empty until focus changed (seen once while testing; not caused by the type change, worth a look).
20. **Scroll sides to verify on hardware:** the curl's shading on the user's theme (light themes may want it fainter), and the scroll's edges against the screen edge on a 1x display.
21. **Profile plate to verify on hardware:** the probe's facts on the user's machine (theme name, `omarchy-version`, Hyprland tag, install date from `stat -c %W /`), Save image writing to `~/Pictures` (or `$XDG_PICTURES_DIR`; the folder must exist), the inline name field with a long name, and the impression box's size at the window's real size. Also resize the settings window through the sizes the harness renders (600 px to ultrawide, and short) and check nothing overlaps at the user's `typeSize` and font scale.
22. **Window style:** a change in the settings window does not reach Hyprland until `hyprctl reload`; Hanko could run `hyprctl reload` (or an `hyprctl eval` hook like Omacale's) when `surface` or `motion` changes. Also check the red print on a light theme and next to floating windows, and that `popin 96%` reads as a print rather than a zoom.
23. **Overview to verify on hardware:** live snapshots (`ToplevelManager` + `HyprlandToplevel.address` matching Hanko's `0x` addresses), the focus grab closing on click-away and not on the first click inside, keyboard on the focused monitor only with two screens, `hl.dsp.window.move` with `window` and `workspace` together, the deferred focus after a click (90 ms; raise it if focus snaps back), and the page fit on a portrait monitor.
24. **Dynamic overview:** icons resolving for Omarchy's webapps and TUI apps (omarchy-overview has a longer lookup in `OverviewWindow.qml` if `heuristicLookup` misses), the wallpaper path after `omarchy theme bg next`, the + cell creating the workspace on this monitor, and Alt+Tab reaching the layer (Hyprland may take it first).

25. **Kata panels (K5):** Time has no weather yet and Power no quick chips (the Classic sheets have both); the handscroll stays Classic's under a Kata design.
26. **Kata letters (K6):** a letter swiped or torn away is only set aside for the session (Omarchy's history has no per-letter delete for bars); it returns after a shell restart until Clear all.
27. **Revision 2 (Classic sheets):** check on hardware that the watermark kanji stays faint enough on a busy theme at 1x, that the sheet's shadow reads on wallpaper without darkening the bar, and the needle's ease on a fast scroll. The Classic bar and the handscroll were left as they were.
28. **Classic bar polish:** check the hover plate on a touchpad (it follows `containsMouse`, which can stick when the pointer leaves the bar window; see omacale's notes on hover), the ink seals on a light theme, and that Fraunces's `tnum` really applies in the shell's Qt (if not, the clock still renders, just proportional).
29. **Bar feedback:** watch the counters and the meter cascade on a fast wheel scroll (each step restarts the roll from the shown number) and the breathing's cost when a low battery breathes all evening (one opacity animation; stop it with `motion: still` if it bothers).
30. **Sheet hands:** pull the Tanzaku lead slip on hardware (drag and wheel), and each hand at the user's `typeSize` large (the sheets grow, they don't scroll).
31. **Craft hands to verify on hardware:** Shōgi's square click and wheel on the master and an app (the wheel steps one file, 12.5%), Soroban's bead flick (a hundreds rod appears at 100%; clicking the units' first earth bead when one is counted takes it back to zero), Odoshi's scale click, Kasumi's drag along a band that drifts in from the right (it measures from the right edge), the 24-scale day lame at 1x, and each hand on the user's theme (light themes draw Kasumi's bands as ink and Shōgi's pieces as pale wood). The harness letter timestamps are UTC: render with `TZ=UTC` or the inbox reads "now" for every letter.
32. **Shōji sheet hand to verify on hardware:** the rail slide between two cells on a Hanko bar (`Behavior on x` only runs while both are Shōji sheets; from another hand it jumps), the panel's side when the cell is near the middle, the Display panel's monitor pick and Arrange › (`omarchy-launch-editor`), the brush slider dragged on a real brightness (DDC can lag), and Tab from Power to Display. The Shōji preset (S4) on a real `style.json` that had `"design": "shoji"` (it should load straight into the preset, keep its height and Bluetooth, and open Shōji panels and the framed overview), and on a laptop (the brightness cell appears, which Shōji never had). Shōji's bar values (S3): the brush pointer following a real pointer across cells and leaving when it leaves the bar, names coming out on reach in `status: ink`, the carved seal's press when a letter arrives, the season clock's sekki at midnight on a change of term, washi grain on a 1x panel, and `notif: seal` with the seal hidden (the inbox must come back). `overview: framed` on a Hanko bar: the washi pages' opacity follows Panel opacity (Auto is the washi's 86%), keys and drag as on the grid.

33. **Right-side studies to verify on hardware:** Shizuka's unfold on a real volume key (the reading must open on the change, hold two seconds and fold, and not open at login: `fresh` waits for `Motion.live`), the zone-wide `HoverHandler` unfolding everything without the cells jumping out from under the pointer (the zone grows to the left), Suji's dotted range at 1x, the Inrō case's height at 36 and 44 px and with `typeSize: large`, and `Status.short` on the user's real SSIDs and device names.

34. **Presets page to verify on hardware:** eleven live `BarSurface` previews at once (scrolling cost; each binds the live data), the cards at the settings window's real 1320 px and at `typeSize: large`, and Shuffle from the Presets page (it edits on top of the preset in use, which the page then shows as `N EDITS`).

35. **Inkan to verify on hardware:** the seal layer under fullscreen windows (it is on `Top`), its mask (only the seal takes clicks; the rest of its 500 px layer must pass them through), hover on a layer-shell surface, the drag carrying on past the layer's edge (Wayland's implicit grab) and the snap writing `monitors.<name>.inkanAt`, `barSize` 0 with Omarchy's OSD and toasts, the sheet layer's seal hole (a click on the seal lifts the sheet off, not the closer then the seal again), the 140 ms print delay and the lift-off on a real sheet, Backspace back to No. 00 (a `Shortcut` in a layer-shell window), Tab under Inkan, the scroll unrolling from the seal's edge, Omarchy's panel hotkeys printing at the seal, and the wear specks' size at 1x. `form: inkan` on one monitor only still reports the bar's height to Omarchy (barSize is global).

36. **Kōsei to verify on hardware:** the galley's hover and click with a real pointer (brackets follow a 30 ms settle after the bar lays out), the specimens' cost (Status builds eight 1920 px bars; only the open part's are built), hover-to-try leaving no trial behind when the pointer leaves the window fast, `screenWidth` on a scaled monitor (logical width), and ← → / 1–0 not firing while the search field has focus.

## 13. QML pitfalls already hit

- Under a Wayland session `QT_QPA_PLATFORM` is already set, so the harness opened a real window that Hyprland tiled to its own size. `render.py` now forces `offscreen`.

- A property named `onSomething` is parsed as a **signal handler** (`onBone` broke; renamed `boneInk`). Never start a property name with `on` + capital.
- The id `gc` masks a JS global and fails at load (lint missed it, the render caught it). Avoid ids that shadow globals (`gc`, `print`, `console`, `Qt`).
- Use `pragma ComponentBehavior: Bound` in files with delegates / `Loader` components, give delegates `required property` and qualify outer ids (`root.x`), or qmllint reports unqualified access.
- Loader-based variants: give the component a `property var ws` and set it in `onLoaded` with `Qt.binding(...)`.
- Fraunces is variable: set `font.weight: Font.Normal` **and** `font.variableAxes: Type.axes(size)`, or it renders bold. Pass the size expression itself: `Type.axes(font.pixelSize)` is a binding loop on the font group.
- Space Grotesk is variable too: `font.weight` alone left it Regular; give `font.variableAxes: Type.valueAxes` as well.
- The live shell did not hot-reload Hanko's files on this machine; `omarchy-restart-shell` loads the edits. Screenshots of sheets and the scroll need about a second after the IPC call, or they catch the print or pan half way.
- `Text.StyledText` with `<font color=…>` for mixed-ink runs; escape `& < >` in any user text (titles, songs, notifications) first.
- Inline `component X: …` declarations can't see the delegate scope; pass what they need as properties.
- Ids inside a file share one scope: don't reuse a short id like `n` that a component property also uses.
- Stubs must be `QtObject`/`Item` with the exact property names the real module has; an enum-typed thing (e.g. `ExclusionMode`) must be a QML `enum`, not properties.
- An id in the file shadows a same-named property inside an inline component: a `Loader { id: plate }` in SettingsPage made every `SmallButton`'s bare `plate` truthy. Qualify (`button.plate`) or pick ids that no component property uses.
- A property named `data` on an Item (or window) replaces its default property: the children vanish. Inkan's readings were `data` until lint said "Duplicate binding on property 'data'".
- A `var` declared later in a JS function is hoisted over the whole function: `var screenW` in one branch made `screenW` (the property) undefined in another. Qualify properties (`win.screenW`).
- A list a QML model hands to JS is not always an Array: `Array.isArray` is false and `.some` may be missing. Count by `length`.
- Never read a Row's children's positions (`mapToItem`) from a binding and trust the answer: the Row places them in a later polish pass. Measure on a short Timer after the layout changes (Galley, Specimen).
- A property named `left`, `right`, `top` or `bottom` on an Item clashes with the FINAL anchor-line properties ("Cannot override FINAL property"); use `east`, `west`, `high`, `low`.
- Never find a Repeater's item with a binding over `itemAt(i)`: nothing tells the binding when the Repeater builds its items (`count` can change first), so it can stay null for good and the sliding plate vanished in places. Let the delegates report themselves (`onOnChanged` / `Component.onCompleted` / `onDestruction`), as `Segmented` and `Workspaces` do.

## 14. Reference material

- Omarchy: `github.com/omacom/omarchy` (manual `manual/32-shell-plugins.md`, `docs/omarchy-shell.md`, `shell/`, `bin/`, `default/hypr/`).
- Ryoku (style only): `github.com/Ryoku-dev/ryoku` branch `unstable-dev` (the Settings app), and `ryoku.dev` (blocked by the cloud network; use a web fetch tool).
- Plugin integration references (not design): `AyushKr2003/omacale` (closest model: a full `bar` plugin; its `CLAUDE.md` is worth reading), `HANCORE-linux/Shibumi-Shell`, `gitcoder89431/ruixen-shell`.
- In this repo: [ROADMAP.md](ROADMAP.md), [COMPONENTS.md](COMPONENTS.md), [DESIGN.md](DESIGN.md), [history/sheet-DESIGN.md](history/sheet-DESIGN.md), [history/scroll-DESIGN.md](history/scroll-DESIGN.md), `docs/mockups/`.
- Project files (Claude project): `/mnt/project-files/ryoku-shell/{scroll,typeset}/` hold mockups and phase renders; project memory notes `hanko-bar-design`.
