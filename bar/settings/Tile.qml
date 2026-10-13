import QtQuick
import "../../core"

// One choice as a picture over its caption (docs/settings-kosei): the
// shared grammar of every page after the proof. Whatever is put inside is
// drawn on the stage; the caption names it (kanji, name, a line). The one
// in use is inverted with a // lead; hovering one says so (`hovered`).
Rectangle {
  id: tile

  property bool on: false
  property string name: ""
  property string jp: ""
  property string line: ""
  property real stageHeight: Type.px(120)
  default property alias content: stage.data
  readonly property alias stage: stage
  readonly property bool hovered: hover.containsMouse

  signal clicked()

  implicitHeight: stage.height + caption.height + 2
  radius: 3
  color: hover.containsMouse && !on ? Ink.lineSoft : "transparent"
  border.width: 1
  border.color: on ? Ink.bone : hover.containsMouse ? Ink.lineStrong : Ink.line
  clip: true

  Item {
    id: stage
    x: 1
    y: 1
    width: tile.width - 2
    height: tile.stageHeight
    clip: true
  }

  Rectangle {
    id: caption
    x: 1
    y: stage.y + stage.height
    width: tile.width - 2
    height: captionColumn.height + 2 * Type.px(8)
    color: tile.on ? Ink.bone : "transparent"
    Rectangle { visible: !tile.on; width: parent.width; height: 1; color: Ink.lineSoft }
    Column {
      id: captionColumn
      x: Type.px(10)
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 2 * x
      spacing: Type.px(1)
      Row {
        spacing: Type.px(6)
        Text { visible: tile.on; anchors.baseline: tileName.baseline; text: "//"; color: Ink.boneInk; opacity: 0.6; font.family: Type.mono; font.pixelSize: Type.px(11) }
        Text { visible: tile.jp !== ""; anchors.baseline: tileName.baseline; text: tile.jp; color: tile.on ? Ink.boneInk : Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.px(13) }
        Text {
          id: tileName
          text: tile.name
          color: tile.on ? Ink.boneInk : Ink.ink
          font.family: Type.text
          font.pixelSize: Type.px(14)
          font.weight: Font.Medium
          font.variableAxes: Type.valueAxes
        }
      }
      Text {
        visible: tile.line !== ""
        width: parent.width
        elide: Text.ElideRight
        text: tile.line
        color: tile.on ? Ink.alpha(Ink.boneInk, 0.72) : Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.note
      }
    }
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: tile.clicked()
  }
}
