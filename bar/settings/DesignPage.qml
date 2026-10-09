pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Kata.js" as K
import "../../core/Skin.js" as Sk
import "../../core/Style.js" as S
import "../../core/Season.js" as Season
import ".."
import "../parts"

// Settings › Design 意匠 (docs/kata §6): which design draws the bar, its
// touches and the panels' opacity. Two design cards, Hanko and Shōji, with
// the bar drawn live in each. Every pick applies at once (the window saves
// as you go and keeps an undo history), so nothing here waits for a Save.
Column {
  id: root

  property var doc: S.normalize({})
  property var barData: ({})
  property bool compact: false

  signal designPicked(string name)
  signal touchPicked(string key, string value)
  // Panel opacity: a percent (30..100) as text, or "auto" for the design's own.
  signal opacityPicked(string value)

  readonly property var kata: K.resolve(doc)
  readonly property bool classic: kata.classic
  readonly property var blurbs: ({ classic: "the main bar, in type and ink", shoji: "washi, ink and the seasons" })

  readonly property int panelOpacity: doc.panelOpacity || 0
  // The opacity slider is drawn by Shōji's slider part on either design.
  readonly property var skin: Sk.skin(K.resolve(classic ? { design: "shoji" } : doc), panelOpacity)
  // Auto is solid paper on Hanko's sheets and the washi's own under Shōji.
  readonly property real paperOpacity: panelOpacity > 0 ? panelOpacity / 100 : classic ? 1 : skin.opacity
  readonly property var season: Season.at(barData.now || new Date())

  spacing: Type.px(14)
  topPadding: Type.px(22)

  // ------------------------------------------------ the two designs
  Grid {
    id: cards
    width: parent.width
    columns: width >= Type.px(860) ? 2 : 1
    columnSpacing: Type.px(14)
    rowSpacing: Type.px(14)
    readonly property real cardWidth: (width - (columns - 1) * columnSpacing) / columns

    Repeater {
      model: K.DESIGN_NAMES
      Rectangle {
        id: card
        required property string modelData
        // The Shōji design is the Shōji preset now: light the card for the preset in use.
        readonly property bool on: (modelData === "shoji") === (S.normalize(root.doc).preset === "Shōji")
        readonly property var cardKata: K.resolve({ design: modelData, touches: root.doc.touches })
        width: cards.cardWidth
        height: cardCol.implicitHeight + Type.px(28)
        radius: 3
        color: on ? Ink.alpha(Ink.ink, 0.04) : "transparent"
        border.width: on ? 2 : 1
        border.color: on ? Ink.ink : cardArea.containsMouse ? Ink.lineStrong : Ink.line

        Column {
          id: cardCol
          x: Type.px(14); y: Type.px(14)
          width: parent.width - Type.px(28)
          spacing: Type.px(8)
          Row {
            spacing: Type.px(10)
            Text {
              text: K.LABELS[card.modelData]
              color: Ink.ink
              font.family: Type.display; font.pixelSize: Type.px(22); font.weight: Font.Normal
              font.variableAxes: Type.axes(Type.px(22))
            }
            Text {
              visible: card.on
              anchors.verticalCenter: parent.verticalCenter
              text: "ON YOUR BAR"
              color: Ink.seal
              font.family: Type.mono; font.pixelSize: Type.label; font.letterSpacing: Type.trackLabel
            }
          }
          Text {
            width: parent.width; elide: Text.ElideRight
            text: root.blurbs[card.modelData].toUpperCase()
            color: Ink.inkMuted
            font.family: Type.mono; font.pixelSize: Type.label; font.letterSpacing: Type.trackLabel
          }
          // the bar, drawn at a desktop's width and scaled into the card
          Rectangle {
            width: parent.width
            height: Math.round((card.modelData === "classic" ? classicBar.implicitHeight : kataBar.implicitHeight) * scaleBy) + 2
            readonly property real design: Type.px(1240)
            readonly property real scaleBy: (width - 2) / design
            color: Ink.sunk
            border.width: 1; border.color: Ink.kLine
            clip: true
            BarSurface {
              id: classicBar
              visible: card.modelData === "classic"
              x: 1; y: 1
              width: parent.design; height: implicitHeight
              scale: parent.scaleBy; transformOrigin: Item.TopLeft
              style: S.resolve(root.doc)
              now: root.barData.now || new Date()
              spaces: root.barData.spaces || []
              activeWindow: root.barData.activeWindow || null
              home: root.barData.home || ""
              timeFormat: root.barData.timeFormat || "HH:mm"
              volume: root.barData.volume || null
              network: root.barData.network || null
              battery: root.barData.battery || null
              notifications: root.barData.notifications || []
              dnd: !!root.barData.dnd
            }
            KataBar {
              id: kataBar
              visible: card.modelData !== "classic"
              x: 1; y: 1
              width: parent.design
              scale: parent.scaleBy; transformOrigin: Item.TopLeft
              skin: Sk.skin(card.cardKata)
              style: S.resolve(root.doc)
              now: root.barData.now || new Date()
              spaces: root.barData.spaces || []
              activeWindow: root.barData.activeWindow || null
              home: root.barData.home || ""
              volume: root.barData.volume || null
              network: root.barData.network || null
              battery: root.barData.battery || null
              notifications: root.barData.notifications || []
              dnd: !!root.barData.dnd
            }
          }
        }
        MouseArea {
          id: cardArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.designPicked(card.modelData)
        }
      }
    }
  }

  Rectangle { visible: !root.classic; width: parent.width; height: 1; color: Ink.line }

  // ------------------------------------------------ touches
  Text {
    visible: !root.classic
    text: "Touches"
    color: Ink.ink
    font.family: Type.display; font.pixelSize: Type.px(20); font.weight: Font.Normal
    font.variableAxes: Type.axes(Type.px(20))
  }
  Repeater {
    model: [
      { key: "season", name: "Season", detail: "The sekki and kō beside the date and in Time", labels: { off: "off", kanji: root.season.sekkiKanji, english: root.season.sekkiName } },
      { key: "numerals", name: "Numerals", detail: "Workspaces in figures or kanji", labels: { arabic: "1 2 3", kanji: "一 二 三" } },
      { key: "grain", name: "Grain", detail: "How much paper is in the paper", labels: {} }
    ]
    Item {
      id: touchRow
      required property var modelData
      visible: !root.classic
      width: root.width
      height: Math.max(touchLabel.implicitHeight, seg.height) + Type.px(10)
      Column {
        id: touchLabel
        width: parent.width - seg.width - Type.px(16)
        spacing: Type.px(2)
        Text { text: touchRow.modelData.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row; font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
        Text { width: parent.width; elide: Text.ElideRight; text: touchRow.modelData.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(12) }
      }
      Segmented {
        id: seg
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        options: K.TOUCHES[touchRow.modelData.key]
        labels: touchRow.modelData.labels
        selected: root.kata.touches[touchRow.modelData.key] || ""
        onPicked: function(value) { root.touchPicked(touchRow.modelData.key, value) }
      }
    }
  }

  // ------------------------------------------------ panel opacity
  Rectangle { width: parent.width; height: 1; color: Ink.line }
  Item {
    id: opacityRow
    width: root.width
    height: opacityLabel.implicitHeight + Type.px(14) + (root.compact ? opacityControls.height + Type.px(10) : 0)
    Column {
      id: opacityLabel
      width: root.compact ? parent.width : parent.width - opacityControls.width - Type.px(24)
      spacing: Type.px(2)
      Text { text: "Panel opacity"; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row; font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
      Text {
        width: parent.width; wrapMode: Text.Wrap
        text: "How much of your desk shows through every panel: sheets, the scroll and Shōji's panels. Auto keeps the design's own (solid paper on Hanko, Shōji's washi at 86%)."
        color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(12)
      }
    }
    Row {
      id: opacityControls
      x: root.compact ? 0 : parent.width - width
      y: root.compact ? opacityLabel.implicitHeight + Type.px(10) : 0
      spacing: Type.px(14)
      KataSlider {
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
      Button { anchors.verticalCenter: parent.verticalCenter; label: "Auto"; faint: root.panelOpacity === 0; onClicked: root.opacityPicked("auto") }
    }
  }

  component Button: Rectangle {
    id: button
    property string label: ""
    property bool faint: false
    signal clicked()
    width: buttonText.implicitWidth + 2 * Type.px(14)
    height: Type.px(32)
    radius: 3
    color: buttonHover.containsMouse && !faint ? Ink.lineSoft : "transparent"
    border.width: 1
    border.color: faint ? Ink.line : Ink.lineStrong
    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.label.toUpperCase()
      color: button.faint ? Ink.inkFaint : Ink.ink
      font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.8)
    }
    MouseArea {
      id: buttonHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (!button.faint) button.clicked()
    }
  }
}
