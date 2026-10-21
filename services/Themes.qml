pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Themes.js" as T

// Omarchy's themes for Settings › Colour 色: the list (read when the page
// opens), the one in use, and switching to another.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"

  property var themes: []
  property string theme: ""
  property Process _themes: Process {
    command: ["sh", "-c",
      "for d in \"$HOME\"/.config/omarchy/themes/*/ \"$1\"/themes/*/; do f=\"$d/colors.toml\"; [ -r \"$f\" ] || continue;"
      + "g() { awk -F'\"' -v k=\"$1\" '$0 ~ \"^\" k \" *=\" {print $2; exit}' \"$f\"; };"
      + "m=$(g mode); [ -e \"$d/light.mode\" ] && m=light;"
      + "printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$(basename \"$d\")\" \"$(g background)\" \"$(g foreground)\" \"$(g red)\" \"$m\"; done", "sh", root.omarchyPath]
    stdout: StdioCollector { onStreamFinished: root.themes = T.themes(text) }
  }
  property FileView _themeName: FileView {
    path: root.home + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.theme = String(text()).trim()
  }
  function setTheme(name) { Quickshell.execDetached(["omarchy-theme-set", String(name)]) }
  function loadThemes() { if (!_themes.running) _themes.running = true }
}
