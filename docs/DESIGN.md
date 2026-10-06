# Hanko gama1: one bar, two temperaments

beta1 and alpha1 were two answers to the same brief. beta1 treated the bar as a **printed running head**: a seal, label-over-value cells, tick meters, a day rule along the foot, and flush sheets that drop from a cell. alpha1 treated it as a **calm line of type that unrolls into a handscroll**: a workspace seal, real-layout glyphs, a serif byline, kanji status, stamps, and a rod you pull.

They share everything underneath: paper and ink from `colors.toml`, emphasis by inversion, hairlines instead of shadows, and the seal red as the only colour. So gama1 stops choosing between them. Each part of the bar becomes a setting, and both designs become presets of one bar:

- **Sheet** = beta1
- **Scroll** = alpha1
- **Hanko** = the merge (default): alpha1's left end and handscroll, beta1's cells and meters, and a new edge, the roller that carries the day.

Three new presets show the range: **Quiet**, **Instrument** and **Islet**.

The settings live on Hanko's own settings page, drawn in the same Ryoku Hub grammar as everything else (numbered rail, inverted selection, `//` group heads, an action bar). Its first page, **Typesetting 組版**, has a live preview, a preset gallery, and one segmented control per setting.

Everything about the options, how they interact, the presets, the combination count, the settings page and the config file is in **[COMPONENTS.md](COMPONENTS.md)**.

The reasoning behind each earlier direction is kept as written:

- [beta1 design](history/beta1-DESIGN.md) · [beta1 mockups](mockups/beta1/)
- [alpha1 design](history/alpha1-DESIGN.md) · [alpha1 mockups](mockups/alpha1/)

## How it plugs into Omarchy

Unchanged: one `bar`-kind plugin (`hanko.bar`), `manifest.json` plus `Bar.qml`, installed into `~/.config/omarchy/plugins/hanko.bar` and enabled with `omarchy bar use hanko.bar`. The style is a small JSON file next to it (see COMPONENTS.md §7); the bar reads one resolved style object and each component switches on its own mode. Sheets and the handscroll are both layer-shell surfaces owned by the bar, so switching `panels` needs no restart.
