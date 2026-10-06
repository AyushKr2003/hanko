# Hanko 判子

A bar for [Omarchy](https://github.com/omacom/omarchy), printed in your theme's paper and ink.

![The Typesetting settings page](docs/mockups/gama1/01-settings.png)

## What you get

- **Every part is a setting:** 16 settings and 6 presets (Sheet, Scroll, Hanko, Quiet, Instrument, Islet).
- **Left:** a seal, your workspaces and the window title.
- **Centre:** the clock and what's playing.
- **Right:** sound, network, Bluetooth, battery, brightness and notifications.
- **Panels:** click any cell to drop a sheet, or set `panels: scroll` to unroll every panel as one handscroll. The scroll opens on today's weather.
- **Your widgets still work:** Omarchy's hotkeys, tray, indicators and third-party bar widgets.
- **Follows your theme,** light or dark, and switches with it live.
- **Safe to try:** if Hanko fails to load, Omarchy puts its own bar back.

## Requirements

- Omarchy with its shell running (`omarchy-shell`)
- `jq` and `rsync` for the CLI; `curl` for the weather
- Noto CJK fonts for the kanji (Omarchy installs them)

## Install

```sh
git clone -b dev https://github.com/AyushKr2003/hanko.git
cd hanko
scripts/hanko install
```

- This copies Hanko to `~/.config/omarchy/plugins/hanko.bar` and makes it your bar.
- It remembers the bar you had, so uninstalling puts that one back.
- **For development:** `scripts/hanko dev` symlinks the checkout instead, and saving a file reloads the bar.
- **Check the install:** `scripts/hanko doctor`.

## Update

```sh
cd hanko && git pull && scripts/hanko install
```

## Uninstall

```sh
scripts/hanko menu remove   # only if you added the menu entry
scripts/hanko uninstall
```

- This switches back to your previous bar and removes the plugin folder.
- Your style is kept in `~/.config/hanko/`. Delete that folder to remove it too.

## Use

| Do this | Command |
|---|---|
| Open the settings window | `scripts/hanko settings` |
| Pick a preset | `scripts/hanko style preset Sheet` |
| Change one setting | `scripts/hanko style set clock mono` |
| Change it on one monitor | `scripts/hanko style set --monitor DP-2 height 32` |
| Random look | `scripts/hanko style shuffle` |
| Back to the preset | `scripts/hanko style reset` |
| See the current style | `scripts/hanko style get` |
| Hide or show a part | `scripts/hanko hide tray` / `scripts/hanko show tray` |
| Unroll the scroll | `scripts/hanko scroll` |
| Turn motion off | `scripts/hanko style set motion still` |
| Add Setup › Hanko to the Omarchy menu | `scripts/hanko menu add` |

- Changes show on the bar at once and are saved to `~/.config/hanko/style.json`.
- Every setting and option is listed in [COMPONENTS.md](docs/COMPONENTS.md).
- Parts you can hide include `seal`, `clock`, `volume`, `weather`, `tray`, `indicator:<name>`, `tray:<app>` and `hosted:<widget id>`.

## Optional extras

**A key for the scroll.** Add this to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + CTRL + U", "Hanko scroll", "omarchy-shell hanko scroll")
```

**Frosted glass.** The `glass` surface needs a blur rule in `~/.config/hypr/hyprland.lua`:

```lua
hl.layer_rule({ match = { namespace = "hanko-bar" }, blur = true, ignore_alpha = 0.5 })
```

## Troubleshooting

- **Bar didn't change:** run `scripts/hanko doctor`.
- **QML errors:** check `journalctl --user -f`.
- **A setting was ignored:** `omarchy-shell hanko warnings` lists what `style.json` got wrong.
- **No weather on the scroll:** it needs `curl` and a network connection, and only shows on screens about 1600 px wide or more.

## Docs

- [Every component and combination](docs/COMPONENTS.md)
- [Design overview](docs/DESIGN.md)
- [Roadmap](docs/ROADMAP.md)
- [Handoff: the full state of the build](docs/HANDOFF.md)
- [Changelog](CHANGELOG.md)
- Earlier design directions are on the `docs` branch.

## Credits

- Design language inspired by [Ryoku](https://github.com/Ryoku-dev/ryoku)'s settings app and [ryoku.dev](https://ryoku.dev). No Ryoku code is used.
- Bundled fonts: Fraunces and Space Grotesk, under the SIL Open Font License (`assets/fonts/`).

## License

- Hanko is [MIT](LICENSE).
- The bundled fonts keep their own SIL Open Font License (`assets/fonts/*-OFL.txt`).
