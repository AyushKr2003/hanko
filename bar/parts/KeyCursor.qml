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
// the one in use, `keyMenu()` its menu (a tray icon's). An item with
// `keyStops: false` fences off everything inside it; `keyPane: n` makes
// a column of a window (Up and Down stay in it while they can). The cursor walks
// the stops under `scope` where they lie. As in Omarchy it shows on the
// first key or under the pointer, and Left/Right on a level set it rather
// than leave it. One cursor for keys and mouse, as Omarchy's panels keep
// theirs: the pointer moves it too, but only when it really moves (its
// PointerMoveGate), so a resting pointer never takes it back from a key.
// Moved by a key, a part in a scrolled page is scrolled into view.
Item {
  id: root

  // Where the stops are looked for.
  property Item scope: null
  // While false the cursor hides and forgets where it was.
  property bool active: true
  // Corner marks kept within this item's height (the bar: a cell may fill
  // it, and marks past it would be cut off by the window).
  property bool inside: false
  // Left/Right may leave the line for the nearest part that way (a window
  // of columns, core/Cursor.js move()).
  property bool loose: false
  // The pointer moves the cursor.
  property bool follow: true
  // Where it shows first: only parts this says yes to, when any does
  // (function(part) → bool; null: all).
  property var prefer: null

  property bool shown: false
  property Item item: null
  // Where the cursor was (its centre), to land again when the parts are
  // made anew under it (a new reading rebuilds the rows).
  property point at: Qt.point(-1, -1)
  property rect rect: Qt.rect(0, 0, 0, 0)
  // The part is scrolled out of its page: the marks hide.
  property bool outOfView: false

  anchors.fill: parent
  z: 100

  // A part's own key property (the parts are plain Items to the linter).
  function says(part, key) { return !!part && !!part[key] }
  // The pane a part is in: the nearest ancestor with `keyPane` set (its
  // number), else 0.
  function paneOf(part) {
    for (var p = part; p && p !== root.scope; p = p.parent) if (p["keyPane"]) return p["keyPane"]
    return 0
  }
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
      // A fence: a picture of a bar or a sheet inside a page (settings'
      // previews) is not walked into.
      if (it !== root.scope && it.keyStops === false) return
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
      return { x: p.x, y: p.y, w: it.width, h: it.height, step: root.says(it, "keyStep"), chosen: root.says(it, "keyChosen"),
               pane: root.paneOf(it) }
    })
  }
  // The page a part scrolls in: its nearest Flickable, or null.
  function pageOf(it) {
    for (var p = it ? it.parent : null; p && p !== root.scope; p = p.parent)
      if (p["contentY"] !== undefined && p["contentItem"] !== undefined && p["interactive"] !== undefined) return p
    return null
  }
  function scrollTo(it) {
    var page = root.pageOf(it)
    if (!page || page.contentHeight <= page.height) return
    var y = it.mapToItem(page.contentItem, 0, 0).y
    var margin = Type.px(24)
    if (y - margin < page.contentY) page.contentY = Math.max(0, y - margin)
    else if (y + it.height + margin > page.contentY + page.height)
      page.contentY = Math.min(page.contentHeight - page.height, y + it.height + margin - page.height)
  }
  // `byKey`: moved by a key, so scrolled into view, and the pointer's gate
  // shut until it moves again.
  function set(it, byKey) {
    root.item = it || null
    root.shown = !!it
    if (it && byKey !== false) { root.scrollTo(it); gate.primed = false }
    root.place()
  }
  function place() {
    var it = root.item
    if (!it) return
    var p = it.mapToItem(root, 0, 0)
    root.rect = Qt.rect(p.x, p.y, it.width, it.height)
    root.at = Qt.point(p.x + it.width / 2, p.y + it.height / 2)
    var page = root.pageOf(it)
    if (!page) { root.outOfView = false; return }
    var v = page.mapToItem(root, 0, 0)
    root.outOfView = p.y + it.height <= v.y || p.y >= v.y + page.height
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
    if (root.at.x < 0 && typeof root.prefer === "function") {
      var liked = items.filter(function(it) { return root.prefer(it) })
      if (liked.length) items = liked
    }
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
    root.set(items[Cursor.move(root.stopsOf(items), from, dx, dy, root.loose)])
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

  // The pointer: only a real move counts (more than a pixel since the last
  // sample, and never the first sample after a key), then the part under
  // it, looked up at most every 40 ms.
  QtObject {
    id: gate
    property bool primed: false
    property point last: Qt.point(0, 0)
    property point pending: Qt.point(0, 0)
  }
  // On the scope, an ancestor of every part, so it never takes the hover
  // from the parts themselves.
  HoverHandler {
    parent: root.scope
    enabled: root.follow && root.active && !!root.scope
    onPointChanged: {
      if (!root.scope) return
      var p = root.mapFromItem(root.scope, point.position.x, point.position.y)
      if (!gate.primed) { gate.primed = true; gate.last = p; return }
      if (Math.abs(p.x - gate.last.x) <= 1 && Math.abs(p.y - gate.last.y) <= 1) return
      gate.last = p
      gate.pending = p
      if (!pointerPick.running) pointerPick.start()
    }
  }
  Timer {
    id: pointerPick
    interval: 40
    onTriggered: {
      var items = root.stopItems()
      var i = Cursor.at(root.stopsOf(items), gate.pending)
      if (i >= 0 && items[i] !== root.item) root.set(items[i], false)
    }
  }

  Item {
    id: bracket
    readonly property int out: Type.px(3)
    readonly property int arm: Type.px(7)
    readonly property real high: root.inside ? Math.max(1, root.rect.y - out) : root.rect.y - out
    readonly property real low: root.inside ? Math.min(root.height - 1, root.rect.y + root.rect.height + out)
      : root.rect.y + root.rect.height + out
    visible: root.shown && root.active && root.rect.width > 0 && !root.outOfView
    x: root.rect.x - out
    y: high
    width: root.rect.width + 2 * out
    height: low - high
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
