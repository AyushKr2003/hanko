# Hanko

判子 · a printed bar for [Omarchy](https://github.com/omacom/omarchy).

The screen is the page and the bar is its running head: one hairline, one red seal, labels over values, and the day measured along the bar's foot. Clicking a cell drops a flush "sheet" laid out like a settings page. Colours come from your Omarchy theme.

**Status: beta1, design only.** No plugin code yet. This release holds the design direction and mockups; the plugin (`hanko.bar`, a full-bar Omarchy plugin) comes next.

![Hanko on the desktop](docs/mockups/01-desktop.png)

- [Design rationale](docs/DESIGN.md)
- [Bar anatomy](docs/mockups/02-bar-anatomy.png)
- [Sound sheet](docs/mockups/03-sound-sheet.png)
- [Time sheet on Kanagawa](docs/mockups/04-time-sheet-kanagawa.png)
- [Six Omarchy themes](docs/mockups/05-themes.png)

The mockups are rendered from HTML in `docs/mockups/source/` with Playwright: `node shoot.mjs <file.html> <out.png>`.

Design language inspired by the settings app of [Ryoku](https://github.com/Ryoku-dev/ryoku). Wallpapers in the mockups are procedural dither prints made for them.
