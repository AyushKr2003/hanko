pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import "../../core/Leaf.js" as LeafJs
import ".."
import "../scroll"

// Settings › Scroll 巻: how panels open, the scroll's dividers and end leaf.
Column {
  id: root

  property var style: ({})
  property var draft: S.normalize({})
  property string query: ""
  property bool compact: false
  // Settings.visibilityCards ctx: own, indicators, tray, hosted.
  property var visibility: ({})

  signal settingPicked(string key, string value)
  signal showAll()

  width: parent ? parent.width : 0

  // ------------------------------------------------ Scroll
  // How panels open (sheets or the scroll), the scroll's frame and the
  // overview: what used to close Typesetting.
  Column {
    width: parent.width
    topPadding: Type.px(22)
    SettingsCard {
      width: parent.width
      height: implicitHeight
      card: Settings.PANELS_CARD
      style: root.style
      options: S.OPTIONS
      query: root.query
      onPicked: function(key, value) { root.settingPicked(key, value) }
    }
  }

  // What sits between the scroll's sections (the `interlude` setting):
  // each tile draws the real Interlude between two stub sections.
  Column {
    width: parent.width
    topPadding: Type.px(22)
    spacing: Type.px(12)

    Row {
      spacing: Type.px(8)
      Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
      Text { text: "BETWEEN PANELS"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
    }

    Grid {
      id: interludes
      width: parent.width
      spacing: Type.px(8)
      columns: width >= Type.px(760) ? 3 : 2
      Repeater {
        model: Settings.INTERLUDES
        Rectangle {
          id: tile
          required property var modelData
          readonly property bool on: modelData.key === root.style.interlude
          width: (interludes.width - (interludes.columns - 1) * interludes.spacing) / interludes.columns
          height: stage.height + caption.height + Type.px(20)
          radius: 3
          color: tileHover.containsMouse && !on ? Ink.lineSoft : "transparent"
          border.width: on ? 2 : 1
          border.color: on ? Ink.bone : Ink.line

          // Two stub sections either side of the interlude.
          Item {
            id: stage
            x: Type.px(8); y: Type.px(8)
            width: parent.width - 2 * x
            height: Type.px(150)
            clip: true
            Repeater {
              model: [{ jp: "時", no: "01", left: true }, { jp: "音", no: "02", left: false }]
              Column {
                id: stub
                required property var modelData
                x: stub.modelData.left ? Type.px(10) : stage.width / 2 + Type.px(30)
                y: Type.px(18)
                width: stage.width / 2 - Type.px(42)
                spacing: Type.px(6)
                Text { text: stub.modelData.jp + "  " + stub.modelData.no; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(9) }
                Rectangle { width: parent.width * 0.8; height: Type.px(7); radius: 1; color: Ink.inkDim; opacity: 0.55 }
                Rectangle { width: parent.width * 0.55; height: Type.px(3); color: Ink.inkFaint; opacity: 0.6 }
                Item { width: 1; height: Type.px(6) }
                Repeater {
                  model: 4
                  Rectangle { required property int index; width: stub.width * (0.9 - index * 0.12); height: 1; color: Ink.line }
                }
              }
            }
            Interlude {
              x: stage.width / 2 - width / 2
              y: Type.px(8)
              width: Type.px(46)
              height: stage.height - Type.px(16)
              s: Type.scale * 0.62
              seed: 0
              style: tile.modelData.key
            }
          }

          Row {
            id: caption
            x: Type.px(12)
            y: stage.y + stage.height + Type.px(6)
            spacing: Type.px(8)
            Text { text: tile.modelData.jp; color: tile.on ? Ink.seal : Ink.inkDim; font.family: Type.jp; font.pixelSize: Type.px(13) }
            Column {
              Text { text: tile.modelData.name.toUpperCase() + (tile.on ? "  · IN USE" : ""); color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.6) }
              Text { text: tile.modelData.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
            }
          }

          MouseArea {
            id: tileHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingPicked("interlude", tile.modelData.key)
          }
        }
      }
    }
  }

  // What sits after Inbox (the `endleaf` setting): each tile draws the
  // real end leaf, small, with a sample reading.
  Column {
    width: parent.width
    topPadding: Type.px(26)
    spacing: Type.px(12)

    Row {
      spacing: Type.px(8)
      Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
      Text { text: "AFTER INBOX"; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
    }

    Grid {
      id: endleaves
      width: parent.width
      spacing: Type.px(8)
      columns: width >= Type.px(760) ? 3 : 2
      readonly property var reading: LeafJs.sample(new Date())
      Repeater {
        model: Settings.ENDLEAVES
        Rectangle {
          id: leafTile
          required property var modelData
          readonly property bool on: modelData.key === root.style.endleaf
          width: (endleaves.width - (endleaves.columns - 1) * endleaves.spacing) / endleaves.columns
          height: leafStage.height + leafCaption.height + Type.px(20)
          radius: 3
          color: leafHover.containsMouse && !on ? Ink.lineSoft : "transparent"
          border.width: on ? 2 : 1
          border.color: on ? Ink.bone : Ink.line

          Item {
            id: leafStage
            x: Type.px(8)
            y: Type.px(8)
            width: parent.width - 2 * x
            height: Math.round(width * 0.82)
            clip: true
            EndLeaf {
              width: Type.px(400)
              height: Type.px(460)
              x: (leafStage.width - width * scale) / 2
              y: -Type.px(36) * scale
              transformOrigin: Item.TopLeft
              scale: leafStage.height / Type.px(390)
              kind: leafTile.modelData.key
              reading: endleaves.reading
              version: "0.1.0"
              preset: root.style.preset
              sealGlyph: root.style.sealGlyph
              enabled: false
            }
          }

          Row {
            id: leafCaption
            x: Type.px(12)
            y: leafStage.y + leafStage.height + Type.px(6)
            spacing: Type.px(8)
            Text { text: leafTile.modelData.jp; color: leafTile.on ? Ink.seal : Ink.inkDim; font.family: Type.jp; font.pixelSize: Type.px(13) }
            Column {
              Text { text: leafTile.modelData.name.toUpperCase() + (leafTile.on ? "  · IN USE" : ""); color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(1.6) }
              Text { text: leafTile.modelData.detail; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
            }
          }

          MouseArea {
            id: leafHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingPicked("endleaf", leafTile.modelData.key)
          }
        }
      }
    }
  }
}
