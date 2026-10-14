.pragma library

// Taikan 体幹, posture (docs/kaze, mockup 06): Omarchy's on-screen display as
// one hairline at the foot of the screen that fills from the centre outward,
// as Sekiro's posture bar does. plugins/hanko.osd keeps Omarchy's calls
// (omarchy-osd, `osd show {json}`) and draws what this file decides.
//
//   level     a reading with a value: volume, brightness, the keyboard light
//   switch    a word and a crest: the microphone, the touchpad, anything else
//   end       shutting down, rebooting, logging out (the ceremonies take
//             these over in KZ10; until then they show as a switch)

// Omarchy's icon names → { label, kanji } for levels.
var LEVELS = {
  "volume": { label: "VOL", kanji: "音" },
  "volume-low": { label: "VOL", kanji: "音" },
  "volume-medium": { label: "VOL", kanji: "音" },
  "volume-high": { label: "VOL", kanji: "音" },
  "volume-muted": { label: "VOL", kanji: "音" },
  "volume-mute": { label: "VOL", kanji: "音" },
  "muted": { label: "VOL", kanji: "音" },
  "mute": { label: "VOL", kanji: "音" },
  "brightness": { label: "LIGHT", kanji: "光" },
  "display": { label: "LIGHT", kanji: "光" },
  "keyboard": { label: "KEYS", kanji: "灯" }
}
var MUTED = ["volume-muted", "volume-mute", "muted", "mute"]

// Switches → { crest, label, red }. Red means "you": you turned it off.
var SWITCHES = {
  "microphone-muted": { crest: "黙", label: "MICROPHONE", red: true },
  "microphone-off": { crest: "黙", label: "MICROPHONE", red: true },
  "mic-muted": { crest: "黙", label: "MICROPHONE", red: true },
  "mic-off": { crest: "黙", label: "MICROPHONE", red: true },
  "microphone": { crest: "声", label: "MICROPHONE", red: false },
  "mic": { crest: "声", label: "MICROPHONE", red: false },
  "touchpad": { crest: "触", label: "TOUCHPAD", red: false },
  "touch": { crest: "触", label: "TOUCHSCREEN", red: false },
  "touchscreen": { crest: "触", label: "TOUCHSCREEN", red: false },
  "media": { crest: "曲", label: "MEDIA", red: false },
  "player": { crest: "曲", label: "MEDIA", red: false },
  "media-source": { crest: "曲", label: "MEDIA", red: false },
  "player-source": { crest: "曲", label: "MEDIA", red: false },
  "media-play": { crest: "曲", label: "PLAYING", red: false },
  "player-play": { crest: "曲", label: "PLAYING", red: false },
  "media-pause": { crest: "曲", label: "PAUSED", red: false },
  "player-pause": { crest: "曲", label: "PAUSED", red: false },
  "media-next": { crest: "曲", label: "NEXT", red: false },
  "player-next": { crest: "曲", label: "NEXT", red: false },
  "media-previous": { crest: "曲", label: "BACK", red: false },
  "player-previous": { crest: "曲", label: "BACK", red: false }
}
var ENDS = {
  "shutdown": { crest: "終", label: "SHUT DOWN" }, "power": { crest: "終", label: "SHUT DOWN" }, "poweroff": { crest: "終", label: "SHUT DOWN" },
  "reboot": { crest: "終", label: "RESTART" }, "restart": { crest: "終", label: "RESTART" },
  "logout": { crest: "退", label: "LOG OUT" }, "sign-out": { crest: "退", label: "LOG OUT" }, "leave": { crest: "退", label: "LOG OUT" }
}

// What to draw for one of Omarchy's OSD states (OsdModel.stateForShow):
//   { iconKey, maxValue, hasProgress, value, message, duration }
// → { kind, label, kanji, crest, red, fill (0..1), full, muted, figure, word, duration }
function view(st) {
  st = st || {}
  var key = String(st.iconKey || "").toLowerCase()
  var max = Math.max(1, Number(st.maxValue) || 100)
  var value = Math.max(0, Math.min(max, Number(st.value) || 0))
  var duration = Number(st.duration)
  if (!(duration >= 0)) duration = 1200
  if (st.hasProgress) {
    var lv = LEVELS[key] || { label: "LEVEL", kanji: "量" }
    var muted = MUTED.indexOf(key) >= 0
    var fill = muted ? 0 : value / max
    return { kind: "level", label: lv.label, kanji: lv.kanji, crest: "", red: muted, fill: fill, full: !muted && value >= max,
             muted: muted, figure: Math.round(value * 100 / max), word: muted ? "無音 Muted" : "", duration: duration }
  }
  if (ENDS[key]) {
    var e = ENDS[key]
    return { kind: "end", label: e.label, kanji: "", crest: e.crest, red: false, fill: 0, full: false, muted: false,
             figure: -1, word: String(st.message || ""), duration: duration }
  }
  var sw = SWITCHES[key] || { crest: crestFor(key), label: "", red: false }
  return { kind: "switch", label: sw.label, kanji: "", crest: sw.crest, red: !!sw.red, fill: 0, full: false, muted: false,
           figure: -1, word: word(String(st.message || ""), sw.label), duration: duration }
}

// A crest for anything else: an Omarchy caller may pass its own glyph as the
// icon (a nerd-font icon, or a kanji); a plain name gets 文.
function crestFor(key) {
  if (!key) return "文"
  if (/^[㐀-鿿]$/.test(key)) return key
  return "文"
}

// The word under a switch's label: "Microphone muted" → "Muted" when the
// label already says what it is.
function word(message, label) {
  var m = String(message || "").trim()
  if (!m) return ""
  if (label) {
    var lead = label.toLowerCase().split(" ")[0]
    var low = m.toLowerCase()
    if (low.indexOf(lead + " ") === 0) {
      var rest = m.slice(lead.length + 1)
      return rest.charAt(0).toUpperCase() + rest.slice(1)
    }
  }
  return m
}

// The two halves of the line at `fill` (0..1): each from the centre, as a
// share of the line's width. Muted collapses to the centre mark.
function halves(fill) {
  var f = Math.max(0, Math.min(1, Number(fill) || 0))
  return { left: 0.5 - f / 2, width: f }
}
