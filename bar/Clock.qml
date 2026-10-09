pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Season.js" as Season

// The clock 時, in three faces (docs/COMPONENTS.md):
//   stacked  serif time, the day and date stacked in small mono beside it
//   inline   serif time with a red colon and a small-caps date on one line
//   mono     all mono, for an instrument look
//   season   Shōji's: serif time, the date, and the solar term (`season`:
//            off | kanji | english; off leaves the time and the date)
// timeFormat follows Omarchy's own clock (`format` on omarchy.clock in
// shell.json), so a 12-hour setting carries over.
Item {
  id: root

  property string mode: "stacked"
  property date now: new Date()
  property int barHeight: 40
  property string timeFormat: "HH:mm"
  property string season: "kanji"
  readonly property string seasonLabel: Season.label(now, season)

  signal clicked()

  readonly property bool compact: barHeight <= Type.px(32)
  readonly property bool tall: barHeight >= Type.px(44)
  readonly property string time: Qt.formatTime(now, timeFormat)
  // Everything before and after the first colon, so the colon can be inked.
  readonly property int colon: time.indexOf(":")
  readonly property string before: colon < 0 ? time : time.slice(0, colon)
  readonly property string after: colon < 0 ? "" : time.slice(colon + 1)

  implicitWidth: face.implicitWidth + Type.px(mode === "stacked" ? 32 : 24)
  implicitHeight: barHeight

  function timeMarkup(colonColor) {
    if (colon < 0) return time
    return before + "<font color='" + colonColor + "'>:</font>" + after
  }

  Loader {
    id: face
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -1
    sourceComponent: root.mode === "inline" ? inlineFace : root.mode === "mono" ? monoFace : root.mode === "season" ? seasonFace : stackedFace
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  // ------------------------------------------------------------ stacked
  Component {
    id: stackedFace

    Row {
      spacing: Type.px(10)

      FadeText {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: root.timeMarkup(Ink.inkMuted)
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(root.compact ? 18 : root.tall ? 24 : 22)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(root.compact ? 18 : root.tall ? 24 : 22))
        font.letterSpacing: 0.2
        // Tabular figures: the time doesn't shift as its digits change.
        font.features: { "tnum": 1, "lnum": 1 }
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(2)
        visible: !root.compact
        Text {
          text: Qt.formatDate(root.now, "ddd").toUpperCase()
          color: Ink.inkDim
          font.family: Type.mono
          font.pixelSize: Type.label
          font.weight: Font.Medium
          font.letterSpacing: Type.trackLabel
        }
        Text {
          text: Qt.formatDate(root.now, "dd MMM").toUpperCase()
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.label
          font.weight: Type.labelWeight
          font.letterSpacing: Type.trackLabel
        }
      }

      // At 32 px the date sits beside the time instead of stacking.
      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.compact
        text: Qt.formatDate(root.now, "ddd dd MMM").toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackLabel
      }
    }
  }

  // ------------------------------------------------------------ inline
  Component {
    id: inlineFace

    Row {
      spacing: Type.px(10)

      FadeText {
        id: inlineTime
        textFormat: Text.StyledText
        text: root.timeMarkup(Ink.seal)
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(root.compact ? 18 : root.tall ? 24 : 22)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(root.compact ? 18 : root.tall ? 24 : 22))
        font.letterSpacing: 0.3
        font.features: { "tnum": 1, "lnum": 1 }
      }

      Text {
        anchors.baseline: inlineTime.baseline
        text: Qt.formatDate(root.now, "ddd d MMM").toLowerCase()
        color: Ink.inkMuted
        font.family: Type.display
        font.pixelSize: Type.px(13)
        font.weight: Font.Normal
        font.capitalization: Font.SmallCaps
        font.letterSpacing: 1.2
        font.variableAxes: Type.axes(Type.px(13))
      }
    }
  }

  // ------------------------------------------------------------ mono
  Component {
    id: monoFace

    Row {
      spacing: Type.px(10)

      FadeText {
        id: monoTime
        text: root.time
        color: Ink.ink
        font.family: Type.mono
        font.pixelSize: Type.px(13)
        font.letterSpacing: 1
      }

      Text {
        anchors.baseline: monoTime.baseline
        text: Qt.formatDate(root.now, "ddd dd MMM").toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackLabel
      }
    }
  }

  // ------------------------------------------------------------ season
  Component {
    id: seasonFace

    Row {
      spacing: Type.px(10)
      FadeText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: root.time
        color: Ink.ink
        font.family: Type.display; font.pixelSize: Type.px(20); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(20), 400)
        font.features: { "tnum": 1, "lnum": 1 }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDate(root.now, "ddd d MMM")
        color: Ink.ink3
        font.family: Type.text; font.pixelSize: Type.px(13)
      }
      Rectangle { visible: root.seasonLabel !== ""; anchors.verticalCenter: parent.verticalCenter; width: 1; height: Type.px(14); color: Ink.kLine }
      Text {
        visible: root.seasonLabel !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: root.seasonLabel
        color: Ink.ink2
        font.family: root.season === "kanji" ? Type.jp : Type.text
        font.pixelSize: Type.px(13)
        font.letterSpacing: root.season === "kanji" ? Type.px(1) : 0
      }
    }
  }
}
