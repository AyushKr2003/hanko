pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A crest-book page's head: the sheet's own mon drawn large (a kuyō whose
// stars are the level, or a character in the ring), and beside it the
// sheet's reading in Fraunces with a few mono lines and its buttons. Where
// the level is yours to set, scroll on the crest, or click one of its stars.
Item {
  id: root

  property string kind: "kuyo"
  property string glyph: ""
  property real level: -1
  property bool red: false
  property bool settable: false
  property string figure: ""
  property string unit: ""
  property string title: ""
  property color titleColor: Ink.ink
  property var lines: []
  default property alias buttons: buttonRow.data
  property real step: 0.05

  signal moved(real value)

  width: parent ? parent.width : 0
  implicitHeight: Math.max(crest.height, side.implicitHeight)

  Crest {
    id: crest
    width: Type.px(132)
    height: width
    kind: root.kind
    glyph: root.glyph
    level: root.level
    urgent: root.red
    MouseArea {
      anchors.fill: parent
      enabled: root.settable
      cursorShape: Qt.PointingHandCursor
      // A click on a star sets the level to it: the nearest of the eight.
      onClicked: function(m) {
        var a = Math.atan2(m.y - height / 2, m.x - width / 2) + Math.PI / 2
        if (a < 0) a += 2 * Math.PI
        var i = Math.round(a / (2 * Math.PI / 8)) % 8
        root.moved((i === 0 ? 8 : i) / 8)
      }
      onWheel: function(w) { root.moved(Math.max(0, Math.min(1, root.level + (w.angleDelta.y > 0 ? root.step : -root.step)))) }
    }
  }

  Column {
    id: side
    x: crest.width + Type.px(22)
    anchors.verticalCenter: crest.verticalCenter
    width: root.width - x
    spacing: Type.px(3)
    Row {
      Text {
        id: fig
        text: root.figure
        color: root.red ? Ink.seal : Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(40)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(40))
        font.features: { "tnum": 1, "lnum": 1 }
      }
      Text {
        visible: root.unit !== ""
        y: Type.px(8)
        text: root.unit
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
      }
    }
    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.title
      color: root.titleColor
      font.family: Type.display
      font.italic: true
      font.pixelSize: Type.px(17)
      font.variableAxes: Type.axes(Type.px(17))
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
    Item { width: 1; height: Type.px(6); visible: buttonRow.children.length > 0 }
    Row { id: buttonRow; spacing: Type.px(6) }
  }
}
