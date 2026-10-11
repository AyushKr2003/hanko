#!/bin/bash
# Renders every image in ../images/*.webp from the one engine.
# Needs Node + Playwright's Chromium, Pillow, and Noto Serif/Sans JP installed.
set -euo pipefail
cd "$(dirname "$0")"
node kata.test.mjs >/dev/null && echo "resolver tests ok"
OUT=../images; TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT; mkdir -p "$OUT"
D="file://$PWD/desk.html?still=1"; H="file://$PWD/sheets.html?page"
shot() { node shoot.mjs "$1" "$TMP/$2.png" "${3:-1600}" 900 && echo "$2"; }
shot "$H=idea"                                        01-idea
shot "$H=parts"                                       02-parts
shot "$H=compare"                                     03-one-engine
shot "$D&design=margin&panel=sound"                   04-margin
shot "$D&design=leaf&panel=sound"                     05-leaf
shot "$D&design=shoji&panel=sound"                    06-shoji
shot "$H=mixes"                                       07-mixes
shot "$D&design=leaf&slider=brush&unread=stamp&season=kanji&panel=inbox&theme=rosepine" 08-mix-light
shot "$H=settings"                                    09-settings
shot "file://$PWD/playground.html"                    10-playground 1940
shot "$H=build"                                       11-build
python3 - "$TMP" "$OUT" <<'PY'
import sys, glob, os
from PIL import Image
tmp, out = sys.argv[1:]
for f in sorted(glob.glob(tmp + '/*.png')):
    Image.open(f).convert('RGB').save(os.path.join(out, os.path.basename(f)[:-4] + '.webp'), quality=88, method=6)
print('webp written')
PY
