# Hanko

判子 · a configurable bar for [Omarchy](https://github.com/omacom/omarchy), printed in your theme's paper and ink.

**Status: early plugin (phase 4 of 10).** gama1 merges the beta1 and alpha1 directions into one bar where every part is a setting: 15 settings, 6 presets, 2,985,984 combinations. The plugin (`hanko.bar`, a full-bar Omarchy plugin) is being built phase by phase; see the [roadmap](docs/ROADMAP.md). Right now it draws the seal, your workspaces, the window title, the clock (stacked, inline or mono, following your 12- or 24-hour setting) what is playing, your sound, network, battery and brightness, and your notifications on your theme's paper, and reads every setting from `~/.config/hanko/style.json`.

## Try it

```sh
git clone -b dev https://github.com/AyushKr2003/hanko.git
cd hanko
scripts/hanko install      # or `scripts/hanko dev` to symlink the checkout
scripts/hanko style preset Sheet
scripts/hanko uninstall    # puts your previous bar back
```

Hanko only replaces the bar. If it ever fails to load, Omarchy falls back to its own bar on its own.

![The Typesetting settings page](docs/mockups/gama1/01-settings.png)
![Six presets](docs/mockups/gama1/03-presets.png)

- **[Every component and combination](docs/COMPONENTS.md)**
- [Design overview](docs/DESIGN.md)
- [Twelve random combinations](docs/mockups/gama1/04-shuffle.png)
- [Presets across themes](docs/mockups/gama1/05-presets-x-themes.png)
- [Hanko preset with the scroll open](docs/mockups/gama1/20-desk-hanko-scroll.png)
- [Sheet preset with a sheet open](docs/mockups/gama1/21-desk-sheet-sound.png)
- [All gama1 sheets](docs/mockups/gama1/)

Earlier directions: [beta1](docs/history/beta1-DESIGN.md) and [alpha1](docs/history/alpha1-DESIGN.md).

Design language inspired by [Ryoku](https://github.com/Ryoku-dev/ryoku)'s settings app and [ryoku.dev](https://ryoku.dev). The wallpaper plates in the mockups are procedural and made for them.
