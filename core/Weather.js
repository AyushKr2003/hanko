.pragma library

// Weather 天: the leaf that hangs left of 01 // TIME on the handscroll (the
// paper there is otherwise bare while Time sits in the middle).
//
// The data follows Omarchy's own weather panel (shell/plugins/panels/
// weather), so Hanko shows the same place and the same units:
//  - the place comes from ~/.local/state/omarchy/settings/weather.json
//    ({name, latitude, longitude}, owned by omarchy-weather-location);
//    without coordinates the place is found from the IP address the way
//    Omarchy does, through wttr.in's nearest_area;
//  - the forecast comes from Open-Meteo (fast, keyless, °C and km/h);
//  - units follow the `unit` setting on the omarchy.weather entry in
//    shell.json, else the country, else the locale.

function trim(s) { return String(s === undefined || s === null ? "" : s).replace(/^\s+|\s+$/g, "") }

// weather.json → { name, latitude, longitude } (null coordinates = auto).
function location(raw) {
  var unset = { name: "", latitude: null, longitude: null }
  try {
    var d = JSON.parse(String(raw || ""))
    if (!d || typeof d !== "object") return unset
    var lat = parseFloat(d.latitude), lon = parseFloat(d.longitude)
    var ok = !isNaN(lat) && !isNaN(lon)
    return { name: typeof d.name === "string" ? trim(d.name) : "", latitude: ok ? lat : null, longitude: ok ? lon : null }
  } catch (e) {
    return unset
  }
}

// wttr.in j1 → { name, country, latitude, longitude } of the detected area.
function area(raw) {
  try {
    var a = JSON.parse(String(raw || "")).nearest_area[0]
    var v = function(x) { return x && x[0] ? trim(x[0].value) : "" }
    var lat = parseFloat(a.latitude), lon = parseFloat(a.longitude)
    if (isNaN(lat) || isNaN(lon)) return null
    return { name: v(a.areaName), country: v(a.country), latitude: lat, longitude: lon }
  } catch (e) {
    return null
  }
}

// One request: now, the next two days by the hour, and four days.
function url(latitude, longitude) {
  return "https://api.open-meteo.com/v1/forecast"
    + "?latitude=" + encodeURIComponent(String(latitude))
    + "&longitude=" + encodeURIComponent(String(longitude))
    + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day"
    + "&hourly=temperature_2m,precipitation_probability"
    + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
    + "&forecast_days=4&timezone=auto"
}

// Omarchy's rule (Model.js shouldUseImperial): an explicit unit wins, then
// the country, then the locale.
function imperial(unit, localeName, country) {
  var u = trim(unit).toLowerCase()
  if (u === "imperial") return true
  if (u === "metric") return false
  var c = trim(country).replace(/[._-]+/g, " ").toLowerCase()
  if (c) return ["us", "usa", "united states", "united states of america", "liberia", "myanmar", "burma"].indexOf(c) >= 0
  var l = String(localeName || "").replace(".", "_")
  return /^en[_-]US($|[_.-])/.test(l) || /^en[_-]LR($|[_.-])/.test(l) || /^my($|[_.-])/.test(l)
}

// WMO weather code → a word and its kanji: 晴 clear (月 at night),
// 曇 cloud, 霧 fog, 雨 rain, 雪 snow, 雷 thunder.
function condition(code, isDay) {
  var c = parseInt(String(code), 10)
  var night = isDay === 0 || isDay === false
  if (c === 0) return { word: "clear", jp: night ? "月" : "晴" }
  if (c === 1) return { word: "mostly clear", jp: night ? "月" : "晴" }
  if (c === 2) return { word: "partly cloudy", jp: "曇" }
  if (c === 3) return { word: "overcast", jp: "曇" }
  if (c === 45 || c === 48) return { word: "fog", jp: "霧" }
  if (c >= 51 && c <= 57) return { word: "drizzle", jp: "雨" }
  if (c >= 61 && c <= 67) return { word: "rain", jp: "雨" }
  if (c >= 80 && c <= 82) return { word: "showers", jp: "雨" }
  if ((c >= 71 && c <= 77) || c === 85 || c === 86) return { word: "snow", jp: "雪" }
  if (c >= 95) return { word: "storm", jp: "雷" }
  return { word: "", jp: "天" }
}

// Degrees → the eight-point compass.
function compass(deg) {
  var d = Number(deg)
  if (!isFinite(d)) return ""
  return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(((d % 360) + 360) % 360 / 45) % 8]
}

function temp(c, imp) {
  var n = Number(c)
  if (c === null || c === undefined || c === "" || !isFinite(n)) return null
  return Math.round(imp ? n * 9 / 5 + 32 : n)
}

// "2026-10-06T06:12" → minutes since midnight (the forecast is in local time).
function minutesOf(stamp) {
  var m = /T(\d\d):(\d\d)/.exec(String(stamp || ""))
  return m ? parseInt(m[1], 10) * 60 + parseInt(m[2], 10) : -1
}

function hhmm(minutes) {
  if (minutes < 0) return ""
  var h = Math.floor(minutes / 60), m = minutes % 60
  return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
}

// Open-Meteo's answer → everything the leaf draws, or null.
//   { place, temp, unit, feels, word, jp, wind, humidity, caption,
//     hours: [{ hour, t, p, past }] (today, 0..23), lo, hi, nowHour,
//     sunrise, sunset (minutes, -1 if unknown),
//     days: [{ name, jp, lo, hi }] (the next three), weekLo, weekHi }
function leaf(raw, place, imp, now) {
  var d
  try { d = typeof raw === "string" ? JSON.parse(raw) : raw } catch (e) { return null }
  if (!d || !d.current || d.current.temperature_2m === undefined || d.current.temperature_2m === null) return null
  var cur = d.current
  var at = now instanceof Date ? now : new Date()
  var cond = condition(cur.weather_code, cur.is_day)
  var t = temp(cur.temperature_2m, imp)
  var feels = temp(cur.apparent_temperature, imp)
  var speed = Number(cur.wind_speed_10m)
  var wind = isFinite(speed) ? Math.round(imp ? speed * 0.621371 : speed) + (imp ? " mph" : " km/h") : ""
  var dir = compass(cur.wind_direction_10m)
  var hum = isFinite(Number(cur.relative_humidity_2m)) ? Math.round(Number(cur.relative_humidity_2m)) : null

  // Today by the hour: the first 24 hourly slots are today, local time.
  var hours = []
  var h = d.hourly || {}
  var today = d.daily && d.daily.time ? String(d.daily.time[0]) : ""
  for (var i = 0; h.time && i < h.time.length && hours.length < 24; i++) {
    if (today && String(h.time[i]).slice(0, 10) !== today) continue
    var hour = parseInt(String(h.time[i]).slice(11, 13), 10)
    var p = h.precipitation_probability ? Number(h.precipitation_probability[i]) : 0
    hours.push({ hour: hour, t: temp(h.temperature_2m[i], imp), p: isFinite(p) ? Math.max(0, Math.min(100, p)) : 0,
                 past: hour < at.getHours() })
  }
  var lo = null, hi = null
  for (var j = 0; j < hours.length; j++) {
    if (hours[j].t === null) continue
    if (lo === null || hours[j].t < lo) lo = hours[j].t
    if (hi === null || hours[j].t > hi) hi = hours[j].t
  }

  // The next three days, and the span all four share (for the range bars).
  var days = []
  var dd = d.daily || {}
  var weekLo = lo, weekHi = hi
  var names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  for (var k = 0; dd.time && k < dd.time.length; k++) {
    var dlo = temp(dd.temperature_2m_min[k], imp), dhi = temp(dd.temperature_2m_max[k], imp)
    if (dlo !== null && (weekLo === null || dlo < weekLo)) weekLo = dlo
    if (dhi !== null && (weekHi === null || dhi > weekHi)) weekHi = dhi
    if (k === 0) continue
    if (days.length >= 3) continue
    var date = new Date(String(dd.time[k]) + "T12:00:00")
    days.push({ name: isNaN(date.getTime()) ? "" : names[date.getDay()],
                jp: condition(dd.weather_code ? dd.weather_code[k] : null, 1).jp, lo: dlo, hi: dhi })
  }

  var unit = imp ? "°F" : "°C"
  var parts = []
  if (trim(place)) parts.push(trim(place))
  if (feels !== null) parts.push("feels " + feels + "°")
  if (wind) parts.push((dir ? dir + " " : "") + wind)
  return {
    place: trim(place), temp: t, unit: unit, feels: feels, word: cond.word, jp: cond.jp,
    wind: wind, dir: dir, humidity: hum, caption: parts.join(" · "),
    hours: hours, lo: lo, hi: hi, nowHour: at.getHours() + at.getMinutes() / 60,
    sunrise: dd.sunrise ? minutesOf(dd.sunrise[0]) : -1, sunset: dd.sunset ? minutesOf(dd.sunset[0]) : -1,
    sunLine: [dd.sunrise && dd.sunset ? "Sun " + hhmm(minutesOf(dd.sunrise[0])) + " → " + hhmm(minutesOf(dd.sunset[0])) : "",
              hum !== null ? hum + "% humid" : ""].filter(function(x) { return x }).join(" · "),
    days: days, weekLo: weekLo, weekHi: weekHi
  }
}

// The curve's points: x 0..1 across the day, y 0..1 from the day's low to
// its high (with a little air), one per hour.
function curve(hours, lo, hi) {
  var out = []
  if (!hours || !hours.length || lo === null || hi === null) return out
  var span = Math.max(4, hi - lo)
  var floor = lo - span * 0.15, top = hi + span * 0.15
  for (var i = 0; i < hours.length; i++) {
    if (hours[i].t === null) continue
    out.push({ x: hours[i].hour / 23, y: (hours[i].t - floor) / (top - floor), past: hours[i].past })
  }
  return out
}

// Where a day's low..high sits on the week's span, as 0..1 fractions.
function range(lo, hi, weekLo, weekHi) {
  if (lo === null || hi === null || weekLo === null || weekHi === null) return { from: 0, to: 0 }
  var span = Math.max(1, weekHi - weekLo)
  return { from: (lo - weekLo) / span, to: (hi - weekLo) / span }
}

// How wide the leaf can be: the paper left of Time while Time is in the
// middle of a view `viewW` wide, less the interlude before Time and a
// margin inside the roller's curl (the leaf's own padding covers the rest,
// so its edge curls under the roller like any section's). 0 when there is
// too little room to be worth it.
var WIDTH = 400
var MIN = 240
function leafWidth(viewW, timeW, interlude, scale) {
  var s = scale || 1
  var room = viewW / 2 - timeW / 2 - interlude - 40 * s
  var w = Math.min(WIDTH * s, room)
  return w >= MIN * s ? Math.round(w) : 0
}
