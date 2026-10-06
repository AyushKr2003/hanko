import QtQuick
import "../core"

// The clock 時. Phase 1 draws `stacked`: serif time with the day and date
// stacked in small mono beside it. `inline` and `mono` arrive in phase 3.
Item {
  id: root

  property string mode: "stacked"
  property date now: new Date()
  property int barHeight: 40

  readonly property real timeSize: barHeight <= 32 ? 18 : barHeight >= 44 ? 24 : 21
  readonly property string hours: Qt.formatTime(now, "HH")
  readonly property string minutes: Qt.formatTime(now, "mm")

  implicitWidth: row.implicitWidth + Type.px(32)
  implicitHeight: barHeight

  Row {
    id: row
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -1
    spacing: Type.px(10)

    Text {
      id: time
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.StyledText
      text: root.hours + "<font color='" + Ink.inkMuted + "'>:</font>" + root.minutes
      color: Ink.ink
      font.family: Type.display
      font.pixelSize: Type.px(root.timeSize)
      font.weight: Font.Normal
      font.variableAxes: { "opsz": 36, "wght": 400 }
      font.letterSpacing: 0.2
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(2)
      visible: root.barHeight > 32

      Text {
        text: Qt.formatDate(root.now, "ddd").toUpperCase()
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.px(8)
        font.weight: Font.Medium
        font.letterSpacing: 1.6
      }
      Text {
        text: Qt.formatDate(root.now, "dd MMM").toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.px(8)
        font.letterSpacing: 1.6
      }
    }

    // At 32 px the date sits beside the time instead of stacking.
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.barHeight <= 32
      text: Qt.formatDate(root.now, "ddd dd MMM").toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(8)
      font.letterSpacing: 1.6
    }
  }
}
