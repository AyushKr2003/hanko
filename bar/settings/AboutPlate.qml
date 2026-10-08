pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Profile.js" as P
import "../../core/InkMath.js" as InkMath

// About 由来: what Hanko is and where it came from. A whole dithered moon
// rises on the right; the left column carries the bilingual title, a
// Fraunces deck, how it is put together as editorial lines, the three
// directions it was drawn in, and a colophon that sets each face in
// itself and prints the inks you are set in with their measured contrast.
Item {
  id: root

  property string version: ""
  property string settingCount: String(S.KEYS.length)

  // Two layouts, and the moon never sits under the type: beside the column
  // when it has room there, else small beside the title, the page in one
  // column. The column scrolls when the window is short.
  readonly property real sideColumn: Math.min(Type.px(600), width * 0.56 - Type.px(56))
  readonly property real moonRoom: width - Type.px(56) - sideColumn - Type.px(48)
  readonly property bool side: sideColumn >= Type.px(420) && moonRoom >= Type.px(260)
  readonly property int margin: side ? Type.px(56) : width < Type.px(560) ? Type.px(20) : Type.px(32)
  readonly property real columnWidth: side ? sideColumn : width - 2 * margin
  // Stacked: the moon's square beside the title, or none on a narrow page.
  readonly property real smallMoon: side || columnWidth < Type.px(420) ? 0 : Math.min(Type.px(220), columnWidth * 0.36)

  function hex(c) {
    function o(v) { var s = Math.round(v * 255).toString(16); return s.length < 2 ? "0" + s : s }
    return "#" + o(c.r) + o(c.g) + o(c.b)
  }
  readonly property var ramp: [
    { label: "INK", swatch: Ink.ink }, { label: "DIM", swatch: Ink.inkDim },
    { label: "MUTED", swatch: Ink.inkMuted }, { label: "FAINT", swatch: Ink.inkFaint },
    { label: "SEAL", swatch: Ink.seal }
  ]

  Rectangle { anchors.fill: parent; color: Ink.paper }

  // The moon in its own room right of the column, whole.
  Plate {
    visible: root.side
    x: root.width - width
    width: root.moonRoom
    height: parent.height
    cxw: 0.5
    cyh: 0.46
    rh: Math.min(0.34, 0.44 * width / Math.max(1, height))
  }

  PlateSpine {
    visible: root.side && length <= root.height - 2 * Type.px(24)
    x: Type.px(22)
    anchors.verticalCenter: parent.verticalCenter
    text: "HANKO  ·  判子 ABOUT  ·  HANKO.BAR " + root.version + "  ·  SET IN INK"
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
      spacing: Type.px(36)

      Item {
        width: parent.width
        height: Math.max(heading.height, root.smallMoon)
        Plate {
          visible: root.smallMoon > 0
          x: parent.width - width
          width: root.smallMoon
          height: root.smallMoon
          cxw: 0.5
          cyh: 0.5
          rh: 0.46
        }
      Column {
        id: heading
        width: parent.width - (root.smallMoon > 0 ? root.smallMoon + Type.px(24) : 0)
        spacing: Type.px(16)
        PlateEyebrow { jp: "由来"; label: "About" }
        Column {
          Text { text: "判子"; color: Ink.ink; font.family: Type.jpSerif; font.pixelSize: Type.px(64); font.weight: Font.Medium }
          Text {
            text: "Hanko"
            color: Ink.ink
            font.family: Type.display
            font.pixelSize: Type.px(44)
            font.variableAxes: Type.axes(Type.px(44))
          }
        }
        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: "A bar for Omarchy, set like a page. Every part of it is a setting, every panel is paper, and the only red is the seal you press."
          color: Ink.inkMuted
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.px(17)
          font.variableAxes: Type.axes(Type.px(17))
        }
      }
      }

      // How it is put together.
      Column {
        width: parent.width
        Repeater {
          model: P.facts(root.version, S.combinations(), root.settingCount, S.PRESET_NAMES.length)
          LeaderRow {
            required property var modelData
            width: column.width
            kind: "credit"
            name: modelData[0]
            value: modelData[1]
            url: modelData[2]
          }
        }
      }

      // The three directions it was drawn in.
      Column {
        width: parent.width
        spacing: Type.px(10)
        Text {
          text: "DRAWN THREE WAYS, BUILT AS ONE"
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackEyebrow
        }
        Repeater {
          model: P.LINEAGE
          Row {
            id: line
            required property var modelData
            required property int index
            spacing: Type.px(14)
            Text {
              width: Type.px(26)
              text: "0" + (line.index + 1)
              color: Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.note
            }
            Text {
              width: Type.px(40)
              text: line.modelData.jp
              color: Ink.seal
              font.family: Type.jp
              font.pixelSize: Type.note
            }
            Text {
              id: lineName
              width: Type.px(80)
              text: line.modelData.name
              color: Ink.ink
              font.family: Type.display
              font.pixelSize: Type.px(18)
              font.variableAxes: Type.axes(Type.px(18))
            }
            Text {
              width: column.width - Type.px(26 + 40 + 80 + 42)
              anchors.baseline: lineName.baseline
              elide: Text.ElideRight
              text: line.modelData.line
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
          }
        }
      }

      // Colophon: each face set in itself, then the inks.
      Column {
        width: parent.width
        spacing: Type.px(12)
        Text {
          text: "COLOPHON"
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackEyebrow
        }
        Text { text: "Fraunces 44"; color: Ink.ink; font.family: Type.display; font.pixelSize: Type.px(44); font.variableAxes: Type.axes(Type.px(44)) }
        Text { text: "Space Grotesk 14"; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(14) }
        Text { width: parent.width; elide: Text.ElideRight; text: Type.mono + " 12  ·  your Omarchy font"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.px(12) }
        Text { text: "Noto Serif CJK 判子 印影 由来 謝辞"; color: Ink.inkMuted; font.family: Type.jpSerif; font.pixelSize: Type.px(14) }

        Flow {
          width: parent.width
          spacing: Type.px(18)
          topPadding: Type.px(6)
          Repeater {
            model: root.ramp
            Column {
              id: chip
              required property var modelData
              spacing: Type.px(3)
              Rectangle { width: Type.px(56); height: Type.px(26); radius: 3; color: chip.modelData.swatch }
              Text { text: chip.modelData.label; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
              Text { text: root.hex(chip.modelData.swatch); color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.tag }
              Text {
                text: InkMath.contrast(root.hex(chip.modelData.swatch), root.hex(Ink.paper)).toFixed(1) + " : 1"
                color: Ink.inkFaint
                font.family: Type.mono
                font.pixelSize: Type.tag
              }
            }
          }
        }

        Text {
          width: parent.width
          wrapMode: Text.Wrap
          topPadding: Type.px(6)
          text: "Every plate here is drawn in code from your theme; no images ship with Hanko. Made by AyushKr2003, written with Claude Code. Original work in Ryoku's grammar, not a copy of any bar."
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.note
        }
      }
    }
  }
}
