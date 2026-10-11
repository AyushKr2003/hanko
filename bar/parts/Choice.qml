pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One of a few (a segmented control): Shōji's sliding doors (fusuma) in a
// frame; the ink door slides to the one picked.
Item {
  id: root

  property var skin: ({})
  property var options: []          // [{ key, label }]
  property string current: ""
  signal picked(string key)

  readonly property int index: {
    for (var i = 0; i < options.length; i++) if (options[i].key === current) return i
    return -1
  }
  readonly property real cellW: options.length ? width / options.length : 0

  implicitHeight: Type.px(38)

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.width: 1
    border.color: Ink.ink4
  }
  Repeater {
    model: Math.max(0, root.options.length - 1)
    Rectangle { required property int index; x: (index + 1) * root.cellW; width: 1; height: root.height; color: Ink.kLine }
  }
  Rectangle {
    visible: root.index >= 0
    x: root.index * root.cellW
    width: root.cellW; height: root.height
    color: Ink.ink
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(root.skin.open || 200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] } }
  }
  Repeater {
    model: root.options
    Item {
      id: opt
      required property var modelData
      required property int index
      x: index * root.cellW
      width: root.cellW; height: root.height
      Text {
        anchors.centerIn: parent
        text: opt.modelData.label
        color: opt.index === root.index ? Ink.paper : Ink.ink3
        font.family: Type.text; font.pixelSize: Type.px(12.5)
        font.weight: opt.index === root.index ? Font.Medium : Font.Normal
        font.variableAxes: Type.valueAxes
      }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(opt.modelData.key) }
    }
  }
}
