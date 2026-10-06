.pragma library

// The Power sheet 電 (docs/COMPONENTS.md, "Panels"): the battery, the power
// profile and the screen's brightness, from the scripts Omarchy's own power
// panel uses (omarchy-battery-status --shell, omarchy-powerprofiles-list).

// The plain names Omarchy's profiles carry, in the order they are listed.
var PROFILE_NAMES = { "power-saver": "Power saver", "balanced": "Balanced", "performance": "Performance" }
var PROFILE_DETAIL = {
  "power-saver": "Longer battery, slower and cooler",
  "balanced": "Fast when it matters, quiet otherwise",
  "performance": "Everything at full speed"
}

// "key\tvalue" lines -> { key: value }.
function keyValues(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var at = lines[i].indexOf("\t")
    if (at > 0) out[lines[i].slice(0, at)] = lines[i].slice(at + 1).trim()
  }
  return out
}

// `omarchy-powerprofiles-list --active-state`: "name\t1" for the active one.
function profiles(text) {
  var out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].trim().split("\t")
    if (!f[0]) continue
    out.push({ name: f[0], label: PROFILE_NAMES[f[0]] || f[0], detail: PROFILE_DETAIL[f[0]] || "", active: f[1] === "1" })
  }
  return out
}

// What the battery is doing, in words.
function stateLabel(state) {
  var s = String(state || "")
  if (s === "charging") return "Charging"
  if (s === "discharging") return "On battery"
  if (s === "fully-charged") return "Full"
  if (s === "holding" || s === "pending-charge") return "Holding charge"
  return s ? s.charAt(0).toUpperCase() + s.slice(1) : ""
}

// The blurb under the title: "2h 41m left · drawing 9.8W", "Plugged in".
function blurb(kv) {
  if (!kv || !kv.percentage) return "No battery: plugged in for good."
  var s = kv.state
  var parts = []
  if (kv.time) parts.push(kv.time + (s === "charging" ? " to full" : " left"))
  if (kv.rate && kv.rate !== "0W") parts.push((s === "charging" ? "taking " : "drawing ") + kv.rate)
  if (!parts.length) parts.push(stateLabel(s) || "Plugged in")
  return parts.join(" · ")
}

// Battery detail rows: [{ name, value }], only what the machine reports.
function details(kv) {
  var rows = []
  if (!kv || !kv.percentage) return rows
  rows.push({ name: "State", value: stateLabel(kv.state) })
  if (kv.size && kv.size !== "0Wh") rows.push({ name: "Capacity", value: kv.size })
  if (kv.cycles) rows.push({ name: "Cycles", value: kv.cycles })
  if (kv.threshold) rows.push({ name: "Charge limit", value: kv.threshold })
  return rows
}

function sheet(kv, profileList, battery, brightness) {
  return {
    percent: battery ? battery.percent : -1,
    low: !!(battery && battery.needsYou),
    charging: !!(battery && battery.charging),
    blurb: blurb(kv),
    details: details(kv),
    profiles: profileList || [],
    brightness: brightness
  }
}
