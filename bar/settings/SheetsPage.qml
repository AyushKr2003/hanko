pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Sheets.js" as Sheets
import "../sheets"

// Settings › Sheets 紙: which hand draws each cell's sheet. Three cards name
// the hands (Ledger 帳, Dial 盤, Prose 文); then one row per sheet with its
// choice, and "All sheets" to set them together. Beside the rows the sheet
// you last touched prints live in its hand, with the bar's own readings.
Item {
  id: root

  property var doc: S.normalize({})
  // The sheets' plain data (SheetWindow.feed's shape).
  property var feed: ({})
  property bool compact: false

  signal stylePicked(string sheet, string style)

  readonly property var styles: S.resolve(doc).sheetStyles
  property string focusSheet: "sound"
  readonly property var hands: [
    { key: "ledger", jp: "帳", name: "Ledger", short: "The editorial page: every choice listed", line: "The editorial page: a serif title, // groups and hairline rows. Everything listed, nothing hidden." },
    { key: "dial", jp: "盤", name: "Dial", short: "The instrument: a gauge and tiles", line: "The instrument: one gauge you turn as the hero, the choices as tiles. Read at a glance, set with a turn." },
    { key: "prose", jp: "文", name: "Prose", short: "The sentence: tap the underlined words", line: "The state written as a sentence; the underlined words are the controls. Reads like a note left for you." }
  ]
  readonly property var labels: ({ ledger: "帳 Ledger", dial: "盤 Dial", prose: "文 Prose" })
  readonly property string allStyle: {
    var first = styles[S.SHEET_KEYS[0]]
    for (var i = 1; i < S.SHEET_KEYS.length; i++) if (styles[S.SHEET_KEYS[i]] !== first) return ""
    return first
  }
  readonly property bool twoUp: width >= Type.px(900)
  readonly property real listWidth: twoUp ? width - preview.width - Type.px(40) : width

  width: parent ? parent.width : 0
  implicitHeight: body.y + Math.max(list.height, twoUp ? previewBox.height : 0) + (twoUp ? 0 : previewBox.height + Type.px(24))

  // The three hands.
  Row {
    id: cards
    y: Type.px(22)
    width: parent.width
    spacing: Type.px(12)
    Repeater {
      model: root.hands
      Rectangle {
        id: card
        required property var modelData
        width: (cards.width - 2 * cards.spacing) / 3
        height: Type.px(root.compact ? 96 : 104)
        radius: 3
        color: root.allStyle === card.modelData.key ? Ink.bone : cardHover.containsMouse ? Ink.alpha(Ink.bone, 0.05) : "transparent"
        border.width: 1
        border.color: root.allStyle === card.modelData.key ? Ink.bone : Ink.line
        readonly property color ink: root.allStyle === card.modelData.key ? Ink.boneInk : Ink.ink
        readonly property color soft: root.allStyle === card.modelData.key ? Ink.alpha(Ink.boneInk, 0.7) : Ink.inkMuted
        Row {
          x: Type.px(14)
          y: Type.px(12)
          spacing: Type.px(8)
          Text { text: card.modelData.jp; color: card.soft; font.family: Type.brush; font.pixelSize: Type.px(20) }
          Text {
            anchors.baseline: parent.children[0].baseline
            text: card.modelData.name
            color: card.ink
            font.family: Type.display
            font.pixelSize: Type.px(20)
            font.variableAxes: Type.axes(Type.px(20))
          }
        }
        Text {
          x: Type.px(14)
          y: Type.px(46)
          width: parent.width - 2 * x
          wrapMode: Text.Wrap
          maximumLineCount: 3
          elide: Text.ElideRight
          text: card.modelData.line
          color: card.soft
          font.family: Type.text
          font.pixelSize: Type.note
        }
        MouseArea {
          id: cardHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.stylePicked("all", card.modelData.key)
        }
      }
    }
  }

  Item {
    id: body
    y: cards.y + cards.height + Type.px(22)
    width: parent.width

    Column {
      id: list
      width: root.listWidth

      Row_ {
        jp: "全"
        name: "All sheets"
        line: root.allStyle ? "Every sheet in one hand" : "A mix: each sheet as set below"
        selected: root.allStyle
        onPicked: function(v) { root.stylePicked("all", v) }
      }
      Repeater {
        model: Sheets.SHEETS
        Row_ {
          required property var modelData
          jp: modelData.jp
          name: modelData.label.charAt(0) + modelData.label.slice(1).toLowerCase()
          line: root.hands[Math.max(0, S.SHEET_STYLES.indexOf(root.styles[modelData.key]))].short
          selected: root.styles[modelData.key] || "ledger"
          focused: root.focusSheet === modelData.key
          onPicked: function(v) { root.focusSheet = modelData.key; root.stylePicked(modelData.key, v) }
          onTouched: root.focusSheet = modelData.key
        }
      }
    }

    // The sheet last touched, printed live in its hand.
    Item {
      id: previewBox
      x: root.twoUp ? root.width - preview.width : 0
      y: root.twoUp ? 0 : list.height + Type.px(24)
      width: preview.width
      height: previewLabel.height + Type.px(10) + preview.height
      Text {
        id: previewLabel
        text: ("Preview · " + root.focusSheet + " · " + (root.labels[root.styles[root.focusSheet]] || "")).toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackEyebrow
      }
      SheetView {
        id: preview
        y: previewLabel.height + Type.px(10)
        sheet: root.focusSheet
        styles: root.styles
        feed: root.feed
        animate: false
        tearX: Type.px(30)
        tearWidth: Type.px(80)
      }
    }
  }

  // One sheet's row: its kanji and name, what its hand is, the choice.
  component Row_: Item {
    id: row
    property string jp: ""
    property string name: ""
    property string line: ""
    property string selected: ""
    property bool focused: false
    signal picked(string value)
    signal touched()
    width: parent ? parent.width : 0
    height: Type.px(54)
    Rectangle {
      anchors.fill: parent
      color: row.focused ? Ink.alpha(Ink.bone, 0.05) : "transparent"
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.lineSoft }
    Rectangle { visible: row.focused; width: 2; height: parent.height - Type.px(16); anchors.verticalCenter: parent.verticalCenter; color: Ink.ink }
    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: row.touched(); onClicked: row.touched() }
    Text {
      x: Type.px(12)
      anchors.verticalCenter: parent.verticalCenter
      width: Type.px(26)
      text: row.jp
      color: Ink.inkMuted
      font.family: Type.brush
      font.pixelSize: Type.px(18)
    }
    Column {
      x: Type.px(46)
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - x - seg.width - Type.px(20)
      spacing: Type.px(2)
      Text { text: row.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row }
      Text { width: parent.width; elide: Text.ElideRight; text: row.line; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
    }
    Segmented {
      id: seg
      anchors.right: parent.right
      anchors.rightMargin: Type.px(8)
      anchors.verticalCenter: parent.verticalCenter
      options: S.SHEET_STYLES
      labels: root.labels
      selected: row.selected
      onPicked: function(v) { row.picked(v) }
    }
  }
}
