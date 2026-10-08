pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Kata.js" as K
import "../../../core/Skin.js" as Sk
import "../../../bar/parts"

// Kata's parts in QML: every part as each design draws it, then a small
// panel per design built from nothing but parts. params:
//   { theme: { foreground, background, red }, width, title, designs?: [doc, ...] }
Rectangle {
  id: sheet

  readonly property var p: JSON.parse(params)
  readonly property var docs: p.designs || [{ design: "margin" }, { design: "leaf" }, { design: "shoji" }]
  readonly property var skins: docs.map(function(d) { return Sk.skin(K.resolve(d)) })
  readonly property var names: docs.map(function(d) { return K.describe(K.resolve(d)) })
  readonly property real col: (width - 80 - 170) / docs.length

  width: p.width || 1600
  height: content.implicitHeight + 80
  color: Ink.paper

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
    Motion.forceStill = true
  }

  component Label: Text {
    color: Ink.ink3
    font.family: Type.text
    font.pixelSize: 13
  }

  Column {
    id: content
    x: 40; y: 36
    width: sheet.width - 80
    spacing: 0

    Text {
      text: sheet.p.title || "Kata 型 · the parts in QML"
      color: Ink.ink
      font.family: Type.display; font.pixelSize: 30; font.weight: Font.Normal
      font.variableAxes: Type.axes(30, 360, 0)
      bottomPadding: 20
    }

    // header: design names
    Row {
      Item { width: 170; height: 30 }
      Repeater {
        model: sheet.names
        Text { required property string modelData; width: sheet.col; text: modelData; color: Ink.ink; font.family: Type.text; font.pixelSize: 14; font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
      }
    }

    Repeater {
      model: ["surface", "divider", "select", "slider", "ring", "seal", "unread", "pointer", "sign"]
      Rectangle {
        id: rowBox
        required property string modelData
        required property int index
        width: content.width
        height: modelData === "surface" ? 110 : modelData === "sign" ? 120 : 76
        color: index % 2 ? "transparent" : Ink.alpha(Ink.ink, 0.025)
        Rectangle { width: parent.width; height: 1; color: Ink.kLine }
        Label { x: 12; anchors.verticalCenter: parent.verticalCenter; text: rowBox.modelData; font.pixelSize: 14; color: Ink.ink2 }

        Repeater {
          model: sheet.skins
          Item {
            id: cell
            required property var modelData
            required property int index
            readonly property var skin: modelData
            x: 170 + index * sheet.col
            width: sheet.col - 24; height: rowBox.height

            Surface { visible: rowBox.modelData === "surface"; skin: cell.skin; x: 8; y: 16; width: 180; height: 70 }
            Label { visible: rowBox.modelData === "surface"; x: 210; anchors.verticalCenter: parent.verticalCenter; text: cell.skin.surface + " · corners " + cell.skin.corner }

            Divider { visible: rowBox.modelData === "divider"; skin: cell.skin; x: 16; y: 36; width: 200 }
            Label { visible: rowBox.modelData === "divider"; x: 240; anchors.verticalCenter: parent.verticalCenter; text: cell.skin.divider }

            Item {
              visible: rowBox.modelData === "select"
              x: 8; y: 15; width: 260; height: 46
              Selection { id: sel; skin: cell.skin; width: parent.width; height: 46 }
              Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "Studio Monitors"; color: sel.inverts ? Ink.paper : Ink.ink; font.family: Type.text; font.pixelSize: 14; font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
            }

            KataSlider { visible: rowBox.modelData === "slider"; skin: cell.skin; x: 8; y: 23; width: 260; height: 30; value: 62 }
            KataSlider { visible: rowBox.modelData === "slider"; skin: cell.skin; x: 290; y: 29; width: 120; height: 18; value: 45; thin: true; seed: 12 }

            Row {
              visible: rowBox.modelData === "ring"
              x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 18
              Ring { skin: cell.skin; value: 91; size: 17; anchors.verticalCenter: parent.verticalCenter }
              Ring { skin: cell.skin; value: 12; size: 17; alert: true; anchors.verticalCenter: parent.verticalCenter }
              Ring { skin: cell.skin; value: 91; size: 60; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              visible: rowBox.modelData === "seal"
              x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 14
              KataSeal { skin: cell.skin; size: 28 }
              KataSeal { skin: cell.skin; size: 28; on: true }
              KataSeal { skin: cell.skin; size: 28; on: true; glyph: "安" }
            }

            Row {
              visible: rowBox.modelData === "unread"
              x: 8; y: 12; spacing: 16
              Rectangle {
                width: 150; height: 52; color: "transparent"; radius: cell.skin.radiusRow
                border.width: 1; border.color: Ink.kLine
                Label { x: 12; y: 10; text: "Signal · 2 min" }
                UnreadMark { anchors.fill: parent; skin: cell.skin }
              }
              Item {
                width: 28; height: 26
                Text { anchors.centerIn: parent; text: "4"; color: Ink.ink2; font.family: Type.text; font.pixelSize: 13 }
                UnreadMark { anchors.fill: parent; skin: cell.skin; small: true }
              }
            }

            Item {
              visible: rowBox.modelData === "pointer"
              x: 8; y: 8; width: 300; height: 60
              Rectangle { y: 0; width: parent.width; height: 40; color: Ink.paper }
              Rectangle { y: 39; width: parent.width; height: 1; color: Ink.kLine }
              Row {
                y: 0; height: 40; spacing: 0
                Repeater {
                  model: ["Wi-Fi", "62", "91"]
                  Text { required property string modelData; width: 60; height: 40; text: modelData; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: modelData === "62" ? Ink.ink : Ink.ink2; font.family: Type.text; font.pixelSize: 13 }
                }
              }
              PointerMark { anchors.fill: parent; skin: cell.skin; target: Qt.rect(60, 0, 60, 40); lineY: 40; label: "Sound" }
            }

            Item {
              visible: rowBox.modelData === "sign"
              x: 8; y: 10; width: parent.width - 16; height: 100
              Sign { visible: cell.skin.sign === "eyebrow"; skin: cell.skin; y: 6; name: "Sound"; detail: "Studio Monitors" }
              Sign { visible: cell.skin.sign === "tabs"; skin: cell.skin; y: 30; current: "sound"; tabs: [{ key: "time", name: "Time" }, { key: "sound", name: "Sound" }, { key: "net", name: "Network" }, { key: "power", name: "Power" }] }
              Sign { visible: cell.skin.sign === "tategaki"; skin: cell.skin; width: 52; height: 100; kanji: "音"; name: "Sound" }
            }
          }
        }
      }
    }

    Item { width: 1; height: 36 }
    Label { text: "A panel built only from parts"; font.pixelSize: 13; color: Ink.ink2; bottomPadding: 14 }

    Row {
      spacing: 24
      Repeater {
        model: sheet.skins
        Item {
          id: mini
          required property var modelData
          readonly property var skin: modelData
          readonly property bool tate: skin.sign === "tategaki"
          width: (content.width - 48) / 3; height: 360

          Surface { id: surf; skin: mini.skin; x: 0; y: 0; width: parent.width; height: 300 }
          Column {
            x: 20; y: 18; width: parent.width - 40 - (mini.tate ? 52 : 0); spacing: 10
            Sign { visible: mini.skin.sign === "eyebrow"; skin: mini.skin; name: "Sound"; detail: "Studio Monitors" }
            Label { visible: mini.skin.sign !== "eyebrow"; text: "Studio Monitors"; color: Ink.ink2 }
            Row {
              spacing: 6
              Text { text: "62"; color: Ink.ink; font.family: Type.display; font.pixelSize: 60; font.weight: Font.Normal; font.variableAxes: Type.axes(60, 330, mini.skin.soft) }
              Text { text: "%"; anchors.baseline: parent.children[0].baseline; color: Ink.ink3; font.family: Type.display; font.pixelSize: 20 }
            }
            KataSlider { skin: mini.skin; width: parent.width; height: 30; value: 62 }
            Divider { skin: mini.skin; width: parent.width; bleed: 20 }
            Item {
              width: parent.width; height: 92
              Selection { id: ms; skin: mini.skin; x: -10; width: parent.width + 20; height: 46 }
              Repeater {
                model: ["Studio Monitors", "WH-1000XM5"]
                Text { required property string modelData; required property int index; x: 4; y: index * 46 + 14; text: modelData; color: index === 0 ? (ms.inverts ? Ink.paper : Ink.ink) : Ink.ink2; font.family: Type.text; font.pixelSize: 14; font.weight: index === 0 ? Font.Medium : Font.Normal; font.variableAxes: Type.valueAxes }
              }
            }
          }
          Sign { visible: mini.tate; skin: mini.skin; x: parent.width - 52; width: 52; height: 300; kanji: "音"; name: "Sound" }
          Rectangle { visible: mini.tate; x: parent.width - 53; width: 1; height: 300; color: Ink.kLine }
          Sign { visible: mini.skin.sign === "tabs"; skin: mini.skin; x: 14; y: 300; current: "sound"; tabs: [{ key: "time", name: "Time" }, { key: "sound", name: "Sound" }, { key: "power", name: "Power" }] }
        }
      }
    }
  }
}
