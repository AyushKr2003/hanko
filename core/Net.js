.pragma library

// The Network sheet 網 (docs/COMPONENTS.md, "Panels"): the connection you
// are on and the Wi-Fi around you, from NetworkManager's terse output
// (`nmcli -t`), which services/Net.qml gathers while the sheet is open.

// nmcli -t joins fields with ':' and escapes ':' and '\' inside them.
function splitTerse(line) {
  var out = []
  var cur = ""
  var s = String(line || "")
  for (var i = 0; i < s.length; i++) {
    var c = s.charAt(i)
    if (c === "\\" && i + 1 < s.length) { cur += s.charAt(++i); continue }
    if (c === ":") { out.push(cur); cur = ""; continue }
    cur += c
  }
  out.push(cur)
  return out
}

// `nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,SSID device wifi list`: one row
// per network (the strongest access point of each), hidden ones left out,
// the one in use first, then by signal.
function parseWifi(text) {
  var by = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].trim()) continue
    var f = splitTerse(lines[i])
    if (f.length < 5) continue
    var ssid = f.slice(4).join(":")
    if (!ssid) continue
    var signal = parseInt(f[1], 10) || 0
    var row = { ssid: ssid, signal: signal, inUse: f[0].trim() === "*",
                secure: f[2].trim() !== "" && f[2].trim() !== "--", security: f[2].trim(), freq: parseInt(f[3], 10) || 0 }
    var had = by[ssid]
    if (!had || row.inUse || (!had.inUse && row.signal > had.signal)) by[ssid] = row
  }
  var rows = []
  for (var k in by) rows.push(by[k])
  rows.sort(function(a, b) { return (b.inUse ? 1 : 0) - (a.inUse ? 1 : 0) || b.signal - a.signal || (a.ssid < b.ssid ? -1 : 1) })
  return rows
}

// `nmcli -t -f NAME,TYPE connection show`: the saved Wi-Fi connection names.
function parseSaved(text) {
  var out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = splitTerse(lines[i])
    if (f.length >= 2 && f[1].indexOf("wireless") >= 0 && f[0]) out.push(f[0])
  }
  return out
}

// "2.4 GHz", "5 GHz", "6 GHz" from MHz.
function band(mhz) {
  var v = Number(mhz) || 0
  if (!v) return ""
  if (v < 2500) return "2.4 GHz"
  if (v < 5925) return "5 GHz"
  if (v < 7125) return "6 GHz"
  return Math.round(v / 100) / 10 + " GHz"
}

// "WPA2" from "WPA1 WPA2", "WPA3" from "WPA2 WPA3 (SAE)"; "" when open.
function securityName(sec) {
  var s = String(sec || "")
  if (!s || s === "--") return ""
  if (s.indexOf("WPA3") >= 0 || s.indexOf("SAE") >= 0) return "WPA3"
  if (s.indexOf("WPA2") >= 0 || s.indexOf("802.1X") >= 0) return "WPA2"
  if (s.indexOf("WPA") >= 0) return "WPA"
  if (s.indexOf("WEP") >= 0) return "WEP"
  return s.split(" ")[0]
}

// How a click on a network row connects: "up" for a saved one, "open" for
// one without a password, "ask" for one that needs a password typed.
function connectHow(row) {
  if (row.saved) return "up"
  return row.secure ? "ask" : "open"
}

// The whole sheet. `status` is core/Status.js network() (the bar's own
// reading), `radio` whether Wi-Fi is switched on.
function sheet(status, wifi, saved, radio) {
  var s = status || { kind: "disconnected", name: "Offline" }
  var current = { kind: s.kind, label: s.kind === "wifi" ? s.name : s.kind === "ethernet" ? "Wired" : "Offline",
                  detail: "" }
  var networks = []
  var known = saved || []
  for (var i = 0; i < (wifi || []).length; i++) {
    var w = wifi[i]
    var sec = securityName(w.security)
    var isSaved = known.indexOf(w.ssid) >= 0
    var parts = []
    if (sec) parts.push(sec)
    if (band(w.freq)) parts.push(band(w.freq))
    parts.push(w.signal + "%")
    networks.push({ ssid: w.ssid, detail: parts.join(" · "), current: w.inUse, saved: isSaved,
                    secure: w.secure, signal: w.signal,
                    note: w.inUse ? "Connected" : isSaved ? "Saved" : w.secure ? "" : "Open" })
    if (w.inUse && s.kind === "wifi") current.detail = ["Wi-Fi"].concat(parts).join(" · ")
  }
  if (s.kind === "ethernet") current.detail = "Ethernet · cable"
  else if (s.kind === "wifi" && !current.detail) current.detail = "Wi-Fi · " + (s.signal || 0) + "%"
  else if (s.kind !== "wifi") current.detail = radio === false ? "Wi-Fi is off" : "Not connected"
  return { current: current, networks: networks, radio: radio !== false, offline: s.kind === "disconnected" }
}
