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

const S = load("core/Style.js", ["OPTIONS", "MOTIONS", "TYPE_SIZES", "TYPE_SCALE", "KEYS", "PRESETS", "PRESET_NAMES", "DEFAULT_PRESET",
  "coerce", "normalize", "resolve", "withSetting", "withPreset", "shuffled", "combinations", "withMonitorSetting",
  "shows", "withShown", "SHOW_OPTIONS"])
const Se = load("core/Settings.js", ["ENDLEAVES", "endleafOf", "endleafLabels", "interludeLabels", "interludeOf", "RAIL", "CARDS", "MOTION_CARD", "MOTION_OPTIONS", "MOTION_ROWS", "GLYPHS", "PRESET_BLURBS", "optionsFor", "nameOf", "selected", "changes",
  "status", "presetLine", "matches", "pageMatches", "visibilityCards", "prettyId"])
const I = load("core/InkMath.js", ["TIERS", "contrast", "tier", "ramp", "mix", "isLight", "kata"])
const T = load("core/Title.js", ["appName", "describe", "tildify"])
const W = load("core/Spaces.js", ["numeral", "folio", "layoutOf", "usableArea", "list"])
const St = load("core/Status.js", ["ticks", "bars", "network", "volume", "battery", "brightness",
  "stampGlyph", "tilt", "notifications", "count2", "LOW_BATTERY", "age"])
const Sh = load("core/Sheets.js", ["SHEETS", "byKey", "forCell", "forOmarchyId", "omarchyIdForCell", "step", "panelAt", "place"])
const Tm = load("core/Time.js", ["dayOfYear", "daysInYear", "isoWeek", "leftInDay", "heading", "ribbon", "parseZones",
  "zonesFromBarConfig", "probeCommand", "parseProbe", "relative", "zoneRow", "ordinal", "counted", "dayAcross"])
const So = load("core/Sound.js", ["friendly", "label", "bus", "detail", "outputs", "streams", "master", "inputNote", "sheet"])
const N = load("core/Net.js", ["splitTerse", "parseWifi", "parseSaved", "band", "securityName", "connectHow", "sheet", "remember", "KEEP_MS"])
const Pw = load("core/Power.js", ["keyValues", "profiles", "stateLabel", "blurb", "details", "sheet"])
const Sc = load("core/Scroll.js", ["SECTIONS", "INTERLUDE", "indexOf", "forCell", "layout", "centred", "nearest",
  "clampTrack", "landing", "position"])
const Lf = load("core/Leaf.js", ["KINDS", "kindOf", "labels", "uptime", "uptimeShort", "themeName", "colophon", "almanac", "moon",
  "cpuTimes", "cpuBusy", "memory", "temperature", "disk", "top", "bytes", "machine", "SESSION", "sessionAction", "themes", "themeWindow",
  "themesView", "TOOLS", "tool", "toolsLine", "focusState", "focusStep", "focusView", "clock", "notes", "toggled", "notesView", "clipboard",
  "afterword", "SEKKI", "KO"])
const H = load("core/Hosted.js", ["DRAWN", "OWN", "entries", "hosted", "own", "cell", "idOfCell"])
const X = load("core/Extras.js", ["INDICATORS", "indicators", "moduleJson", "keyboard", "tray"])
const D = load("core/Display.js", ["monitors", "brightness", "target", "sheet"])
const B = load("core/Blue.js", ["human", "kind", "row", "lists", "cell", "action", "sheet", "mark"])
const E = load("core/Edge.js", ["dayFraction", "hourTicks", "at", "span", "pulled", "PULL_THRESHOLD"])
const Sn = load("core/Season.js", ["SEKKI", "KO", "sunLongitude", "koIndex", "at", "label"])
const Sk = load("core/Skin.js", ["skin", "TEMPOS", "RADII"])
const Br = load("core/Brush.js", ["stroke", "kasure", "enso", "noise"])
const K = load("core/Kata.js", ["PARTS", "PART_KEYS", "MAIN_PARTS", "AUTO", "TOUCHES", "DESIGNS", "DESIGN_NAMES", "DEFAULT_DESIGN",
  "resolve", "withDesign", "withBorrow", "withTouch", "surprised", "describe", "clean", "designName"])

let passed = 0
function test(name, fn) {
  try { fn(); passed++ } catch (e) { console.error(`FAIL ${name}\n  ${e.message}`); process.exitCode = 1 }
}

test("twenty-two settings, 61,917,364,224 combinations (COMPONENTS.md §5)", () => {
  assert.equal(S.KEYS.length, 22)
  assert.equal(S.combinations(), 61917364224)
})

test("indicators: all or only what is on; icon or kanji, alone or named; set per preset", () => {
  assert.deepEqual(S.OPTIONS.indicators, ["all", "active"])
  assert.deepEqual(S.OPTIONS.indicatorStyle, ["icon", "kanji", "iconname", "kanjiname"])
  assert.equal(S.coerce("indicatorStyle", "full"), "iconname")
  assert.equal(S.resolve({}).indicators, "all")
  assert.equal(S.resolve({}).indicatorStyle, "icon")
  assert.deepEqual(S.PRESET_NAMES.map(p => S.resolve({ preset: p }).indicators), ["all", "active", "all", "active", "all", "active"])
  assert.deepEqual(S.PRESET_NAMES.map(p => S.resolve({ preset: p }).indicatorStyle), ["kanji", "kanji", "icon", "icon", "iconname", "icon"])
  assert.equal(S.resolve({ edits: { indicatorStyle: "emoji" } }).indicatorStyle, "icon")
  assert.equal(Se.nameOf("indicatorStyle"), "Indicator marks")
})

test("bluetooth styles: device, marks, count, off; an older \"on\" reads as device", () => {
  assert.deepEqual(S.OPTIONS.bluetooth, ["device", "marks", "count", "off"])
  assert.equal(S.coerce("bluetooth", "on"), "device")
  assert.equal(S.resolve({ edits: { bluetooth: "on" } }).bluetooth, "device")
  assert.equal(S.resolve({ preset: "Scroll" }).bluetooth, "marks")
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

test("scroll: eight sections on one paper, interludes between", () => {
  const l = Sc.layout(1)
  assert.deepEqual(l.xs, [0, 670, 1400, 2010, 2580, 3070, 3660, 4430])
  assert.equal(l.width, 4430 + 560)
  assert.equal(Sc.layout(1.5).widths[0], 900)
  assert.equal(Sc.indexOf("spaces"), 6)
  assert.equal(Sc.forCell("bluetooth"), "bluetooth")
  assert.equal(Sc.forCell("brightness"), "display")
  assert.equal(Sc.forCell("media"), "")
})

test("scroll: centring a section, and landing a pan on the nearest", () => {
  const view = 1300
  assert.equal(Sc.centred(1, view), 650 - (670 + 330))
  for (let i = 0; i < 8; i++) assert.equal(Sc.nearest(Sc.centred(i, view), view), i)
  // A little push from Sound lands back on Sound; a fling carries on.
  const at = Sc.centred(1, view)
  assert.equal(Sc.landing(at - 100, 0, view), 1)
  assert.equal(Sc.landing(at - 100, -3000, view), 2)
  assert.equal(Sc.clampTrack(99999, view), Sc.centred(0, view))
  assert.equal(Sc.clampTrack(-99999, view), Sc.centred(7, view))
  assert.deepEqual(Sc.position(0), { x: 0, width: 1 / 8 })
})

test("scroll: nine interludes, each with a kanji, presets pick one", () => {
  assert.deepEqual(S.OPTIONS.interlude, ["ma", "hairline", "folio", "kotoba", "tsugime", "seal", "jiku", "fuda", "su"])
  assert.equal(S.resolve({}).interlude, "seal")
  assert.equal(S.resolve({ preset: "Scroll" }).interlude, "kotoba")
  assert.equal(S.resolve({ preset: "Islet" }).interlude, "fuda")
  assert.equal(S.resolve({ preset: "Quiet" }).interlude, "ma")
  assert.equal(S.resolve({ preset: "Hanko", edits: { interlude: "dither" } }).interlude, "seal")
  const labels = Se.interludeLabels()
  assert.deepEqual(Object.keys(labels), S.OPTIONS.interlude)
  assert.equal(labels.seal, "印")
  assert.equal(new Set(Object.values(labels)).size, 9)
  assert.equal(Se.interludeOf("tsugime").name, "Tsugime")
  assert.equal(Se.interludeOf("nope").key, "ma")
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

test("settings: six cards hold every one of the twenty-two settings once", () => {
  const keys = Se.CARDS.flatMap(c => c.rows.map(r => r.key)).filter(k => k !== "sealGlyph" && k !== "typeSize" && k !== "overview")
  assert.deepEqual([...keys].sort(), [...S.KEYS].sort())
  assert.equal(Se.CARDS.length, 6)
  assert.deepEqual(Object.keys(Se.PRESET_BLURBS), S.PRESET_NAMES)
  assert.equal(Se.RAIL.flatMap(g => g.pages).length, 11)
})

test("settings: options, the lit one, and the seal glyph's typed case", () => {
  assert.deepEqual(Se.optionsFor("height", S.OPTIONS), ["32", "36", "40", "44"])
  assert.deepEqual(Se.optionsFor("sealGlyph", S.OPTIONS), ["印", "力", "侍", "A", "…"])
  assert.deepEqual(Se.optionsFor("motion", S.OPTIONS), S.MOTIONS)
  assert.equal(Se.MOTION_ROWS.length, 8)
  assert.equal(Se.nameOf("clockAt"), "Clock position")
  assert.equal(Se.nameOf("bluetooth"), "Bluetooth")
  assert.ok(S.KEYS.every((k) => Se.nameOf(k) !== k))
  const st = S.resolve({})
  assert.equal(Se.selected("height", st, "印"), "40")
  assert.equal(Se.selected("sealGlyph", st, "侍"), "侍")
  assert.equal(Se.selected("sealGlyph", st, "鷹"), "…")
})

test("settings: counting what the draft changes", () => {
  const saved = S.normalize({})
  assert.equal(Se.changes(saved, saved, S.resolve), 0)
  const two = S.withSetting(S.withSetting(saved, "clock", "inline"), "status", "glyphs")
  assert.equal(Se.changes(saved, two, S.resolve), 2)
  // A preset switch counts every setting it moves.
  assert.equal(Se.changes(saved, S.withPreset(saved, "Scroll"), S.resolve), 10)
  const glyph = S.normalize({ sealGlyph: "侍" })
  assert.equal(Se.changes(saved, glyph, S.resolve), 1)
  assert.equal(Se.changes(saved, S.withMonitorSetting(saved, "DP-2", "height", 32), S.resolve), 1)
  assert.equal(Se.status(0), "Saved · every change is kept as you make it")
  assert.equal(Se.status(2), "Saved · 2 changes · Ctrl+Z undoes")
  assert.equal(Se.presetLine(two), "Preset · Hanko + edits")
  assert.equal(Se.presetLine(saved), "Preset · Hanko")
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
  assert.deepEqual(all.map(i => i.glyph), ["録", "書", "鈴", "醒", "夜"])
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
  assert.equal(S.withPreset(d, "Sheet").motion, "still")
  assert.equal(S.shuffled(d, () => 0.5).motion, "still")
  assert.equal(S.withSetting({}, "sealGlyph", "侍たち").sealGlyph, "侍")
  assert.equal(S.combinations(), 61917364224)
})

test("type size sits beside motion: small, regular or large, kept through presets and shuffles", () => {
  assert.equal(S.resolve({}).typeSize, "regular")
  assert.equal(S.resolve({ typeSize: "huge" }).typeSize, "regular")
  const d = S.withSetting({ preset: "Islet" }, "typeSize", "large")
  assert.equal(d.typeSize, "large")
  assert.deepEqual(d.edits, {})
  assert.equal(S.withSetting({}, "typeSize", "tiny"), null)
  assert.equal(S.withPreset(d, "Sheet").typeSize, "large")
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
  assert.deepEqual(S.withPreset(d, "Sheet").hidden, d.hidden)
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
  const s = S.withSetting({ preset: "Sheet", edits: { seal: "none" } }, "show:seal", "shown")
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

const Wx = load("core/Weather.js", ["location", "area", "url", "imperial", "condition", "compass", "leaf", "curve", "range", "leafWidth"])

const METEO = {
  current: { temperature_2m: 17.6, apparent_temperature: 15.9, relative_humidity_2m: 72, wind_speed_10m: 12.4,
             wind_direction_10m: 40, weather_code: 61, is_day: 1 },
  hourly: { time: Array.from({ length: 48 }, (_, i) => `2026-10-0${6 + Math.floor(i / 24)}T${String(i % 24).padStart(2, "0")}:00`),
            temperature_2m: Array.from({ length: 48 }, (_, i) => 14 + 6 * Math.sin((i % 24 - 9) / 24 * Math.PI * 2)),
            precipitation_probability: Array.from({ length: 48 }, (_, i) => (i % 24 > 15 ? 60 : 0)) },
  daily: { time: ["2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09"], weather_code: [61, 0, 3, 71],
           temperature_2m_max: [20, 22, 18, 9], temperature_2m_min: [8, 12, 11, 2],
           sunrise: ["2026-10-06T05:47"], sunset: ["2026-10-06T17:21"] }
}

test("weather: the place file, the detected area and the request", () => {
  assert.deepEqual(Wx.location('{"name":" Tokyo ","latitude":"35.68","longitude":139.69}'), { name: "Tokyo", latitude: 35.68, longitude: 139.69 })
  assert.deepEqual(Wx.location("nope"), { name: "", latitude: null, longitude: null })
  assert.equal(Wx.location('{"name":"Lisbon"}').latitude, null)
  const a = Wx.area(JSON.stringify({ nearest_area: [{ areaName: [{ value: "Pune" }], country: [{ value: "India" }], latitude: "18.5", longitude: "73.8" }] }))
  assert.deepEqual(a, { name: "Pune", country: "India", latitude: 18.5, longitude: 73.8 })
  assert.equal(Wx.area("{}"), null)
  assert.ok(Wx.url(35.68, 139.69).includes("latitude=35.68") && Wx.url(1, 2).includes("hourly=temperature_2m,precipitation_probability"))
})

test("weather: units the way Omarchy picks them", () => {
  assert.equal(Wx.imperial("metric", "en_US", "United States"), false)
  assert.equal(Wx.imperial("imperial", "de_DE", ""), true)
  assert.equal(Wx.imperial("", "de_DE", "United States"), true)
  assert.equal(Wx.imperial("", "en_US", "India"), false)
  assert.equal(Wx.imperial("", "en_US.UTF-8", ""), true)
})

test("weather: codes to words and kanji, wind to a compass point", () => {
  assert.deepEqual(Wx.condition(0, 1), { word: "clear", jp: "晴" })
  assert.equal(Wx.condition(0, 0).jp, "月")
  assert.equal(Wx.condition(63, 1).jp, "雨")
  assert.equal(Wx.condition(73, 1).jp, "雪")
  assert.equal(Wx.condition(95, 1).jp, "雷")
  assert.equal(Wx.condition(48, 1).word, "fog")
  assert.equal(Wx.compass(40), "NE")
  assert.equal(Wx.compass(355), "N")
})

test("weather: Open-Meteo into the leaf", () => {
  const l = Wx.leaf(METEO, "Tokyo", false, new Date(2026, 9, 6, 14, 30))
  assert.deepEqual([l.temp, l.unit, l.feels, l.word, l.jp, l.wind, l.dir, l.humidity], [18, "°C", 16, "rain", "雨", "12 km/h", "NE", 72])
  assert.equal(l.caption, "Tokyo · feels 16° · NE 12 km/h")
  assert.equal(l.hours.length, 24)
  assert.deepEqual([l.hours[13].past, l.hours[14].past], [true, false])
  assert.deepEqual([l.lo, l.hi], [8, 20])
  assert.equal(l.sunLine, "Sun 05:47 → 17:21 · 72% humid")
  assert.deepEqual(l.days.map(d => [d.name, d.jp, d.lo, d.hi]), [["WED", "晴", 12, 22], ["THU", "曇", 11, 18], ["FRI", "雪", 2, 9]])
  assert.deepEqual([l.weekLo, l.weekHi], [2, 22])
  const f = Wx.leaf(METEO, "", true, new Date(2026, 9, 6, 9))
  assert.deepEqual([f.temp, f.unit, f.wind], [64, "°F", "8 mph"])
  assert.equal(Wx.leaf({}, "", false), null)
  assert.equal(Wx.leaf("garbage", "", false), null)
})

test("weather: the day's curve, range bars and how wide the leaf can be", () => {
  const l = Wx.leaf(METEO, "", false, new Date(2026, 9, 6, 12))
  const c = Wx.curve(l.hours, l.lo, l.hi)
  assert.equal(c.length, 24)
  for (const p of c) assert.ok(p.x >= 0 && p.x <= 1 && p.y > 0 && p.y < 1)
  assert.deepEqual(Wx.range(12, 22, 2, 22), { from: 0.5, to: 1 })
  assert.equal(Wx.leafWidth(1700, 600, 70, 1), 400)
  assert.equal(Wx.leafWidth(1604, 600, 70, 1), 392)
  assert.equal(Wx.leafWidth(1250, 600, 70, 1), 0)
  assert.equal(Wx.leafWidth(1500, 600, 70, 1), 340)
})


test("end leaf: nine kinds, a setting with a kanji each, presets pick one", () => {
  assert.deepEqual(S.OPTIONS.endleaf, ["okugaki", "koyomi", "kiki", "shimai", "iro", "dougu", "shuchu", "hikae", "batsu"])
  assert.deepEqual(Lf.KINDS.map(k => k.key), S.OPTIONS.endleaf)
  assert.deepEqual(Se.ENDLEAVES.map(k => k.key), S.OPTIONS.endleaf)
  assert.deepEqual(Se.ENDLEAVES.map(k => k.jp), Lf.KINDS.map(k => k.jp))
  assert.equal(new Set(Object.values(Se.endleafLabels())).size, 9)
  assert.equal(S.resolve({}).endleaf, "koyomi")
  assert.deepEqual(S.PRESET_NAMES.map(p => S.resolve({ preset: p }).endleaf), ["shimai", "okugaki", "koyomi", "batsu", "kiki", "dougu"])
  assert.equal(S.resolve({ edits: { endleaf: "nope" } }).endleaf, "koyomi")
  assert.equal(Se.endleafOf("iro").name, "Iro")
  assert.equal(Lf.kindOf("nope").key, "koyomi")
  assert.equal(S.shows(S.resolve({ hidden: ["endleaf"] }), "endleaf"), false)
})

test("end leaf: the almanac for Tuesday 6 October 2026", () => {
  assert.equal(Lf.SEKKI.length, 24)
  assert.equal(Lf.KO.length, 72)
  const a = Lf.almanac(new Date(2026, 9, 6, 14, 30))
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
  const j = Lf.almanac(new Date(2027, 0, 2))
  assert.equal(j.sekki.name, "Tōji")
  assert.equal(j.ko.no, 66)
  assert.equal(j.sekki.season, "winter")
  assert.equal(Lf.almanac(new Date(2026, 1, 4)).ko.no, 1)
  // The moon: a waning crescent, new in a few days.
  const m = Lf.moon(new Date(2026, 9, 6, 14, 30))
  assert.equal(m.waxing, false)
  assert.ok(m.percent > 10 && m.percent < 35)
  assert.match(m.next, /^New · 1[01]th$/)
  assert.ok(Lf.moon(new Date(Date.UTC(2000, 0, 6, 18, 14))).percent === 0)
})

test("end leaf: the colophon from the machine's facts", () => {
  const raw = "host\tkumo\nmodel\tThinkPad X1 Carbon Gen 11\nkernel\t6.17.2-arch1-1\npackages\t1214\nupgraded\tMon 05 Oct\nomarchy\t3.1.4\nhyprland\t0.51.0\nuptime\t279000.5\nuser\tayush\nname\tAyush Kumar\ntheme\ttokyo-night\n"
  const c = Lf.colophon(raw, { font: "JetBrains Mono", version: "0.1.0", preset: "Hanko" })
  assert.equal(c.title, "Set on <i>kumo</i>")
  assert.equal(c.caption, "Omarchy 3.1.4 · up 3 days")
  assert.deepEqual(c.rows.map(r => r.k), ["Host", "Kernel", "Hyprland", "Packages", "Theme", "Font", "Bar"])
  assert.equal(c.rows[3].v, "1,214 · upgraded Mon 05 Oct")
  assert.equal(c.rows[4].v, "Tokyo Night")
  assert.deepEqual(c.seals.map(s => s.glyph), ["A", "T", "判"])
  const bare = Lf.colophon("host\tbox\nmodel\tTo Be Filled By O.E.M.\n", {})
  assert.equal(bare.rows[0].v, "box")
  assert.equal(Lf.colophon("", {}).ready, false)
  assert.equal(Lf.uptime(279000), "3 days 5 hours")
  assert.equal(Lf.uptime(3700), "1 hour 1 min")
  assert.equal(Lf.themeName("rose-pine-dawn"), "Rose Pine Dawn")
})

test("end leaf: the machine from /proc, df, sensors and top", () => {
  const a = Lf.cpuTimes("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 2 3")
  const b = Lf.cpuTimes("cpu  150 0 150 800 100 0 0 0 0 0")
  assert.deepEqual(a, { idle: 800, total: 1000 })
  assert.equal(Lf.cpuBusy(a, b), 0.5)
  assert.equal(Lf.cpuBusy(null, b), null)
  const mem = Lf.memory("MemTotal:       32000000 kB\nMemFree:  1000 kB\nMemAvailable:   24000000 kB\n")
  assert.deepEqual(mem, { used: 8000000 * 1024, total: 32000000 * 1024 })
  assert.equal(Lf.temperature("acpitz 38000\nnvme 45000\ncoretemp 41000\n"), 41)
  assert.equal(Lf.temperature("nvme 45000\niwlwifi 0\n"), 45)
  assert.equal(Lf.temperature(""), null)
  assert.deepEqual(Lf.disk("     1B/size    1B/used\n465000000000 268000000000\n"), { used: 268e9, total: 465e9 })
  assert.deepEqual(Lf.top("firefox\t6.1\nHyprland\t2.3\nquickshell\t1.4\nextra\t1\n").map(p => p.name), ["firefox", "Hyprland", "quickshell"])
  assert.equal(Lf.bytes(7.4e9), "7.4 GB")
  assert.equal(Lf.machine({ cpu: 0.5, mem: { used: 7.4e9, total: 32e9 } }).rows[1].v, "7.4 / 32 GB")
  const m = Lf.machine({ cpu: 0.12, cores: 8, load: 0.42, mem: { used: 7.4e9, total: 32e9 }, disk: { used: 268e9, total: 465e9 },
    temp: 41, history: [0.1, 0.61, 0.2], top: [{ name: "firefox", cpu: 6.1 }, { name: "Hyprland", cpu: 2.3 }] })
  assert.equal(m.title, "12%, <i>quiet</i>")
  assert.equal(m.caption, "8 cores · 41°C · load 0.42")
  assert.deepEqual(m.rows.map(r => r.k), ["CPU", "Memory", "Disk", "Heat"])
  assert.equal(m.peakLabel, "61% peak")
  assert.equal(m.peakAt, 1)
  assert.equal(m.top, "firefox 6% · Hyprland 2%")
  assert.equal(Lf.machine(null).ready, false)
})

test("end leaf: themes around the current one, tools, session", () => {
  const raw = ["kanagawa\t#1f1f28\t#dcd7ba\t#c34043\tdark", "nord\t#2e3440\t#d8dee9\t#bf616a\t", "rose-pine\t#faf4ed\t#575279\t#b4637a\tlight",
    "kanagawa\t#000000\t#ffffff\t#ff0000\t", "broken\tnope\t#fff\t\t", "tokyo-night\t#1a1b26\t#a9b1d6\t\t"].join("\n")
  const list = Lf.themes(raw)
  assert.deepEqual(list.map(t => t.slug), ["kanagawa", "nord", "rose-pine", "tokyo-night"])
  assert.equal(list[0].bg, "#1f1f28")          // the user's copy, listed first, wins
  assert.equal(list[2].light, true)
  assert.equal(list[3].red, "#a9b1d6")
  assert.deepEqual(Lf.themeWindow(list, "nord", 3).map(t => t.slug), ["kanagawa", "nord", "rose-pine"])
  assert.deepEqual(Lf.themeWindow(list, "kanagawa", 3).map(t => t.slug), ["tokyo-night", "kanagawa", "nord"])
  const v = Lf.themesView(list, "rose-pine", 6)
  assert.equal(v.title, "Rose Pine, <i>light</i>")
  assert.equal(v.shown.length, 4)
  assert.equal(v.more, 0)
  assert.equal(Lf.TOOLS.length, 9)
  assert.equal(Lf.tool("picker").closes, true)
  assert.equal(Lf.toolsLine({ awake: true, dnd: true }), "Staying awake · silenced")
  assert.equal(Lf.toolsLine({}), "Nothing is on")
  assert.deepEqual(Lf.SESSION.map(a => a.key), ["lock", "suspend", "logout", "reboot", "shutdown"])
  assert.deepEqual(Lf.sessionAction("suspend").command, ["systemctl", "suspend"])
  assert.equal(Lf.sessionAction("nope"), null)
})

test("end leaf: the focus timer runs, pauses, ends and counts the day", () => {
  const t0 = new Date(2026, 9, 6, 14, 30).getTime()
  let s = Lf.focusState("")
  assert.equal(s.kind, "idle")
  assert.equal(Lf.focusView(s, t0).title, "25:00, <i>ready</i>")
  s = Lf.focusStep(s, "start", t0).state
  assert.equal(s.kind, "focus")
  let v = Lf.focusView(s, t0 + 6 * 60000 + 18000)
  assert.equal(v.title, "18:42, <i>focus</i>")
  assert.equal(v.caption, "Session 1 of 4 · break at 14:55")
  s = Lf.focusStep(s, "pause", t0 + 60000).state
  assert.equal(Lf.focusView(s, t0 + 10 * 60000).title, "24:00, <i>paused</i>")
  s = Lf.focusStep(s, "resume", t0 + 10 * 60000).state
  s = Lf.focusStep(s, "more", t0 + 10 * 60000).state
  assert.equal(Lf.clock(s.endsAt - (t0 + 10 * 60000)), "29:00")
  let r = Lf.focusStep(s, "tick", s.endsAt)
  assert.equal(r.state.kind, "break")
  assert.equal(r.state.done, 1)
  assert.equal(r.said, "Focus done · take five")
  r = Lf.focusStep(r.state, "skip", r.state.endsAt - 1000)
  assert.equal(r.state.kind, "idle")
  assert.equal(r.said, "Break over")
  // A new day starts the count again; stopping a focus counts nothing.
  const next = Lf.focusStep(r.state, "start", t0 + 86400000).state
  assert.equal(next.done, 0)
  assert.equal(Lf.focusStep(next, "skip", t0 + 86400000 + 1000).state.done, 0)
  assert.equal(Lf.focusState("{bad").kind, "idle")
  assert.equal(Lf.focusState(JSON.stringify(s)).length, 30)
})

test("end leaf: notes you can tick, and the clipboard", () => {
  const text = "# Today\n\n- [x] Test Hanko on the laptop\n- [ ] Reply to Kenji\n* [ ] Pick a name\nA plain line\n"
  const items = Lf.notes(text)
  assert.deepEqual(items.map(i => [i.text, i.done, i.box, i.line]),
    [["Test Hanko on the laptop", true, true, 2], ["Reply to Kenji", false, true, 3], ["Pick a name", false, true, 4], ["A plain line", false, false, 5]])
  assert.equal(Lf.toggled(text, 3).split("\n")[3], "- [x] Reply to Kenji")
  assert.equal(Lf.toggled(text, 2).split("\n")[2], "- [ ] Test Hanko on the laptop")
  assert.equal(Lf.toggled(text, 5), text)
  assert.equal(Lf.notesView(items, true).title, "Two <i>to do</i>")
  assert.equal(Lf.notesView([], false).title, "A blank <i>page</i>")
  const clips = Lf.clipboard(JSON.stringify([{ type: "text", text: "git  push\n-u origin dev" }, { type: "image", path: "/tmp/a.png" }, "#c34043", { type: "text", text: "four" }]))
  assert.deepEqual(clips.map(c => c.text), ["git push -u origin dev", "Image", "#c34043"])
  assert.equal(clips[2].index, 2)
  assert.deepEqual(Lf.clipboard("nope"), [])
  assert.equal(Lf.afterword(new Date(2026, 9, 6), 8).line, "Eight sections · Tuesday 06 · X · 2026")
})

test("scroll sides: bare or curl, in place of the rollers", () => {
  assert.deepEqual(S.OPTIONS.sides, ["bare", "curl"])
  assert.equal(S.resolve({}).sides, "curl")
  assert.deepEqual(S.PRESET_NAMES.map(p => S.resolve({ preset: p }).sides), ["bare", "curl", "curl", "bare", "bare", "curl"])
  assert.equal(S.resolve({ edits: { sides: "roller" } }).sides, "curl")
})

test("scroll guides: the tabs on top, the position bar at the foot, both or none", () => {
  assert.deepEqual(S.OPTIONS.guides, ["both", "tabs", "foot", "none"])
  assert.equal(S.resolve({}).guides, "both")
  assert.ok(S.PRESET_NAMES.every(p => S.resolve({ preset: p }).guides === "both"))
  assert.equal(S.resolve({ edits: { guides: "tabs" } }).guides, "tabs")
  assert.equal(S.resolve({ edits: { guides: "top" } }).guides, "both")
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
  assert.deepEqual(rows[0], ["Preset", "Hanko + 1 edit"])
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
  assert.deepEqual(Ov.LAYOUTS, ["grid", "dynamic"])
})

test("overview layout is a setting beside the counted ones", () => {
  assert.equal(S.resolve({}).overview, "grid")
  assert.equal(S.resolve({ overview: "dynamic" }).overview, "dynamic")
  assert.equal(S.resolve({ overview: "bogus" }).overview, "grid")
  const d = S.withSetting({}, "overview", "dynamic")
  assert.equal(d.overview, "dynamic")
  assert.equal(S.withPreset(d, "Quiet").overview, "dynamic")
  assert.equal(S.withSetting({}, "overview", "tiles"), null)
  assert.deepEqual(Se.optionsFor("overview", S.OPTIONS), ["grid", "dynamic"])
})

// ── Kata 型: one engine for every design ──────────────────────────────
test("kata: twelve parts, three partners, three touches; every design resolves cleanly", () => {
  assert.equal(K.MAIN_PARTS.length, 12)
  assert.equal(K.PART_KEYS.length, 15)
  assert.deepEqual(K.DESIGN_NAMES, ["classic", "margin", "leaf", "shoji"])
  for (const d of ["margin", "leaf", "shoji"]) {
    const s = K.resolve({ design: d })
    assert.deepEqual(s.warnings, [])
    assert.deepEqual(s.borrowed, [])
    for (const k of K.PART_KEYS) assert.ok(K.PARTS[k].v[s[k]], `${d}.${k} = ${s[k]}`)
  }
})
test("kata: Classic is the default, so today's style.json is unchanged", () => {
  const s = K.resolve({ preset: "Sheet", edits: { clock: "mono" } })
  assert.equal(s.design, "classic"); assert.equal(s.classic, true); assert.deepEqual(s.warnings, [])
  assert.equal(K.DEFAULT_DESIGN, "classic")
  assert.equal(K.designName("hanko"), "classic"); assert.equal(K.resolve({ design: "Hanko" }).classic, true)
})
test("kata: partners follow the part they belong with, unless set", () => {
  assert.equal(K.resolve({ design: "leaf" }).corner, "cut")
  assert.equal(K.resolve({ design: "shoji" }).tempo, "johakyu")
  const mix = K.resolve({ design: "shoji", borrow: { surface: "paper", arrive: "fold" } })
  assert.deepEqual([mix.corner, mix.divider, mix.tempo], ["soft", "hairline", "spring"])
  const hand = K.resolve({ design: "leaf", borrow: { corner: "soft" } })
  assert.deepEqual([hand.corner, hand.divider], ["soft", "score"])
  assert.deepEqual(K.resolve({ design: "leaf", borrow: { corner: "cut" } }).borrowed, [])   // what auto gives anyway
})
test("kata: unknown designs, parts and values fall back with a warning", () => {
  const s = K.resolve({ design: "nope", borrow: { slider: "laser", wings: "on" }, touches: { season: "always" } })
  assert.equal(s.design, "classic"); assert.equal(s.slider, "ruler"); assert.equal(s.touches.season, "off")
  assert.equal(s.warnings.length, 4)
  assert.equal(K.resolve({ design: "Shōji" }).design, "shoji")
})
test("kata: a monitor's own design and borrows win on that monitor", () => {
  const doc = { design: "shoji", borrow: { slider: "ruler" }, monitors: { "DP-2": { design: "margin", borrow: { ring: "enso" } } } }
  const here = K.resolve(doc), there = K.resolve(doc, "DP-2")
  assert.equal(here.design, "shoji"); assert.equal(here.slider, "ruler")
  assert.equal(there.design, "margin"); assert.equal(there.ring, "enso"); assert.equal(there.surface, "paper")
})
test("kata: picking a design drops borrows, keeps touches; Classic leaves no key", () => {
  let d = K.withTouch(K.withBorrow({ design: "shoji" }, "slider", "ruler"), "season", "english")
  d = K.withDesign(d, "leaf")
  assert.equal(d.design, "leaf"); assert.equal(d.borrow, undefined); assert.equal(d.touches.season, "english")
  assert.equal(K.withDesign(d, "classic").design, undefined)
  assert.equal(K.withDesign(d, "bauhaus"), null)
})
test("kata: borrowing a design's own part, or auto, gives it back; bad values refuse", () => {
  const d = K.withBorrow({ design: "leaf" }, "slider", "brush")
  assert.equal(d.borrow.slider, "brush")
  assert.equal(K.withBorrow(d, "slider", "auto").borrow, undefined)
  assert.equal(K.withBorrow(d, "slider", "block").borrow, undefined)
  assert.equal(K.withBorrow(d, "slider", "laser"), null)
  assert.equal(K.withTouch({ design: "shoji" }, "season", "kanji").touches, undefined)   // Shōji's own
  assert.equal(K.withTouch({}, "grain", "velvet"), null)
})
test("kata: describe names what was borrowed", () => {
  assert.equal(K.describe(K.resolve({ design: "shoji" })), "Shōji")
  assert.equal(K.describe(K.resolve({ design: "shoji", borrow: { slider: "ruler", seal: "deboss" } })), "Shōji with Margin’s slider, Leaf’s seal")
  assert.equal(K.describe(K.resolve({})), "Hanko")
})
test("kata: a surprise is always a clean mix of two or three borrowed parts", () => {
  let seed = 7
  const rng = () => (seed = (seed * 16807) % 2147483647) / 2147483647
  for (let i = 0; i < 400; i++) {
    const s = K.resolve(K.surprised({ touches: { grain: "toothy" } }, rng))
    assert.deepEqual(s.warnings, []); assert.notEqual(s.design, "classic")
    assert.ok(s.borrowed.length >= 2 && s.borrowed.length <= 3, s.borrowed.join())
    assert.equal(s.touches.grain, "toothy")
  }
})
test("kata: Style.js carries design, borrow and touches through normalize and monitors", () => {
  const doc = { preset: "Quiet", design: "shoji", borrow: { slider: "ruler" }, touches: { season: "english" },
    monitors: { "DP-2": { height: 36, design: "margin" } } }
  const n = S.normalize(doc, [])
  assert.equal(n.design, "shoji"); assert.deepEqual(n.borrow, { slider: "ruler" }); assert.deepEqual(n.touches, { season: "english" })
  assert.deepEqual(n.monitors["DP-2"], { height: 36, design: "margin" })
  const w = []; S.normalize(doc, w); assert.deepEqual(w, [])
  assert.equal(S.resolve(doc, "DP-2").height, 36); assert.equal(S.resolve(doc, "DP-2").design, undefined)
  assert.equal(JSON.stringify(S.normalize({})).includes("design"), false)   // nothing new in an untouched file
  const p = S.withPreset(n, "Sheet"); assert.equal(p.design, undefined); assert.equal(p.borrow, undefined)
  assert.equal(S.withSetting(n, "clock", "mono").design, "shoji")
  assert.equal(S.withMonitorSetting(n, "DP-2", "height", 32).monitors["DP-2"].design, "margin")
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
test("kata K2: a skin carries each design's tokens", () => {
  const m = Sk.skin(K.resolve({ design: "margin" })), l = Sk.skin(K.resolve({ design: "leaf" })), s = Sk.skin(K.resolve({ design: "shoji" }))
  assert.deepEqual([m.radius, l.radius, s.radius], [16, 0, 0])
  assert.deepEqual([m.dividerWidth, l.dividerWidth, s.dividerWidth], [1, 2, 1])
  assert.deepEqual([m.open, l.open, s.open], [240, 220, 340])
  assert.deepEqual([m.soft, l.soft, s.soft], [30, 0, 0])
  assert.equal(s.opacity, 0.86); assert.equal(s.travels, true); assert.equal(s.joints, true); assert.equal(s.season, "kanji")
  assert.equal(m.gap, -1); assert.equal(l.gap, 0); assert.equal(s.gap, 6)
  assert.equal(Sk.skin(K.resolve({ design: "shoji", borrow: { surface: "paper" } })).radius, 16)   // partners follow into the skin
  assert.equal(Sk.skin({}).design, "classic")
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

test("kata K6: the second wave borrows like the first; hold is Leaf's soak, shared by Margin", () => {
  assert.deepEqual(["margin", "leaf", "shoji"].map(d => K.resolve({ design: d }).notify), ["cards", "tickets", "rows"])
  assert.deepEqual(["margin", "leaf", "shoji"].map(d => K.resolve({ design: d }).overview), ["miniatures", "contact", "framed"])
  assert.deepEqual(["margin", "leaf", "shoji"].map(d => K.resolve({ design: d }).hold), ["soak", "soak", "stroke"])
  const m = K.resolve({ design: "margin", borrow: { hold: "soak" } })
  assert.deepEqual(m.borrowed, [])
  const s = K.resolve(K.withBorrow({ design: "shoji" }, "notify", "tickets"))
  assert.deepEqual(s.borrowed, ["notify"])
  assert.equal(K.describe(s), "Shōji with Leaf’s letters")
  assert.equal(K.withBorrow({ design: "leaf" }, "hold", "ring"), null)
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
  assert.equal(Sk.skin(K.resolve({ design: "shoji" })).opacity, 0.86)
  assert.equal(Sk.skin(K.resolve({ design: "shoji" }), 50).opacity, 0.5)
  assert.equal(Sk.skin(K.resolve({ design: "margin" }), 0).opacity, 1)
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

console.log(`${passed} passed${process.exitCode ? ", some failed" : ""}`)
