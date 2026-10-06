import QtQuick
import "../core"

// Everything drawn inside the bar window, for one screen. Pure QtQuick: it
// takes the resolved style and plain data, so tests/harness can render it
// without a running shell. Bar.qml feeds it live data.
Item {
  id: root

  // Resolved style (core/Style.js resolve()).
  property var style: ({})
  property date now: new Date()
  property int workspace: 1

  readonly property int barHeight: Type.px(style.height || 40)
  readonly property bool atBottom: style.position === "bottom"

  implicitHeight: barHeight

  Rectangle {
    id: paper
    anchors.fill: parent
    color: root.style.surface === "glass" ? Ink.paperAt(0.74) : Ink.paper
  }

  // Left zone: where you are.
  Row {
    id: left
    anchors.left: parent.left
    anchors.leftMargin: Type.px(6)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(14)

    Seal {
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.seal || "stamp"
      glyph: root.style.sealGlyph || "印"
      workspace: root.workspace
      size: root.barHeight <= Type.px(32) ? Type.px(22) : Type.px(26)
    }
  }

  // Centre: when. Anchored to the exact screen centre.
  Clock {
    anchors.centerIn: parent
    mode: root.style.clock || "stacked"
    now: root.now
    barHeight: root.barHeight
  }

  // Edge: a hairline on the side facing the desktop.
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: root.atBottom ? undefined : parent.bottom
    anchors.top: root.atBottom ? parent.top : undefined
    height: 1
    color: Ink.line
  }
}
