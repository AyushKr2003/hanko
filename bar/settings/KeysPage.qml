pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Settings.js" as Settings

// Settings › Keys 鍵 (docs/settings-kosei): a keyboard drawn in keycaps.
// Pick where you are (settings, a sheet, the scroll, the overview) and the
// keys Hanko answers to there are inked; hover a key to read what it does.
// The same keys follow as a list, then the Hyprland bindings for what Hanko
// has no key of its own for, each with a Copy.
Column {
  id: root

  property bool compact: false
  property string context: "sheet"

  signal copyText(string text)

  readonly property var ctx: {
    for (var i = 0; i < Settings.KEYMAP.length; i++) if (Settings.KEYMAP[i].key === context) return Settings.KEYMAP[i]
    return Settings.KEYMAP[0]
  }
  readonly property var lit: Settings.keysLit(ctx)
  property string pointed: ""

  // A compact board: [label, width in units].
  readonly property var board: [
    [["Esc", 1.25], ["1", 1], ["2", 1], ["3", 1], ["4", 1], ["5", 1], ["6", 1], ["7", 1], ["8", 1], ["9", 1], ["0", 1], ["Bksp", 1.75]],
    [["Tab", 1.5], ["Q", 1], ["W", 1], ["E", 1], ["R", 1], ["T", 1], ["Y", 1], ["U", 1], ["I", 1], ["O", 1], ["P", 1], ["/", 1.5]],
    [["Ctrl", 1.75], ["A", 1], ["S", 1], ["D", 1], ["F", 1], ["G", 1], ["H", 1], ["J", 1], ["K", 1], ["L", 1], ["Enter", 2.25]],
    [["Shift", 2.25], ["Z", 1], ["X", 1], ["C", 1], ["V", 1], ["B", 1], ["N", 1], ["M", 1], ["", 1], ["↑", 1], ["", 1.75]],
    [["Super", 1.5], ["Alt", 1.25], ["Space", 6.25], ["←", 1], ["↓", 1], ["→", 1], ["", 1]]
  ]
  readonly property real unit: Math.min(Type.px(56), (width - Type.px(40)) / 13)

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  // ------------------------------------------------------------ where you are
  Row {
    spacing: Type.px(6)
    Repeater {
      model: Settings.KEYMAP
      Rectangle {
        id: tab
        required property var modelData
        readonly property bool open: modelData.key === root.ctx.key
        width: tabRow.width + Type.px(24)
        height: Type.px(34)
        radius: 3
        color: open ? Ink.bone : tabHover.containsMouse ? Ink.lineSoft : "transparent"
        border.width: 1
        border.color: open ? Ink.bone : Ink.line
        Row {
          id: tabRow
          anchors.centerIn: parent
          spacing: Type.px(8)
          Text { anchors.verticalCenter: parent.verticalCenter; text: tab.modelData.jp; color: tab.open ? Ink.boneInk : Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(13) }
          Text { anchors.verticalCenter: parent.verticalCenter; text: tab.modelData.name; color: tab.open ? Ink.boneInk : Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(13) }
        }
        MouseArea {
          id: tabHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.context = tab.modelData.key
        }
      }
    }
  }

  Item { width: 1; height: Type.px(16) }

  // ------------------------------------------------------------ the board
  Rectangle {
    width: parent.width
    height: boardColumn.height + Type.px(40) + said.height + Type.px(10)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.line

    Column {
      id: boardColumn
      x: (parent.width - width) / 2
      y: Type.px(20)
      spacing: Type.px(5)
      Repeater {
        model: root.board
        Row {
          id: boardRow
          required property var modelData
          spacing: Type.px(5)
          Repeater {
            model: boardRow.modelData
            Rectangle {
              id: cap
              required property var modelData
              readonly property string label: modelData[0]
              readonly property bool on: label !== "" && !!root.lit[label]
              width: root.unit * modelData[1] + Type.px(5) * (modelData[1] - 1)
              height: root.unit * 0.86
              radius: 4
              visible: true
              opacity: label === "" ? 0 : 1
              color: on ? (capHover.containsMouse ? Ink.ink : Ink.bone) : "transparent"
              border.width: 1
              border.color: on ? Ink.bone : capHover.containsMouse ? Ink.lineStrong : Ink.line
              // A keycap's lip.
              Rectangle {
                visible: !cap.on
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                x: 3
                width: parent.width - 6
                height: 1
                color: Ink.lineSoft
              }
              Text {
                x: Type.px(7)
                y: Type.px(5)
                text: cap.label
                color: cap.on ? Ink.boneInk : Ink.inkFaint
                font.family: cap.label.length > 1 && !/[←→↑↓]/.test(cap.label) ? Type.mono : Type.text
                font.pixelSize: cap.label.length > 1 && !/[←→↑↓]/.test(cap.label) ? Type.tag : Type.px(13)
                font.letterSpacing: cap.label.length > 1 ? 1 : 0
              }
              MouseArea {
                id: capHover
                anchors.fill: parent
                hoverEnabled: cap.label !== ""
                onContainsMouseChanged: root.pointed = containsMouse ? cap.label : (root.pointed === cap.label ? "" : root.pointed)
              }
            }
          }
        }
      }
    }
    // What the pointed key does here.
    Text {
      id: said
      anchors.horizontalCenter: parent.horizontalCenter
      y: boardColumn.y + boardColumn.height + Type.px(16)
      text: {
        if (root.pointed === "") return "POINT AT AN INKED KEY"
        var does = Settings.keyDoes(root.ctx, root.pointed)
        return does ? root.pointed + "  ·  " + does : root.pointed + "  ·  nothing, " + root.ctx.name.toLowerCase()
      }
      color: root.pointed !== "" && Settings.keyDoes(root.ctx, root.pointed) ? Ink.ink : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(11)
      font.letterSpacing: 1
    }
  }

  Item { width: 1; height: Type.px(24) }

  // ------------------------------------------------------------ as a list
  SectionLabel { jp: root.ctx.jp; text: root.ctx.name + " · " + root.ctx.keys.length + " keys" }
  Item { width: 1; height: Type.px(4) }
  Grid {
    id: list
    width: parent.width
    columns: width >= Type.px(760) ? 2 : 1
    columnSpacing: Type.px(28)
    readonly property real cellWidth: (width - (columns - 1) * columnSpacing) / columns
    Repeater {
      model: root.ctx.keys
      Item {
        id: entry
        required property var modelData
        width: list.cellWidth
        height: Type.px(38)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.lineSoft }
        Row {
          id: caps
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(4)
          Repeater {
            model: entry.modelData.caps
            KeyCap { required property string modelData; label: modelData }
          }
        }
        Text {
          x: Type.px(150)
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - x
          elide: Text.ElideRight
          text: entry.modelData.what
          color: Ink.inkDim
          font.family: Type.text
          font.pixelSize: Type.px(13)
        }
      }
    }
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------- your own bindings
  SectionLabel { jp: "綴"; text: "Bindings of your own · for ~/.config/hypr/bindings.lua" }
  Item { width: 1; height: Type.px(8) }
  Repeater {
    model: Settings.BINDINGS
    Item {
      id: bind
      required property var modelData
      required property int index
      width: root.width
      height: code.height + Type.px(28)
      Rectangle { visible: bind.index > 0; width: parent.width; height: 1; color: Ink.lineSoft }
      Column {
        y: Type.px(14)
        width: Type.px(260)
        spacing: Type.px(6)
        Text { text: bind.modelData.what; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row }
        Row {
          spacing: Type.px(4)
          Repeater { model: bind.modelData.caps; KeyCap { required property string modelData; label: modelData } }
        }
      }
      Text {
        id: code
        x: Type.px(280)
        y: Type.px(14)
        width: parent.width - x - copy.width - Type.px(16)
        wrapMode: Text.WrapAnywhere
        text: bind.modelData.code
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.px(11)
      }
      SmallButton {
        id: copy
        anchors.right: parent.right
        y: Type.px(12)
        label: "Copy"
        onClicked: root.copyText(bind.modelData.code)
      }
    }
  }

  component KeyCap: Rectangle {
    id: kc
    property string label: ""
    width: Math.max(Type.px(24), capText.implicitWidth + Type.px(12))
    height: Type.px(22)
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.lineStrong
    Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 2; x: 3; width: parent.width - 6; height: 1; color: Ink.lineSoft }
    Text {
      id: capText
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -1
      text: kc.label
      color: Ink.ink
      font.family: kc.label.length > 1 && !/[←→↑↓–]/.test(kc.label) ? Type.mono : Type.text
      font.pixelSize: kc.label.length > 1 && !/[←→↑↓–]/.test(kc.label) ? Type.tag : Type.px(12)
      font.letterSpacing: kc.label.length > 1 ? 1 : 0
    }
  }
}
