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
  // { title, artist, progress, playing } or null.
  property var media: null
  property string timeFormat: "HH:mm"
  // services/Status: core/Status.js shapes, or null when absent.
  property var volume: null
  property var network: null
  property var battery: null
  property var brightness: null
  property var notifications: []
  property bool dnd: false

  readonly property int workspace: {
    for (var i = 0; i < spaces.length; i++) if (spaces[i].active) return spaces[i].id
    return 1
  }

  signal sealClicked(int button)
  signal workspaceActivated(int id)
  signal workspaceStepped(int delta)
  signal mediaAction(string name)
  signal clockClicked()
  signal statusAction(string name, string how)
  signal inboxAction(string how)

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
      // Never run under the centre clock or into the right zone.
      maxWidth: Math.max(0, (root.clockRight ? right.x : centreClock.x) - left.x - x - Type.px(24))
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

  readonly property bool clockRight: style.clockAt === "right"

  // Centre: when. Anchored to the exact screen centre, or left empty on
  // purpose when the clock joins the right zone.
  Clock {
    id: centreClock
    anchors.centerIn: parent
    visible: !root.clockRight
    mode: root.style.clock || "stacked"
    now: root.now
    timeFormat: root.timeFormat
    barHeight: root.barHeight
    onClicked: root.clockClicked()
  }

  // Right zone: how things are. Media, status, notifications, then the
  // clock when it sits on the right; a divider goes before each part that
  // has something showing before it.
  Row {
    id: right
    anchors.right: parent.right
    anchors.rightMargin: Type.px(10)
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    layoutDirection: Qt.LeftToRight

    NowPlaying {
      id: media
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.media || "underline"
      media: root.media
      barHeight: root.barHeight
      onAction: function(name) { root.mediaAction(name) }
    }

    Divider { ruled: root.ruled; visible: status.visible && media.visible }

    StatusRow {
      id: status
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.status || "cells"
      meters: root.style.meters || "ticks"
      ruled: root.ruled
      barHeight: root.barHeight
      volume: root.volume
      network: root.network
      battery: root.battery
      brightness: root.brightness
      onAction: function(name, how) { root.statusAction(name, how) }
    }

    Divider { ruled: root.ruled; visible: media.visible || status.visible }

    Inbox {
      id: inbox
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.notif || "stamps"
      notifications: root.notifications
      dnd: root.dnd
      barHeight: root.barHeight
      onAction: function(how) { root.inboxAction(how) }
    }

    Divider { ruled: root.ruled; visible: rightClock.visible }

    Clock {
      id: rightClock
      anchors.verticalCenter: parent.verticalCenter
      visible: root.clockRight
      mode: root.style.clock || "stacked"
      now: root.now
      timeFormat: root.timeFormat
      barHeight: root.barHeight
      onClicked: root.clockClicked()
    }
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
