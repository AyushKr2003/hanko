import QtQuick
import "../../core"

// A tile on a Dial sheet: a mark or kanji, a name, a line under it and a
// note in the corner; a thin gauge along its foot when it has a level. The
// one that is on turns into a bone plate, as rows do on a ledger. After
// quick-settings tiles (the pick is the tile, not a switch inside it).
Rectangle {
  id: root

  property string mark: ""
  property string name: ""
  property string detail: ""
  property string note: ""
  property real level: -1
  property bool selected: false
  property bool interactive: true
  property bool urgent: false

  signal clicked()

  implicitHeight: Type.px(64)
  radius: 3
  color: selected ? Ink.bone : hover.containsMouse && interactive ? Ink.alpha(Ink.bone, 0.06) : "transparent"
  border.width: 1
  border.color: selected ? Ink.bone : hover.containsMouse && interactive ? Ink.inkMuted : Ink.line
  transform: Translate { y: hover.pressed && root.interactive ? 1 : 0 }

  readonly property color ink: selected ? Ink.boneInk : Ink.ink
  readonly property color soft: selected ? Ink.alpha(Ink.boneInk, 0.7) : Ink.inkMuted

  Text {
    visible: root.mark !== ""
    x: Type.px(10)
    y: Type.px(8)
    text: root.mark
    color: root.urgent ? Ink.seal : root.soft
    font.family: Type.brush
    font.pixelSize: Type.px(14)
  }
  Text {
    visible: root.note !== ""
    anchors.right: parent.right
    anchors.rightMargin: Type.px(10)
    y: Type.px(10)
    text: root.note.toUpperCase()
    color: root.soft
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }
  Column {
    x: Type.px(10)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(root.level >= 0 ? 12 : 9)
    width: parent.width - 2 * x
    spacing: Type.px(1)
    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.name
      color: root.ink
      font.family: Type.text
      font.pixelSize: Type.note
      font.weight: Type.valueWeight
      font.variableAxes: Type.valueAxes
    }
    Text {
      visible: text !== ""
      width: parent.width
      elide: Text.ElideRight
      text: root.detail
      color: root.soft
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
  }
  // The level, a hairline along the foot inked up to it.
  Item {
    visible: root.level >= 0
    x: Type.px(10)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(6)
    width: parent.width - 2 * x
    height: 2
    Rectangle { y: 1; width: parent.width; height: 1; color: root.selected ? Ink.alpha(Ink.boneInk, 0.3) : Ink.line }
    Rectangle { width: parent.width * Math.max(0, Math.min(1, root.level)); height: 2; color: root.urgent ? Ink.seal : root.ink }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
