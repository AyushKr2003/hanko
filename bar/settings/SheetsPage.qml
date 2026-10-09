pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Sheets.js" as Sheets
import "../../core/Skin.js" as Sk
import "../sheets"
import "../parts" as Parts

// Settings › Sheets 紙: which hand draws each cell's sheet. Cards name
// the six hands (Ledger 帳, Tanzaku 短冊, Shōgi 将棋, Soroban 算盤,
// Odoshi 縅, Kasumi 霞, Shōji 障子; a click sets every sheet), three to
// a row; then one row per sheet: its name, what its hand is, and under
// them the choice. Beside the rows the sheet you last touched prints live
// in its hand, in a room as wide as the widest sheet.
Item {
  id: root

  property var doc: S.normalize({})
  // The sheets' plain data (SheetWindow.feed's shape).
  property var feed: ({})
  property bool compact: false

  signal stylePicked(string sheet, string style)
  // Panel opacity: a percent (30..100) as text, or "auto" for each hand's own.
  signal opacityPicked(string value)

  readonly property var styles: S.resolve(doc).sheetStyles
  property string focusSheet: "sound"
  readonly property var hands: [
    { key: "ledger", jp: "帳", name: "Ledger", short: "The editorial page: every choice listed", line: "The editorial page: a serif title, // groups and hairline rows. Everything listed, nothing hidden." },
    { key: "tanzaku", jp: "短冊", name: "Tanzaku", short: "The poem slips: each choice a hanging strip", line: "Each choice a paper slip hung from a rail, right to left, as long as its level; the one in use inked and sealed." },
    { key: "shogi", jp: "将棋", name: "Shōgi", short: "The board: each level a piece on its square", line: "Each level a rank of nine squares, its piece on the square of its level; choices wait on the piece stand, the one in play promoted red." },
    { key: "soroban", jp: "算盤", name: "Soroban", short: "The abacus: readings counted in beads", line: "The figures counted out in beads pushed to the beam, the sheet's own in red; each choice one bead, slid across for the one in use." },
    { key: "odoshi", jp: "縅", name: "Odoshi", short: "Armour lacing: each level a laced lame", line: "A crown plate, then a lame of small scales for each level, laced as far as it goes; the one in use laced in full and knotted red." },
    { key: "kasumi", jp: "霞", name: "Kasumi", short: "Mist bands: each level a band of gold leaf", line: "Each level a band of gold-leaf mist drawn as far as it goes, drifting in from alternate sides; the one in use gilded whole and sealed." },
    { key: "shoji", jp: "障子", name: "Shōji", short: "Washi panels that slide along a rail", line: "One washi panel on a rail under the bar, sliding to the cell you pick; its name down the right edge, brush sliders and the ensō." },
  ]
  readonly property var labels: ({ ledger: "Ledger", tanzaku: "Tanzaku", shogi: "Shōgi", soroban: "Soroban", odoshi: "Odoshi", kasumi: "Kasumi", shoji: "Shōji" })
  // Shōji's panels are drawn in Shōji's skin, with your touches and opacity.
  readonly property var skin: Sk.fromStyle(S.resolve(doc))
  readonly property int panelOpacity: S.resolve(doc).panelOpacity || 0
  // Auto: each hand's own paper (solid, or Shōji's washi at 86%); the
  // slider and figure read 100% then.
  readonly property real paperOpacity: panelOpacity > 0 ? panelOpacity / 100 : 1
  readonly property string allStyle: {
    var first = styles[S.SHEET_KEYS[0]]
    for (var i = 1; i < S.SHEET_KEYS.length; i++) if (styles[S.SHEET_KEYS[i]] !== first) return ""
    return first
  }
  readonly property bool twoUp: width >= Type.px(900)
  // The preview's room is fixed to the widest sheet, so pointing at another
  // row never resizes the list or shifts its choices.
  readonly property real previewRoom: Type.px(Math.max.apply(null, Sheets.SHEETS.map(function(x) { return x.width })))
  readonly property real listWidth: twoUp ? width - previewRoom - Type.px(40) : width

  width: parent ? parent.width : 0
  implicitHeight: body.y + Math.max(list.height, twoUp ? previewBox.height : 0) + (twoUp ? 0 : previewBox.height + Type.px(24))

  // The six hands, three to a row (two when narrow).
  Grid {
    id: cards
    y: Type.px(22)
    width: parent.width
    columns: root.width >= Type.px(720) ? 3 : 2
    spacing: Type.px(12)
    Repeater {
      model: root.hands
      Rectangle {
        id: card
        required property var modelData
        width: (cards.width - (cards.columns - 1) * cards.spacing) / cards.columns
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

  // Panel opacity 透け: how much of the desk shows through every panel
  // (sheets in any hand, the scroll, the framed overview), with Shōji's
  // brush slider. It was on Settings › Design, which went with the design.
  Item {
    id: opacityRow
    y: cards.y + cards.height + Type.px(18)
    width: root.width
    height: opacityLabel.implicitHeight + Type.px(14) + (root.compact ? opacityControls.height + Type.px(10) : 0)
    Rectangle { width: parent.width; height: 1; color: Ink.line }
    Column {
      id: opacityLabel
      y: Type.px(12)
      width: root.compact ? parent.width : parent.width - opacityControls.width - Type.px(24)
      spacing: Type.px(2)
      Text { text: "Panel opacity"; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row; font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
      Text {
        width: parent.width; wrapMode: Text.Wrap
        text: "How much of your desk shows through every panel: sheets in any hand, the scroll and the framed overview. Auto keeps each one's own paper (solid, or Shōji's washi at 86%)."
        color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note
      }
    }
    Row {
      id: opacityControls
      x: root.compact ? 0 : parent.width - width
      y: root.compact ? opacityLabel.y + opacityLabel.implicitHeight + Type.px(10) : Type.px(12)
      spacing: Type.px(14)
      Parts.KataSlider {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(240); height: Type.px(26)
        skin: root.skin
        // 30..100 drawn across the whole ruler
        value: (Math.round(root.paperOpacity * 100) - 30) / 70 * 100
        onMoved: function(v) { root.opacityPicked(String(Math.round(30 + v / 100 * 70))) }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(56)
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.paperOpacity * 100) + "%"
        color: Ink.ink
        font.family: Type.display; font.pixelSize: Type.px(22); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(22), 360)
        font.features: { "tnum": 1, "lnum": 1 }
      }
      Rectangle {
        id: autoButton
        readonly property bool faint: root.panelOpacity === 0
        anchors.verticalCenter: parent.verticalCenter
        width: autoText.implicitWidth + 2 * Type.px(14)
        height: Type.px(32)
        radius: 3
        color: autoHover.containsMouse && !faint ? Ink.lineSoft : "transparent"
        border.width: 1
        border.color: faint ? Ink.line : Ink.lineStrong
        Text {
          id: autoText
          anchors.centerIn: parent
          text: "AUTO"
          color: autoButton.faint ? Ink.inkFaint : Ink.ink
          font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.8)
        }
        MouseArea {
          id: autoHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (!autoButton.faint) root.opacityPicked("auto")
        }
      }
    }
  }

  Item {
    id: body
    y: opacityRow.y + opacityRow.height + Type.px(18)
    width: parent.width

    Column {
      id: list
      width: root.listWidth

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
      x: root.twoUp ? root.width - root.previewRoom : 0
      y: root.twoUp ? 0 : list.height + Type.px(24)
      width: root.previewRoom
      height: previewLabel.height + Type.px(10) + preview.height * preview.scale
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
        skin: root.skin
        // A Shōji panel can be wider than the room (Time with the season): fit it.
        scale: Math.min(1, root.previewRoom / Math.max(1, width))
        transformOrigin: Item.TopLeft
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
    // Three lines: the name, the hand's line, the seven-way choice across.
    height: seg.y + seg.height + Type.px(12)
    Rectangle {
      anchors.fill: parent
      color: row.focused ? Ink.alpha(Ink.bone, 0.05) : "transparent"
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.lineSoft }
    Rectangle { visible: row.focused; width: 2; height: parent.height - Type.px(16); anchors.verticalCenter: parent.verticalCenter; color: Ink.ink }
    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: row.touched(); onClicked: row.touched() }
    Text {
      x: Type.px(12)
      y: label.y
      width: Type.px(26)
      text: row.jp
      color: Ink.inkMuted
      font.family: Type.brush
      font.pixelSize: Type.px(18)
    }
    Column {
      id: label
      x: Type.px(46)
      y: Type.px(12)
      width: parent.width - x - Type.px(12)
      spacing: Type.px(2)
      Text { text: row.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row }
      Text { width: parent.width; elide: Text.ElideRight; text: row.line; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
    }
    Segmented {
      id: seg
      x: Type.px(12)
      y: label.y + label.implicitHeight + Type.px(10)
      fill: row.width - 2 * x
      options: S.SHEET_STYLES
      labels: root.labels
      selected: row.selected
      onPicked: function(v) { row.picked(v) }
    }
  }
}
