pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import "../../core/Leaf.js" as LeafJs
import ".."
import "../scroll"

// Settings › Parts 部品 (was Widgets): every part the bar can show.
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

  // ------------------------------------------------ Widgets
  // Every part the bar can show, each shown or hidden: Hanko's own,
  // its marks, the tray's apps and the widgets it hosts.
  Column {
    width: parent.width
    topPadding: Type.px(22)
    spacing: Type.px(14)

    Row {
      spacing: Type.px(12)
      SmallButton {
        label: "Show all"
        faint: root.style.hidden.length === 0
        onClicked: root.showAll()
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.style.hidden.length
          ? (root.style.hidden.length + (root.style.hidden.length === 1 ? " PART HIDDEN" : " PARTS HIDDEN"))
          : "EVERYTHING SHOWN"
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.px(10)
        font.letterSpacing: Type.px(1.8)
      }
    }

    Grid {
      id: partCards
      width: parent.width
      columns: Math.max(1, Math.min(3, Math.floor((width + spacing) / (Type.px(400) + spacing))))
      spacing: Type.px(12)
      readonly property real cardWidth: (width - (columns - 1) * spacing) / columns
      readonly property var cardList: Settings.visibilityCards(root.visibility)

      Repeater {
        id: partRepeater
        model: partCards.cardList
        SettingsCard {
          required property var modelData
          required property int index
          width: partCards.cardWidth
          height: Math.max(implicitHeight, partCards.rowHeight(Math.floor(index / partCards.columns)))
          card: modelData
          style: root.style
          options: S.OPTIONS
          query: root.query
          onPicked: function(key, value) { root.settingPicked(key, value) }
        }
      }

      function rowHeight(r) {
        void partRepeater.count
        var h = 0
        for (var i = r * columns; i < (r + 1) * columns; i++) {
          var c = partRepeater.itemAt(i) as SettingsCard
          if (c && c.visible) h = Math.max(h, c.implicitHeight)
        }
        return h
      }
    }

    Text {
      width: parent.width
      wrapMode: Text.Wrap
      text: "Hiding a part takes it off this bar only; the widget stays in Omarchy's bar layout. Add or remove widgets there."
      color: Ink.inkMuted
      font.family: Type.text
      font.pixelSize: Type.note
    }
  }

}
