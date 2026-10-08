pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// How a panel says what it is (Kata part `sign`). Each kind is laid out by
// the panel: `eyebrow` sits at the top of its content, `tabs` hang from its
// foot, `tategaki` is a column down its right edge.
//   eyebrow   Margin: a heading, the panel's name then its detail
//   tabs      Leaf: die-cut index tabs, the open one part of the sheet
//   tategaki  Shōji: the name written down the edge in Mincho, English beside
Item {
  id: root

  property var skin: ({})
  property string kanji: "音"
  property string name: "Sound"
  property string detail: ""
  property var tabs: []            // [{ key, name }] for index tabs
  property string current: ""
  signal picked(string key)

  readonly property string kind: skin.sign || "eyebrow"

  implicitWidth: kind === "tategaki" ? Type.px(52) : kind === "tabs" ? tabRow.implicitWidth : head.implicitWidth
  implicitHeight: kind === "tategaki" ? column.implicitHeight : kind === "tabs" ? Type.px(30) : head.implicitHeight

  Row {
    id: head
    visible: root.kind === "eyebrow"
    spacing: Type.px(8)
    Text { text: root.name; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
    Text { text: root.detail ? "· " + root.detail : ""; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5) }
  }

  Row {
    id: tabRow
    visible: root.kind === "tabs"
    spacing: 3
    Repeater {
      model: root.tabs
      Item {
        id: tab
        required property var modelData
        readonly property bool open: modelData.key === root.current
        width: label.implicitWidth + Type.px(22); height: Type.px(28)
        y: open ? 0 : -3
        Rectangle { visible: root.skin.surface === "card"; x: 2; y: 4; width: parent.width; height: parent.height; color: Ink.shade2 }
        Rectangle { visible: root.skin.surface === "card"; y: 2; width: parent.width; height: parent.height; color: Ink.shade }
        Rectangle {
          anchors.fill: parent
          color: tab.open ? Ink.paper : Ink.paper2
          border.width: root.skin.surface === "card" ? 0 : 1; border.color: Ink.kLine
          radius: root.skin.radiusChip || 0
        }
        Rectangle { visible: tab.open; x: 1; y: -2; width: parent.width - 2; height: 3; color: Ink.paper }
        Text {
          id: label
          anchors.centerIn: parent
          text: tab.modelData.name
          color: tab.open ? Ink.ink : Ink.ink3
          font.family: Type.text; font.pixelSize: Type.px(12); font.weight: Font.Medium; font.variableAxes: Type.valueAxes
        }
        MouseArea { anchors.fill: parent; onClicked: root.picked(tab.modelData.key) }
      }
    }
  }

  Column {
    id: column
    visible: root.kind === "tategaki"
    width: root.width
    topPadding: Type.px(18)
    spacing: Type.px(14)
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Type.px(4)
      Repeater {
        model: Array.from(root.kanji)
        Text {
          required property string modelData
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData
          color: Ink.ink
          font.family: Type.jpSerif; font.weight: Font.Medium; font.pixelSize: Type.px(24)
        }
      }
    }
    // Latin in a vertical line turns 90°, as Japanese print sets it.
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: en.implicitHeight; height: en.implicitWidth
      Text {
        id: en
        anchors.centerIn: parent
        rotation: 90
        text: root.name
        color: Ink.ink3
        font.family: Type.text; font.pixelSize: Type.px(11.5)
      }
    }
  }
}
