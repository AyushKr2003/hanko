pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A segmented control: the options side by side in one hairline frame, the
// chosen one a bone plate that slides to a new choice (Motion.slide). Mono
// labels, the way Ryoku's settings set them.
Rectangle {
  id: root

  property var options: []
  property string selected: ""
  // What a segment shows, when not the option itself (value -> label).
  property var labels: ({})
  // A width to fill, the segments sharing it evenly (0: each its own width).
  property real fill: 0
  // Jp-looking options (seal glyphs) use the CJK face.
  signal picked(string value)

  implicitWidth: row.implicitWidth + 2
  implicitHeight: Type.px(24)
  radius: 3
  color: "transparent"
  border.width: 1
  border.color: Ink.lineStrong
  clip: true

  // The lit segment, reported by the segments themselves as they are built
  // and as the choice changes (a binding over itemAt() is not told when
  // the Repeater builds its items, so it could stay empty).
  property Item chosen: null
  function note(item: Item, on: bool) {
    if (on) chosen = item
    else if (chosen === item) chosen = null
  }

  Rectangle {
    visible: root.chosen !== null
    x: row.x + (root.chosen ? root.chosen.x : 0)
    y: row.y
    width: root.chosen ? root.chosen.width : 0
    height: row.height
    color: Ink.bone
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: Motion.live; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
  }

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
        onOnChanged: root.note(seg, seg.on)
        Component.onCompleted: root.note(seg, seg.on)
        Component.onDestruction: if (root.chosen === seg) root.chosen = null
        width: Math.max(label.implicitWidth + 2 * Type.px(8), (root.fill - 2) / Math.max(1, root.options.length))
        height: row.height
        color: !on && hover.containsMouse ? Ink.lineSoft : "transparent"
        Rectangle { visible: seg.index > 0; width: 1; height: parent.height; color: Ink.line }
        Text {
          id: label
          anchors.centerIn: parent
          readonly property bool jp: /[　-鿿]/.test(text)
          text: root.labels[String(seg.modelData)] || String(seg.modelData)
          color: seg.on ? Ink.boneInk : Ink.inkDim
          font.family: jp ? Type.jp : Type.mono
          font.pixelSize: jp ? Type.glossMid : Type.label
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
