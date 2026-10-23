.pragma library

// Koyomi 暦, the almanac time sheet (docs/koyomi/README.md): one model of a
// month that every hand draws its own way. A month is always six weeks
// (the days of the months either side kept, faint), so turning a month
// never changes the sheet's height. Each day knows its solar term or
// microseason when one starts on it, the new and full moons, and the
// forecast when there is one; the picked day gets a leaf of its own.
//
// Pure JavaScript. The sun comes from core/Season.js and the moon from
// core/Almanac.js, passed in as lib = { Se: Season.js, Al: Almanac.js }, as
// Hands.js takes its own; nothing here knows how a hand looks.

var MONTH_KANJI = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
var MONTHS = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"]
// Monday first, as every Hanko week is.
var WEEK = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
var WEEK_KANJI = ["月", "火", "水", "木", "金", "土", "日"]
var DAY_KANJI = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"]

// The old month names (wafū getsumei 和風月名), still printed on Japanese
// calendars beside the numbered month.
var WAFU = [
  ["睦月", "Mutsuki", "the month of harmony"], ["如月", "Kisaragi", "the month of layered robes"],
  ["弥生", "Yayoi", "the month of new growth"], ["卯月", "Uzuki", "the month of deutzia"],
  ["皐月", "Satsuki", "the month of rice planting"], ["水無月", "Minazuki", "the month of water"],
  ["文月", "Fumizuki", "the month of letters"], ["葉月", "Hazuki", "the month of leaves"],
  ["長月", "Nagatsuki", "the month of long nights"], ["神無月", "Kannazuki", "the month without gods"],
  ["霜月", "Shimotsuki", "the month of frost"], ["師走", "Shiwasu", "the month the teachers run"]
]

// The four seasons, each six solar terms from its 立 (risshun, rikka…).
var SEASONS = [
  { key: "spring", jp: "春", name: "Spring" }, { key: "summer", jp: "夏", name: "Summer" },
  { key: "autumn", jp: "秋", name: "Autumn" }, { key: "winter", jp: "冬", name: "Winter" }
]

// The moon by its age in days, by the old names for the nights.
var MOONS = [
  [1.5, "新月", "New moon"], [5, "三日月", "Crescent"], [9, "上弦", "First quarter"],
  [13.3, "十三夜", "Thirteenth night"], [16, "満月", "Full moon"], [17.5, "十六夜", "Izayoi, the hesitant moon"],
  [20, "居待月", "The moon you sit up for"], [24, "下弦", "Last quarter"], [28, "有明月", "Dawn moon"], [99, "新月", "New moon"]
]

// WMO weather codes (Open-Meteo) as the one kanji a Japanese forecast
// prints: 晴 clear, 曇 cloud, 霧 fog, 雨 rain, 雪 snow, 雷 thunder.
// Each entry: the highest code it covers.
var SKY = [
  [0, "晴", "Clear"], [1, "晴", "Fair"], [2, "曇", "Partly cloudy"], [3, "曇", "Overcast"], [48, "霧", "Fog"],
  [57, "雨", "Drizzle"], [67, "雨", "Rain"], [77, "雪", "Snow"], [82, "雨", "Showers"], [86, "雪", "Snow showers"],
  [99, "雷", "Thunder"]
]
// Where the wind comes from, in eight.
var WINDS = [["北", "north"], ["北東", "north-east"], ["東", "east"], ["南東", "south-east"],
             ["南", "south"], ["南西", "south-west"], ["西", "west"], ["北西", "north-west"]]

var DAY_MS = 86400000

function pad2(n) { return (n < 10 ? "0" : "") + n }
function iso(d) { return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate()) }
function midnight(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()) }
function addDays(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n) }
// Whole days from a to b (local midnights, so a clock change is no day).
function daysBetween(a, b) { return Math.round((midnight(b) - midnight(a)) / DAY_MS) }
function dow(d) { return (d.getDay() + 6) % 7 }
function daysIn(y, m) { return new Date(y, m + 1, 0).getDate() }

// The same day `n` months on, kept inside the month (31 Jan + 1 → 28 Feb).
function addMonths(d, n) {
  var y = d.getFullYear(), m = d.getMonth() + n
  var first = new Date(y, m, 1)
  return new Date(first.getFullYear(), first.getMonth(), Math.min(d.getDate(), daysIn(first.getFullYear(), first.getMonth())))
}

// A day number in kanji, the way a calendar slip writes it: 六, 十六, 二十六.
function kanjiDay(n) {
  if (n <= 10) return n === 10 ? "十" : DAY_KANJI[n]
  var t = Math.floor(n / 10), o = n % 10
  return (t > 1 ? DAY_KANJI[t] : "") + "十" + (o ? DAY_KANJI[o] : "")
}

function seasonOfSekki(s) { return SEASONS[Math.floor(s / 6) % 4] }

// The microseason (kō, 0..71) at local midnight of `d`.
function koAt(d, Se) { return Se.koIndex(midnight(d)) }

// The kō that starts on `d` (it is in force by the next midnight and was
// not at this one), or -1.
function koStarting(d, Se) {
  var a = koAt(d, Se), b = koAt(addDays(d, 1), Se)
  return a === b ? -1 : b
}

// The first day of the kō, solar term or season `d` is in, and the first
// day of the next one: scanned day by day (a season is at most 95 days).
function span(d, Se, of) {
  var here = of(koAt(addDays(d, 1), Se))
  var start = midnight(d), end = addDays(d, 1)
  for (var i = 0; i < 100 && of(koAt(start, Se)) === here; i++) start = addDays(start, -1)
  for (var j = 0; j < 100 && of(koAt(addDays(end, 1), Se)) === here; j++) end = addDays(end, 1)
  return { start: start, end: end, days: daysBetween(start, end) }
}
function koOf(k) { return k }
function sekkiOf(k) { return Math.floor(k / 3) }
function seasonOf(k) { return Math.floor(k / 18) }

// The moon on `d`: its age at noon, name, how much is lit, and whether the
// new or full moon falls on that day.
function moonOn(d, Al) {
  var noon = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 12)
  var m = Al.moon(noon)
  var name = MOONS[MOONS.length - 1]
  for (var i = 0; i < MOONS.length; i++) if (m.age < MOONS[i][0]) { name = MOONS[i]; break }
  var a0 = Al.moon(midnight(d)).age, a1 = Al.moon(addDays(d, 1)).age
  var half = a0 < Al.SYNODIC / 2 && a1 >= Al.SYNODIC / 2
  return { age: m.age, lit: m.lit, waxing: m.waxing, jp: name[1], name: name[2],
           mark: a1 < a0 ? "new" : half ? "full" : "" }
}

// ---- weather (Open-Meteo, as Omarchy's own weather panel asks it)

function sky(code) {
  var c = Number(code)
  if (code === null || code === undefined || !isFinite(c)) return null
  for (var i = 0; i < SKY.length; i++) if (c <= SKY[i][0]) return { jp: SKY[i][1], word: SKY[i][2], code: c }
  return null
}

function wind(dir) {
  var w = WINDS[Math.round(((Number(dir) % 360) + 360) % 360 / 45) % 8]
  return { jp: w[0] + "風", from: w[1] }
}

// One request: the sky now and sixteen days ahead.
function url(latitude, longitude) {
  return "https://api.open-meteo.com/v1/forecast"
    + "?latitude=" + encodeURIComponent(String(latitude))
    + "&longitude=" + encodeURIComponent(String(longitude))
    + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,is_day"
    + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
    + "&timezone=auto&forecast_days=16"
}

// A place named in weather.json without coordinates, found by name.
function geocodeUrl(name) {
  return "https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&format=json&name=" + encodeURIComponent(String(name))
}
function geocoded(raw) {
  try {
    var r = JSON.parse(String(raw || "")).results[0]
    var lat = parseFloat(r.latitude), lon = parseFloat(r.longitude)
    if (isNaN(lat) || isNaN(lon)) return null
    return { name: String(r.name || ""), country: String(r.country || ""), latitude: lat, longitude: lon }
  } catch (e) {
    return null
  }
}

// Fahrenheit only where Omarchy's weather panel would use it.
function imperial(localeName, country) {
  var c = String(country || "").toLowerCase()
  if (/^(us|usa|united states( of america)?|liberia|myanmar|burma)$/.test(c)) return true
  if (c) return false
  var n = String(localeName || "").replace(".", "_")
  return /^en[_-](US|LR)($|[_.-])/.test(n) || /^my($|[_.-])/.test(n)
}
function degrees(c, imp) {
  if (c === null || c === undefined || !isFinite(Number(c))) return ""
  return Math.round(imp ? Number(c) * 9 / 5 + 32 : Number(c)) + "°"
}

// The answer → { now: { temp, feels, jp, word, wind, speed, day } | null,
//                days: { "2026-10-06": { jp, word, hi, lo, rain } } }
// (temperatures as written, "18°"; rain a percent or -1).
function forecast(raw, imp) {
  var out = { now: null, days: {} }
  var j
  try { j = typeof raw === "string" ? JSON.parse(raw) : raw } catch (e) { return out }
  if (!j || typeof j !== "object") return out
  var c = j.current
  if (c && c.temperature_2m !== undefined && c.temperature_2m !== null) {
    var s = sky(c.weather_code) || { jp: "", word: "" }
    out.now = { temp: degrees(c.temperature_2m, imp), feels: degrees(c.apparent_temperature, imp), jp: s.jp, word: s.word,
                wind: wind(c.wind_direction_10m), speed: Math.round(Number(c.wind_speed_10m) || 0), day: Number(c.is_day) !== 0 }
  }
  var d = j.daily
  if (d && d.time && d.time.length) {
    for (var i = 0; i < d.time.length; i++) {
      var k = sky(d.weather_code ? d.weather_code[i] : null)
      if (!k) continue
      var pp = d.precipitation_probability_max ? d.precipitation_probability_max[i] : null
      var p = pp === null || pp === undefined ? NaN : Number(pp)
      out.days[String(d.time[i]).slice(0, 10)] = {
        jp: k.jp, word: k.word,
        hi: degrees(d.temperature_2m_max ? d.temperature_2m_max[i] : null, imp),
        lo: degrees(d.temperature_2m_min ? d.temperature_2m_min[i] : null, imp),
        rain: isFinite(p) ? Math.round(p) : -1
      }
    }
  }
  return out
}

// ---- the month, the year, the picked day

// How a day stands from today, in words.
function fromToday(n) {
  if (n === 0) return "Today"
  if (n === 1) return "Tomorrow"
  if (n === -1) return "Yesterday"
  return n > 0 ? "In " + n + " days" : -n + " days ago"
}

// The six weeks around the month of `view`: [[cell × 7] × 6].
// cell: { key, date, day, jp, month, inMonth, today, past, picked, weekend,
//         dow, kanji (the weekday), ko (-1 or the kō starting), sekki (-1
//         or the term starting), term (its kanji), moon ("", "new", "full"),
//         sky (the forecast or null), offset (days from today) }
function weeks(view, today, picked, wx, lib) {
  var y = view.getFullYear(), m = view.getMonth()
  var first = new Date(y, m, 1)
  var start = addDays(first, -dow(first))
  var t0 = midnight(today), p0 = midnight(picked)
  var days = (wx && wx.days) || {}
  var out = []
  for (var w = 0; w < 6; w++) {
    var row = []
    for (var i = 0; i < 7; i++) {
      var d = addDays(start, w * 7 + i)
      var k = koStarting(d, lib.Se)
      var s = k >= 0 && k % 3 === 0 ? k / 3 : -1
      var off = daysBetween(t0, d)
      row.push({
        key: iso(d), date: d, day: d.getDate(), jp: kanjiDay(d.getDate()), month: d.getMonth(),
        inMonth: d.getMonth() === m, today: off === 0, past: off < 0, picked: daysBetween(p0, d) === 0,
        weekend: i >= 5, dow: i, kanji: WEEK_KANJI[i],
        ko: k, sekki: s, term: s >= 0 ? lib.Se.SEKKI[s][0] : "",
        moon: moonOn(d, lib.Al).mark, sky: days[iso(d)] || null, offset: off
      })
    }
    out.push(row)
  }
  return out
}

// The twelve months of `view`'s year: { m, jp, wafu, season (at the 15th),
// current (today's), shown (the one turned to), terms ([{ jp, day }]) }.
function year(view, today, lib) {
  var y = view.getFullYear()
  var out = []
  for (var m = 0; m < 12; m++) {
    var mid = new Date(y, m, 15)
    var terms = []
    for (var d = 1; d <= daysIn(y, m); d++) {
      var k = koStarting(new Date(y, m, d), lib.Se)
      if (k >= 0 && k % 3 === 0) terms.push({ jp: lib.Se.SEKKI[k / 3][0], day: d })
    }
    out.push({ m: m, jp: MONTH_KANJI[m], name: MONTHS[m], wafu: WAFU[m][0], season: SEASONS[seasonOf(koAt(mid, lib.Se))].key,
               seasonJp: SEASONS[seasonOf(koAt(mid, lib.Se))].jp,
               current: today.getFullYear() === y && today.getMonth() === m, shown: view.getMonth() === m, terms: terms })
  }
  return out
}

// The leaf for the picked day: its date in words, where it stands in its
// microseason, solar term and season (each 0..1 through), the next term,
// the moon and the sky.
function leaf(d, today, wx, lib) {
  var Se = lib.Se
  // The kō in force by the day's end: one that starts on it counts from it.
  var k = koAt(addDays(d, 1), Se)
  var s = sekkiOf(k), sn = seasonOf(k)
  var ko = span(d, Se, koOf), sekki = span(d, Se, sekkiOf), season = span(d, Se, seasonOf)
  var through = function(sp) { return Math.max(0, Math.min(1, (daysBetween(sp.start, d) + 0.5) / Math.max(1, sp.days))) }
  var off = daysBetween(today, d)
  var next = (s + 1) % 24
  var days = (wx && wx.days) || {}
  var moon = moonOn(d, lib.Al)
  return {
    key: iso(d), date: d, offset: off, when: fromToday(off),
    title: WEEK[dow(d)] + ", " + d.getDate() + " " + MONTHS[d.getMonth()],
    weekday: WEEK[dow(d)], weekdayJp: WEEK_KANJI[dow(d)] + "曜日", day: d.getDate(), dayJp: kanjiDay(d.getDate()),
    ko: { no: k + 1, jp: Se.KO[k][0], english: Se.KO[k][1], through: through(ko), days: ko.days, left: daysBetween(d, ko.end) },
    sekki: { index: s, jp: Se.SEKKI[s][0], romaji: Se.SEKKI[s][1], english: Se.SEKKI[s][2], through: through(sekki),
             start: sekki.start, day: daysBetween(sekki.start, d) + 1, days: sekki.days, left: daysBetween(d, sekki.end) },
    season: { key: SEASONS[sn].key, jp: SEASONS[sn].jp, name: SEASONS[sn].name, through: through(season),
              day: daysBetween(season.start, d) + 1, days: season.days },
    next: { jp: Se.SEKKI[next][0], romaji: Se.SEKKI[next][1], english: Se.SEKKI[next][2], in: daysBetween(d, sekki.end) },
    moon: moon,
    sky: days[iso(d)] || null,
    now: off === 0 && wx ? wx.now : null
  }
}

// Everything a hand draws for the time sheet.
//   now      the clock
//   pick     days from today the picked day is (0: today); the month shown
//            is the picked day's
//   wx       forecast() or null; weather off: null
//   lib      { Se, Al }
// → { today, picked, view: { y, m, name, jp, wafu, romaji, english },
//     weeks, year, leaf, moved (pick ≠ 0), monthsAway }
function sheet(now, pick, wx, lib) {
  var today = midnight(now)
  var picked = addDays(today, Number(pick) || 0)
  var y = picked.getFullYear(), m = picked.getMonth()
  return {
    today: today, picked: picked,
    view: { y: y, m: m, name: MONTHS[m], jp: MONTH_KANJI[m], wafu: WAFU[m][0], romaji: WAFU[m][1], english: WAFU[m][2] },
    weeks: weeks(picked, now, picked, wx, lib),
    year: year(picked, now, lib),
    leaf: leaf(picked, today, wx, lib),
    moved: daysBetween(today, picked) !== 0,
    monthsAway: (y - today.getFullYear()) * 12 + m - today.getMonth()
  }
}

// What a key or the wheel does to the pick: a day, a week, a month, back
// to today. → the new pick (days from today).
function step(now, pick, how) {
  var today = midnight(now), picked = addDays(today, Number(pick) || 0)
  if (how === "today") return 0
  if (how === "day+") return pick + 1
  if (how === "day-") return pick - 1
  if (how === "week+") return pick + 7
  if (how === "week-") return pick - 7
  if (how === "month+" || how === "month-") return daysBetween(today, addMonths(picked, how === "month+" ? 1 : -1))
  if (how === "year+" || how === "year-") return daysBetween(today, addMonths(picked, how === "year+" ? 12 : -12))
  return pick
}

// The pick for a month of the shown year (the year rail): the same day,
// or today when it is the current month.
function toMonth(now, pick, m) {
  var today = midnight(now), picked = addDays(today, Number(pick) || 0)
  if (picked.getFullYear() === today.getFullYear() && m === today.getMonth()) return 0
  return daysBetween(today, addMonths(picked, m - picked.getMonth()))
}
