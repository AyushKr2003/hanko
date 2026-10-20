pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Cursor.js" as Cursor

// Te 手, the keyboard cursor (core/Cursor.js), for a sheet and for the bar.
// It fills its parent and draws there: four red corner marks around the
// part it is on, a printer's register (red is you, now), as Kōsei brackets
// the part you have open. A part that does something says so with
// `keyStop` and `keyPress()`; a level adds `keyStep`, `keyAdjust(d)` and
// `keyAxis` ("x" by default, "y" for a slip or a rod); `keyChosen` marks
// the one in use, `keyMenu()` its menu (a tray icon's). The cursor walks
// the stops under `scope` where they lie. As in Omarchy it shows on the
// first key, not for the pointer, and Left/Right on a level set it rather
// than leave it.
Item {
  id: root

  // Where the stops are looked for.
  property Item scope: null
  // While false the cursor hides and forgets where it was.
  property bool active: true
  // Corner marks drawn inside the part (the bar: a cell fills its height,
  // so marks outside it would be cut off by the window).
  property bool inside: false

  property bool shown: false
  property Item item: null
  // Where the cursor was (its centre), to land again when the parts are
  // made anew under it (a new reading rebuilds the rows).
  property point at: Qt.point(-1, -1)
  property rect rect: Qt.rect(0, 0, 0, 0)

  anchors.fill: parent
  z: 100

  // A part's own key property (the parts are plain Items to the linter).
  function says(part, key) { return !!part && !!part[key] }
  function axisOf(part) { return part && part["keyAxis"] === "y" ? "y" : "x" }
  function call(part, fn, arg) {
    var f = part ? part[fn] : null
    if (typeof f !== "function") return false
    f.call(part, arg)
    return true
  }

  function stopItems() {
    var out = []
    function walk(it) {
      if (!it || !it.visible || it.opacity <= 0) return
      if (it.keyStop === true && it.width > 0 && it.height > 0) out.push(it)
      var kids = it.children
      for (var i = 0; i < kids.length; i++) walk(kids[i])
    }
    walk(root.scope)
    return out
  }
  function stopsOf(items) {
    return items.map(function(it) {
      var p = it.mapToItem(root, 0, 0)
      return { x: p.x, y: p.y, w: it.width, h: it.height, step: root.says(it, "keyStep"), chosen: root.says(it, "keyChosen") }
    })
  }
  function set(it) {
    root.item = it || null
    root.shown = !!it
    root.place()
  }
  function place() {
    var it = root.item
    if (!it) return
    var p = it.mapToItem(root, 0, 0)
    root.rect = Qt.rect(p.x, p.y, it.width, it.height)
    root.at = Qt.point(p.x + it.width / 2, p.y + it.height / 2)
  }
  function reset() {
    root.shown = false
    root.item = null
    root.at = Qt.point(-1, -1)
  }
  // Show the cursor without moving it: where it was, or where it starts.
  function reveal() {
    var items = root.stopItems()
    if (!items.length) return false
    var stops = root.stopsOf(items)
    root.set(items[root.at.x >= 0 ? Cursor.nearest(stops, root.at) : Cursor.start(stops)])
    return true
  }
  // Land on the stop `pick(item)` says yes to, if there is one.
  function find(pick) {
    var items = root.stopItems()
    for (var i = 0; i < items.length; i++) if (pick(items[i])) { root.set(items[i]); return true }
    return false
  }
  function move(dx, dy) {
    var items = root.stopItems()
    if (!items.length) return
    var from = root.shown ? items.indexOf(root.item) : -1
    if (from < 0) { root.reveal(); return }
    var it = root.item
    if (root.says(it, "keyStep")) {
      var axis = root.axisOf(it)
      if (axis === "x" && dx !== 0 && root.call(it, "keyAdjust", dx)) return
      // A slip is pulled down to hang longer.
      if (axis === "y" && dy !== 0 && root.call(it, "keyAdjust", dy)) return
    }
    root.set(items[Cursor.move(root.stopsOf(items), from, dx, dy)])
  }
  function activate() {
    if (!root.shown || !root.item) { root.reveal(); return }
    root.call(root.item, "keyPress")
  }
  function menu() {
    if (!root.shown || !root.item) { root.reveal(); return }
    root.call(root.item, "keyMenu")
  }
  // + and -: the level under the cursor, else the first one there is.
  function step(d) {
    var it = root.shown ? root.item : null
    if (!root.says(it, "keyStep")) {
      if (!root.find(function(s) { return root.says(s, "keyStep") })) return
      it = root.item
    }
    root.call(it, "keyAdjust", d)
  }

  onActiveChanged: if (!active) reset()
  onItemChanged: {
    // Its part was made anew: land on what stands there now.
    if (!root.item && root.shown) Qt.callLater(function() {
      if (root.item || !root.shown) return
      var items = root.stopItems()
      var i = Cursor.nearest(root.stopsOf(items), root.at)
      if (i >= 0) root.set(items[i])
      else root.reset()
    })
  }
  // Parts move as a sheet lays out (a row comes, a slip swings longer):
  // follow the one under the cursor while it shows.
  Timer {
    interval: 100
    repeat: true
    running: root.shown && root.active
    onTriggered: root.place()
  }

  Item {
    id: bracket
    readonly property int out: root.inside ? -Type.px(2) : Type.px(3)
    readonly property int arm: Type.px(7)
    visible: root.shown && root.active && root.rect.width > 0
    x: root.rect.x - out
    y: root.rect.y - out
    width: root.rect.width + 2 * out
    height: root.rect.height + 2 * out
    Behavior on x { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Repeater {
      model: 4
      Item {
        id: corner
        required property int index
        readonly property bool east: index % 2 === 1
        readonly property bool low: index >= 2
        x: east ? bracket.width - bracket.arm : 0
        y: low ? bracket.height - bracket.arm : 0
        width: bracket.arm
        height: bracket.arm
        Rectangle { x: corner.east ? parent.width - width : 0; width: 2; height: parent.height; color: Ink.seal }
        Rectangle { y: corner.low ? parent.height - height : 0; width: parent.width; height: 2; color: Ink.seal }
      }
    }
  }
}
