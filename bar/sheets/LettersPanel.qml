pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs
import "../parts"

// Letters 便り: what is waiting for you, newest first, each marked by the
// unread part; Quiet (do not disturb) at the top; replay and clear at the foot.
// Requests as InboxSheet's: dnd | replay | clear | open | putAway.
Column {
  id: root

  property var skin: ({})
  property var letters: []
  property bool dnd: false
  property date now: new Date()
  property int maxRows: 5
  // The letter unfolded (SheetView keeps it).
  property string openStem: ""
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
    Letter {
      required property var modelData
      required property int index
      width: root.width
      skin: root.skin
      letter: modelData
      now: root.now
      first: index === 0
      expanded: modelData.stem === root.openStem
      onToggled: root.request("inbox", "open", expanded ? "" : modelData.stem)
      onPutAway: root.request("inbox", "putAway", modelData)
    }
  }
  Item {
    width: parent.width; height: Type.px(30)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "Show recent again"
      readonly property bool keyStop: true
      function keyPress() { root.request("inbox", "replay", null) }
      color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.request("inbox", "replay", null) }
    }
    Text {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      text: "Clear all"
      readonly property bool keyStop: true
      function keyPress() { root.request("inbox", "clear", null) }
      color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.request("inbox", "clear", null) }
    }
  }
}
