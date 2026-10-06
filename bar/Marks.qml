pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../core"

// Hanko's own small marks in the right zone, for what Omarchy shows as
// widgets: indicators as kanji (録 recording, 書 dictation, 鈴 reminder,
// 醒 stay awake, 夜 night light; only what is on, red only for "now"), the
// keyboard layout as a mono code, the microphone as 声 (red when muted),
// and the tray, every icon inked in the dim tier. Pure: data in, signals
// out.
Item {
  id: root

  // core/Extras.js shapes.
  property var indicators: []
  property var keyboard: null      // { label, count } or null
  property var mic: null           // { muted, percent } or null
  property var tray: []
  property int barHeight: 40
  // Short of room, the tray folds into one mark (盆 and a count) that a
  // click unfolds.
  property bool compactTray: false
  property bool trayOpen: false
  readonly property bool trayFolded: compactTray && !trayOpen && tray.length > 1
  onTrayOpenChanged: if (trayOpen) refold.restart()
  Timer { id: refold; interval: 8000; onTriggered: root.trayOpen = false }

  // how: click | middle | right | up | down
  signal indicatorAction(string key, string how)
  signal keyboardAction(string how)
  signal micAction(string how)
  // The tray item's cell is passed so a menu can open under it.
  signal trayAction(string id, string how, Item cell)

  readonly property bool showKeyboard: !!keyboard && keyboard.count > 1
  // How wide the marks are with the tray unfolded.
  readonly property real fullWidth: fixedPart.implicitWidth + tray.length * (Type.px(16) + row.spacing)
  readonly property int glyphSize: Type.px(13)

  visible: indicators.length > 0 || showKeyboard || !!mic || tray.length > 0
  implicitWidth: visible ? row.implicitWidth : 0
  implicitHeight: barHeight

  function how(mouse) {
    return mouse.button === Qt.MiddleButton ? "middle" : mouse.button === Qt.RightButton ? "right" : "click"
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(12)

    // Everything but the tray, measured apart so folding the tray never
    // feeds back into the decision to fold it.
    Row {
      id: fixedPart
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(12)

      // Indicators: a kanji each, a small count for reminders.
      Repeater {
        model: root.indicators
        Item {
          id: mark
          required property var modelData
          width: markRow.implicitWidth
          height: root.barHeight
          Row {
            id: markRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(2)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: mark.modelData.glyph
              color: mark.modelData.red ? Ink.seal : Ink.inkDim
              font.family: Type.jp
              font.pixelSize: root.glyphSize
            }
            Text {
              visible: mark.modelData.count > 1
              anchors.bottom: parent.bottom
              text: String(mark.modelData.count)
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.px(8)
            }
          }
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) { root.indicatorAction(mark.modelData.key, root.how(mouse)) }
          }
        }
      }

      // Keyboard layout: "US", "DE"; a click goes to the next layout.
      Item {
        visible: root.showKeyboard
        width: kbFrame.width
        height: root.barHeight
        Rectangle {
          id: kbFrame
          anchors.verticalCenter: parent.verticalCenter
          width: kbText.implicitWidth + Type.px(10)
          height: Type.px(17)
          radius: 2
          color: "transparent"
          border.width: 1
          border.color: Ink.line
          Text {
            id: kbText
            anchors.centerIn: parent
            text: root.keyboard ? root.keyboard.label : ""
            color: Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.px(10)
            font.letterSpacing: 1
          }
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.keyboardAction(root.how(mouse)) }
        }
      }

      // Microphone: 声, red with a stroke through it when muted.
      Item {
        visible: !!root.mic
        width: micText.implicitWidth
        height: root.barHeight
        Text {
          id: micText
          anchors.verticalCenter: parent.verticalCenter
          text: "声"
          color: root.mic && root.mic.muted ? Ink.seal : Ink.inkDim
          font.family: Type.jp
          font.pixelSize: root.glyphSize
        }
        Rectangle {
          visible: !!(root.mic && root.mic.muted)
          anchors.centerIn: micText
          width: micText.implicitWidth + 2
          height: 1
          rotation: -35
          color: Ink.seal
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.micAction(root.how(mouse)) }
          onWheel: function(wheel) { root.micAction(wheel.angleDelta.y > 0 ? "up" : "down") }
        }
      }
    }

    // The folded tray.
    Item {
      visible: root.trayFolded
      width: foldRow.implicitWidth
      height: root.barHeight
      Row {
        id: foldRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(2)
        Text { anchors.verticalCenter: parent.verticalCenter; text: "盆"; color: Ink.inkDim; font.family: Type.jp; font.pixelSize: root.glyphSize }
        Text { anchors.bottom: parent.bottom; text: String(root.tray.length); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.px(8) }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.trayOpen = true
      }
    }

    // The tray: each icon inked in the dim tier; a letter when there's no
    // icon to ink.
    Repeater {
      model: root.trayFolded ? [] : root.tray
      Item {
        id: cell
        required property var modelData
        width: Type.px(16)
        height: root.barHeight

        Image {
          id: icon
          visible: false
          anchors.centerIn: parent
          width: Type.px(15)
          height: width
          sourceSize: Qt.size(width * 2, height * 2)
          source: cell.modelData.icon
          fillMode: Image.PreserveAspectFit
          smooth: true
        }
        MultiEffect {
          visible: icon.status === Image.Ready
          anchors.fill: icon
          source: icon
          colorization: 1
          colorizationColor: Ink.inkDim
          brightness: 0.25
        }
        Text {
          visible: icon.status !== Image.Ready
          anchors.centerIn: parent
          text: cell.modelData.letter
          color: Ink.inkMuted
          font.family: Type.text
          font.pixelSize: Type.px(11)
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.trayAction(cell.modelData.id, root.how(mouse), cell) }
          onWheel: function(wheel) { root.trayAction(cell.modelData.id, wheel.angleDelta.y > 0 ? "up" : "down", cell) }
        }
      }
    }
  }
}
