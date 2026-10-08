pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Kata.js" as K
import "../../core/Skin.js" as Sk
import "../../core/Style.js" as S
import "../../core/Season.js" as Season
import ".."

// Settings › Design 意匠 (docs/kata §6): which design draws the bar, the
// parts borrowed from the others, and the touches. Four design cards with
// the bar drawn live in each; a line naming the mix, Surprise and Back to
// the design; one row per part, each variant drawn by the part itself; the
// touches. Every pick applies at once (the window saves as you go and keeps
// an undo history), so nothing here waits for a Save.
Column {
  id: root

  property var doc: S.normalize({})
  property var barData: ({})
  property bool compact: false

  signal designPicked(string name)
  signal borrowPicked(string part, string value)
  signal touchPicked(string key, string value)
  signal surprise()
  signal backToDesign()

  readonly property var kata: K.resolve(doc)
  readonly property bool classic: kata.classic
  readonly property var blurbs: ({ classic: "today's Typeset bar", margin: "paper, soft and calm", leaf: "cards, tabs and tickets", shoji: "washi, ink and the seasons" })
  // Classic has no parts to borrow; its rows show Margin's.
  readonly property var base: classic ? ({ design: "margin" }) : doc

  readonly property var season: Season.at(barData.now || new Date())
  function skinWith(part, value) { return Sk.skin(K.resolve(K.withBorrow(base, part, value) || base)) }

  spacing: Type.px(14)
  topPadding: Type.px(22)

  // ------------------------------------------------ the four designs
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
        readonly property bool on: root.kata.design === modelData
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

  // ------------------------------------------------ the mix
  Item {
    width: parent.width
    height: Math.max(mix.implicitHeight, mixButtons.height) + Type.px(12)
    Text {
      id: mix
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - mixButtons.width - Type.px(16)
      wrapMode: Text.Wrap
      text: K.describe(root.kata)
      color: Ink.ink
      font.family: Type.display; font.italic: true; font.pixelSize: Type.px(20)
      font.variableAxes: Type.axes(Type.px(20))
    }
    Row {
      id: mixButtons
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(10)
      Button { label: root.classic ? "Back to Classic" : "Back to " + K.LABELS[root.kata.design]; faint: root.classic || root.kata.borrowed.length === 0; onClicked: root.backToDesign() }
      Button { label: "Surprise me"; onClicked: root.surprise() }
    }
  }

  Rectangle { width: parent.width; height: 1; color: Ink.line }

  // ------------------------------------------------ borrow a part
  Text {
    width: parent.width
    wrapMode: Text.Wrap
    text: root.classic
      ? "Classic is drawn by its own code, so it has no parts to borrow. Pick Margin, Leaf or Shōji above, then borrow any part from the other two here."
      : "Borrow any part from another design. The parts that go with it (corners, dividers, tempo) follow on their own."
    color: Ink.inkMuted
    font.family: Type.text; font.pixelSize: Type.row
  }

  Repeater {
    model: K.MAIN_PARTS
    Item {
      id: partRow
      required property string modelData
      required property int index
      readonly property var variants: Object.keys(K.PARTS[modelData].v)
      readonly property real labelW: root.compact ? parent.width : Type.px(150)
      width: root.width
      height: (root.compact ? label.height + Type.px(8) : 0) + tiles.height + Type.px(8)
      opacity: root.classic ? 0.45 : 1
      enabled: !root.classic

      Column {
        id: label
        width: partRow.labelW - Type.px(12)
        y: root.compact ? 0 : Type.px(10)
        spacing: Type.px(3)
        Text {
          text: K.PART_LABELS[partRow.modelData].charAt(0).toUpperCase() + K.PART_LABELS[partRow.modelData].slice(1)
          color: Ink.ink
          font.family: Type.text; font.pixelSize: Type.row; font.weight: Font.Medium; font.variableAxes: Type.valueAxes
        }
        Text {
          visible: root.kata.borrowed.indexOf(partRow.modelData) >= 0
          text: "BORROWED"
          color: Ink.seal
          font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag
        }
      }
      Row {
        id: tiles
        x: root.compact ? 0 : partRow.labelW
        y: root.compact ? label.height + Type.px(8) : 0
        spacing: Type.px(10)
        readonly property real tileW: Math.min(Type.px(230), (partRow.width - x - 2 * spacing) / 3)
        Repeater {
          model: partRow.variants
          Column {
            id: tile
            required property string modelData
            readonly property bool on: root.kata[partRow.modelData] === modelData
            readonly property string from: K.PARTS[partRow.modelData].v[modelData]
            spacing: Type.px(4)
            Rectangle {
              width: tiles.tileW; height: Type.px(78)
              radius: 3
              color: "transparent"
              border.width: tile.on ? 2 : 1
              border.color: tile.on ? Ink.ink : tileArea.containsMouse ? Ink.lineStrong : Ink.line
              PartPreview {
                x: 2; y: 2
                width: parent.width - 4; height: parent.height - 4
                part: partRow.modelData
                skin: root.skinWith(partRow.modelData, tile.modelData)
              }
              MouseArea {
                id: tileArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.borrowPicked(partRow.modelData, tile.modelData)
              }
            }
            Text {
              width: tiles.tileW; elide: Text.ElideRight
              text: tile.modelData + " · " + K.LABELS[tile.from]
              color: tile.on ? Ink.ink : Ink.inkMuted
              font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag
              font.capitalization: Font.AllUppercase
            }
          }
        }
      }
    }
  }

  Rectangle { width: parent.width; height: 1; color: Ink.line }

  // ------------------------------------------------ touches
  Text {
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
