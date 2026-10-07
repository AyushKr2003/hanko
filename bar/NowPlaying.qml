import QtQuick
import "../core"

// Now playing 再生 (docs/COMPONENTS.md):
//   cell       NOW 再生 over artist — song
//   underline  the song in serif italic; its underline is the progress bar
//   none       hidden
// Click plays or pauses, middle-click skips, scroll moves between tracks.
Item {
  id: root

  property string mode: "underline"
  // { title, artist, progress, playing } or null
  property var media: null
  property int barHeight: 40
  property real maxWidth: Type.px(mode === "cell" ? 300 : 260)

  signal action(string name)

  readonly property bool compact: barHeight <= Type.px(32)

  visible: mode !== "none" && media !== null
  implicitWidth: visible ? Math.min(maxWidth, mode === "cell" ? (compact ? oneLine.implicitWidth : cell.implicitWidth) : under.implicitWidth) : 0
  implicitHeight: barHeight
  clip: true

  function esc(s) {
    return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  // Paused media dims to the next ink tier.
  readonly property color songInk: media && media.playing ? Ink.ink : Ink.inkDim

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { root.action(mouse.button === Qt.MiddleButton ? "next" : "playPause") }
    onWheel: function(wheel) { root.action(wheel.angleDelta.y > 0 ? "previous" : "next") }
  }

  // ------------------------------------------------------------ underline
  Column {
    id: under
    visible: root.mode === "underline"
    anchors.verticalCenter: parent.verticalCenter
    leftPadding: Type.px(6)
    rightPadding: Type.px(6)
    spacing: Type.px(3)

    Row {
      id: line
      spacing: Type.px(5)
      readonly property real room: root.maxWidth - Type.px(12)

      Text {
        id: song
        anchors.baseline: artist.baseline
        width: Math.min(implicitWidth, line.room * 0.62)
        elide: Text.ElideRight
        text: root.media ? root.media.title : ""
        color: root.songInk
        font.family: Type.display
        font.italic: true
        font.pixelSize: Type.px(14)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(14))
      }
      Text {
        id: artist
        visible: text !== ""
        width: Math.min(implicitWidth, line.room - song.width - line.spacing)
        elide: Text.ElideRight
        text: root.media && root.media.artist ? "· " + root.media.artist : ""
        color: Ink.inkDim
        font.family: Type.text
        font.pixelSize: Type.value
      }
    }

    // The progress bar is the underline: a hairline with an ink run and a tick.
    Item {
      width: line.width
      height: 1
      Rectangle { anchors.fill: parent; color: Ink.line }
      Rectangle {
        id: run
        width: Math.round(parent.width * (root.media ? root.media.progress : 0))
        height: 1
        color: Ink.ink
      }
      Rectangle { x: run.width - 1; y: -2; width: 1; height: 5; color: Ink.ink; visible: run.width > 0 }
    }
  }

  // ------------------------------------------------------------ cell
  Column {
    id: cell
    visible: root.mode === "cell" && !root.compact
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -1
    leftPadding: Type.px(12)
    rightPadding: Type.px(12)
    spacing: 1

    Row {
      spacing: Type.px(6)
      Text {
        text: "NOW"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackLabel
      }
      Text {
        text: "再生"
        color: Ink.inkMuted
        font.family: Type.jp
        font.pixelSize: Type.gloss
      }
    }
    Text {
      width: Math.min(implicitWidth, root.maxWidth - Type.px(24))
      elide: Text.ElideRight
      textFormat: Text.StyledText
      text: root.media ? root.esc(root.media.artist) + " <font color='" + Ink.inkMuted + "'>— " + root.esc(root.media.title) + "</font>" : ""
      color: root.songInk
      font.family: Type.text
      font.pixelSize: Type.value
      font.weight: Type.valueWeight
      font.variableAxes: Type.valueAxes
    }
  }

  Row {
    id: oneLine
    visible: root.mode === "cell" && root.compact
    anchors.verticalCenter: parent.verticalCenter
    leftPadding: Type.px(12)
    rightPadding: Type.px(12)
    spacing: Type.px(7)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "NOW"
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackLabel
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, root.maxWidth - Type.px(60))
      elide: Text.ElideRight
      textFormat: Text.StyledText
      text: root.media ? root.esc(root.media.artist) + " <font color='" + Ink.inkMuted + "'>— " + root.esc(root.media.title) + "</font>" : ""
      color: root.songInk
      font.family: Type.text
      font.pixelSize: Type.value
      font.weight: Type.valueWeight
      font.variableAxes: Type.valueAxes
    }
  }
}
