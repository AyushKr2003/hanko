.pragma library

// The four craft hands for the sheets (Settings › Sheets 紙): Shōgi 将棋,
// Soroban 算盤, Odoshi 縅 and Kasumi 霞 (docs/revision2/sheet-hands.md).
// They draw the same things in four ways, so each sheet's data is first
// turned into one plain model here, and bar/sheets/<Hand>Hand.qml draws
// the model. Nothing here knows how a hand looks.
//
// model(sheet, feed, now, lib) → {
//   sheet, jp, label                 the eyebrow
//   hero: { mark, name, figure, unit, line, caption, red, level (0..1, -1 = none),
//           rank (its level is a row of its own), set ({ what } or null), min,
//           scales (how many steps its level is counted in, 0 = the hand's own) }
//   levels: [row]                    things with a level (a volume, a signal, a charge)
//   choices: [row]                   things you pick one of (an output, a profile)
//   choicesLabel, choicesMark, inline (choices are short: draw them in one line)
//   tally: [{ name, n, lead }]       what the abacus counts, when not the levels
//   lines: [string]                  quiet facts under the body (zones, details)
//   hint, note, buttons: [{ text, on, ghost, plate, visible, what, arg }]
//   keys: { step: { what, min }, left, right, letters: { M: { what, arg } } }
// }
// row: { key, name, mark, detail, note, figure, level (-1 = none), count,
//        lead, muted, urgent, selected, dashed,
//        set ({ what, arg } or null: a level picked on the row), click ({ what, arg } or null) }
//
// lib: the other core modules this reads, passed in so they are not copied
// here: { T: Time.js, St: Status.js, B: Blue.js }.

var HANDS = ["shogi", "soroban", "odoshi", "kasumi"]
var WEEK_KANJI = ["日", "月", "火", "水", "木", "金", "土"]
var PROFILE_MARKS = { performance: "速", balanced: "均", "power-saver": "省" }
// A letter's reach (a file, a lacing, a band) wanes over a working day.
var FRESH_MS = 8 * 3600 * 1000

function clamp01(v) { v = Number(v); return v > 1 ? 1 : v > 0 ? v : 0 }
function pct(v) { return Math.round(clamp01(v) * 100) + "%" }

// A row with every field present, so the hands never test for undefined.
function row(o) {
  var r = { key: "", name: "", mark: "", detail: "", note: "", figure: "", level: -1, count: -1,
            lead: false, muted: false, urgent: false, selected: false, dashed: false, set: null, click: null }
  for (var k in o) r[k] = o[k]
  if (r.count < 0 && r.level >= 0) r.count = Math.round(clamp01(r.level) * 100)
  return r
}

function base(sheet, jp, label) {
  return { sheet: sheet, jp: jp, label: label,
           hero: { mark: jp, name: "", figure: "—", unit: "", line: "", caption: "", red: false, level: -1, rank: false, set: null, min: 0, scales: 0 },
           levels: [], choices: [], choicesLabel: "", choicesMark: "", inline: false,
           tally: [], lines: [], hint: "", note: "", buttons: [], keys: { step: null, left: null, right: null, letters: {} } }
}

// The hero as a row, for the hands that draw it as one more rank or rod.
function heroRow(m) {
  var h = m.hero
  return row({ key: "hero", name: h.name, mark: h.mark, level: h.level, figure: h.figure + h.unit,
               note: h.caption, lead: true, muted: h.red && h.level >= 0 && !!h.set,
               urgent: h.red, set: h.set ? { what: h.set.what, arg: null } : null })
}

// What a hand that draws its hero as a row lays out: the hero first.
function ranks(m) {
  return m.hero.rank && m.hero.level >= 0 ? [heroRow(m)].concat(m.levels) : m.levels.slice()
}

// The request a row sends when its level is picked: a plain value, or the
// row's own argument with the value added.
function setArg(set, v) {
  if (!set) return null
  if (!set.arg) return v
  var a = {}
  for (var k in set.arg) a[k] = set.arg[k]
  a.value = v
  return a
}

// ---- the seven sheets

function time(feed, now, lib) {
  var T = lib.T, shift = Number(feed.timeShift) || 0
  var head = T.heading(now)
  var m = base("time", "時", "Time · Week " + head.week)
  var mins = now.getHours() * 60 + now.getMinutes()
  var y = now.getFullYear(), mo = now.getMonth()
  var dim = new Date(y, mo + 1, 0).getDate()
  var dow = (now.getDay() + 6) % 7 // Monday 0
  var doy = T.dayOfYear(now), diy = T.daysInYear(y)
  // 12-hour when the bar's clock is (feed.timeFormat, from the hours setting).
  var twelve = /AP/i.test(String(feed.timeFormat || ""))
  var hh = twelve ? String(now.getHours() % 12 || 12) : T.pad2(now.getHours())
  m.hero = { mark: "時", name: "Day", figure: hh + ":" + T.pad2(now.getMinutes()), unit: twelve ? (now.getHours() < 12 ? "AM" : "PM") : "",
             line: head.title + ", " + now.getDate() + " " + T.MONTHS[mo], caption: T.leftInDay(now),
             red: false, level: mins / 1440, rank: true, set: null, min: 0, scales: 24 }
  m.levels = [
    row({ key: "week", name: "Week", mark: "週", level: (dow * 1440 + mins) / (7 * 1440),
          figure: "day " + (dow + 1) + " of 7", note: "Week " + head.week, count: head.week }),
    row({ key: "month", name: T.MONTHS[mo], mark: "月", level: (now.getDate() - 1 + mins / 1440) / dim,
          figure: now.getDate() + " of " + dim, note: (dim - now.getDate()) + " to go", count: now.getDate() }),
    row({ key: "year", name: String(y), mark: "年", level: (doy - 1 + mins / 1440) / diy,
          figure: "day " + doy, note: "of " + diy, count: doy })
  ]
  // The week the sheet is turned to: today sealed, days gone paler.
  var start = new Date(y, mo, now.getDate() - dow + 7 * shift)
  var today = T.startOfDay(now).getTime()
  for (var i = 0; i < 7; i++) {
    var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
    var t = d.getTime()
    m.choices.push(row({ key: "d" + i, mark: WEEK_KANJI[d.getDay()], name: String(d.getDate()),
                         detail: T.WEEKDAYS[d.getDay()].slice(0, 3), note: T.MONTHS[d.getMonth()].slice(0, 3),
                         selected: t === today, dashed: t < today,
                         click: shift !== 0 ? { what: "shift", arg: 0 } : null }))
  }
  m.choicesLabel = shift === 0 ? "This week" : (shift > 0 ? "+" : "") + shift + (Math.abs(shift) === 1 ? " week" : " weeks")
  m.choicesMark = "週"
  m.inline = true
  m.tally = [{ name: "Hour", n: now.getHours(), lead: true }, { name: "Minute", n: now.getMinutes() },
             { name: "Day", n: now.getDate() }]
  var zones = feed.zones || []
  for (var z = 0; z < zones.length; z++)
    if (zones[z].ready !== false) m.lines.push(zones[z].label + "  " + zones[z].time + "  " + zones[z].rel)
  m.buttons = [
    { text: "‹ Week", ghost: true, what: "shift", arg: shift - 1 },
    { text: "Today", on: shift === 0, what: "shift", arg: 0 },
    { text: "Week ›", ghost: true, what: "shift", arg: shift + 1 }
  ]
  m.keys.left = { what: "shift", arg: shift - 1 }
  m.keys.right = { what: "shift", arg: shift + 1 }
  m.keys.letters = { T: { what: "shift", arg: 0 } }
  return m
}

function sound(feed) {
  var s = feed.sound
  var m = base("sound", "音", "Sound · Pipewire")
  if (!s) return m
  var master = s.master, outputs = s.outputs || [], streams = s.streams || []
  var playing = null
  for (var i = 0; i < outputs.length; i++) if (outputs[i].current) playing = outputs[i]
  if (master)
    m.hero = { mark: "音", name: "Master", figure: String(master.percent), unit: "%",
               line: playing ? "through " + playing.label : "no output",
               caption: master.muted ? "Muted" : "Master", red: !!master.muted,
               level: clamp01(master.level), rank: true, set: { what: "master" }, min: 0 }
  for (var j = 0; j < streams.length && j < 4; j++) {
    var st = streams[j]
    m.levels.push(row({ key: "s" + st.id, name: st.label, mark: "奏", level: clamp01(st.level),
                        figure: st.muted ? "muted" : st.percent + "%", muted: !!st.muted, dashed: !!st.muted,
                        set: { what: "stream", arg: { id: st.id, name: st.name } },
                        click: { what: "streamMute", arg: { id: st.id, name: st.name } } }))
  }
  for (var k = 0; k < outputs.length && k < 4; k++) {
    var o = outputs[k]
    m.choices.push(row({ key: "o" + o.id, name: o.label, mark: o.current ? "鳴" : "出", detail: o.detail || "",
                         note: o.note || "", selected: !!o.current,
                         click: o.current ? null : { what: "output", arg: { id: o.id, name: o.name } } }))
  }
  m.choicesLabel = "Output"
  m.choicesMark = "出"
  m.note = s.input || ""
  m.buttons = [
    { text: "Mute", on: !!(master && master.muted), what: "mute", arg: null },
    { text: s.inputMuted ? "Unmute mic" : "Mute mic", ghost: true, what: "inputMute", arg: null }
  ]
  if (master) m.keys.step = { what: "master", min: 0, level: clamp01(master.level) }
  m.keys.letters = { M: { what: "mute", arg: null } }
  m.hint = outputs.length > 1 ? "Click an output to play there" : ""
  return m
}

function network(feed) {
  var n = feed.network
  var m = base("network", "網", "Network · NetworkManager")
  var radio = !n || n.radio !== false
  var cur = n && n.current ? n.current : { kind: "", label: "…", detail: "" }
  var nets = n && radio ? (n.networks || []) : []
  var here = null
  for (var i = 0; i < nets.length; i++) if (nets[i].current) here = nets[i]
  var offline = !!(n && n.offline)
  m.hero = { mark: "網", name: "Signal", figure: here ? String(here.signal) : offline ? "off" : "—", unit: here ? "%" : "",
             line: offline ? "offline" : cur.label, caption: offline ? "No connection" : cur.detail,
             red: offline, level: here ? here.signal / 100 : -1, rank: false, set: null, min: 0 }
  for (var j = 0; j < nets.length && j < 6; j++) {
    var w = nets[j]
    m.levels.push(row({ key: "n" + j, name: w.ssid, mark: w.current ? "網" : w.secure ? "鍵" : "開",
                        level: clamp01(w.signal / 100), figure: w.signal + "%", note: w.note || "", detail: w.detail || "",
                        selected: !!w.current,
                        click: w.current ? null : { what: "connect", arg: { ssid: w.ssid, saved: w.saved, secure: w.secure } } }))
  }
  m.tally = here ? [{ name: "Signal", n: here.signal, lead: true }, { name: "Nearby", n: nets.length }] : [{ name: "Nearby", n: nets.length }]
  m.hint = !radio ? "Wi-Fi is off" : nets.length ? "Click a network to join it" : "Looking for networks"
  m.buttons = [
    { text: "Wi-Fi", on: radio, what: "radio", arg: !radio },
    { text: "Rescan", ghost: true, visible: radio, what: "rescan", arg: null },
    { text: "Speed test ›", plate: true, what: "speedtest", arg: null }
  ]
  m.keys.letters = { R: { what: "rescan", arg: null } }
  return m
}

function bluetooth(feed, now, lib) {
  var b = feed.bluetooth, B = lib.B
  var m = base("bluetooth", "藍", "Bluetooth · BlueZ")
  var powered = !!(b && b.enabled)
  var all = b && powered ? (b.connected || []).concat(b.known || []).concat(b.found || []).slice(0, 6) : []
  var first = b && powered && b.connected && b.connected.length ? b.connected[0] : null
  var low = function(d) { return d.level >= 0 && d.level / 100 <= B.LOW }
  m.hero = { mark: "藍", name: "Charge", figure: first && first.level >= 0 ? String(first.level) : powered ? "—" : "off",
             unit: first && first.level >= 0 ? "%" : "", line: first ? first.name : b ? b.title : "Bluetooth",
             caption: b ? b.blurb : "", red: !!(first && low(first)), level: -1, rank: false, set: null, min: 0 }
  for (var i = 0; i < all.length; i++) {
    var d = all[i]
    var kind = String(d.detail || "").split(" · ")[0]
    var r = row({ key: d.address, name: d.name, mark: B.KIND_MARKS[kind] || "器", detail: d.detail || "",
                  note: d.connected ? "Connected" : d.paired ? "Paired" : "New",
                  level: d.level >= 0 ? d.level / 100 : -1, figure: d.level >= 0 ? d.level + "%" : "",
                  urgent: low(d), selected: !!d.connected,
                  click: { what: "device", arg: { address: d.address, action: B.action(d) } } })
    if (r.level >= 0) m.levels.push(r)
    else m.choices.push(r)
  }
  m.choicesLabel = "Devices"
  m.choicesMark = "器"
  var counted = []
  for (var t = 0; t < m.levels.length && t < 3; t++)
    counted.push({ name: m.levels[t].name, n: Math.round(m.levels[t].level * 100), lead: m.levels[t].selected })
  m.tally = counted
  m.hint = !b || !b.present ? "No adapter" : !powered ? "Bluetooth is off"
         : b.scanning ? "Looking for devices · click one to connect" : "Click a device to connect it"
  m.buttons = b && b.present ? [{ text: "Bluetooth", on: powered, what: "power", arg: !powered }] : []
  m.keys.letters = { P: { what: "power", arg: !powered } }
  return m
}

function power(feed) {
  var p = feed.power
  var m = base("power", "電", "Power · UPower")
  if (!p) return m
  var has = p.percent >= 0
  var details = p.details || []
  m.jp = p.charging ? "充" : "電"
  m.hero = { mark: m.jp, name: "Battery", figure: has ? String(p.percent) : "AC", unit: has ? "%" : "",
             line: p.blurb || "", caption: details.length ? details[0].value : "", red: !!p.low,
             level: has ? p.percent / 100 : -1, rank: true, set: null, min: 0 }
  var profiles = p.profiles || []
  for (var i = 0; i < profiles.length; i++) {
    var pr = profiles[i]
    m.choices.push(row({ key: pr.name, name: pr.label, mark: PROFILE_MARKS[pr.name] || "電", detail: pr.detail || "",
                         note: pr.active ? "Running" : "", selected: !!pr.active,
                         click: pr.active ? null : { what: "profile", arg: pr.name } }))
  }
  m.choicesLabel = "Profile"
  m.choicesMark = "式"
  if (has) m.tally.push({ name: "Charge", n: p.percent, lead: true })
  for (var j = 1; j < details.length; j++) {
    m.lines.push(details[j].name + "  " + details[j].value)
    var num = parseInt(details[j].value, 10)
    if (isFinite(num) && m.tally.length < 3 && /^\d+\s*(Wh)?$/.test(details[j].value))
      m.tally.push({ name: details[j].name, n: num })
  }
  m.hint = profiles.length ? "Click a profile to run it" : ""
  return m
}

function display(feed) {
  var d = feed.display
  var m = base("display", "明", "Display · Hyprland")
  if (!d) return m
  var light = d.brightness
  m.hero = { mark: "明", name: "Brightness", figure: light ? String(light.percent) : "—", unit: light ? "%" : "",
             line: d.title || "", caption: d.blurb || "", red: false, level: light ? clamp01(light.level) : -1,
             rank: true, set: light ? { what: "brightness" } : null, min: 0.01 }
  var mons = (d.monitors || []).slice(0, 5)
  for (var i = 0; i < mons.length; i++) {
    var mo = mons[i]
    m.choices.push(row({ key: mo.name, name: mo.label, mark: mo.internal ? "内" : "外", detail: mo.detail || "",
                         note: !mo.enabled ? "Off" : mo.focused ? "Focused" : "", selected: !!mo.current,
                         dashed: !mo.enabled, click: mo.current || !mo.enabled ? null : { what: "monitor", arg: mo.name } }))
  }
  m.choicesLabel = "Monitor"
  m.choicesMark = "画"
  m.hint = mons.length > 1 ? "Click a monitor to choose it" : ""
  m.buttons = [
    { text: "Night", on: !!d.night, what: "night", arg: !d.night },
    { text: "Monitors ›", plate: true, what: "edit", arg: null }
  ]
  if (light) m.keys.step = { what: "brightness", min: 0.01, level: clamp01(light.level) }
  m.keys.letters = { N: { what: "night", arg: !d.night } }
  return m
}

function inbox(feed, now, lib) {
  var St = lib.St
  var letters = feed.letters || [], dnd = !!feed.dnd
  var m = base("inbox", "報", "Inbox · " + St.count2(letters.length))
  var urgent = 0
  for (var u = 0; u < letters.length; u++) if (letters[u].urgent) urgent++
  m.hero = { mark: "報", name: "Waiting", figure: St.count2(letters.length), unit: "",
             line: dnd ? "quiet: nothing will pop up" : letters.length === 1 ? "letter waiting" : "letters waiting",
             caption: urgent ? urgent + (urgent === 1 ? " needs" : " need") + " you" : "Newest first", red: false, level: -1, rank: false, set: null, min: 0 }
  for (var i = 0; i < letters.length && i < 5; i++) {
    var l = letters[i]
    var age = now.getTime() - Number(l.timestamp)
    m.levels.push(row({ key: "l" + i, name: l.summary || l.app, mark: l.glyph || "報",
                        detail: l.body ? String(l.body).replace(/\s+/g, " ") : l.app,
                        note: St.age(l.timestamp, now.getTime()),
                        level: Math.max(0.08, 1 - clamp01(age / FRESH_MS)), figure: St.age(l.timestamp, now.getTime()),
                        urgent: !!l.urgent, dashed: dnd }))
  }
  m.tally = [{ name: "Waiting", n: letters.length, lead: true }, { name: "Urgent", n: urgent }]
  m.hint = letters.length ? "Fresh letters reach furthest" : "Nothing new"
  m.buttons = [
    { text: "Quiet", on: dnd, what: "dnd", arg: null },
    { text: "Replay", ghost: true, what: "replay", arg: null },
    { text: "Clear all", plate: true, what: "clear", arg: null }
  ]
  return m
}

var SHEETS = { time: time, sound: sound, network: network, bluetooth: bluetooth,
               power: power, display: display, inbox: inbox }

function model(sheet, feed, now, lib) {
  var f = SHEETS[sheet]
  if (!f) return base(sheet, "", "")
  return f(feed || {}, now || new Date(), lib || {})
}
