pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Profile.js" as P

// Credits 謝辞, the thanks plate. A hanging scroll dissolves off the right;
// the left column carries the bilingual title, a Fraunces deck, everything
// Hanko stands on as editorial lines (a linked one inverts under the pointer
// and opens its home), and the one bone placard on the plate, for the
// people who test every build on real machines.
Item {
  id: root

  readonly property bool wide: width >= Type.px(1000)
  readonly property int margin: Type.px(wide ? 56 : 28)
  readonly property real columnWidth: wide ? Math.min(Type.px(620), width * 0.58 - margin) : width - 2 * margin

  Rectangle { anchors.fill: parent; color: Ink.paper }

  HangingScroll {
    anchors.right: parent.right
    anchors.rightMargin: root.wide ? root.margin : 0
    width: Math.min(parent.height * 0.62, root.width * (root.wide ? 0.4 : 0.9))
    height: parent.height
    opacity: root.wide ? 1 : 0.25
  }

  PlateSpine {
    x: Type.px(22)
    anchors.verticalCenter: parent.verticalCenter
    text: "HANKO  ·  感謝 KANSHA  ·  WITH THANKS  ·  SET IN INK"
  }

  Flickable {
    id: flick
    x: root.margin
    y: root.margin
    width: root.columnWidth
    height: parent.height - 2 * root.margin
    contentHeight: column.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: column
      width: flick.width
      spacing: Type.px(24)

      Column {
        width: parent.width
        spacing: Type.px(16)
        PlateEyebrow { jp: "謝辞"; label: "Kansha" }
        Column {
          Text { text: "感謝"; color: Ink.ink; font.family: Type.jpSerif; font.pixelSize: Type.px(64); font.weight: Font.Medium }
          Text {
            text: "Gratitude"
            color: Ink.ink
            font.family: Type.display
            font.pixelSize: Type.px(44)
            font.variableAxes: Type.axes(Type.px(44))
          }
        }
        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: "The paper this bar is printed on: every project, typeface and service it stands on."
          color: Ink.inkMuted
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.px(17)
          font.variableAxes: Type.axes(Type.px(17))
        }
      }

      Column {
        width: parent.width
        Repeater {
          model: P.PROJECTS
          LeaderRow {
            required property var modelData
            width: column.width
            height: Type.px(31)
            kind: "credit"
            name: modelData.name
            by: modelData.by
            value: modelData.role
            url: modelData.url
          }
        }
      }

      // The one bone plate: the people who test it on real machines.
      Rectangle {
        width: parent.width
        height: crew.height + 2 * Type.px(18)
        radius: 3
        color: Ink.bone
        Column {
          id: crew
          x: Type.px(18)
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 2 * x
          spacing: Type.px(10)
          Text {
            text: "THE PROOFREADERS  ·  校正"
            color: Ink.boneInk
            opacity: 0.65
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackEyebrow
          }
          Flow {
            width: parent.width
            Repeater {
              model: P.PROOFREADERS
              Row {
                id: person
                required property var modelData
                required property int index
                Text {
                  text: person.modelData.name.toUpperCase()
                  color: Ink.boneInk
                  font.family: Type.mono
                  font.pixelSize: Type.row
                  font.underline: personHover.hovered
                  HoverHandler { id: personHover; cursorShape: Qt.PointingHandCursor }
                  TapHandler { onTapped: Qt.openUrlExternally(person.modelData.url) }
                }
                Text {
                  visible: person.index < P.PROOFREADERS.length - 1
                  text: "  ◆  "
                  color: Ink.boneInk
                  opacity: 0.5
                  font.family: Type.mono
                  font.pixelSize: Type.row
                }
              }
            }
          }
          Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "Every build is checked on a real Omarchy desk before it is called done. Found something? Open an issue on the repository."
            color: Ink.boneInk
            opacity: 0.7
            font.family: Type.text
            font.pixelSize: Type.note
          }
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.Wrap
        text: "Ryoku lent Hanko its grammar, not its look: one paper, four inks, hairlines, emphasis by inversion. Its palette, art and bars stay its own."
        color: Ink.inkFaint
        font.family: Type.text
        font.pixelSize: Type.note
        bottomPadding: Type.px(12)
      }
    }
  }
}
