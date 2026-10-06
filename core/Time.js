.pragma library

// The Time sheet 時 (docs/COMPONENTS.md, "Panels"): where today sits in the
// year, a two-week day ribbon, and Elsewhen's other cities. QML has no
// Intl, so other zones' offsets come from a `date` probe (the same way
// Omarchy's Elsewhen does it) and their clocks tick locally from that.

var WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var MONTHS = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"]
// Elsewhen seeds these when you have never set any; Hanko shows the same.
var DEFAULT_ZONES = "Los Angeles|America/Los_Angeles, Paris|Europe/Paris, Tokyo|Asia/Tokyo"
var ZONE_ID = /^[A-Za-z0-9_+\-\/]+$/

function pad2(n) { return (n < 10 ? "0" : "") + n }

function startOfDay(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()) }

// 1 on the 1st of January. Counted on calendar dates, so a DST change
// inside the year does not shift it.
function dayOfYear(d) {
  var a = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate())
  var b = Date.UTC(d.getFullYear(), 0, 1)
  return Math.round((a - b) / 86400000) + 1
}

function daysInYear(year) {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0 ? 366 : 365
}

// ISO 8601 week: weeks start on Monday, week 1 holds the year's first Thursday.
function isoWeek(d) {
  var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  var dow = t.getUTCDay() || 7
  t.setUTCDate(t.getUTCDate() + 4 - dow)
  var yearStart = Date.UTC(t.getUTCFullYear(), 0, 1)
  return Math.ceil(((t - yearStart) / 86400000 + 1) / 7)
}

// "2h 16m left in the day"
function leftInDay(d) {
  var left = 24 * 60 - (d.getHours() * 60 + d.getMinutes())
  var h = Math.floor(left / 60)
  var m = left % 60
  return (h > 0 ? h + "h " : "") + m + "m left in the day"
}

// The head of the sheet: { eyebrow, title, blurb }.
function heading(d) {
  return {
    week: isoWeek(d),
    title: WEEKDAYS[d.getDay()],
    blurb: "Day " + dayOfYear(d) + " of " + daysInYear(d.getFullYear()) + " · " + leftInDay(d)
  }
}

// `count` days around today (fourteen by default): five behind, today, the
// rest ahead, moved a week at a time by `shift`. Each day: { day "06", letter "T", weekend, past,
// today, weekStart (a Monday, ruled off) }. `month` names the month most of
// the ribbon is in.
function ribbon(d, shift, count) {
  var n = count || 14
  var today = startOfDay(d)
  var start = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 5 + 7 * (shift || 0))
  var days = []
  for (var i = 0; i < n; i++) {
    var x = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
    var dow = x.getDay()
    days.push({
      day: pad2(x.getDate()),
      letter: WEEKDAYS[dow].charAt(0),
      weekend: dow === 0 || dow === 6,
      past: x < today,
      today: x.getTime() === today.getTime(),
      weekStart: dow === 1 && i > 0
    })
  }
  var mid = new Date(start.getFullYear(), start.getMonth(), start.getDate() + Math.floor(n / 2))
  var prev = new Date(mid.getFullYear(), mid.getMonth() - 1, 1)
  var next = new Date(mid.getFullYear(), mid.getMonth() + 1, 1)
  return { month: MONTHS[mid.getMonth()] + " " + mid.getFullYear(), days: days,
           before: MONTHS[prev.getMonth()], after: MONTHS[next.getMonth()], current: MONTHS[mid.getMonth()] }
}

var ORDINALS = ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth",
  "tenth", "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth",
  "eighteenth", "nineteenth", "twentieth", "twenty-first", "twenty-second", "twenty-third",
  "twenty-fourth", "twenty-fifth", "twenty-sixth", "twenty-seventh", "twenty-eighth", "twenty-ninth",
  "thirtieth", "thirty-first"]
var NUMBERS = ["No", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
  "Eleven", "Twelve"]

// "the sixth": the day of the month in words, for the scroll's Time title.
function ordinal(day) { return "the " + (ORDINALS[day] || String(day)) }

// "Three letters", "One letter", "No letters", "14 letters".
function counted(n, one, many) {
  var w = n >= 0 && n < NUMBERS.length ? NUMBERS[n] : String(n)
  return w + " " + (n === 1 ? one : many)
}

// ------------------------------------------------------------ Elsewhen

// "Tokyo|Asia/Tokyo, Europe/Lisbon" -> [{ label, id }]. Bad ids are dropped.
function parseZones(spec) {
  var out = []
  var parts = String(spec === undefined || spec === null ? "" : spec).split(",")
  for (var i = 0; i < parts.length; i++) {
    var entry = parts[i].trim()
    if (!entry) continue
    var bar = entry.indexOf("|")
    var id = (bar >= 0 ? entry.slice(bar + 1) : entry).trim()
    var label = bar >= 0 ? entry.slice(0, bar).trim() : ""
    if (!ZONE_ID.test(id)) continue
    out.push({ label: label || id.split("/").pop().replace(/_/g, " "), id: id })
  }
  return out
}

// Elsewhen's zones from Omarchy's bar layout (its `zones` setting), or the
// cities Elsewhen seeds when it has none.
function zonesFromBarConfig(barConfig) {
  var layout = barConfig && barConfig.layout ? barConfig.layout : {}
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var list = Array.isArray(layout[sections[s]]) ? layout[sections[s]] : []
    for (var i = 0; i < list.length; i++) {
      var e = list[i]
      if (e && e.id === "omarchy.elsewhen" && String(e.zones || "").trim() !== "") return parseZones(e.zones)
    }
  }
  return parseZones(DEFAULT_ZONES)
}

// argv printing "Asia/Tokyo|JST|+0900" per zone. Zones are arguments to
// the script, never part of it.
function probeCommand(ids) {
  return ["bash", "-c", "for z in \"$@\"; do TZ=\"$z\" date \"+$z|%Z|%z\"; done", "hanko"].concat(ids || [])
}

// Probe output -> { "Asia/Tokyo": { abbr: "JST", offset: 540 } }
function parseProbe(text) {
  var map = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split("|")
    if (f.length < 3) continue
    var m = /^([+-])(\d{2})(\d{2})$/.exec(f[2].trim())
    if (!m || !f[0].trim()) continue
    var mins = parseInt(m[2], 10) * 60 + parseInt(m[3], 10)
    map[f[0].trim()] = { abbr: f[1].trim(), offset: m[1] === "-" ? -mins : mins }
  }
  return map
}

// "+9", "-3:30", "±0": a zone's distance from the local clock.
function relative(minutes) {
  if (!minutes) return "±0"
  var a = Math.abs(minutes)
  return (minutes < 0 ? "-" : "+") + Math.floor(a / 60) + (a % 60 ? ":" + pad2(a % 60) : "")
}

// One Elsewhen row at `now`: { label, time "06:44", date "Wed 07 · JST",
// rel "+9", ready }. `localOffset` is minutes east of UTC here.
function zoneRow(zone, info, now, localOffset, hour24) {
  if (!info) return { label: zone.label, id: zone.id, ready: false, time: "--:--", date: zone.id, rel: "" }
  var t = new Date(now.getTime() + info.offset * 60000)
  var h = t.getUTCHours()
  var time = hour24 === false
    ? ((h % 12) || 12) + ":" + pad2(t.getUTCMinutes()) + (h < 12 ? " AM" : " PM")
    : pad2(h) + ":" + pad2(t.getUTCMinutes())
  return {
    label: zone.label,
    id: zone.id,
    ready: true,
    time: time,
    date: WEEKDAYS[t.getUTCDay()].slice(0, 3) + " " + pad2(t.getUTCDate()) + (info.abbr ? " · " + info.abbr : ""),
    rel: relative(info.offset - localOffset),
    // Whether it is already tomorrow (or still yesterday) there.
    day: dayAcross(now, info.offset, localOffset)
  }
}

// "tomorrow", "yesterday" or "" for a zone `offset` minutes east of UTC,
// against the local calendar day.
function dayAcross(now, offset, localOffset) {
  var there = new Date(now.getTime() + offset * 60000)
  var here = new Date(now.getTime() + localOffset * 60000)
  var a = Date.UTC(there.getUTCFullYear(), there.getUTCMonth(), there.getUTCDate())
  var b = Date.UTC(here.getUTCFullYear(), here.getUTCMonth(), here.getUTCDate())
  return a > b ? "tomorrow" : a < b ? "yesterday" : ""
}

function zoneRows(zones, probe, now, localOffset, hour24) {
  var out = []
  for (var i = 0; i < (zones || []).length; i++)
    out.push(zoneRow(zones[i], probe ? probe[zones[i].id] : null, now, localOffset, hour24))
  return out
}
