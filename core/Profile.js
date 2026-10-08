.pragma library

// The settings window's three plates (Profile 印影, About 由来, Credits 謝辞):
// the sums and lists they print. Pure JavaScript, so tests/unit.mjs runs it.
// services/Machine.qml reads the machine; core/Dossier.qml keeps what you
// wrote on your profile (~/.config/hanko/profile.json).

// One probe, one line per fact, key=value. Run by services/Machine.qml.
var PROBE = [
  'echo "user=${USER:-$(id -un)}"',
  'echo "host=$(cat /etc/hostname 2>/dev/null || uname -n)"',
  'echo "kernel=$(uname -r)"',
  'echo "uptime=$(cut -d" " -f1 /proc/uptime 2>/dev/null)"',
  'echo "theme=$(omarchy-theme-current 2>/dev/null)"',
  'echo "omarchy=$(omarchy-version 2>/dev/null)"',
  'echo "hyprland=$(hyprctl version -j 2>/dev/null | sed -n \'s/.*"tag": *"\\([^"]*\\)".*/\\1/p\' | head -1)"',
  'echo "packages=$(pacman -Qq 2>/dev/null | wc -l)"',
  'b=$(stat -c %W / 2>/dev/null); [ "${b:-0}" -gt 0 ] && echo "since=$(date -d @$b +%Y-%m-%d)"',
  'echo "machine=$(cat /etc/machine-id 2>/dev/null)"'
].join("; ")

var BLOCKS = ["watermark", "seal", "vitals", "specs", "palette", "day", "spine"]

// The probe's output -> { user, host, kernel, uptime (s), theme, omarchy,
// hyprland, packages, since, machine }; anything missing is "".
function parseMachine(text) {
  var out = { user: "", host: "", kernel: "", uptime: 0, theme: "", omarchy: "", hyprland: "", packages: 0, since: "", machine: "" }
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var eq = lines[i].indexOf("=")
    if (eq < 1) continue
    var k = lines[i].slice(0, eq).trim(), v = lines[i].slice(eq + 1).trim()
    if (!(k in out)) continue
    if (k === "uptime" || k === "packages") out[k] = Math.max(0, Number(v) || 0)
    else out[k] = v
  }
  // "Unknown" is what omarchy-theme-current says when it can't tell.
  if (out.theme === "Unknown") out.theme = ""
  return out
}

// A value, or a quiet dash.
function fv(x) {
  var s = x === undefined || x === null ? "" : String(x).trim()
  return s === "" || s === "0" ? "—" : s
}

// 3 d 4 h, 5 h 12 m, 12 m.
function uptime(seconds) {
  var s = Math.floor(Number(seconds) || 0)
  if (s <= 0) return "—"
  var d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
  if (d > 0) return d + " d " + h + " h"
  if (h > 0) return h + " h " + m + " m"
  return Math.max(1, m) + " m"
}

// A four-digit edition number for this machine (FNV-1a over the seed), so
// the same install always prints the same No.
function edition(seed) {
  var s = String(seed || "hanko")
  var h = 2166136261
  for (var i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619) >>> 0
  return ("000" + (h % 10000)).slice(-4)
}

// Which of the combinations this bar is: the resolved style read as a
// mixed-radix number over the settings, 1-based ("No. 1,234,567 of N").
function combination(style, OPTIONS, KEYS) {
  var n = 0
  for (var i = 0; i < KEYS.length; i++) {
    var opts = OPTIONS[KEYS[i]]
    var at = 0
    for (var j = 0; j < opts.length; j++) if (String(opts[j]) === String(style[KEYS[i]])) at = j
    n = n * opts.length + at
  }
  return n + 1
}

function grouped(n) {
  return String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

// The live readings pinned beside the seal: { key, name, jp, big, sub }.
// Only what the machine has; the bar's own shapes (core/Status.js).
// Each reading carries `level` (0..1 for a gauge, -1 for none).
function vitals(d) {
  d = d || {}
  var out = []
  var spaces = d.spaces || []
  if (spaces.length) {
    var windows = 0, live = ""
    for (var i = 0; i < spaces.length; i++) {
      windows += spaces[i].count || 0
      if (spaces[i].active) live = ("0" + spaces[i].id).slice(-2)
    }
    out.push({ key: "spaces", name: "SPACES", jp: "頁", big: ("0" + spaces.length).slice(-2),
               sub: windows + (windows === 1 ? " window" : " windows") + (live ? " · on " + live : ""), level: -1 })
  }
  if (d.volume) out.push({ key: "sound", name: "SOUND", jp: "音", big: d.volume.muted ? "Muted" : d.volume.percent + "%",
                           sub: d.volume.muted ? d.volume.percent + "% when on" : "output level",
                           level: d.volume.muted ? 0 : Math.max(0, Math.min(1, d.volume.percent / 100)) })
  if (d.network) out.push({ key: "network", name: "NETWORK", jp: "網", big: fv(d.network.name),
                            sub: d.network.off ? "offline" : d.network.kind === "wifi" ? "Wi-Fi · " + (d.network.bars || 0) + " of 4 bars" : String(d.network.kind || "wired"),
                            level: d.network.off ? 0 : d.network.kind === "wifi" ? Math.max(0, Math.min(1, (d.network.bars || 0) / 4)) : -1 })
  if (d.battery) out.push({ key: "power", name: "POWER", jp: d.battery.charging ? "充" : "電", big: d.battery.percent + "%",
                            sub: d.battery.charging ? "charging" : "on battery",
                            level: Math.max(0, Math.min(1, d.battery.percent / 100)) })
  var n = (d.notifications || []).length
  out.push({ key: "inbox", name: "INBOX", jp: "報", big: ("0" + n).slice(-2),
             sub: d.dnd ? "do not disturb" : n ? (d.notifications[0].app || "a letter") + " last" : "nothing waiting", level: -1 })
  return out
}

// The dossier's small print: [label, value] rows.
function specs(style, doc, machine, version, OPTIONS, KEYS, total) {
  var m = machine || {}
  var edits = Object.keys((doc && doc.edits) || {}).length
  return [
    ["Preset", style.preset + (edits ? " + " + edits + (edits === 1 ? " edit" : " edits") : "")],
    ["Typeset", "No. " + grouped(combination(style, OPTIONS, KEYS)) + " of " + grouped(total)],
    ["Theme", fv(m.theme)],
    ["Compositor", m.hyprland ? "Hyprland " + String(m.hyprland).replace(/^v+/, "") : "Hyprland"],
    ["Kernel", fv(m.kernel)],
    ["Uptime", uptime(m.uptime)],
    ["Omarchy", fv(m.omarchy)],
    ["Hanko", fv(version)]
  ]
}

// Credits: what Hanko stands on. An empty url is a quiet, unlinked credit.
var PROJECTS = [
  { name: "Omarchy", group: "system", by: "basecamp", role: "the system this bar belongs to", url: "https://github.com/basecamp/omarchy" },
  { name: "Quickshell", group: "system", by: "outfoxxed", role: "the QML shell it runs in", url: "https://quickshell.org" },
  { name: "Hyprland", group: "system", by: "hyprwm", role: "the compositor under it", url: "https://github.com/hyprwm/Hyprland" },
  { name: "Ryoku", group: "lineage", by: "Ryoku-dev", role: "the settings grammar: ink tiers, hairlines, inversion", url: "https://github.com/Ryoku-dev/ryoku" },
  { name: "Omacale", group: "lineage", by: "AyushKr2003", role: "how a bar plugin hosts Omarchy's widgets", url: "https://github.com/AyushKr2003/omacale" },
  { name: "Shibumi-Shell", group: "lineage", by: "HANCORE-linux", role: "plugin integration", url: "https://github.com/HANCORE-linux/Shibumi-Shell" },
  { name: "ruixen-shell", group: "lineage", by: "gitcoder89431", role: "plugin integration", url: "https://github.com/gitcoder89431/ruixen-shell" },
  { name: "Fraunces", group: "type", by: "Undercase Type", role: "titles, time and bylines", url: "https://github.com/undercasetype/Fraunces" },
  { name: "Space Grotesk", group: "type", by: "Florian Karsten", role: "values and language", url: "https://github.com/floriankarsten/space-grotesk" },
  { name: "Noto CJK", group: "type", by: "Google · Adobe", role: "every kanji", url: "https://github.com/notofonts/noto-cjk" },
  { name: "Qt Quick", group: "system", by: "The Qt Company", role: "every pixel", url: "https://www.qt.io" },
  { name: "PipeWire · BlueZ · NetworkManager", group: "system", by: "", role: "sound, Bluetooth, network", url: "" }
]

// The groups credits are set under, in order: what Hanko runs on, whose
// work it learned from, and the type it is set in.
var CREDIT_GROUPS = [
  { key: "system",  jp: "礎",   label: "Foundation" },
  { key: "lineage", jp: "系譜", label: "Lineage" },
  { key: "type",    jp: "活字", label: "Type" }
]

function creditsIn(group) {
  return PROJECTS.filter(function(p) { return p.group === group })
}

// The people who test every build on real machines.
var PROOFREADERS = [
  { name: "AyushKr2003", url: "https://github.com/AyushKr2003" }
]

var REPOSITORY = "https://github.com/AyushKr2003/hanko"

// About: how Hanko is put together, as [label, value, url] lines.
function facts(version, total, settings, presets) {
  return [
    ["Kind", "an Omarchy bar plugin · hanko.bar", ""],
    ["Version", fv(version), ""],
    ["Settings", settings + " settings · " + presets + " presets · " + grouped(total) + " bars", ""],
    ["Style", "~/.config/hanko/style.json", ""],
    ["Profile", "~/.config/hanko/profile.json", ""],
    ["Terminal", "hanko style set <setting> <value>", ""],
    ["Shell", "omarchy-shell hanko settings | scroll", ""],
    ["Source", REPOSITORY.replace("https://", ""), REPOSITORY]
  ]
}

// The three directions Hanko was drawn in before it was built.
var LINEAGE = [
  { name: "Sheet", jp: "紙", line: "the printed bar: a spec table across the top of the page" },
  { name: "Scroll", jp: "巻", line: "the handscroll: calm type, every panel on one paper" },
  { name: "Typeset", jp: "組版", line: "the two together: every part of the bar a setting" }
]
