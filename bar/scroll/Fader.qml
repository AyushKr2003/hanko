pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One fader of the Sound section's bank: the value in serif over a rail
// with a scale, an inked fill and a cap; the master's cap is seal red, a
// muted channel goes faint and shows a dash. Drag or scroll it.
Item {
  id: root

  property string name: ""
  // 0..1
  property real value: 0
  property bool master: false
  property bool muted: false

  signal moved(real value)

  readonly property real v: Math.max(0, Math.min(1, value))
  readonly property int railHeight: Type.px(150)

  implicitWidth: Type.px(46)
  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: parent.width
    spacing: Type.px(8)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.muted ? "—" : String(Math.round(root.v * 100))
      color: root.muted ? Ink.inkFaint : Ink.ink
      font.family: Type.display
      font.pixelSize: Type.px(22)
      font.weight: Font.Normal
      font.variableAxes: { "opsz": 36, "wght": 400 }
    }

    Item {
      id: rail
      width: parent.width
      height: root.railHeight

      // The scale: eleven marks, every fifth longer.
      Repeater {
        model: 11
        Rectangle {
          id: mark
          required property int index
          readonly property bool major: index % 5 === 0
          x: Type.px(12) - width
          y: Math.round(index / 10 * (rail.height - 1))
          width: major ? Type.px(12) : Type.px(6)
          height: 1
          color: major ? Ink.lineStrong : Ink.line
        }
      }
      Rectangle {
        x: Type.px(22)
        width: 3
        height: parent.height
        radius: 2
        color: Ink.lineSoft
      }
      Rectangle {
        x: Type.px(22)
        y: parent.height - height
        width: 3
        height: Math.round(root.v * parent.height)
        radius: 2
        color: root.muted ? Ink.inkFaint : Ink.ink
      }
      Rectangle {
        x: Type.px(13)
        y: Math.round(rail.height - root.v * rail.height - height / 2)
        width: Type.px(21)
        height: Type.px(10)
        radius: 2
        color: root.master ? Ink.seal : Ink.paper
        border.width: 1
        border.color: root.master ? Ink.seal : Ink.ink
        Rectangle {
          x: 3
          width: parent.width - 6
          y: Math.round(parent.height / 2) - 1
          height: 1
          color: root.master ? Ink.paper : Ink.ink
        }
      }
      MouseArea {
        anchors.fill: parent
        anchors.margins: -Type.px(6)
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function at(y) { return Math.max(0, Math.min(1, 1 - (y - Type.px(6)) / rail.height)) }
        onPressed: function(mouse) { root.moved(at(mouse.y)) }
        onPositionChanged: function(mouse) { if (pressed) root.moved(at(mouse.y)) }
        onWheel: function(wheel) { root.moved(Math.max(0, Math.min(1, root.v + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))) }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.name
      color: Ink.inkDim
      font.family: Type.text
      font.pixelSize: Type.px(11.5)
    }
  }
}
