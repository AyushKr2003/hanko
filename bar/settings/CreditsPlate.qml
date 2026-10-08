pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Profile.js" as P

// Credits 謝辞, the thanks plate. A hanging scroll dissolves off the right;
// the left column carries the bilingual title, a Fraunces deck, everything
// Hanko stands on as editorial lines set under three heads (Foundation 礎,
// Lineage 系譜, Type 活字; a linked line inverts under the pointer and opens
// its home), and a ruled card stamped 校 for the people who test every
// build on real machines.
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
        // The kanji and its English on one line, as a title and its reading.
        Row {
          spacing: Type.px(18)
          Text { id: titleJp; text: "感謝"; color: Ink.ink; font.family: Type.jpSerif; font.pixelSize: Type.px(64); font.weight: Font.Medium }
          Text {
            anchors.baseline: titleJp.baseline
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

      // Everything it stands on, under three heads.
      Repeater {
        model: P.CREDIT_GROUPS
        Column {
          id: group
          required property var modelData
          width: column.width
          spacing: Type.px(6)
          SectionLabel { jp: group.modelData.jp; text: group.modelData.label }
          Column {
            width: parent.width
            Repeater {
              model: P.creditsIn(group.modelData.key)
              LeaderRow {
                required property var modelData
                width: column.width
                height: Type.px(29)
                kind: "credit"
                name: modelData.name
                by: modelData.by
                value: modelData.role
                url: modelData.url
              }
            }
          }
        }
      }

      // The proofreaders: a ruled card, stamped 校 (to check) in the corner.
      Rectangle {
        width: parent.width
        height: crew.height + 2 * Type.px(20)
        radius: 3
        color: Ink.alpha(Ink.bone, Ink.light ? 0.04 : 0.03)
        border.width: 1
        border.color: Ink.line
        Rectangle {
          id: stamp
          x: Type.px(20)
          y: Type.px(20)
          width: Type.px(40)
          height: width
          radius: 3
          rotation: -4
          color: "transparent"
          border.width: 2
          border.color: Ink.seal
          Text {
            anchors.centerIn: parent
            text: "校"
            color: Ink.seal
            font.family: Type.jpSerif
            font.weight: Font.Bold
            font.pixelSize: Type.px(22)
          }
        }
        Column {
          id: crew
          x: stamp.x + stamp.width + Type.px(20)
          y: Type.px(20)
          width: parent.width - x - Type.px(20)
          spacing: Type.px(8)
          Text {
            text: "THE PROOFREADERS  ·  校正"
            color: Ink.inkMuted
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
                  text: person.modelData.name
                  color: Ink.ink
                  font.family: Type.display
                  font.pixelSize: Type.px(22)
                  font.variableAxes: Type.axes(Type.px(22))
                  font.underline: personHover.hovered
                  HoverHandler { id: personHover; cursorShape: Qt.PointingHandCursor }
                  TapHandler { onTapped: Qt.openUrlExternally(person.modelData.url) }
                }
                Text {
                  visible: person.index < P.PROOFREADERS.length - 1
                  text: "  ·  "
                  color: Ink.inkFaint
                  font.family: Type.display
                  font.pixelSize: Type.px(22)
                }
              }
            }
          }
          Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "Every build is checked on a real Omarchy desk before it is called done. Found something? Open an issue on the repository."
            color: Ink.inkDim
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
