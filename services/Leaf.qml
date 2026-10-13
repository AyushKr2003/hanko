pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Leaf.js" as L

// The end leaf right of 08 // INBOX on the handscroll (core/Leaf.js; the
// `endleaf` setting). Reads only what the chosen leaf shows, and only while
// the scroll is out, except two things that keep time on their own: the
// machine's last hour (a CPU sample a minute while `kiki` is chosen) and
// the focus timer (which has to end on time with the scroll rolled up).
Singleton {
  id: root

  // Set by Bar.qml: the scroll is out, and which leaf it shows.
  property bool wanted: false
  property string kind: "koyomi"

  readonly property string home: Quickshell.env("HOME")
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
  readonly property bool showing: wanted && kind !== ""

  // ------------------------------------------------------------ colophon
  property string colophonRaw: ""
  property Process _colophon: Process {
    command: ["sh", "-c",
      "printf 'host\\t%s\\n' \"$(cat /etc/hostname 2>/dev/null || uname -n)\";"
      + "v=$(cat /sys/devices/virtual/dmi/id/product_version 2>/dev/null); n=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null);"
      + "case \"$v\" in *[A-Za-z]*[A-Za-z]*) printf 'model\\t%s\\n' \"$v\";; *) printf 'model\\t%s\\n' \"$n\";; esac;"
      + "printf 'kernel\\t%s\\n' \"$(uname -r)\";"
      + "command -v pacman >/dev/null && printf 'packages\\t%s\\n' \"$(pacman -Qq 2>/dev/null | wc -l)\";"
      + "u=$(grep ' upgraded ' /var/log/pacman.log 2>/dev/null | tail -1 | sed -E 's/^\\[([^]]+)\\].*/\\1/'); [ -n \"$u\" ] && printf 'upgraded\\t%s\\n' \"$(date -d \"$u\" '+%a %d %b' 2>/dev/null)\";"
      + "command -v omarchy-version >/dev/null && printf 'omarchy\\t%s\\n' \"$(omarchy-version 2>/dev/null)\";"
      + "command -v hyprctl >/dev/null && printf 'hyprland\\t%s\\n' \"$(hyprctl version 2>/dev/null | awk 'NR==1{print $2}')\";"
      + "printf 'uptime\\t%s\\n' \"$(cut -d' ' -f1 /proc/uptime)\";"
      + "printf 'user\\t%s\\n' \"$USER\";"
      + "printf 'name\\t%s\\n' \"$(getent passwd \"$USER\" 2>/dev/null | cut -d: -f5 | cut -d, -f1)\";"
      + "printf 'theme\\t%s\\n' \"$(cat \"$HOME/.local/state/omarchy/current/theme.name\" 2>/dev/null)\""]
    stdout: StdioCollector { onStreamFinished: root.colophonRaw = text }
  }

  // ------------------------------------------------------------ machine
  // { cpu (0..1), cores, load, mem, disk, temp, history, top }
  property var machine: ({ cpu: null, history: [] })
  property var _lastTimes: null
  property var _minuteTimes: null
  property var _history: []
  property Process _stat: Process {
    command: ["sh", "-c", "head -1 /proc/stat; echo '#'; cat /proc/meminfo; echo '#'; cat /proc/loadavg; echo '#'; nproc"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.split("\n#\n")
        var t = L.cpuTimes(parts[0])
        var busy = L.cpuBusy(root._lastTimes, t)
        root._lastTimes = t
        var m = Object.assign({}, root.machine)
        if (busy !== null) m.cpu = busy
        m.mem = L.memory(parts[1] || "")
        m.load = parseFloat(String(parts[2] || "").split(" ")[0])
        m.cores = parseInt(parts[3], 10) || 0
        m.history = root._history
        root.machine = m
      }
    }
  }
  // A minute's average for the curve, kept while kiki is chosen.
  property Process _minute: Process {
    command: ["head", "-1", "/proc/stat"]
    stdout: StdioCollector {
      onStreamFinished: {
        var t = L.cpuTimes(text)
        var busy = L.cpuBusy(root._minuteTimes, t)
        root._minuteTimes = t
        if (busy === null) return
        root._history = root._history.concat([busy]).slice(-60)
        var m = Object.assign({}, root.machine)
        m.history = root._history
        root.machine = m
      }
    }
  }
  property Process _slow: Process {
    command: ["sh", "-c",
      "df -B1 --output=size,used / 2>/dev/null; echo '#';"
      + "for h in /sys/class/hwmon/hwmon*; do [ -r \"$h/temp1_input\" ] && echo \"$(cat \"$h/name\" 2>/dev/null) $(cat \"$h/temp1_input\")\"; done;"
      + "for z in /sys/class/thermal/thermal_zone*; do [ -r \"$z/temp\" ] && echo \"$(cat \"$z/type\" 2>/dev/null) $(cat \"$z/temp\")\"; done; echo '#';"
      + "top -b -n2 -d0.4 -w 256 -o %CPU 2>/dev/null | awk '/^top -/{f++} f==2 && $1 ~ /^[0-9]+$/ {printf \"%s\\t%s\\n\", $12, $9; if (++n == 3) exit}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.split("#\n")
        var m = Object.assign({}, root.machine)
        m.disk = L.disk(parts[0] || "")
        m.temp = L.temperature(parts[1] || "")
        m.top = L.top(parts[2] || "")
        root.machine = m
      }
    }
  }
  property Timer _statTick: Timer {
    interval: 2000
    repeat: true
    triggeredOnStart: true
    running: root.showing && root.kind === "kiki"
    onTriggered: if (!root._stat.running) root._stat.running = true
  }
  property Timer _slowTick: Timer {
    interval: 6000
    repeat: true
    triggeredOnStart: true
    running: root.showing && root.kind === "kiki"
    onTriggered: if (!root._slow.running) root._slow.running = true
  }
  property Timer _minuteTick: Timer {
    interval: 60000
    repeat: true
    triggeredOnStart: true
    running: root.kind === "kiki"
    onTriggered: if (!root._minute.running) root._minute.running = true
  }

  // ------------------------------------------------------------ session
  property real uptime: 0
  property Process _uptime: Process {
    command: ["cut", "-d", " ", "-f1", "/proc/uptime"]
    stdout: StdioCollector { onStreamFinished: root.uptime = parseFloat(text) || 0 }
  }
  function sessionAct(key) {
    var a = L.sessionAction(key)
    if (a) Quickshell.execDetached(a.command)
  }

  // ------------------------------------------------------------ themes
  property var themes: []
  property string theme: ""
  property Process _themes: Process {
    command: ["sh", "-c",
      "for d in \"$HOME\"/.config/omarchy/themes/*/ \"$1\"/themes/*/; do f=\"$d/colors.toml\"; [ -r \"$f\" ] || continue;"
      + "g() { awk -F'\"' -v k=\"$1\" '$0 ~ \"^\" k \" *=\" {print $2; exit}' \"$f\"; };"
      + "m=$(g mode); [ -e \"$d/light.mode\" ] && m=light;"
      + "printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$(basename \"$d\")\" \"$(g background)\" \"$(g foreground)\" \"$(g red)\" \"$m\"; done", "sh", root.omarchyPath]
    stdout: StdioCollector { onStreamFinished: root.themes = L.themes(text) }
  }
  property FileView _themeName: FileView {
    path: root.home + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.theme = String(text()).trim()
  }
  function setTheme(name) { Quickshell.execDetached(["omarchy-theme-set", String(name)]) }
  // Settings › Colour reads the themes too, whatever the end leaf is.
  function loadThemes() { if (!_themes.running) _themes.running = true }
  function openThemes() {
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", "omarchy.image-picker", "{\"source\":\"themes\"}"])
  }

  // ------------------------------------------------------------ tools
  property bool recording: false
  property Timer _recTick: Timer {
    interval: 2000
    repeat: true
    triggeredOnStart: true
    running: root.showing && root.kind === "dougu"
    onTriggered: if (!root._rec.running) root._rec.running = true
  }
  property Process _rec: Process {
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(code) { root.recording = code === 0 }
  }
  function runTool(key) {
    var t = L.tool(key)
    if (t && t.command) Quickshell.execDetached(["sh", "-c", t.command])
  }

  // ------------------------------------------------------------ focus
  property var focusTimer: L.focusState("")
  property real clockNow: Date.now()
  readonly property string focusPath: root.home + "/.local/state/hanko/focus.json"
  property FileView _focusFile: FileView {
    path: root.focusPath
    printErrors: false
    onLoaded: root.focusTimer = L.focusState(text())
  }
  property Process _focusWrite: Process {}
  function _saveFocus() {
    var json = JSON.stringify(root.focusTimer)
    _focusWrite.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", root.focusPath, json]
    _focusWrite.running = true
  }
  function focusAct(what) {
    var r = L.focusStep(root.focusTimer, what, Date.now())
    root.focusTimer = r.state
    root.clockNow = Date.now()
    if (what !== "tick" || r.said) _saveFocus()
    if (r.said) Quickshell.execDetached(["notify-send", "-a", "Hanko", "-i", "alarm-symbolic", "集 " + r.said])
  }
  property Timer _focusTick: Timer {
    interval: 1000
    repeat: true
    running: root.focusTimer.kind !== "idle" && root.focusTimer.pausedLeft === null
    onTriggered: root.focusAct("tick")
  }
  // Keeps the idle and paused clock fresh while it shows.
  property Timer _focusShow: Timer {
    interval: 1000
    repeat: true
    running: root.showing && root.kind === "shuchu"
    onTriggered: root.clockNow = Date.now()
  }

  // ------------------------------------------------------------ notes
  readonly property string notesPath: root.home + L.NOTES_PATH
  property string notesText: ""
  property bool notesExist: false
  property FileView _notes: FileView {
    path: root.notesPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.notesText = text(); root.notesExist = true }
    onLoadFailed: { root.notesText = ""; root.notesExist = false }
  }
  function toggleNote(line) {
    var next = L.toggled(root.notesText, line)
    if (next === root.notesText) return
    root.notesText = next
    _notes.setText(next)
  }
  property Process _notesNew: Process {}
  function editNotes() {
    _notesNew.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\"; [ -e \"$1\" ] || printf '# Today\\n\\n- [ ] \\n' > \"$1\"; exec omarchy-launch-editor \"$1\"", "sh", root.notesPath]
    _notesNew.running = true
  }
  property string clipRaw: ""
  property FileView _clip: FileView {
    path: root.home + "/.local/state/omarchy/clipboard-history.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.clipRaw = text()
  }
  function copyClip(index) {
    Quickshell.execDetached(["omarchy-clipboard-paste-text", "--copy-only", "--history-index", String(index)])
  }

  // ------------------------------------------------------------ fetch
  function refresh() {
    if (!root.showing) return
    if (root.kind === "okugaki" && !_colophon.running) _colophon.running = true
    if (root.kind === "shimai" && !_uptime.running) _uptime.running = true
    if (root.kind === "iro" && !_themes.running) _themes.running = true
  }
  onShowingChanged: refresh()
  onKindChanged: refresh()

  // What bar/scroll/EndLeaf.qml reads (the harness passes the same shape).
  readonly property var reading: ({
    colophon: root.colophonRaw,
    machine: root.machine,
    uptime: root.uptime,
    themes: root.themes,
    theme: root.theme,
    recording: root.recording,
    focus: root.focusTimer,
    clockNow: root.clockNow,
    notes: root.notesText,
    notesExist: root.notesExist,
    notesPath: root.notesPath,
    clipboard: root.kind === "hikae" ? root.clipRaw : ""
  })
}
