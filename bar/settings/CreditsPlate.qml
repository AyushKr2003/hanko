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

  // Two layouts, and the scroll never hangs under the type: beside the
  // column when it has room there, else small beside the title, the page in
  // one column. The column scrolls when the window is short.
  readonly property real sideColumn: Math.min(Type.px(620), width * 0.58 - Type.px(56))
  readonly property real scrollRoom: width - Type.px(56) - sideColumn - Type.px(48) - Type.px(56)
  readonly property bool side: sideColumn >= Type.px(420) && scrollRoom >= Type.px(240)
  readonly property int margin: side ? Type.px(56) : width < Type.px(560) ? Type.px(20) : Type.px(32)
  readonly property real columnWidth: side ? sideColumn : width - 2 * margin
  // Stacked: the scroll's width beside the title, or none on a narrow page.
  readonly property real smallScroll: side || columnWidth < Type.px(420) ? 0 : Math.min(Type.px(150), columnWidth * 0.3)

  Rectangle { anchors.fill: parent; color: Ink.paper }

  HangingScroll {
    visible: root.side
    anchors.right: parent.right
    anchors.rightMargin: root.margin
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(parent.height * 0.62, root.scrollRoom)
    height: Math.min(parent.height, width / 0.62)
  }

  PlateSpine {
    visible: root.side && length <= root.height - 2 * Type.px(24)
    x: Type.px(22)
    anchors.verticalCenter: parent.verticalCenter
    text: "HANKO  ·  感謝 KANSHA  ·  WITH THANKS  ·  SET IN INK"
  }

  Flickable {
    id: flick
    width: root.side ? root.margin + root.columnWidth + Type.px(24) : parent.width
    height: parent.height
    contentHeight: column.height + 2 * root.margin
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: column
      x: root.margin
      y: root.margin
      width: root.columnWidth
      spacing: Type.px(24)

      Item {
        width: parent.width
        height: Math.max(heading.height, root.smallScroll / 0.62)
        HangingScroll {
          visible: root.smallScroll > 0
          x: parent.width - width
          width: root.smallScroll
          height: root.smallScroll / 0.62
        }
      Column {
        id: heading
        width: parent.width - (root.smallScroll > 0 ? root.smallScroll + Type.px(24) : 0)
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
