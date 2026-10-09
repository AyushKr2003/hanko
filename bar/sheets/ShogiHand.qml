pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Hands.js" as Hands

// Shōgi 将棋, the board. Every level is a rank of nine squares and its
// piece (koma) stands on the square of its level, file ９ empty to file １
// full; the squares it has crossed are washed faintly, red for the sheet's
// own reading. A click on a square moves a piece you can set (the wheel
// steps it a file); a click on any other rank does what its row does
// (join a network, connect a device). File numbers run over the board and
// rank numerals down its side, with the hoshi dots, as on a real board.
// Choices wait on the piece stand (komadai) under it: the one in play is
// promoted, its character written red as a promoted piece's reverse is;
// a muted app's piece is turned away, as the other side's pieces point.
HandSheet {
  id: root
  setHint: "Click a square to move a piece"

  readonly property var ranks: Hands.ranks(model).slice(0, 6)
  readonly property var numerals: ["一", "二", "三", "四", "五", "六"]
  readonly property var files: ["９", "８", "７", "６", "５", "４", "３", "２", "１"]
  readonly property var ordinals: ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth"]
  function fileOf(level) { return Math.round(Math.max(0, Math.min(1, level)) * 8) }

  FigureHero {
    hero: root.hero
    caption: root.hero.rank && root.hero.level >= 0
      ? root.hero.name + " on the " + root.ordinals[9 - root.fileOf(root.hero.level)] + " file"
      : root.hero.caption
  }
  Item { width: 1; height: Type.px(14); visible: root.ranks.length > 0 }

  // The board: file numbers over it, rank numerals down its right side.
  Item {
    id: board
    visible: root.ranks.length > 0
    readonly property real nameW: Type.px(88)
    readonly property real cw: Math.min(Type.px(34), (width - nameW - Type.px(26)) / 9)
    readonly property real ch: Type.px(34)
    width: root.inner
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
        model: Math.max(0, root.ranks.length - 1)
        Rectangle { required property int index; y: (index + 1) * board.ch; width: grid.width; height: 1; color: Ink.line }
      }
      // Hoshi: the dots that mark the three-by-three camps.
      Repeater {
        model: {
          var r = []
          for (var y = 1; y < root.ranks.length; y += 3) r.push([3, y], [6, y])
          return r
        }
        Rectangle {
          required property var modelData
          x: modelData[0] * board.cw - width / 2
          y: modelData[1] * board.ch - height / 2
          width: Type.px(5); height: width; radius: width / 2
          color: Ink.inkMuted
        }
      }
      Repeater {
        model: root.ranks
        Item {
          id: rank
          required property var modelData
          required property int index
          readonly property var r: modelData
          readonly property int at: root.fileOf(r.level)
          readonly property bool red: (r.lead && !r.muted) || r.urgent
          y: index * board.ch
          width: grid.width
          height: board.ch

          // The squares the level has crossed: a faint wash.
          Rectangle {
            x: 1; y: 1
            width: Math.max(0, rank.at * board.cw - 1)
            height: board.ch - 1
            color: Ink.alpha(rank.red ? Ink.seal : Ink.bone, rank.red ? 0.10 : rank.r.selected ? 0.09 : 0.05)
          }
          // The square under the pointer, where a click would move the piece.
          Rectangle {
            visible: squares.containsMouse && (!!rank.r.set || !!rank.r.click)
            x: (rank.r.set ? Math.floor(squares.mouseX / board.cw) : rank.at) * board.cw + 1
            y: 1
            width: board.cw - 1
            height: board.ch - 1
            color: "transparent"
            border.width: 1
            border.color: Ink.inkMuted
          }
          Koma {
            x: rank.at * board.cw + (board.cw - width) / 2
            y: (board.ch - height) / 2
            size: Type.px(25)
            glyph: rank.r.mark
            promoted: rank.r.lead || rank.r.selected || rank.r.urgent
            away: rank.r.muted
            faint: rank.r.dashed && !rank.r.muted
            lifted: squares.containsMouse
            Behavior on x {
              enabled: Motion.live
              NumberAnimation { duration: Motion.ms(160); easing.type: Easing.OutCubic }
            }
          }
          MouseArea {
            id: squares
            anchors.fill: parent
            hoverEnabled: true
            enabled: !!rank.r.set || !!rank.r.click
            cursorShape: Qt.PointingHandCursor
            onClicked: function(m) {
              if (rank.r.set) root.pick(rank.r, Math.max(0, Math.min(8, Math.floor(m.x / board.cw))) / 8)
              else root.act(rank.r.click)
            }
            onWheel: function(w) {
              if (!rank.r.set) return
              root.pick(rank.r, Math.max(0, Math.min(8, rank.at + (w.angleDelta.y > 0 ? 1 : -1))) / 8)
            }
          }
        }
      }
    }

    // Names on the left, numerals on the right.
    Repeater {
      model: root.ranks
      Item {
        id: side
        required property var modelData
        required property int index
        y: grid.y + index * board.ch
        width: board.width
        height: board.ch
        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: board.nameW - Type.px(10)
          Text {
            width: parent.width
            elide: Text.ElideRight
            text: side.modelData.name
            color: side.modelData.selected || side.modelData.lead ? Ink.ink : Ink.inkDim
            font.family: Type.text
            font.pixelSize: Type.px(13)
          }
          Text {
            width: parent.width
            elide: Text.ElideRight
            text: (side.modelData.muted ? "muted" : side.modelData.figure).toUpperCase()
            color: side.modelData.urgent || (side.modelData.lead && !side.modelData.muted) ? Ink.seal : Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackTag
          }
        }
        Text {
          x: grid.x + grid.width + Type.px(8)
          anchors.verticalCenter: parent.verticalCenter
          text: root.numerals[side.index]
          color: Ink.inkMuted
          font.family: Type.brush
          font.pixelSize: Type.px(13)
        }
      }
    }
  }

  // The piece stand: the choices, waiting off the board.
  Item { width: 1; height: Type.px(16); visible: root.model.choices.length > 0 }
  Row {
    visible: root.model.choices.length > 0
    spacing: Type.px(10)
    Text { anchors.verticalCenter: parent.verticalCenter; text: "駒台"; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(13) }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: (root.model.choicesLabel + " · on the stand").toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }
  Item { width: 1; height: Type.px(8); visible: root.model.choices.length > 0 }
  Item {
    id: stand
    visible: root.model.choices.length > 0
    readonly property int n: root.model.choices.length
    readonly property real span: root.inner - board.nameW / 2
    readonly property real slot: span / Math.max(1, n)
    readonly property real piece: Type.px(root.model.inline ? 26 : 28)
    width: root.inner
    height: piece * 1.12 + Type.px(root.model.inline ? 34 : 30)

    // The stand: a low tray on two feet.
    Rectangle {
      x: board.nameW / 4
      y: stand.piece * 1.12 + Type.px(2)
      width: stand.span
      height: Type.px(5)
      color: Ink.alpha(Ink.bone, 0.10)
      border.width: 1
      border.color: Ink.lineStrong
      Repeater {
        model: [0.03, 0.97]
        Rectangle { required property real modelData; x: parent.width * modelData - width / 2; y: parent.height; width: Type.px(6); height: Type.px(4); color: Ink.lineStrong }
      }
    }
    Repeater {
      model: root.model.choices
      Item {
        id: held
        required property var modelData
        required property int index
        x: board.nameW / 4 + index * stand.slot
        width: stand.slot
        height: stand.height
        Koma {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Type.px(2)
          size: stand.piece
          glyph: held.modelData.mark
          promoted: held.modelData.selected || held.modelData.urgent
          faint: held.modelData.dashed
          lifted: pick.containsMouse && !!held.modelData.click
        }
        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          y: stand.piece * 1.12 + Type.px(12)
          width: parent.width - Type.px(6)
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.model.inline ? held.modelData.detail + " " + held.modelData.name : held.modelData.name
            color: held.modelData.selected ? Ink.ink : Ink.inkMuted
            font.family: root.model.inline ? Type.mono : Type.text
            font.pixelSize: root.model.inline ? Type.tag : Type.px(11)
            font.letterSpacing: root.model.inline ? Type.trackTag : 0
          }
        }
        MouseArea {
          id: pick
          anchors.fill: parent
          hoverEnabled: true
          enabled: !!held.modelData.click
          cursorShape: Qt.PointingHandCursor
          onClicked: root.act(held.modelData.click)
        }
      }
    }
  }
}
