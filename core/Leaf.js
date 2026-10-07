.pragma library

// The end leaf: what sits on the bare paper right of 08 // INBOX on the
// handscroll, the twin of the weather leaf left of 01 // TIME. Nine kinds,
// the `endleaf` setting (core/Style.js); the designs are in
// docs/revision2 on the docs branch. Pure JavaScript: services/Leaf.qml
// reads the machine and bar/scroll/EndLeaf.qml draws what these return.

var KINDS = [
  { key: "okugaki", jp: "奥", word: "奥書", name: "Okugaki", label: "COLOPHON", detail: "The machine the scroll is set on, and seals" },
  { key: "koyomi",  jp: "暦", word: "暦",   name: "Koyomi",  label: "ALMANAC",  detail: "The month, the season, the moon" },
  { key: "kiki",    jp: "機", word: "機",   name: "Kiki",    label: "MACHINE",  detail: "CPU, memory, disk and heat" },
  { key: "shimai",  jp: "終", word: "終い", name: "Shimai",  label: "SESSION",  detail: "Lock, suspend, log out, restart, shut down" },
  { key: "iro",     jp: "色", word: "色",   name: "Iro",     label: "THEMES",   detail: "Omarchy's themes, to switch" },
  { key: "dougu",   jp: "具", word: "道具", name: "Dōgu",    label: "TOOLS",    detail: "Omarchy's utilities, one click each" },
  { key: "shuchu",  jp: "集", word: "集中", name: "Shūchū",  label: "FOCUS",    detail: "A focus timer" },
  { key: "hikae",   jp: "控", word: "控え", name: "Hikae",   label: "NOTES",    detail: "Today's list and the clipboard" },
  { key: "batsu",   jp: "跋", word: "跋",   name: "Batsu",   label: "AFTERWORD", detail: "The end of the scroll" }
]

function kindOf(key) {
  for (var i = 0; i < KINDS.length; i++) if (KINDS[i].key === key) return KINDS[i]
  return KINDS[1]
}

// value -> kanji, for the Typesetting row's segmented control.
function labels() {
  var out = {}
  for (var i = 0; i < KINDS.length; i++) out[KINDS[i].key] = KINDS[i].jp
  return out
}

function trim(s) { return String(s === undefined || s === null ? "" : s).replace(/^\s+|\s+$/g, "") }
function two(n) { return (n < 10 ? "0" : "") + n }
function num(v, d) { var n = parseFloat(v); return isNaN(n) ? (d === undefined ? 0 : d) : n }
// 1214 -> "1,214"
function grouped(n) { return String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ",") }

var MONTHS = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"]
var DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var NUMBERS = ["Nothing", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
function counted(n) { return n >= 0 && n < NUMBERS.length ? NUMBERS[n] : String(n) }

// 279000 s -> "3 days 5 hours"; under a day "5 hours 12 min".
function uptime(seconds) {
  var s = Math.max(0, Math.floor(num(seconds)))
  var d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
  function u(n, w) { return n + " " + w + (n === 1 ? "" : "s") }
  if (d > 0) return u(d, "day") + (h ? " " + u(h, "hour") : "")
  if (h > 0) return u(h, "hour") + " " + m + " min"
  return m + " min"
}
// The short form for captions: "3 days", "5 hours", "12 min".
function uptimeShort(seconds) {
  var s = Math.max(0, Math.floor(num(seconds)))
  var d = Math.floor(s / 86400), h = Math.floor(s / 3600)
  if (d > 0) return d + (d === 1 ? " day" : " days")
  if (h > 0) return h + (h === 1 ? " hour" : " hours")
  return Math.floor(s / 60) + " min"
}

// Omarchy's theme slug as its theme list prints it ("tokyo-night" ->
// "Tokyo Night"), the same sed omarchy-theme-list runs.
function themeName(slug) {
  return trim(slug).replace(/(^|-)([a-z])/g, function(m, a, b) { return a + b.toUpperCase() }).replace(/-/g, " ")
}

// Lines of `key<TAB>value` -> { key: value }.
function keyValues(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var t = lines[i].indexOf("\t")
    if (t > 0) out[trim(lines[i].slice(0, t))] = trim(lines[i].slice(t + 1))
  }
  return out
}

// ------------------------------------------------------- okugaki 奥書
//
// The colophon a handscroll ends with: who made it, on what, when. Here:
// the machine. `raw` is services/Leaf.qml's colophon script output.
function colophon(raw, extra) {
  var kv = keyValues(raw)
  var x = extra || {}
  var host = kv.host || ""
  var model = kv.model || ""
  if (/^(none|default string|to be filled.*|system product name|not specified)$/i.test(model)) model = ""
  var packages = parseInt(kv.packages, 10)
  var theme = themeName(kv.theme || "")
  var who = trim(kv.name) || trim(kv.user)
  var rows = [
    { k: "Host", v: host + (model ? " · " + model : "") },
    { k: "Kernel", v: kv.kernel || "" },
    { k: "Hyprland", v: kv.hyprland || "" },
    { k: "Packages", v: isNaN(packages) ? "" : grouped(packages) + (kv.upgraded ? " · upgraded " + kv.upgraded : "") },
    { k: "Theme", v: theme, italic: true },
    { k: "Font", v: x.font || "" },
    { k: "Bar", v: "Hanko " + (x.version || "") + (x.preset ? " · " + x.preset : "") }
  ].filter(function(r) { return trim(r.v) !== "" && r.v !== "Hanko " })
  return {
    title: host ? "Set on <i>" + host + "</i>" : "Set on <i>this machine</i>",
    caption: [kv.omarchy ? "Omarchy " + kv.omarchy : "", kv.uptime ? "up " + uptimeShort(kv.uptime) : ""].filter(function(s) { return s }).join(" · "),
    rows: rows,
    // Collectors' seals: you, your theme, Hanko.
    seals: [
      { glyph: who ? Array.from(who)[0].toUpperCase() : "人", word: "You", solid: true },
      { glyph: theme ? Array.from(theme)[0] : "色", word: "Theme", solid: false },
      { glyph: "判", word: "Hanko", solid: false }
    ],
    ready: !!host
  }
}

// ------------------------------------------------------- koyomi 暦
//
// The 24 solar terms (sekki) and 72 microseasons (kō) of the Japanese
// almanac, by the day each starts in an ordinary year (they move by a day
// or so year to year; good enough for a calendar on a bar).
var SEKKI = [
  ["立春", "Risshun", "start of spring", 2, 4], ["雨水", "Usui", "rain water", 2, 19],
  ["啓蟄", "Keichitsu", "insects awaken", 3, 6], ["春分", "Shunbun", "spring equinox", 3, 21],
  ["清明", "Seimei", "clear and bright", 4, 5], ["穀雨", "Kokuu", "grain rain", 4, 20],
  ["立夏", "Rikka", "start of summer", 5, 5], ["小満", "Shōman", "lesser ripening", 5, 21],
  ["芒種", "Bōshu", "grain in ear", 6, 6], ["夏至", "Geshi", "summer solstice", 6, 21],
  ["小暑", "Shōsho", "lesser heat", 7, 7], ["大暑", "Taisho", "greater heat", 7, 23],
  ["立秋", "Risshū", "start of autumn", 8, 7], ["処暑", "Shosho", "end of heat", 8, 23],
  ["白露", "Hakuro", "white dew", 9, 7], ["秋分", "Shūbun", "autumn equinox", 9, 23],
  ["寒露", "Kanro", "cold dew", 10, 8], ["霜降", "Sōkō", "frost falls", 10, 23],
  ["立冬", "Rittō", "start of winter", 11, 7], ["小雪", "Shōsetsu", "lesser snow", 11, 22],
  ["大雪", "Taisetsu", "greater snow", 12, 7], ["冬至", "Tōji", "winter solstice", 12, 22],
  ["小寒", "Shōkan", "lesser cold", 1, 5], ["大寒", "Daikan", "greater cold", 1, 20]
]
var SEASONS = ["spring", "summer", "autumn", "winter"]

// Kō 1..72 (kanji, English, month, day), from 東風解凍 on 4 February.
var KO = [
  ["東風解凍", "east wind melts the ice", 2, 4], ["黄鶯睍睆", "bush warblers sing", 2, 9], ["魚上氷", "fish rise from the ice", 2, 14],
  ["土脉潤起", "rain moistens the soil", 2, 19], ["霞始靆", "mist starts to linger", 2, 24], ["草木萌動", "grass sprouts, trees bud", 3, 1],
  ["蟄虫啓戸", "insects come out", 3, 6], ["桃始笑", "first peach blossoms", 3, 11], ["菜虫化蝶", "caterpillars become butterflies", 3, 16],
  ["雀始巣", "sparrows start to nest", 3, 21], ["櫻始開", "first cherry blossoms", 3, 26], ["雷乃発声", "distant thunder", 3, 31],
  ["玄鳥至", "swallows return", 4, 5], ["鴻雁北", "wild geese fly north", 4, 10], ["虹始見", "first rainbows", 4, 15],
  ["葭始生", "first reeds sprout", 4, 20], ["霜止出苗", "last frost, rice seedlings", 4, 25], ["牡丹華", "peonies bloom", 4, 30],
  ["蛙始鳴", "frogs start singing", 5, 5], ["蚯蚓出", "worms surface", 5, 10], ["竹笋生", "bamboo shoots sprout", 5, 15],
  ["蚕起食桑", "silkworms feast on mulberry", 5, 21], ["紅花栄", "safflowers bloom", 5, 26], ["麦秋至", "wheat ripens", 5, 31],
  ["螳螂生", "praying mantises hatch", 6, 6], ["腐草為螢", "fireflies over the grass", 6, 11], ["梅子黄", "plums turn yellow", 6, 16],
  ["乃東枯", "self-heal withers", 6, 21], ["菖蒲華", "irises bloom", 6, 26], ["半夏生", "crow-dipper sprouts", 7, 2],
  ["温風至", "warm winds blow", 7, 7], ["蓮始開", "first lotus blossoms", 7, 12], ["鷹乃学習", "hawks learn to fly", 7, 17],
  ["桐始結花", "paulownia seeds", 7, 23], ["土潤溽暑", "damp earth, humid air", 7, 28], ["大雨時行", "great rains fall", 8, 2],
  ["涼風至", "cool winds blow", 8, 7], ["寒蝉鳴", "evening cicadas sing", 8, 12], ["蒙霧升降", "thick fog descends", 8, 17],
  ["綿柎開", "cotton flowers open", 8, 23], ["天地始粛", "the heat dies down", 8, 28], ["禾乃登", "rice ripens", 9, 2],
  ["草露白", "dew glistens on the grass", 9, 7], ["鶺鴒鳴", "wagtails sing", 9, 12], ["玄鳥去", "swallows leave", 9, 17],
  ["雷乃収声", "thunder ceases", 9, 23], ["蟄虫坏戸", "insects hole up", 9, 28], ["水始涸", "farmers drain their fields", 10, 3],
  ["鴻雁来", "wild geese return", 10, 8], ["菊花開", "chrysanthemums bloom", 10, 13], ["蟋蟀在戸", "crickets at the door", 10, 18],
  ["霜始降", "first frost", 10, 23], ["霎時施", "light rains fall", 10, 28], ["楓蔦黄", "maple and ivy turn", 11, 2],
  ["山茶始開", "camellias bloom", 11, 7], ["地始凍", "the land starts to freeze", 11, 12], ["金盞香", "daffodils bloom", 11, 17],
  ["虹蔵不見", "rainbows hide", 11, 22], ["朔風払葉", "north wind strips the leaves", 11, 27], ["橘始黄", "tachibana leaves yellow", 12, 2],
  ["閉塞成冬", "cold sets in, winter begins", 12, 7], ["熊蟄穴", "bears go to their dens", 12, 12], ["鱖魚群", "salmon gather upstream", 12, 16],
  ["乃東生", "self-heal sprouts", 12, 22], ["麋角解", "deer shed their antlers", 12, 26], ["雪下出麦", "wheat sprouts under snow", 12, 31],
  ["芹乃栄", "parsley flourishes", 1, 5], ["水泉動", "springs thaw", 1, 10], ["雉始雊", "pheasants start to call", 1, 15],
  ["款冬華", "butterburs bud", 1, 20], ["水沢腹堅", "ice thickens on streams", 1, 25], ["鶏始乳", "hens start laying", 1, 30]
]

// The entry of a (month, day) table that `d` falls in: the last one that
// started on or before it, wrapping round the new year.
function termIndex(table, d) {
  var md = (d.getMonth() + 1) * 100 + d.getDate()
  var best = -1, bestMd = -1
  for (var i = 0; i < table.length; i++) {
    var t = table[i][table[i].length - 2] * 100 + table[i][table[i].length - 1]
    if (t <= md && t > bestMd) { best = i; bestMd = t }
  }
  if (best >= 0) return best
  // Before the year's first start (1-4 January): the last one of last year.
  for (var j = 0; j < table.length; j++) {
    var u = table[j][table[j].length - 2] * 100 + table[j][table[j].length - 1]
    if (u > bestMd) { best = j; bestMd = u }
  }
  return best
}

function startOf(entry, year) {
  return new Date(year, entry[entry.length - 2] - 1, entry[entry.length - 1])
}

// The next start of a table entry after `d`.
function nextStart(entry, d) {
  var s = startOf(entry, d.getFullYear())
  if (s <= d) s = startOf(entry, d.getFullYear() + 1)
  return s
}

// The moon: age in days since new, how much is lit, waxing or waning, and
// the next new and full moons. From the mean synodic month and a known new
// moon (6 January 2000, 18:14 UTC): within about half a day, plenty here.
var SYNODIC = 29.530588853
var NEW_MOON = Date.UTC(2000, 0, 6, 18, 14)
function moon(d) {
  var days = (d.getTime() - NEW_MOON) / 86400000
  var age = ((days % SYNODIC) + SYNODIC) % SYNODIC
  var lit = (1 - Math.cos(2 * Math.PI * age / SYNODIC)) / 2
  var toNew = SYNODIC - age
  var toFull = age < SYNODIC / 2 ? SYNODIC / 2 - age : SYNODIC * 1.5 - age
  var nextNew = new Date(d.getTime() + toNew * 86400000)
  var nextFull = new Date(d.getTime() + toFull * 86400000)
  var waxing = age < SYNODIC / 2
  var next = toNew < toFull ? { word: "New", date: nextNew } : { word: "Full", date: nextFull }
  return {
    age: age,
    lit: lit,
    percent: Math.round(lit * 100),
    waxing: waxing,
    phase: age < 1.5 || age > SYNODIC - 1.5 ? "new" : Math.abs(age - SYNODIC / 2) < 1.5 ? "full"
      : (waxing ? (lit < 0.5 ? "waxing crescent" : "waxing gibbous") : (lit < 0.5 ? "waning crescent" : "waning gibbous")),
    next: next.word + " · " + ordinal(next.date.getDate()),
    nextDate: next.date
  }
}

function ordinal(n) {
  var s = (n % 100 >= 11 && n % 100 <= 13) ? "th" : ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
  return n + s
}

function dayOfYear(d) {
  var start = new Date(d.getFullYear(), 0, 1)
  return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - start) / 86400000) + 1
}
function daysInYear(y) { return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0 ? 366 : 365 }

// The whole leaf for `d`: a Monday-first month grid (35 or 42 cells), the
// solar term and microseason we are in and the next term, the moon, and
// how far through the year we are.
function almanac(d) {
  var y = d.getFullYear(), m = d.getMonth()
  var first = new Date(y, m, 1)
  var lead = (first.getDay() + 6) % 7
  var count = new Date(y, m + 1, 0).getDate()
  var si = termIndex(SEKKI, d)
  var ki = termIndex(KO, d)
  var sekki = SEKKI[si], nextSekki = SEKKI[(si + 1) % SEKKI.length]
  var nextAt = nextStart(nextSekki, d)
  var cells = []
  var total = lead + count <= 35 ? 35 : 42
  for (var i = 0; i < total; i++) {
    var day = i - lead + 1
    var inMonth = day >= 1 && day <= count
    cells.push({
      day: inMonth ? day : 0,
      label: inMonth ? two(day) : "",
      today: inMonth && day === d.getDate(),
      past: inMonth && day < d.getDate(),
      weekend: i % 7 >= 5,
      // The day the next solar term starts, when it falls this month.
      term: inMonth && nextAt.getFullYear() === y && nextAt.getMonth() === m && nextAt.getDate() === day
    })
  }
  var doy = dayOfYear(d), diy = daysInYear(y)
  var season = SEASONS[Math.floor(((si + 24) % 24) / 6)]
  return {
    month: MONTHS[m],
    year: y,
    cells: cells,
    sekki: { jp: sekki[0], name: sekki[1], english: sekki[2], season: season },
    ko: { no: ki + 1, jp: KO[ki][0], english: KO[ki][1] },
    next: { jp: nextSekki[0], name: nextSekki[1], english: nextSekki[2], day: nextAt.getDate(), date: nextAt },
    moon: moon(d),
    day: doy,
    days: diy,
    yearDone: (doy - 1 + (d.getHours() * 60 + d.getMinutes()) / 1440) / diy,
    title: sekki[1] + ", <i>" + season + "</i>",
    caption: "Kō " + (ki + 1) + " · " + KO[ki][1]
  }
}

// ------------------------------------------------------- kiki 機
//
// /proc/stat's first line -> { idle, total } jiffies.
function cpuTimes(stat) {
  var line = String(stat || "").split("\n")[0] || ""
  var f = line.trim().split(/\s+/)
  if (f[0] !== "cpu") return null
  var total = 0
  for (var i = 1; i < f.length; i++) total += num(f[i])
  // idle + iowait count as idle, as top does.
  return { idle: num(f[4]) + num(f[5]), total: total }
}

// Busy share 0..1 between two samples.
function cpuBusy(a, b) {
  if (!a || !b) return null
  var dt = b.total - a.total
  if (dt <= 0) return null
  return Math.max(0, Math.min(1, 1 - (b.idle - a.idle) / dt))
}

// /proc/meminfo -> { used, total } in bytes.
function memory(text) {
  var kv = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^(\w+):\s+(\d+)/.exec(lines[i])
    if (m) kv[m[1]] = parseInt(m[2], 10) * 1024
  }
  if (!kv.MemTotal) return null
  var avail = kv.MemAvailable !== undefined ? kv.MemAvailable : (kv.MemFree || 0)
  return { used: kv.MemTotal - avail, total: kv.MemTotal }
}

// The CPU temperature in °C from lines of `name milli°C` (hwmon names,
// thermal zone types): a CPU sensor if there is one, else the warmest.
var CPU_SENSORS = ["coretemp", "k10temp", "zenpower", "x86_pkg_temp", "cpu_thermal", "cpu-thermal", "soc_thermal", "acpitz"]
function temperature(text) {
  var best = null, rank = 99, warmest = null
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].trim().split(/\s+/)
    if (f.length < 2) continue
    var c = num(f[1], NaN) / 1000
    if (isNaN(c) || c <= 0 || c > 150) continue
    var r = CPU_SENSORS.indexOf(f[0])
    if (r >= 0 && r < rank) { rank = r; best = c }
    if (warmest === null || c > warmest) warmest = c
  }
  var t = best !== null ? best : warmest
  return t === null ? null : Math.round(t)
}

// `df -B1 --output=size,used /` -> { used, total }.
function disk(text) {
  var lines = String(text || "").trim().split("\n")
  for (var i = lines.length - 1; i >= 0; i--) {
    var f = lines[i].trim().split(/\s+/)
    var size = parseFloat(f[0]), used = parseFloat(f[1])
    if (!isNaN(size) && !isNaN(used) && size > 0) return { used: used, total: size }
  }
  return null
}

// Lines of `command<TAB>%cpu` -> the top three, busiest first.
function top(text) {
  var out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length && out.length < 3; i++) {
    var t = lines[i].lastIndexOf("\t")
    if (t <= 0) continue
    var name = trim(lines[i].slice(0, t)), cpu = num(lines[i].slice(t + 1), NaN)
    if (!name || isNaN(cpu)) continue
    out.push({ name: name, cpu: cpu })
  }
  return out.sort(function(a, b) { return b.cpu - a.cpu })
}

// "7.4 / 32 GB": used and total, the unit once when they share it.
function pair(used, total) {
  var a = bytes(used), b = bytes(total)
  var ua = a.split(" ")[1], ub = b.split(" ")[1]
  return (ua === ub ? a.split(" ")[0] : a) + " / " + b
}

// 7.4e9 -> "7.4 GB" (decimal, like df -H and most panels).
function bytes(n) {
  var v = num(n)
  if (v >= 1e12) return (v / 1e12).toFixed(v >= 1e13 ? 0 : 1) + " TB"
  if (v >= 1e9) return (v / 1e9).toFixed(v >= 1e10 ? 0 : 1) + " GB"
  return Math.round(v / 1e6) + " MB"
}

function cpuWord(p) {
  return p < 0.15 ? "quiet" : p < 0.4 ? "working" : p < 0.75 ? "busy" : "straining"
}

// The leaf's view of a reading { cpu, cores, load, mem, disk, temp,
// history (0..1 per minute, oldest first), top }.
function machine(r) {
  if (!r || r.cpu === null || r.cpu === undefined) return { ready: false, title: "—", caption: "Reading the machine", rows: [], history: [], top: "" }
  var cpu = r.cpu
  var rows = [{ k: "CPU", at: cpu, v: Math.round(cpu * 100) + "%" }]
  if (r.mem) rows.push({ k: "Memory", at: r.mem.used / r.mem.total, v: pair(r.mem.used, r.mem.total) })
  if (r.disk) rows.push({ k: "Disk", at: r.disk.used / r.disk.total, v: pair(r.disk.used, r.disk.total) })
  if (r.temp !== null && r.temp !== undefined) rows.push({ k: "Heat", at: Math.max(0, Math.min(1, (r.temp - 25) / 75)), v: r.temp + "°C", hot: r.temp >= 85 })
  var history = (r.history || []).slice(-60)
  var peak = 0, peakAt = -1
  for (var i = 0; i < history.length; i++) if (history[i] > peak) { peak = history[i]; peakAt = i }
  return {
    ready: true,
    title: Math.round(cpu * 100) + "%, <i>" + cpuWord(cpu) + "</i>",
    caption: [r.cores ? r.cores + (r.cores === 1 ? " core" : " cores") : "", r.temp !== null && r.temp !== undefined ? r.temp + "°C" : "",
              r.load !== undefined && r.load !== null ? "load " + Number(r.load).toFixed(2) : ""].filter(function(s) { return s }).join(" · "),
    rows: rows,
    history: history,
    peak: peak,
    peakAt: peakAt,
    peakLabel: peakAt >= 0 && peak >= 0.05 ? Math.round(peak * 100) + "% peak" : "",
    top: (r.top || []).slice(0, 2).map(function(p) { return p.name + " " + Math.round(p.cpu) + "%" }).join(" · ")
  }
}

// ------------------------------------------------------- shimai 終
//
// Omarchy's own system menu actions (default/omarchy/omarchy-menu.jsonc).
var SESSION = [
  { key: "lock",     jp: "鍵", name: "Lock",      command: ["omarchy-system-lock"] },
  { key: "suspend",  jp: "眠", name: "Suspend",   command: ["systemctl", "suspend"] },
  { key: "logout",   jp: "出", name: "Log out",   command: ["omarchy-system-logout"] },
  { key: "reboot",   jp: "再", name: "Restart",   command: ["omarchy-system-reboot"] },
  { key: "shutdown", jp: "止", name: "Shut down", command: ["omarchy-system-shutdown"] }
]
function sessionAction(key) {
  for (var i = 0; i < SESSION.length; i++) if (SESSION[i].key === key) return SESSION[i]
  return null
}

// ------------------------------------------------------- iro 色
//
// services/Leaf.qml's theme script prints `slug<TAB>bg<TAB>fg<TAB>red<TAB>mode`
// per theme, the user's own copies first; Omarchy's list keeps one of each.
function themes(text) {
  var seen = {}, out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split("\t")
    var slug = trim(f[0])
    if (!slug || seen[slug]) continue
    var bg = trim(f[1]), fg = trim(f[2]), red = trim(f[3])
    if (!/^#[0-9a-fA-F]{6}$/.test(bg) || !/^#[0-9a-fA-F]{6}$/.test(fg)) continue
    seen[slug] = true
    out.push({ slug: slug, name: themeName(slug), bg: bg, fg: fg,
               red: /^#[0-9a-fA-F]{6}$/.test(red) ? red : fg, light: trim(f[4]) === "light" })
  }
  return out.sort(function(a, b) { return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : a.name.toLowerCase() > b.name.toLowerCase() ? 1 : 0 })
}

// `n` themes to show around the current one (it sits second when it can,
// so the one before it shows too), wrapping round the list.
function themeWindow(list, current, n) {
  var count = Math.min(n, list.length)
  if (!count) return []
  var at = 0
  for (var i = 0; i < list.length; i++) if (list[i].slug === current) at = i
  var start = list.length > count ? at - 1 : 0
  var out = []
  for (var k = 0; k < count; k++) out.push(list[((start + k) % list.length + list.length) % list.length])
  return out
}

function themesView(list, current, n) {
  var cur = null
  for (var i = 0; i < list.length; i++) if (list[i].slug === current) cur = list[i]
  var shown = themeWindow(list, current, n)
  return {
    title: cur ? cur.name + ", <i>" + (cur.light ? "light" : "dark") + "</i>" : (current ? themeName(current) : "Themes"),
    caption: list.length + (list.length === 1 ? " theme" : " themes") + " · click one to switch",
    shown: shown,
    more: Math.max(0, list.length - shown.length)
  }
}

// ------------------------------------------------------- dougu 具
//
// Omarchy's utilities as its own keys run them (default/hypr/bindings/
// utilities.lua and clipboard.lua). The ones that look at the screen wait
// for the scroll to roll up first. `state` names the switch a tool shows.
var TOOLS = [
  { key: "screenshot", jp: "写", name: "Screenshot", command: "sleep 0.4; omarchy-capture-screenshot", closes: true },
  { key: "record",     jp: "録", name: "Record",     command: "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord", closes: true, state: "recording" },
  { key: "picker",     jp: "色", name: "Picker", command: "sleep 0.4; pkill hyprpicker || hyprpicker -a", closes: true },
  { key: "awake",      jp: "覚", name: "Stay awake", state: "awake" },
  { key: "night",      jp: "夜", name: "Night", state: "night" },
  { key: "silence",    jp: "静", name: "Silence",    state: "dnd" },
  { key: "emoji",      jp: "字", name: "Emoji",      command: "omarchy-shell shell toggle omarchy.emojis", closes: true },
  { key: "clipboard",  jp: "板", name: "Clipboard",  command: "omarchy-shell shell toggle omarchy.clipboard", closes: true },
  { key: "lock",       jp: "鍵", name: "Lock",       command: "omarchy-system-lock", closes: true }
]
function tool(key) {
  for (var i = 0; i < TOOLS.length; i++) if (TOOLS[i].key === key) return TOOLS[i]
  return null
}
// What is on, as a line under the tiles.
function toolsLine(state) {
  var s = state || {}
  var on = []
  if (s.recording) on.push("recording")
  if (s.awake) on.push("staying awake")
  if (s.night) on.push("night light on")
  if (s.dnd) on.push("silenced")
  if (!on.length) return "Nothing is on"
  var line = on.join(" · ")
  return line.charAt(0).toUpperCase() + line.slice(1)
}

// ------------------------------------------------------- shuchu 集
//
// A focus timer kept in ~/.local/state/hanko/focus.json:
// { kind: "idle"|"focus"|"break", endsAt, pausedLeft (ms, when paused),
//   length (min), day ("2026-10-06"), done (sessions that day) }.
var FOCUS_MIN = 25
var BREAK_MIN = 5
var GOAL = 4

function dayKey(d) { return d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate()) }

function focusState(raw) {
  var s = {}
  try { s = JSON.parse(String(raw || "{}")) || {} } catch (e) { s = {} }
  var kind = s.kind === "focus" || s.kind === "break" ? s.kind : "idle"
  return {
    kind: kind,
    endsAt: num(s.endsAt),
    pausedLeft: s.pausedLeft === null || s.pausedLeft === undefined ? null : num(s.pausedLeft),
    length: Math.max(1, Math.round(num(s.length, kind === "break" ? BREAK_MIN : FOCUS_MIN))),
    day: typeof s.day === "string" ? s.day : "",
    done: Math.max(0, Math.round(num(s.done)))
  }
}

function left(s, now) {
  if (s.kind === "idle") return 0
  if (s.pausedLeft !== null) return Math.max(0, s.pausedLeft)
  return Math.max(0, s.endsAt - now)
}

// mm:ss
function clock(ms) {
  var t = Math.ceil(Math.max(0, ms) / 1000)
  return two(Math.floor(t / 60)) + ":" + two(t % 60)
}

// What the timer does next: start, pause, resume, add five minutes, skip
// (end this part now) or tick (time passing). Returns the new state and,
// when a part ends, what to tell you.
function focusStep(s, what, now) {
  var n = { kind: s.kind, endsAt: s.endsAt, pausedLeft: s.pausedLeft, length: s.length, day: s.day, done: s.done }
  var today = dayKey(new Date(now))
  if (n.day !== today) { n.day = today; n.done = 0 }
  var said = ""
  function begin(kind, min) { n.kind = kind; n.length = min; n.endsAt = now + min * 60000; n.pausedLeft = null }
  function finish() {
    if (n.kind === "focus") {
      n.done += 1
      said = n.done >= GOAL ? "Focus done · that's " + n.done + " today" : "Focus done · take five"
      begin("break", BREAK_MIN)
    } else if (n.kind === "break") {
      said = "Break over"
      n.kind = "idle"; n.pausedLeft = null; n.endsAt = 0
    }
  }
  if (what === "start") begin("focus", FOCUS_MIN)
  else if (what === "pause" && n.kind !== "idle" && n.pausedLeft === null) n.pausedLeft = Math.max(0, n.endsAt - now)
  else if (what === "resume" && n.pausedLeft !== null) { n.endsAt = now + n.pausedLeft; n.pausedLeft = null }
  else if (what === "more" && n.kind !== "idle") {
    if (n.pausedLeft !== null) n.pausedLeft += 5 * 60000
    else n.endsAt += 5 * 60000
    n.length += 5
  } else if (what === "skip" && n.kind !== "idle") {
    if (n.kind === "focus") { n.kind = "idle"; n.pausedLeft = null; n.endsAt = 0 }
    else finish()
  } else if (what === "stop") { n.kind = "idle"; n.pausedLeft = null; n.endsAt = 0 }
  else if (what === "tick" && n.kind !== "idle" && n.pausedLeft === null && now >= n.endsAt) finish()
  return { state: n, said: said }
}

function focusView(s, now) {
  var today = dayKey(new Date(now))
  var done = s.day === today ? s.done : 0
  var ms = left(s, now)
  var total = s.length * 60000
  var paused = s.pausedLeft !== null && s.kind !== "idle"
  var title, caption
  if (s.kind === "idle") {
    title = FOCUS_MIN + ":00, <i>ready</i>"
    caption = done ? done + " of " + GOAL + " today · start another" : "Twenty-five minutes · start when you are"
  } else {
    title = clock(ms) + ", <i>" + (paused ? "paused" : s.kind === "focus" ? "focus" : "break") + "</i>"
    var ends = new Date(now + ms)
    caption = s.kind === "focus"
      ? "Session " + (done + 1) + " of " + Math.max(GOAL, done + 1) + (paused ? " · paused" : " · break at " + two(ends.getHours()) + ":" + two(ends.getMinutes()))
      : "Five minutes off" + (paused ? " · paused" : " · back at " + two(ends.getHours()) + ":" + two(ends.getMinutes()))
  }
  return {
    kind: s.kind,
    paused: paused,
    title: title,
    caption: caption,
    // How far through this part, 0..1, and its length in minutes.
    at: s.kind === "idle" ? 0 : Math.max(0, Math.min(1, 1 - ms / total)),
    minutes: s.kind === "idle" ? FOCUS_MIN : s.length,
    done: done,
    goal: Math.max(GOAL, done)
  }
}

// ------------------------------------------------------- hikae 控
//
// Today's list: a plain Markdown file. `- [ ] thing` and `- [x] thing` are
// items you can tick; any other non-empty line that isn't a heading shows
// as plain text.
var NOTES_PATH = "/.config/hanko/notes.md"

function notes(text) {
  var items = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var l = lines[i]
    var m = /^\s*[-*+]\s+\[( |x|X)\]\s+(.*)$/.exec(l)
    if (m) { items.push({ text: trim(m[2]), done: m[1] !== " ", box: true, line: i }); continue }
    var t = trim(l)
    if (!t || /^#/.test(t)) continue
    items.push({ text: t.replace(/^[-*+]\s+/, ""), done: false, box: false, line: i })
  }
  return items
}

// Ticks or unticks the item on `line`.
function toggled(text, line) {
  var lines = String(text || "").split("\n")
  var l = lines[line]
  if (l === undefined) return String(text || "")
  var m = /^(\s*[-*+]\s+\[)( |x|X)(\]\s+.*)$/.exec(l)
  if (!m) return String(text || "")
  lines[line] = m[1] + (m[2] === " " ? "x" : " ") + m[3]
  return lines.join("\n")
}

function notesView(items, exists) {
  var open = items.filter(function(i) { return i.box && !i.done }).length
  var boxes = items.filter(function(i) { return i.box }).length
  return {
    title: !exists ? "A blank <i>page</i>" : boxes ? counted(open) + " <i>to do</i>" : counted(items.length) + " <i>" + (items.length === 1 ? "note" : "notes") + "</i>",
    shown: items.slice(0, 5),
    more: Math.max(0, items.length - 5)
  }
}

// Omarchy's clipboard history (~/.local/state/omarchy/clipboard-history.json,
// newest first) -> the last three, as one line each.
function clipboard(raw) {
  var list = []
  try { list = JSON.parse(String(raw || "[]")) } catch (e) { list = [] }
  if (!Array.isArray(list)) return []
  var out = []
  for (var i = 0; i < list.length && out.length < 3; i++) {
    var v = list[i]
    if (typeof v === "string") v = { type: "text", text: v }
    if (!v || typeof v !== "object") continue
    if (v.type === "image") out.push({ index: i, text: "Image", image: true })
    else {
      var t = String(v.text || "").replace(/\s+/g, " ").trim()
      if (t) out.push({ index: i, text: t, image: false })
    }
  }
  return out
}

// ------------------------------------------------------- batsu 跋
var ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
function afterword(d, sections) {
  return {
    line: counted(sections) + " sections · " + DAYS[d.getDay()] + " " + two(d.getDate()) + " · " + ROMAN[d.getMonth()] + " · " + d.getFullYear()
  }
}

// ------------------------------------------------------- sample
//
// A reading for the settings page's gallery (and the harness), in the
// shape services/Leaf.qml gives: what each leaf looks like on a quiet
// afternoon.
function sample(now) {
  var t = now.getTime()
  return {
    colophon: "host\tkumo\nmodel\tThinkPad X1 Carbon\nkernel\t6.17.2-arch1-1\npackages\t1214\nupgraded\tMon 05 Oct\n"
      + "omarchy\t3.1.4\nhyprland\t0.51.0\nuptime\t279000\nuser\tayush\nname\tAyush\ntheme\tkanagawa\n",
    machine: { cpu: 0.12, cores: 8, load: 0.42, mem: { used: 7.4e9, total: 32e9 }, disk: { used: 268e9, total: 465e9 }, temp: 41,
      history: [0.09, 0.11, 0.08, 0.14, 0.22, 0.18, 0.12, 0.1, 0.34, 0.61, 0.48, 0.22, 0.15, 0.12, 0.11, 0.09, 0.13, 0.17, 0.12, 0.1,
        0.09, 0.14, 0.12, 0.12, 0.1, 0.09, 0.11, 0.1, 0.13, 0.12],
      top: [{ name: "firefox", cpu: 6.1 }, { name: "Hyprland", cpu: 2.3 }] },
    uptime: 279000,
    themes: [
      { slug: "everforest", name: "Everforest", bg: "#2d353b", fg: "#d3c6aa", red: "#e67e80", light: false },
      { slug: "gruvbox", name: "Gruvbox", bg: "#282828", fg: "#ebdbb2", red: "#fb4934", light: false },
      { slug: "kanagawa", name: "Kanagawa", bg: "#1f1f28", fg: "#dcd7ba", red: "#c34043", light: false },
      { slug: "nord", name: "Nord", bg: "#2e3440", fg: "#d8dee9", red: "#bf616a", light: false },
      { slug: "rose-pine", name: "Rose Pine", bg: "#faf4ed", fg: "#575279", red: "#b4637a", light: true },
      { slug: "tokyo-night", name: "Tokyo Night", bg: "#1a1b26", fg: "#a9b1d6", red: "#f7768e", light: false },
      { slug: "catppuccin", name: "Catppuccin", bg: "#1e1e2e", fg: "#cdd6f4", red: "#f38ba8", light: false }
    ],
    theme: "kanagawa",
    recording: false,
    focus: { kind: "focus", endsAt: t + 18 * 60000 + 42000, pausedLeft: null, length: 25, day: dayKey(now), done: 2 },
    clockNow: t,
    notes: "# Today\n\n- [x] Test Hanko on the laptop\n- [ ] Reply to Kenji about the scroll\n- [ ] Pick a release name\n- [ ] Print the Typeset sheets\n",
    notesExist: true,
    clipboard: JSON.stringify([{ type: "text", text: "git push -u origin dev" }, { type: "text", text: "#c34043" }, { type: "image", path: "/tmp/shot.png" }])
  }
}
