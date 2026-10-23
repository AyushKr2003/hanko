pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Sheets.js" as Sheets
import "../../core/Skin.js" as Sk
import "../sheets"
import "../parts" as Parts

// Settings › Sheets 紙, on the proof's rule (docs/settings-kosei): pick a
// sheet from the row of seven; it prints large, live, in the hand that
// draws it; beside it every hand is drawn as a picture of that same sheet.
// Hover a hand to print the sheet in it, click to keep it for that sheet;
// "Every sheet" puts all seven in one hand. Panel opacity at the foot.
Column {
  id: root

  property var doc: S.normalize({})
  // The sheets' plain data (SheetWindow.feed's shape).
  property var feed: ({})
  property bool compact: false

  signal stylePicked(string sheet, string style)
  // Panel opacity: a percent (30..100) as text, or "auto" for each hand's own.
  signal opacityPicked(string value)
  // The Time sheet's two settings (Koyomi 暦): calendar and weather.
  signal touchPicked(string key, string value)

  readonly property var styles: S.resolve(doc).sheetStyles
  // The previews draw the Time sheet as the draft says: almanac or week.
  readonly property var shownFeed: Object.assign({}, feed, { calendar: S.resolve(doc).calendar, sky: S.resolve(doc).weather === "off" ? null : feed.sky })
  property string focusSheet: "sound"
  // A hand under the pointer, tried on the large print.
  property string trialHand: ""
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
  readonly property var skin: Sk.fromStyle(S.resolve(doc))
  readonly property int panelOpacity: S.resolve(doc).panelOpacity || 0
  readonly property real paperOpacity: panelOpacity > 0 ? panelOpacity / 100 : 1
  readonly property string handOf: styles[focusSheet] || "ledger"
  readonly property string shownHand: trialHand !== "" ? trialHand : handOf
  function withHand(hand) {
    var m = Object.assign({}, styles)
    m[focusSheet] = hand
    return m
  }
  function handInfo(key) { return hands[Math.max(0, S.SHEET_STYLES.indexOf(key))] }
  readonly property bool twoUp: width >= Type.px(900)
  readonly property real printRoom: twoUp ? Math.min(Type.px(560), width * 0.52) : width

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  // ------------------------------------------------------------ the seven
  Flow {
    width: parent.width
    spacing: Type.px(6)
    Repeater {
      model: Sheets.SHEETS
      Rectangle {
        id: tab
        required property var modelData
        readonly property bool open: modelData.key === root.focusSheet
        width: Math.max(Type.px(118), tabCol.width + Type.px(24))
        height: Type.px(62)
        radius: 3
        color: open ? Ink.bone : tabHover.containsMouse ? Ink.lineSoft : "transparent"
        border.width: 1
        border.color: open ? Ink.bone : Ink.line
        Row {
          x: Type.px(12)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(10)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tab.modelData.jp
            color: tab.open ? Ink.boneInk : Ink.seal
            font.family: Type.brush
            font.pixelSize: Type.px(24)
          }
          Column {
            id: tabCol
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(2)
            Text {
              text: tab.modelData.label.charAt(0) + tab.modelData.label.slice(1).toLowerCase()
              color: tab.open ? Ink.boneInk : Ink.ink
              font.family: Type.text
              font.pixelSize: Type.px(14)
            }
            Text {
              text: (root.labels[root.styles[tab.modelData.key]] || "Ledger").toUpperCase()
              color: tab.open ? Ink.alpha(Ink.boneInk, 0.7) : Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackLabel
            }
          }
        }
        MouseArea {
          id: tabHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          readonly property bool keyStop: enabled
          readonly property bool keyChosen: tab.open
          function keyPress() { root.focusSheet = tab.modelData.key }
          onClicked: root.focusSheet = tab.modelData.key
        }
      }
    }
  }

  Item { width: 1; height: Type.px(22) }

  // ------------------------------------------------- the print and the hands
  Grid {
    id: body
    width: parent.width
    columns: root.twoUp ? 2 : 1
    columnSpacing: Type.px(28)
    rowSpacing: Type.px(22)

    // The sheet, printed live in its hand (or the hand being tried).
    Column {
      width: root.printRoom
      spacing: Type.px(10)
      Row {
        spacing: Type.px(8)
        Text { text: root.handInfo(root.shownHand).jp; color: Ink.seal; font.family: Type.brush; font.pixelSize: Type.px(14) }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: (root.trialHand !== "" ? "TRYING · " : "PRINTED · ") + root.focusSheet.toUpperCase() + " IN " + root.handInfo(root.shownHand).name.toUpperCase()
          color: root.trialHand !== "" ? Ink.ink : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackLabel
        }
      }
      Item {
        width: parent.width
        height: printed.height * printed.scale
        SheetView {
          id: printed
          keyStops: false
          sheet: root.focusSheet
          styles: root.withHand(root.shownHand)
          skin: root.skin
          scale: Math.min(1, root.printRoom / Math.max(1, width))
          transformOrigin: Item.TopLeft
          feed: root.shownFeed
          animate: false
          tearX: Type.px(30)
          tearWidth: Type.px(80)
        }
      }
    }

    // Every hand, as a picture of this sheet.
    Column {
      width: root.twoUp ? body.width - root.printRoom - body.columnSpacing : body.width
      spacing: Type.px(10)
      Text {
        text: "書  SEVEN HANDS · " + root.focusSheet.toUpperCase() + " IN EACH"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
      Grid {
        id: handGrid
        width: parent.width
        columns: width >= Type.px(380) ? 2 : 1
        spacing: Type.px(8)
        readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)
        Repeater {
          model: root.hands
          Rectangle {
            id: hand
            required property var modelData
            readonly property bool on: modelData.key === root.handOf
            width: handGrid.tileWidth
            height: thumb.height + handCaption.height + 2
            radius: 3
            color: handHover.containsMouse && !on ? Ink.lineSoft : "transparent"
            border.width: 1
            border.color: on ? Ink.bone : handHover.containsMouse ? Ink.lineStrong : Ink.line
            clip: true

            // The top of the sheet in this hand, small.
            Item {
              id: thumb
              x: 1
              y: 1
              width: parent.width - 2
              height: Type.px(104)
              clip: true
              SheetView {
                id: mini
                keyStops: false
                x: Math.max(0, (thumb.width - width * scale) / 2)
                y: Type.px(4)
                sheet: root.focusSheet
                styles: root.withHand(hand.modelData.key)
                skin: root.skin
                scale: Math.min(0.5, (thumb.width - Type.px(8)) / Math.max(1, width))
                transformOrigin: Item.TopLeft
                feed: root.shownFeed
                animate: false
                tearX: Type.px(30)
                tearWidth: Type.px(80)
                enabled: false
              }
              Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Type.px(26)
                gradient: Gradient {
                  GradientStop { position: 0; color: Ink.alpha(Ink.paper, 0) }
                  GradientStop { position: 1; color: Ink.paper } }
              }
            }
            Rectangle {
              id: handCaption
              x: 1
              y: thumb.y + thumb.height
              width: parent.width - 2
              height: Type.px(42)
              color: hand.on ? Ink.bone : "transparent"
              Column {
                x: Type.px(10)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * x
                spacing: Type.px(1)
                Row {
                  spacing: Type.px(6)
                  Text { visible: hand.on; text: "//"; color: Ink.boneInk; opacity: 0.6; font.family: Type.mono; font.pixelSize: Type.px(11) }
                  Text { text: hand.modelData.jp; color: hand.on ? Ink.boneInk : Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(13) }
                  Text {
                    text: hand.modelData.name
                    color: hand.on ? Ink.boneInk : Ink.ink
                    font.family: Type.text
                    font.pixelSize: Type.px(13)
                    font.weight: Font.Medium
                    font.variableAxes: Type.valueAxes
                  }
                }
                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: hand.modelData.short
                  color: hand.on ? Ink.alpha(Ink.boneInk, 0.7) : Ink.inkMuted
                  font.family: Type.text
                  font.pixelSize: Type.note
                }
              }
            }
            MouseArea {
              id: handHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: root.trialHand = containsMouse ? hand.modelData.key : ""
              readonly property bool keyStop: enabled
              readonly property bool keyChosen: hand.on
              function keyPress() { root.trialHand = ""; root.stylePicked(root.focusSheet, hand.modelData.key) }
              onClicked: { root.trialHand = ""; root.stylePicked(root.focusSheet, hand.modelData.key) }
            }
          }
        }
      }
      // All seven in this hand.
      Row {
        spacing: Type.px(10)
        SmallButton {
          label: "Every sheet in " + root.handInfo(root.handOf).name
          onClicked: root.stylePicked("all", root.handOf)
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: {
            var n = 0
            for (var i = 0; i < S.SHEET_KEYS.length; i++) if ((root.styles[S.SHEET_KEYS[i]] || "ledger") === root.handOf) n++
            return n + " OF 7 IN IT NOW"
          }
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackLabel
        }
      }
    }
  }

  Item { width: 1; height: Type.px(26) }

  // Panel opacity 透け: how much of the desk shows through every sheet,
  // in any hand, with Shōji's brush slider. It was on Settings › Design, which went with the design.
  Item {
    id: opacityRow
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
        text: "How much of your desk shows through every panel: sheets in any hand. Auto keeps each one's own paper (solid, or Shōji's washi at 86%)."
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
          readonly property bool keyStop: enabled
          function keyPress() { if (!autoButton.faint) root.opacityPicked("auto") }
          onClicked: if (!autoButton.faint) root.opacityPicked("auto")
        }
      }
    }
  }

  // Koyomi 暦: the Time sheet as the almanac (the whole month, in every
  // hand) or the week, and the forecast on it.
  Item { width: 1; height: Type.px(14) }
  Repeater {
    model: [
      { key: "calendar", name: "Time sheet", options: ["koyomi", "week"], labels: { koyomi: "Koyomi 暦", week: "Week" },
        line: "Koyomi: the whole month in every hand, with its solar terms, the seventy-two microseasons, the moon and the year. Week: the sheet as it was, a week and the day's rulers." },
      { key: "weather", name: "Weather on the almanac", options: ["on", "off"], labels: { on: "On", off: "Off" },
        line: "The forecast on the days ahead and the weather now, from Open-Meteo at the place Omarchy's weather panel has. Off: nothing is fetched." }
    ]
    Item {
      id: touch
      required property var modelData
      width: root.width
      height: touchLabel.implicitHeight + Type.px(24) + (root.compact ? touchSeg.height + Type.px(10) : 0)
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Column {
        id: touchLabel
        y: Type.px(12)
        width: root.compact ? parent.width : parent.width - touchSeg.width - Type.px(24)
        spacing: Type.px(2)
        Text { text: touch.modelData.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row; font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
        Text { width: parent.width; wrapMode: Text.Wrap; text: touch.modelData.line; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
      }
      Segmented {
        id: touchSeg
        x: root.compact ? 0 : parent.width - width
        y: root.compact ? touchLabel.y + touchLabel.implicitHeight + Type.px(10) : Type.px(12)
        options: touch.modelData.options
        labels: touch.modelData.labels
        selected: String(S.resolve(root.doc)[touch.modelData.key])
        onPicked: function(v) { root.touchPicked(touch.modelData.key, v) }
      }
    }
  }
}
