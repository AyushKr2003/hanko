// Unit tests for the pure logic in core/*.js. Run: node tests/unit.mjs
// The files are QML JavaScript libraries (".pragma library"), so they are
// loaded as text with that line removed and evaluated in a function scope.
import { readFileSync, statSync, mkdtempSync, mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { tmpdir } from "node:os"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import assert from "node:assert/strict"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")

function load(file, names) {
  const src = readFileSync(join(root, file), "utf8").replace(/^\.pragma library\s*$/m, "")
  return new Function(`${src}\nreturn { ${names.join(", ")} }`)()
}

const S = load("core/Style.js", ["PRESET_GROUPS", "SHEET_STYLES", "SHEET_KEYS", "OPTIONS", "MOTIONS", "TYPE_SIZES", "TYPE_SCALE", "KEYS", "PRESETS", "PRESET_NAMES", "DEFAULT_PRESET",
  "coerce", "normalize", "resolve", "withSetting", "withPreset", "shuffled", "combinations", "withMonitorSetting",
  "shows", "withShown", "SHOW_OPTIONS"])
const Se = load("core/Settings.js", ["PRESET_KANJI", "presetFacts", "presetMatches", "pageInfo", "RAIL", "CARDS", "MOTION_CARD", "MOTION_OPTIONS", "MOTION_ROWS", "GLYPHS", "PRESET_BLURBS", "optionsFor", "nameOf", "selected", "changes",
  "status", "presetLine", "matches", "pageMatches", "visibilityCards", "prettyId", "PLATES",
  "PROOF", "proofPart", "proofPartOf", "WAYS", "wayOf", "ALSO", "alsoOf", "proofEdits", "proofMatches", "proofStep", "describeChange", "partName", "PAGE_LINES", "PAGE_ALIASES", "BOOT_CHOICES", "presetDiff", "partsTray", "MOTION_SHEET", "KEYMAP", "BINDINGS", "keysLit", "keyDoes", "bindingCode", "bindingsCode", "KAZE_SWITCHES", "kazeValue", "kazeWith", "kazeChange", "kazeOn", "kazeWind", "KAZE_WIND_MAX"])
const I = load("core/InkMath.js", ["TIERS", "contrast", "tier", "ramp", "mix", "isLight", "kata"])
const T = load("core/Title.js", ["appName", "describe", "tildify"])
const W = load("core/Spaces.js", ["numeral", "folio", "layoutOf", "usableArea", "list"])
const St = load("core/Status.js", ["ticks", "bars", "network", "volume", "battery", "brightness",
  "stampGlyph", "tilt", "notifications", "stillHeld", "without", "count2", "LOW_BATTERY", "age", "short", "fill"])
const Sh = load("core/Sheets.js", ["SHEETS", "ALL", "byKey", "forCell", "forOmarchyId", "omarchyIdForCell", "step", "panelAt", "place"])
const Tm = load("core/Time.js", ["dayOfYear", "daysInYear", "isoWeek", "leftInDay", "heading", "ribbon", "parseZones",
  "zonesFromBarConfig", "probeCommand", "parseProbe", "relative", "zoneRow", "ordinal", "counted", "dayAcross"])
const So = load("core/Sound.js", ["friendly", "label", "bus", "detail", "outputs", "streams", "master", "inputNote", "sheet"])
const N = load("core/Net.js", ["splitTerse", "parseWifi", "parseSaved", "band", "securityName", "connectHow", "sheet", "remember", "KEEP_MS"])
const Pw = load("core/Power.js", ["keyValues", "profiles", "stateLabel", "blurb", "details", "sheet"])
const Al = load("core/Almanac.js", ["almanac", "moon", "SEKKI", "KO"])
const Th = load("core/Themes.js", ["themes", "themeName"])
const H = load("core/Hosted.js", ["DRAWN", "OWN", "entries", "hosted", "own", "cell", "idOfCell"])
const Ia = load("core/Iai.js", ["BEATS", "ORDER", "SNAP_PX", "qml", "total", "ease", "at", "hyprSpeed"])
const Sw = load("core/Sweep.js", ["MS", "HOLD", "LENGTH", "PIECES", "frame", "perimeter", "pointAt", "lit", "onScreen"])
const Pt = load("core/Print.js", ["TONES", "CLIP", "steps", "inkFor", "skyAt", "wallpaperMode"])
const Wi = load("core/Wind.js", ["FULL", "MAX_LEAN", "MIN_FELT", "GUST_MS", "lean", "field", "gustAt", "blade", "mayMove", "swayAt", "settings", "virtualLean", "VIRTUAL_MAX", "ripple", "puffAfter", "rippleUniforms"])
const Tk = load("core/Taikan.js", ["LEVELS", "SWITCHES", "ENDS", "CEREMONIES", "view", "crestFor", "word", "halves"])
const Fu = load("core/Fumi.js", ["CRESTS", "crestFor", "kindFor", "timeOf", "urgent", "MOST", "shown", "plain", "gustShare", "isScreenshot", "forHow"])
const Oi = load("core/Oin.js", ["LAYOUT", "bladeWidth", "nicks", "hint", "MOMENTS", "moment", "STORY_MS", "story", "stale", "day"])
const Tj = load("core/Taiji.js", ["NICK", "LEAD", "bladeWidth", "nicks", "hint", "dayLine", "nameOf", "sentence", "CUT_MS", "CUT_CURLS", "cutFlash", "cutRoll", "cutCurl"])
const Ot = load("core/Oto.js", ["EVENTS", "VOLUME", "mode", "play"])
const Pa = load("core/Paths.js", ["local"])
const Ks = load("core/Kaisei.js", ["WINDOW_MS", "crashedRecently"])
const Bt = load("core/Batto.js", ["CRESTS", "crestFor", "rail", "topOf"])
const X = load("core/Extras.js", ["INDICATORS", "indicators", "moduleJson", "keyboard", "tray", "menuText", "menuOnlyIds", "pathId"])
const D = load("core/Display.js", ["monitors", "brightness", "target", "sheet"])
const B = load("core/Blue.js", ["human", "kind", "row", "lists", "cell", "action", "sheet", "mark"])
const E = load("core/Edge.js", ["dayFraction", "hourTicks", "at", "span", "pulled", "PULL_THRESHOLD"])
const Sn = load("core/Season.js", ["SEKKI", "KO", "sunLongitude", "koIndex", "at", "label"])
const Sk = load("core/Skin.js", ["skin", "fromStyle", "SHOJI", "TEMPOS", "RADII", "OPACITY"])
const Ik = load("core/Inkan.js", ["SIZE", "MARGIN", "CORNERS", "ROWS", "NUMERALS", "wear", "specks", "worn", "chips", "chipSize", "carving",
  "reading", "rows", "place", "sheetPlace", "nearest", "cornerOf"])
const Br = load("core/Brush.js", ["stroke", "kasure", "enso", "noise"])
const Ky = load("core/Koyomi.js", ["WAFU", "SEASONS", "sheet", "step", "toMonth", "forecast", "sky", "wind", "kanjiDay", "url", "geocodeUrl", "geocoded", "imperial", "addMonths"])
const AlM = load("core/Almanac.js", ["moon", "SYNODIC"])

let passed = 0
function test(name, fn) {
  try { fn(); passed++ } catch (e) { console.error(`FAIL ${name}\n  ${e.message}`); process.exitCode = 1 }
}

test("twenty-one settings, 24,159,191,040 combinations (COMPONENTS.md §5)", () => {
  assert.equal(S.KEYS.length, 21)
  assert.equal(S.combinations(), 24159191040)
})

test("the handscroll's settings are gone: an old style.json loads without them, and without a warning", () => {
  const warnings = []
  const d = S.normalize({ preset: "Ma", edits: { panels: "scroll", interlude: "fuda", order: "mokuroku", clock: "inline" },
    hidden: ["weather", "endleaf", "mic"] }, warnings)
  assert.deepEqual(d.edits, { clock: "inline" })
  assert.deepEqual(d.hidden, ["mic"])
  assert.deepEqual(warnings, [])
  assert.equal(S.resolve(d).panels, undefined)
})

test("indicators: all or only what is on; icon or kanji, alone or named; set per preset", () => {
  assert.deepEqual(S.OPTIONS.indicators, ["all", "active"])
  assert.deepEqual(S.OPTIONS.indicatorStyle, ["icon", "kanji", "iconname", "kanjiname"])
  assert.equal(S.coerce("indicatorStyle", "full"), "iconname")
  assert.equal(S.resolve({}).indicators, "active")
  assert.equal(S.resolve({}).indicatorStyle, "kanjiname")
  assert.deepEqual(S.PRESET_NAMES.map(p => S.resolve({ preset: p }).indicators), Array(9).fill("active"))
  assert.deepEqual(S.PRESET_NAMES.map(p => S.resolve({ preset: p }).indicatorStyle), ["icon", "icon", "icon", "kanjiname", "kanjiname", "kanji", "kanji", "kanji", "kanji"])
  assert.equal(S.resolve({ edits: { indicatorStyle: "emoji" } }).indicatorStyle, "kanjiname")
  assert.equal(Se.nameOf("indicatorStyle"), "Indicator marks")
})

test("bluetooth styles: device, marks, count, off; an older \"on\" reads as device", () => {
  assert.deepEqual(S.OPTIONS.bluetooth, ["device", "marks", "count", "off"])
  assert.equal(S.coerce("bluetooth", "on"), "device")
  assert.equal(S.resolve({ edits: { bluetooth: "on" } }).bluetooth, "device")
  assert.equal(S.resolve({ preset: "Islet" }).bluetooth, "marks")
})

test("every preset sets every setting to a valid option", () => {
  for (const name of S.PRESET_NAMES) {
    const p = S.PRESETS[name]
    assert.deepEqual(Object.keys(p).sort(), [...S.KEYS].sort(), name)
    for (const k of S.KEYS) assert.ok(S.OPTIONS[k].includes(p[k]), `${name}.${k}=${p[k]}`)
  }
})

test("an empty or broken document resolves to the Kamon preset", () => {
  for (const doc of [undefined, null, {}, "x", { preset: "Nope" }]) {
    const s = S.resolve(doc)
    assert.equal(s.preset, "Kamon")
    for (const k of S.KEYS) assert.equal(s[k], S.PRESETS.Kamon[k])
    assert.equal(s.sealGlyph, "鑑")
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
  let d = S.withSetting({ preset: "Kamon" }, "clock", "mono")
  assert.deepEqual(d.edits, { clock: "mono" })
  d = S.withSetting(d, "clock", "stacked")
  assert.deepEqual(d.edits, {})
  assert.equal(S.withSetting(d, "clock", "sundial"), null)
})

test("applying a preset clears edits but keeps monitors and glyph", () => {
  const d = S.withPreset({ preset: "Quiet", edits: { clock: "mono" }, sealGlyph: "侍", monitors: { A: { height: 32 } } }, "islet")
  assert.equal(d.preset, "Islet")
  assert.deepEqual(d.edits, {})
  assert.equal(d.sealGlyph, "侍")
  assert.deepEqual(d.monitors, { A: { height: 32 } })
  assert.equal(S.withPreset({}, "Nope"), null)
})

test("seal glyph keeps one character, surrogate pairs included", () => {
  assert.equal(S.resolve({ sealGlyph: "侍たち" }).sealGlyph, "侍")
  assert.equal(S.resolve({ sealGlyph: "𠮷x" }).sealGlyph, "𠮷")
  assert.equal(S.resolve({ sealGlyph: "  " }).sealGlyph, "鑑")
})

test("shuffle never moves the bar", () => {
  let seed = 7
  const rng = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647 }
  for (let i = 0; i < 50; i++) {
    const d = S.shuffled({ preset: "Hanko", edits: { position: "bottom" } }, rng)
    const s = S.resolve(d)
    assert.equal(s.position, "bottom")
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
  assert.deepEqual(l[0], { x: 0, y: 0, w: 0.5, h: 1, focused: true, name: "", address: "" })
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

test("float: flush or inset under any paper; a saved surface: inset floats solid paper", () => {
  assert.deepEqual(S.OPTIONS.surface, ["solid", "glass", "washi"])
  assert.deepEqual(S.OPTIONS.float, ["flush", "inset"])
  assert.deepEqual(S.PRESET_NAMES.filter(p => S.resolve({ preset: p }).float === "inset"), ["Islet"])
  const old = S.resolve({ preset: "Shōji", edits: { surface: "inset" } })
  assert.deepEqual([old.surface, old.float], ["solid", "inset"])
  const m = S.resolve({ monitors: { "DP-1": { surface: "inset" } } }, "DP-1")
  assert.deepEqual([m.surface, m.float], ["solid", "inset"])
  const d = S.withSetting({ preset: "Shōji" }, "surface", "inset")
  assert.deepEqual(d.edits, { float: "inset" })
  assert.equal(S.resolve(d).surface, "washi")
  assert.equal(Se.nameOf("float"), "Float")
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

test("sheets answer to bar cells and to Omarchy's panel ids", () => {
  assert.equal(Sh.forCell("clock"), "time")
  assert.equal(Sh.forCell("volume"), "sound")
  assert.equal(Sh.forCell("brightness"), "display")
  assert.equal(Sh.forCell("battery"), "power")
  assert.equal(Sh.forCell("media"), "")
  assert.equal(Sh.forOmarchyId("omarchy.audio"), "sound")
  assert.equal(Sh.forOmarchyId("omarchy.elsewhen"), "time")
  assert.equal(Sh.forOmarchyId("omarchy.bluetooth"), "bluetooth")
  assert.equal(Sh.forOmarchyId("omarchy.weather"), "")
  assert.equal(Sh.forCell("bluetooth"), "bluetooth")
  assert.equal(Sh.forOmarchyId("omarchy.monitor"), "display")
})

test("Tab walks the sheets that can open, wrapping", () => {
  assert.equal(Sh.step("time", 1), "sound")
  assert.equal(Sh.step("inbox", 1), "time")
  assert.equal(Sh.step("time", -1), "inbox")
  assert.equal(Sh.step("power", 1), "display")
  assert.equal(Sh.step("time", 1, ["time", "inbox"]), "inbox")
  assert.equal(Sh.step("nope", 1, ["sound"]), "sound")
  // No. 00 (Inkan) walks first when it can open, and is never a bar sheet.
  assert.equal(Sh.step("inbox", 1, ["all", "time", "inbox"]), "all")
  assert.equal(Sh.step("all", 1, ["all", "time", "inbox"]), "time")
  assert.equal(Sh.step("inbox", 1), "time")
  assert.equal(Sh.byKey("all").no, "00")
  assert.ok(Sh.SHEETS.every(x => x.key !== "all"))
})

test("togglePanelAt right N counts distinct Omarchy panels on the right", () => {
  const cells = ["media", "network", "volume", "brightness", "battery", "notif", "clock"]
  assert.equal(Sh.panelAt(cells, 1), "omarchy.network")
  assert.equal(Sh.panelAt(cells, 2), "omarchy.audio")
  assert.equal(Sh.panelAt(cells, 3), "omarchy.monitor")
  assert.equal(Sh.panelAt(cells, 4), "omarchy.power")
  assert.equal(Sh.panelAt(cells, 5), "omarchy.clock")
  assert.equal(Sh.panelAt(cells, 6), "")
  assert.equal(Sh.panelAt(cells, "0"), "")
})

test("sheet placement: centred under the clock, hanging left from the right zone", () => {
  const t = Sh.place("time", 760, 80, 500, 1600)
  assert.equal(t.x, 550)
  assert.deepEqual([t.tearX, t.tearWidth], [202, 96])
  const s = Sh.place("sound", 1380, 100, 430, 1600)
  assert.equal(s.x, 1090)
  const edge = Sh.place("sound", 1500, 90, 430, 1600)
  assert.equal(edge.x, 1162)
  assert.ok(edge.tearX + edge.tearWidth <= 430)
  assert.equal(Sh.place("time", 0, 40, 500, 1600).x, 8)
})

test("the year: day of year, ISO week, leap years, time left", () => {
  const d = new Date(2026, 9, 6, 21, 44)
  assert.equal(Tm.dayOfYear(d), 279)
  assert.equal(Tm.daysInYear(2026), 365)
  assert.equal(Tm.daysInYear(2028), 366)
  assert.equal(Tm.daysInYear(2100), 365)
  assert.equal(Tm.isoWeek(d), 41)
  assert.equal(Tm.isoWeek(new Date(2027, 0, 1)), 53)
  assert.equal(Tm.leftInDay(d), "2h 16m left in the day")
  assert.equal(Tm.leftInDay(new Date(2026, 9, 6, 23, 30)), "30m left in the day")
  assert.deepEqual(Tm.heading(d), { week: 41, title: "Tuesday", blurb: "Day 279 of 365 · 2h 16m left in the day" })
})

test("the day ribbon: fourteen days, today sixth, weeks ruled on Mondays", () => {
  const r = Tm.ribbon(new Date(2026, 9, 6, 21, 44), 0)
  assert.equal(r.days.length, 14)
  assert.equal(r.month, "October 2026")
  assert.equal(r.days[0].day, "01")
  assert.ok(r.days[5].today && !r.days[5].past)
  assert.ok(r.days[4].past && !r.days[6].past)
  assert.equal(r.days[5].letter, "T")
  assert.deepEqual(r.days.filter(x => x.weekStart).map(x => x.day), ["05", "12"])
  assert.deepEqual(r.days.filter(x => x.weekend).map(x => x.day), ["03", "04", "10", "11"])
  const back = Tm.ribbon(new Date(2026, 9, 6), -1)
  assert.equal(back.days[0].day, "24")
  assert.equal(back.month, "October 2026")
  assert.ok(back.days[12].today)
  assert.ok(!Tm.ribbon(new Date(2026, 9, 6), 2).days.some(x => x.today))
})

test("Elsewhen zones: parsed from Omarchy's bar layout, seeded when unset", () => {
  assert.deepEqual(Tm.parseZones("Tokyo|Asia/Tokyo, Europe/Lisbon, bad zone!"),
    [{ label: "Tokyo", id: "Asia/Tokyo" }, { label: "Lisbon", id: "Europe/Lisbon" }])
  const cfg = { layout: { right: [{ id: "omarchy.clock" }, { id: "omarchy.elsewhen", zones: "Home|America/New_York" }] } }
  assert.deepEqual(Tm.zonesFromBarConfig(cfg), [{ label: "Home", id: "America/New_York" }])
  assert.equal(Tm.zonesFromBarConfig({}).length, 3)
  assert.deepEqual(Tm.zonesFromBarConfig({ layout: { centerEnd: [{ id: "omarchy.elsewhen", zones: "Tokyo|Asia/Tokyo" }] } }), [{ label: "Tokyo", id: "Asia/Tokyo" }])
  assert.deepEqual(Tm.probeCommand(["Asia/Tokyo"]).slice(-1), ["Asia/Tokyo"])
})

test("Elsewhen rows tick from a date probe", () => {
  const probe = Tm.parseProbe("Asia/Tokyo|JST|+0900\nEurope/Lisbon|WEST|+0100\nAmerica/St_Johns|NDT|-0230\njunk")
  assert.deepEqual(probe["Asia/Tokyo"], { abbr: "JST", offset: 540 })
  assert.equal(probe["America/St_Johns"].offset, -150)
  const now = new Date(Date.UTC(2026, 9, 6, 21, 44))
  const tokyo = Tm.zoneRow({ label: "Tokyo", id: "Asia/Tokyo" }, probe["Asia/Tokyo"], now, 0, true)
  assert.deepEqual([tokyo.time, tokyo.date, tokyo.rel], ["06:44", "Wed 07 · JST", "+9"])
  const lis = Tm.zoneRow({ label: "Lisbon", id: "Europe/Lisbon" }, probe["Europe/Lisbon"], now, 0, false)
  assert.deepEqual([lis.time, lis.rel], ["10:44 PM", "+1"])
  assert.equal(Tm.relative(-150), "-2:30")
  assert.equal(Tm.relative(0), "±0")
  assert.equal(Tm.zoneRow({ label: "X", id: "X/Y" }, null, now, 0, true).ready, false)
})

test("sound: device names and what they are attached by", () => {
  const usb = { id: 41, name: "alsa_output.usb-Focusrite_Scarlett_2i2", description: "Scarlett 2i2 USB Analog Stereo",
    nickname: "Studio Monitors", props: { "device.bus": "usb", "device.product.name": "Focusrite 2i2", "audio.rate": 48000 } }
  assert.equal(So.label(usb), "Studio Monitors")
  assert.equal(So.detail(usb), "USB · Focusrite 2i2 · 48 kHz")
  const bt = { id: 52, name: "bluez_output.AC_80", description: "WH-1000XM5", props: { "api.bluez5.codec": "ldac" } }
  assert.equal(So.bus(bt), "Bluetooth")
  assert.equal(So.detail(bt), "Bluetooth · LDAC")
  assert.equal(So.label({ name: "x", description: "Built-in Audio Analog Stereo Output", props: {} }), "Analog Stereo")
  assert.equal(So.label({ name: "", props: {} }), "Unknown")
})

test("sound: outputs list the live one first and hide unavailable sinks", () => {
  const sinks = [
    { id: 52, name: "bluez_output.AC_80", description: "WH-1000XM5", props: {} },
    { id: 41, name: "usb_sink", description: "Studio Monitors", props: {} },
    { id: 60, name: "hdmi_sink", description: "HDMI", props: {} }]
  const rows = So.outputs(sinks, "usb_sink", { hdmi_sink: false })
  assert.deepEqual(rows.map(r => [r.id, r.current, r.note]), [[41, true, "Live"], [52, false, "Paired"]])
  assert.ok(!("node" in rows[0]))
})

test("sound: mixer rows per app, the speaker tuning left out", () => {
  const rows = So.streams([
    { id: 7, name: "spotify", props: { "application.name": "spotify" }, volume: 0.8, muted: false },
    { id: 8, name: "Firefox", description: "Firefox", props: {}, volume: 0.45, muted: true },
    { id: 9, name: "omarchy_speaker_tuning_out", props: {}, volume: 1 }])
  assert.deepEqual(rows.map(r => [r.label, r.percent, r.muted]), [["Spotify", 80, false], ["Firefox", 45, true]])
  assert.deepEqual(So.master(0.625, true), { percent: 63, level: 0.625, muted: true })
  assert.equal(So.inputNote({ description: "Shure MV7", props: {}, muted: false }), "Input · Shure MV7")
  assert.equal(So.inputNote({ description: "Shure MV7", props: {}, muted: true }), "Input · muted")
  assert.equal(So.inputNote(null), "No input")
  assert.equal(So.sheet(null, null, [], [], null).master, null)
})

test("network: nmcli terse lines, escaped colons and all", () => {
  assert.deepEqual(N.splitTerse("*:82:WPA2:5180:Cafe\\: Upstairs"), ["*", "82", "WPA2", "5180", "Cafe: Upstairs"])
  const rows = N.parseWifi([" :40:WPA2:2437:Kumo", "*:82:WPA2:5180:Kumo", " :91:WPA1 WPA2:2412:Neighbour",
    " :30::2462:Library", " :70:WPA2:5200:", ""].join("\n"))
  assert.deepEqual(rows.map(r => [r.ssid, r.signal, r.inUse]), [["Kumo", 82, true], ["Neighbour", 91, false], ["Library", 30, false]])
  assert.equal(rows[2].secure, false)
  assert.deepEqual(N.parseSaved("Kumo:802-11-wireless\nWired connection 1:802-3-ethernet\n"), ["Kumo"])
})

test("network: a pruned cache doesn't shrink the list to the network you're on", () => {
  const full = N.parseWifi("*:82:WPA2:5180:Kumo\n :91:WPA2:2412:Neighbour\n :30::2462:Library")
  const a = N.remember({}, full, 1000)
  assert.equal(a.rows.length, 3)
  // A minute later NetworkManager's cache holds only the joined network.
  const b = N.remember(a.seen, N.parseWifi("*:80:WPA2:5180:Kumo"), 61000)
  assert.deepEqual(b.rows.map(r => [r.ssid, r.signal, r.inUse]), [["Kumo", 80, true], ["Neighbour", 91, false], ["Library", 30, false]])
  // Only the latest reading says what is in use.
  const c = N.remember(b.seen, N.parseWifi("*:88:WPA2:2412:Neighbour"), 62000)
  assert.deepEqual(c.rows.filter(r => r.inUse).map(r => r.ssid), ["Neighbour"])
  // Gone for longer than KEEP_MS: dropped.
  const d = N.remember(c.seen, N.parseWifi("*:88:WPA2:2412:Neighbour"), 62000 + N.KEEP_MS + 1)
  assert.deepEqual(d.rows.map(r => r.ssid), ["Neighbour"])
})

test("network: bands, security and how a click connects", () => {
  assert.equal(N.band(2437), "2.4 GHz")
  assert.equal(N.band(5180), "5 GHz")
  assert.equal(N.band(6115), "6 GHz")
  assert.equal(N.securityName("WPA2 WPA3"), "WPA3")
  assert.equal(N.securityName("--"), "")
  assert.equal(N.connectHow({ saved: true, secure: true }), "up")
  assert.equal(N.connectHow({ saved: false, secure: false }), "open")
  assert.equal(N.connectHow({ saved: false, secure: true }), "ask")
})

test("network sheet: current connection and rows", () => {
  const wifi = N.parseWifi("*:82:WPA2:5180:Kumo\n :91:WPA2:2412:Neighbour\n :30::2462:Library")
  const s = N.sheet({ kind: "wifi", name: "Kumo", signal: 82 }, wifi, ["Kumo"], true)
  assert.deepEqual(s.current, { kind: "wifi", label: "Kumo", detail: "Wi-Fi · WPA2 · 5 GHz · 82%" })
  assert.deepEqual(s.networks.map(n => n.note), ["Connected", "", "Open"])
  const off = N.sheet({ kind: "disconnected", name: "Offline" }, [], [], false)
  assert.deepEqual([off.current.label, off.current.detail, off.radio, off.offline], ["Offline", "Wi-Fi is off", false, true])
  assert.equal(N.sheet({ kind: "ethernet" }, [], [], true).current.detail, "Ethernet · cable")
})

test("power: battery status, profiles and the blurb", () => {
  const kv = Pw.keyValues("percentage\t91%\nstate\tdischarging\nrate\t9.8W\nsize\t57Wh\ntime\t2h 41m\ncycles\t112\nthreshold\t80%\n")
  assert.equal(Pw.blurb(kv), "2h 41m left · drawing 9.8W")
  assert.equal(Pw.blurb({ percentage: "60%", state: "charging", time: "40m", rate: "30W" }), "40m to full · taking 30W")
  assert.equal(Pw.blurb({}), "No battery: plugged in for good.")
  assert.deepEqual(Pw.details(kv).map(r => r.name), ["State", "Capacity", "Cycles", "Charge limit"])
  const p = Pw.profiles("performance\t0\nbalanced\t1\npower-saver\t0\n")
  assert.deepEqual(p.map(x => [x.label, x.active]), [["Performance", false], ["Balanced", true], ["Power saver", false]])
  assert.equal(Pw.stateLabel("holding"), "Holding charge")
  const s = Pw.sheet(kv, p, { percent: 12, charging: false, needsYou: true }, null)
  assert.deepEqual([s.percent, s.low, s.profiles.length], [12, true, 3])
})

test("inbox: bodies, one copy per notification, and how long ago", () => {
  const raw = [
    JSON.stringify({ app: "Signal", summary: "Mika", body: "See you at 8", timestamp: 1000, originalId: 4 }),
    JSON.stringify({ app: "Signal", summary: "Mika", body: "See you at 8", timestamp: 1000, originalId: 4 })].join("\n")
  const n = St.notifications(raw)
  assert.equal(n.length, 1)
  assert.equal(n[0].body, "See you at 8")
  assert.equal(St.age(0, 30000), "now")
  assert.equal(St.age(0, 12 * 60000), "12m")
  assert.equal(St.age(0, 3 * 3600000), "3h")
  assert.equal(St.age(0, 50 * 3600000), "2d")
})

test("inbox: each letter carries the stem Omarchy files it under, to put one away", () => {
  const raw = [
    JSON.stringify({ app: "Signal", summary: "Mika", timestamp: 1000, originalId: 4 }),
    JSON.stringify({ app: "Mail", summary: "Rent", timestamp: 2000, originalId: 9 })].join("\n")
  const n = St.notifications(raw)
  assert.deepEqual(n.map(l => l.stem), ["2000-9", "1000-4"])
  assert.deepEqual(St.without(n, { "2000-9": true }).map(l => l.stem), ["1000-4"])
  assert.equal(St.without(n, null).length, 2)
})

test("inbox: the deck's live.json and history.json (rc, edge, dev), one letter per key", () => {
  const live = [{ key: "abc", originalId: 3, app: "Signal", summary: "Mika", body: "Here", urgency: 2, ts: 3 }]
  const history = [
    { key: "abc", originalId: 3, app: "Signal", summary: "Mika", body: "Here", ts: 3, closed_ts: 4 },
    { key: "old", originalId: 1, app: "Mail", summary: "Rent", ts: 1.5, closed_ts: 2 }]
  const quiet = { snoozes: {}, dnd: true, silencedSince: 0, codesBypassQuiet: false }
  const raw = ["#live", JSON.stringify(live), "#history", JSON.stringify(history), JSON.stringify(quiet), "[]"].join("\n")
  const n = St.notifications(raw)
  assert.deepEqual(n.map(l => [l.stem, l.key, l.live, l.timestamp]), [["abc", "abc", true, 3000], ["old", "old", false, 1500]])
  assert.equal(n[0].urgent, true)
  assert.equal(n[0].glyph, "信")
  assert.deepEqual(St.stillHeld({ old: true, gone: true }, n), { old: true })
  assert.deepEqual(St.stillHeld(null, n), {})
})

test("inbox: stable files under #live and #history markers", () => {
  const one = JSON.stringify({ app: "Mail", summary: "Rent", timestamp: 2000, originalId: 9 })
  const n = St.notifications(["#live", one, "#history", one].join("\n"))
  assert.deepEqual(n.map(l => [l.stem, l.key, l.live]), [["2000-9", "", true]])
})

test("spaces carry each window's app and address for the scroll's map", () => {
  const area = { x: 0, y: 0, width: 100, height: 100 }
  const l = W.layoutOf([{ at: [0, 0], size: [50, 100], name: "Firefox", address: "0xabc" }], area)
  assert.equal(l[0].name, "Firefox")
  assert.equal(l[0].address, "0xabc")
})

test("words for the scroll: ordinals, counts, and the day across midnight", () => {
  assert.equal(Tm.ordinal(6), "the sixth")
  assert.equal(Tm.ordinal(31), "the thirty-first")
  assert.equal(Tm.counted(3, "letter", "letters"), "Three letters")
  assert.equal(Tm.counted(1, "letter", "letters"), "One letter")
  assert.equal(Tm.counted(0, "letter", "letters"), "No letters")
  assert.equal(Tm.counted(14, "space", "spaces"), "14 spaces")
  const now = new Date(Date.UTC(2026, 9, 6, 21, 44))
  assert.equal(Tm.dayAcross(now, 540, 0), "tomorrow")
  assert.equal(Tm.dayAcross(now, -600, 120), "")
  assert.equal(Tm.dayAcross(new Date(Date.UTC(2026, 9, 6, 2, 0)), -420, 0), "yesterday")
  const r = Tm.ribbon(new Date(2026, 9, 6), 0, 18)
  assert.equal(r.days.length, 18)
  assert.deepEqual([r.before, r.current, r.after], ["September", "October", "November"])
})

test("settings: six cards hold every one of the twenty-one settings once", () => {
  const beside = ["sealGlyph", "typeSize", "overview", "season", "numerals", "grain", "hours"]
  const keys = Se.CARDS.flatMap(c => c.rows.map(r => r.key)).filter(k => beside.indexOf(k) < 0)
  assert.deepEqual([...keys].sort(), [...S.KEYS].sort())
  assert.equal(Se.CARDS.length, 6)
  assert.deepEqual(Object.keys(Se.PRESET_BLURBS).sort(), [...S.PRESET_NAMES].sort())
  // Typesetting, Presets, Parts, Colour, Screens · Sheets, Overview · Kaze, Boot, Motion, Keys · Profile, About, Credits
  assert.equal(Se.RAIL.flatMap(g => g.pages).length, 14)
})

test("settings: options, the lit one, and the seal glyph's typed case", () => {
  assert.deepEqual(Se.optionsFor("height", S.OPTIONS), ["32", "36", "40", "44"])
  assert.deepEqual(Se.optionsFor("sealGlyph", S.OPTIONS), ["鑑", "漢", "観", "寛", "…"])
  assert.deepEqual(Se.optionsFor("motion", S.OPTIONS), S.MOTIONS)
  assert.deepEqual(Se.optionsFor("season", S.OPTIONS), ["off", "kanji", "english"])
  assert.deepEqual(Se.optionsFor("grain", S.OPTIONS), ["smooth", "fine", "toothy"])
  assert.deepEqual(Se.optionsFor("hours", S.OPTIONS), ["auto", "24h", "12h"])
  assert.equal(S.resolve({}).hours, "auto")
  assert.equal(S.resolve({ hours: "12h" }).hours, "12h")
  assert.equal(S.resolve({ hours: "13h" }).hours, "auto")
  assert.equal(S.withSetting({}, "hours", "24h").hours, "24h")
  assert.equal(Se.selected("numerals", S.resolve({ numerals: "kanji" }), "鑑"), "kanji")
  assert.equal(Se.MOTION_ROWS.length, 13)  // the five Iai beats, then the eight moves
  assert.equal(Se.nameOf("clockAt"), "Clock position")
  assert.equal(Se.nameOf("bluetooth"), "Bluetooth")
  assert.ok(S.KEYS.every((k) => Se.nameOf(k) !== k))
  const st = S.resolve({})
  assert.equal(Se.selected("height", st, "鑑"), "40")
  assert.equal(Se.selected("sealGlyph", st, "観"), "観")
  assert.equal(Se.selected("sealGlyph", st, "侍"), "…")
  assert.equal(Se.selected("sealGlyph", st, "鷹"), "…")
})

test("settings: counting what the draft changes", () => {
  const saved = S.normalize({})
  assert.equal(Se.changes(saved, saved, S.resolve), 0)
  const two = S.withSetting(S.withSetting(saved, "clock", "inline"), "status", "glyphs")
  assert.equal(Se.changes(saved, two, S.resolve), 2)
  // A preset switch counts every setting it moves.
  assert.equal(Se.changes(saved, S.withPreset(saved, "Islet"), S.resolve), 8)
  const glyph = S.normalize({ sealGlyph: "侍" })
  assert.equal(Se.changes(saved, glyph, S.resolve), 1)
  assert.equal(Se.changes(saved, S.withMonitorSetting(saved, "DP-2", "height", 32), S.resolve), 1)
  assert.equal(Se.status(0), "Saved · every change is kept as you make it")
  assert.equal(Se.status(2), "Saved · 2 changes · Ctrl+Z undoes")
  assert.equal(Se.presetLine(two), "Preset · Kamon + edits")
  assert.equal(Se.presetLine(saved), "Preset · Kamon")
})

test("settings: search finds rows by name, detail and option", () => {
  const row = Se.CARDS[0].rows[1]
  assert.ok(Se.matches(row, "", S.OPTIONS))
  assert.ok(Se.matches(row, "WORK", S.OPTIONS))
  assert.ok(Se.matches(row, "kanji", S.OPTIONS))
  assert.ok(!Se.matches(row, "battery", S.OPTIONS))
  assert.ok(Se.pageMatches({ key: "motion", label: "Motion", jp: "動" }, "mot"))
})

test("per-monitor settings: set, and dropped when they match", () => {
  const d = S.withMonitorSetting(S.normalize({}), "DP-2", "height", "32")
  assert.deepEqual(d.monitors, { "DP-2": { height: 32 } })
  assert.equal(S.resolve(d, "DP-2").height, 32)
  assert.equal(S.resolve(d, "eDP-1").height, 40)
  assert.deepEqual(S.withMonitorSetting(d, "DP-2", "height", 40).monitors, {})
  assert.equal(S.withMonitorSetting(d, "DP-2", "height", 33), null)
  assert.equal(S.withMonitorSetting(d, "", "height", 32), null)
})

test("hosting: Omarchy's default layout, minus what Hanko draws itself", () => {
  const cfg = { layout: {
    left: [{ id: "omarchy.menu" }, { id: "omarchy.workspaces" }],
    center: [{ id: "omarchy.indicators" }, { id: "omarchy.elsewhen" }, { id: "omarchy.clock" },
             { id: "omarchy.keyboard-layout" }, { id: "omarchy.weather", units: "C" }, { id: "omarchy.system-update" }],
    right: [{ id: "omarchy.tray" }, { id: "omarchy.agents" }, { id: "omarchy.bluetooth" }, { id: "omarchy.network" },
            { id: "omarchy.audio" }, { id: "omarchy.monitor" }, { id: "omarchy.power" }, { id: "daz.toggl" }, "daz.toggl"] } }
  const all = id => id !== "omarchy.agents"
  const h = H.hosted(cfg, all, () => false)
  assert.deepEqual(h.map(x => x.id), ["omarchy.weather", "omarchy.system-update", "daz.toggl"])
  assert.equal(h[0].settings.units, "C")
  const many = H.hosted(cfg, all, id => id === "daz.toggl")
  assert.deepEqual(many.slice(-2).map(x => x.key), ["daz.toggl", "daz.toggl#1"])
  assert.deepEqual(H.own(cfg), { tray: true, indicators: true, keyboard: true, mic: false })
  assert.deepEqual(H.own({}), { tray: true, indicators: true, keyboard: true, mic: false })
  assert.deepEqual(H.own({ layout: { right: [{ id: "omarchy.microphone" }] } }), { tray: false, indicators: false, keyboard: false, mic: true })
  // centerBegin and centerEnd count, in reading order; the tray drawer doesn't.
  const centred = { layout: { centerBegin: [{ id: "omarchy.indicators" }], center: [{ id: "omarchy.clock" }],
    centerEnd: [{ id: "omarchy.weather" }], right: [{ id: "omarchy.tray" }], tray: [{ id: "omarchy.microphone" }] } }
  assert.deepEqual(H.own(centred), { tray: true, indicators: true, keyboard: false, mic: false })
  assert.deepEqual(H.entries(centred).map(e => e.id), ["omarchy.indicators", "omarchy.clock", "omarchy.weather", "omarchy.tray"])
  assert.deepEqual(H.hosted(centred, all, () => false).map(h => h.id), ["omarchy.weather"])
  assert.equal(H.idOfCell(H.cell("omarchy.weather")), "omarchy.weather")
  assert.equal(H.idOfCell("volume"), "")
})

test("togglePanelAt counts hosted widgets in their place", () => {
  const cells = ["network", "volume", "hosted:omarchy.weather", "battery", "notif"]
  assert.equal(Sh.panelAt(cells, 3), "omarchy.weather")
  assert.equal(Sh.panelAt(cells, 4), "omarchy.power")
})

test("own marks: only the indicators that are on, red only for now", () => {
  assert.deepEqual(X.indicators({}), [])
  const all = X.indicators({ recording: true, dictation: "recording", reminders: 2, awake: true, night: true })
  assert.deepEqual(all.map(i => i.glyph), ["写", "言", "予", "目", "月"])
  assert.deepEqual(all.map(i => i.red), [true, true, false, false, false])
  assert.equal(all[2].count, 2)
  assert.equal(X.indicators({ dictation: "transcribing" })[0].red, false)
  assert.equal(X.indicators({ dictation: "transcribing" })[0].icon, "\u{f051f}")
  const every = X.indicators({ night: true, dnd: true }, true)
  assert.deepEqual(every.map(i => i.key), ["recording", "dictation", "reminder", "awake", "night", "dnd"])
  assert.deepEqual(every.filter(i => i.on).map(i => i.key), ["night", "dnd"])
  assert.equal(every[4].icon, "\u{f050e}")
  assert.equal(every.find(i => i.key === "recording").red, false)
  assert.deepEqual(X.moduleJson('warm up\n{"count":1,"tooltip":"tea"}'), { count: 1, tooltip: "tea" })
  assert.deepEqual(X.moduleJson("plain"), { text: "plain" })
})

test("keyboard layout from hyprctl devices", () => {
  const json = JSON.stringify({ keyboards: [
    { name: "power-button", layout: "us", active_layout_index: 0 },
    { name: "at-translated-set-2-keyboard", main: true, layout: "us,de", active_layout_index: 1, active_keymap: "German" }] })
  assert.deepEqual(X.keyboard(json), { label: "DE", count: 2, keyboard: "at-translated-set-2-keyboard", keymap: "German" })
  assert.equal(X.keyboard(JSON.stringify({ keyboards: [{ name: "kb", layout: "us" }] })).count, 1)
  assert.equal(X.keyboard("not json"), null)
  assert.equal(X.keyboard(JSON.stringify({ keyboards: [] })), null)
})

test("tray rows: titles, symbolic icons, a letter to fall back on", () => {
  const t = X.tray([{ id: "nm-applet", title: "Network", icon: "image://icon/nm-signal-75-symbolic" },
                    { id: "steam", tooltipTitle: "Steam", icon: "" }, null])
  assert.deepEqual(t.map(x => [x.id, x.letter, x.symbolic]), [["nm-applet", "N", true], ["steam", "S", false]])
})

test("tray menu labels: access-key underscores dropped, doubled ones kept", () => {
  assert.equal(X.menuText("_Quit"), "Quit")
  assert.equal(X.menuText("Show __main__ win_dow"), "Show _main_ window")
  assert.equal(X.menuText(undefined), "")
})

test("tray: Ayatana items (Steam) are found from the watcher's list, since they can't be activated", () => {
  const out = 'as 3 ":1.127/org/ayatana/NotificationItem/steam" ":1.191/org/chromium/StatusNotifierItem/1" ":1.9/org/ayatana/NotificationItem/nm_applet"'
  assert.deepEqual(X.menuOnlyIds(out), ["steam", "nm_applet"])
  assert.deepEqual(X.menuOnlyIds("as 0"), [])
  assert.deepEqual(X.menuOnlyIds(undefined), [])
  assert.equal(X.pathId("nm-applet"), "nm_applet")
  assert.equal(X.pathId("steam"), "steam")
})

test("display: monitors from hyprctl, the focused one first", () => {
  const json = JSON.stringify([
    { name: "DP-2", model: "LG ULTRAGEAR", width: 2560, height: 1440, refreshRate: 143.97, scale: 1.25, focused: false },
    { name: "eDP-1", description: "BOE 0x0BCA", width: 2880, height: 1800, refreshRate: 120, scale: 1.75, focused: true },
    { name: "HDMI-A-1", model: "TV", disabled: true }])
  const m = D.monitors(json)
  assert.deepEqual(m.map(x => x.name), ["eDP-1", "DP-2", "HDMI-A-1"])
  assert.equal(m[0].label, "Built-in · eDP-1")
  assert.equal(m[0].detail, "2880×1800 · 120 Hz · ×1.75")
  assert.equal(m[1].label, "LG ULTRAGEAR · DP-2")
  assert.equal(m[1].detail, "2560×1440 · 144 Hz · ×1.25")
  assert.equal(m[2].detail, "Switched off in Hyprland")
  assert.deepEqual(D.monitors("nope"), [])
})

test("display: brightness reading, the monitor it speaks for, the panel", () => {
  assert.equal(D.brightness("70"), 70)
  assert.equal(D.brightness("70%\n"), 70)
  assert.equal(D.brightness(""), -1)
  const m = D.monitors([{ name: "eDP-1", focused: true, width: 1, height: 1 }, { name: "DP-2", width: 1, height: 1 },
                        { name: "HDMI-A-1", disabled: true }])
  assert.equal(D.target(m, ""), "eDP-1")
  assert.equal(D.target(m, "DP-2"), "DP-2")
  assert.equal(D.target(m, "HDMI-A-1"), "eDP-1")
  assert.equal(D.target([], ""), "")
  const s = D.sheet(m, "DP-2", 40, true)
  assert.deepEqual([s.title, s.target, s.brightness.level, s.night], ["DP-2", "DP-2", 0.4, true])
  assert.deepEqual(s.monitors.map(x => x.current), [false, true, false])
  assert.equal(D.sheet(m, "", -1, false).brightness, null)
  assert.equal(D.sheet(m, "", 50, false).title, "Built-in")
})

test("bluetooth: devices into connected, known and found, nameless ones out", () => {
  const devs = [
    { address: "AC:80:0A:11:22:33", name: "WH-1000XM5", icon: "audio-headset", connected: true, paired: true, battery: 0.8 },
    { address: "11:22:33:44:55:66", name: "MX Keys", icon: "input-keyboard", connected: false, paired: true, battery: -1 },
    { address: "77:88:99:AA:BB:CC", name: "77:88:99:AA:BB:CC", icon: "", connected: false, paired: false, battery: -1 },
    { address: "DD:EE:FF:00:11:22", name: "Pixel 9", icon: "phone", connected: false, paired: false, battery: -1, pairing: true }]
  const l = B.lists(devs)
  assert.deepEqual(l.connected.map(r => [r.name, r.detail, r.note]), [["WH-1000XM5", "Headphones · 80%", "Connected"]])
  assert.deepEqual(l.known.map(r => r.name), ["MX Keys"])
  assert.deepEqual(l.found.map(r => [r.name, r.note]), [["Pixel 9", "Pairing"]])
  assert.equal(B.action(l.connected[0]), "disconnect")
  assert.equal(B.action(l.known[0]), "connect")
  assert.equal(B.action(l.found[0]), "pair")
  assert.ok(!B.human("0000110b-0000-1000-8000-00805f9b34fb"))
})

test("bluetooth: the bar cell and the sheet", () => {
  const devs = [{ address: "A", name: "WH-1000XM5", icon: "audio-headset", connected: true, paired: true, battery: 0.8 },
                { address: "B", name: "MX Keys", icon: "input-keyboard", connected: true, paired: true, battery: -1 }]
  assert.equal(B.cell(false, true, devs), null)
  const c = B.cell(true, true, devs)
  assert.deepEqual([c.name, c.connected, c.level, c.count, c.needsYou], ["MX Keys +1", 2, -1, "02", false])
  assert.deepEqual(c.devices.map(d => [d.mark, d.level]), [["鍵", -1], ["耳", 0.8]])
  const low = B.cell(true, true, [{ ...devs[0], battery: 0.12 }])
  assert.deepEqual([low.needsYou, low.devices[0].low], [true, true])
  assert.equal(B.cell(true, false, devs).devices.length, 0)
  assert.equal(B.mark("input-mouse"), "鼠")
  assert.equal(B.mark(""), "器")
  assert.equal(B.cell(true, true, devs.slice(0, 1)).level, 0.8)
  assert.equal(B.cell(true, false, devs).name, "Off")
  assert.equal(B.cell(true, true, []).name, "On")
  assert.deepEqual([B.sheet(true, true, false, devs).title, B.sheet(true, true, false, devs).blurb], ["MX Keys", "2 devices connected."])
  assert.equal(B.sheet(false, false, false, []).title, "No adapter")
  assert.equal(B.sheet(true, false, false, devs).blurb, "Turn it on to see your devices.")
  assert.equal(B.sheet(true, true, true, []).blurb, "Looking for devices nearby…")
})

test("motion sits outside the settings: paper or still, kept through presets and resets", () => {
  assert.equal(S.resolve({}).motion, "paper")
  assert.equal(S.resolve({ motion: "wobbly" }).motion, "paper")
  const d = S.withSetting({ preset: "Quiet" }, "motion", "still")
  assert.equal(d.motion, "still")
  assert.deepEqual(d.edits, {})
  assert.equal(S.withSetting({}, "motion", "fast"), null)
  assert.equal(S.withPreset(d, "Quiet").motion, "still")
  assert.equal(S.shuffled(d, () => 0.5).motion, "still")
  assert.equal(S.withSetting({}, "sealGlyph", "侍たち").sealGlyph, "侍")
  assert.equal(S.combinations(), 24159191040)
})

test("type size sits beside motion: small, regular or large, kept through presets and shuffles", () => {
  assert.equal(S.resolve({}).typeSize, "regular")
  assert.equal(S.resolve({ typeSize: "huge" }).typeSize, "regular")
  const d = S.withSetting({ preset: "Islet" }, "typeSize", "large")
  assert.equal(d.typeSize, "large")
  assert.deepEqual(d.edits, {})
  assert.equal(S.withSetting({}, "typeSize", "tiny"), null)
  assert.equal(S.withPreset(d, "Quiet").typeSize, "large")
  assert.equal(S.shuffled(d, () => 0.5).typeSize, "large")
  assert.deepEqual(S.TYPE_SIZES.map((t) => S.TYPE_SCALE[t]), [0.9, 1, 1.15])
  assert.deepEqual(Se.optionsFor("typeSize", S.OPTIONS), S.TYPE_SIZES)
  assert.equal(Se.changes({}, { typeSize: "small" }, S.resolve), 1)
})

test("hidden parts: shown or hidden per part, kept through presets, shuffles and resets", () => {
  assert.deepEqual(S.resolve({}).hidden, [])
  assert.deepEqual(S.normalize({ hidden: ["tray", " tray ", "", null, "mic"] }).hidden, ["mic", "tray"])
  const w = []
  assert.deepEqual(S.normalize({ hidden: ["volume", "nonsense"] }, w).hidden, ["volume"])
  assert.deepEqual(w, ["ignored unknown part nonsense in hidden"])
  assert.deepEqual(S.normalize({ hidden: "tray" }).hidden, [])
  const d = S.withSetting({}, "show:hosted:omarchy.weather", "hidden")
  assert.deepEqual(d.hidden, ["hosted:omarchy.weather"])
  assert.deepEqual(d.edits, {})
  assert.equal(S.shows(S.resolve(d), "hosted:omarchy.weather"), false)
  assert.equal(S.shows(S.resolve(d), "volume"), true)
  assert.deepEqual(S.withSetting(d, "show:hosted:omarchy.weather", "shown").hidden, [])
  assert.equal(S.withSetting({}, "show:tray", "maybe"), null)
  assert.equal(S.withSetting({}, "show:", "hidden"), null)
  assert.equal(S.withSetting({}, "show:nonsense", "hidden"), null)
  assert.equal(S.withSetting({}, "show:tray:", "hidden"), null)
  assert.deepEqual(S.withSetting({}, "show:tray:nm-applet", "hidden").hidden, ["tray:nm-applet"])
  assert.deepEqual(S.withPreset(d, "Quiet").hidden, d.hidden)
  assert.deepEqual(S.shuffled(d, () => 0.5).hidden, d.hidden)
  assert.equal(S.shows({}, "seal"), true)
})

test("hidden parts: a part its setting leaves out reads hidden, and showing it sets it back", () => {
  // Quiet has no window title and no Bluetooth cell.
  const q = S.resolve({ preset: "Quiet" })
  assert.equal(S.shows(q, "title"), false)
  assert.equal(S.shows(q, "bluetooth"), false)
  const t = S.withSetting({ preset: "Quiet" }, "show:title", "shown")
  assert.equal(S.resolve(t).title, "cell")
  assert.equal(S.withSetting({ preset: "Quiet" }, "show:bluetooth", "shown").edits.bluetooth, "device")
  // The preset's own way comes back when it draws the part.
  const s = S.withSetting({ preset: "Quiet", edits: { seal: "none" } }, "show:seal", "shown")
  assert.equal(S.resolve(s).seal, "stamp")
  assert.deepEqual(s.edits, {})
  // Picking a way to draw a hidden part shows it again.
  const h = S.withSetting({}, "show:seal", "hidden")
  assert.deepEqual(S.withSetting(h, "seal", "stamp").hidden, [])
  assert.deepEqual(S.withSetting(h, "seal", "none").hidden, ["seal"])
})

test("the Widgets page lists every part, and the marks, tray apps and widgets you have", () => {
  const keys = cards => cards.flatMap(c => c.rows.map(r => r.key))
  const base = keys(Se.visibilityCards({}))
  for (const p of ["seal", "spaces", "title", "clock", "media", "network", "bluetooth", "volume", "brightness", "battery", "notif", "edge"])
    assert.ok(base.includes("show:" + p), p)
  assert.ok(!base.includes("show:tray"))
  const all = Se.visibilityCards({
    own: { indicators: true, keyboard: true, mic: false, tray: true },
    indicators: X.INDICATORS,
    tray: [{ id: "nm-applet", title: "Network" }],
    hosted: [{ id: "omarchy.weather", name: "Weather", firstParty: true }, { id: "me.pomodoro", firstParty: false }]
  })
  const k = keys(all)
  assert.ok(k.includes("show:indicator:night") && k.includes("show:keyboard") && k.includes("show:tray"))
  assert.ok(!k.includes("show:mic"))
  assert.ok(k.includes("show:tray:nm-applet") && k.includes("show:hosted:me.pomodoro"))
  const third = all.flatMap(c => c.rows).find(r => r.key === "show:hosted:me.pomodoro")
  assert.equal(third.name, "Pomodoro")
  assert.match(third.detail, /^Third-party/)
  assert.deepEqual(Se.optionsFor("show:tray", S.OPTIONS), S.SHOW_OPTIONS)
  assert.equal(Se.prettyId("omarchy.system-updates"), "System updates")
  // A hidden part counts as a change.
  assert.equal(Se.changes(S.normalize({}), S.withSetting({}, "show:mic", "hidden"), S.resolve), 1)
})

const Wx = load("core/Weather.js", ["location", "area", "url"])

test("weather: the place file, the detected area and the request", () => {
  assert.deepEqual(Wx.location('{"name":" Tokyo ","latitude":"35.68","longitude":139.69}'), { name: "Tokyo", latitude: 35.68, longitude: 139.69 })
  assert.deepEqual(Wx.location("nope"), { name: "", latitude: null, longitude: null })
  assert.equal(Wx.location('{"name":"Lisbon"}').latitude, null)
  const a = Wx.area(JSON.stringify({ nearest_area: [{ areaName: [{ value: "Pune" }], country: [{ value: "India" }], latitude: "18.5", longitude: "73.8" }] }))
  assert.deepEqual(a, { name: "Pune", country: "India", latitude: 18.5, longitude: 73.8 })
  assert.equal(Wx.area("{}"), null)
  assert.ok(Wx.url(35.68, 139.69).includes("latitude=35.68") && Wx.url(1, 2).includes("current=wind_speed_10m,wind_direction_10m"))
})


test("almanac: Tuesday 6 October 2026", () => {
  assert.equal(Al.SEKKI.length, 24)
  assert.equal(Al.KO.length, 72)
  const a = Al.almanac(new Date(2026, 9, 6, 14, 30))
  assert.equal(a.month, "October")
  assert.equal(a.cells.length, 35)
  assert.equal(a.cells[3].label, "01")          // 1 October 2026 is a Thursday
  assert.ok(a.cells.find(c => c.today).day === 6)
  assert.equal(a.sekki.name, "Shūbun")
  assert.equal(a.title, "Shūbun, <i>autumn</i>")
  assert.equal(a.ko.no, 48)
  assert.equal(a.caption, "Kō 48 · farmers drain their fields")
  assert.equal(a.next.name, "Kanro")
  assert.equal(a.next.day, 8)
  assert.ok(a.cells.find(c => c.term).day === 8)
  assert.equal(a.day, 279)
  assert.equal(a.days, 365)
  // Early January belongs to last December's term and microseason.
  const j = Al.almanac(new Date(2027, 0, 2))
  assert.equal(j.sekki.name, "Tōji")
  assert.equal(j.ko.no, 66)
  assert.equal(j.sekki.season, "winter")
  assert.equal(Al.almanac(new Date(2026, 1, 4)).ko.no, 1)
  // The moon: a waning crescent, new in a few days.
  const m = Al.moon(new Date(2026, 9, 6, 14, 30))
  assert.equal(m.waxing, false)
  assert.ok(m.percent > 10 && m.percent < 35)
  assert.match(m.next, /^New · 1[01]th$/)
  assert.ok(Al.moon(new Date(Date.UTC(2000, 0, 6, 18, 14))).percent === 0)
})

test("themes: Omarchy's list, the user's copies first", () => {
  const raw = ["kanagawa\t#1f1f28\t#dcd7ba\t#c34043\tdark", "nord\t#2e3440\t#d8dee9\t#bf616a\t", "rose-pine\t#faf4ed\t#575279\t#b4637a\tlight",
    "kanagawa\t#000000\t#ffffff\t#ff0000\t", "broken\tnope\t#fff\t\t", "tokyo-night\t#1a1b26\t#a9b1d6\t\t"].join("\n")
  const list = Th.themes(raw)
  assert.deepEqual(list.map(t => t.slug), ["kanagawa", "nord", "rose-pine", "tokyo-night"])
  assert.equal(list[0].bg, "#1f1f28")          // the user's copy, listed first, wins
  assert.equal(list[2].light, true)
  assert.equal(list[2].name, "Rose Pine")
  assert.equal(list[3].red, "#a9b1d6")
  assert.equal(Th.themeName("tokyo-night"), "Tokyo Night")
})


const Pr = load("core/Profile.js", ["PROBE", "BLOCKS", "parseMachine", "fv", "uptime", "edition", "combination", "grouped", "vitals", "specs", "PROJECTS", "PROOFREADERS", "facts", "LINEAGE", "CREDIT_GROUPS", "creditsIn"])

test("profile: the machine probe's lines become facts", () => {
  const m = Pr.parseMachine("user=ayush\nhost=kumo\nkernel=6.18\nuptime=187420.5\ntheme=Unknown\npackages=1184\nnoise\nbogus=1")
  assert.equal(m.user, "ayush")
  assert.equal(m.uptime, 187420.5)
  assert.equal(m.packages, 1184)
  assert.equal(m.theme, "")
  assert.equal(m.bogus, undefined)
  assert.equal(Pr.parseMachine("").host, "")
  assert.ok(Pr.PROBE.includes("omarchy-theme-current") && Pr.PROBE.includes("/proc/uptime"))
})

test("profile: uptime, dashes, edition numbers", () => {
  assert.equal(Pr.uptime(187420), "2 d 4 h")
  assert.equal(Pr.uptime(3 * 3600 + 12 * 60), "3 h 12 m")
  assert.equal(Pr.uptime(20), "1 m")
  assert.equal(Pr.uptime(0), "—")
  assert.equal(Pr.fv(""), "—")
  assert.equal(Pr.fv("Kumo"), "Kumo")
  assert.match(Pr.edition("abc"), /^\d{4}$/)
  assert.equal(Pr.edition("abc"), Pr.edition("abc"))
  assert.notEqual(Pr.edition("abc"), Pr.edition("abd"))
  assert.equal(Pr.grouped(5971968), "5,971,968")
})

test("profile: which of the combinations a bar is, first to last", () => {
  const first = {}, last = {}
  for (const k of S.KEYS) { first[k] = S.OPTIONS[k][0]; last[k] = S.OPTIONS[k][S.OPTIONS[k].length - 1] }
  assert.equal(Pr.combination(first, S.OPTIONS, S.KEYS), 1)
  assert.equal(Pr.combination(last, S.OPTIONS, S.KEYS), S.combinations())
  const a = Pr.combination(S.resolve({}), S.OPTIONS, S.KEYS), b = Pr.combination(S.resolve({ preset: "Quiet" }), S.OPTIONS, S.KEYS)
  assert.notEqual(a, b)
})

test("profile: live readings and the small print", () => {
  const v = Pr.vitals({ spaces: [{ id: 1, count: 2 }, { id: 3, active: true, count: 1 }], volume: { percent: 62, muted: false },
                        network: { kind: "wifi", name: "Kumo", bars: 3 }, notifications: [{ app: "Signal" }] })
  assert.deepEqual(v.map(x => x.key), ["spaces", "sound", "network", "inbox"])
  assert.equal(v[0].big, "02")
  assert.equal(v[0].sub, "3 windows · on 03")
  assert.equal(v[2].sub, "Wi-Fi · 3 of 4 bars")
  assert.equal(v[3].sub, "Signal last")
  assert.equal(Pr.vitals({}).length, 1)
  assert.equal(v[1].level, 0.62)
  assert.equal(v[2].level, 0.75)
  assert.equal(v[0].level, -1)
  const rows = Pr.specs(S.resolve({ edits: { clock: "mono" } }), S.normalize({ edits: { clock: "mono" } }), { theme: "Kanagawa", hyprland: "v0.52.1", uptime: 60 }, "0.1.0", S.OPTIONS, S.KEYS, S.combinations())
  assert.deepEqual(rows[0], ["Preset", "Kamon + 1 edit"])
  assert.match(rows[1][1], /^No\. [\d,]+ of [\d,]+$/)
  assert.deepEqual(rows[3], ["Compositor", "Hyprland 0.52.1"])
  assert.deepEqual(rows[5], ["Uptime", "1 m"])
})

test("about and credits: every line is whole, links are https", () => {
  for (const p of Pr.PROJECTS) { assert.ok(p.name && p.role); assert.ok(p.url === "" || p.url.startsWith("https://")) }
  for (const p of Pr.PROOFREADERS) assert.ok(p.url.startsWith("https://github.com/"))
  // Every credit sits in one of the groups, and the groups hold them all.
  const keys = Pr.CREDIT_GROUPS.map(g => g.key)
  for (const p of Pr.PROJECTS) assert.ok(keys.includes(p.group), p.name)
  assert.equal(keys.reduce((n, k) => n + Pr.creditsIn(k).length, 0), Pr.PROJECTS.length)
  const f = Pr.facts("0.1.0", 10, "22", 6)
  assert.equal(f.length, 8)
  assert.equal(f[f.length - 1][2], "https://github.com/AyushKr2003/hanko")
  assert.equal(Pr.LINEAGE.length, 3)
  assert.ok(Se.RAIL.some(g => g.pages.some(p => p.key === "profile")))
})

const Ov = load("core/Overview.js", ["ROWS", "COLUMNS", "group", "pages", "rowsShown", "fit", "step", "jump", "wheel", "visibleWindows", "summary", "KEYS",
  "PER_DESKTOP", "deskOf", "deskList", "deskDots", "newWsId", "slots", "packRows", "lay", "cycle", "LAYOUTS"])

test("overview: the group of ten the live workspace is in", () => {
  assert.deepEqual(Ov.group(3, 2, 5), [1, 10])
  assert.deepEqual(Ov.group(10, 2, 5), [1, 10])
  assert.deepEqual(Ov.group(11, 2, 5), [11, 20])
})

test("overview: pages in grid order, empty rows folded", () => {
  const spaces = [{ id: 1, count: 2, all: [{ x: 0 }] }, { id: 3, count: 1, urgent: true }, { id: 99, count: 1 }]
  const p = Ov.pages(spaces, 3, 2, 5, true)
  assert.equal(p.length, 5)
  assert.deepEqual(p.map(x => x.id), [1, 2, 3, 4, 5])
  assert.equal(p[2].active, true)
  assert.equal(p[2].urgent, true)
  assert.equal(p[0].windows.length, 1)
  assert.equal(Ov.rowsShown(p), 1)
  assert.equal(Ov.pages(spaces, 3, 2, 5, false).length, 10)
  // The live workspace keeps its row even when it is empty.
  const q = Ov.pages(spaces, 7, 2, 5, true)
  assert.deepEqual(q.map(x => x.row), [0, 0, 0, 0, 0, 1, 1, 1, 1, 1])
  assert.equal(Ov.pages([], 14, 2, 5, true)[0].id, 11)
})

test("overview: pages fit the room at the monitor's aspect", () => {
  const f = Ov.fit(2, 5, 1488, 600, 0.5625, 22, 30, 300)
  assert.ok(f.width <= 1488 + 0.01 && f.height <= 600 + 0.01)
  assert.ok(Math.abs(f.screenH / f.pageW - 0.5625) < 1e-9)
  assert.equal(f.pageH, f.screenH + 30)
  // A wide room is bound by height: one row of pages gets taller ones.
  assert.ok(Ov.fit(1, 5, 3000, 600, 0.5625, 22, 30, 300).screenH > Ov.fit(2, 5, 3000, 600, 0.5625, 22, 30, 300).screenH)
})

test("overview: arrows, digits and the wheel stay inside the group", () => {
  assert.equal(Ov.step(3, "right", 2, 5), 4)
  assert.equal(Ov.step(5, "right", 2, 5), 1)
  assert.equal(Ov.step(1, "left", 2, 5), 5)
  assert.equal(Ov.step(3, "down", 2, 5), 8)
  assert.equal(Ov.step(8, "down", 2, 5), 3)
  assert.equal(Ov.step(13, "up", 2, 5), 18)
  assert.equal(Ov.jump(3, 7, 2, 5), 7)
  assert.equal(Ov.jump(12, 0, 2, 5), 20)
  assert.equal(Ov.jump(3, 0, 1, 5), -1)
  assert.equal(Ov.wheel(10, 1, 2, 5), 1)
  assert.equal(Ov.wheel(1, -1, 2, 5), 10)
})

test("overview: fullscreen hides the rest, floats print last, sums", () => {
  assert.deepEqual(Ov.visibleWindows([{ a: 1 }, { a: 2, fullscreen: true }]).map(w => w.a), [2])
  assert.deepEqual(Ov.visibleWindows([{ a: 1, floating: true }, { a: 2 }]).map(w => w.a), [2, 1])
  assert.equal(Ov.summary([{ count: 2 }, { count: 0 }, { count: 1 }]), "02 SPACES  ·  03 WINDOWS")
  assert.equal(Ov.summary([{ count: 1 }]), "01 SPACE  ·  01 WINDOW")
  assert.equal(Ov.KEYS.length, 6)
})

test("dynamic overview: busy spaces and the live one, then a +", () => {
  const spaces = [{ id: 1, count: 2 }, { id: 2, count: 0 }, { id: 4, count: 1 }, { id: 12, count: 3 }]
  const all = spaces.map(s => s.id)
  assert.deepEqual(Ov.slots(spaces, 2, 0, all).map(s => [s.id, s.add]), [[1, false], [2, false], [4, false], [3, true]])
  assert.deepEqual(Ov.slots(spaces, 1, 0, all).map(s => s.id), [1, 4, 3])
  assert.deepEqual(Ov.slots(spaces, 12, 1, all).map(s => [s.id, s.pos, s.add]), [[12, 2, false], [11, 2, true]])
  // The live workspace shows even when Hyprland hasn't listed it yet.
  assert.deepEqual(Ov.slots([], 5, 0, []).map(s => [s.id, s.active]), [[5, true], [1, false]])
  const full = Array.from({ length: 10 }, (_, k) => k + 1)
  assert.equal(Ov.newWsId(full, 0), 11)
  assert.equal(Ov.newWsId(full.concat([11]), 0), 21)
})

test("dynamic overview: desktops, dots, packing and the selection", () => {
  assert.deepEqual(Ov.deskList([1, 2, 12], 2, [1, 2, 12]), [0, 1, 2])
  assert.deepEqual(Ov.deskList([1, 25], 1, [1, 25]), [0, 2, 3])
  assert.deepEqual(Ov.deskDots([{ id: 1, count: 1 }, { id: 2, count: 0 }, { id: 13, count: 1 }], 0), [true, false])
  const l = Ov.lay(5, 1450, 600, 0.5625, 18, 132, 460, 6)
  assert.equal(l.items.length, 5)
  for (const b of l.items) assert.ok(b.x >= 0 && b.x + b.w <= 1450.01 && b.y + b.h <= 600.01)
  assert.equal(Ov.packRows(3, 1000, 0.5625, 500, 18), null)
  assert.equal(Ov.cycle(4, 1, 5), 0)
  assert.equal(Ov.cycle(0, -1, 5), 4)
  assert.deepEqual(Ov.LAYOUTS, ["grid", "dynamic", "mission"])
})

test("overview layout is a setting beside the counted ones", () => {
  assert.equal(S.resolve({}).overview, "grid")
  assert.equal(S.resolve({ overview: "dynamic" }).overview, "dynamic")
  assert.equal(S.resolve({ overview: "bogus" }).overview, "grid")
  const d = S.withSetting({}, "overview", "dynamic")
  assert.equal(d.overview, "dynamic")
  assert.equal(S.withPreset(d, "Quiet").overview, "dynamic")
  assert.equal(S.withSetting({}, "overview", "tiles"), null)
  assert.deepEqual(Se.optionsFor("overview", S.OPTIONS), ["grid", "dynamic", "mission"])
  assert.equal(S.resolve({ overview: "mission" }).overview, "mission")
  // Shōji's framed pages are gone: a file that names them opens the grid.
  assert.equal(S.withSetting({}, "overview", "framed"), null)
  assert.equal(S.resolve({ overview: "framed" }).overview, "grid")
})

// ── Shōji, folded into Hanko: the preset, the migration, its skin ──────
test("shōji: a saved Shōji design loads as the Shōji preset; touches become settings", () => {
  const doc = { preset: "Quiet", edits: { clock: "mono", height: 36 }, design: "shoji", borrow: { slider: "ruler" },
    touches: { season: "english" }, sheetStyles: { inbox: "tanzaku" },
    monitors: { "DP-2": { height: 32, design: "classic", touches: { grain: "toothy" } }, "HDMI-A-1": { design: "shoji" } } }
  const n = S.normalize(doc, [])
  assert.equal(n.preset, "Shōji"); assert.deepEqual(n.edits, { height: 36 })      // only what Shōji's bar honoured
  assert.equal(n.design, undefined); assert.equal(n.borrow, undefined); assert.equal(n.touches, undefined)
  assert.deepEqual([n.season, n.numerals, n.grain], ["english", "arabic", "fine"])
  assert.equal(n.overview, "grid")
  assert.equal(n.sheetStyles.inbox, "tanzaku"); assert.equal(n.sheetStyles.sound, "shoji")  // a hand you picked stays
  // A monitor in the other design gets that preset's values, under its own.
  assert.equal(n.monitors["DP-2"].seal, "stamp"); assert.equal(n.monitors["DP-2"].height, 32)
  assert.equal(n.monitors["DP-2"].design, undefined)
  assert.deepEqual(n.monitors["HDMI-A-1"], {})
  assert.equal(S.resolve(doc, "DP-2").status, "cells"); assert.equal(S.resolve(doc).status, "ink")
  const w = []; S.normalize(doc, w); assert.deepEqual(w, [])
  assert.deepEqual(S.normalize(n), n)                                    // the migration settles
  // On a Hanko file, a monitor that was Shōji gets Shōji's values.
  assert.equal(S.resolve({ monitors: { "DP-2": { design: "shoji" } } }, "DP-2").surface, "washi")
  assert.equal(JSON.stringify(S.normalize({})).includes("design"), false)
  assert.equal(S.withSetting(n, "clock", "mono").preset, "Shōji")
})

test("the Shōji preset: picked by any spelling, it puts every sheet in the Shōji hand", () => {
  for (const name of ["Shōji", "shoji", "SHOJI", "shōji"]) assert.equal(S.withPreset({}, name).preset, "Shōji")
  const d = S.withPreset({ sheetStyles: { time: "kasumi" }, overview: "dynamic" }, "shoji")
  assert.ok(S.SHEET_KEYS.every(k => S.resolve(d).sheetStyles[k] === "shoji"))
  assert.equal(d.overview, "dynamic")   // the overview is yours
  // Kept afterwards, like anything beside the settings.
  const h = S.withPreset(d, "Hanko"); assert.equal(h.sheetStyles.time, "shoji")
  const st = S.resolve(d)
  assert.deepEqual([st.seal, st.spaces, st.status, st.notif, st.surface, st.pointer], ["carved", "brush", "ink", "seal", "washi", "brush"])
})

test("kata K2: the inks are solved by contrast in every theme", () => {
  for (const [fg, bg] of [["#e9e1d2", "#0e0d0b"], ["#c0caf5", "#1a1b26"], ["#d4be98", "#282828"], ["#575279", "#faf4ed"], ["#100f0f", "#fffcf0"]]) {
    const k = I.kata(fg, bg)
    assert.ok(Math.abs(I.contrast(k.ink3, bg) - 4.6) < 0.1, `ink3 ${fg} on ${bg}: ${I.contrast(k.ink3, bg)}`)
    assert.ok(Math.abs(I.contrast(k.ink4, bg) - 2.05) < 0.1)
    assert.ok(I.contrast(k.ink2, bg) >= 5.5)
    for (const c of Object.values(k)) assert.match(c, /^#[0-9a-f]{6}$/)
  }
})
test("kata K2: a skin carries Shōji's tokens", () => {
  const s = Sk.fromStyle(S.resolve({}))
  assert.deepEqual([s.radius, s.radiusRow, s.radiusChip], [0, 0, 0])
  assert.deepEqual([s.open, s.leave], [340, 160])
  assert.equal(s.opacity, 0.86); assert.equal(s.travels, true); assert.equal(s.joints, true); assert.equal(s.season, "kanji")
  assert.equal(s.gap, 6); assert.equal(s.grain, 1); assert.equal(s.kanjiNumerals, false)
  assert.equal(s.soft, undefined); assert.equal(s.dividerWidth, undefined)
  assert.deepEqual(Object.keys(Sk.TEMPOS), ["johakyu"]); assert.deepEqual(Object.keys(Sk.RADII), ["cut"]); assert.deepEqual(Object.keys(Sk.OPACITY), ["washi"])
  assert.equal(Sk.skin({}).design, "classic")
  // The style's touches and panel opacity reach the skin.
  const t = Sk.fromStyle(S.resolve({ season: "english", numerals: "kanji", grain: "toothy", panelOpacity: 50 }))
  assert.deepEqual([t.season, t.kanjiNumerals, t.grain, t.opacity], ["english", true, 2, 0.5])
  assert.equal(Sk.fromStyle(null).season, "kanji")
})
test("kata K2: brush strokes and ensō are deterministic, closed SVG paths", () => {
  const a = Br.stroke(120, 16, 4), b = Br.stroke(120, 16, 4)
  assert.equal(a, b); assert.match(a, /^M [\d. -]+ Q [\d. -]+( L [\d. -]+)+ Z$/)
  assert.notEqual(Br.stroke(120, 16, 5), a)
  assert.equal(Br.kasure(30, 9, 4).length, 0); assert.equal(Br.kasure(120, 16, 4).length, 4)
  const e = Br.enso(0.91, 118, 11, 9)
  assert.match(e, /^M [\d. -]+( L [\d. -]+)+ Z$/)
  assert.equal(e.split(" L ").length, 242)                 // 121 points out, 121 back
  assert.ok(Br.enso(0, 20).length > 0 && Br.enso(2, 20).length > 0)   // clamped, never empty
})

test("kata K6: the second wave: Shōji's rows and brush-stroke hold", () => {
  const s = Sk.fromStyle(S.resolve({}))
  assert.deepEqual([s.notify, s.hold], ["rows", "stroke"])
  assert.equal(s.overview, undefined)
  assert.equal(Object.keys(Sk.SHOJI).length, 14)
})
test("panel opacity: 30..100 or the design's own, kept beside the edits and through presets", () => {
  assert.equal(S.normalize({}).panelOpacity, undefined)
  assert.equal(S.resolve({}).panelOpacity, 0)
  assert.equal(S.normalize({ panelOpacity: 72 }).panelOpacity, 72)
  assert.equal(S.normalize({ panelOpacity: 5 }).panelOpacity, 30)
  assert.equal(S.normalize({ panelOpacity: 140 }).panelOpacity, 100)
  assert.equal(S.normalize({ panelOpacity: "nope" }).panelOpacity, undefined)
  const d = S.withSetting({}, "panelOpacity", "64")
  assert.equal(S.resolve(d).panelOpacity, 64)
  assert.deepEqual(d.edits, {})
  assert.equal(S.withSetting(d, "panelOpacity", "auto").panelOpacity, undefined)
  assert.equal(S.withSetting(d, "panelOpacity", "x"), null)
  assert.equal(S.withPreset(d, "Quiet").panelOpacity, 64)
  assert.equal(Sk.fromStyle(S.resolve({})).opacity, 0.86)
  assert.equal(Sk.fromStyle(S.resolve({ panelOpacity: 50 })).opacity, 0.5)
})
test("kata K4: the season comes from the sun, right on the boundaries", () => {
  assert.equal(Sn.KO.length, 72); assert.equal(Sn.SEKKI.length, 24)
  const s = Sn.at(new Date("2026-10-08T16:14:00Z"))
  assert.equal(s.koKanji, "鴻雁来"); assert.equal(s.koName, "Wild geese return"); assert.equal(s.sekkiKanji, "寒露")
  assert.equal(Sn.at(new Date("2026-02-04T12:00:00Z")).koKanji, "東風解凍")
  assert.equal(Sn.at(new Date("2026-03-21T12:00:00Z")).koKanji, "雀始巣")
  // the 2027 June solstice is at 14:11 UTC: noon is still the kō before
  assert.equal(Sn.at(new Date("2027-06-21T12:00:00Z")).koKanji, "梅子黄")
  assert.equal(Sn.at(new Date("2027-06-21T16:00:00Z")).koKanji, "乃東枯")
  assert.equal(Sn.label(new Date("2026-10-08T12:00:00Z"), "kanji"), "寒露")
  assert.equal(Sn.label(new Date("2026-10-08T12:00:00Z"), "english"), "Cold dew")
  assert.equal(Sn.label(new Date("2026-10-08T12:00:00Z"), "off"), "")
})

test("sheet styles: two hands per sheet, stored only where not a ledger", () => {
  assert.deepEqual(S.SHEET_STYLES, ["ledger", "tanzaku", "shogi", "soroban", "odoshi", "kasumi", "shoji"])
  assert.equal(S.resolve({}).sheetStyles.sound, "ledger")
  let d = S.withSetting({}, "sheetStyle:sound", "tanzaku")
  assert.deepEqual(d.sheetStyles, { sound: "tanzaku" })
  assert.equal(S.resolve(d).sheetStyles.sound, "tanzaku")
  // A dial saved before the Tanzaku hand replaced it carries over.
  assert.deepEqual(S.normalize({ sheetStyles: { time: "dial" } }).sheetStyles, { time: "tanzaku" })
  assert.equal(S.resolve(d).sheetStyles.time, "ledger")
  d = S.withSetting(d, "sheetStyle:all", "tanzaku")
  assert.equal(Object.keys(d.sheetStyles).length, S.SHEET_KEYS.length)
  d = S.withSetting(d, "sheetStyle:all", "ledger")
  assert.equal(d.sheetStyles, undefined)
  assert.equal(S.withSetting({}, "sheetStyle:sound", "fancy"), null)
  assert.equal(S.withSetting({}, "sheetStyle:nope", "tanzaku"), null)
  // A preset change keeps them, like the overview.
  const p = S.withPreset(S.withSetting({}, "sheetStyle:time", "tanzaku"), "Quiet")
  assert.deepEqual(p.sheetStyles, { time: "tanzaku" })
  assert.deepEqual(S.normalize({ sheetStyles: { time: "ledger", sound: "x", inbox: "tanzaku" } }).sheetStyles, { inbox: "tanzaku" })
  // Prose was taken out: a sheet saved in it is a ledger again.
  assert.equal(S.normalize({ sheetStyles: { inbox: "prose" } }).sheetStyles, undefined)
  // So was Mon.
  assert.equal(S.normalize({ sheetStyles: { sound: "mon" } }).sheetStyles, undefined)
  assert.equal(S.withSetting({}, "sheetStyle:sound", "mon"), null)
  // The four craft hands are kept like Tanzaku.
  for (const h of ["shogi", "soroban", "odoshi", "kasumi", "shoji"]) {
    const e = S.withSetting({}, "sheetStyle:all", h)
    assert.equal(S.resolve(e).sheetStyles.inbox, h)
    assert.deepEqual(S.normalize(e).sheetStyles, e.sheetStyles)
  }
})

test("Shōji's bar parts are Hanko values (S3)", () => {
  const shoji = { seal: "carved", spaces: "brush", title: "ink", clock: "season", media: "ink", status: "ink", notif: "seal", surface: "washi", pointer: "brush" }
  for (const k in shoji) {
    assert.ok(S.OPTIONS[k].includes(shoji[k]), k)
    assert.equal(S.resolve(S.withSetting({}, k, shoji[k]))[k], shoji[k])
  }
  // The values that leave a part out stay last.
  for (const k of ["seal", "title", "media"]) assert.equal(S.OPTIONS[k][S.OPTIONS[k].length - 1], "none")
  // Every Typeset preset keeps the plain pointer; Hanko itself is unchanged.
  for (const n of S.PRESET_NAMES) assert.equal(S.PRESETS[n].pointer, n === "Shōji" ? "brush" : "plain")
  // The touches are kept through a preset change and a shuffle.
  const d = S.withSetting(S.withSetting({}, "season", "off"), "numerals", "kanji")
  assert.equal(S.withPreset(d, "Quiet").season, "off")
  assert.equal(S.shuffled(d, () => 0.5).numerals, "kanji")
})

// ---- the craft hands' model (core/Hands.js)
const Hd = load("core/Hands.js", ["HANDS", "model", "ranks", "setArg", "FRESH_MS"])
const handLib = {
  T: load("core/Time.js", ["WEEKDAYS", "MONTHS", "pad2", "startOfDay", "dayOfYear", "daysInYear", "isoWeek", "leftInDay", "heading"]),
  St: St,
  B: load("core/Blue.js", ["KIND_MARKS", "LOW", "action", "kind"]),
}
const handNow = new Date(2026, 9, 6, 21, 44)
const handFeed = {
  zones: [{ label: "Tokyo", time: "06:44", rel: "+9", ready: true }],
  sound: { master: { percent: 62, level: 0.62, muted: false },
           outputs: [{ id: 41, name: "usb", label: "Studio Monitors", current: true, note: "Live" },
                     { id: 52, name: "bt", label: "WH-1000XM5", current: false, note: "Paired" }],
           streams: [{ id: 7, name: "spotify", label: "Spotify", level: 0.8, percent: 80, muted: false },
                     { id: 8, name: "firefox", label: "Firefox", level: 0.45, percent: 45, muted: true }],
           input: "Input · Shure MV7", inputMuted: false },
  network: { current: { kind: "wifi", label: "Kumo", detail: "Wi-Fi" }, radio: true, offline: false,
             networks: [{ ssid: "Kumo", current: true, saved: true, secure: true, signal: 82, note: "Connected" },
                        { ssid: "Library", current: false, saved: false, secure: false, signal: 22, note: "Open" }] },
  bluetooth: { title: "WH-1000XM5", blurb: "Headphones · 80%", present: true, enabled: true, scanning: false,
               connected: [{ address: "A", name: "WH-1000XM5", detail: "Headphones · 80%", connected: true, paired: true, level: 80 }],
               known: [{ address: "B", name: "MX Keys", detail: "Keyboard", connected: false, paired: true, level: -1 }], found: [] },
  power: { percent: 12, low: true, charging: false, blurb: "40m left",
           details: [{ name: "State", value: "On battery" }, { name: "Cycles", value: "112" }, { name: "Charge limit", value: "80%" }],
           profiles: [{ name: "balanced", label: "Balanced", active: true }, { name: "power-saver", label: "Power saver", active: false }] },
  display: { title: "Built-in", blurb: "2880×1800", monitors: [
               { name: "eDP-1", label: "Built-in", internal: true, enabled: true, focused: true, current: true },
               { name: "HDMI-A-1", label: "TV", internal: false, enabled: false, focused: false, current: false }],
             brightness: { percent: 70, level: 0.7 }, night: false },
  letters: [{ app: "Signal", summary: "Mika", body: "See  you\nat 8", timestamp: handNow.getTime() - 60000, urgent: false, glyph: "信" },
            { app: "System", summary: "Battery low", body: "", timestamp: handNow.getTime() - Hd.FRESH_MS * 2, urgent: true, glyph: "S" }],
  dnd: false,
}

test("hands: every sheet gives a whole model, with data and without", () => {
  for (const sheet of S.SHEET_KEYS) {
    for (const feed of [handFeed, {}]) {
      const m = Hd.model(sheet, feed, handNow, handLib)
      assert.equal(m.sheet, sheet)
      for (const k of ["levels", "choices", "tally", "lines", "buttons"]) assert.ok(Array.isArray(m[k]), sheet + " " + k)
      assert.equal(typeof m.hero.figure, "string")
      for (const r of m.levels.concat(m.choices)) {
        assert.ok(r.level <= 1, sheet + " level")
        assert.equal(typeof r.selected, "boolean")
      }
    }
  }
  assert.deepEqual(Hd.HANDS, ["shogi", "soroban", "odoshi", "kasumi"])
})

test("hands: sound sets the master and each app, outputs are the choices", () => {
  const m = Hd.model("sound", handFeed, handNow, handLib)
  assert.equal(m.hero.figure, "62")
  assert.deepEqual(m.hero.set, { what: "master" })
  const r = Hd.ranks(m)
  assert.equal(r[0].key, "hero")
  assert.equal(r.length, 3)
  assert.deepEqual(Hd.setArg(r[1].set, 0.5), { id: 7, name: "spotify", value: 0.5 })
  assert.equal(Hd.setArg(r[0].set, 0.5), 0.5)
  assert.ok(r[2].muted)
  assert.equal(m.choices[0].selected, true)
  assert.equal(m.choices[0].click, null)
  assert.deepEqual(m.choices[1].click, { what: "output", arg: { id: 52, name: "bt" } })
  assert.deepEqual(m.keys.step, { what: "master", min: 0, level: 0.62 })
})

test("hands: time is the day, week, month and year, and a week of days", () => {
  const m = Hd.model("time", { zones: handFeed.zones }, handNow, handLib)
  assert.equal(m.hero.figure, "21:44")
  assert.equal(m.hero.scales, 24)
  assert.deepEqual(m.levels.map(r => r.key), ["week", "month", "year"])
  assert.equal(m.choices.length, 7)
  assert.equal(m.choices.filter(c => c.selected).length, 1)
  assert.equal(m.choices[1].selected, true) // a Tuesday: Monday first
  assert.equal(m.choices[0].dashed, true)
  assert.equal(m.choices[1].click, null)
  assert.deepEqual(m.tally.map(t => t.n), [21, 44, 6])
  assert.deepEqual(m.lines, ["Tokyo  06:44  +9"])
  const later = Hd.model("time", { timeShift: 2 }, handNow, handLib)
  assert.equal(later.choices.filter(c => c.selected).length, 0)
  assert.deepEqual(later.choices[0].click, { what: "shift", arg: 0 })
  assert.deepEqual(later.keys.left, { what: "shift", arg: 1 })
})

test("hands: network, bluetooth, power, display and inbox", () => {
  const n = Hd.model("network", handFeed, handNow, handLib)
  assert.equal(n.hero.level, 0.82)
  assert.equal(n.levels[0].click, null)
  assert.equal(n.levels[1].click.arg.ssid, "Library")
  assert.equal(Hd.model("network", { network: { radio: false, networks: [] } }, handNow, handLib).hint, "Wi-Fi is off")
  const b = Hd.model("bluetooth", handFeed, handNow, handLib)
  assert.equal(b.levels.length, 1) // has a charge
  assert.equal(b.choices[0].name, "MX Keys") // doesn't
  assert.equal(b.levels[0].mark, "耳")
  assert.equal(b.choices[0].click.what, "device")
  const p = Hd.model("power", handFeed, handNow, handLib)
  assert.ok(p.hero.red)
  assert.deepEqual(p.tally.map(t => t.n), [12, 112])
  assert.equal(p.choices[1].click.arg, "power-saver")
  const d = Hd.model("display", handFeed, handNow, handLib)
  assert.equal(d.hero.min, 0.01)
  assert.equal(d.choices[1].dashed, true)
  assert.equal(d.choices[1].click, null)
  const i = Hd.model("inbox", handFeed, handNow, handLib)
  assert.equal(i.hero.figure, "02")
  assert.equal(i.hero.caption, "1 needs you")
  assert.ok(i.levels[0].level > 0.9)
  assert.equal(i.levels[1].level, 0.08)
  assert.equal(i.levels[0].detail, "See you at 8")
  assert.ok(i.levels[1].urgent)
  assert.equal(i.letter, null)
  // A letter opened (by its stem): selected, unfolded as m.letter, and a
  // second click folds it.
  const letters = [{ app: "Signal", summary: "Mika", body: "A long one", timestamp: handNow.getTime(), stem: "1-4" },
                   { app: "Mail", summary: "Rent", body: "", timestamp: handNow.getTime(), stem: "2-9" }]
  const o = Hd.model("inbox", { letters, openLetter: "2-9" }, handNow, handLib)
  assert.equal(o.letter.summary, "Rent")
  assert.deepEqual(o.levels.map(r => r.selected), [false, true])
  assert.deepEqual(o.levels.map(r => r.click), [{ what: "open", arg: "1-4" }, { what: "open", arg: "" }])
})


test("right side: four studies as status values and presets on your Hanko bar", () => {
  assert.deepEqual(S.OPTIONS.status, ["cells", "glyphs", "numerals", "ink", "ma", "shizuka", "suji", "inro"])
  assert.deepEqual(S.PRESET_NAMES.slice(-4), ["Ma", "Shizuka", "Suji", "Inrō"])
  const status = { Ma: "ma", Shizuka: "shizuka", Suji: "suji", "Inrō": "inro" }
  const hanko = S.PRESETS.Kamon
  for (const name in status) {
    const p = S.PRESETS[name]
    assert.equal(p.status, status[name])
    assert.equal(p.indicatorStyle, "kanji")
    assert.deepEqual(Object.keys(p).sort(), [...S.KEYS].sort())
    // Only the right zone (and Ma's dividers and height) differs from your bar.
    const diff = S.KEYS.filter(k => p[k] !== hanko[k])
    const allowed = ["status", "meters", "indicatorStyle", "rules"].concat(name === "Ma" ? ["height"] : [])
    assert.ok(diff.every(k => allowed.indexOf(k) >= 0), name + " changes " + diff)
  }
  // Typed any case, with or without the macron.
  assert.equal(S.withPreset({}, "inro").preset, "Inrō")
  assert.equal(S.withPreset({}, "SHIZUKA").preset, "Shizuka")
  assert.equal(S.resolve({ preset: "Hanko", edits: { status: "suji" } }).status, "suji")
  assert.deepEqual(S.PRESET_GROUPS.flatMap(g => g.names).sort(), [...S.PRESET_NAMES].sort())
})

test("right side: short names and how full a reading is", () => {
  assert.equal(St.short("OPPO Enco Buds2"), "Enco Buds2")
  assert.equal(St.short("Infinix NOTE 50S 5G"), "Infinix")
  assert.equal(St.short("WH-1000XM5"), "WH-1000XM5")
  assert.equal(St.short("Kumo"), "Kumo")
  assert.equal(St.short("  "), "")
  assert.equal(St.short(null), "")
  assert.equal(St.short("Supercalifragilistic"), "Supercalifrag…")
  assert.equal(St.fill("network", { kind: "wifi", bars: 3 }), 0.75)
  assert.equal(St.fill("network", { kind: "ethernet" }), 1)
  assert.equal(St.fill("network", { off: true }), 0)
  assert.equal(St.fill("bluetooth", { enabled: true, connected: 1, level: 0.6 }), 0.6)
  assert.equal(St.fill("bluetooth", { enabled: true, connected: 1, level: -1 }), 1)
  assert.equal(St.fill("bluetooth", { enabled: true, connected: 0, level: -1 }), 0)
  assert.equal(St.fill("bluetooth", { enabled: false }), 0)
  assert.equal(St.fill("volume", { level: 0.4, muted: true }), 0)
  assert.equal(St.fill("volume", { level: 0.4 }), 0.4)
  assert.equal(St.fill("battery", { level: 1.4 }), 1)
  assert.equal(St.fill("battery", null), 0)
})

test("settings: a Presets 型 page, every preset with a kanji and its facts", () => {
  const pages = Se.RAIL.flatMap(g => g.pages)
  assert.deepEqual(pages.slice(0, 2).map(p => p.key), ["typesetting", "presets"])
  assert.equal(Se.pageInfo("presets").page.jp, "型")
  assert.equal(Se.pageInfo("nope").page.key, "typesetting")
  assert.deepEqual(Object.keys(Se.PRESET_KANJI).sort(), [...S.PRESET_NAMES].sort())
  assert.equal(Se.presetFacts(S.resolve({ preset: "Suji" })), "status suji · clock stacked · 40 px · surface solid")
  assert.ok(Se.presetMatches("Inrō", "inro", S.PRESETS))
  assert.ok(Se.presetMatches("Suji", "筋", S.PRESETS))
  assert.ok(Se.presetMatches("Quiet", "glass", S.PRESETS))
  assert.ok(!Se.presetMatches("Kamon", "glass", S.PRESETS))
  assert.ok(Se.presetMatches("Kamon", "  ", S.PRESETS))
  assert.ok(Se.presetMatches("Kamon", "hanko", S.PRESETS))
})

test("Kamon 家紋 is the preset that was Hanko; the old name still loads it", () => {
  assert.equal(S.DEFAULT_PRESET, "Kamon")
  assert.equal(S.normalize({}).preset, "Kamon")
  assert.equal(S.normalize({ preset: "Hanko", edits: { clock: "mono" } }).preset, "Kamon")
  assert.equal(S.resolve({ preset: "Hanko", edits: { clock: "mono" } }).clock, "mono")
  const w = []; S.normalize({ preset: "hanko" }, w); assert.deepEqual(w, [])
  assert.equal(S.withPreset({}, "HANKO").preset, "Kamon")
  assert.equal(S.normalize({ design: "classic" }).preset, "Kamon")
  assert.ok(S.PRESET_NAMES.indexOf("Hanko") < 0)
  assert.equal(Se.PRESET_KANJI.Kamon, "家紋")
  assert.equal(Se.PRESET_BLURBS.Kamon, "the family crest")
})
test("inkan: form and its corner are settings; the Inkan preset is Kamon as a seal", () => {
  assert.deepEqual(S.OPTIONS.form, ["bar", "inkan"])
  assert.deepEqual(S.OPTIONS.inkanAt, Ik.CORNERS)
  assert.equal(S.resolve({}).form, "bar")
  assert.equal(S.resolve({}).inkanAt, "bottom-right")
  const diff = S.KEYS.filter(k => S.PRESETS.Inkan[k] !== S.PRESETS.Kamon[k])
  assert.deepEqual(diff, ["form"])
  assert.equal(S.withPreset({}, "inkan").preset, "Inkan")
  // Per monitor: a laptop all seal beside a full bar.
  const d = S.withMonitorSetting({}, "eDP-1", "form", "inkan")
  assert.equal(S.resolve(d, "eDP-1").form, "inkan")
  assert.equal(S.resolve(d, "DP-2").form, "bar")
  // A shuffle never takes the bar away or moves the seal.
  for (let i = 0; i < 20; i++) {
    let n = i
    const sh = S.shuffled({ edits: { inkanAt: "top-left" } }, () => ((n = (n * 7919 + 13) % 997) / 997))
    assert.equal(S.resolve(sh).form, "bar")
    assert.equal(S.resolve(sh).inkanAt, "top-left")
  }
  assert.ok(Se.CARDS.some(c => c.rows.some(r => r.key === "form")))
  assert.equal(Se.PRESET_KANJI.Inkan, "印")
  assert.equal(Se.presetFacts(S.resolve({ preset: "Inkan" })), "form inkan · seal bottom-right")
})

test("inkan: the battery wears the carving, always in the same places", () => {
  assert.equal(Ik.wear(null), 1)
  assert.equal(Ik.wear({ percent: 90 }), 1)
  assert.equal(Ik.wear({ percent: 60 }), 1)
  assert.equal(Ik.wear({ percent: 10, charging: true }), 1)
  assert.ok(Ik.wear({ percent: 45 }) > Ik.wear({ percent: 30 }))
  assert.ok(Ik.wear({ percent: 30 }) > Ik.wear({ percent: 14 }))
  assert.equal(Ik.wear({ percent: 0 }), 0.3)
  assert.deepEqual(Ik.specks(), Ik.specks())
  const all = Ik.specks()
  assert.ok(all.length > 60 && all.every(p => p.x > 0 && p.x < 1 && p.y > 0 && p.y < 1 && p.t <= 1))
  assert.equal(Ik.worn(all, 1).length, 0)
  const low = Ik.worn(all, Ik.wear({ percent: 14 })), mid = Ik.worn(all, Ik.wear({ percent: 40 }))
  assert.ok(low.length > mid.length && mid.length > 0)
  // Wearing further only adds specks.
  assert.ok(mid.every(p => low.indexOf(p) >= 0))
})

test("inkan: chips for letters, an outline when quiet, a broken rule offline", () => {
  const one = [{ urgent: false }], three = [{}, {}, { urgent: true }]
  assert.deepEqual(Ik.chips([], false), { count: 0, deep: false })
  assert.deepEqual(Ik.chips(one, false), { count: 1, deep: false })
  assert.deepEqual(Ik.chips(three, false), { count: 2, deep: true })
  assert.deepEqual(Ik.chips(three, true), { count: 0, deep: false })
  assert.ok(Ik.chipSize(true) > Ik.chipSize(false))
  // A list QML hands over need not be a JS Array: counted by its length.
  assert.deepEqual(Ik.chips({ length: 2, 0: {}, 1: { urgent: true } }, false), { count: 1, deep: true })
  const c = Ik.carving({ seal: "stamp", sealGlyph: "寛" }, { notifications: one, network: { off: true }, battery: { percent: 12, needsYou: true } })
  assert.equal(c.glyph, "寛")
  assert.equal(c.chips, 1)
  assert.ok(c.broken && c.low && c.wear < 1 && !c.outline)
  assert.equal(Ik.carving({ seal: "workspace" }, { workspace: 3 }).glyph, "参")
  assert.ok(Ik.carving({ seal: "stamp" }, { dnd: true }).outline)
  assert.ok(Ik.carving({ seal: "carved" }, {}).outline)
  assert.ok(!Ik.carving({ seal: "carved" }, { notifications: one }).outline)
  assert.equal(Ik.carving({ seal: "none" }, {}).glyph, "鑑")
  // Recording or dictation rings the seal, and leads the reading in red.
  const rec = [{ key: "recording", on: true }, { key: "night", on: true }]
  assert.ok(Ik.carving({}, { indicators: rec }).live)
  assert.ok(!Ik.carving({}, { indicators: [{ key: "recording", on: false }, { key: "night", on: true }] }).live)
  assert.deepEqual(Ik.reading({ indicators: rec }, "9:41")[1], { jp: "写", text: "recording", red: true })
})

test("inkan: the hover reading and No. 00's rows", () => {
  const d = { battery: St.battery(14, false, true), network: St.network("wifi\tKumo\t82\t5180"),
              volume: St.volume(0.62, false, true), notifications: [{}, { urgent: true }], dnd: false,
              bluetooth: { enabled: true, connected: 1, name: "WH-1000XM5", level: 0.8, needsYou: false },
              brightness: { percent: 70 } }
  const r = Ik.reading(d, "21:44")
  assert.equal(r[0].text, "21:44")
  assert.deepEqual(r.slice(1).map(p => [p.jp || "", p.text, !!p.red]), [["電", "14%", true], ["", "Kumo", false], ["報", "2", true]])
  const rows = Ik.rows(d)
  assert.deepEqual(rows.map(x => x.key), ["sound", "network", "bluetooth", "power", "display", "inbox"])
  assert.deepEqual(rows.map(x => x.value), ["62%", "Kumo · 82%", "WH-1000XM5 · 80%", "14%", "70%", "2 letters"])
  assert.deepEqual(rows.filter(x => x.red).map(x => x.key), ["power", "inbox"])
  // A desktop: no Power, Display or Bluetooth rows; quiet inbox.
  const desk = Ik.rows({ volume: St.volume(0.5, true, true), network: St.network(""), notifications: [{}], dnd: true })
  assert.deepEqual(desk.map(x => [x.key, x.value, x.red]), [["sound", "Muted", true], ["network", "Offline", true], ["inbox", "Quiet", false]])
  // Each row's kanji is its sheet's.
  for (const row of Ik.ROWS) assert.equal(row.jp, Sh.byKey(row.key).jp, row.key)
})

test("inkan: the seal in its corner, the sheet printed away from the edge it shares", () => {
  assert.deepEqual(Ik.place("bottom-right", 1920, 1080, 46, 18), { x: 1856, y: 1016, width: 46, height: 46 })
  assert.deepEqual(Ik.place("top-left", 1920, 1080, 46, 18), { x: 18, y: 18, width: 46, height: 46 })
  assert.equal(Ik.cornerOf("middle"), "bottom-right")
  const br = Ik.sheetPlace("bottom-right", 1920, 1080, Ik.place("bottom-right", 1920, 1080, 46, 18), 440, 560, 18, 8)
  assert.deepEqual(br, { x: 1462, y: 438, origin: "bottom-right" })
  const tl = Ik.sheetPlace("top-left", 1920, 1080, Ik.place("top-left", 1920, 1080, 46, 18), 440, 560, 18, 8)
  assert.deepEqual(tl, { x: 18, y: 82, origin: "top-left" })
  // A sheet taller than the room above stays on screen.
  assert.equal(Ik.sheetPlace("bottom-left", 800, 500, Ik.place("bottom-left", 800, 500, 46, 18), 440, 560, 18, 8).y, 8)
  assert.equal(Ik.nearest(100, 900, 1920, 1080), "bottom-left")
  assert.equal(Ik.nearest(1500, 100, 1920, 1080), "top-right")
})


test("settings: the proof sets every setting once, on its part or on Overview", () => {
  const all = Se.PROOF.flatMap(p => p.cast.concat(p.also)).concat(["overview"])
  assert.equal(new Set(all).size, all.length)
  const want = S.KEYS.concat(["sealGlyph", "numerals", "hours", "season", "grain", "typeSize", "overview"])
  for (const k of want) assert.ok(all.includes(k), k)
  assert.deepEqual(Se.PROOF.map(p => p.no), ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10"])
  // Every way a cast setting can take has a specimen name and line.
  for (const p of Se.PROOF) for (const k of p.cast)
    for (const v of Se.optionsFor(k, S.OPTIONS)) assert.ok(Se.WAYS[k][v] && Se.wayOf(k, v).line, k + " " + v)
  for (const p of Se.PROOF) for (const k of p.also) assert.ok(Se.ALSO[k], k)
})

test("settings: the proof's parts, edits, search and stepping", () => {
  assert.equal(Se.proofPartOf("hours").key, "clock")
  assert.equal(Se.proofPartOf("inkanAt").key, "frame")
  assert.equal(Se.proofPartOf("overview"), null)
  assert.equal(Se.proofPart("nope").key, "seal")
  const doc = S.normalize({ preset: "Ma", edits: { clock: "inline", hours: "24h", form: "inkan" } })
  assert.deepEqual(Se.proofEdits(Se.proofPart("clock"), doc), ["clock"])
  assert.deepEqual(Se.proofEdits(Se.proofPart("frame"), doc), ["form"])
  assert.ok(Se.proofMatches(Se.proofPart("status"), "brush line", S.OPTIONS))
  assert.ok(Se.proofMatches(Se.proofPart("clock"), "solar", S.OPTIONS))
  assert.ok(!Se.proofMatches(Se.proofPart("seal"), "solar", S.OPTIONS))
  assert.ok(Se.proofMatches(Se.proofPart("frame"), "glass", S.OPTIONS))
  assert.equal(Se.proofStep("frame", 1), "seal")
  assert.equal(Se.proofStep("seal", -1), "frame")
  assert.equal(Se.wayOf("status", "inro").name, "Inrō 印籠")
})

test("settings: the last change in words, and every rail page has a line", () => {
  const a = S.normalize({ preset: "Ma" })
  assert.equal(Se.describeChange(a, S.withSetting(a, "clock", "inline"), S.resolve), "Clock · stacked → inline")
  assert.equal(Se.describeChange(a, S.withPreset(a, "Kamon"), S.resolve), "Preset · Ma → Kamon")
  assert.equal(Se.describeChange(a, S.withSetting(a, "show:seal", "hidden"), S.resolve), "Seal set aside")
  assert.equal(Se.describeChange(a, S.withSetting(a, "show:indicator:night", "hidden"), S.resolve), "Night light set aside")
  assert.equal(Se.describeChange(a, S.withMonitorSetting(a, "DP-2", "height", 32), S.resolve), "DP-2 · Height 32")
  assert.equal(Se.describeChange(a, a, S.resolve), "")
  assert.equal(Se.pageInfo("widgets").page.key, "parts")
  for (const g of Se.RAIL) for (const p of g.pages)
    assert.ok(Se.PLATES.includes(p.key) || Se.PAGE_LINES[p.key], p.key)
})

test("settings: what a preset would change, in the proof's order", () => {
  const doc = S.normalize({ preset: "Ma", edits: { clock: "inline" } })
  const toKamon = Se.presetDiff(doc, "Kamon", S)
  const keys = toKamon.map(r => r.key)
  assert.ok(keys.indexOf("clock") < keys.indexOf("status"))
  assert.deepEqual(toKamon.find(r => r.key === "clock"), { key: "clock", name: "Clock", no: "04", part: "Clock", from: "inline", to: "stacked" })
  assert.equal(toKamon.find(r => r.key === "status").to, "cells")
  assert.equal(toKamon.find(r => r.key === "height").no, "10")
  assert.deepEqual(Se.presetDiff(S.normalize({ preset: "Ma" }), "Ma", S), [])
  assert.ok(Se.presetDiff(doc, "Shōji", S).some(r => r.key === "sheetStyles"))
})

test("settings: the parts tray holds every part once, each a known part", () => {
  const ctx = { own: { indicators: true, keyboard: true, mic: true, tray: true },
    indicators: [{ key: "night", glyph: "月", title: "Night light" }],
    tray: [{ id: "nm-applet", title: "Network", letter: "N" }],
    hosted: [{ id: "omarchy.weather", name: "Weather", firstParty: true }] }
  const parts = Se.partsTray(ctx).flatMap(g => g.sorts.map(s => s.part))
  assert.equal(new Set(parts).size, parts.length)
  for (const p of parts) assert.ok(S.withSetting(S.normalize({}), "show:" + p, "hidden"), p)
  assert.ok(parts.includes("indicator:night") && parts.includes("tray:nm-applet") && parts.includes("hosted:omarchy.weather"))
  assert.ok(!Se.partsTray({}).flatMap(g => g.sorts).some(s => s.kind === "stamp"))
})

test("settings: the timesheet has every motion, the keymap lights its keys", () => {
  assert.deepEqual(Se.MOTION_SHEET.map(m => m.prop), Se.MOTION_ROWS.map(r => r[2]))
  for (const m of Se.MOTION_SHEET) assert.equal(m.curve.length, 4)
  const sheet = Se.KEYMAP.find(c => c.key === "sheet")
  const lit = Se.keysLit(sheet)
  assert.ok(lit.Esc && lit.Tab && lit.M && lit["↑"] && lit.H && lit.Enter && !lit.Q)
  const bar = Se.keysLit(Se.KEYMAP.find(c => c.key === "bar"))
  assert.ok(bar.Menu && bar["0"] && bar["9"] && bar.Esc)
  assert.ok(Se.BINDINGS.some(b => b.command === "omarchy-shell hanko barFocus"))
  assert.ok(!Se.KEYMAP.some(c => c.key === "scroll"))
  const overview = Se.keysLit(Se.KEYMAP.find(c => c.key === "overview"))
  assert.ok(overview["0"] && overview["9"] && overview.J)
  const settings = Se.keysLit(Se.KEYMAP[0])
  assert.ok(settings["1"] && settings["0"] && settings["5"])
  assert.equal(Se.keyDoes(sheet, "M"), "Sound: mute")
  assert.equal(Se.keyDoes(sheet, "Q"), "")
  for (const b of Se.BINDINGS) {
    const code = Se.bindingCode(b)
    assert.ok(code.startsWith('hl.unbind("' + b.keys + '")\n'), code)
    assert.ok(code.includes('o.bind("' + b.keys + '", "' + b.name + '", "omarchy-shell hanko '))
  }
  assert.equal(Se.bindingsCode().split("hl.unbind").length - 1, Se.BINDINGS.length)
})

test("iai: five beats, none overshoots, the sheath slower than the draw, all under 320 ms", () => {
  assert.deepEqual(Ia.ORDER, ["kamae", "nuki", "kiri", "chiburi", "noto"])
  assert.deepEqual(Object.keys(Ia.BEATS).sort(), [...Ia.ORDER].sort())
  for (const name of Ia.ORDER) {
    const b = Ia.BEATS[name]
    assert.equal(b.curve.length, 4, name)
    assert.ok(Ia.total(name) <= 320, name + " " + Ia.total(name))
    assert.deepEqual(Ia.qml(name), [...b.curve, 1, 1])
    let last = 0
    for (let i = 0; i <= 100; i++) {
      const v = Ia.ease(b.curve, i / 100)
      assert.ok(v >= -1e-9 && v <= 1 + 1e-9, `${name} leaves 0..1 at ${i}%: ${v}`)
      assert.ok(v >= last - 1e-9, `${name} goes back at ${i}%`)
      last = v
    }
  }
  assert.ok(Ia.BEATS.noto.ms > Ia.BEATS.nuki.ms)
  assert.ok(Ia.BEATS.nuki.hold > 0)
})

test("iai: the draw is mostly there by half its time; the sheath has barely left", () => {
  assert.ok(Ia.ease(Ia.BEATS.nuki.curve, 0.5) > 0.9)
  assert.ok(Ia.ease(Ia.BEATS.noto.curve, 0.5) < 0.2)
  assert.equal(Ia.at("nuki", 0), 0)
  assert.equal(Ia.at("nuki", Ia.BEATS.nuki.hold), 0)
  assert.equal(Ia.at("nuki", Ia.total("nuki")), 1)
  assert.equal(Ia.at("chiburi", Ia.BEATS.chiburi.delay - 1), 0)
  assert.equal(Ia.hyprSpeed("nuki"), 1.6)
  assert.equal(Ia.hyprSpeed("noto"), 2.4)
})

test("iai: style.lua and the Motion timesheet carry the same curves and speeds", () => {
  const lua = readFileSync(join(root, "style.lua"), "utf8")
  for (const name of ["kamae", "nuki", "chiburi", "noto"]) {
    const m = lua.match(new RegExp(`hl\\.curve\\("${name}", \\{ type = "bezier", points = \\{ \\{ ([\\d.]+), ([\\d.]+) \\}, \\{ ([\\d.]+), ([\\d.]+) \\} \\} \\}\\)`))
    assert.ok(m, "style.lua has no curve " + name)
    assert.deepEqual(m.slice(1, 5).map(Number), Ia.BEATS[name].curve, name)
  }
  const anim = leaf => {
    const m = lua.match(new RegExp(`leaf = "${leaf}", enabled = true, speed = ([\\d.]+), bezier = "(\\w+)"`))
    assert.ok(m, "style.lua has no animation " + leaf)
    return { speed: Number(m[1]), bezier: m[2] }
  }
  for (const [leaf, beat] of [["windowsIn", "nuki"], ["windowsOut", "noto"], ["layersIn", "nuki"], ["layersOut", "noto"], ["fadeIn", "chiburi"]])
    assert.deepEqual(anim(leaf), { speed: Ia.hyprSpeed(beat), bezier: beat }, leaf)
  // The edge inks up over the focus sweep (core/Sweep.js MS), settling in.
  assert.deepEqual(anim("border"), { speed: Sw.MS / 100, bezier: "chiburi" })
  assert.ok(/namespace = "\^hanko-desk\$" \}, no_anim = true/.test(lua), "the desk's overlay must not fade in")
  assert.ok(/local shadow_style = "none"/.test(lua), "Kaze has no window shadows by default")
  assert.ok(!/popin|bounce|elastic|overshot/i.test(lua.replace(/^\s*--.*$/gm, "")), "no pop-in or springs in style.lua")
  for (const name of Ia.ORDER) {
    const row = Se.MOTION_SHEET.find(r => r.prop === name)
    assert.ok(row, "timesheet has no " + name)
    assert.deepEqual(row.curve, Ia.BEATS[name].curve, name)
  }
})

test("sweep: the frame sits a border outside the window; the edge is walked clockwise", () => {
  const r = Sw.frame([100, 50], [400, 300], 1)
  assert.deepEqual(r, { x: 99, y: 49, width: 402, height: 302 })
  assert.equal(Sw.perimeter(r), 1408)
  assert.deepEqual(Sw.pointAt(r, 0), { x: 99, y: 49 })
  assert.deepEqual(Sw.pointAt(r, 402), { x: 501, y: 49 })
  assert.deepEqual(Sw.pointAt(r, 402 + 302), { x: 501, y: 351 })
  assert.deepEqual(Sw.pointAt(r, 402 + 302 + 402), { x: 99, y: 351 })
  assert.deepEqual(Sw.pointAt(r, 1408), { x: 99, y: 49 })
})

test("sweep: nothing before or after, a lit stretch between, brightest at the head, on the edge", () => {
  const r = Sw.frame([0, 0], [400, 300], 1)
  assert.deepEqual(Sw.lit(r, 0), [])
  assert.deepEqual(Sw.lit(r, 1), [])
  const mid = Sw.lit(r, 0.5)
  assert.ok(mid.length >= Sw.PIECES)
  assert.ok(mid[mid.length - 1].alpha > mid[0].alpha)
  for (const s of mid) for (const q of [s.a, s.b]) {
    const onEdge = Math.abs(q.x - r.x) < 1e-3 || Math.abs(q.x - r.x - r.width) < 1e-3 || Math.abs(q.y - r.y) < 1e-3 || Math.abs(q.y - r.y - r.height) < 1e-3
    assert.ok(onEdge, JSON.stringify(q))
    // each piece runs along one side (horizontal or vertical)
    assert.ok(Math.abs(s.a.x - s.b.x) < 1e-3 || Math.abs(s.a.y - s.b.y) < 1e-3)
  }
  // the light's total length stays within its share of the perimeter
  const len = mid.reduce((n, s) => n + Math.hypot(s.b.x - s.a.x, s.b.y - s.a.y), 0)
  assert.ok(len <= Sw.perimeter(r) * Sw.LENGTH + 1)
  // at the very start only a sliver of the top edge is lit
  const start = Sw.lit(r, 0.01)
  assert.ok(start.every(s => Math.abs(s.a.y - r.y) < 1e-3))
})

test("sweep: a window is drawn on its own screen only, in that screen's coordinates", () => {
  const screen = { x: 1920, y: 0, width: 2560, height: 1440 }
  assert.equal(Sw.onScreen({ x: 10, y: 10, width: 100, height: 100 }, screen), null)
  assert.deepEqual(Sw.onScreen({ x: 2000, y: 50, width: 100, height: 100 }, screen), { x: 80, y: 50, width: 100, height: 100 })
})

test("print: the majority tone becomes the paper, on dark and light themes", () => {
  // Great Wave (0.65) and Sudden Shower (0.59) flip on a dark desk; the night pines (0.18) don't.
  assert.deepEqual(Pt.steps(0.65, false, "#000", "#888"), { negate: true, from: "#000", to: "#888" })
  assert.deepEqual(Pt.steps(0.18, false, "#000", "#888"), { negate: false, from: "#000", to: "#888" })
  // On a light desk the light end is paper, and a mostly dark picture flips.
  assert.deepEqual(Pt.steps(0.18, true, "#eee", "#333"), { negate: true, from: "#333", to: "#eee" })
  assert.deepEqual(Pt.steps(0.65, true, "#eee", "#333"), { negate: false, from: "#333", to: "#eee" })
  assert.equal(Pt.steps(NaN, false, "a", "b").negate, false)
  const ramp = I.ramp("#ddd5c7", "#0a0a09")
  assert.equal(Pt.inkFor(ramp, false), ramp.inkFaint)
  assert.equal(Pt.inkFor(ramp, true), ramp.inkMuted)
  assert.equal(Pt.wallpaperMode({}), "print")
  assert.equal(Pt.wallpaperMode({ wallpaper: "original" }), "original")
  assert.equal(Pt.wallpaperMode({ wallpaper: "nonsense" }), "print")
})

test("print: the sky lifts by day, settles at night, a few percent at most", () => {
  assert.deepEqual(Pt.skyAt(12), { lift: 0.07, shade: 0 })
  assert.deepEqual(Pt.skyAt(0), { lift: 0, shade: 0.22 })
  assert.equal(Pt.skyAt(6).lift, 0)
  assert.equal(Pt.skyAt(24).shade, Pt.skyAt(0).shade)
  for (let h = 0; h < 24; h += 0.5) {
    const s = Pt.skyAt(h)
    assert.ok(s.lift <= 0.07 && s.shade <= 0.22 && (s.lift === 0 || s.shade === 0), String(h))
  }
})

test("print: hanko-print and Print.js crush to the same tones", () => {
  const sh = readFileSync(join(root, "scripts/hanko-print"), "utf8")
  assert.ok(sh.includes(`TONES=${Pt.TONES} CLIP=${Pt.CLIP}`))
})

test("wind: a west wind leans the grass right, an east wind left, calm stands still", () => {
  assert.equal(Wi.lean(0, 270), 0)
  assert.ok(Wi.lean(14, 270) > 0)
  assert.ok(Wi.lean(14, 90) < 0)
  assert.equal(Wi.lean(14, 270), -Wi.lean(14, 90))
  assert.equal(Wi.lean(400, 270), Wi.MAX_LEAN)
  // from the north: still felt, by its least share
  assert.ok(Math.abs(Wi.lean(40, 0)) >= Wi.MIN_FELT - 1e-9)
  assert.ok(Math.abs(Wi.lean(9, 270)) < Math.abs(Wi.lean(31, 270)))
  assert.equal(Wi.lean("x", 0), 0)
})

test("wind: the field is clumps across the width, the same every time", () => {
  const a = Wi.field(1920, 170, 11), b = Wi.field(1920, 170, 11)
  assert.deepEqual(a, b)
  assert.ok(a.length > 150 && a.length < 600, String(a.length))
  assert.ok(a.some(x => x.plume))
  assert.ok(a.every(x => x.len > 0 && x.len <= 170 && x.x < 1960))
  assert.ok(Math.max(...a.map(x => x.x)) > 1800)
})

test("wind: a blade leans with the wind and harder in a gust; the gust runs toward its target", () => {
  const b = { x: 960, len: 100, rest: 0, w: 1, alpha: 1, plume: true, jitter: 1 }
  const still = Wi.blade(b, 170, 1920, 0, 0, null)
  assert.equal(still.tip[0], 960)
  assert.equal(still.plume.length, 7)
  const right = Wi.blade(b, 170, 1920, 0.4, 0, null)
  assert.ok(right.tip[0] > 960 && right.tip[1] > still.tip[1])
  const gust = Wi.blade(b, 170, 1920, 0.4, 0, { x: 0.5, width: 0.08, strength: 1.2 })
  assert.ok(gust.tip[0] > right.tip[0])
  assert.equal(Wi.gustAt(0, 0.9), null)
  assert.equal(Wi.gustAt(1, 0.9), null)
  const g1 = Wi.gustAt(0.3, 0.9), g2 = Wi.gustAt(0.7, 0.9)
  assert.ok(g1.x < g2.x && g2.x < 0.9)
  assert.ok(Wi.gustAt(0.5, 0.1).x > 0.1)
})

test("wind: it rests under fullscreen, with motion still and on low battery; settings default on", () => {
  assert.equal(Wi.mayMove(false, false, false, 1), true)
  assert.equal(Wi.mayMove(true, false, false, 1), false)
  assert.equal(Wi.mayMove(false, true, false, 1), false)
  assert.equal(Wi.mayMove(false, false, true, 0.2), false)
  assert.equal(Wi.mayMove(false, false, true, 0.5), true)
  assert.equal(Wi.swayAt(0.05, 3), 0)
  // The ripple: none in calm, bigger in a strong wind, running downwind.
  assert.equal(Wi.ripple(0.1, 2, 0.5), 0)
  const peak = l => Math.max(...Array.from({ length: 200 }, (_, i) => Math.abs(Wi.ripple(l, i * 0.05, 0.3))))
  assert.ok(peak(1.2) > peak(0.3) && peak(1.2) <= 0.16 + 1e-9)
  // A crest at x moves to a larger x a moment later when the wind leans right.
  const crest = (l, t) => { let best = 0, at = 0; for (let x = 0; x <= 0.38; x += 0.002) { const v = Wi.ripple(l, t, x) * Math.sign(l); if (v > best) { best = v; at = x } } return at }
  assert.ok(crest(1, 0.1) > crest(1, 0))
  assert.ok(crest(-1, 0.1) < crest(-1, 0) || crest(-1, 0) === 0)
  const rb = Wi.blade({ x: 300, len: 100, rest: 0, w: 1, alpha: 1, plume: false, jitter: 1 }, 170, 1920, 1, { t: 0.4 }, null)
  assert.ok(Array.isArray(rb.tip) && isFinite(rb.tip[0]))
  // Puffs: none in a light wind, every 3–12 s in a strong one.
  assert.equal(Wi.puffAfter(0.3, 0.5), 0)
  assert.ok(Wi.puffAfter(1.2, 0) >= 3000 && Wi.puffAfter(1.2, 1) <= 12000 && Wi.puffAfter(1.4, 1) < Wi.puffAfter(0.6, 1))
  assert.ok(Wi.gustAt(0.5, 1, 0.5).strength < Wi.gustAt(0.5, 1).strength)
  // The shader's wave: none in calm, the tips' shift a few % of the width,
  // and the shader reads exactly these uniforms (and is compiled).
  assert.equal(Wi.rippleUniforms(0.1, 170, 1920).amp, 0)
  const u = Wi.rippleUniforms(-1.2, 170, 1920)
  assert.equal(u.dir, -1)
  assert.ok(u.amp > 0.01 && u.amp < 0.03 && u.freq > 0.5)
  const frag = readFileSync(join(root, "assets/shaders/grass.frag"), "utf8")
  for (const name of ["time", "amp", "freq", "dir"]) assert.match(frag, new RegExp(`float ${name};`))
  const qml = readFileSync(join(root, "plugins/hanko.background/Background.qml"), "utf8")
  assert.match(qml, /grass\.frag\.qsb/)
  assert.ok(statSync(join(root, "assets/shaders/grass.frag.qsb")).mtimeMs >= statSync(join(root, "assets/shaders/grass.frag")).mtimeMs - 1000, "grass.frag changed: run scripts/hanko-shaders")
  assert.ok(Math.abs(Wi.swayAt(0.5, 1)) <= 0.04 + 1e-9)
  assert.deepEqual(Wi.settings({}), { grass: "grass", gusts: true, wind: "weather", speed: 15, from: "west" })
  assert.deepEqual(Wi.settings({ grass: "off", gusts: false, wind: "calm" }), { grass: "off", gusts: false, wind: "calm", speed: 15, from: "west" })
  assert.equal(Wi.settings({ grass: "petals" }).grass, "grass")
})

test("taikan: levels fill from the centre, the top is the break, muted is red and empty", () => {
  const v = Tk.view({ iconKey: "volume-high", maxValue: 100, hasProgress: true, value: 62, message: "62%", duration: 1200 })
  assert.equal(v.kind, "level"); assert.equal(v.label, "VOL"); assert.equal(v.kanji, "音")
  assert.equal(v.fill, 0.62); assert.equal(v.figure, 62); assert.equal(v.full, false); assert.equal(v.red, false)
  assert.equal(Tk.view({ iconKey: "brightness", hasProgress: true, value: 100, maxValue: 100 }).full, true)
  const m = Tk.view({ iconKey: "volume-muted", hasProgress: true, value: 40, maxValue: 100 })
  assert.ok(m.muted && m.red && m.fill === 0 && m.word === "無音 Muted")
  assert.equal(Tk.view({ iconKey: "keyboard", hasProgress: true, value: 3, maxValue: 6 }).fill, 0.5)
  assert.deepEqual(Tk.halves(0.62), { left: 0.19, width: 0.62 })
  assert.deepEqual(Tk.halves(2), { left: 0, width: 1 })
})

test("taikan: switches get a crest and their word; red only when you turned it off", () => {
  const off = Tk.view({ iconKey: "microphone-muted", message: "Microphone muted", hasProgress: false })
  assert.deepEqual([off.kind, off.crest, off.red, off.label, off.word], ["switch", "黙", true, "MICROPHONE", "Muted"])
  const on = Tk.view({ iconKey: "microphone", message: "Microphone on" })
  assert.deepEqual([on.crest, on.red, on.word], ["声", false, "On"])
  assert.equal(Tk.view({ iconKey: "", message: "Hello" }).crest, "文")
  assert.equal(Tk.view({ iconKey: "Hello", message: "x" }).crest, "文")
  assert.equal(Tk.view({ iconKey: "鍵", message: "Unlocked" }).crest, "鍵")
  const end = Tk.view({ iconKey: "reboot", message: "Rebooting", duration: 5000 })
  assert.deepEqual([end.kind, end.kanji, end.sealed, end.sub, end.duration], ["ceremony", "終", true, "Restarting", 5000])
  const out = Tk.view({ iconKey: "logout", message: "Logging out" })
  assert.deepEqual([out.kanji, out.sealed, out.band], ["退", false, false])
  const danger = Tk.view({ iconKey: "danger", message: "Battery 5%", duration: 800 })
  assert.deepEqual([danger.kanji, danger.red, danger.band, danger.english, danger.duration], ["危", true, true, "Battery 5%", 1200])
  assert.equal(Tk.view({ iconKey: "new", message: "Omarchy 4.1" }).sub, "Omarchy 4.1")
  assert.equal(Tk.view({}).duration, 1200)
})

test("fumi: a crest per sender, a kind per letter, red only when critical", () => {
  assert.equal(Fu.crestFor("Signal"), "話")
  assert.equal(Fu.crestFor("Thunderbird"), "郵")
  assert.equal(Fu.crestFor("org.gnome.Calendar"), "暦")
  assert.equal(Fu.crestFor("Spotify"), "曲")
  assert.equal(Fu.crestFor("zen"), "網")
  assert.equal(Fu.crestFor(""), "器")
  assert.equal(Fu.crestFor("Mystery App"), "文")
  assert.equal(Fu.kindFor("Signal", "Aiko", "Are we on for Saturday?", 1), "便り")
  assert.equal(Fu.kindFor("UPower", "Battery low", "5%", 2), "警告")
  assert.equal(Fu.kindFor("gnome-calendar", "Standup", "in 5 minutes", 1), "予定")
  assert.equal(Fu.kindFor("Hyprshot", "Screenshot saved", "", 1), "完了")
  assert.equal(Fu.urgent(2), true); assert.equal(Fu.urgent(1), false)
  assert.equal(Fu.isScreenshot("", "Screenshot saved to clipboard and file"), true)
  assert.equal(Fu.isScreenshot("Hyprshot", "Saved"), true)
  assert.equal(Fu.isScreenshot("Signal", "Aiko"), false)
  assert.equal(Fu.crestFor("", "Screenshot saved to clipboard and file"), "写")
})

test("fumi: five strips at most, then a count; bodies as plain words; time and gust share", () => {
  assert.deepEqual(Fu.shown(3), { strips: 3, more: 0 })
  assert.deepEqual(Fu.shown(8), { strips: 5, more: 3 })
  assert.deepEqual(Fu.shown(-1), { strips: 0, more: 0 })
  assert.equal(Fu.plain("<b>Hi</b> &amp; <a href='x'>there</a><br/>ok"), "Hi & there\nok")
  assert.equal(Fu.timeOf(new Date(2026, 9, 14, 9, 5).getTime()), "09:05")
  assert.equal(Fu.gustShare(96, 1920), 0.95)
  assert.equal(Fu.gustShare(5000, 1920), 0)
})

test("taiji: the blade grows a nick a key, never past its length, and draws no password", () => {
  assert.equal(Tj.bladeWidth(0), 0)
  assert.equal(Tj.bladeWidth(1), Tj.LEAD + Tj.NICK + 16)
  assert.equal(Tj.bladeWidth(200, 640), 640)
  assert.equal(Tj.nicks(0).length, 0)
  assert.equal(Tj.nicks(9).length, 9)
  const many = Tj.nicks(200, 640)
  assert.ok(many.length > 0 && many.length < 200 && Math.max(...many) <= 632)
})

test("taiji: the hint says what the lock is doing; red only after a wrong password", () => {
  assert.deepEqual(Tj.hint({}), { text: "Type to unlock", red: false })
  assert.equal(Tj.hint({ fingerprint: true }).text, "Type to unlock · or touch the reader")
  assert.equal(Tj.hint({ count: 9 }).text, "9 characters · Enter to cut")
  assert.equal(Tj.hint({ count: 1 }).text, "1 character · Enter to cut")
  // the unlock cut: the hairline at once, then faded; each half rolls only
  // forward, the one above first, and both are gone by the end
  assert.equal(Tj.cutFlash(0), 1)
  assert.equal(Tj.cutFlash(Tj.CUT_MS), 0)
  for (let k = 0; k < 2; k++) {
    assert.equal(Tj.cutRoll(k, 0), 0)
    assert.equal(Tj.cutRoll(k, Tj.CUT_MS), 1)
    let last = 0
    for (let ms = 0; ms <= Tj.CUT_MS; ms += 10) { const r = Tj.cutRoll(k, ms); assert.ok(r >= last - 1e-9); last = r }
    assert.ok(Tj.CUT_CURLS[k].at + Tj.CUT_CURLS[k].ms <= Tj.CUT_MS)
  }
  assert.ok(Tj.CUT_CURLS[0].at < Tj.CUT_CURLS[1].at)
  // the curl: flat at 0 (its axis at the leading end of the cut), past the
  // far corner at 1, moving only outward and opening as it goes
  for (const [w, h] of [[1920, 1080], [2560, 1440], [1080, 1920]]) {
    const at0 = Tj.cutCurl(0, w, h), at1 = Tj.cutCurl(1, w, h)
    assert.equal(at0.fold, at0.start)
    assert.ok(at1.fold - at1.radius >= at1.end)
    let fold = -Infinity, radius = 0
    for (let t = 0; t <= 1; t += 0.05) {
      const c = Tj.cutCurl(t, w, h)
      assert.ok(c.fold > fold && c.radius >= radius - 1e-9)
      fold = c.fold; radius = c.radius
    }
  }
  // the shaders read these uniforms, and are compiled
  const curlVert = readFileSync(join(root, "assets/shaders/curl.vert"), "utf8")
  for (const name of ["side", "fold", "radius", "tilt", "eye"]) assert.match(curlVert, new RegExp(`float ${name};`))
  const desk = readFileSync(join(root, "plugins/hanko.desk/Desk.qml"), "utf8")
  for (const f of ["curl.vert", "curl.frag", "curlshade.frag"]) {
    assert.match(desk, new RegExp(f.replace(".", "\\.") + "\\.qsb"))
    assert.ok(statSync(join(root, "assets/shaders", f + ".qsb")).mtimeMs >= statSync(join(root, "assets/shaders", f)).mtimeMs - 1000, f + " changed: run scripts/hanko-shaders")
  }
  assert.deepEqual(Tj.hint({ failure: "x", attempts: 2 }), { text: "Not that one · 2", red: true })
  assert.equal(Tj.hint({ authenticating: true, failure: "x" }).text, "Checking…")
  assert.equal(Tj.dayLine(new Date(2026, 9, 14)), "Wednesday · 14 October")
  assert.equal(Tj.nameOf("shadow"), "Shadow")
  assert.equal(Tj.sentence("chrysanthemums bloom"), "Chrysanthemums bloom")
})

test("taiji: the lock clone keeps Omarchy's service byte for byte and the view's whole interface", () => {
  const ours = join(root, "plugins/hanko.lock")
  const theirs = "/usr/share/omarchy/shell/plugins/lock"
  let stock = null
  try { stock = readFileSync(theirs + "/Service.qml", "utf8") } catch (e) {}
  if (stock !== null) assert.equal(readFileSync(ours + "/Service.qml", "utf8"), stock, "Service.qml differs from Omarchy's")
  const view = readFileSync(ours + "/LockView.qml", "utf8")
  for (const p of ["backgroundPath", "backgroundVersion", "fingerprintConfigured", "authenticatingPassword", "failureMessage",
    "failedAttempts", "inputEnabled", "loadBackground", "passwordText"]) assert.ok(new RegExp(`property \\w+ ${p}:`).test(view), "LockView lost " + p)
  for (const sig of ["submitPassword(string password)", "passwordTextEdited(string password)", "clearFailureRequested()", "wakeRequested()"])
    assert.ok(view.includes("signal " + sig), "LockView lost signal " + sig)
  for (const keep of ["echoMode: TextInput.Password", "root.submitPassword(submitted)", "root.passwordTextEdited(text)", "forceActiveFocus()"])
    assert.ok(view.includes(keep), "LockView lost " + keep)
})

test("fumi: a snooze's length, short", () => {
  assert.deepEqual([1800, 3600, 14400, 50400, 0].map(Fu.forHow), ["30m", "1h", "4h", "14h", "1m"])
})

test("fumi on the deck: Omarchy's daemon copied whole, only the surface and two IPC calls Hanko's; refused when it moves", () => {
  const tmp = mkdtempSync(join(tmpdir(), "hanko-fumi-"))
  const stock = join(tmp, "stock"), out = join(tmp, "out")
  mkdirSync(stock)
  const surface = "  // ------------------------------------------------------------- surface\n"
  const uses = ["ListModel {\n    id: toasts\n  }", "property var leaving: ({})", "function closeToast(key, reason) {}",
    "function activate(key) {}", "function rowIndexFor(key) {}", "function storeDrop(key) {}", "property var historyEntries: []",
    "function saveSoon(file) {}", "function refreshHeld() {}", "function refreshHistory() {}", "property var liveKeys: ({})",
    "function showsOn(name) {}", "function marginsFor(screenName) {}", "function fullscreenOn(name) {}",
    "function actionsOf(key, revision) {}", "function invokeAction(key, identifier) {}", "readonly property var snoozeOptions: []",
    "function snoozeSource(groupKey, label, seconds, fromNow) {}", "readonly property var barRef: null",
    "readonly property int defaultBarSize: 0", "property int refsRevision: 0", "function clearAll(reason) {}",
    "var list = surfaceVariants.instances"]
  const service = 'import "Delivery.js" as Delivery\nimport "Icons.js" as Icons\n\nItem {\n  id: service\n' + uses.join("\n") +
    '\n  ShellIpc {\n    function ping(): string { return "ok" }\n  }\n' + surface + "  Variants { STOCK_CARDS_MARKER }\n}\n"
  writeFileSync(join(stock, "Service.qml"), service)
  writeFileSync(join(stock, "Store.js"), "// store\n")
  writeFileSync(join(stock, "manifest.json"), '{"id": "omarchy.notifications"}\n')
  const run = () => execFileSync("python3", [join(root, "scripts/hanko-fumi-deck"), stock, join(root, "plugins/hanko.notifications"), out], { stdio: "pipe" })
  run()
  const built = readFileSync(join(out, "Service.qml"), "utf8")
  assert.equal(readFileSync(join(out, "Store.js"), "utf8"), "// store\n")
  assert.equal(JSON.parse(readFileSync(join(out, "manifest.json"), "utf8")).id, "hanko.notifications")
  assert.ok(built.startsWith(service.slice(0, service.indexOf("Item {"))), "the stock imports stay first")
  assert.ok(built.includes('import "core/Fumi.js" as Fumi'))
  assert.ok(built.includes(uses.join("\n")), "everything above the surface is stock")
  assert.ok(built.includes("function forgetKeys(keys: string): string") && built.includes("function forgetAll(): string"))
  assert.ok(!built.includes("STOCK_CARDS_MARKER") && built.includes('WlrLayershell.namespace: "hanko-notifications"'))
  assert.ok(built.includes("id: surfaceVariants"), "probe still finds the surfaces")
  // A stock file that lost something the patch needs is refused, and nothing is written.
  writeFileSync(join(stock, "Service.qml"), service.replace("function closeToast(key, reason) {}", ""))
  rmSync(out, { recursive: true, force: true })
  assert.throws(run, e => e.status === 2)
  assert.throws(() => statSync(join(out, "Service.qml")))
  rmSync(tmp, { recursive: true, force: true })
})

test("oto: silent by default; quiet and on; one sound off on its own; only the bell in Sumi", () => {
  assert.equal(Ot.play("letter", {}), null)
  assert.deepEqual(Ot.play("letter", { sound: "quiet" }), { file: "kami", volume: 0.15 })
  assert.deepEqual(Ot.play("workspace", { sound: "on" }), { file: "hyoshigi", volume: 0.3 })
  assert.equal(Ot.play("workspace", { sound: "on", sounds: { workspace: false } }), null)
  assert.equal(Ot.play("letter", { sound: "on" }, true), null)
  assert.deepEqual(Ot.play("end", { sound: "on" }, true), { file: "kane", volume: 0.3 })
  assert.equal(Ot.play("nonsense", { sound: "on" }), null)
  assert.equal(Ot.mode({ sound: "loud" }), "off")
  for (const f of Object.values(Ot.EVENTS)) assert.ok(readFileSync(join(root, "assets/sounds/" + f + ".ogg")).length > 500, f)
})

test("settings: the Kaze page's switches read and write kaze.json the way the plugins read it", () => {
  assert.deepEqual(Se.KAZE_SWITCHES.map(s => s.key), ["wallpaper", "grass", "gusts", "wind", "sound", "osdCard"])
  assert.equal(Se.kazeValue({}, "osdCard"), "on")
  assert.equal(Se.kazeWith({}, "osdCard", "off").osdCard, "off")
  assert.equal(Se.kazeValue({}, "wallpaper"), "print")
  assert.equal(Se.kazeValue({}, "sound"), "off")
  assert.equal(Se.kazeValue({}, "gusts"), "on")
  assert.equal(Se.kazeValue({ gusts: false }, "gusts"), "off")
  assert.equal(Se.kazeValue({ grass: "petals" }, "grass"), "grass")
  const d = Se.kazeWith({ wallpaper: "print", extra: 1 }, "gusts", "off")
  assert.deepEqual(d, { wallpaper: "print", extra: 1, gusts: false })
  assert.equal(Se.kazeWith({}, "sound", "quiet").sound, "quiet")
  // what the plugins make of them
  assert.equal(Pt.wallpaperMode(Se.kazeWith({}, "wallpaper", "original")), "original")
  assert.deepEqual(Wi.settings(Se.kazeWith(Se.kazeWith({}, "grass", "off"), "gusts", "off")), { grass: "off", gusts: false, wind: "weather", speed: 15, from: "west" })
  assert.equal(Ot.mode(Se.kazeWith({}, "sound", "on")), "on")
  assert.equal(Se.kazeChange({}, { sound: "quiet" }), "Sound · off → quiet")
  assert.equal(Se.kazeChange({ gusts: true }, {}), "")
  assert.deepEqual(Se.kazeOn({ wallpaper: "print" }, true, true, false), { on: 6, of: 9 })  // the OSD card is on by default
  // The cursor, the tools and the theme count when the page gives them.
  assert.deepEqual(Se.kazeOn({ wallpaper: "print" }, true, true, false, { cursor: true, tools: false, theme: true }), { on: 8, of: 12 })
  // The virtual wind: Settings and the grass read windSpeed/windFrom the same way.
  for (const doc of [{}, { wind: "virtual" }, { wind: "virtual", windSpeed: 32, windFrom: "east" }, { windSpeed: 99 }, { windSpeed: -4 }, { windSpeed: "x" }, { windSpeed: 0 }]) {
    const a = Se.kazeWind(doc), b = Wi.settings(doc)
    assert.deepEqual([a.speed, a.from], [b.speed, b.from], JSON.stringify(doc))
  }
  assert.equal(Wi.settings({ wind: "virtual" }).wind, "virtual")
  assert.equal(Se.kazeValue({ wind: "virtual" }, "wind"), "virtual")
  assert.equal(Se.kazeWind({ windSpeed: 0 }).speed, 0)
  assert.ok(Wi.virtualLean(Wi.settings({ wind: "virtual", windSpeed: 30 })) > 0)
  assert.ok(Wi.virtualLean(Wi.settings({ wind: "virtual", windSpeed: 30, windFrom: "east" })) < 0)
  assert.equal(Wi.virtualLean(Wi.settings({ wind: "virtual", windSpeed: 0 })), 0)
  assert.equal(Se.kazeChange({ wind: "virtual" }, { wind: "virtual", windSpeed: 30 }), "Virtual wind · 15 → 30 km/h")
  assert.equal(Se.kazeWith({}, "windSpeed", 22).windSpeed, 22)
  assert.ok(Se.PAGE_LINES.kaze)
})


test("theme: the Hanko theme ships what Omarchy reads, its paper the bar's", () => {
  const dir = join(root, "theme")
  for (const f of ["colors.toml", "hyprland.lua", "icons.theme", "shell.bar.toml", "shell.menu.toml", "shell.launcher.toml", "btop.theme", "neovim.lua", "preview.jpg"])
    assert.ok(readFileSync(join(dir, f)).length > 0, f)
  const colors = readFileSync(join(dir, "colors.toml"), "utf8")
  assert.match(colors, /^background = "#0a0a09"$/m)
  assert.match(colors, /^foreground = "#ddd5c7"$/m)
  assert.match(colors, /^red = "#d8452f"$/m)
  assert.match(readFileSync(join(dir, "neovim.lua"), "utf8"), /colorscheme = "hanko"/)
})

// Dōgu 道具: the Lua ramp the tools use (assets/kaze/nvim/lua/hanko/ink.lua)
// must give the bar's inks, and btop's theme must name every key btop reads.
// Skipped where no Lua is installed.
{
  const { execFileSync } = await import("node:child_process")
  const lua = ["lua", "luajit"].find(cmd => { try { execFileSync(cmd, ["-v"], { stdio: "ignore" }); return true } catch { return false } })
  test("tools: the Lua ink ramp agrees with InkMath.js, and btop gets every key", () => {
    if (!lua) return
    const env = { ...process.env, LUA_PATH: join(root, "assets/kaze/nvim/lua/?.lua") + ";;" }
    const themes = [["#f8ebeb", "#010000"], ["#2b2924", "#dfdacb"], ["#a9b1d6", "#1a1b26"], ["#575279", "#faf4ed"], ["#d4be98", "#282828"], ["#ddd5c7", "#0a0a09"]]
    const code = `local I = require("hanko.ink") for _, t in ipairs({${themes.map(([f, b]) => `{"${f}","${b}"}`).join(",")}}) do local r = I.ramp(t[1], t[2]) print(r.ink, r.inkDim, r.inkMuted, r.inkFaint) end`
    const out = execFileSync(lua, ["-e", code], { env, encoding: "utf8" }).trim().split("\n")
    themes.forEach(([fg, bg], i) => {
      const r = I.ramp(fg, bg)
      assert.equal(out[i], [r.ink, r.inkDim, r.inkMuted, r.inkFaint].join("\t"), `${fg} on ${bg}`)
    })
    const theme = execFileSync(lua, [join(root, "assets/kaze/btop.lua"), join(root, "tests/harness/fixtures/colors.toml")], { env, encoding: "utf8" })
    const keys = [...theme.matchAll(/^theme\[(\w+)\]="#[0-9a-f]{6}"$/gm)].map(m => m[1])
    assert.equal(keys.length, 42)
    assert.ok(theme.includes('theme[used_end]="#d8452f"'))
    assert.ok(theme.includes('theme[selected_bg]="#ddd5c7"') && theme.includes('theme[selected_fg]="#0a0a09"'))
  })
  test("theme: the Hanko theme's btop.theme is what btop.lua writes for its colours", () => {
    if (!lua) return
    const env = { ...process.env, LUA_PATH: join(root, "assets/kaze/nvim/lua/?.lua") + ";;" }
    const made = execFileSync(lua, [join(root, "assets/kaze/btop.lua"), join(root, "theme/colors.toml")], { env, encoding: "utf8" })
    assert.equal(readFileSync(join(root, "theme/btop.theme"), "utf8"), made)
  })
}

test("kaisei: a quickshell core dump in the last two minutes means the shell rose again", () => {
  const now = 1790000000000
  const dump = (ms, exe) => JSON.stringify([{ exe: exe || "/usr/bin/quickshell", time: (now - ms) * 1000 }])
  assert.equal(Ks.crashedRecently(dump(30000), now), true)
  assert.equal(Ks.crashedRecently(dump(300000), now), false)
  assert.equal(Ks.crashedRecently(dump(30000, "/usr/bin/python3"), now), false)
  assert.equal(Ks.crashedRecently(dump(-5000), now), false)
  assert.equal(Ks.crashedRecently("", now), false)
  assert.equal(Ks.crashedRecently("No coredumps found.", now), false)
})

test("batto: a crest per top-level menu, in the menu's order; actions and submenus have none", () => {
  const items = {
    root: { parent: "", kind: "menu" }, apps: { parent: "root", label: "Apps", provider: "apps" },
    style: { parent: "root", label: "Style" }, "style.theme": { parent: "style", label: "Theme" },
    about: { parent: "root", label: "About", action: "omarchy-launch-about" },
    hanko: { parent: "root", label: "判子 Hanko", kind: "menu" }, odd: { parent: "root", label: "Odd", kind: "menu" }
  }
  const order = ["root", "apps", "style", "style.theme", "about", "hanko", "odd"]
  const count = id => order.filter(k => (items[k].parent || "") === id).length
  assert.deepEqual(Bt.rail(items, order, count).map(r => [r.id, r.crest]), [["apps", "器"], ["style", "彩"], ["hanko", "判"], ["odd", "文"]])
  assert.equal(Bt.topOf("style.theme.font"), "style")
  assert.equal(Bt.topOf("root"), "root")
  assert.equal(Bt.crestFor("system", "System"), "政")
})

test("Paths: a plugin file as a path, from file:// or qs://", () => {
  assert.equal(Pa.local("file:///home/a/hanko.bar/scripts/hanko"), "/home/a/hanko.bar/scripts/hanko")
  assert.equal(Pa.local("qs:///home/a/.config/omarchy/plugins/hanko.bar/scripts/hanko"), "/home/a/.config/omarchy/plugins/hanko.bar/scripts/hanko")
  assert.equal(Pa.local("qs:///home/a/my%20dots/hanko"), "/home/a/my dots/hanko")
  assert.equal(Pa.local("/already/a/path"), "/already/a/path")
  assert.equal(Pa.local(undefined), "")
})


// ── The mission overview (core/Mission.js) ──────────────────────────────
const Mi = load("core/Mission.js", ["layout", "order", "neighbour", "windowsOf", "stripKeys", "idOfKey", "freeId", "stripCell", "stepId",
  "score", "find", "menuEntries", "evaluate", "format", "CATEGORIES", "KEYS"])

test("mission: the spread fits the room, keeps sizes and reads in the desk's order", () => {
  const area = { x: 0, y: 0, w: 1000, h: 500 }
  const r = Mi.layout([{ key: "a", w: 800, h: 900, cx: 400, cy: 450 }, { key: "b", w: 800, h: 900, cx: 1200, cy: 450 }], area, { gap: 20 })
  assert.equal(r.rows, 1)
  assert.ok(r.slots.a.x < r.slots.b.x)
  assert.equal(r.slots.a.w, r.slots.b.w)
  for (const k of ["a", "b"]) assert.ok(r.slots[k].x >= 0 && r.slots[k].x + r.slots[k].w <= 1000 && r.slots[k].y + r.slots[k].h <= 500)
  // Four quarters in a 10:7 room go to two rows.
  const q = Mi.layout([0, 1, 2, 3].map(i => ({ key: "w" + i, w: 400, h: 300, cx: (i % 2) * 400, cy: Math.floor(i / 2) * 300 })), { x: 0, y: 0, w: 1000, h: 700 }, { gap: 10 })
  assert.equal(q.rows, 2)
  assert.deepEqual(Mi.order(q.slots), ["w0", "w1", "w2", "w3"])
  assert.deepEqual(Mi.layout([], area, {}).slots, {})
})

test("mission: arrows pick the neighbour in line", () => {
  const rects = [{ x: 0, y: 0, w: 10, h: 10 }, { x: 20, y: 0, w: 10, h: 10 }, { x: 0, y: 20, w: 10, h: 10 }]
  assert.equal(Mi.neighbour(rects, 0, "right"), 1)
  assert.equal(Mi.neighbour(rects, 0, "down"), 2)
  assert.equal(Mi.neighbour(rects, 0, "left"), -1)
  assert.equal(Mi.neighbour(rects, 9, "left"), 0)
})

test("mission: the live space's windows, tiled under floating", () => {
  const spaces = [{ id: 3, all: [{ address: "f", floating: true, focus: 0 }, { address: "a", focus: 2 }, { address: "b", focus: 1 }] }]
  assert.deepEqual(Mi.windowsOf(spaces, 3).map(w => w.address), ["a", "b", "f"])
  assert.deepEqual(Mi.windowsOf(spaces, 4), [])
})

test("mission: the strip, the new space and stepping", () => {
  const keys = Mi.stripKeys([{ id: 3 }, { id: 1 }, { id: -98 }], 5)
  assert.deepEqual(keys, ["ws:1", "ws:3", "ws:5", "new"])
  assert.equal(Mi.idOfKey("ws:3"), 3)
  assert.equal(Mi.idOfKey("new"), -1)
  assert.equal(Mi.freeId([1, 2, 4]), 3)
  assert.equal(Mi.stepId(keys, 3, 1), 5)
  assert.equal(Mi.stepId(keys, 5, 1), -1)
  assert.equal(Mi.stepId(keys, 1, -1), -1)
  const c = Mi.stripCell(4, 100, 2000, 0.5, 10)
  assert.equal(c.w, 200)
  assert.equal(c.h, 100)
  assert.ok(Mi.stripCell(40, 100, 1000, 0.5, 10).w < 25)
})

test("mission: search finds sums, windows, apps and menu leaves", () => {
  assert.equal(Mi.evaluate("2 + 3 * 4"), 14)
  assert.equal(Mi.evaluate("(1+1)^3"), 8)
  assert.equal(Mi.evaluate("sqrt(16)"), 4)
  assert.equal(Mi.evaluate("12"), null)
  assert.equal(Mi.evaluate("firefox"), null)
  assert.equal(Mi.evaluate("2 +"), null)
  assert.equal(Mi.format(0.1 + 0.2), "0.3")
  assert.equal(Mi.score("Firefox web", "Firefox", ["fire"]), 3)
  assert.equal(Mi.score("Firefox web", "Firefox", ["chrome"]), -1)
  const menu = Mi.menuEntries('{ "items": { "style": { "label": "Style" }, "style.bg": { "label": "Background", "action": "omarchy-theme-bg-next", }, \n // a note\n "x": { "label": "Hidden", "action": "y", "when": "z" } } }', "")
  assert.deepEqual(menu.map(e => e.label), ["Background"])
  assert.equal(menu[0].path, "Style")
  const r = Mi.find("back", { spaces: [{ id: 2, all: [{ address: "0x1", name: "Firefox", title: "Backend docs" }] }],
    apps: [{ id: "a.desktop", name: "Backup" }, { id: "h.desktop", name: "Back hidden", noDisplay: true }], menu })
  assert.deepEqual(r.map(x => x.kind), ["window", "app", "menu"])
  assert.equal(Mi.find("1+1", {})[0].value, "2")
  assert.deepEqual(Mi.find("  ", {}), [])
  for (const k of ["calc", "window", "app", "menu"]) assert.ok(Mi.CATEGORIES[k].jp)
})

test("desk: the CLI never wires style.lua into looknfeel.lua, and takes out the line it once added", () => {
  const sh = readFileSync(join(root, "scripts/hanko"), "utf8")
  assert.ok(!/>>\s*"\$LOOK_FILE"/.test(sh), "hanko desk must not append to looknfeel.lua")
  assert.ok(sh.includes("post-boot.d/50-hanko-desk"), "the desk comes back after a boot")
  const dir = mkdtempSync(join(tmpdir(), "hanko-desk-"))
  try {
    mkdirSync(join(dir, "hypr"))
    const mine = "-- mine\nhl.config({})\n\nif bar == \"hanko\" then\n  pcall(dofile, \"x/hanko.bar/style.lua\")\nend\n\n\n"
    const legacy = "\n-- Kaze 風: Hanko's look and motion for the whole desk (hanko desk off removes it).\n" +
      "pcall(dofile, os.getenv(\"HOME\") .. \"/.config/omarchy/plugins/hanko.bar/style.lua\") -- hanko desk\n"
    const file = join(dir, "hypr/looknfeel.lua")
    writeFileSync(file, mine + legacy)
    const fns = sh.split("\n").filter(l => /^(say\(\)|LOOK_FILE=)/.test(l)).join("\n") + "\n" +
      sh.slice(sh.indexOf("look_legacy_off() {"), sh.indexOf("\n}\n", sh.indexOf("look_legacy_off() {")) + 3) +
      sh.slice(sh.indexOf("style_loaded() {"), sh.indexOf("\n", sh.indexOf("style_loaded() {")) + 1)
    const run = body => execFileSync("bash", ["-c", fns + body], { env: { ...process.env, XDG_CONFIG_HOME: dir } }).toString()
    run("look_legacy_off >/dev/null")
    assert.equal(readFileSync(file, "utf8"), mine)
    assert.equal(run("look_legacy_off || echo none").trim(), "none")
    assert.equal(run("style_loaded && echo yes").trim(), "yes")
    writeFileSync(file, "-- pcall(dofile, \"x/hanko.bar/style.lua\")\n")
    assert.equal(run("style_loaded || echo no").trim(), "no")
  } finally { rmSync(dir, { recursive: true, force: true }) }
})

const Cu = load("core/Cursor.js", ["start", "reading", "move", "nearest", "action", "KEYS", "sameLine", "at"])

test("cursor: a ledger's rows, a ruler and the foot's buttons", () => {
  // Master ruler with Mute beside it, two outputs, then three buttons.
  const stops = [
    { x: 100, y: 0, w: 200, h: 26, step: true },   // 0 ruler
    { x: 320, y: 2, w: 60, h: 22 },                // 1 Mute
    { x: 0, y: 60, w: 380, h: 46, chosen: true },  // 2 output (in use)
    { x: 0, y: 106, w: 380, h: 46 },               // 3 output
    { x: 120, y: 180, w: 80, h: 28 },              // 4 Mute mic
    { x: 210, y: 180, w: 80, h: 28 },              // 5 Next output
    { x: 300, y: 182, w: 80, h: 24 }               // 6 a shorter one on the same line
  ]
  assert.equal(Cu.start(stops), 0)
  assert.deepEqual(Cu.reading(stops), [0, 1, 2, 3, 4, 5, 6])
  assert.equal(Cu.move(stops, 0, 1, 0), 1)
  assert.equal(Cu.move(stops, 1, 1, 0), 1, "the edge stops the cursor")
  assert.equal(Cu.move(stops, 1, -1, 0), 0)
  assert.equal(Cu.move(stops, 0, 0, 1), 2)
  assert.equal(Cu.move(stops, 2, 0, 1), 3)
  assert.equal(Cu.move(stops, 3, 0, 1), 4, "the button under the row's start")
  assert.equal(Cu.move(stops, 5, 1, 0), 6, "a ragged line is still one line")
  assert.equal(Cu.move(stops, 6, 0, 1), 6)
  assert.equal(Cu.move(stops, 6, 0, -1), 3)
  assert.equal(Cu.move(stops, 2, 0, -1), 0)
  assert.equal(Cu.move(stops, -1, 0, 1), 0, "no cursor yet: it shows where it starts")
  assert.equal(Cu.move([], 0, 0, 1), -1)
})

test("cursor: slips on a rail, then the foot", () => {
  const slips = [0, 1, 2, 3].map(i => ({ x: i * 48, y: 0, w: 40, h: 200 - i * 20 }))
  const stops = slips.concat([{ x: 150, y: 240, w: 80, h: 28 }])
  assert.equal(Cu.start(stops), 0)
  assert.equal(Cu.move(stops, 0, 1, 0), 1)
  assert.equal(Cu.move(stops, 3, 0, 1), 4)
  assert.equal(Cu.move(stops, 4, 0, -1), 3, "back up to the slip above")
  assert.equal(Cu.start(stops.map((s, i) => Object.assign({}, s, { chosen: i === 2 }))), 2)
})

test("cursor: a rail beside a page (loose), and the stop under the pointer", () => {
  const stops = [
    { x: 0, y: 0, w: 200, h: 40 }, { x: 0, y: 40, w: 200, h: 40 }, { x: 0, y: 80, w: 200, h: 40 },  // the rail
    { x: 300, y: 100, w: 400, h: 30 }, { x: 300, y: 400, w: 400, h: 30 }                            // the page
  ]
  assert.equal(Cu.move(stops, 1, 1, 0), 1, "strict: nothing on the line")
  assert.equal(Cu.move(stops, 1, 1, 0, true), 3, "loose: across to the page")
  assert.equal(Cu.move(stops, 4, -1, 0, true), 2, "and back to the rail item nearest its row")
  const panes = stops.map((st, i) => Object.assign({ pane: i < 3 ? 0 : 1 }, st))
  panes.push({ x: 300, y: 150, w: 100, h: 30, pane: 1 })
  assert.equal(Cu.move(panes, 3, 0, 1), 5, "down stays on the page")
  assert.equal(Cu.move(panes, 4, 0, 1), 4, "and stops at its foot, not in the rail")
  assert.equal(Cu.at(stops, { x: 310, y: 110 }), 3)
  assert.equal(Cu.at(stops, { x: 250, y: 10 }), -1)
  const nested = [{ x: 0, y: 0, w: 100, h: 100 }, { x: 10, y: 10, w: 20, h: 20 }]
  assert.equal(Cu.at(nested, { x: 15, y: 15 }), 1, "the innermost part")
})

test("cursor: the nearest stop after the parts are made anew, and the keys", () => {
  const stops = [{ x: 0, y: 0, w: 10, h: 10 }, { x: 0, y: 50, w: 10, h: 10 }]
  assert.equal(Cu.nearest(stops, { x: 5, y: 48 }), 1)
  assert.equal(Cu.nearest([], { x: 0, y: 0 }), -1)
  const K = Cu.KEYS
  assert.deepEqual(Cu.action(K.Down, "", false), { kind: "move", dx: 0, dy: 1 })
  assert.deepEqual(Cu.action(0, "k", false), { kind: "move", dx: 0, dy: -1 })
  assert.deepEqual(Cu.action(0, "h", false), { kind: "move", dx: -1, dy: 0 })
  assert.deepEqual(Cu.action(K.Tab, "", true), { kind: "tab", dir: -1 })
  assert.deepEqual(Cu.action(K.Backtab, "", false), { kind: "tab", dir: -1 })
  assert.deepEqual(Cu.action(K.Space, " ", false), { kind: "activate" })
  assert.deepEqual(Cu.action(K.Escape, "", false), { kind: "close" })
  assert.equal(Cu.action(0, "m", false), null, "a sheet's own letters pass through")
})

// Ōin 押印, the boot screen: Plymouth's script language is interpreted
// (assets/boot/plyscript.mjs) so the theme runs here without plymouthd.
{
  const { Interpreter } = await import("../assets/boot/plyscript.mjs")
  const sim = await import("../assets/boot/sim.mjs")
  const runs = src => { try { new Interpreter({}).run(src); return "" } catch (e) { return e.message } }
  test("boot: the interpreter refuses what Plymouth would get wrong", () => {
    // One name space: a global named like a function replaces it.
    assert.match(runs("fun fit(i) { return i; }\nglobal.fit = 1;\nx = fit(2);"), /not a function/)
    assert.match(runs("a = [1, 2];"), /array literal/)
    assert.match(runs("fun f() { return y + 1; }\nf();"), /'y' is read before it is set/)
    assert.match(runs("x = 1"), /expected ';'/)
    // What Plymouth does do: hashes made on assignment, locals and globals,
    // a string and a number joined, the empty array, i++ on a member.
    const p = new Interpreter({})
    p.run('a.b[3] = 2; n = []; global.k = 0; fun f(v) { k = v; local.t = 1; global.k++; return "n" + v; } s = f(7);')
    assert.equal(p.global.get("a").get("b").get("3"), 2)
    assert.equal(p.global.get("s"), "n7")
    assert.equal(p.global.get("k"), 8, "k found in the globals, so the function set it there, then ++")
    assert.equal(p.global.has("t"), false, "a function's local stays in it")
  })
  const tool = cmd => { try { execFileSync(cmd, ["-version"], { stdio: "ignore" }); return true } catch { return false } }
  test("boot: the theme draws and plays every path a boot takes", () => {
    if (!tool("magick")) return
    const dir = mkdtempSync(join(tmpdir(), "hanko-boot-"))
    try {
      const empty = mkdtempSync(join(tmpdir(), "hanko-boot-config-"))
      execFileSync(join(root, "scripts/hanko-boot"), ["build", dir],
        { env: { ...process.env, XDG_CONFIG_HOME: empty, HANKO_BOOT_HEIGHT: "1080", HANKO_BOOT_COLORS: join(root, "theme/colors.toml") }, stdio: "pipe" })
      rmSync(empty, { recursive: true, force: true })
      const script = readFileSync(join(dir, "hanko.script"), "utf8")
      assert.doesNotMatch(script, /@[A-Z_]+@/, "every number filled in")
      sim.check(dir)
      // Shutting down: 終 whole, "The end", the seal; no hairline, no corner.
      const s = sim.boot(dir, { mode: "shutdown" }); s.tick(60)
      assert.deepEqual(s.visible().map(x => x.image.src.split("/").pop()).sort(),
        ["end-0.png", "stamp.png", "sub-shutdown.png", "words-end.png"])
      // No picture of the old seal mark is drawn or asked for.
      assert.ok(!existsSync(join(dir, "seal-7.png")) && !/seal-[0-9]/.test(script))
      // A wrong passphrase: the red hint with its count, and the spark.
      const b = sim.boot(dir); b.tick(70, { held: true }); b.password(0); b.tick(1, { held: true })
      const hint = () => b.visible().map(x => x.image.src.split("/").pop()).find(f => f.startsWith("hint-"))
      assert.equal(hint(), "hint-type.png")
      b.password(5); b.tick(1, { held: true }); assert.equal(hint(), "hint-enter.png")
      // Settings › Boot draws the same nicks (core/Oin.js).
      for (const n of [5, 20]) {
        b.password(n); b.tick(1, { held: true })
        const ruleX = b.global("rule_x")
        const xs = b.visible().filter(x => x.image.src.endsWith("nick.png")).map(x => x.x - ruleX)
        assert.deepEqual(xs, Oi.nicks(n), `nicks for ${n} keys`)
      }
      b.password(5); b.tick(1, { held: true })
      b.normal(); b.tick(5, { held: true }); assert.equal(hint(), "hint-check.png")
      b.password(0); b.tick(1, { held: true }); assert.equal(hint(), "hint-wrong-1.png")
      assert.ok(b.visible().some(x => x.image.src.endsWith("spark.png")))
      // The right one: Plymouth's clock runs again, the rule is progress.
      b.password(4); b.normal(); b.tick(30)
      assert.equal(b.global("state"), "booting")
      assert.ok(b.visible().some(x => x.image.src.endsWith("notch.png")))
      assert.equal(hint(), undefined)
      // The blade lies on the hairline (it was once left at the screen's corner).
      {
        const t = sim.boot(dir); t.tick(70, { held: true }); t.password(6); t.tick(1, { held: true })
        const blade = t.visible().find(x => x.image.src.endsWith("ink.png") && x.image.w === Oi.bladeWidth(6))
        assert.ok(blade, "a blade")
        assert.deepEqual([blade.x, blade.y], [t.global("rule_x"), t.global("rule_y")], "the blade on the hairline")
      }
      // The brush: 始 written, its seal and words; at shutdown 終, "The end".
      const names = t => t.visible().map(x => x.image.src.split("/").pop())
      const up = sim.boot(dir); up.tick(80, { held: true })
      for (const f of ["brush-19.png", "stamp.png", "words-start.png", "sub-start.png"]) assert.ok(names(up).includes(f), f)
      const early = sim.boot(dir); early.tick(20, { held: true })
      assert.ok(names(early).some(f => /^brush-[0-9]\.png$/.test(f)), "written stroke by stroke")
      assert.ok(!names(early).includes("stamp.png"), "the seal after the strokes")
      const down = sim.boot(dir, { mode: "reboot" }); down.tick(40)
      for (const f of ["end-0.png", "words-end.png", "sub-reboot.png", "stamp.png"]) assert.ok(names(down).includes(f), f)
      assert.ok(!names(down).some(f => f.startsWith("brush-")))
      // The script's words sit beside the kanji, centred with it as a row.
      const kanji = up.visible().find(x => x.image.src.endsWith("brush-19.png"))
      const words = up.visible().find(x => x.image.src.endsWith("words-start.png"))
      assert.equal(words.x, kanji.x + Oi.LAYOUT.brush + Oi.LAYOUT.brushGap)
      const row = Oi.LAYOUT.brush + Oi.LAYOUT.brushGap + Math.max(words.image.w, up.visible().find(x => x.image.src.endsWith("sub-start.png")).image.w)
      assert.ok(Math.abs(kanji.x + row / 2 - 960) <= 1, "the row centred")
    } finally { rmSync(dir, { recursive: true, force: true }) }
  })
  test("boot: the CLI checks the theme before it installs, and goes back to the theme it replaced", () => {
    const cli = readFileSync(join(root, "scripts/hanko"), "utf8")
    const on = cli.slice(cli.indexOf("cmd_boot() {"), cli.indexOf("    off)", cli.indexOf("cmd_boot() {")))
    assert.ok(on.indexOf("sim.mjs\" --check") > 0 && on.indexOf("sim.mjs\" --check") < on.indexOf("as_root"), "the check comes first")
    assert.match(cli, /printf '%s\\n' "\$\{now:-omarchy\}" > "\$BOOT_BEFORE"/)
    assert.match(cli, /\|\| back=omarchy/)
    assert.match(cli, /if ! rebuild; then[\s\S]*plymouth-set-default-theme "\$before"/, "a failed rebuild goes back")
  })
}

test("boot page: the layout is the one hanko-boot draws, the blade the lock's", () => {
  const cli = readFileSync(join(root, "scripts/hanko-boot"), "utf8")
  const num = name => Number((new RegExp(`(?:^|; )${name}=([0-9.]+)`, "m").exec(cli) || [])[1])
  const L = Oi.LAYOUT
  assert.deepEqual([L.rule, L.hintGap, L.nick, L.lead, L.nickH, L.hiltH, L.corner],
    ["RULE_W", "HINT_GAP", "NICK", "LEAD", "NICK_H", "HILT_H", "CORNER"].map(num))
  assert.deepEqual([L.brush, L.brushAt, L.brushGap, L.brushRuleGap, L.brushFrames, L.stamp, L.wordsGap],
    ["BRUSH", "BRUSH_AT", "BRUSH_GAP", "BRUSH_RULE_GAP", "BRUSH_FRAMES", "STAMP", "WORDS_GAP"].map(num))
  assert.equal(L.nick, Tj.NICK); assert.equal(L.lead, Tj.LEAD)
  for (const n of [0, 1, 5, 14, 15, 40]) {
    assert.equal(Oi.bladeWidth(n), Tj.bladeWidth(n, L.rule), `width ${n}`)
    assert.ok(Oi.nicks(n).every(x => x <= Oi.bladeWidth(n) - 8), `nicks ${n}`)
  }
  assert.equal(Oi.nicks(40).length, 15, "a long passphrase stops at the rule")
  assert.equal(Oi.hint("password", 0, 0), "hint-type")
  assert.equal(Oi.hint("password", 3, 1), "hint-enter")
  assert.equal(Oi.hint("wrong", 0, 12), "hint-wrong-9", "the pictures stop at nine")
  assert.equal(Oi.hint("booting", 0, 0), "")
  // Every hint the page asks for is a picture hanko-boot draws.
  for (const f of ["hint-type.png", "hint-enter.png", "hint-check.png", "hint-wrong-$i.png", "for i in 1 2 3 4 5 6 7 8 9"]) assert.ok(cli.includes(f), f)
})

test("boot page: one boot played, the moments, and when the installed screen is out of date", () => {
  let last = -1
  const order = ["still", "password", "checking", "wrong", "password", "checking", "booting"]
  const seen = []
  for (let t = 0; t <= Oi.STORY_MS; t += 50) {
    const o = Oi.story(t)
    if (seen[seen.length - 1] !== o.state) seen.push(o.state)
    if (o.state === "booting") { assert.ok(o.progress >= last); last = o.progress }
  }
  assert.deepEqual(seen, order)
  assert.ok(last > 0.69 && last <= 0.7)
  assert.deepEqual(Oi.MOMENTS.map(m => m.key), ["asked", "typing", "wrong", "booting", "shutdown"])
  for (const m of Oi.MOMENTS) assert.ok(Oi.moment(m.key).state)
  const drawn = { theme: "catppuccin", glyph: "鑑", name: "name", press: "ink", mark: "brush", at: "2026-10-22T16:00:00+05:30" }
  const pretty = s => s[0].toUpperCase() + s.slice(1)
  assert.equal(Oi.stale(drawn, { theme: "catppuccin", glyph: "鑑", name: "name", press: "ink" }), "")
  assert.equal(Oi.stale(drawn, { theme: "hanko", glyph: "鑑" }, pretty), "Drawn for Catppuccin; your theme is Hanko now")
  assert.match(Oi.stale(drawn, { theme: "catppuccin", glyph: "漢" }), /your seal is 漢/)
  assert.match(Oi.stale(drawn, { theme: "catppuccin", name: "none" }), /corner/)
  // A screen drawn with the old seal (a record with no mark, or "seal") is out of date.
  assert.match(Oi.stale(Object.assign({}, drawn, { mark: undefined }), { theme: "catppuccin" }), /old seal/)
  assert.match(Oi.stale(Object.assign({}, drawn, { mark: "seal" }), { theme: "catppuccin" }), /old seal/)
  assert.deepEqual(Se.BOOT_CHOICES.map(c => c.key), ["bootName", "bootPress"], "no mark to choose: the brush only")
  assert.equal(Oi.stale({}, { theme: "x" }), "", "nothing installed: nothing to be out of date")
  assert.equal(Oi.day("2026-10-22T16:00:00+05:30"), "22 October")
  // The page's two choices read and say like the Kaze switches, and aren't counted there.
  assert.equal(Se.kazeValue({}, "bootName"), "name")
  assert.equal(Se.kazeValue({ bootPress: "still" }, "bootPress"), "still")
  assert.equal(Se.kazeValue({ bootPress: "nope" }, "bootPress"), "ink")
  assert.equal(Se.kazeChange({}, { bootName: "none" }), "Boot corner · name → none")
  assert.deepEqual(Se.kazeOn({ bootName: "none", bootPress: "still" }, false, false, false), Se.kazeOn({}, false, false, false))
  assert.ok(Se.pageInfo("boot").page.jp === "押印" && Se.PAGE_LINES.boot)
})

{
  const brush = await import("../assets/boot/brush.mjs")
  test("boot brush: the shutdown ceremony's hand, and 始 in its stroke order", () => {
    // The ceremony's Canvas (plugins/hanko.osd) and the boot's SVG draw one stroke.
    const osd = readFileSync(join(root, "plugins/hanko.osd/Osd.qml"), "utf8")
    assert.ok(osd.includes("var w = t < 0.12 ? 0.8 + t / 0.12 * 0.2 : (t > 0.7 ? 1 - (t - 0.7) / 0.3 * 0.62 : 1)"))
    assert.ok(osd.includes("var base = width * 0.062"))
    const ceremony = t => t < 0.12 ? 0.8 + t / 0.12 * 0.2 : (t > 0.7 ? 1 - (t - 0.7) / 0.3 * 0.62 : 1)
    for (const t of [0, 0.05, 0.12, 0.5, 0.7, 0.85, 1]) assert.equal(brush.width(t), ceremony(t))
    const { STROKES } = brush.strokes()
    assert.equal(STROKES["始"].length, 8, "始 has eight strokes")
    assert.equal(STROKES["終"].length, 11)
    const half = brush.svg("始", 432, "#ddd5c7", 4), whole = brush.svg("始", 432, "#ddd5c7", 8)
    assert.ok(half.split("<line").length < whole.split("<line").length, "half written is fewer marks")
    assert.match(whole, /stroke-width="26\.78"/, "full width: 6.2% of the box")
  })
}

test("koyomi: the month in six weeks, its terms, moons and weather, and the picked day's leaf", () => {
  const lib = { Se: Sn, Al: AlM }
  const now = new Date(2026, 9, 23, 14, 0)
  const k = Ky.sheet(now, 0, null, lib)
  assert.equal(k.weeks.length, 6, "always six weeks, so a turn never changes the height")
  assert.ok(k.weeks.every(w => w.length === 7))
  assert.equal(k.weeks[0][0].dow, 0, "Monday first")
  assert.deepEqual([k.view.wafu, k.view.romaji, k.view.jp], ["神無月", "Kannazuki", "十月"])
  const days = k.weeks.flat()
  assert.equal(days.filter(c => c.inMonth).length, 31)
  assert.equal(days.filter(c => c.today).length, 1)
  const term = d => days.find(c => c.inMonth && c.day === d).term
  // 2026: 寒露 on 8 October, 霜降 on 23 October (the real dates, from the sun).
  assert.equal(term(8), "寒露")
  assert.equal(term(23), "霜降")
  assert.equal(days.filter(c => c.inMonth && c.term).length, 2)
  assert.equal(days.find(c => c.inMonth && c.moon === "full").day, 26, "the full moon of 26 October 2026")
  // The leaf: first day of 霜降 and of its first kō, autumn's last term.
  assert.equal(k.leaf.sekki.jp, "霜降")
  assert.equal(k.leaf.sekki.day, 1)
  assert.equal(k.leaf.ko.jp, "霜始降")
  assert.equal(k.leaf.ko.no, 52)
  assert.equal(k.leaf.season.key, "autumn")
  assert.equal(k.leaf.next.jp, "立冬")
  assert.equal(k.leaf.next.in, 15, "立冬 on 7 November")
  assert.equal(k.leaf.when, "Today")
  assert.equal(k.moved, false)
  // The year: twelve months, two terms each, autumn's three marked.
  assert.equal(k.year.length, 12)
  assert.ok(k.year.every(m => m.terms.length === 2))
  assert.deepEqual(k.year.filter(m => m.season === "autumn").map(m => m.m), [7, 8, 9])
  assert.equal(k.year.find(m => m.current).m, 9)
  assert.deepEqual(Ky.WAFU.map(w => w[0]).slice(0, 3), ["睦月", "如月", "弥生"])
})

test("koyomi: moves by day, week, month and year stay inside the month; the year rail and today", () => {
  const now = new Date(2026, 0, 31, 9)
  assert.equal(Ky.step(now, 0, "day+"), 1)
  assert.equal(Ky.step(now, 3, "week-"), -4)
  assert.equal(Ky.step(now, 0, "month+"), 28, "31 January → 28 February")
  assert.equal(Ky.step(now, 0, "month-"), -31, "→ 31 December")
  assert.equal(Ky.step(now, 0, "year+"), 365)
  assert.equal(Ky.step(now, 40, "today"), 0)
  assert.equal(Ky.toMonth(now, 0, 0), 0, "this month is today")
  assert.equal(Ky.toMonth(now, 0, 3), 89, "30 April")
  const later = Ky.sheet(now, 28, null, { Se: Sn, Al: AlM })
  assert.equal(later.view.m, 1)
  assert.equal(later.monthsAway, 1)
  assert.equal(later.leaf.when, "In 28 days")
  assert.equal(later.weeks.flat().filter(c => c.picked).length, 1)
  assert.equal(Ky.addMonths(new Date(2024, 0, 31), 1).getDate(), 29, "a leap February")
})

test("koyomi: day numbers in kanji, and the sky from Open-Meteo", () => {
  assert.deepEqual([1, 6, 10, 11, 16, 20, 23, 30, 31].map(Ky.kanjiDay), ["一", "六", "十", "十一", "十六", "二十", "二十三", "三十", "三十一"])
  assert.deepEqual([0, 2, 3, 45, 53, 63, 75, 81, 86, 96].map(c => Ky.sky(c).jp), ["晴", "曇", "曇", "霧", "雨", "雨", "雪", "雨", "雪", "雷"])
  assert.equal(Ky.sky(null), null)
  assert.equal(Ky.sky(123), null, "not a WMO code")
  assert.equal(Ky.wind(40).from, "north-east")
  assert.equal(Ky.wind(350).jp, "北風")
  const raw = { current: { temperature_2m: 14.2, apparent_temperature: 12.6, weather_code: 1, wind_speed_10m: 11.4, wind_direction_10m: 200, is_day: 0 },
                daily: { time: ["2026-10-23", "2026-10-24"], weather_code: [61, 0], temperature_2m_max: [18.4, 20], temperature_2m_min: [9.6, 11], precipitation_probability_max: [80, null] } }
  const f = Ky.forecast(JSON.stringify(raw), false)
  assert.deepEqual(f.now, { temp: "14°", feels: "13°", jp: "晴", word: "Fair", wind: { jp: "南風", from: "south" }, speed: 11, day: false })
  assert.deepEqual(f.days["2026-10-23"], { jp: "雨", word: "Rain", hi: "18°", lo: "10°", rain: 80 })
  assert.equal(f.days["2026-10-24"].rain, -1, "no chance given")
  assert.equal(Ky.forecast(raw, true).now.temp, "58°", "Fahrenheit")
  assert.deepEqual(Ky.forecast("not json", false), { now: null, days: {} })
  // On the grid: the forecast lands on its day.
  const k = Ky.sheet(new Date(2026, 9, 23, 8), 0, f, { Se: Sn, Al: AlM })
  assert.equal(k.weeks.flat().find(c => c.key === "2026-10-23").sky.jp, "雨")
  assert.equal(k.leaf.now.temp, "14°", "today's leaf has the weather now")
  assert.ok(Ky.url(25.6, 85.1).includes("forecast_days=16") && Ky.url(25.6, 85.1).includes("daily=weather_code"))
  assert.ok(Ky.geocodeUrl("Patna").endsWith("name=Patna"))
  assert.deepEqual(Ky.geocoded(JSON.stringify({ results: [{ name: "Patna", country: "India", latitude: 25.6, longitude: 85.1 }] })),
                   { name: "Patna", country: "India", latitude: 25.6, longitude: 85.1 })
  assert.equal(Ky.geocoded("{}"), null)
  assert.equal(Ky.imperial("en_US.UTF-8", ""), true)
  assert.equal(Ky.imperial("en_US.UTF-8", "India"), false, "the place's country wins")
  assert.equal(Ky.imperial("de_DE", ""), false)
})

test("koyomi: the calendar and weather settings, beside the twenty-one", () => {
  assert.equal(S.resolve({}).calendar, "koyomi")
  assert.equal(S.resolve({}).weather, "on")
  assert.equal(S.resolve({ calendar: "week", weather: "off" }).calendar, "week")
  assert.equal(S.resolve({ calendar: "nope" }).calendar, "koyomi")
  const d = S.withSetting({}, "calendar", "week")
  assert.equal(d.calendar, "week")
  assert.equal(S.withSetting(d, "weather", "off").weather, "off")
  assert.equal(S.withSetting({}, "calendar", "month"), null)
  assert.equal(S.resolve(S.withPreset(d, "Quiet")).calendar, "week", "a preset keeps it")
})

console.log(`${passed} passed${process.exitCode ? ", some failed" : ""}`)
