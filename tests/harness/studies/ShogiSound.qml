pragma ComponentBehavior: Bound
import QtQuick
import "../../../core"
import "../../../bar/sheets"

// Study: Shōgi 将棋, the board. Each level is a rank of nine squares and
// its piece stands on the square of its level (file 9 empty .. file 1
// full); click a square to move it there. The outputs stand on the piece
// stand (komadai) beside the board; the one playing is promoted, its
// character turned red. A muted app's piece is turned away.
Item {
  id: root
  property var sound: null
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var ranks: {
    var r = []
    if (master) r.push({ name: "Master", glyph: "音", level: master.level, figure: master.percent, muted: master.muted, lead: true })
    var s = sound ? sound.streams : []
    for (var i = 0; i < s.length && i < 3; i++) r.push({ name: s[i].label, glyph: "奏", level: s[i].level, figure: s[i].percent, muted: s[i].muted })
    return r
  }
  readonly property var numerals: ["一", "二", "三", "四", "五"]
  readonly property var files: ["９", "８", "７", "６", "５", "４", "３", "２", "１"]

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(16)
    spacing: 0

    SheetHead { sheet: "sound"; jp: "音"; label: "Sound · Pipewire"; compact: true }
    Item { width: 1; height: Type.px(16) }

    Row {
      spacing: Type.px(10)
      Text {
        text: root.master ? String(root.master.percent) : "—"
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(44)
        font.variableAxes: { "opsz": 72, "wght": 380 }
      }
      Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Type.px(8)
        spacing: Type.px(2)
        Text { text: "through Studio Monitors"; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(16); font.weight: Font.Normal; font.variableAxes: Type.axes(Type.px(16), 360) }
        Text { text: "MASTER ON THE FOURTH FILE"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
      }
    }
    Item { width: 1; height: Type.px(14) }

    // The board: file numbers over it, rank numerals down its right side.
    Item {
      id: board
      readonly property real nameW: Type.px(78)
      readonly property real cw: Type.px(30)
      readonly property real ch: Type.px(34)
      width: parent.width
      height: Type.px(16) + root.ranks.length * ch + Type.px(4)

      Repeater {
        model: root.files
        Text {
          required property int index
          required property string modelData
          x: board.nameW + index * board.cw
          width: board.cw
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.tag
        }
      }

      Rectangle {
        id: grid
        x: board.nameW
        y: Type.px(16)
        width: 9 * board.cw
        height: root.ranks.length * board.ch
        color: Ink.alpha(Ink.bone, 0.035)
        border.width: 1
        border.color: Ink.lineStrong
        Repeater {
          model: 8
          Rectangle { required property int index; x: (index + 1) * board.cw; width: 1; height: grid.height; color: Ink.line }
        }
        Repeater {
          model: root.ranks.length - 1
          Rectangle { required property int index; y: (index + 1) * board.ch; width: grid.width; height: 1; color: Ink.line }
        }
        // Hoshi: the four dots that mark the three-by-three camps.
        Repeater {
          model: root.ranks.length > 1 ? [[3, 1], [6, 1]] : []
          Rectangle {
            required property var modelData
            x: modelData[0] * board.cw - width / 2
            y: modelData[1] * board.ch - height / 2
            width: Type.px(5); height: width; radius: width / 2
            color: Ink.inkMuted
          }
        }
        // The squares: a click moves the piece there.
        Repeater {
          model: root.ranks
          Item {
            id: rank
            required property var modelData
            required property int index
            y: index * board.ch
            width: grid.width
            height: board.ch
            readonly property int at: Math.round(Math.max(0, Math.min(1, modelData.level)) * 8)
            // The squares the level has crossed: a faint wash.
            Rectangle {
              x: 1; y: 1
              width: (rank.at) * board.cw - 1
              height: board.ch - 1
              color: Ink.alpha(rank.modelData.lead ? Ink.seal : Ink.bone, rank.modelData.lead ? 0.10 : 0.05)
            }
            Koma {
              x: rank.at * board.cw + (board.cw - width) / 2
              y: (board.ch - height) / 2
              size: Type.px(25)
              glyph: rank.modelData.glyph
              promoted: !!rank.modelData.lead
              away: !!rank.modelData.muted
            }
          }
        }
      }

      // Names on the left, numerals and figures on the right.
      Repeater {
        model: root.ranks
        Item {
          required property var modelData
          required property int index
          y: grid.y + index * board.ch
          width: board.width
          height: board.ch
          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: board.nameW - Type.px(10)
            Text { width: parent.width; elide: Text.ElideRight; text: modelData.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.px(13) }
            Text { text: modelData.muted ? "MUTED" : modelData.figure + "%"; color: modelData.lead ? Ink.seal : Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
          }
          Text {
            x: grid.x + grid.width + Type.px(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.numerals[index]
            color: Ink.inkMuted
            font.family: Type.brush
            font.pixelSize: Type.px(13)
          }
        }
      }
    }

    Item { width: 1; height: Type.px(16) }

    // The piece stand: the outputs, waiting off the board.
    Row {
      spacing: Type.px(10)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "駒台"; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(13) }
      Text { anchors.verticalCenter: parent.verticalCenter; text: "OUTPUT · ON THE STAND"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
    }
    Item { width: 1; height: Type.px(8) }
    Item {
      width: parent.width
      height: Type.px(64)
      // The stand: a low tray on four feet.
      Rectangle {
        y: Type.px(38)
        x: board.nameW
        width: 9 * board.cw
        height: Type.px(5)
        color: Ink.alpha(Ink.bone, 0.10)
        border.width: 1
        border.color: Ink.lineStrong
        Repeater {
          model: [0.04, 0.96]
          Rectangle { required property real modelData; x: parent.width * modelData - width / 2; y: parent.height; width: Type.px(6); height: Type.px(4); color: Ink.lineStrong }
        }
      }
      Row {
        x: board.nameW + Type.px(14)
        spacing: Type.px(92)
        Repeater {
          model: root.sound ? root.sound.outputs : []
          Item {
            required property var modelData
            width: Type.px(34)
            height: Type.px(64)
            Koma {
              anchors.horizontalCenter: parent.horizontalCenter
              y: Type.px(38) - height
              size: Type.px(28)
              glyph: modelData.current ? "鳴" : "出"
              promoted: modelData.current
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              y: Type.px(48)
              text: modelData.label
              color: modelData.current ? Ink.ink : Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.px(11)
            }
          }
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.sound ? root.sound.input : ""
    SheetButton { text: "Mute" }
    SheetButton { ghost: true; text: "Mute mic" }
  }
}
