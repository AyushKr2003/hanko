pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs
import "../parts"

// Letters 便り: what is waiting for you, newest first, each marked by the
// unread part; Quiet (do not disturb) at the top; replay and clear at the foot.
// Requests as InboxSheet's: dnd | replay | clear.
Column {
  id: root

  property var skin: ({})
  property var letters: []
  property bool dnd: false
  property date now: new Date()
  property int maxRows: 5
  signal request(string sheet, string what, var arg)

  readonly property var shown: letters.slice(0, maxRows)

  spacing: Type.px(10)

  Item {
    width: parent.width; height: Type.px(22)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.letters.length === 0 ? "Nothing for you" : root.letters.length + (root.letters.length === 1 ? " letter" : " letters")
      color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes
    }
    Row {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(8)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "Quiet"; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5) }
      KataSwitch { anchors.verticalCenter: parent.verticalCenter; skin: root.skin; on: root.dnd; onToggled: root.request("inbox", "dnd", null) }
    }
  }
  Repeater {
    model: root.shown
    Item {
      id: letter
      required property var modelData
      required property int index
      width: root.width
      height: body.implicitHeight + Type.px(22)
      // a card on paper and card; a row between lattice lines on washi
      Rectangle {
        anchors.fill: parent
        visible: root.skin.surface !== "washi"
        radius: root.skin.radiusRow || 0
        color: root.skin.surface === "card" ? Ink.paper : "transparent"
        border.width: root.skin.surface === "card" ? 0 : 1
        border.color: Ink.kLine
      }
      Rectangle { visible: root.skin.surface === "card"; y: parent.height; width: parent.width; height: 2; color: Ink.shade }
      Divider { visible: root.skin.surface === "washi" && letter.index > 0; skin: root.skin; width: parent.width; bleed: Type.px(20) }
      Column {
        id: body
        x: root.skin.surface === "washi" ? 0 : Type.px(14)
        y: Type.px(11)
        width: parent.width - 2 * x - Type.px(24)
        spacing: Type.px(3)
        Text {
          text: letter.modelData.app + " · " + StatusJs.age(letter.modelData.timestamp, root.now)
          color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
        }
        Text {
          width: parent.width; elide: Text.ElideRight
          text: letter.modelData.summary || letter.modelData.app
          color: letter.modelData.urgent ? Ink.seal : Ink.ink
          font.family: Type.text; font.pixelSize: Type.px(13.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes
        }
        Text {
          visible: !!letter.modelData.body
          width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
          text: letter.modelData.body || ""
          color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
        }
      }
      UnreadMark { anchors.fill: parent; skin: root.skin }
    }
  }
  Item {
    width: parent.width; height: Type.px(30)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "Show recent again"
      color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.request("inbox", "replay", null) }
    }
    Text {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      text: "Clear all"
      color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.request("inbox", "clear", null) }
    }
  }
}
