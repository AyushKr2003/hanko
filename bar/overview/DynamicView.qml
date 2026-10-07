pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Overview.js" as O

// The dynamic overview (`overview: dynamic`), Ryoku's, kept to its layout
// and its gestures: a mark top left (the seal, OVERVIEW, DESKTOP 01), the
// desktop strip top centre, the viewed desktop's busy workspaces as live
// mini-desktops wrapped into as many centred rows as fit (no scrolling),
// one + cell after them, and the keys along the foot. Ryoku's colours are
// read from the theme: its vermilion is the seal, its creams are the inks.
// Scroll or Tab moves a selection without switching; Enter or a click goes
// and closes. Pure QtQuick: bar/OverviewWindow.qml feeds it and dispatches.
Item {
  id: root

  // This screen's workspaces ({ id, count, all, urgent }), every numbered
  // id Hyprland has, the live one, the monitor's aspect (height / width).
  property var spaces: []
  property var allIds: []
  property int activeId: 1
  property real aspect: 0.5625
  property int topInset: 0
  property int bottomInset: 0
  property string glyph: "印"
  // file:// wallpaper, a window's snapshot builder, an app's icon (null in
  // the harness).
  property string wallpaper: ""
  property Component snapshot: null
  property var iconFor: null
  property bool animateIn: true
  property real reveal: 1

  signal goTo(int id)
  signal windowFocused(string address)
  signal windowMoved(string address, int id)
  signal windowClosed(string address)
  signal dismissed()

  // ------------------------------------------------ desktops and cells
  readonly property int activeDesk: O.deskOf(activeId)
  property int viewedDesk: activeDesk
  readonly property var screenIds: spaces.filter(function(s) { return s.id > 0 }).map(function(s) { return s.id })
  readonly property var desks: O.deskList(screenIds, activeId, allIds)
  readonly property var slots: O.slots(spaces, activeId, viewedDesk, allIds)
  function dotsOf(d) { return O.deskDots(spaces, d) }

  property int selected: 0
  // Back to the live workspace each time it opens.
  function seed() {
    viewedDesk = activeDesk
    var s = O.slots(spaces, activeId, activeDesk, allIds)
    selected = 0
    for (var i = 0; i < s.length; i++) if (s[i].id === activeId) selected = i
  }
  function cycle(d) { selected = O.cycle(selected, d, slots.length) }
  function cycleDesk(d) {
    var at = Math.max(0, desks.indexOf(viewedDesk))
    showDesk(desks[O.cycle(at, d, desks.length)])
  }
  function showDesk(d) { viewedDesk = d; selected = 0 }
  function newDesktop(d) { goTo(d * O.PER_DESKTOP + 1) }
  function activateSelected() { if (selected >= 0 && selected < slots.length) goTo(slots[selected].id) }
  function go(id) { goTo(id) }
  function focusWindow(address) { windowFocused(address) }
  function closeWindow(address) { windowClosed(address) }

  // ------------------------------------------------ dragging a window
  property bool dragging: false
  property string dragAddress: ""
  property int dragFrom: -1
  property int dragCell: -1
  property int dragDesk: -1
  property real dragX: 0
  property real dragY: 0
  function beginDrag(address, fromId) { dragAddress = address; dragFrom = fromId; dragging = true }
  function dragTo(x, y) {
    dragX = x; dragY = y
    dragDesk = deskAt(x, y)
    dragCell = dragDesk >= 0 ? -1 : cellAt(x - grid.x, y - grid.y)
  }
  function drop() {
    if (dragDesk >= 0 && dragDesk !== O.deskOf(dragFrom)) windowMoved(dragAddress, landingFor(dragDesk))
    else if (dragCell > 0 && dragCell !== dragFrom) windowMoved(dragAddress, dragCell)
    endDrag()
  }
  function endDrag() { dragging = false; dragAddress = ""; dragFrom = -1; dragCell = -1; dragDesk = -1 }
  function cellAt(px, py) {
    for (var i = 0; i < slots.length; i++) {
      var b = layout.items[i]
      if (b && px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h) return slots[i].id
    }
    return -1
  }
  function deskAt(px, py) {
    var lx = px - stripWrap.x, ly = py - stripWrap.y
    if (ly < 0 || ly > deskH || lx < 0) return -1
    var unit = deskW + deskGap
    var i = Math.floor(lx / unit)
    if (lx - i * unit > deskW || i >= desks.length) return -1
    return desks[i]
  }
  // A window moved to a desktop lands on its lowest workspace.
  function landingFor(d) {
    var lo = -1
    for (var i = 0; i < screenIds.length; i++)
      if (O.deskOf(screenIds[i]) === d && (lo < 0 || screenIds[i] < lo)) lo = screenIds[i]
    return lo > 0 ? lo : d * O.PER_DESKTOP + 1
  }

  // ------------------------------------------------ geometry (Ryoku's numbers)
  readonly property real deskW: Type.px(122)
  readonly property real deskH: Type.px(58)
  readonly property real deskGap: Type.px(14)
  readonly property real stripTop: topInset + Type.px(40)
  readonly property real regionTop: stripTop + deskH + Type.px(46)
  readonly property real regionBottom: height - bottomInset - Type.px(78)
  readonly property real availW: width - 2 * Type.px(72)
  readonly property real availH: Math.max(Type.px(150), regionBottom - regionTop)
  readonly property var layout: O.lay(slots.length, availW, availH, aspect, Type.px(18), Type.px(132), Type.px(460), Type.px(6))

  // Ryoku's card and tile fills, from the theme's paper and ink.
  readonly property color cardColor: Qt.tint(Ink.paper, Ink.alpha(Ink.ink, 0.03))
  readonly property color tileColor: Qt.tint(Ink.paper, Ink.alpha(Ink.ink, 0.07))
  readonly property color sealLit: Qt.lighter(Ink.seal, 1.22)

  // The scrim over the desk; a click on it dismisses.
  Rectangle {
    y: root.topInset
    width: parent.width
    height: parent.height - root.topInset - root.bottomInset
    color: Qt.rgba(0, 0, 0, 0.32)
    opacity: root.reveal
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.dismissed() }
  }

  Item {
    anchors.fill: parent
    opacity: root.reveal
    scale: 0.97 + 0.03 * root.reveal

    // The mark, top left.
    Row {
      x: Type.px(52)
      y: root.topInset + Type.px(46)
      spacing: Type.px(11)
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(24); height: width
        color: Ink.seal
        Text {
          anchors.centerIn: parent
          text: root.glyph
          color: Ink.paper
          font.family: Type.jpSerif
          font.pixelSize: Type.px(14)
        }
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text { text: "OVERVIEW"; color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(12); font.letterSpacing: Type.px(3); font.weight: Font.DemiBold }
        Text { text: "DESKTOP " + ("0" + (root.viewedDesk + 1)).slice(-2); color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.px(9); font.letterSpacing: Type.px(2) }
      }
    }

    // The desktops, top centre.
    Item {
      id: stripWrap
      x: (root.width - strip.width) / 2
      y: root.stripTop
      width: strip.width
      height: root.deskH
      DesktopStrip { id: strip; view: root }
    }

    // The viewed desktop's cells.
    Item {
      id: grid
      x: Type.px(72)
      y: root.regionTop
      width: root.availW
      height: root.availH
      Repeater {
        model: root.slots
        DynamicCell {
          id: cellItem
          required property var modelData
          required property int index
          readonly property var box: root.layout.items[cellItem.index] || ({ x: 0, y: 0, w: 10, h: 10 })
          x: cellItem.box.x
          y: cellItem.box.y
          width: cellItem.box.w
          height: cellItem.box.h
          view: root
          slot: cellItem.modelData
          order: cellItem.index
          selected: root.selected === cellItem.index
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.height - root.bottomInset - Type.px(38) - height
      text: O.DYNAMIC_HINT
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(10)
      font.letterSpacing: Type.px(2)
      opacity: 0.85
    }
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function(event) { if (event.angleDelta.y !== 0) root.cycle(event.angleDelta.y < 0 ? 1 : -1) }
  }

  // The carried window, with its hard shadow.
  Item {
    anchors.fill: parent
    z: 100
    visible: root.dragging
    readonly property real gw: Type.px(150)
    readonly property real gh: Math.round(Type.px(150) * root.aspect)
    Rectangle { x: root.dragX - parent.gw / 2 + Type.px(8); y: root.dragY - parent.gh / 2 + Type.px(8); width: parent.gw; height: parent.gh; color: "#000000"; opacity: 0.8 }
    Rectangle {
      x: root.dragX - parent.gw / 2
      y: root.dragY - parent.gh / 2
      width: parent.gw
      height: parent.gh
      color: root.tileColor
      border.width: 2
      border.color: Ink.seal
      Loader {
        anchors.fill: parent
        anchors.margins: 2
        active: root.dragging && root.snapshot !== null
        sourceComponent: root.snapshot
        onLoaded: item.address = root.dragAddress
      }
    }
  }
}
