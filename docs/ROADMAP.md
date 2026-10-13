# Hanko roadmap: from Typeset design to a working Omarchy bar

Typeset is the design: one bar where every part is a setting ([COMPONENTS.md](COMPONENTS.md)). This roadmap turns it into a real `bar`-kind plugin for Omarchy. Each phase ends in something that runs, and each one lands as its own commit (or a few) on the `dev` branch, which merges into `main` when a phase is ready to try.

Status key: ✅ done · 🔨 in progress · ⬜ not started

## How Hanko plugs into Omarchy

The facts below come from the Omarchy repo (`manual/32-shell-plugins.md`, `docs/omarchy-shell.md`, `shell/shell.qml`, `shell/services/Plugin*.qml`, `shell/plugins/bar/`). Each phase relies on them.

- **One process.** Omarchy's desktop is one long-running Quickshell process, `omarchy-shell`. A full bar is a plugin of kind `bar`. Hanko never starts a second Quickshell.
- **Install and enable.** The plugin is a git repo with `manifest.json` at its root, installed to `~/.config/omarchy/plugins/hanko.bar/`.
  - `omarchy plugin add <git-url>` installs it; `omarchy bar use hanko.bar` (which sets `bar.id` in `shell.json`) selects it.
  - `omarchy plugin validate .` checks the manifest the same way the shell does.
  - Saving any file in the plugin folder hot-reloads it.
  - If the bar fails to load, the shell falls back to `omarchy.bar`, so a broken Hanko never leaves you without a bar.
- **What the host injects into `Bar.qml`:** `omarchyPath`, `shell`, `manifest`, `barWidgetRegistry`, `pluginRegistry` and `barConfig`. A third-party bar gets *facades*, not the trusted objects:
  - `shell` is a `PluginShellApi`. It provides `summon`/`hide`/`toggle` for configured UI plugins, `firstPartyServiceFor()` and `updateEntryInline()`.
  - `firstPartyServiceFor()` hands out narrow proxies only for `omarchy.idle`, `omarchy.nightlight`, `omarchy.notifications` (do not disturb) and `omarchy.media` (player actions).
  - `barConfig` is a detached copy of the `bar:` subtree of `shell.json`.
- **What the host reads back from the bar:** `barHidden`, `barSize`, `position` and `fontFamily`, plus these functions if present: `summonBarWidget(id)`, `hideBarWidget(id)`, `isBarWidgetOpen(id)`, `panelWidgetIdAt(section, index)`, `toggleTransparency()` and `debugBarGeometry()`.
- **Hiding.** `omarchy toggle bar` writes `~/.local/state/omarchy/toggles/bar-off`, then calls IPC `omarchy.bar syncHidden`. Hanko must register that IPC target and watch the flag.
- **Live data the bar reads itself.** Omarchy's own bar uses these, and Omacale shows they work from a third-party bar:
  - Workspaces and the window title: `Quickshell.Hyprland`.
  - Audio: `Quickshell.Services.Pipewire`; scroll volume with `omarchy-audio-output-volume`.
  - Network: `Quickshell.Networking`.
  - Battery: `Quickshell.Services.UPower`.
  - Media: `Quickshell.Services.Mpris`, plus the `omarchy.media` proxy.
  - Notifications: the files under `~/.local/state/omarchy/notifications/`, the DND proxy, and `omarchy-shell notifications ...`.
  - Brightness: `omarchy-brightness-display`.
  - Time zones: the user's Elsewhen settings.
- **Theme.** `qs.Commons` provides `Color.foreground`, `Color.background` and `Color.urgent` (the theme's `red`), which update live on theme switch. `Style.font.*` gives the type scale and `Style.bar.sizeHorizontal` the bar height. The monospace face is the fontconfig `monospace` alias that `omarchy font set` controls.
- **Fonts.** Omarchy installs `noto-fonts-cjk`, so the kanji come from the system. Hanko bundles Fraunces and Space Grotesk (both under the SIL Open Font License) and loads them with `FontLoader`.

## Phases

### Phase 0 · Roadmap and scaffolding ✅
- This roadmap.
- A dev loop that works without an Omarchy machine. `qmllint` checks every QML file. An offscreen render harness (PySide6 plus small stubs for Quickshell and `qs.Commons`) draws the bar to PNG, so each phase is checked by eye against the Typeset mockups.
- Node tests for the pure logic: style resolution and the ink ramp.

### Phase 1 · A bar that loads ✅
- `manifest.json` (`hanko.bar`, kind `bar`), `Bar.qml` and `qmldir`.
- One layer-shell `PanelWindow` per screen. It reserves its space, follows `position`, and parks off screen when hidden (the same trick Omarchy uses).
- The host contract: `barHidden` (flag file plus `omarchy.bar syncHidden`), `barSize`, `position` and `fontFamily`.
- **Ink**: paper, four ink tiers at 12, 9, 6.2 and 4.6 : 1, seal red, and hairlines, all derived live from the theme.
- **Typeset**: the 15 settings (16 since the Bluetooth cell), the six presets and validation. The style is read from `~/.config/hanko/style.json` with a live file watch; resolution order is preset, then edits, then per-monitor overrides.
- Fonts are bundled and loaded.
- A first bar: the seal (`stamp`) and the clock (`stacked`), on paper, with a hairline edge.
- The `hanko` CLI: `install`, `uninstall` (restores your previous bar), `dev` (symlinks the checkout), `style get|set|preset|reset`, and `doctor`.

### Phase 2 · Left zone: where you are ✅
- Seal: `stamp` / `workspace` / `none`. Clicking it opens the Omarchy menu, right-clicking opens a terminal, and scrolling walks workspaces.
- Workspaces: `folio` / `layout` / `kanji` / `dots`, from Hyprland. `layout` draws each workspace's real tiling from client geometry. Urgent workspaces get the red dot.
- Window title: `cell` / `byline` / `none`, with app-name cleanup and a path that recedes.

### Phase 3 · Centre: when ✅
- Clock: `stacked` / `inline` / `mono`, at `center` or `right`.
- Now playing: `cell` / `underline` / `none`. The underline in `underline` mode is the progress bar. Click plays or pauses, middle-click skips, and scroll moves between tracks.

### Phase 4 · Right zone: how things are ✅
- Status: `cells` / `glyphs` / `numerals` for network, volume and battery, plus brightness on laptops. Scroll on volume or brightness to change it.
- Meters: `ticks` / `off`.
- Notifications: `count` / `stamps`, with the do-not-disturb state.
- The red rule: a glyph turns solid red only when it needs you (muted, low battery, disconnected).

### Phase 5 · Edge and frame ✅
- Edge: `hairline` / `dayrule` / `rod` / `rodrule`. The day rule's now-notch moves every minute. The rod's grip lifts on hover and a drag away from the bar pulls it (the scroll it unrolls arrives in Phase 7).
- Dividers on or off; heights 32, 36, 40 and 44 (with the compact one-line cells at 32).
- Surface: `solid` / `glass` / `inset`. Position: top or bottom, with edge details flipping side.
- Follows Omarchy's `bar.position` and transparency toggle unless Hanko overrides them. The toggle turns solid paper into glass.

### Phase 6 · Sheets ✅
- `panels: sheets`: a flush sheet drops from the clicked cell, joined to the bar by a bone tear, printed top-down (bottom-up from a bar at the bottom). Until the handscroll lands, `panels: scroll` opens sheets too.
- Sheets: Time (day ribbon, Elsewhen), Sound (master, outputs, per-app mixer, input), Network (connection, Wi-Fi, speed test and share card), Bluetooth (the BT cell's panel: connected, known and nearby devices, power; added after the phase), Power (battery, profiles), Display (the LUM cell's panel: brightness per monitor, monitors, night light; added after the phase), Inbox (stamped letters, do not disturb, clear).
- Keyboard: `Esc`, arrow keys, and `Tab` between sheets. The host's panel hotkeys (`SUPER+CTRL+A/W/P`, `ALT+D/E`, `togglePanelAt right N`) open the matching sheet.

### Phase 7 · The handscroll ✅
- `panels: scroll`: one paper (its edges bare or curling under, the `sides` setting; the rollers came out after the phase) holding eight sections (Time, Sound, Network, Bluetooth, Power, Display, Spaces, Inbox) with dividers between them (nine styles, the `interlude` setting, added after the phase), a weather leaf left of Time and an end leaf right of Inbox (both added after the phase; the end leaf is the `endleaf` setting, nine kinds); an index plate on top (below, for a bar at the bottom) and a position bar along the foot, either or both shown by the `guides` setting (added after the phase).
- Unrolls from a status, clock or inbox click (at that section), a pull on the rod, Omarchy's panel hotkeys, or `omarchy-shell hanko scroll`. Pans with a drag, the wheel, `H`/`L` or the arrows, lands centred on a section; `Esc` rolls it up.
- Sections in ryoku.dev's grammar with Scroll's controls: the day ribbon, a fader bank, the networks, the power profiles, a map of every workspace's tiling (click a window to go there) and stamped letters.
- Motion as Scroll drew it (unroll 300 ms, ink 200 ms after 120 ms, pan snap 260 ms); Omarchy's reduced motion cuts to the end frames.

### Phase 8 · Settings window and CLI parity ✅
- The settings window (a normal floating window) in the Ryoku Hub grammar: rail, search, Advanced. Typesetting 組版 has the live preview, the preset gallery, six cards of segmented controls, and Reset to preset / Revert / Save. Edits show on the bar at once; only Save writes style.json, and closing unsaved puts the saved style back.
- Advanced: any seal glyph, each monitor's overrides, the raw document. Presets 型: the six as bars, plus shuffle. The other rail pages say what they will hold (Motion 動 became a real page in Phase 10).
- Open it with `hanko settings` (IPC `hanko settings`), or `hanko menu add` for Setup › Hanko in the Omarchy menu. CLI parity: `hanko style set --monitor DP-2 height 32`.

### Phase 9 · Hosting other widgets ✅
- Widgets in Omarchy's bar layout that Hanko doesn't draw (weather, Bluetooth, monitors, system update, third-party widgets) are hosted in the right zone from the host's widget registry, in Hanko's ink, with their own panels and Omarchy's hotkeys still reaching them.
- Hanko's own marks for the rest: the indicators as kanji (録 recording, 書 dictation, 鈴 reminder, 醒 stay awake, 夜 night light; only what's on, red only for "now"; after the phase they became stamps with Omarchy's icons, do not disturb 静 joined them, and two settings, `indicators` and `indicatorStyle`, choose all or only what is on, and icon or kanji, alone or named), the keyboard layout as a mono code, the microphone as 声 (red when muted), and the tray with every icon inked.
- When the right zone fills up, what is playing gives way first, then the tray folds into 盆 with a count, then hosted widgets drop out whole; nothing ever runs into the clock.

### Phase 10 · Motion ✅ and release ⬜
- ✅ The motion spec from Scroll: the scroll unrolls and pans on paper-like curves, a sheet prints from its cell, the live page's plate slides to the next one, readings and the clock fade to new values, the now-notch creeps, and a new stamp is pressed down and settles (the only overshoot). A Motion 動 page with a paper/still switch (style.json `motion`, outside the eighteen settings); still, or Omarchy's animations off, cuts every move to its end frame.
- ✅ A per-monitor override UI under Advanced: pick a monitor, set any setting for it alone, see which ones differ.
- ✅ Visibility (asked for after Phase 10): every part of the bar, each mark and tray app, and every hosted Omarchy or third-party widget can be shown or hidden on the Widgets 部品 page or with `hanko hide|show <part>` (style.json `hidden`).
- ✅ The settings window reflows to any window size.
- ✅ Type scale (asked for after the indicator stamps, from screenshots of the real bar at 1x): one scale for every size, weight and tracking in `core/Type.qml`, readable floors, Medium labels and values, the bold byline fixed, a `typeSize` setting (small, regular, large), and a 1x render pass in `tests/run`.
- ✅ Profile 印影, About 由来 and Credits 謝辞 (asked for after the scroll guides): poster plates in the settings window in the grammar of Ryoku's Profile and Credits pages, with Hanko's own art; the profile's name, line and hidden blocks in `~/.config/hanko/profile.json`, and Save image. Made responsive afterwards: a poster and a stacked layout for each, the art never under the type, scrolling when short.
- ✅ Dynamic overview (asked for after the overview): Ryoku's layout, only busy workspaces and a +, desktops on top, chosen with `overview: grid | dynamic` on Typesetting's Panels card.
- ✅ Workspace overview 一覧 (asked for after the window style): every workspace as a printed page with its windows live where they sit, on every screen; arrows switch, click goes, drag moves, middle-click closes; right-click the workspaces or `omarchy-shell hanko overview`. Working principle from the user's omarchy-overview plugin.
- ✅ Window style 窓 (asked for after the plates): `style.lua`, Hyprland windows in the bar's grammar (hairline frames, square or inset corners, a short black paper shadow, with hard print, seal and none as alternatives, flat group tabs, Motion's timings), loaded from `~/.config/hypr/looknfeel.lua`.
- ⬜ Release, left to the user after testing on hardware: a README install guide, the manifest version, a CHANGELOG entry, a listing on omarchyplugins.com, and merging into `main`.

### Kata 型 · one engine for every design (asked for after the three redesigns)
Spec: `docs/kata/README.md` (also on `revision1`). Margin, Leaf and Shōji become presets over nine parts, three partners and three touches; Classic (today's Typeset bar) stays the default until the Kata bar is complete. Shōji's variants are built first.
- ✅ **K1 · Kata.js**: the pure resolver (`core/Kata.js`), `design` / `borrow` / `touches` in `style.json` (top level and per monitor; `Style.js` carries them through), `Typeset.kata` / `kataFor()` / `setDesign` / `borrow` / `touch` / `surprise` (and draft twins), IPC `designGet | design | designDescribe | borrow | touch`, CLI `hanko design | borrow | touch`. Nothing on screen changes yet.
- ✅ **K2 · Skin and tokens**: `core/Skin.js` (a resolved design → radii, divider width and joints, tempo durations and curves, the figure SOFT axis, washi opacity, grain, where a panel hangs, whether it travels), `core/Brush.js` (brush stroke, kasure, ensō as SVG paths), Kata's tones in `InkMath.kata()` and `Ink.qml` (ink2/3/4 by contrast, line, lift, paper2, sunk, and Leaf's cut, edge, shade, score), `Type.axes(size, wght, soft)`. A pure JS skin passed as a prop, not a singleton, so each monitor can wear its own design.
- ✅ **K3 · The parts, every variant**: `bar/parts/` `Surface` (paper, card, washi), `Fibres`, `Divider` (hairline, score, lattice), `Selection` (tint, plate, wash), `KataSlider` (ruler, block, brush), `Ring` (glyph, ensō), `KataSeal` (outline, deboss, carved), `UnreadMark` (edge, dog-ear, 未), `PointerMark` (thread, crop, brush), `Sign` (heading, tabs, tategaki), `InkShape`; all three designs' variants at once (they were small), not Shōji's alone. Harness `kata-parts.json` and `kata-parts-light.json` (Rosé Pine Dawn, three mixes); renders in `docs/kata/images/k3-*.webp`.
- ✅ **K4 · The Kata bar**: `bar/KataBar.qml` (seal = Letters, desks with the selection's mark and unread marks, app + document, the time with the season touch, now playing, Wi-Fi with its name on reach, volume to scroll, the battery ring, the pointer mark), `bar/parts/Icon.qml`, `core/Season.js` (sekki and kō from the sun's longitude). `BarWindow` shows it for any design but Classic, with the same data, signals and anchors, so the existing sheets and scroll open under its cells until K5. Harness `kata-bars.json`, `kata-bars-light.json`.
- ✅ **K5 · Kata's panels**: `bar/kata/KataPanelView.qml` (the frame: `Surface`, a fold's concave `Joins`, the sign as eyebrow, index tabs at the foot or a tategaki column; arrival by fold, slip or slide, and a slide panel travels along the bar to the next cell) holding `TimePanel` (the day as a sentence, the month with today on a plate or in an ensō, the kō in tategaki with the season touch, other cities), `SoundPanel`, `NetworkPanel` (Wi-Fi and Bluetooth), `PowerPanel` (the ring, brightness, a segmented power mode, session actions that hold to confirm) and `LettersPanel` (unread marks, Quiet). New parts `KataSwitch`, `Choice`, `Joins`; `bar/kata/KataList`, `Figure`, `Heading`, `SessionRow`. `SheetWindow` prints it instead of `SheetView` when the design isn't Classic, with the same requests; Tab walks the five panels. Harness `kata-panels.json`, `kata-panels-light.json`.
- ✅ **K6 · The second wave**: three more main parts in `Kata.js` with the same mechanism: `notify` (cards that swipe aside, tickets that tear off at a perforation, rows between lattice lines with 未), `overview` (miniatures, contact sheet frames numbered 03A with sprocket holes and crop marks, framed shōji desks with both numerals) and `hold` (Leaf's soak, which Margin shares, or Shōji's brush stroke). `bar/parts/Letter.qml` and `Hold.qml`; the Letters panel and session actions use them, and the overview prints its pages in the design's part (always the grid under a Kata design). Letters put away are set aside for the session (`Bar.setAside`). Harness `kata-wave.json`, `kata-wave-light.json`, `overview-{margin,leaf,shoji,kata-light}.json`.
- ✅ **Kata Bluetooth** (asked for after K7: the three designs had no Bluetooth): a Bluetooth cell on the Kata bar (the rune, faint when off; the connected device's charge, red when low; its name on reach) and its own panel, `bar/kata/BluetoothPanel.qml` (switch, the connected device as the hero with its charge on the ring part, connected / your devices / nearby, P toggles). Connections became Network (Wi-Fi only); Tab and Leaf's tabs walk six panels. `Blue.row()` carries `level`.
- ✅ **Panel opacity 透け** (asked for after Kata's Bluetooth: every panel's opacity adjustable): `panelOpacity` in style.json (30–100%, or none for the design's own), a slider with Auto on Settings › Design, `hanko style set panelOpacity 70` from a terminal. Every panel follows it: Kata's six (the `Surface` part; shadows fade out as the paper clears), Classic's sheets and the scroll. One drag is one step of Undo.
- ✅ **Revision 2 · Classic polished** (`d565381`, made on `revision2` and merged into `dev`; asked for: polish Classic as a senior would, without redesigning it): Classic's sheets get a folio and a faint kanji behind the title, an italic standfirst, underscored group heads, a hover bar on rows, a capped needle, a soft shadow, printer's crop marks, a colophon foot, and Time's ribbon without its doubled rule and with a red notch on today.
- ✅ **Classic bar polish** (asked for on the user's own style): kanji indicator seals in ink with red kept for recording, tabular figures on readings and the clock, shorter softer rules, hover plates on cells, a visible urgent dot, and a fix for the blank the tray left beside the marks.
- ✅ **Bar feedback, after game HUDs**: readings count up to new values, meters fill tick by tick, a changed reading's label inks up for a moment, cells press, and a red reading also breathes. `tests/motion.py` checks the motion.
- ✅ **Bar, a more natural pass**: the rodrule drawn as a stroke of ink that fades at its ends and darkens toward now, readings grouped by space instead of hairlines, a half-length BT meter, workspace windows as solid tiles, and the rod's grip shown only when you reach for it.
- ✅ **Profile, About and Credits redesigned**: Profile as a seal registration certificate (holder and register left, the seal in a ruled box on a practice grid right, live readings as a row of stats with gauges, edition and day as the foot); About with its lineage side by side and a 奥付 colophon box under the moon; Credits grouped under Foundation, Lineage and Type with a 校-stamped proofreaders card.
- ✅ **Profile: the seal becomes a signed work**: the dithered red seal is gone; your glyph is written large in ink and signed with a rakkan, your name down the margin over two small seals (a white-cut square with your initial, a red ring with the glyph).
- ✅ **Kan 鑑 and a brush for every kanji**: the seal glyph defaults to 鑑 with 漢 観 寛 to choose from in Settings; every kanji in Hanko is drawn in the bundled Yuji Boku brush face; glosses a step larger so the brush reads at 1x.
- ✅ **Plainer kanji on the bar**: cells read 波 双 耳 光 力, indicators 写 言 予 目 月 休, the inbox 文; the workspace numerals stay.
- ✅ **Sheet hands**: every cell's sheet in six hands, Ledger 帳 (the page), Tanzaku 短冊 (poem slips hung from a rail, as long as their level; replaced a first Dial hand), and four after old Japan's crafts, built from the design studies: Shōgi 将棋 (the board), Soroban 算盤 (the abacus), Odoshi 縅 (armour lacing) and Kasumi 霞 (gold-leaf mist bands), drawn from one model per sheet (`core/Hands.js`) ([revision2/sheet-hands.md](revision2/sheet-hands.md); Prose and Mon were tried and taken out), chosen per sheet on Settings › Sheets with a live preview; `hanko style set sheetStyle:<sheet> <hand>`. A seventh hand, Shōji 障子 (the Shōji design's panels, with a new Display panel), is S1 of folding Shōji into Hanko.
- ✅ **The Hanko preset is the user's bar**: a stamped seal, kanji pages, named kanji indicators shown only when on, flush sheets and no scroll guides, as the user runs it.
- ✅ **Shōji into Hanko** (asked for: "Shōji should be part of Hanko, not a separate design; tweak Hanko to get the Shōji design, and all its sheets move to the sheets in Hanko"). One design, Hanko; Shōji becomes a sheet hand, new option values and a preset. Steps, each its own commit (plan in HANDOFF §10):
  - ✅ **S1 · Shōji as a sheet hand**: the panels move to `bar/sheets/`, a new Shōji Display panel, the rail kept, a seventh card on Settings › Sheets.
  - ✅ **S2 · The framed overview** as `overview: framed`, on any bar.
  - ✅ **S3 · Shōji's bar parts as Hanko options** (`surface: washi`, `seal: carved`, `notif: seal`, `spaces: brush`, `title: ink`, `clock: season`, `media: ink`, `status: ink`, `pointer`, and global `season`, `numerals`, `grain`).
  - ✅ **S4 · The Shōji preset and migration** (a saved `design: shoji` loads as the preset).
  - ✅ **S5 · Removal**: the design switch, `KataBar`, Settings › Design, `core/Kata.js`, `hanko design` and `hanko touch`; Panel opacity moved to Settings › Sheets.
- ✅ **K7 · Settings › Design 意匠** (asked for without a Save button): the rail's first Bar page. Four design cards, each with its bar drawn live (Classic the Typeset bar); the mix named in a line, Back to the design and Surprise me; twelve borrow rows, each variant drawn small by its own part (`bar/settings/PartPreview.qml`), the current one ringed and a borrowed part marked; the touches (season with today's sekki, numerals, grain). The whole settings window now saves as you go: `Typeset.keep()` after every edit, `Typeset.history` and `undo()` (Ctrl+Z and the action bar's Undo), forgotten on close; Save and Revert are gone. Harness `design-settings.json`, `-light`, `-narrow`.
- ✅ **Margin and Leaf removed** (asked for): two designs are left, Hanko and Shōji, and with them borrowing, Surprise me and the borrow rows on Settings › Design; a style.json naming Margin or Leaf loads as Hanko and a saved `borrow` is ignored. Shōji renders exactly as before.
- ✅ **The right side, four ways** (asked for: "the right side looks too cramped; research and come up with a better design with a Japanese touch", then "add all"): four `status` values and four presets on the Hanko bar, Ma 間 (groups held apart by space), Shizuka 静 (quiet until it changes), Suji 筋 (one brush line per reading) and Inrō 印籠 (one ruled case), from six study sheets and their research in [right-side/](right-side/README.md).
- ✅ **Fewer presets:** Sheet, Scroll and Instrument taken out (aliased to Kamon and Islet); Ma carries the user's bar (36 px, fuda); Kamon is last of the bars.
- ✅ **Presets 型, a page of their own** (asked for: "move the presets from Typesetting to a new Presets page, with the 4 new designs there too"): the first page of `01 BAR`, every preset a numbered specimen with its kanji, blurb, telling settings and its bar drawn live, in one list (the bars, then the studies), filtered by search, with Shuffle and Reset; Typesetting keeps a one-line link to it.
- ✅ **Kamon 家紋** (asked for: no "Hanko" on the preset): the default preset is renamed Kamon, the family crest; "Hanko" still loads it.

- ✅ **Inkan 印, the seal only** (asked for: "now I want to work on this Inkan", shell concept 04, then "go with your idea and all"): a `form` setting that takes the bar away and leaves one seal in a corner, its carving the status; pressed, it prints the whole shell as one sheet, No. 00. Design and timings in [shell-concepts/inkan/](shell-concepts/inkan/README.md). Steps, each its own commit:
  - ✅ **I0 · Design sheets**: the seal's states, No. 00, the four corners and per monitor, the ink-press, a light theme.
  - ✅ **I1 · The model**: `form` and `inkanAt` in `Style.js`, the Inkan preset, `core/Inkan.js` (wear, specks, chips, placement, No. 00 rows) with tests.
  - ✅ **I2 · The seal that reads**: `bar/InkanSeal.qml`, harness scene and params.
  - ✅ **I3 · The corner layer**: `bar/SealWindow.qml`, the bar parked under `inkan`, `barSize` 0, clicks, wheel, hover reading.
  - ✅ **I4 · No. 00**: `bar/sheets/AllSheet.qml`, printing from the seal, rows into their sheets and back, Omarchy's panel hotkeys at the corner, the scroll from the seal.
  - ✅ **I5 · The ink-press**: press, bloom, print out, lift off.
  - ✅ **I6 · Settings, CLI and keys**: Form and Corner rows, the Inkan specimen on Presets, `hanko press`, README.
  - ✅ **I7 · Drag to a corner** and the recording ring.

- ✅ **Kōsei 校正, Typesetting as a proof** (asked for: "all are just crumbled in Typesetting … research how people create this kind of experience, then something unique and premium"): the six cards of segmented controls are replaced by a galley of your bar (set in two lines at your screen's width, its parts numbered in the margin), an index of ten parts and a case per part with a live specimen of every way it can be set (hover tries, click keeps) and the few word choices under it. Panel settings moved to Scroll 巻. Research and renders in [settings-kosei/](settings-kosei/README.md).

- 🔨 **Kōsei, the whole window** (asked for: "redesign all the other sections too … full control of the whole settings flow and layout"): every page on the proof's rule, the thing itself first. Plan and research in [settings-kosei/](settings-kosei/README.md#part-two-the-whole-window).
  - ✅ **R1 · The shell and Screens 画面**: rail regrouped (Typesetting first), key hints, the action bar names the last change, one file per page built only while open; Advanced becomes Screens (monitors to scale, overrides by part, style.json); your own glyph in the Seal case; "on the bar / set aside" in each part's case.
  - ✅ **R2 · Presets 型, the pattern book**: nine swatches, the open one set as your bar, only what it would change, Use.
  - ⬜ **R3 · Parts 部品, the sorts tray**
  - ⬜ **R4 · Colour 色**
  - ⬜ **R5 · Sheets 紙, Scroll 巻, Overview 一覧**
  - ⬜ **R6 · Motion 動, the timesheet; Keys 鍵, the keymap**

## Dev loop

```sh
scripts/hanko dev          # symlink this checkout into ~/.config/omarchy/plugins/hanko.bar and select it
omarchy plugin validate .  # same checks the shell runs
tests/run                  # node unit tests + qmllint + offscreen renders into tests/out/
```

On a machine without Omarchy, `tests/run` still runs the unit tests, lint and renders (it needs Node and `pip install PySide6-Essentials`).
