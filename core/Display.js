.pragma library

// The Display panel 明 (the LUM cell's sheet and the scroll's Display
// section): how bright the chosen monitor is, every monitor Hyprland knows,
// and night light. services/Display.qml reads `hyprctl monitors all -j` and
// `omarchy-brightness-display --monitor NAME` (backlight on a laptop panel,
// DDC on an external one), the way Omarchy's own Display panel does.

// Laptop panels: their brightness is the backlight.
var INTERNAL = /^(eDP|LVDS|DSI)-/

function scaleText(s) {
  var n = Math.round(Number(s) * 100) / 100
  return isFinite(n) && n > 0 ? "×" + n : ""
}

// `hyprctl monitors all -j` -> [{ name, label, detail, focused, enabled,
// internal }], the focused one first, then by name.
function monitors(json) {
  var list
  try { list = typeof json === "string" ? JSON.parse(json) : json } catch (e) { return [] }
  if (!Array.isArray(list)) return []
  var out = list.map(function(m) {
    var name = String(m.name || "")
    var internal = INTERNAL.test(name)
    var model = String(m.model || m.description || "").trim()
    var parts = []
    if (m.width && m.height) parts.push(m.width + "×" + m.height)
    if (m.refreshRate) parts.push(Math.round(Number(m.refreshRate)) + " Hz")
    if (scaleText(m.scale)) parts.push(scaleText(m.scale))
    return { name: name, label: internal ? "Built-in · " + name : (model ? model + " · " + name : name),
             detail: m.disabled ? "Switched off in Hyprland" : parts.join(" · "), focused: m.focused === true,
             enabled: m.disabled !== true, internal: internal }
  })
  out.sort(function(a, b) { return (b.focused ? 1 : 0) - (a.focused ? 1 : 0) || (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) })
  return out
}

// `omarchy-brightness-display` prints a percentage ("70", "70%"); -1 when
// the monitor has no brightness Hanko can reach.
function brightness(text) {
  var m = /(\d+(?:\.\d+)?)/.exec(String(text || ""))
  if (!m) return -1
  return Math.max(0, Math.min(100, Math.round(Number(m[1]))))
}

// The monitor the brightness ruler speaks for: the one picked, if it is
// still there and on, else the focused one, else the first that is on.
function target(list, picked) {
  var on = (list || []).filter(function(m) { return m.enabled })
  for (var i = 0; i < on.length; i++) if (on[i].name === picked) return on[i].name
  for (var j = 0; j < on.length; j++) if (on[j].focused) return on[j].name
  return on.length ? on[0].name : ""
}

// The whole panel's data.
function sheet(list, picked, percent, night) {
  var t = target(list, picked)
  var m = null
  for (var i = 0; i < (list || []).length; i++) if (list[i].name === t) m = list[i]
  return {
    title: m ? (m.internal ? "Built-in" : m.name) : "No display",
    blurb: m ? m.detail : "Hyprland reports no monitor",
    target: t,
    monitors: (list || []).map(function(x) { return Object.assign({}, x, { current: x.name === t }) }),
    brightness: percent >= 0 ? { percent: percent, level: percent / 100 } : null,
    night: !!night
  }
}
