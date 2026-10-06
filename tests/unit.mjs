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
  "coerce", "normalize", "resolve", "withSetting", "withPreset", "shuffled", "combinations", "withMonitorSetting"])
const Se = load("core/Settings.js", ["RAIL", "CARDS", "GLYPHS", "PRESET_BLURBS", "optionsFor", "selected", "changes",
  "status", "presetLine", "matches", "pageMatches"])
const I = load("core/InkMath.js", ["TIERS", "contrast", "tier", "ramp", "mix", "isLight"])
const T = load("core/Title.js", ["appName", "describe", "tildify"])
const W = load("core/Spaces.js", ["numeral", "folio", "layoutOf", "usableArea", "list"])
const St = load("core/Status.js", ["ticks", "bars", "network", "volume", "battery", "brightness",
  "stampGlyph", "tilt", "notifications", "count2", "LOW_BATTERY", "age"])
const Sh = load("core/Sheets.js", ["SHEETS", "byKey", "forCell", "forOmarchyId", "omarchyIdForCell", "step", "panelAt", "place"])
const Tm = load("core/Time.js", ["dayOfYear", "daysInYear", "isoWeek", "leftInDay", "heading", "ribbon", "parseZones",
  "zonesFromBarConfig", "probeCommand", "parseProbe", "relative", "zoneRow", "ordinal", "counted", "dayAcross"])
const So = load("core/Sound.js", ["friendly", "label", "bus", "detail", "outputs", "streams", "master", "inputNote", "sheet"])
const N = load("core/Net.js", ["splitTerse", "parseWifi", "parseSaved", "band", "securityName", "connectHow", "sheet"])
const Pw = load("core/Power.js", ["keyValues", "profiles", "stateLabel", "blurb", "details", "sheet"])
const Sc = load("core/Scroll.js", ["SECTIONS", "INTERLUDE", "indexOf", "forCell", "layout", "centred", "nearest",
  "clampTrack", "landing", "position", "sliver"])
const H = load("core/Hosted.js", ["DRAWN", "OWN", "entries", "hosted", "own", "cell", "idOfCell"])
const X = load("core/Extras.js", ["INDICATORS", "indicators", "moduleJson", "keyboard", "tray"])
const D = load("core/Display.js", ["monitors", "brightness", "target", "sheet"])
const B = load("core/Blue.js", ["human", "kind", "row", "lists", "cell", "action", "sheet"])
const E = load("core/Edge.js", ["dayFraction", "hourTicks", "at", "span", "pulled", "PULL_THRESHOLD"])

let passed = 0
function test(name, fn) {
  try { fn(); passed++ } catch (e) { console.error(`FAIL ${name}\n  ${e.message}`); process.exitCode = 1 }
}

test("sixteen settings, 5,971,968 combinations (COMPONENTS.md §5)", () => {
  assert.equal(S.KEYS.length, 16)
  assert.equal(S.combinations(), 5971968)
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

test("scroll: interludes are two-tone dither, fading out at the ends", () => {
  const w = 20, h = 60, px = Sc.sliver(w, h, 1)
  assert.equal(px.length, w * h)
  assert.ok(px.every(v => v === 0 || v === 1))
  const row = y => px.slice(y * w, y * w + w).reduce((a, b) => a + b, 0)
  assert.equal(row(0), 0)
  assert.deepEqual(Sc.sliver(w, h, 1), px)
  assert.notDeepEqual(Sc.sliver(w, h, 2), px)
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

test("settings: six cards hold every one of the sixteen settings once", () => {
  const keys = Se.CARDS.flatMap(c => c.rows.map(r => r.key)).filter(k => k !== "sealGlyph")
  assert.deepEqual([...keys].sort(), [...S.KEYS].sort())
  assert.equal(Se.CARDS.length, 6)
  assert.deepEqual(Object.keys(Se.PRESET_BLURBS), S.PRESET_NAMES)
  assert.equal(Se.RAIL.flatMap(g => g.pages).length, 8)
})

test("settings: options, the lit one, and the seal glyph's typed case", () => {
  assert.deepEqual(Se.optionsFor("height", S.OPTIONS), ["32", "36", "40", "44"])
  assert.deepEqual(Se.optionsFor("sealGlyph", S.OPTIONS), ["印", "力", "侍", "A", "…"])
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
  assert.equal(Se.changes(saved, S.withPreset(saved, "Scroll"), S.resolve), 5)
  const glyph = S.normalize({ sealGlyph: "侍" })
  assert.equal(Se.changes(saved, glyph, S.resolve), 1)
  assert.equal(Se.changes(saved, S.withMonitorSetting(saved, "DP-2", "height", 32), S.resolve), 1)
  assert.equal(Se.status(0), "Saved · as on your bar")
  assert.equal(Se.status(2), "Edited · live on your bar · 2 changes")
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
                { address: "B", name: "MX Keys", connected: true, paired: true, battery: -1 }]
  assert.equal(B.cell(false, true, devs), null)
  assert.deepEqual(B.cell(true, true, devs), { name: "MX Keys +1", enabled: true, connected: 2, level: -1, needsYou: false })
  assert.equal(B.cell(true, true, devs.slice(0, 1)).level, 0.8)
  assert.equal(B.cell(true, false, devs).name, "Off")
  assert.equal(B.cell(true, true, []).name, "On")
  assert.deepEqual([B.sheet(true, true, false, devs).title, B.sheet(true, true, false, devs).blurb], ["MX Keys", "2 devices connected."])
  assert.equal(B.sheet(false, false, false, []).title, "No adapter")
  assert.equal(B.sheet(true, false, false, devs).blurb, "Turn it on to see your devices.")
  assert.equal(B.sheet(true, true, true, []).blurb, "Looking for devices nearby…")
})

console.log(`${passed} passed${process.exitCode ? ", some failed" : ""}`)
