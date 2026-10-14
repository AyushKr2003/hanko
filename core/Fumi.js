.pragma library

// Fumi 文, letters on a branch (docs/kaze, mockup 07): a notification hangs
// from the bar as a tanzaku, a narrow paper strip carrying the sender's
// crest, two kanji for the kind of letter and the time, set vertically.
// Hover it and it opens sideways into the letter. plugins/hanko.notifications
// keeps Omarchy's notification server and draws what this file decides.

// The sender's crest: a ring and one kanji, by app name (lower case, any
// part of it). Unknown senders get 文.
var CRESTS = [
  [["signal", "telegram", "discord", "slack", "whatsapp", "element", "teams", "zulip", "messages", "chat"], "話"],
  [["thunderbird", "mail", "geary", "evolution", "gmail", "proton"], "郵"],
  [["calendar", "gnome-calendar", "khal", "reminder", "remind"], "暦"],
  [["spotify", "mpv", "music", "player", "rhythmbox", "vlc", "mpd", "tidal"], "曲"],
  [["screenshot", "hyprshot", "grim", "satty", "screenrecord", "capture"], "写"],
  [["zen", "firefox", "chromium", "chrome", "brave", "qutebrowser", "browser", "web"], "網"],
  [["omarchy", "networkmanager", "network", "upower", "battery", "power", "system", "update", "pacman", "yay", "bluetooth", "notify-send", "hyprland", "hypridle"], "器"],
  [["code", "nvim", "terminal", "alacritty", "kitty", "ghostty", "foot", "claude"], "筆"]
]

function crestFor(app, summary) {
  if (summary !== undefined && /^screenshot\b/i.test(String(summary))) return "写"
  var a = String(app || "").toLowerCase()
  if (!a) return "器"
  for (var i = 0; i < CRESTS.length; i++)
    for (var j = 0; j < CRESTS[i][0].length; j++)
      if (a.indexOf(CRESTS[i][0][j]) >= 0) return CRESTS[i][1]
  return "文"
}

// The kind of letter, two kanji down the strip:
//   警告 a warning (critical)   予定 an event   完了 something finished
//   便り a message (the rest)
function kindFor(app, summary, body, urgency) {
  if (Number(urgency) >= 2) return "警告"
  var crest = crestFor(app)
  if (crest === "暦") return "予定"
  var text = (String(summary || "") + " " + String(body || "")).toLowerCase()
  if (/\b(done|complete|completed|finished|saved|copied|installed|updated|uploaded|downloaded|ready)\b/.test(text)) return "完了"
  return "便り"
}

// "21:44" for a millisecond timestamp, in local time.
function timeOf(ms) {
  var d = new Date(Number(ms) || Date.now())
  var h = d.getHours(), m = d.getMinutes()
  return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
}

// Red means "you": only a letter that is critical gets the red crest.
function urgent(urgency) {
  return Number(urgency) >= 2
}

// How many strips hang at once; the rest are counted on one more strip.
var MOST = 5
function shown(count) {
  var n = Math.max(0, count | 0)
  return { strips: Math.min(n, MOST), more: Math.max(0, n - MOST) }
}

// A notification body as plain words for the letter: markup and links
// dropped, entities read, runs of space folded.
function plain(body) {
  return String(body || "")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]*>/g, "")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&amp;/g, "&")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim()
}

// The share of the screen's width a strip hangs at, for the wind's gust:
// `right` px from the right edge of a screen `width` px wide.
function gustShare(right, width) {
  var w = Number(width) || 1
  return Math.max(0, Math.min(1, 1 - Number(right) / w))
}

// A screenshot's letter (Omarchy's capture script says "Screenshot saved to
// clipboard and file"): it gets the 写 crest and the brush's sound instead
// of paper. The screenshot sound has no other cue: Omarchy has no hook for it.
function isScreenshot(app, summary) {
  return /^screenshot\b/i.test(String(summary || "")) || crestFor(app) === "写"
}
