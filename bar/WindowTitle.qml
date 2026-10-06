import QtQuick
import "../core"
import "../core/Title.js" as TitleJs

// Window title 窓 (docs/COMPONENTS.md):
//   cell    the app as a tracked mono label over the title
//   byline  the app in serif italic like a byline; title in grotesk
//   none    hidden
// Folders recede to a fainter ink so the file stays the thing you read.
Item {
  id: root

  property string mode: "byline"
  property string appClass: ""
  property string title: ""
  property string home: ""
  property int barHeight: 40
  property real maxWidth: Type.px(520)

  readonly property var parts: TitleJs.describe(appClass, TitleJs.tildify(title, home))
  readonly property bool compact: barHeight <= Type.px(32)
  readonly property bool empty: parts.app === "" && parts.head === "" && parts.leaf === ""

  visible: mode !== "none" && !empty
  implicitWidth: visible ? Math.min(maxWidth, (mode === "byline" ? byline.implicitWidth : compact ? oneLine.implicitWidth : cell.implicitWidth)) : 0
  implicitHeight: barHeight
  clip: true

  // "nvim · ~/code/hanko/Bar.qml" with the folders in a fainter ink.
  function styledTitle(headColor, dirColor, leafColor) {
    var p = parts
    var out = []
    if (p.head !== "") out.push("<font color='" + headColor + "'>" + esc(p.head) + "</font>")
    if (p.dir !== "" || p.leaf !== "")
      out.push("<font color='" + dirColor + "'>" + esc(p.dir) + "</font><font color='" + leafColor + "'>" + esc(p.leaf) + "</font>")
    return out.join(mode === "byline" ? " · " : "  ")
  }

  function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  // ------------------------------------------------------------ byline
  Row {
    id: byline
    visible: root.mode === "byline"
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(9)

    Text {
      id: app
      anchors.baseline: rest.baseline
      text: root.parts.app
      visible: text !== ""
      color: Ink.ink
      font.family: Type.display
      font.italic: true
      font.pixelSize: Type.px(15)
      font.variableAxes: { "opsz": 18, "wght": 400 }
    }

    Text {
      id: rest
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, root.maxWidth - app.implicitWidth - byline.spacing)
      elide: Text.ElideRight
      textFormat: Text.StyledText
      text: root.styledTitle(Ink.inkMuted, Ink.inkMuted, Ink.inkDim)
      color: Ink.inkMuted
      font.family: Type.text
      font.pixelSize: Type.px(13)
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
        text: root.parts.app.toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.px(8)
        font.letterSpacing: 1.6
      }
      Text {
        text: "窓"
        color: Ink.inkFaint
        font.family: Type.jp
        font.pixelSize: Type.px(8.5)
      }
    }

    Text {
      width: Math.min(implicitWidth, root.maxWidth - Type.px(24))
      elide: Text.ElideRight
      textFormat: Text.StyledText
      text: root.styledTitle(Ink.ink, Ink.inkMuted, Ink.ink)
      color: Ink.ink
      font.family: Type.text
      font.pixelSize: Type.px(12.5)
    }
  }

  // At 32 px the cell collapses to one line: label, then value.
  Row {
    id: oneLine
    visible: root.mode === "cell" && root.compact
    anchors.verticalCenter: parent.verticalCenter
    leftPadding: Type.px(12)
    spacing: Type.px(7)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.parts.app.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(8)
      font.letterSpacing: 1.6
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.StyledText
      text: root.styledTitle(Ink.ink, Ink.inkMuted, Ink.ink)
      color: Ink.ink
      font.family: Type.text
      font.pixelSize: Type.px(12.5)
    }
  }
}
