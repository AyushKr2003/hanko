#!/usr/bin/env bash
# Renders each sheet (docs/densho/source/NN-*.html) to docs/densho/images/NN-*.webp
# with headless Chromium. A sheet names its width (and the most height it may
# need): <meta name="size" content="1920x3000">; the empty foot is trimmed.
# Usage: shoot.sh [sheet.html ...]   (default: every sheet)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="$here/../images"; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$out"
sheets=("$@"); [ ${#sheets[@]} -eq 0 ] && sheets=("$here"/[0-9][0-9]-*.html)
for f in "${sheets[@]}"; do
  f="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  size=$(grep -oP 'name="size" content="\K[0-9]+x[0-9]+' "$f" || echo 1920x1080)
  name=$(basename "$f" .html)
  chromium --headless=new --hide-scrollbars --disable-gpu --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=5000 \
    --window-size="${size/x/,}" --screenshot="$tmp/$name.png" "file://$f" >/dev/null 2>&1
  # trim the empty foot: keep 64 px under the last thing drawn
  w=${size%x*}; read -r th ty < <(magick "$tmp/$name.png" -fuzz 2% -trim -format '%h %Y\n' info: | tr -d '+')
  h=$((th + ty + 64)); [ "$h" -gt "${size#*x}" ] && h=${size#*x}
  magick "$tmp/$name.png" -crop "${w}x${h}+0+0" +repage "$tmp/$name.c.png"
  cwebp -quiet -q 86 "$tmp/$name.c.png" -o "$out/$name.webp"
  echo "$name.webp  ${w}x${h}"
done
