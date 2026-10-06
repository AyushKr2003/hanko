# Hanko handoff: everything a fresh session needs

This file is the single source a new Claude session (or a person) reads to pick up Hanko exactly where it was left. It covers the brief, every branch, the design, the Omarchy plugin contract, the code, the dev environment, the conventions, what each finished phase built, and detailed instructions for every remaining phase.

Last updated: 2026-10-06, after Phase 10's motion and per-monitor parts (on `claude/hanko-plugin-zzm827`, thirteen commits ahead of `dev`). The release steps are left to the user, who is testing on hardware first.

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

- **Design first, with many mockup images.** Each design direction lived on its own branch (`beta1`, `alpha1`, `gama1`) with a full set of rendered sheets. The user picks a direction, then asks for the next.
- **Build step by step, not all at once.** Verbatim: *"work on this properly with roadmap and all in step by step … no need to do all at once and commit after a part is done."* One phase (or a clear part of a phase) per commit, pushed right away.
- **Work happens on `dev`.** Verbatim: *"merge this branch in main and from there create a new branch name dev and start working in that."* Do not merge `dev` into `main` again unless the user asks.
- **Read the real docs.** The user pointed at the Omarchy manual and its third-party plugin docs. Base every integration decision on the Omarchy source, not on guesses.
- **Integration references are not design references.** Shibumi-Shell, `AyushKr2003/omacale` and ruixen-shell show how plugins talk to Omarchy; never borrow their look.
- **"good" / "go on" means keep going** to the next phase without asking.
- **Show renders.** Every phase reply carries a render of what was built (the harness PNG), since there is no Omarchy machine in the cloud session.
- **Before writing a lot of new code after a long stretch, the user may ask for a write-up like this one.** Keep it updated.

## 3. Repository and branches

Repo: **`AyushKr2003/hanko`** (private). In cloud sessions it was checked out at `/tmp/claude-0/hanko`.

| Branch | What it holds | State |
|---|---|---|
| `beta1` | Design direction 1, **"Sheet"**: the bar as a printed running head. Seal, label-over-value cells, tick meters, the 24-hour day rule along the foot, folio workspaces, flush sheets that drop from a cell. 5 mockups + HTML. Doc: `docs/history/beta1-DESIGN.md` (on later branches). | Frozen. The user later said to set it aside, but it lives on as the Sheet preset. |
| `alpha1` | Design direction 2, **"Scroll"**: a calm one-line bar that unrolls into a horizontal handscroll (emakimono) holding every panel (Time, Sound, Network, Power, Spaces, Inbox), with rollers, an index plate and dithered interludes. Workspace-numeral seal, real-layout workspace glyphs, serif byline, kanji glyph status, notification stamps, the rod. 6 mockups. Doc: `docs/history/alpha1-DESIGN.md`. | Frozen. Lives on as the Scroll preset. |
| `gama1` | Design direction 3, **the merge the user chose**: every part of the bar is a setting (15 settings, 6 presets, 2,985,984 combinations), with a Typesetting 組版 settings page. 19 sheets in `docs/mockups/gama1/`, spec in `docs/COMPONENTS.md`, overview in `docs/DESIGN.md`. | Frozen design. This is the spec the plugin implements. |
| `gama1-plugin` | Roadmap + Phase 0 + Phase 1 of the plugin. | Merged into `main` (fast-forward), no longer used. |
| `main` | = `gama1-plugin` at `101a6b6` (Phase 1). | Only updated when the user asks. |
| **`dev`** | **All current work.** Phases 2–5 on top of main. | **Active branch.** |
| `claude/hanko-plugin-zzm827` | A cloud session's working branch: `dev` + Phases 5–9, the Display and Bluetooth panels, and Phase 10 (motion, per-monitor UI). | Fast-forward `dev` to it when the user agrees. |

`git log --oneline dev`:

```
bb1cc08 Phase 4: the right zone, how things are
528154b Phase 3: the centre, when
49e1d5b Phase 2: the left zone, where you are
101a6b6 Phase 1: a bar that loads in Omarchy
5bb25e3 Phase 0: style logic, ink ramp and an offline dev loop
4abd0cb docs: add the plugin roadmap
db3f434 gama1: merge beta1 and alpha1 into one configurable bar
efda228 Hanko alpha1: redesign as a calm bar that unrolls into a handscroll
647880b Hanko beta1: design direction and mockups
```

A future design iteration (if the user asks for one) follows the same pattern: a new branch with a Greek-ish name, a full set of mockup sheets, a design doc, and the earlier directions moved under `docs/history/`.

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
- **Project chat (Claude projects):** replies go through the thread's `reply` tool. A thread can hold at most 24 attached outputs; the Hanko thread is at that limit, so link files by path (`/mnt/project-files/...`) in the text instead of attaching them. Renders are copied to `/mnt/project-files/ryoku-shell/gama1/phaseN-render.png`.

## 5. The design in one page

Full spec: [COMPONENTS.md](COMPONENTS.md). This is the summary a builder needs in their head.

### The six rules every option keeps

1. **One paper, four inks, one red.** All colour comes from the Omarchy theme. Paper = `background`; ink = `foreground` stepped toward the paper to contrasts of **12, 9, 6.2 and 4.6 : 1** (`ink`, `inkDim`, `inkMuted`, `inkFaint`); seal = the theme's `red`. No option may introduce a colour.
2. **Red means "you" or "now".** The seal, the now-notch, an urgent workspace, a muted master, an unread dot, a low battery, being offline. Nothing else is red.
3. **Emphasis is inversion.** The selected thing becomes a solid ink ("bone") plate, often with a `//` lead.
4. **Three typefaces with fixed jobs.** Fraunces (serif) for time, titles, bylines; Space Grotesk for values and language; the user's Omarchy monospace for labels; Noto Sans/Serif CJK JP for kanji.
5. **Hairlines, not shadows.** Dividers, frames and edges are 1 px ink lines.
6. **One baseline.** Every zone sits on the same text baseline at every height.

### The sixteen settings (`core/Style.js` `OPTIONS`; **bold** = Hanko default)

| Zone | Key | Options |
|---|---|---|
| Left | `seal` | `stamp`, **`workspace`**, `none` (plus free-text `sealGlyph`, default 印) |
| Left | `spaces` | `folio`, **`layout`**, `kanji`, `dots` |
| Left | `title` | `cell`, **`byline`**, `none` |
| Centre | `clock` | **`stacked`**, `inline`, `mono` |
| Centre | `clockAt` | **`center`**, `right` |
| Centre | `media` | `cell`, **`underline`**, `none` |
| Right | `status` | **`cells`**, `glyphs`, `numerals` |
| Right | `meters` | **`ticks`**, `off` |
| Right | `notif` | `count`, **`stamps`** |
| Right | `bluetooth` | **`on`**, `off` (added after gama1) |
| Edge | `edge` | `hairline`, `dayrule`, `rod`, **`rodrule`** |
| Edge | `rules` | **`on`**, `off` |
| Frame | `height` | `32`, `36`, **`40`**, `44` |
| Frame | `surface` | **`solid`**, `glass`, `inset` |
| Frame | `position` | **`top`**, `bottom` |
| Panels | `panels` | `sheets`, **`scroll`** |

### Presets

| Setting | Sheet (=beta1) | Scroll (=alpha1) | **Hanko** (default) | Quiet | Instrument | Islet |
|---|---|---|---|---|---|---|
| seal | stamp | workspace | workspace | stamp | stamp | workspace |
| spaces | folio | layout | layout | dots | kanji | kanji |
| title | cell | byline | byline | none | cell | byline |
| clock | stacked | inline | stacked | inline | mono | inline |
| clockAt | center | center | center | center | right | center |
| media | cell | underline | underline | none | cell | underline |
| status | cells | glyphs | cells | numerals | cells | glyphs |
| meters | ticks | off | ticks | off | ticks | ticks |
| notif | count | stamps | stamps | count | count | stamps |
| bluetooth | on | on | on | off | on | on |
| edge | dayrule | rod | rodrule | hairline | dayrule | rodrule |
| rules | on | off | on | off | on | off |
| height | 36 | 40 | 40 | 32 | 44 | 36 |
| surface | solid | solid | solid | glass | solid | inset |
| position | top | top | top | top | top | top |
| panels | sheets | scroll | scroll | sheets | sheets | scroll |

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
{ "preset": "Hanko", "edits": { "clock": "inline" }, "sealGlyph": "印", "motion": "paper",
  "hidden": ["tray", "hosted:omarchy.weather"],
  "monitors": { "DP-2": { "height": 32, "spaces": "dots" } } }
```

Resolution: preset → `edits` → `monitors[name]`. Invalid keys/values are dropped with a warning (`Typeset.warnings`).

### Mockups

`docs/mockups/gama1/*.png` (19 sheets; index in COMPONENTS.md §8) are the visual target for every phase. Compare each phase's render against the matching sheet. The HTML kit that drew them is `docs/mockups/gama1/source/` (`cat.html`, `desk.html`, `studio.html`, `gama.css`, `gama.js`, `shootq.mjs`), rendered with Node + Playwright:

```sh
cd docs/mockups/gama1/source
node shootq.mjs "file://$PWD/cat.html?page=status&theme=gruvbox" out.png
node shootq.mjs "file://$PWD/desk.html?preset=Quiet&o={\"spaces\":\"kanji\"}&panel=sheet-time" out.png
```

`cat.html` pages: `identity | time | status | signals | edge | frame | presets | shuffle | themes`. `desk.html` takes `preset`, `theme`, `o` (JSON overrides), `panel` (`sheet-sound`, `sheet-time`, `scroll-0`…`scroll-5`) and `wins=1`. When a phase needs a detail the sheets don't show (sheet contents, scroll sections), read the HTML/CSS in this kit: it is the exact design.

beta1 and alpha1 mockups: `docs/mockups/beta1/`, `docs/mockups/alpha1/`. Copies of the gama1 sheets also sit in `/mnt/project-files/ryoku-shell/gama1/`.

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
| Theme | `qs.Commons` `Color.foreground`, `Color.background`, `Color.urgent` (= theme red); live on theme switch. `Style.font.family` (mono), `Style.font.body` (base size; Hanko scales by `body/12`) | — |

Other Omarchy panels that exist (`shell/plugins/panels/`): audio, bluetooth, clock, disk-speedtest, dropbox, elsewhen, monitor, network, power, speedtest, tailscale, weather, wifiqr.

### Fonts

Omarchy installs `noto-fonts-cjk`, so kanji come from the system ("Noto Sans CJK JP", "Noto Serif CJK JP"). Hanko bundles **Fraunces** (+ Italic) and **Space Grotesk** under `assets/fonts/` (SIL OFL, licence files alongside) and loads them with `FontLoader`. The mono face is `Style.font.family` (what `omarchy font set` controls).

## 7. Code map

Everything is plain QML/JS, no build step.

```
manifest.json            plugin manifest (hanko.bar, kind bar)
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
  SheetWindow.qml        the layer a sheet is printed on (see Phase 6 in §9)
  ScrollWindow.qml       the layer the handscroll unrolls on (see Phase 7 in §9)
  SettingsWindow.qml     the settings window (see Phase 8 in §9)
  settings/              SettingsPage, SettingsCard, Segmented, Plate (all pure)
  HostedSlot.qml         one hosted widget from the registry (see Phase 9 in §9)
  HostBar.qml            the `bar` facade hosted widgets see
  Marks.qml              Hanko's own indicators, keyboard, mic and tray marks
  scroll/                ScrollView, ScrollSection, ListRow, Fader, SignalBars, Interlude;
                         Time/Sound/Network/Power/Display/Spaces/InboxSection (all pure)
  sheets/                SheetView, SheetCard, SheetHead, GroupHead, SheetRow, Ruler,
                         SheetButton, ActionBar; TimeSheet, SoundSheet, NetworkSheet,
                         PowerSheet, DisplaySheet, InboxSheet (all pure)
  Edge.qml               hairline | dayrule | rod | rodrule, mirrored at the bottom,
                         inset-aware; rod grip lifts on hover, drag emits pulled()
core/
  Ink.qml   (singleton)  paper, ink, inkDim, inkMuted, inkFaint, seal, bone, boneInk,
                         line, lineSoft, lineStrong, light, alpha(), paperAt()
  Type.qml  (singleton)  FontLoaders; display (Fraunces), text (Space Grotesk), mono,
                         jp, jpSerif; scale; px()
  Motion.qml (singleton) every timing and curve (alpha1 sheet 05); still (motion: still
                         or Omarchy's reduced motion), live (awake and not still), ms()
  Typeset.qml (singleton) style.json FileView + watch; doc, warnings, current,
                         ownsPosition; styleFor(monitor), set, applyPreset, reset,
                         setSealGlyph, shuffle, serialized; debounced save (200 ms)
  Style.js               OPTIONS, KEYS, PRESETS, PRESET_NAMES, DEFAULT_PRESET, coerce,
                         normalize, resolve(doc, monitor), withSetting, withPreset,
                         shuffled(doc, rng), combinations(); MOTIONS (motion and
                         sealGlyph sit beside the edits, outside the sixteen)
  InkMath.js             hexToRgb, mix, luminance, contrast, tier, isLight, ramp (TIERS)
  Title.js               appName (NAMES map, reverse-DNS), describe(cls, title) →
                         {app, head, dir, leaf}, findPath, tildify
  Spaces.js              numeral (壱 弐 参…), folio, layoutOf(windows, area),
                         usableArea(monitor), list(workspaces, activeId, min=5)
  Sheets.js              SHEETS (key, kanji, width, anchor cells, Omarchy ids), forCell,
                         forOmarchyId, step (Tab), panelAt, place (x + tear)
  Hosted.js              which layout entries are drawn, own, or hosted
  Extras.js              indicators, keyboard (hyprctl devices), tray rows
  Settings.js            RAIL, CARDS, MOTION_CARD/ROWS, PRESET_BLURBS, GLYPHS, nameOf,
                         changes, status, search
  Scroll.js              SECTIONS, layout, centred, nearest, clampTrack, landing,
                         position, forCell, sliver (interlude dither)
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
                         mockups/{beta1,alpha1,gama1}
```

**IPC target `hanko`** (Bar.qml): `version`, `styleGet`, `styleDoc`, `styleSet(key, value)`, `stylePreset(name)`, `styleReset`, `styleShuffle`, `warnings`. All typed, all return strings.

**Data flow:** services (live Quickshell data) → `BarWindow` (per screen, picks `Typeset.styleFor(screen.name)`) → `BarSurface` props (plain JS objects) → components. Components never import services. This is what lets the harness render any state, and it is the pattern to keep for every new part.

**Params JSON shape for the harness** (`tests/harness/params/*.json`): `{ title, width, theme: {foreground, background, red}, now, spaces, window, media, volume, network, battery, brightness, notifications, dnd, strips: [ { label, doc: {preset?, edits}, …any per-strip override of the sheet-level values… } ] }`.

## 8. Dev environment from scratch

There is **no Omarchy machine** in the cloud session. Everything is verified with unit tests, `qmllint`, and offscreen renders compared by eye against the gama1 sheets.

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

**Lint does not catch everything.** A render failing to load is the real check (it caught the `gc` id clash). Always run the full `tests/run`, then open `tests/out/phaseN.png` and compare with the gama1 sheet.

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
- `core/Edge.js` (+5 unit tests) and `bar/Edge.qml`, replacing the plain hairline. All four edges from the kit's CSS (`alpha.css` `.rod`, `beta-parts.css` `.dayrule`, `gama.css` `.rodrule`): day rule = base `line`, spent part `lineStrong`, ticks 3 px (6/12/18 h 5 px, `lineStrong`), red now-notch 2×7 px with a 3 px head; rod = 2 px `lineStrong`, 6 px `inkMuted` caps, 34×4 paper grip; rodrule adds the spent part in `inkMuted`, ticks above the rod and an 8 px notch. Nothing changes the bar's height (the kit draws edges inside the bar), so `barSize` is unchanged. The rod sits 2 px up so its caps fit inside the window.
- At `position: bottom` the edge is mirrored as a whole onto the top side.
- Rod interaction: an 8 px band along the edge; hover lifts the grip 2 px, pressing inks the rod, a drag of 24 px (scaled) away from the bar emits `pulled()` → `BarSurface.edgePulled` → `Bar.edgePulled(screenName)`, which has no receiver until Phase 7.
- Inset: `BarWindow` sets 8 px margins on the anchored edge and both sides (hidden: parks at `-(height + 8)`); the paper gets a 1 px `Ink.line` frame with 7 px corners (the kit's `gama.css`; COMPONENTS.md says 3 px, the rendered sheets show 7, the sheets won).
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
- **`bar/scroll/`** (pure): `ScrollView` (paper with hairlines, rollers with caps, 120 px curls, index plate, foot with keys and position bar, `reveal` and `ink` 0..1; a pan `MouseArea` behind the sections emits `dragged(dx)`, `released(velocity)`, `stepped(±1)`), `ScrollSection` (red kanji, `02 // SOUND`, 46 px serif title, mono caption, 230 px watermark), `ListRow` (index, name/detail, note, bone plate, `leading`/`trailing` components), `Fader`, `SignalBars`, `Interlude` (Canvas painting `sliver` in `Ink.ink`), and the sections (eight since the Bluetooth panel). Sections send the same requests as the sheets (`Bar.sheetRequest`), plus `spaces` (`window` address → `Hypr.focusWindow`, `workspace` id) and `sound`/`input` (mic level).
- **`bar/ScrollWindow.qml`**: SheetWindow's layer pattern (namespace `hanko-scroll`). Width = screen minus 6.9 % each side (min 16 px), height 460 px scaled. Motion: `reveal` 300 ms bezier(.2,.9,.25,1), `ink` 120 ms delay + 200 ms bezier(.4,0,.2,1), `trackX` 260 ms bezier(.16,1,.3,1) except while dragging; closing reverses in 220/100 ms and unmaps after 320 ms. `Style.reduceMotion` (Omarchy's animations-off flag, from `qs.Commons`) sets every duration to 0. Keys: `H`/`L`/arrows/Tab pan, `1`–`6` jump, `Esc` rolls up; the wheel steps once per 260 ms.
- **State and routing** (`Bar.qml`): `scrollOpen`, `scrollScreen`, `scrollSection`; `openScroll/closeScroll/toggleScroll/scrollTo/stepScroll`; `openPanel/panelOpen/closePanel` pick sheet or scroll by the screen's `panels` style, so `summonBarWidget` and friends serve both. A sheet and the scroll never show together. `BarWindow.cellClicked` unrolls at the cell's section under `panels: scroll`; `rodPulled(x)` (Edge now reports where the pull started; `BarSurface.cellAt(x)`) unrolls the scroll, or under sheets drops the sheet of the cell under the pointer (Time otherwise). Every sheet service is `wanted` while the scroll is out. IPC `hanko scroll` (toggle, any `panels`) and `hanko scrollTo <section>`.
- **No `Super+Space`**: Omarchy binds it (and every `Super+…+Space`) already, and has no plugin hook for binds; README documents `o.bind("SUPER + CTRL + U", "Hanko scroll", "omarchy-shell hanko scroll")`.
- `Spaces.layoutOf` carries each window's `name` (`Title.appName`) and `address`. `Time.ribbon` takes a day count and names the months around it; `Time.ordinal`, `Time.counted`, `Time.dayAcross` (tomorrow/yesterday for a city). `Sound.sheet` adds `inputLevel` and each output's `bus`.
- Harness: `phase7.json` and `phase7-light.json` (the `Sheets` scene takes `scroll: true`, `current`, `reveal`, `ink`). `tests/run` now lints `bar/sheets` and `bar/scroll` too. Unit tests: 48.
- Not done from the alpha1 motion sheet: the rod "lifting into a roller" as the paper drops (the paper simply unrolls under the bar) and the stamp press (done in Phase 10).

### Phase 8 · Settings window and CLI parity ✅ (`56cd19f` page, `0555318` window and CLI)
- **Draft** in `core/Typeset.qml`: `draft` (null or a document), `live = draft || doc`; `current`, `styleFor` and `ownsPosition` read `live`, so the real bar shows every edit at once. `draftSet(key, value)` (also `sealGlyph`), `draftPreset`, `draftMonitor`, `draftClearMonitor`, `draftReset` (edits dropped, glyph and monitors kept), `draftShuffle`, `save()` (commits the draft through the usual debounced write), `revert()`. `setFor(monitor, key, value)` saves a per-monitor value at once (CLI). A CLI `style set` while a draft is open changes `doc` but the bar keeps showing the draft until Save/Revert.
- **`core/Settings.js`** (+ tests): `RAIL` (four groups, eight pages), `CARDS` (six cards, every one of the settings once (16 since Bluetooth), plus the seal glyph), `PRESET_BLURBS`, `GLYPHS` (印 力 侍 A, then "…" for your own), `optionsFor`, `selected`, `changes(saved, draft, resolve)` (settings that resolve differently + glyph + each differing monitor), `status(n)`, `presetLine(doc)`, `matches(row, query)` and `pageMatches` for search. `core/Style.js` gained `withMonitorSetting(doc, monitor, key, value)` (drops an override equal to what the monitor would get anyway).
- **`bar/settings/`** (pure): `SettingsPage` (rail with masthead, search, groups, Advanced switch; page with eyebrow `印 BAR · PRESET · HANKO + EDITS`, 44 px title, preview over `Plate`, preset cards, a 3×2 `Grid` of `SettingsCard`s with each row of cards as tall as its tallest, an Advanced card with a glyph field, monitors and raw JSON; Presets page with six `BarSurface` strips and Shuffle; honest text for Colour, Widgets, Sheets, Scroll, Motion, Keys; action bar), `SettingsCard`, `Segmented`, `Plate` (dithered orb). Signals: `settingPicked`, `presetPicked`, `resetToPreset`, `revert`, `save`, `pagePicked`, `queryEdited`, `advancedToggled`, `monitorCleared`, `shuffle`. Note: `set` can't be a QML signal name.
- **`bar/SettingsWindow.qml`**: a Quickshell `FloatingWindow` (as Omarchy's dev gallery), 1600×900 scaled, min 420×360. `SettingsPage` reflows to any size (a tiled window ignores the minimum): cards go 3→2→1 columns (400 px each), presets 6→3→2, overrides 2→1, a card row stacks its control under its name when narrow, the preview bar lays out at least 1240 px wide and scales down, the rail narrows under 1100 px and folds to glyphs under 760 px (the search moves onto the page), and the rail scrolls on short windows; `/` searches, `Ctrl+S` saves, `Esc` clears the search then closes; the window manager closing it counts as Cancel. `Bar.settingsOpen`, `openSettings()`, `closeSettings()` (reverts the draft). IPC `hanko settings` and `hanko styleSetFor <monitor> <key> <value>`.
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
- **Own marks**: `core/Extras.js` (+ tests: `indicators(state)`, `moduleJson`, `keyboard(hyprctl devices)`, `tray(items)`), `services/Extras.qml` (pgrep for gpu-screen-recorder every 2 s; `omarchy-voxtype-status` stream; `omarchy-reminder show --json` every minute; the idle and nightlight proxies; `hyprctl -j devices` on `activelayout`; `Pipewire.defaultAudioSource`; `SystemTray.items`), `bar/Marks.qml` (pure). Actions: indicator click turns it off / opens its tool (as Omarchy's do), keyboard click/right-click `hyprctl switchxkblayout all next|prev`, mic click `omarchy-audio-input-mute`, wheel ±5 %, middle opens Sound; tray left `activate()` (or the menu when `onlyMenu`), right `display()` (Quickshell's platform menu), middle `secondaryActivate()`, wheel `scroll()`. Do-not-disturb has no mark: the inbox already shows it.
- **Room**: `BarSurface.extrasRoom` (right edge to the centre clock, less status, inbox and the right clock) bounds the marks and hosted row; `mediaRoom` is what's left for now playing (hidden under 90 px). Order of giving way: media, then the tray folds (`盆` + count, a click unfolds it for 8 s), then hosted widgets drop out whole (`HostedSlot.fits`, measured from the cells before it). Natural widths are measured apart (`Marks.fullWidth`, each cell's `naturalWidth`) so folding never feeds back into its own decision.
- Harness: `tests/harness/widgets/FakeWidget.qml` (an Omarchy-style widget reading `bar.barForeground`/`fontFamily`), `phase9.json` (indicators, keyboard, mic, tray, hosted, everything at once in five presets). Unit tests: 58.

### Phase 10 · Motion ✅ and per-monitor overrides ✅ (release: the user's, after testing)
- **`core/Motion.qml`**: the timings from alpha1's sheet 05 (unroll 300, roll up 220, ink 200 after 120, pan 260, stamp 140 with the only overshoot `[0.3, 1.4, 0.5, 1]`, sheet print 180, plate slide 160, value fade 140, now-notch creep 1200) and their curves. `still` = harness `forceStill`, Omarchy's `Style.reduceMotion`, or `style.motion === "still"`; `ms(v)` gives 0 when still. `awake` turns on 1.5 s after start and `live = awake && !still` gates the Behaviours that would otherwise slide in from 0 while the bar lays out.
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

## 10. Instructions for the remaining phase (10)

Each phase: read the matching gama1 sheets and the HTML kit first, keep `BarSurface` pure (data in, signals out), add services for live data, add a `tests/harness/params/phaseN.json` covering every option and state, and follow §11.

### Phase 10 · Motion and release

Items 1 and 2 are done (§9). Items 3 and 4 wait for the user.

1. ~~The alpha1 motion spec across the bar: inversion plates slide between items (one indicator, like Ryoku's rail); values crossfade; the now-notch creeps; a new stamp is pressed down oversized and tilted, then settles (140 ms, the only overshoot anywhere); sheets print top-down (~180 ms). A global **reduced motion** switch (Motion 動 page + style key, outside the 16 settings) that cuts every transition to its end frame.~~
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
7. `tests/run`; fix every new lint warning; open `tests/out/phaseN.png` and compare with the gama1 sheet; iterate until it matches.
8. Update `docs/ROADMAP.md` (phase ✅), `README.md` (status "phase N of 10" and the "Right now it draws…" sentence), and this file (§9, §12, "Last updated").
9. Commit (`Phase N: …` + trailer), `git push -u origin dev`.
10. Copy the render to `/mnt/project-files/ryoku-shell/gama1/phaseN-render.png`; reply to the user with what's new, how to try it, what to check on their machine, and what's next. Update project memory.

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
10. **Phase 8 to verify on hardware:** the `FloatingWindow` tiling or floating sensibly (add an Omarchy window rule for title "Hanko settings" if it should float), keyboard focus landing in the window so `/`, `Ctrl+S` and `Esc` work, the window manager's close running `closeSettings` (revert), Omarchy's menu parser accepting the `// hanko.bar` line comment and the 印 icon in the menu font, and Canvas cost of `Plate` at 1600 px.
11. **Phase 9 to verify on hardware:** a real hosted widget's panel (Bluetooth, monitor, weather) opening under Hanko's bar through `HostBar` (its KeyboardPanel reads `bar.barSize`, `bar.position`, `bar.clickTargets`), `pluginShellForBarEntry` returning a shell for those entries, the `hosted:` cells counting right in `togglePanelAt`, tray icons inked by `MultiEffect` colorization (symbolic and full-colour), `item.display()` menus placing under the cell, the voxtype and reminder commands on a machine that has them, and the right zone's giving-way order on a narrow laptop screen.
12. **Bluetooth to verify on hardware:** `Quickshell.Bluetooth` property names on the user's Quickshell (`deviceName`, `batteryAvailable`, `battery`, `bonded`, `pairing`, adapter `discovering`), discovery starting and stopping with the panel, `omarchy-bluetooth-device` pairing a device that needs a PIN (Hanko has no PIN prompt; Omarchy's script may ask on its own), and the cell on a desktop without an adapter (it should not appear).
13. **Phase 10 to verify on hardware:** that nothing slides in at login (Behaviours wait 1.5 s; raise `Motion._wake` if a slow start still shows it), FadeText not flickering while a volume wheel spins (each step restarts the fade), the stamp press on a real notification (and not on every inbox reload: the key is timestamp + app + summary), the notch creep after suspend (a big jump creeps for 1.2 s, by design), `Style.reduceMotion` being the right name in the user's `qs.Commons`, and the per-monitor grid at 1200 px wide.

## 13. QML pitfalls already hit

- A property named `onSomething` is parsed as a **signal handler** (`onBone` broke; renamed `boneInk`). Never start a property name with `on` + capital.
- The id `gc` masks a JS global and fails at load (lint missed it, the render caught it). Avoid ids that shadow globals (`gc`, `print`, `console`, `Qt`).
- Use `pragma ComponentBehavior: Bound` in files with delegates / `Loader` components, give delegates `required property` and qualify outer ids (`root.x`), or qmllint reports unqualified access.
- Loader-based variants: give the component a `property var ws` and set it in `onLoaded` with `Qt.binding(...)`.
- Fraunces is variable: set `font.weight: Font.Normal` **and** `font.variableAxes: { "opsz": N, "wght": 400 }`, or it renders bold.
- `Text.StyledText` with `<font color=…>` for mixed-ink runs; escape `& < >` in any user text (titles, songs, notifications) first.
- Inline `component X: …` declarations can't see the delegate scope; pass what they need as properties.
- Ids inside a file share one scope: don't reuse a short id like `n` that a component property also uses.
- Stubs must be `QtObject`/`Item` with the exact property names the real module has; an enum-typed thing (e.g. `ExclusionMode`) must be a QML `enum`, not properties.
- Never find a Repeater's item with a binding over `itemAt(i)`: nothing tells the binding when the Repeater builds its items (`count` can change first), so it can stay null for good and the sliding plate vanished in places. Let the delegates report themselves (`onOnChanged` / `Component.onCompleted` / `onDestruction`), as `Segmented` and `Workspaces` do.

## 14. Reference material

- Omarchy: `github.com/omacom/omarchy` (manual `manual/32-shell-plugins.md`, `docs/omarchy-shell.md`, `shell/`, `bin/`, `default/hypr/`).
- Ryoku (style only): `github.com/Ryoku-dev/ryoku` branch `unstable-dev` (the Settings app), and `ryoku.dev` (blocked by the cloud network; use a web fetch tool).
- Plugin integration references (not design): `AyushKr2003/omacale` (closest model: a full `bar` plugin; its `CLAUDE.md` is worth reading), `HANCORE-linux/Shibumi-Shell`, `gitcoder89431/ruixen-shell`.
- In this repo: [ROADMAP.md](ROADMAP.md), [COMPONENTS.md](COMPONENTS.md), [DESIGN.md](DESIGN.md), [history/beta1-DESIGN.md](history/beta1-DESIGN.md), [history/alpha1-DESIGN.md](history/alpha1-DESIGN.md), `docs/mockups/`.
- Project files (Claude project): `/mnt/project-files/ryoku-shell/{alpha1,gama1}/` hold mockups and phase renders; project memory notes `hanko-bar-design`.
