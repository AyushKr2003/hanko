// Unit tests for the pure logic in core/*.js. Run: node tests/unit.mjs
// The files are QML JavaScript libraries (".pragma library"), so they are
// loaded as text with that line removed and evaluated in a function scope.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import assert from "node:assert/strict"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")

function load(file, names) {
  const src = readFileSync(join(root, file), "utf8").replace(/^\.pragma library\s*$/m, "")
  return new Function(`${src}\nreturn { ${names.join(", ")} }`)()
}

const S = load("core/Style.js", ["OPTIONS", "KEYS", "PRESETS", "PRESET_NAMES", "DEFAULT_PRESET",
  "coerce", "normalize", "resolve", "withSetting", "withPreset", "shuffled", "combinations"])
const I = load("core/InkMath.js", ["TIERS", "contrast", "tier", "ramp", "mix", "isLight"])
const T = load("core/Title.js", ["appName", "describe", "tildify"])
const W = load("core/Spaces.js", ["numeral", "folio", "layoutOf", "usableArea", "list"])
const St = load("core/Status.js", ["ticks", "bars", "network", "volume", "battery", "brightness",
  "stampGlyph", "tilt", "notifications", "count2", "LOW_BATTERY"])
const E = load("core/Edge.js", ["dayFraction", "hourTicks", "at", "span", "pulled", "PULL_THRESHOLD"])

let passed = 0
function test(name, fn) {
  try { fn(); passed++ } catch (e) { console.error(`FAIL ${name}\n  ${e.message}`); process.exitCode = 1 }
}

test("fifteen settings, 2,985,984 combinations (COMPONENTS.md §5)", () => {
  assert.equal(S.KEYS.length, 15)
  assert.equal(S.combinations(), 2985984)
})

test("every preset sets every setting to a valid option", () => {
  for (const name of S.PRESET_NAMES) {
    const p = S.PRESETS[name]
    assert.deepEqual(Object.keys(p).sort(), [...S.KEYS].sort(), name)
    for (const k of S.KEYS) assert.ok(S.OPTIONS[k].includes(p[k]), `${name}.${k}=${p[k]}`)
  }
})

test("an empty or broken document resolves to the Hanko preset", () => {
  for (const doc of [undefined, null, {}, "x", { preset: "Nope" }]) {
    const s = S.resolve(doc)
    assert.equal(s.preset, "Hanko")
    for (const k of S.KEYS) assert.equal(s[k], S.PRESETS.Hanko[k])
    assert.equal(s.sealGlyph, "印")
    assert.equal(s.edited, false)
  }
})

test("preset, then edits, then monitor overrides", () => {
  const doc = { preset: "quiet", edits: { clock: "mono", height: "40" }, monitors: { "DP-2": { height: 32, spaces: "kanji" } } }
  const a = S.resolve(doc)
  assert.equal(a.preset, "Quiet")
  assert.equal(a.clock, "mono")
  assert.equal(a.height, 40)
  assert.equal(a.spaces, "dots")
  assert.equal(a.edited, true)
  const b = S.resolve(doc, "DP-2")
  assert.equal(b.height, 32)
  assert.equal(b.spaces, "kanji")
  assert.equal(b.clock, "mono")
})

test("invalid and unknown edits are dropped with a warning", () => {
  const warnings = []
  const d = S.normalize({ edits: { clock: "sundial", height: 33, glow: true, edge: "rod" } }, warnings)
  assert.deepEqual(d.edits, { edge: "rod" })
  assert.equal(warnings.length, 3)
})

test("setting a value equal to the preset removes the edit", () => {
  let d = S.withSetting({ preset: "Sheet" }, "clock", "mono")
  assert.deepEqual(d.edits, { clock: "mono" })
  d = S.withSetting(d, "clock", "stacked")
  assert.deepEqual(d.edits, {})
  assert.equal(S.withSetting(d, "clock", "sundial"), null)
})

test("applying a preset clears edits but keeps monitors and glyph", () => {
  const d = S.withPreset({ preset: "Sheet", edits: { clock: "mono" }, sealGlyph: "侍", monitors: { A: { height: 32 } } }, "islet")
  assert.equal(d.preset, "Islet")
  assert.deepEqual(d.edits, {})
  assert.equal(d.sealGlyph, "侍")
  assert.deepEqual(d.monitors, { A: { height: 32 } })
  assert.equal(S.withPreset({}, "Nope"), null)
})

test("seal glyph keeps one character, surrogate pairs included", () => {
  assert.equal(S.resolve({ sealGlyph: "侍たち" }).sealGlyph, "侍")
  assert.equal(S.resolve({ sealGlyph: "𠮷x" }).sealGlyph, "𠮷")
  assert.equal(S.resolve({ sealGlyph: "  " }).sealGlyph, "印")
})

test("shuffle never moves the bar or changes how panels open", () => {
  let seed = 7
  const rng = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647 }
  for (let i = 0; i < 50; i++) {
    const d = S.shuffled({ preset: "Hanko", edits: { position: "bottom" } }, rng)
    const s = S.resolve(d)
    assert.equal(s.position, "bottom")
    assert.equal(s.panels, "scroll")
    for (const k of S.KEYS) assert.ok(S.OPTIONS[k].includes(s[k]))
  }
})

const THEMES = {
  hanko: ["#ddd5c7", "#0a0a09"], "tokyo-night": ["#c0caf5", "#1a1b26"], gruvbox: ["#ebdbb2", "#282828"],
  "flexoki-light": ["#100F0F", "#FFFCF0"], "rose-pine-dawn": ["#575279", "#faf4ed"]
}

test("each ink tier reaches its contrast and the ramp gets fainter", () => {
  for (const [name, [fg, bg]] of Object.entries(THEMES)) {
    const r = I.ramp(fg, bg)
    const fgC = I.contrast(fg, bg)
    for (const [k, target] of Object.entries(I.TIERS)) {
      const c = I.contrast(r[k], bg)
      // A foreground already below a tier's target stays at the foreground.
      assert.ok(c >= Math.min(target, fgC) - 0.01, `${name}.${k} ${c.toFixed(2)} < ${target}`)
    }
    assert.ok(I.contrast(r.inkDim, bg) >= I.contrast(r.inkMuted, bg), name)
    assert.ok(I.contrast(r.inkMuted, bg) >= I.contrast(r.inkFaint, bg), name)
  }
})

test("tiers land close to their targets, not just above them", () => {
  const r = I.ramp(...THEMES.hanko)
  assert.ok(I.contrast(r.inkFaint, "#0a0a09") < 4.8)
  assert.ok(I.contrast(r.inkMuted, "#0a0a09") < 6.5)
})

test("light and dark papers are told apart", () => {
  assert.equal(I.isLight("#FFFCF0"), true)
  assert.equal(I.isLight("#0a0a09"), false)
})

test("app names read the way people say them", () => {
  assert.equal(T.appName("Alacritty"), "Alacritty")
  assert.equal(T.appName("firefox"), "Firefox")
  assert.equal(T.appName("org.gnome.Nautilus"), "Files")
  assert.equal(T.appName("com.mitchellh.ghostty"), "Ghostty")
  assert.equal(T.appName("org.kde.dolphin"), "Dolphin")
  assert.equal(T.appName("chrome-web_app"), "Chrome web app")
  assert.equal(T.appName(""), "")
})

test("titles split into head, receding folders and the file", () => {
  assert.deepEqual(T.describe("Alacritty", "nvim ~/code/hanko/Bar.qml"),
    { app: "Alacritty", head: "nvim", dir: "~/code/hanko/", leaf: "Bar.qml" })
  assert.deepEqual(T.describe("Alacritty", "~/code/hanko"),
    { app: "Alacritty", head: "", dir: "~/code/", leaf: "hanko" })
  assert.deepEqual(T.describe("firefox", "Hanko · GitHub — Mozilla Firefox"),
    { app: "Firefox", head: "Hanko · GitHub", dir: "", leaf: "" })
  assert.deepEqual(T.describe("Spotify", "Spotify"), { app: "Spotify", head: "", dir: "", leaf: "" })
  assert.equal(T.describe("x", "a/b is not a path").dir, "")
  assert.equal(T.tildify("/home/ayush/code", "/home/ayush"), "~/code")
})

test("workspace numerals and folios", () => {
  assert.equal(W.numeral(3), "参")
  assert.equal(W.numeral(10), "拾")
  assert.equal(W.numeral(12), "12")
  assert.equal(W.folio(4), "04")
})

test("workspace list keeps 1-5, adds occupied ones and skips specials", () => {
  const l = W.list([{ id: 7, windows: [{}] }, { id: 8, windows: [] }, { id: -98, windows: [{}] }, { id: 2, urgent: true }], 3)
  assert.deepEqual(l.map(w => w.id), [1, 2, 3, 4, 5, 7])
  assert.equal(l[2].active, true)
  assert.equal(l[1].urgent, true)
  assert.deepEqual(W.list([], 9).map(w => w.id), [1, 2, 3, 4, 5, 9])
})

test("window geometry becomes fractions of the usable area", () => {
  const area = W.usableArea({ x: 0, y: 0, width: 3840, height: 2160, scale: 2, transform: 0, reserved: [0, 40, 0, 0] })
  assert.deepEqual(area, { x: 0, y: 40, width: 1920, height: 1040 })
  const l = W.layoutOf([
    { at: [0, 40], size: [960, 1040], focused: true },
    { at: [960, 40], size: [960, 520] },
    { at: [100, 100], size: [300, 300], floating: true }
  ], area)
  assert.equal(l.length, 2)
  assert.deepEqual(l[0], { x: 0, y: 0, w: 0.5, h: 1, focused: true })
  assert.equal(l[1].x, 0.5)
  assert.equal(l[1].h, 0.5)
  assert.deepEqual(W.layoutOf([{ at: [0, 0], size: [1, 1] }], null), [])
  assert.deepEqual(W.usableArea({ x: 0, y: 0, width: 1080, height: 1920, scale: 1, transform: 1, reserved: [0, 0, 0, 0] }).width, 1920)
})

test("ticks light at least one for any level and never overflow", () => {
  assert.equal(St.ticks(0, 10), 0)
  assert.equal(St.ticks(0.03, 10), 1)
  assert.equal(St.ticks(0.62, 10), 6)
  assert.equal(St.ticks(1.4, 10), 10)
  assert.equal(St.ticks(0.91, 4), 4)
  assert.equal(St.ticks("x", 5), 0)
})

test("network status lines (omarchy-network-status)", () => {
  const w = St.network("wifi\tKumo\t68\t5180\n")
  assert.deepEqual([w.kind, w.name, w.bars, w.needsYou], ["wifi", "Kumo", 3, false])
  assert.equal(St.network("wifi\tKumo\t90\t").bars, 4)
  assert.equal(St.network("ethernet\tenp3s0\t\t").name, "Wired")
  const d = St.network("disconnected\t\t\t")
  assert.deepEqual([d.kind, d.off, d.needsYou], ["disconnected", true, true])
})

test("the red rule: muted, low and draining, offline", () => {
  assert.equal(St.volume(0.62, false).needsYou, false)
  assert.equal(St.volume(0.62, true).needsYou, true)
  assert.equal(St.volume(1.2, false).percent, 120)
  assert.equal(St.volume(1.2, false).level, 1)
  assert.equal(St.battery(91, false, true).needsYou, false)
  assert.equal(St.battery(St.LOW_BATTERY, false, true).needsYou, true)
  assert.equal(St.battery(8, true, true).needsYou, false)
  assert.equal(St.battery(50, false, false), null)
})

test("brightnessctl -m lines", () => {
  assert.equal(St.brightness("intel_backlight,backlight,9600,50%,19200").percent, 50)
  assert.equal(St.brightness(""), null)
})

test("notification files parse newest first with stamps", () => {
  const raw = [
    JSON.stringify({ app: "Firefox", summary: "a", timestamp: 100, urgency: 1 }),
    "not json",
    JSON.stringify({ app: "signal", summary: "b", timestamp: 300, urgency: 2 }),
    JSON.stringify({ app: "Ghostty", summary: "c", timestamp: 200 }),
  ].join("\n")
  const n = St.notifications(raw)
  assert.deepEqual(n.map(x => x.glyph), ["信", "G", "火"])
  assert.equal(n[0].urgent, true)
  for (const x of n) assert.ok(x.tilt >= -6 && x.tilt <= 6)
  assert.equal(St.tilt("same"), St.tilt("same"))
  assert.equal(St.stampGlyph(""), "・")
  assert.equal(St.count2(3), "03")
  assert.equal(St.count2(140), "99")
})

test("the day rule: spent part of the day, minute by minute", () => {
  assert.equal(E.dayFraction(new Date(2026, 9, 6, 0, 0)), 0)
  assert.equal(E.dayFraction(new Date(2026, 9, 6, 6, 0)), 0.25)
  assert.equal(E.dayFraction(new Date(2026, 9, 6, 0, 30)), 30 / 1440)
  assert.equal(E.dayFraction(new Date(2026, 9, 6, 21, 44)), (21 * 60 + 44) / 1440)
  assert.ok(E.dayFraction(new Date(2026, 9, 6, 23, 59)) < 1)
  assert.equal(E.dayFraction("not a date"), 0)
})

test("the day rule: 23 hour ticks, majors every sixth hour", () => {
  const t = E.hourTicks()
  assert.equal(t.length, 23)
  assert.equal(t[0].hour, 1)
  assert.deepEqual(t.filter(x => x.major).map(x => x.hour), [6, 12, 18])
  assert.equal(t[11].fraction, 0.5)
})

test("edge marks stay on whole pixels inside the bar", () => {
  assert.equal(E.at(0.5, 1000, 2), 500)
  assert.equal(E.at(0, 1000, 2), 0)
  assert.equal(E.at(1, 1000, 2), 998)
  assert.equal(E.at(-3, 100, 1), 0)
})

test("edge span: rod caps and inset frame hold the edge in", () => {
  assert.deepEqual(E.span("hairline", 1000, false), { left: 0, width: 1000 })
  assert.deepEqual(E.span("dayrule", 1000, true), { left: 10, width: 980 })
  assert.deepEqual(E.span("rod", 1000, false), { left: 10, width: 980 })
  assert.deepEqual(E.span("rodrule", 1000, true), { left: 14, width: 972 })
})

test("a rod pull goes away from the bar's own edge", () => {
  assert.ok(E.pulled(E.PULL_THRESHOLD, false))
  assert.ok(!E.pulled(E.PULL_THRESHOLD - 1, false))
  assert.ok(!E.pulled(40, true))
  assert.ok(E.pulled(-40, true))
})

console.log(`${passed} passed${process.exitCode ? ", some failed" : ""}`)
