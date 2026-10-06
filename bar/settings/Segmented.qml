pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A segmented control: the options side by side in one hairline frame, the
// chosen one a bone plate. Mono labels, the way Ryoku's settings set them.
Rectangle {
  id: root

  property var options: []
  property string selected: ""
  // Jp-looking options (seal glyphs) use the CJK face.
  signal picked(string value)

  implicitWidth: row.implicitWidth + 2
  implicitHeight: Type.px(24)
  radius: 3
  color: "transparent"
  border.width: 1
  border.color: Ink.lineStrong
  clip: true

  Row {
    id: row
    x: 1
    y: 1
    height: parent.height - 2
    Repeater {
      model: root.options
      Rectangle {
        id: seg
        required property var modelData
        required property int index
        readonly property bool on: String(modelData) === root.selected
        width: label.implicitWidth + 2 * Type.px(8)
        height: row.height
        color: on ? Ink.bone : hover.containsMouse ? Ink.lineSoft : "transparent"
        Rectangle { visible: seg.index > 0; width: 1; height: parent.height; color: Ink.line }
        Text {
          id: label
          anchors.centerIn: parent
          text: String(seg.modelData)
          color: seg.on ? Ink.boneInk : Ink.inkDim
          font.family: /[　-鿿]/.test(text) ? Type.jp : Type.mono
          font.pixelSize: Type.px(9.5)
          font.letterSpacing: 1
        }
        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(String(seg.modelData))
        }
      }
    }
  }
}
