// The brush for the boot screen (Ōin's brush mark, Settings › Boot): a kanji
// written stroke by stroke in its real order, drawn exactly as the shutdown
// ceremony draws it (plugins/hanko.osd's Canvas: core/Strokes.js's points,
// a stroke 6.2% of the box wide, pressed to 80% at its start, full through
// the middle, lifted to 38% at its end, round caps), as SVG for librsvg.
//
//   node brush.mjs OUT SIZE COLOUR KANJI FRAMES PREFIX
//     writes PREFIX-0.png … PREFIX-(FRAMES-1).png into OUT, the kanji
//     written a share further in each, the last one whole; FRAMES 1 is the
//     kanji whole.
import { readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
// core/Strokes.js is a QML JavaScript library: its text, run as a function.
export function strokes() {
  const src = readFileSync(join(here, "../../core/Strokes.js"), "utf8").replace(/^\.pragma library\s*$/m, "")
  return new Function(`${src}\nreturn { SIZE, STROKES }`)()
}

// The ceremony's width along a stroke (t from 0 to 1).
export function width(t) {
  return t < 0.12 ? 0.8 + t / 0.12 * 0.2 : t > 0.7 ? 1 - (t - 0.7) / 0.3 * 0.62 : 1
}

// One frame: `written` strokes (a fraction for the one being written).
export function svg(kanji, size, colour, written) {
  const { SIZE, STROKES } = strokes()
  const st = STROKES[kanji]
  if (!st) throw new Error(`no strokes for ${kanji} in core/Strokes.js`)
  const k = size / SIZE, base = size * 0.062
  const lines = []
  for (let s = 0; s < st.length && s < written; s++) {
    const pts = st[s], upto = Math.min(1, written - s)
    const n = Math.max(2, Math.round(pts.length * upto))
    for (let i = 1; i < n; i++) {
      const t = i / (pts.length - 1)
      const f = v => (v * k).toFixed(2)
      lines.push(`<line x1="${f(pts[i - 1][0])}" y1="${f(pts[i - 1][1])}" x2="${f(pts[i][0])}" y2="${f(pts[i][1])}" stroke-width="${(base * width(t)).toFixed(2)}"/>`)
    }
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">` +
    `<g fill="none" stroke="${colour}" stroke-linecap="round" stroke-linejoin="round">${lines.join("")}</g></svg>\n`
}

export function frames(out, size, colour, kanji, count, prefix) {
  const { STROKES } = strokes()
  const total = STROKES[kanji].length
  const tmp = join(out, `.${prefix}-svg`)
  mkdirSync(tmp, { recursive: true })
  try {
    for (let i = 0; i < count; i++) {
      const written = count === 1 ? total : total * (i + 1) / count
      const file = join(tmp, `${i}.svg`)
      writeFileSync(file, svg(kanji, size, colour, written))
      execFileSync("magick", ["-background", "none", `rsvg:${file}`, "-depth", "8", join(out, `${prefix}-${i}.png`)])
    }
  } finally { rmSync(tmp, { recursive: true, force: true }) }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [out, size, colour, kanji, count, prefix] = process.argv.slice(2)
  if (!prefix) { console.error("usage: node brush.mjs OUT SIZE COLOUR KANJI FRAMES PREFIX"); process.exit(2) }
  frames(out, Number(size), colour, kanji, Number(count), prefix)
}
