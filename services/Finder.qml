pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Mission.js" as M

// What the mission overview's search reads and runs (after
// omarchy-overview's SearchService): the open windows (Hypr), the apps
// (DesktopEntries), Omarchy's menu (its JSONC, defaults then the user's
// extension, read only) and sums (core/Mission.js). `find` answers on every
// key; `run` does what a result says.
Singleton {
  id: root

  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
  property var menu: []

  function apps() {
    var list = DesktopEntries.applications.values, out = []
    for (var i = 0; i < list.length; i++) {
      var e = list[i]
      out.push({ id: e.id, name: e.name, genericName: e.genericName, comment: e.comment, keywords: e.keywords || [],
                 icon: e.icon, noDisplay: e.noDisplay })
    }
    return out
  }

  function find(query) {
    return M.find(query, { spaces: Hypr.workspaces.filter(function(w) { return w.id > 0 }), apps: apps(), menu: menu })
  }

  // Windows are the overview's own (it closes, then focuses).
  function run(result) {
    if (!result) return
    if (result.kind === "app") {
      var list = DesktopEntries.applications.values
      for (var i = 0; i < list.length; i++) if (list[i].id === result.id) { list[i].execute(); return }
    } else if (result.kind === "calc") {
      Quickshell.execDetached(["wl-copy", "--", String(result.value)])
    } else if (result.kind === "menu" && result.action) {
      Quickshell.execDetached(["sh", "-c", String(result.action)])
    }
  }

  function rebuild() { menu = M.menuEntries(defaults.text(), mine.text()) }

  property FileView defaults: FileView {
    path: root.omarchyPath + "/default/omarchy/omarchy-menu.jsonc"
    watchChanges: true
    printErrors: false
    onLoaded: root.rebuild()
    onFileChanged: reload()
  }
  property FileView mine: FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/extensions/omarchy-menu.jsonc"
    watchChanges: true
    printErrors: false
    onLoaded: root.rebuild()
    onLoadFailed: root.rebuild()
    onFileChanged: reload()
  }
}
