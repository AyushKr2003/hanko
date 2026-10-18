pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../../core"
import "../../core/Mission.js" as M

// One window in the mission overview's spread, laid on the desk like a
// sheet: square, a hairline frame, style.lua's "paper" shadow cast in ink,
// its live snapshot inside and its name set under it in mono, the title
// beside in Space Grotesk. It sits at the window's real place when the
// view's reveal is 0 and at its slot when it is 1, so opening and closing
// zoom the windows out of the desk and back. Selected (the keyboard): an
// ink frame and the caption on a bone plate with a `//` lead. A dragged
// window held over it fills a seal-red rule along its foot; once full,
// letting go swaps the two. Pure: MissionView passes the data and takes
// the gestures.
Item {
  id: tile

  property var view: null
  // core/Mission.js windowsOf() entry, and its rects in the view.
  property var win: ({ address: "", name: "", title: "", focused: false, floating: false })
  property var realRect: ({ x: 0, y: 0, w: 1, h: 1 })
  property var slotRect: ({ x: 0, y: 0, w: 1, h: 1 })
  property real reveal: 1
  property bool selected: false
  property bool dimmed: false
  property Component snapshot: null

  readonly property string address: String(win.address || "")
  readonly property bool hovered: area.containsMouse
  readonly property bool carried: !!view && view.dragging && view.dragAddress === tile.address
  readonly property bool swapTarget: !!view && view.dragging && view.dragTile === tile.address
  readonly property real captionH: view ? view.captionH : Type.px(26)

  // The slot glides when the spread reflows; not when the window in this
  // place changes (another workspace), which jumps.
  property bool glide: false
  property real slotX: slotRect.x
  property real slotY: slotRect.y
  property real slotW: slotRect.w
  property real slotH: slotRect.h
  Behavior on slotX { enabled: tile.glide && !Motion.still; NumberAnimation { duration: Motion.pan; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.panCurve } }
  Behavior on slotY { enabled: tile.glide && !Motion.still; NumberAnimation { duration: Motion.pan; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.panCurve } }
  Behavior on slotW { enabled: tile.glide && !Motion.still; NumberAnimation { duration: Motion.pan; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.panCurve } }
  Behavior on slotH { enabled: tile.glide && !Motion.still; NumberAnimation { duration: Motion.pan; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.panCurve } }
  onAddressChanged: { glide = false; Qt.callLater(function() { tile.glide = true }) }
  Component.onCompleted: Qt.callLater(function() { tile.glide = true })

  x: carried ? view.dragX - pressX : M.lerp(realRect.x, slotX, reveal)
  y: carried ? view.dragY - pressY : M.lerp(realRect.y, slotY, reveal)
  width: M.lerp(realRect.w, slotW, reveal)
  height: M.lerp(realRect.h, slotH, reveal)
  z: carried ? 100 : selected || hovered ? 2 : 1
  opacity: dimmed ? 0 : 1
  Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: Motion.fade } }

  // Carried over the strip, it shrinks round the grab point.
  property real pressX: 0
  property real pressY: 0
  transform: Scale {
    origin.x: tile.pressX
    origin.y: tile.pressY
    xScale: tile.shrink
    yScale: tile.shrink
  }
  property real shrink: tile.carried && tile.view.dragKey !== "" ? 0.35 : 1
  Behavior on shrink { enabled: !Motion.still; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }

  // The paper shadow, as OverviewPage casts it; deeper while carried.
  RectangularShadow {
    anchors.fill: frame
    offset.x: Type.px(tile.carried ? 6 : 3)
    offset.y: Type.px(tile.carried ? 9 : 5)
    blur: Type.px(tile.carried ? 10 : 4)
    spread: Type.px(2)
    color: Ink.alpha(Ink.ink, tile.selected || tile.carried ? 0.5 : 0.25)
    opacity: tile.reveal
  }

  Rectangle {
    id: frame
    anchors.fill: parent
    // Opaque, so a float covers the tiling under it.
    color: Qt.tint(Ink.paper, Ink.alpha(Ink.ink, 0.05))
    clip: true

    // Ink fallback: the app's name, only where there are no snapshots
    // (Settings, the harness).
    Text {
      visible: tile.snapshot === null
      anchors.centerIn: parent
      width: parent.width - Type.px(12)
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      text: tile.win.name || ""
      color: Ink.inkFaint
      readonly property int size: Math.round(Math.max(Type.px(12), Math.min(Type.px(30), tile.height * 0.16)))
      font.family: Type.display
      font.italic: true
      font.pixelSize: size
      font.variableAxes: Type.axes(size)
    }

    Loader {
      id: snap
      anchors.fill: parent
      anchors.margins: 1
      active: tile.snapshot !== null
      sourceComponent: tile.snapshot
    }
    Binding {
      when: snap.item !== null
      target: snap.item
      property: "address"
      value: tile.address
    }

    // Hold to swap: the rule fills along the foot, then says so.
    Rectangle {
      visible: tile.swapTarget
      anchors.bottom: parent.bottom
      height: Type.px(3)
      width: parent.width * (tile.view ? tile.view.swapProgress : 0)
      color: Ink.seal
    }
    Rectangle {
      visible: tile.swapTarget && !!tile.view && tile.view.swapProgress >= 1
      anchors.centerIn: parent
      width: swapText.implicitWidth + Type.px(20)
      height: swapText.implicitHeight + Type.px(10)
      color: Ink.bone
      Text {
        id: swapText
        anchors.centerIn: parent
        text: "//  RELEASE TO SWAP"
        color: Ink.boneInk
        font.family: Type.mono
        font.pixelSize: Type.label
        font.letterSpacing: Type.trackLabel
      }
    }
  }

  // The frame over the snapshot, so it never sits under the picture.
  Rectangle {
    anchors.fill: frame
    color: "transparent"
    opacity: tile.reveal
    border.width: tile.selected || tile.swapTarget ? 2 : 1
    border.color: tile.swapTarget ? Ink.seal : tile.selected ? Ink.ink : tile.hovered ? Ink.ink : Ink.lineStrong
  }

  // The caption: a seal dot on the focused window, the app in mono, the
  // title beside it.
  Item {
    id: caption
    y: tile.height + Type.px(6)
    width: tile.width
    height: tile.captionH - Type.px(8)
    visible: !tile.carried
    opacity: tile.reveal
    Rectangle {
      id: plate
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(parent.width, line.implicitWidth + Type.px(tile.selected ? 18 : 4))
      height: parent.height
      color: tile.selected ? Ink.bone : "transparent"
      Row {
        id: line
        anchors.centerIn: parent
        width: Math.min(implicitWidth, caption.width - Type.px(tile.selected ? 18 : 4))
        spacing: Type.px(7)
        clip: true
        Text {
          visible: tile.selected
          anchors.verticalCenter: parent.verticalCenter
          text: "//"
          color: Ink.boneInk
          opacity: 0.55
          font.family: Type.mono
          font.pixelSize: Type.label
        }
        Rectangle {
          visible: !!tile.win.focused && !tile.selected
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(5); height: width; radius: width / 2
          color: Ink.seal
        }
        Text {
          id: app
          anchors.verticalCenter: parent.verticalCenter
          text: (tile.win.floating ? "◇ " : "") + String(tile.win.name || "").toUpperCase()
          color: tile.selected ? Ink.boneInk : tile.hovered ? Ink.ink : Ink.inkDim
          font.family: Type.mono
          font.pixelSize: Type.label
          font.letterSpacing: Type.trackLabel
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: text !== "" && caption.width > Type.px(150)
          width: Math.min(implicitWidth, Math.max(0, caption.width - app.implicitWidth - Type.px(46)))
          elide: Text.ElideRight
          text: tile.win.title && tile.win.title !== tile.win.name ? tile.win.title : ""
          color: tile.selected ? Ink.boneInk : Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.note
        }
      }
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: !tile.dimmed
    hoverEnabled: true
    preventStealing: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: tile.carried ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    property real downX: 0
    property real downY: 0
    onPressed: function(mouse) { downX = mouse.x; downY = mouse.y; tile.pressX = mouse.x; tile.pressY = mouse.y }
    onPositionChanged: function(mouse) {
      if (!(mouse.buttons & Qt.LeftButton) || !tile.view) return
      if (!tile.view.dragging) {
        if (Math.abs(mouse.x - downX) + Math.abs(mouse.y - downY) < Type.px(8)) return
        tile.view.beginDrag(tile.address)
      }
      var p = area.mapToItem(tile.view, mouse.x, mouse.y)
      tile.view.dragTo(p.x, p.y)
    }
    onReleased: function(mouse) {
      if (!tile.view) return
      if (tile.view.dragging) { tile.view.drop(); return }
      if (mouse.button === Qt.MiddleButton) tile.view.windowClosed(tile.address)
      else tile.view.windowPicked(tile.address)
    }
    onCanceled: if (tile.view) tile.view.endDrag()
  }
}
