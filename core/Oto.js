.pragma library

// Oto 音, six sounds (docs/kaze, mockup 13). Which sound an event makes, and
// how loud, from ~/.config/hanko/kaze.json's `sound` (off by default).
// core/Oto.qml plays them with pw-play; assets/sounds holds them.

var EVENTS = {
  sheath: "noto",        // a panel or the menu closes
  workspace: "hyoshigi", // the workspace changes
  letter: "kami",        // a notification arrives
  urgent: "suzu",        // a window needs you, a reminder
  screenshot: "sumi",    // a screenshot
  end: "kane"            // shutting down, the 終 ceremony
}
// Loudness by setting: a share of the output's own volume, at most 30%.
var VOLUME = { off: 0, quiet: 0.15, on: 0.3 }

function mode(doc) {
  var v = doc && doc.sound
  return v === "on" || v === "quiet" ? v : "off"
}

// What to play for `event`: { file, volume }, or null for silence. In Sumi
// only the bell sounds; a sound can be switched off on its own with
// `"sounds": { "workspace": false }`.
function play(event, doc, sumi) {
  var m = mode(doc)
  var file = EVENTS[event]
  if (!file || m === "off") return null
  if (doc && doc.sounds && doc.sounds[event] === false) return null
  if (sumi && event !== "end") return null
  return { file: file, volume: VOLUME[m] }
}
