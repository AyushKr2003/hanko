# CLAUDE.md · Hanko

Start every session by reading **[docs/HANDOFF.md](docs/HANDOFF.md)**. It holds the brief, how the user likes to work, every branch, the design, the Omarchy plugin contract, the code map, the dev setup, the status of each phase and detailed instructions for the remaining ones.

The short version:

- Hanko is a `bar`-kind Omarchy plugin (`hanko.bar`) styled after Ryoku's Settings app and ryoku.dev. Original design, never a copy.
- Work on the **`dev`** branch, one phase (or part of one) per commit, pushed right away. Don't merge into `main` unless the user asks.
- The spec is [docs/COMPONENTS.md](docs/COMPONENTS.md); the plan is [docs/ROADMAP.md](docs/ROADMAP.md); the visual target is `docs/mockups/typeset/`.
- Check every change with `tests/run` and compare `tests/out/*.png` with the Typeset mockups.
- At the end of each phase, update ROADMAP, README and HANDOFF (§9 status, §12 known issues) in the same commit.
