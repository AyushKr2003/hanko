# Hanko roadmap: from gama1 design to a working Omarchy bar

gama1 is the design: one bar where every part is a setting ([COMPONENTS.md](COMPONENTS.md)). This roadmap turns it into a real `bar`-kind plugin for Omarchy. Each phase ends in something that runs, and each one lands as its own commit (or a few) on the `dev` branch, which merges into `main` when a phase is ready to try.

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
- A dev loop that works without an Omarchy machine. `qmllint` checks every QML file. An offscreen render harness (PySide6 plus small stubs for Quickshell and `qs.Commons`) draws the bar to PNG, so each phase is checked by eye against the gama1 sheets.
- Node tests for the pure logic: style resolution and the ink ramp.

### Phase 1 · A bar that loads ✅
- `manifest.json` (`hanko.bar`, kind `bar`), `Bar.qml` and `qmldir`.
- One layer-shell `PanelWindow` per screen. It reserves its space, follows `position`, and parks off screen when hidden (the same trick Omarchy uses).
- The host contract: `barHidden` (flag file plus `omarchy.bar syncHidden`), `barSize`, `position` and `fontFamily`.
- **Ink**: paper, four ink tiers at 12, 9, 6.2 and 4.6 : 1, seal red, and hairlines, all derived live from the theme.
- **Typeset**: the 15 settings, the six presets and validation. The style is read from `~/.config/hanko/style.json` with a live file watch; resolution order is preset, then edits, then per-monitor overrides.
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

### Phase 5 · Edge and frame ⬜
- Edge: `hairline` / `dayrule` / `rod` / `rodrule`. The day rule's now-notch moves every minute.
- Dividers on or off; heights 32, 36, 40 and 44 (with the compact one-line cells at 32).
- Surface: `solid` / `glass` / `inset`. Position: top or bottom, with edge details flipping side.
- Follows Omarchy's `bar.position` and transparency toggle unless Hanko overrides them.

### Phase 6 · Sheets ⬜
- `panels: sheets`: a flush sheet drops from the clicked cell, joined to the bar.
- Sheets: Sound (master, outputs, per-app mixer), Time (day ribbon, Elsewhen), Network, Power (battery, profiles), Inbox.
- Keyboard: `Esc`, arrow keys, and `Tab` between sheets. The host's panel hotkeys open the matching sheet.

### Phase 7 · The handscroll ⬜
- `panels: scroll`: one surface that unrolls from the rod, with rollers, an index plate, interludes, `H`/`L` panning with snap, and `Esc` to roll up.
- The same six sections, reusing the sheet contents in scroll layout.

### Phase 8 · Settings window and CLI parity ⬜
- The Typesetting 組版 page as a real window: rail, live preview, preset gallery, segmented controls, and Reset / Revert / Save.
- `hanko style shuffle`; IPC `hanko settings`, `hanko style ...`; an Omarchy menu entry under Setup.

### Phase 9 · Hosting other widgets ⬜
- Third-party bar widgets from `bar.layout` render in Hanko's right zone, with Hanko's spacing and ink.
- Tray support.

### Phase 10 · Motion and release ⬜
- The motion spec from alpha1: paper-like timings, stamp press, and the reduced-motion cut.
- A per-monitor override UI, a README install guide, the `v0.1.0` manifest version, and a listing on omarchyplugins.com.

## Dev loop

```sh
scripts/hanko dev          # symlink this checkout into ~/.config/omarchy/plugins/hanko.bar and select it
omarchy plugin validate .  # same checks the shell runs
tests/run                  # node unit tests + qmllint + offscreen renders into tests/out/
```

On a machine without Omarchy, `tests/run` still runs the unit tests, lint and renders (it needs Node and `pip install PySide6-Essentials`).
