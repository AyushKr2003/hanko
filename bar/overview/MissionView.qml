pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../../core"
import "../../core/Mission.js" as M
import "../../core/Spaces.js" as Spaces

// The mission overview (`overview: mission`, 見開き a spread), after
// AyushKr2003/omarchy-overview's mission control: on a sheet of the
// theme's paper, a register line, this screen's workspaces as a strip of
// small pages with their folios, the search field under it, and the live
// workspace's windows spread out at the largest size that fits, zooming
// out of their real places as it opens. Typing searches (MissionFind); the
// spread steps aside for the results. Arrows choose a window or a cell
// (moving along the strip switches there), Tab hops between the strip and
// the spread, Enter goes. Drag a window onto a cell to move it there, onto
// the + for a new space, or hold it over another window until the rule
// fills to swap the two. Pure QtQuick: bar/OverviewWindow.qml feeds it,
// runs the search and dispatches.
Item {
  id: root

  // This screen's workspaces (Hypr.workspaces rows with `all`), every
  // numbered id in use, the live id, the monitor's aspect (height / width).
  property var spaces: []
  property var allIds: []
  property int activeId: 1
  property real aspect: 0.5625
  property string screenName: ""
  property int topInset: 0
  property int bottomInset: 0
  property Component snapshot: null
  // file:// wallpaper the spread lies on, blurred and dimmed (as
  // omarchy-overview's mission control does); "" lays it on plain paper.
  property string wallpaper: ""
  // The search, as OverviewWindow keeps it.
  property string query: ""
  property var results: []
  property int resultIndex: 0
  // 0..1: the sheet prints in and the windows zoom out of the desk.
  property real reveal: 1

  signal workspacePicked(int id, bool go)
  signal windowPicked(string address)
  signal windowClosed(string address)
  signal windowMoved(string address, int id)
  signal windowsSwapped(string a, string b)
  signal resultPicked(var result)
  signal resultHovered(int index)
  signal dismissed()

  readonly property bool searching: query.length > 0

  // ------------------------------------------------ the spread
  readonly property var windows: M.windowsOf(spaces, activeId)
  readonly property var byAddress: {
    var m = {}
    for (var i = 0; i < windows.length; i++) m[windows[i].address] = windows[i]
    return m
  }
  // The desk the windows really sit on: the screen less the bar's strip.
  readonly property real deskY: topInset
  readonly property real deskH: height - topInset - bottomInset
  function realRect(w) {
    return { x: w.x * width, y: deskY + w.y * deskH, w: Math.max(1, w.w * width), h: Math.max(1, w.h * deskH) }
  }
  readonly property var spread: {
    var input = []
    for (var i = 0; i < windows.length; i++) {
      var r = realRect(windows[i])
      input.push({ key: windows[i].address, w: r.w, h: r.h, cx: r.x + r.w / 2, cy: r.y + r.h / 2 })
    }
    return M.layout(input, { x: margin, y: gridTop, w: width - 2 * margin, h: Math.max(1, gridBottom - gridTop) },
                    { gap: Type.px(34), labelHeight: captionH, maxScale: 1 })
  }
  readonly property var slots: spread.slots
  readonly property var ordered: M.order(slots)

  // ------------------------------------------------ the strip
  readonly property var keys: M.stripKeys(spaces, activeId)
  function spaceOf(key) {
    var id = M.idOfKey(key)
    for (var i = 0; i < spaces.length; i++) if (spaces[i].id === id) return spaces[i]
    return null
  }
  readonly property real cellGap: Type.px(14)
  readonly property var cellSize: M.stripCell(keys.length, stripH, width - 2 * margin, aspect, cellGap)
  readonly property real stripW: keys.length * cellSize.w + (keys.length - 1) * cellGap
  function cellBox(i) {
    return { x: (width - stripW) / 2 + i * (cellSize.w + cellGap), y: stripTop, w: cellSize.w, h: cellSize.h + folioH }
  }

  // ------------------------------------------------ geometry
  readonly property int margin: Type.px(width < Type.px(900) ? 20 : 56)
  readonly property real folioH: Type.px(22)
  readonly property real captionH: Type.px(28)
  readonly property real stripTop: topInset + head.height + Type.px(50)
  readonly property real stripH: Math.round(Math.max(Type.px(60), Math.min(Type.px(150), height * 0.13)))
  readonly property real findTop: stripTop + cellSize.h + folioH + Type.px(22)
  readonly property real gridTop: findTop + find.fieldH + Type.px(30)
  readonly property real gridBottom: height - bottomInset - foot.height - Type.px(44)

  // ------------------------------------------------ the keyboard's pick
  // region: "strip" or "grid"; index into keys or ordered.
  property string region: "strip"
  property int index: 0
  function seed() {
    region = "strip"
    index = Math.max(0, keys.indexOf("ws:" + activeId))
  }
  function focusedIndex() {
    for (var i = 0; i < ordered.length; i++) if ((byAddress[ordered[i]] || {}).focused) return i
    return ordered.length > 0 ? 0 : -1
  }
  function selectedAddress() { return region === "grid" ? (ordered[index] || "") : "" }
  function rects() { return ordered.map(function(a) { return slots[a] }) }

  // Arrows. Along the strip each step switches there, so the spread shows
  // that space; down from the strip and up from the spread's top row cross.
  function navigate(dir) {
    if (region === "strip") {
      if (dir === "left" || dir === "right") {
        var next = index + (dir === "left" ? -1 : 1)
        if (next < 0 || next >= keys.length) return
        index = next
        var id = M.idOfKey(keys[next])
        if (id > 0) workspacePicked(id, false)
      } else if (dir === "down" && ordered.length > 0) {
        region = "grid"; index = focusedIndex()
      }
      return
    }
    var n = M.neighbour(rects(), index, dir)
    if (n >= 0) index = n
    else if (dir === "up") seed()
  }
  function hop() {
    if (region === "strip" && ordered.length > 0) { region = "grid"; index = focusedIndex() }
    else seed()
  }
  // Enter: the window or the cell picked.
  function activate() {
    if (region === "grid" && ordered[index]) { windowPicked(ordered[index]); return }
    cellPicked(keys[index] || "ws:" + activeId, true)
  }
  function cellPicked(key, go) {
    var id = key === "new" ? M.freeId(allIds) : M.idOfKey(key)
    if (id > 0) workspacePicked(id, go || key === "new")
  }
  // A new space under the spread keeps the pick on the strip in step.
  onActiveIdChanged: if (region === "strip") index = Math.max(0, keys.indexOf("ws:" + activeId))
  onOrderedChanged: if (region === "grid" && index >= ordered.length) { if (ordered.length > 0) index = ordered.length - 1; else seed() }

  // ------------------------------------------------ dragging a window
  property bool dragging: false
  property string dragAddress: ""
  property real dragX: 0
  property real dragY: 0
  // What it is over: a strip key, or another window's address.
  property string dragKey: ""
  property string dragTile: ""
  property real swapProgress: 0
  NumberAnimation on swapProgress { id: swapFill; running: false; from: 0; to: 1; duration: 1500 }

  function beginDrag(address) { dragAddress = address; dragging = true }
  function dragTo(x, y) {
    dragX = x; dragY = y
    var key = ""
    for (var i = 0; i < keys.length; i++) {
      var b = cellBox(i)
      if (x >= b.x && x <= b.x + b.w && y >= b.y - Type.px(8) && y <= b.y + b.h) { key = keys[i]; break }
    }
    dragKey = key === "ws:" + activeId ? "" : key
    var over = ""
    if (!key) {
      for (var j = 0; j < ordered.length; j++) {
        var s = slots[ordered[j]]
        if (ordered[j] !== dragAddress && x >= s.x && x <= s.x + s.w && y >= s.y && y <= s.y + s.h) { over = ordered[j]; break }
      }
    }
    if (over !== dragTile) {
      dragTile = over
      swapFill.stop(); swapProgress = 0
      if (over) swapFill.restart()
    }
  }
  function drop() {
    if (dragKey === "new") windowMoved(dragAddress, M.freeId(allIds))
    else if (dragKey) windowMoved(dragAddress, M.idOfKey(dragKey))
    else if (dragTile && swapProgress >= 1) windowsSwapped(dragAddress, dragTile)
    endDrag()
  }
  function endDrag() {
    swapFill.stop()
    dragging = false; dragAddress = ""; dragKey = ""; dragTile = ""; swapProgress = 0
  }

  // ------------------------------------------------ the backdrop
  // The desk stepped back: an opaque paper base (nothing behind shows
  // through), the wallpaper over it blurred, a touch desaturated and
  // settling in as it opens, then dimmed with the paper so the ink reads.
  // A click on it (not on a window, a cell or the search) dismisses.
  Item {
    id: backdrop
    y: root.topInset
    width: parent.width
    height: parent.height - root.topInset - root.bottomInset
    opacity: root.reveal
    clip: true
    readonly property bool pictured: wall.status === Image.Ready

    Rectangle { anchors.fill: parent; color: Ink.paper }
    Image {
      id: wall
      anchors.fill: parent
      visible: false
      source: root.wallpaper
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      // Small: it is blurred anyway, and a full-size decode held the blur
      // back a second or two on every open. Kept loaded between opens.
      sourceSize.width: 640
      sourceSize.height: 360
    }
    MultiEffect {
      anchors.fill: parent
      visible: backdrop.pictured
      source: wall
      blurEnabled: true
      blur: 1.0
      blurMax: 64
      blurMultiplier: 2.5
      saturation: -0.15
      // Oversized so the blur's soft edges sit off screen.
      scale: 1.18 - 0.06 * root.reveal
    }
    Rectangle {
      anchors.fill: parent
      visible: backdrop.pictured
      color: Ink.alpha(Ink.paper, 0.5)
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.dismissed() }
  }

  // ------------------------------------------------ head
  Item {
    id: head
    x: root.margin
    y: root.topInset + Type.px(26)
    width: root.width - 2 * root.margin
    height: Type.px(16)
    opacity: root.reveal
    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(8)
      Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(18); height: 1; color: Ink.ink }
      Text { anchors.verticalCenter: parent.verticalCenter; text: "見開"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.label }
      Text { anchors.verticalCenter: parent.verticalCenter; text: "·"; color: Ink.inkFaint; font.family: Type.text; font.pixelSize: Type.label }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "MISSION" + (root.screenName ? "  ·  " + root.screenName : "")
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.eyebrow
        font.letterSpacing: Type.trackEyebrow
      }
    }
    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "SPACE " + Spaces.folio(root.activeId) + "  ·  " + (root.windows.length < 10 ? "0" : "") + root.windows.length
            + (root.windows.length === 1 ? " WINDOW" : " WINDOWS")
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackLabel
    }
  }

  // ------------------------------------------------ strip
  Item {
    id: strip
    width: root.width
    height: root.cellSize.h + root.folioH
    y: root.stripTop - (1 - root.reveal) * Type.px(24)
    opacity: root.reveal
    z: 2
    Repeater {
      model: root.keys.length
      MissionCell {
        id: cellItem
        required property int index
        readonly property var box: root.cellBox(cellItem.index)
        x: cellItem.box.x
        width: cellItem.box.w
        height: cellItem.box.h
        view: root
        key: root.keys[cellItem.index] || "new"
        space: root.spaceOf(cellItem.key)
        live: cellItem.key === "ws:" + root.activeId
        selected: root.region === "strip" && root.index === cellItem.index && !root.searching
        snapshot: root.snapshot
      }
    }
  }

  // ------------------------------------------------ search
  MissionFind {
    id: find
    x: (root.width - width) / 2
    y: root.findTop - (1 - root.reveal) * Type.px(16)
    z: 5
    width: Math.min(root.width - 2 * root.margin, Math.max(Type.px(520), root.width * 0.4))
    roomH: root.gridBottom - root.findTop
    opacity: root.reveal
    query: root.query
    results: root.results
    index: root.resultIndex
    onPicked: function(r) { root.resultPicked(r) }
    onHovered: function(i) { root.resultHovered(i) }
  }

  // ------------------------------------------------ the spread
  Text {
    visible: root.windows.length === 0 && !root.searching
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.gridTop + (root.gridBottom - root.gridTop - height) / 2
    horizontalAlignment: Text.AlignHCenter
    opacity: root.reveal
    text: Spaces.numeral(root.activeId) + "\nNothing on this space yet"
    lineHeight: 1.3
    color: Ink.inkFaint
    font.family: Type.display
    font.italic: true
    font.pixelSize: Type.px(20)
    font.variableAxes: Type.axes(Type.px(20))
  }

  Item {
    id: layer
    anchors.fill: parent
    z: 4
    // Counted, not the array: a new array each Hyprland change would
    // rebuild every tile and its snapshot would blink.
    Repeater {
      model: root.windows.length
      MissionTile {
        id: tileItem
        required property int index
        readonly property var entry: root.windows[tileItem.index] || ({ x: 0, y: 0, w: 0.1, h: 0.1, address: "", name: "" })
        view: root
        win: tileItem.entry
        realRect: root.realRect(tileItem.entry)
        slotRect: root.slots[tileItem.entry.address] || realRect
        reveal: root.reveal
        dimmed: root.searching
        selected: root.region === "grid" && root.ordered[root.index] === tileItem.entry.address && !root.searching
        snapshot: root.snapshot
      }
    }
  }

  // ------------------------------------------------ foot: the keys
  Row {
    id: foot
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height - root.bottomInset - height - Type.px(28)
    spacing: Type.px(20)
    opacity: root.reveal
    Repeater {
      model: M.KEYS
      Row {
        id: key
        required property var modelData
        spacing: Type.px(7)
        Text { text: key.modelData[0]; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
        Text { text: key.modelData[1].toUpperCase(); color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
      }
    }
  }
}
