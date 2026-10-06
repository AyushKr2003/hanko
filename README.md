# Hanko

判子 · a configurable bar for [Omarchy](https://github.com/omacom/omarchy), printed in your theme's paper and ink.

**Status: early plugin (phase 9 of 10).** gama1 merges the beta1 and alpha1 directions into one bar where every part is a setting: 15 settings, 6 presets, 2,985,984 combinations. The plugin (`hanko.bar`, a full-bar Omarchy plugin) is being built phase by phase; see the [roadmap](docs/ROADMAP.md). Right now it draws the seal, your workspaces, the window title, the clock (stacked, inline or mono, following your 12- or 24-hour setting), what is playing, your sound, network, battery and brightness, and your notifications on your theme's paper, edged with a hairline, a day rule, a scroll rod or the rod carrying the day, solid, glass or floating inset. Clicking the clock, a status cell or the inbox drops a sheet from it (Time, Sound, Network, Power, Inbox), and Omarchy's own panel hotkeys open the same sheets; with `panels: scroll` the same clicks unroll a handscroll of all six instead. Indicators, the keyboard layout, the microphone and the tray appear as small marks in Hanko's ink, and any other widget in your Omarchy bar layout (weather, Bluetooth, third-party ones) is hosted in the right zone. Every setting can be changed in Hanko's settings window (`scripts/hanko settings`), which shows each change on the bar at once and writes `~/.config/hanko/style.json` when you Save.

## Try it

```sh
git clone -b dev https://github.com/AyushKr2003/hanko.git
cd hanko
scripts/hanko install      # or `scripts/hanko dev` to symlink the checkout
scripts/hanko settings     # the settings window
scripts/hanko style preset Sheet
scripts/hanko style set --monitor DP-2 height 32
scripts/hanko menu add     # Setup › Hanko in the Omarchy menu
scripts/hanko uninstall    # puts your previous bar back
```

Hanko only replaces the bar. If it ever fails to load, Omarchy falls back to its own bar on its own.

**A key for the scroll.** Omarchy already uses `SUPER + SPACE`, so Hanko doesn't take a key of its own. To unroll the scroll from the keyboard, add this to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + CTRL + U", "Hanko scroll", "omarchy-shell hanko scroll")
```

**Glass needs a blur rule.** The `glass` surface (and Omarchy's bar transparency toggle, which Hanko shows as glass) draws the paper at 74 %. Omarchy doesn't blur its own bar, so Hanko doesn't change your Hyprland config either; for the frosted look, add this to `~/.config/hypr/hyprland.lua`:

```lua
hl.layer_rule({ match = { namespace = "hanko-bar" }, blur = true, ignore_alpha = 0.5 })
```

![The Typesetting settings page](docs/mockups/gama1/01-settings.png)
![Six presets](docs/mockups/gama1/03-presets.png)

- **[Every component and combination](docs/COMPONENTS.md)**
- [Handoff: the full state of the build](docs/HANDOFF.md)
- [Design overview](docs/DESIGN.md)
- [Twelve random combinations](docs/mockups/gama1/04-shuffle.png)
- [Presets across themes](docs/mockups/gama1/05-presets-x-themes.png)
- [Hanko preset with the scroll open](docs/mockups/gama1/20-desk-hanko-scroll.png)
- [Sheet preset with a sheet open](docs/mockups/gama1/21-desk-sheet-sound.png)
- [All gama1 sheets](docs/mockups/gama1/)

Earlier directions: [beta1](docs/history/beta1-DESIGN.md) and [alpha1](docs/history/alpha1-DESIGN.md).

Design language inspired by [Ryoku](https://github.com/Ryoku-dev/ryoku)'s settings app and [ryoku.dev](https://ryoku.dev). The wallpaper plates in the mockups are procedural and made for them.
