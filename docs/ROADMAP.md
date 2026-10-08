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
<<<<<<< HEAD
- ✅ Window style 窓 (asked for after the plates): `style.lua`, Hyprland windows in the bar's grammar (hairline frames, square or inset corners, a short black paper shadow, with hard print, seal and none as alternatives, flat group tabs, Motion's timings), loaded from `~/.config/hypr/looknfeel.lua`.
=======
- ✅ Dynamic overview (asked for after the overview): Ryoku's layout, only busy workspaces and a +, desktops on top, chosen with `overview: grid | dynamic` on Typesetting's Panels card.
- ✅ Workspace overview 一覧 (asked for after the window style): every workspace as a printed page with its windows live where they sit, on every screen; arrows switch, click goes, drag moves, middle-click closes; right-click the workspaces or `omarchy-shell hanko overview`. Working principle from the user's omarchy-overview plugin.
- ✅ Window style 窓 (asked for after the plates): `style.lua`, Hyprland windows in the bar's grammar (hairline frames, square or inset corners, a hard seal-red print under the focused window, flat group tabs, Motion's timings), loaded from `~/.config/hypr/looknfeel.lua`.
>>>>>>> claude/hanko-plugin-zzm827
- ⬜ Release, left to the user after testing on hardware: a README install guide, the manifest version, a CHANGELOG entry, a listing on omarchyplugins.com, and merging into `main`.

### Kata 型 · one engine for every design (asked for after the three redesigns)
Spec: `docs/kata/README.md` (also on `revision1`). Margin, Leaf and Shōji become presets over nine parts, three partners and three touches; Classic (today's Typeset bar) stays the default until the Kata bar is complete. Shōji's variants are built first.
- ✅ **K1 · Kata.js**: the pure resolver (`core/Kata.js`), `design` / `borrow` / `touches` in `style.json` (top level and per monitor; `Style.js` carries them through), `Typeset.kata` / `kataFor()` / `setDesign` / `borrow` / `touch` / `surprise` (and draft twins), IPC `designGet | design | designDescribe | borrow | touch`, CLI `hanko design | borrow | touch`. Nothing on screen changes yet.
- ✅ **K2 · Skin and tokens**: `core/Skin.js` (a resolved design → radii, divider width and joints, tempo durations and curves, the figure SOFT axis, washi opacity, grain, where a panel hangs, whether it travels), `core/Brush.js` (brush stroke, kasure, ensō as SVG paths), Kata's tones in `InkMath.kata()` and `Ink.qml` (ink2/3/4 by contrast, line, lift, paper2, sunk, and Leaf's cut, edge, shade, score), `Type.axes(size, wght, soft)`. A pure JS skin passed as a prop, not a singleton, so each monitor can wear its own design.
- ⬜ **K3 · Part facades with Shōji's variants**: `Surface`, `Divider`, `PointerMark`, `Selection`, `Slider`, `Ring`, `Seal`, `UnreadMark`, `Sign` in `bar/parts/`, a harness gallery.
- ⬜ **K4 · The Kata bar**: `BarSurface` draws the Kata bar when the design is not Classic.
- ⬜ **K5 · The one-panel window and its panels**: Sound, Time, Network, Power, Letters on the facades.
- ⬜ **K6 · Margin's and Leaf's variants**, part by part.
- ⬜ **K7 · Settings › Design** (four designs, nine borrow rows, touches, Surprise, Undo) and the harness grid of panels × designs.

## Dev loop

```sh
scripts/hanko dev          # symlink this checkout into ~/.config/omarchy/plugins/hanko.bar and select it
omarchy plugin validate .  # same checks the shell runs
tests/run                  # node unit tests + qmllint + offscreen renders into tests/out/
```

On a machine without Omarchy, `tests/run` still runs the unit tests, lint and renders (it needs Node and `pip install PySide6-Essentials`).
