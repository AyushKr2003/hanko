pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Oto.js" as OtoJs
import "Paths.js" as Paths

// Oto 音: plays Kaze's six sounds (core/Oto.js decides which and how loud;
// assets/sounds holds them) with PipeWire's pw-play. Silent unless
// ~/.config/hanko/kaze.json says `"sound": "quiet"` or `"on"`.
QtObject {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  // Read when a sound is asked for (both files are tiny), so a change to
  // kaze.json or to Sumi applies to the very next sound.
  property FileView _kaze: FileView {
    path: root.configHome + "/hanko/kaze.json"
    blockLoading: true
    printErrors: false
  }
  property FileView _sumi: FileView {
    path: root.stateHome + "/hanko/sumi/sumi.glsl"
    blockLoading: true
    printErrors: false
  }

  function play(event) {
    _kaze.reload(); _sumi.reload()
    var doc = {}
    try { doc = JSON.parse(_kaze.text() || "{}") } catch (e) { doc = {} }
    var p = OtoJs.play(event, doc, _sumi.text().length > 0)
    if (!p) return
    var file = Paths.local(Qt.resolvedUrl("../assets/sounds/" + p.file + ".ogg"))
    Quickshell.execDetached(["pw-play", "--volume", String(p.volume), file])
  }
}
