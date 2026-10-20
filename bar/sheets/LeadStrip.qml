pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// The first slip on the rail, the widest, hung at the right where vertical
// writing begins: the sheet's kanji brushed large at its head, its reading
// set under it, and a caption down its edge. Where the reading is a level
// you set (volume, brightness), ink washes down the slip as far as the
// level, and pulling the slip (dragging down it, or scrolling) sets it.
Item {
  id: root

  property string mark: ""
  property string figure: ""
  // Set instead of figure to stack the reading down the slip, one part a
  // line (the time: hours, minutes, then AM or PM); a part with no digit is
  // set small, like the unit.
  property var lines: []
  property string unit: ""
  property string caption: ""
  property real level: -1
  property bool red: false
  property bool muted: false
  property bool settable: false
  property real reach: Type.px(220)
  property real step: 0.05

  signal moved(real value)

  // Te 手 (core/Cursor.js): Up/Down pull the slip (down hangs it longer),
  // Left/Right go along the rail.
  readonly property bool keyStop: settable
  readonly property bool keyStep: true
  readonly property string keyAxis: "y"
  function keyAdjust(d) { root.moved(Math.max(0, Math.min(1, root.v + d * root.step))) }

  // How long the slip needs to be for a stacked reading and its caption
  // to fit whole, the caption following straight on from the reading.
  readonly property real natural: stack.y + stack.height + Type.px(10) + cap.implicitWidth + Type.px(12)

  readonly property real cord: Type.px(12)
  readonly property real v: Math.max(0, Math.min(1, level))

  width: Type.px(88)
  height: cord + reach + Type.px(8)

  Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: root.cord; color: Ink.lineStrong }

  Rectangle {
    id: paper
    y: root.cord
    width: parent.width
    height: root.reach
    radius: 1
    color: Ink.alpha(Ink.bone, 0.05)
    border.width: 1
    border.color: Ink.lineStrong
    clip: true

    // The wash: ink soaked down the slip as far as the level.
    Rectangle {
      visible: root.level >= 0
      width: parent.width
      height: Math.round(parent.height * root.v)
      color: root.red && root.muted ? Ink.alpha(Ink.seal, 0.10) : Ink.alpha(Ink.ink, root.muted ? 0.04 : 0.09)
      Behavior on height { enabled: Motion.live; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      // Its edge, where you pull from.
      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: root.red ? Ink.seal : root.muted ? Ink.inkMuted : Ink.ink
      }
    }

    Text {
      id: big
      anchors.horizontalCenter: parent.horizontalCenter
      y: Type.px(10)
      text: root.mark
      color: Ink.ink
      font.family: Type.brush
      font.pixelSize: Type.px(40)
    }
    Row {
      id: reading
      visible: root.lines.length === 0
      anchors.horizontalCenter: parent.horizontalCenter
      y: big.y + big.height + Type.px(2)
      Text {
        id: fig
        readonly property int size: root.figure.length > 3 ? Type.px(20) : Type.px(28)
        text: root.figure
        color: root.red && root.muted ? Ink.seal : Ink.ink
        font.family: Type.display
        font.pixelSize: fig.size
        font.variableAxes: Type.axes(fig.size)
        font.features: { "tnum": 1, "lnum": 1 }
      }
      Text {
        visible: root.unit !== ""
        y: Type.px(4)
        text: root.unit
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
      }
    }
    Column {
      id: stack
      visible: root.lines.length > 0
      anchors.horizontalCenter: parent.horizontalCenter
      y: big.y + big.height + Type.px(2)
      Repeater {
        model: root.lines
        Text {
          required property var modelData
          readonly property bool digits: /\d/.test(String(modelData))
          readonly property int size: Type.px(28)
          anchors.horizontalCenter: parent.horizontalCenter
          text: String(modelData)
          color: digits ? (root.red && root.muted ? Ink.seal : Ink.ink) : Ink.inkMuted
          font.family: digits ? Type.display : Type.mono
          font.pixelSize: digits ? size : Type.tag
          font.letterSpacing: digits ? 0 : Type.trackTag
          font.variableAxes: digits ? Type.axes(size) : ({})
          font.features: { "tnum": 1, "lnum": 1 }
          topPadding: digits ? 0 : Type.px(4)
        }
      }
    }
    // The caption, down the slip's foot; under a stacked reading it follows
    // straight on from it instead, so no blank runs between the two.
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.lines.length > 0 ? readingFoot + Type.px(10) : paper.height - Type.px(10) - height
      width: cap.implicitHeight
      // Below the reading, and on a slip you pull below the wash's edge too,
      // so the caption never crosses where you grab. A wash you cannot pull
      // (the day spent) lets the caption lie over it.
      readonly property real readingFoot: root.lines.length > 0 ? stack.y + stack.height : reading.y + reading.height
      readonly property real room: Math.min(
        root.settable || root.level < 0
          ? paper.height - Type.px(20) - (root.level >= 0 ? Math.round(paper.height * root.v) : paper.height * 0.55)
          : paper.height,
        paper.height - Type.px(20) - readingFoot)
      visible: room >= Type.px(28)
      height: Math.max(0, Math.min(cap.implicitWidth, room))
      Text {
        id: cap
        width: parent.height
        x: (parent.width - width) / 2
        y: (parent.height - implicitHeight) / 2
        rotation: 90
        elide: Text.ElideRight
        text: root.caption.toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackEyebrow
      }
    }
  }

  MouseArea {
    y: root.cord
    width: root.width
    height: root.reach
    enabled: root.settable
    cursorShape: Qt.SizeVerCursor
    preventStealing: true
    function at(my) { return Math.max(0, Math.min(1, my / Math.max(1, height))) }
    onPressed: function(m) { root.moved(at(m.y)) }
    onPositionChanged: function(m) { if (pressed) root.moved(at(m.y)) }
    onWheel: function(w) { root.moved(Math.max(0, Math.min(1, root.v + (w.angleDelta.y > 0 ? root.step : -root.step)))) }
  }
}
