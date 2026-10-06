.pragma library

// Bluetooth 藍: the BT cell on the bar, its sheet and its scroll section.
// services/Blue.qml copies Quickshell's BlueZ devices into plain rows first
// (a live device object in a Repeater can be destroyed mid-build by BlueZ,
// as Omarchy's own panel warns) and acts through Omarchy's scripts:
// omarchy-bluetooth-power and omarchy-bluetooth-device.
//
// A plain device: { address, name, icon, connected, paired, battery (0..1
// or -1), pairing }.

// Names that are really an address or a UUID mean nothing to a person.
function human(name) {
  var s = String(name || "").trim()
  if (!s) return false
  if (/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(s)) return false
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-/i.test(s) || /^[0-9a-f]{32}$/i.test(s)) return false
  return true
}

// What a device is, from its BlueZ icon name.
function kind(icon) {
  var i = String(icon || "")
  if (/headset|headphone/.test(i)) return "Headphones"
  if (/audio|speaker/.test(i)) return "Speaker"
  if (/keyboard/.test(i)) return "Keyboard"
  if (/mouse|pointing/.test(i)) return "Mouse"
  if (/phone/.test(i)) return "Phone"
  if (/gaming|joystick/.test(i)) return "Controller"
  if (/computer/.test(i)) return "Computer"
  return ""
}

function percent(b) { return b >= 0 ? Math.round(b * 100) : -1 }

// One sheet row: { address, name, detail, note, connected, paired }.
function row(d) {
  var parts = []
  if (kind(d.icon)) parts.push(kind(d.icon))
  if (percent(d.battery) >= 0) parts.push(percent(d.battery) + "%")
  return { address: String(d.address || ""), name: String(d.name).trim(), detail: parts.join(" · "),
           connected: !!d.connected, paired: !!d.paired,
           note: d.pairing ? "Pairing" : d.connected ? "Connected" : d.paired ? "Paired" : "" }
}

// Connected, then known (paired), then found nearby; nameless ones left out.
function lists(devices) {
  var out = { connected: [], known: [], found: [] }
  var all = (devices || []).filter(function(d) { return d && human(d.name) })
  all.sort(function(a, b) { return String(a.name).localeCompare(String(b.name)) })
  for (var i = 0; i < all.length; i++) {
    var r = row(all[i])
    if (r.connected) out.connected.push(r)
    else if (r.paired) out.known.push(r)
    else out.found.push(r)
  }
  return out
}

// The bar's BT 藍 cell, in core/Status.js's shape: the connected device's
// name (and its battery as the meter), "On" or "Off". null with no adapter.
function cell(present, enabled, devices) {
  if (!present) return null
  var l = lists(devices)
  var first = l.connected.length ? l.connected[0] : null
  var dev = null
  for (var i = 0; first && i < devices.length; i++) if (devices[i].address === first.address) dev = devices[i]
  var level = dev && dev.battery >= 0 ? dev.battery : -1
  var name = !enabled ? "Off" : first ? first.name : "On"
  if (enabled && first && l.connected.length > 1) name += " +" + (l.connected.length - 1)
  return { name: name, enabled: !!enabled, connected: l.connected.length, level: level, needsYou: false }
}

// How a click on a row acts: connect a known device, pair a new one,
// disconnect a connected one.
function action(r) {
  return r.connected ? "disconnect" : r.paired ? "connect" : "pair"
}

// The sheet: { title, blurb, enabled, scanning, connected, known, found }.
function sheet(present, enabled, scanning, devices) {
  var l = lists(devices)
  var title = !present ? "No adapter" : !enabled ? "Off" : l.connected.length ? l.connected[0].name : "On"
  var blurb = !present ? "This machine has no Bluetooth adapter."
    : !enabled ? "Turn it on to see your devices."
    : l.connected.length > 1 ? l.connected.length + " devices connected."
    : l.connected.length === 1 ? (l.connected[0].detail || "Connected.")
    : scanning ? "Looking for devices nearby…" : "Nothing connected."
  return { title: title, blurb: blurb, present: !!present, enabled: !!enabled, scanning: !!scanning,
           connected: l.connected, known: l.known, found: l.found }
}
