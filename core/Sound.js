.pragma library

// The Sound sheet 音 (docs/COMPONENTS.md, "Panels"): the master, the
// outputs, the per-app mixer and the input, as plain rows. services/Sound.qml
// copies each Pipewire node into a plain object first (see `node` below);
// only ids and names leave this file, never the nodes themselves, since
// Pipewire deletes nodes under a Repeater that still holds them.
//
// A plain node: { id, name, description, nickname, props, volume, muted }
// where props holds the node's properties once it is bound, else {}.

// A known app whose stream name is lower case.
var APP_NAMES = { "spotify": "Spotify", "firefox": "Firefox", "chromium": "Chromium", "mpv": "mpv" }
// Omarchy's speaker tuning sink feeds the speakers: processing, not an app.
var TUNING_PREFIX = "omarchy_speaker_tuning"

function percent(v) { return Math.round(Math.max(0, Number(v) || 0) * 100) }

// "Built-in Audio Analog Stereo Output" -> "Analog Stereo".
function friendly(text) {
  var s = String(text || "").trim()
  s = s.replace(/^sof-soundwire\s+/i, "")
  s = s.replace(/^built-?in audio\s+/i, "")
  s = s.replace(/\s+(Output|Input)$/i, "")
  s = s.replace(/\bMicrophones\b/g, "Microphone")
  return s
}

function label(n) {
  if (!n) return "Unknown"
  var p = n.props || {}
  return friendly(n.nickname || p["node.nick"] || p["device.profile.description"] || "")
    || friendly(n.description || p["node.description"] || n.name || "") || "Unknown"
}

// How a device is attached: "Bluetooth", "USB", "HDMI", "Built-in" or "".
function bus(n) {
  var p = n.props || {}
  var name = String(n.name || "").toLowerCase()
  var b = String(p["device.bus"] || "").toLowerCase()
  if (b === "bluetooth" || name.indexOf("bluez") === 0) return "Bluetooth"
  if (name.indexOf("hdmi") >= 0 || name.indexOf("displayport") >= 0) return "HDMI"
  if (b === "usb" || name.indexOf("usb") >= 0) return "USB"
  if (b === "pci" || name.indexOf("pci") >= 0) return "Built-in"
  return ""
}

// "USB · Focusrite 2i2 · 48 kHz", from whatever the node tells us.
function detail(n) {
  var p = n.props || {}
  var parts = []
  var b = bus(n)
  if (b) parts.push(b)
  var product = friendly(p["device.product.name"] || "")
  if (product && product !== label(n)) parts.push(product)
  if (p["api.bluez5.codec"]) parts.push(String(p["api.bluez5.codec"]).toUpperCase())
  var rate = Number(p["audio.rate"] || 0)
  if (rate > 0) parts.push(Math.round(rate / 100) / 10 + " kHz")
  return parts.join(" · ")
}

// Output rows, the live one first. `available` (name -> bool) hides sinks
// Omarchy reports unplugged, or fronted by a tuning.
function outputs(sinks, liveName, available) {
  var rows = []
  for (var i = 0; i < (sinks || []).length; i++) {
    var n = sinks[i]
    if (!n || n.id === undefined) continue
    if (available && available[n.name] === false) continue
    var live = String(n.name) === String(liveName || "")
    var b = bus(n)
    rows.push({ id: n.id, name: String(n.name || ""), label: label(n), detail: detail(n),
                current: live, note: live ? "Live" : b === "Bluetooth" ? "Paired" : "" })
  }
  rows.sort(function(a, b) { return (b.current ? 1 : 0) - (a.current ? 1 : 0) })
  return rows
}

function streamLabel(n) {
  var p = n.props || {}
  var raw = String(p["application.name"] || n.description || p["media.name"] || p["node.name"] || n.name || "").trim()
  return APP_NAMES[raw.toLowerCase()] || raw || "Unknown"
}

// Mixer rows: one per playing app, tunings left out.
function streams(list) {
  var rows = []
  for (var i = 0; i < (list || []).length; i++) {
    var n = list[i]
    if (!n || n.id === undefined || String(n.name || "").indexOf(TUNING_PREFIX) === 0) continue
    rows.push({ id: n.id, name: String(n.name || ""), label: streamLabel(n),
                level: Math.max(0, Math.min(1, Number(n.volume) || 0)), percent: percent(n.volume), muted: !!n.muted })
  }
  return rows
}

function master(volume, muted) {
  return { percent: percent(volume), level: Math.max(0, Math.min(1, Number(volume) || 0)), muted: !!muted }
}

// "Input · Shure MV7", "Input · muted", "No input".
function inputNote(source) {
  if (!source) return "No input"
  return "Input · " + (source.muted ? "muted" : label(source))
}

// The whole sheet's data from plain nodes.
function sheet(volumeSink, liveSink, sinks, streamList, source, available) {
  return {
    master: volumeSink ? master(volumeSink.volume, volumeSink.muted) : null,
    outputs: outputs(sinks, liveSink ? liveSink.name : "", available),
    streams: streams(streamList),
    input: inputNote(source),
    inputMuted: !!(source && source.muted)
  }
}
