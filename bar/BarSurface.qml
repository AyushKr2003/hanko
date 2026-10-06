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
  // Hypr.spacesFor(screen): [{ id, active, urgent, count, windows }]
  property var spaces: []
  // { cls, title } of the focused window, or null.
  property var activeWindow: null
  property string home: ""

  readonly property int workspace: {
    for (var i = 0; i < spaces.length; i++) if (spaces[i].active) return spaces[i].id
    return 1
  }

  signal sealClicked(int button)
  signal workspaceActivated(int id)
  signal workspaceStepped(int delta)

  readonly property int barHeight: Type.px(style.height || 40)
  readonly property bool atBottom: style.position === "bottom"

  implicitHeight: barHeight

  Rectangle {
    id: paper
    anchors.fill: parent
    color: root.style.surface === "glass" ? Ink.paperAt(0.74) : Ink.paper
  }

  readonly property bool ruled: style.rules !== "off"

  // Left zone: where you are. Groups are ruled off by hairlines, or by
  // space alone when dividers are off.
  Row {
    id: left
    anchors.left: parent.left
    anchors.leftMargin: Type.px(6)
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    spacing: 0

    Seal {
      id: seal
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.seal || "stamp"
      glyph: root.style.sealGlyph || "印"
      workspace: root.workspace
      size: root.barHeight <= Type.px(32) ? Type.px(22) : Type.px(26)

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) { root.sealClicked(mouse.button) }
        onWheel: function(wheel) { root.workspaceStepped(wheel.angleDelta.y > 0 ? -1 : 1) }
      }
    }

    Divider { ruled: root.ruled; visible: seal.visible && spacesView.visible }

    Workspaces {
      id: spacesView
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.spaces || "layout"
      spaces: root.spaces
      barHeight: root.barHeight
      onActivated: function(id) { root.workspaceActivated(id) }
      onStepped: function(delta) { root.workspaceStepped(delta) }
    }

    Divider { ruled: root.ruled; visible: titleView.visible && (seal.visible || spacesView.visible) }

    WindowTitle {
      id: titleView
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.title || "byline"
      appClass: root.activeWindow ? root.activeWindow.cls : ""
      title: root.activeWindow ? root.activeWindow.title : ""
      home: root.home
      barHeight: root.barHeight
      // Never run under the centre clock.
      maxWidth: Math.max(0, root.width / 2 - left.x - x - Type.px(140))
    }
  }

  // A hairline between groups, or a plain gap when dividers are off.
  component Divider: Item {
    id: divider
    property bool ruled: true
    width: ruled ? Type.px(12) * 2 + 1 : Type.px(14)
    height: parent ? parent.height : 0
    Rectangle {
      visible: divider.ruled
      anchors.horizontalCenter: parent.horizontalCenter
      y: Type.px(8)
      width: 1
      height: parent.height - Type.px(18)
      color: Ink.line
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
