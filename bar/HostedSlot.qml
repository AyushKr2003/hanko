import QtQuick
import "../core"

// One hosted widget in Hanko's right zone: created from the host's widget
// registry with `bar`, `moduleName` and `settings` as initial properties
// (so a widget that starts work on completion sees its real settings), and
// sized to what it asks for. The widget keeps its own behaviour; it just
// wears Hanko's ink through the facade.
Item {
  id: root

  // { id, key, settings } from core/Hosted.js, and its registry component.
  property var entry: ({ id: "", key: "", settings: {} })
  property var component: null
  property string pluginId: entry.id
  property var host: null
  property int barHeight: 40
  property string position: "top"

  property Item item: null

  // Te 手 (bar focus): Enter opens the widget's own panel, when it has one.
  function opener(it) {
    var f = it ? (it["toggle"] || it["open"]) : null
    return typeof f === "function" ? f : null
  }
  readonly property bool keyStop: !!opener(item)
  function keyPress() {
    var f = opener(root.item)
    if (f) f.call(root.item)
  }

  // Never hidden by its own child's visibility (that latches hidden): a
  // widget with nothing to show collapses the slot to nothing instead.
  implicitWidth: item && item.visible ? Math.ceil(item.implicitWidth || item.width) : 0
  implicitHeight: barHeight
  // Short of room the bar drops a widget whole rather than cut it: the
  // slot collapses (visibility untouched, see above).
  property bool fits: true
  width: fits ? implicitWidth : 0
  clip: !fits

  HostBar {
    id: facade
    host: root.host
    moduleName: root.entry.id
    pluginId: root.pluginId
    barHeight: root.barHeight
    position: root.position
  }

  function create() {
    if (item) { var old = item; item = null; old.destroy() }
    if (!component || component.status !== Component.Ready) return
    var made = null
    try {
      made = component.createObject(root, { bar: facade, moduleName: entry.id, settings: entry.settings || {} })
    } catch (e) {
      console.warn("hanko: bar widget " + entry.id + " failed to start: " + e)
    }
    if (!made) return
    made.anchors.verticalCenter = root.verticalCenter
    if (!(made.implicitHeight > 0)) made.height = Qt.binding(function() { return root.height })
    item = made
    if (host && typeof host.registerHosted === "function") host.registerHosted(root.entry.key, made)
  }

  // The registry re-registers the same Component on every rescan; only a
  // different one rebuilds the widget.
  property var createdFrom: null
  onComponentChanged: if (createdFrom !== null && component !== createdFrom) { createdFrom = component; create() }
  onEntryChanged: if (item && "settings" in item) item.settings = entry.settings || {}
  Component.onCompleted: { createdFrom = component; create() }
  Component.onDestruction: if (host && typeof host.unregisterHosted === "function") host.unregisterHosted(root.entry.key, item)
}
