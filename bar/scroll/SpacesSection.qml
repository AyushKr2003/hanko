pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Spaces.js" as Spaces
import "../../core/Time.js" as T

// 05 // SPACES: a map of every workspace's real tiling, windows named; the
// active one framed in ink with its focused window on a plate. Click a
// window to go to it, an empty space to switch there.
ScrollSection {
  id: root

  // Hypr.spacesFor(): [{ id, active, urgent, count, windows }]
  property var spaces: []

  signal request(string what, var arg)

  title: T.counted(spaces.length, "space", "spaces")
  caption: "Click a window to go there"

  Row {
    id: tiles
    width: parent.width
    topPadding: Type.px(22)
    spacing: Type.px(14)

    Repeater {
      model: root.spaces
      Column {
        id: space
        required property var modelData
        width: (tiles.width - tiles.spacing * (root.spaces.length - 1)) / Math.max(1, root.spaces.length)
        spacing: Type.px(8)

        Rectangle {
          id: frame
          width: parent.width
          height: Type.px(96)
          radius: 3
          color: "transparent"
          border.width: 1
          border.color: space.modelData.active ? Ink.ink : Ink.line

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request("workspace", space.modelData.id)
          }

          Repeater {
            model: space.modelData.windows || []
            Rectangle {
              id: win
              required property var modelData
              readonly property bool plate: space.modelData.active && modelData.focused
              x: Math.round(modelData.x * frame.width) + 3
              y: Math.round(modelData.y * frame.height) + 3
              width: Math.max(4, Math.round(modelData.w * frame.width) - 6)
              height: Math.max(4, Math.round(modelData.h * frame.height) - 6)
              radius: 2
              color: plate ? Ink.bone : hover.containsMouse ? Ink.line : Ink.lineSoft
              border.width: 1
              border.color: Ink.line
              clip: true
              Text {
                x: Type.px(6)
                y: Type.px(5)
                width: parent.width - Type.px(10)
                elide: Text.ElideRight
                text: win.modelData.name || ""
                color: win.plate ? Ink.boneInk : Ink.inkDim
                font.family: Type.text
                font.pixelSize: Type.px(11)
              }
              MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (win.modelData.address) root.request("window", win.modelData.address)
                  else root.request("workspace", space.modelData.id)
                }
              }
            }
          }
        }

        Row {
          spacing: Type.px(6)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Spaces.numeral(space.modelData.id)
            color: space.modelData.active ? Ink.seal : Ink.inkMuted
            font.family: Type.jpSerif
            font.pixelSize: Type.px(13)
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: space.modelData.count ? space.modelData.count + " WIN" : "EMPTY"
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.label
            font.letterSpacing: Type.trackLabel
          }
        }
      }
    }
  }
}
