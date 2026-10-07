pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What you wrote on your Profile 印影 plate: a name, a tagline, and which
// blocks of the plate are hidden. Kept in ~/.config/hanko/profile.json
// (beside style.json), watched, and written at once: the plate is not a
// draft like the style is.
//
//   { "name": "", "tagline": "", "hidden": ["palette", ...] }
QtObject {
  id: root

  readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hanko"
  readonly property string path: dir + "/profile.json"

  property var doc: ({ name: "", tagline: "", hidden: [] })

  function normalize(d) {
    d = d && typeof d === "object" ? d : {}
    return {
      name: String(d.name || "").slice(0, 60),
      tagline: String(d.tagline || "").slice(0, 120),
      hidden: Array.isArray(d.hidden) ? d.hidden.map(String) : []
    }
  }

  // field: name | tagline
  function setText(field, value) {
    if (field !== "name" && field !== "tagline") return
    var next = normalize(doc)
    next[field] = String(value || "").trim()
    _commit(next)
  }
  function toggle(block) {
    var next = normalize(doc)
    var at = next.hidden.indexOf(block)
    if (at >= 0) next.hidden.splice(at, 1)
    else next.hidden.push(block)
    _commit(next)
  }
  function reset() { _commit(normalize({})) }

  function _commit(next) {
    doc = next
    _mkdir.running = true
  }

  property Process _mkdir: Process {
    command: ["mkdir", "-p", root.dir]
    onExited: root._file.setText(JSON.stringify(root.doc, null, 2) + "\n")
  }

  property FileView _file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    atomicWrites: true
    onFileChanged: reload()
    onLoaded: {
      var parsed = {}
      try { parsed = JSON.parse(text() || "{}") } catch (e) { console.warn("hanko: profile.json is not valid JSON") }
      var next = root.normalize(parsed)
      if (JSON.stringify(next) !== JSON.stringify(root.doc)) root.doc = next
    }
  }
}
