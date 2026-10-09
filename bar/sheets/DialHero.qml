pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A Dial sheet's top: the gauge on the left, and beside it what it is
// reading (a serif title and a few mono lines) over the sheet's quick
// buttons. Put a ClockFace or anything else in `face` to replace the gauge.
Item {
  id: root

  property real value: -1
  property bool red: false
  property bool muted: false
  property string figure: ""
  property string unit: ""
  property string caption: ""
  property bool interactive: true
  property string title: ""
  property color titleColor: Ink.ink
  property var lines: []
  property Component face: null
  default property alias buttons: buttonColumn.data

  signal moved(real value)

  width: parent ? parent.width : 0
  implicitHeight: Math.max(gaugeBox.height, side.implicitHeight)

  Item {
    id: gaugeBox
    width: Type.px(172)
    height: width
    DialGauge {
      visible: !root.face
      anchors.fill: parent
      value: root.value
      red: root.red
      muted: root.muted
      figure: root.figure
      unit: root.unit
      caption: root.caption
      interactive: root.interactive
      onMoved: function(v) { root.moved(v) }
    }
    Loader { anchors.fill: parent; sourceComponent: root.face }
  }

  Column {
    id: side
    x: gaugeBox.width + Type.px(20)
    anchors.verticalCenter: gaugeBox.verticalCenter
    width: root.width - x
    spacing: Type.px(4)
    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.title
      color: root.titleColor
      font.family: Type.display
      font.pixelSize: Type.px(24)
      font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(24))
    }
    Repeater {
      model: root.lines
      Text {
        required property var modelData
        width: side.width
        elide: Text.ElideRight
        text: String(modelData)
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
    }
    Item { width: 1; height: Type.px(8) }
    Column {
      id: buttonColumn
      spacing: Type.px(6)
    }
  }
}
