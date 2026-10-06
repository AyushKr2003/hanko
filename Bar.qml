pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "core"
import "bar"
import "services"

// Hanko · entry point of the `hanko.bar` plugin (manifest.json, kind "bar").
// omarchy-shell loads this file in place of its own bar and injects the
// properties below. The host reads back barHidden, barSize, position and
// fontFamily; see docs/ROADMAP.md for the whole contract.
Item {
  id: root

  // Injected by the host.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  property var barConfig: ({})
  property var shell: null
  property var manifest: null

  readonly property string version: manifest && manifest.version ? manifest.version : "0.1.0"

  // Mirrors `omarchy toggle bar` (the bar-off flag file).
  property bool barHidden: false

  // Hanko's own position when set (`hanko style set position bottom`);
  // otherwise Omarchy's bar.position, as long as it is an edge Hanko draws.
  readonly property string position: {
    if (Typeset.ownsPosition) return Typeset.current.position
    var p = barConfig ? String(barConfig.position || "") : ""
    return p === "bottom" ? "bottom" : "top"
  }
  readonly property bool vertical: false
  readonly property int barSize: barHidden ? 0 : Type.px(Typeset.current.height)
  readonly property string fontFamily: Type.mono

  property alias now: clock.date

  // 12- or 24-hour, from Omarchy's own clock (the `format` on omarchy.clock
  // in shell.json). Only the hour style carries over: Hanko lays out the
  // date itself.
  readonly property string timeFormat: {
    var f = omarchyClockFormat
    return /h/.test(f.replace(/HH?/g, "")) || /ap/i.test(f) ? "h:mm AP" : "HH:mm"
  }
  readonly property string omarchyClockFormat: {
    var layout = barConfig && barConfig.layout ? barConfig.layout : {}
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var list = Array.isArray(layout[sections[s]]) ? layout[sections[s]] : []
      for (var i = 0; i < list.length; i++)
        if (list[i] && list[i].id === "omarchy.clock" && list[i].format) return String(list[i].format)
    }
    return "HH:mm"
  }

  // Omarchy's choice of media player, when the host offers it.
  Binding {
    target: Media
    property: "proxy"
    value: root.shell && typeof root.shell.firstPartyServiceFor === "function" ? root.shell.firstPartyServiceFor("omarchy.media") : null
  }

  Binding {
    target: Status
    property: "notificationsProxy"
    value: root.shell && typeof root.shell.firstPartyServiceFor === "function" ? root.shell.firstPartyServiceFor("omarchy.notifications") : null
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      BarWindow {
        required property var modelData
        screen: modelData
        bar: root
      }
    }
  }

  // ------------------------------------------------------------- hiding
  //
  // `omarchy toggle bar` writes ~/.local/state/omarchy/toggles/bar-off, then
  // calls `omarchy.bar syncHidden`. The directory is watched because a
  // FileView cannot watch a file that does not exist yet.
  readonly property string togglesDir: Quickshell.env("HOME") + "/.local/state/omarchy/toggles"

  Process {
    id: hiddenProbe
    running: true
    command: ["bash", "-c", "[[ -f \"$1/bar-off\" ]] && echo yes || echo no", "_", root.togglesDir]
    stdout: SplitParser {
      onRead: function(line) { root.barHidden = String(line).trim() === "yes" }
    }
  }

  FileView {
    path: root.togglesDir
    watchChanges: true
    printErrors: false
    onFileChanged: hiddenProbe.running = true
  }

  IpcHandler {
    target: "omarchy.bar"
    function syncHidden(): void { hiddenProbe.running = true }
  }

  // ------------------------------------------------------------- hanko IPC
  //
  // omarchy-shell hanko <fn> ...  (scripts/hanko wraps these)
  IpcHandler {
    target: "hanko"

    function version(): string { return root.version }
    function styleGet(): string { return JSON.stringify(Typeset.current) }
    function styleDoc(): string { return Typeset.serialized() }
    function styleSet(key: string, value: string): string { return Typeset.set(key, value) ? "ok" : "invalid" }
    function stylePreset(name: string): string { return Typeset.applyPreset(name) ? "ok" : "unknown" }
    function styleReset(): string { Typeset.reset(); return "ok" }
    function styleShuffle(): string { Typeset.shuffle(); return "ok" }
    function warnings(): string { return Typeset.warnings.join("\n") }
  }
}
