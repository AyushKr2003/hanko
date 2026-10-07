pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One workspace in the dynamic overview, drawn the way Ryoku's
// WorkspaceCell is: a scaled mini-desktop over the wallpaper, dimmed, a
// mono ordinal on a dark chip in the corner (seal red when live or under
// the pointer), the apps open there as a row of small icons under it, and
// every window at its real place as a tile with its live snapshot (its
// icon under it until the picture lands). A hard black shadow sits behind
// every cell and deepens as it lifts. Left-click empty space or right-
// click anywhere goes there; left-click a window focuses it; drag a window
// onto another cell or desktop to move it; ✕ on a hovered window closes
// it. The trailing cell (`add`) is the + that opens a fresh workspace.
Item {
  id: cell

  property var view: null
  // core/Overview.js slots() entry.
  property var slot: ({ id: 1, pos: 1, add: false, active: false, count: 0, windows: [] })
  property int order: 0
  property bool selected: false

  readonly property bool add: slot.add
  readonly property bool active: slot.active
  readonly property bool hot: !!view && view.dragging && view.dragCell === cell.slot.id && view.dragCell !== view.dragFrom
  property bool hovered: false
  readonly property bool lifted: hovered || hot || selected || active

  // A beat apart, each cell settles in.
  property bool appeared: Motion.still || !(view && view.animateIn)
  Timer {
    interval: 40 + cell.order * 55
    running: !cell.appeared
    onTriggered: cell.appeared = true
  }
  opacity: appeared ? 1 : 0
  scale: appeared ? 1 : 0.92
  Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
  Behavior on scale { enabled: !Motion.still; NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

  // The apps open here, one icon each, at most six.
  readonly property var icons: {
    var seen = {}, out = []
    var list = cell.slot.windows || []
    for (var i = 0; i < list.length && out.length < 6; i++) {
      var c = String(list[i].cls || list[i].name || "").toLowerCase()
      if (!c || seen[c]) continue
      seen[c] = true
      var p = cell.view && cell.view.iconFor ? cell.view.iconFor(list[i].cls || list[i].name) : ""
      if (p) out.push(p)
    }
    return out
  }

  // The hard shadow, no blur: the depth is the offset.
  Rectangle {
    x: cell.lifted ? Type.px(10) : Type.px(7)
    y: x
    width: mini.width
    height: mini.height
    color: "#000000"
    opacity: cell.active ? 0.9 : cell.lifted ? 0.8 : 0.6
    antialiasing: false
    Behavior on x { enabled: !Motion.still; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: 140 } }
  }

  Rectangle {
    id: mini
    anchors.fill: parent
    // Opaque: the shadow sits right behind it.
    color: Qt.tint(cell.view ? cell.view.cardColor : Ink.paper, cell.active ? Ink.alpha(Ink.seal, 0.08) : "transparent")
    border.width: cell.active || cell.hot || cell.selected ? 2 : 1
    border.color: cell.hot || cell.active ? Ink.seal
      : cell.selected ? (cell.view ? cell.view.sealLit : Ink.seal)
      : cell.hovered ? Ink.lineStrong
      : Ink.line
    clip: true
    Behavior on border.color { enabled: !Motion.still; ColorAnimation { duration: 90 } }

    // The wallpaper, cropped to the cell and dimmed under the windows.
    Image {
      anchors.fill: parent
      visible: !cell.add && !!cell.view && cell.view.wallpaper !== ""
      source: cell.view ? cell.view.wallpaper : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: Math.round(parent.width * 1.2)
      opacity: cell.active ? 0.62 : 0.42
      Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.28) }
    }

    // The ordinal: its place in the desktop, 01 02 03…
    Rectangle {
      id: chip
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.margins: Type.px(8)
      visible: !cell.add
      width: num.implicitWidth + Type.px(12)
      height: num.implicitHeight + Type.px(5)
      color: Qt.rgba(0, 0, 0, 0.5)
      border.width: 1
      border.color: cell.active ? Ink.seal : Ink.lineSoft
      z: 3
      Text {
        id: num
        anchors.centerIn: parent
        text: (cell.slot.pos < 10 ? "0" : "") + cell.slot.pos
        color: cell.active || cell.hovered ? Ink.seal : Ink.ink
        font.family: Type.mono
        font.pixelSize: Type.px(22)
        font.weight: Font.DemiBold
      }
    }

    Row {
      anchors.top: chip.bottom
      anchors.left: chip.left
      anchors.topMargin: Type.px(6)
      spacing: Type.px(5)
      visible: !cell.add && cell.icons.length > 0
      z: 3
      Repeater {
        model: cell.icons
        Rectangle {
          id: ico
          required property var modelData
          width: Type.px(22); height: width
          color: Qt.rgba(0, 0, 0, 0.5)
          border.width: 1
          border.color: Ink.lineSoft
          Image {
            anchors.centerIn: parent
            width: Type.px(15); height: width
            sourceSize.width: width * 2; sourceSize.height: height * 2
            source: ico.modelData
            fillMode: Image.PreserveAspectFit
          }
        }
      }
    }

    Text {
      anchors.centerIn: parent
      visible: !cell.add && (cell.slot.windows || []).length === 0
      text: "EMPTY"
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(10)
      font.letterSpacing: Type.px(2)
    }

    // Empty space: left or right goes here.
    MouseArea {
      anchors.fill: parent
      visible: !cell.add
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onEntered: cell.hovered = true
      onExited: cell.hovered = false
      onClicked: if (cell.view) cell.view.go(cell.slot.id)
    }

    // ---------------------------------------------- the windows
    Repeater {
      model: cell.add ? [] : (cell.slot.windows || [])
      Rectangle {
        id: tile
        required property var modelData
        readonly property bool over: tileArea.containsMouse || closeArea.containsMouse
        x: tile.modelData.x * mini.width
        y: tile.modelData.y * mini.height
        width: Math.max(Type.px(20), tile.modelData.w * mini.width)
        height: Math.max(Type.px(16), tile.modelData.h * mini.height)
        color: cell.view ? cell.view.tileColor : Ink.paper
        border.width: tile.over ? 2 : 1
        border.color: tile.over ? Ink.seal : Ink.lineSoft
        clip: true
        z: tile.over ? 2 : 1
        opacity: cell.view && cell.view.dragging && cell.view.dragAddress === tile.modelData.address ? 0.22 : 1

        // The icon, under the snapshot; the app's name when there is none.
        Text {
          anchors.centerIn: parent
          visible: tileIcon.status !== Image.Ready
          width: parent.width - Type.px(8)
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          text: String(tile.modelData.name || "").toUpperCase()
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.px(10)
          font.letterSpacing: Type.px(1.5)
        }
        Image {
          id: tileIcon
          anchors.centerIn: parent
          readonly property real size: Math.max(Type.px(16), Math.min(Type.px(48), Math.min(tile.width, tile.height) * 0.5))
          width: size; height: size
          sourceSize.width: size * 2; sourceSize.height: size * 2
          fillMode: Image.PreserveAspectFit
          source: cell.view && cell.view.iconFor ? cell.view.iconFor(tile.modelData.cls || tile.modelData.name) : ""
        }
        Loader {
          anchors.fill: parent
          active: !!cell.view && cell.view.snapshot !== null
          sourceComponent: cell.view ? cell.view.snapshot : null
          onLoaded: item.address = tile.modelData.address
        }

        MouseArea {
          id: tileArea
          anchors.fill: parent
          hoverEnabled: true
          preventStealing: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          property real downX: 0
          property real downY: 0
          property bool armed: false
          property int button: Qt.LeftButton
          onPressed: function(mouse) { button = mouse.button; armed = mouse.button === Qt.LeftButton; downX = mouse.x; downY = mouse.y }
          onPositionChanged: function(mouse) {
            if (!armed || !cell.view) return
            if (!cell.view.dragging) {
              if (Math.abs(mouse.x - downX) + Math.abs(mouse.y - downY) < Type.px(7)) return
              cell.view.beginDrag(tile.modelData.address, cell.slot.id)
            }
            var p = tileArea.mapToItem(cell.view, mouse.x, mouse.y)
            cell.view.dragTo(p.x, p.y)
          }
          onReleased: {
            if (!cell.view) return
            if (cell.view.dragging) cell.view.drop()
            else if (button === Qt.RightButton) cell.view.go(cell.slot.id)
            else if (armed) cell.view.focusWindow(tile.modelData.address)
            armed = false
          }
          onCanceled: { if (cell.view) cell.view.endDrag(); armed = false }
        }

        // ✕ closes the window; over the tile so it takes its own click.
        Rectangle {
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: Type.px(3)
          width: Type.px(18); height: width
          visible: tile.over && !(cell.view && cell.view.dragging)
          color: closeArea.containsMouse ? Ink.seal : Qt.rgba(0, 0, 0, 0.72)
          border.width: 1
          border.color: closeArea.containsMouse ? Ink.seal : Ink.lineStrong
          Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeArea.containsMouse ? Ink.paper : Ink.ink
            font.family: Type.mono
            font.pixelSize: Type.px(11)
            font.weight: Font.Bold
          }
          MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (cell.view) cell.view.closeWindow(tile.modelData.address)
          }
        }
      }
    }

    // ---------------------------------------------- the + cell
    Item {
      anchors.fill: parent
      visible: cell.add
      Rectangle {
        anchors.centerIn: parent
        width: Type.px(26); height: Type.px(3); radius: height / 2
        color: cell.hot || cell.hovered || cell.selected ? Ink.seal : Ink.inkFaint
      }
      Rectangle {
        anchors.centerIn: parent
        width: Type.px(3); height: Type.px(26); radius: width / 2
        color: cell.hot || cell.hovered || cell.selected ? Ink.seal : Ink.inkFaint
      }
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: cell.hovered = true
        onExited: cell.hovered = false
        onClicked: if (cell.view) cell.view.go(cell.slot.id)
      }
    }
  }
}
