pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Style.js" as S

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
  property var bluetooth: null
  property var notifications: []
  property bool dnd: false
  // Hosted widgets: [{ id, key, settings, component, pluginId }] (Bar.qml
  // hostedEntries) and the host they talk to (Bar.qml, null in the harness).
  property var hosted: []
  property var host: null
  // Hanko's own marks (core/Extras.js shapes): indicators, keyboard, mic, tray.
  property var indicators: []
  property var keyboard: null
  property var mic: null
  property var tray: []

  // Parts you hid on the Widgets page (style.hidden, core/Style.js).
  function shown(part) { return !style.hidden || style.hidden.indexOf(part) < 0 }
  // Hanko's own marks and the hosted widgets, less the hidden ones.
  // `indicators: active` keeps only those that are on (a list without
  // `on` is all on).
  readonly property var shownIndicators: indicators.filter(function(i) {
    return root.shown("indicator:" + i.key) && (root.style.indicators !== "active" || i.on !== false)
  })
  readonly property var shownTray: shown("tray") ? tray.filter(function(t) { return root.shown("tray:" + t.id) }) : []
  readonly property var shownHosted: hosted.filter(function(h) { return root.shown("hosted:" + h.id) })

  readonly property int workspace: {
    for (var i = 0; i < spaces.length; i++) if (spaces[i].active) return spaces[i].id
    return 1
  }

  signal sealClicked(int button)
  signal workspaceActivated(int id)
  signal workspaceStepped(int delta)
  signal overviewRequested()
  signal mediaAction(string name)
  signal clockClicked()
  signal statusAction(string name, string how)
  signal inboxAction(string how)
  signal indicatorAction(string key, string how)
  signal keyboardAction(string how)
  signal micAction(string how)
  signal trayAction(string id, string how, Item cell)
  // The rod was pulled away from the bar (edge: rod | rodrule), at x.
  signal edgePulled(real x)

  // The right zone's cells in order, for `togglePanelAt right N`.
  readonly property var rightCells: {
    var out = []
    var items = status.visible ? status.items : []
    for (var i = 0; i < items.length; i++) out.push(items[i].key)
    for (var h = 0; h < shownHosted.length; h++) out.push("hosted:" + shownHosted[h].id)
    if (inbox.visible) out.push("notif")
    if (rightClock.visible) out.push("clock")
    return out
  }

  // Where a cell sits along the bar ({ x, width } in this item), so a sheet
  // can drop from under it; null when the cell isn't showing.
  function anchorFor(cell) {
    var item = cell === "clock" ? (clockRight ? rightClock : centreClock)
      : cell === "notif" ? inbox
      : status.cellFor(cell)
    if (!item || !item.visible) return null
    var p = item.mapToItem(root, 0, 0)
    return { x: Math.round(p.x), width: Math.round(item.width) }
  }

  // The cell (clock, a status reading, notif) under x, or "".
  function cellAt(x) {
    var cells = rightCells.concat(centreClock.visible ? ["clock"] : [])
    for (var i = 0; i < cells.length; i++) {
      var a = anchorFor(cells[i])
      if (a && x >= a.x && x < a.x + a.width) return cells[i]
    }
    return ""
  }

  readonly property int barHeight: Type.px(style.height || 40)
  readonly property bool atBottom: style.position === "bottom"
  // Inset: the window floats 8 px off the screen (BarWindow) and the paper
  // carries a hairline frame. Glass: only the paper is translucent; the
  // seal, stamps and inverted plates draw their own opaque fills.
  readonly property bool inset: style.surface === "inset"

  implicitHeight: barHeight

  Rectangle {
    id: paper
    anchors.fill: parent
    color: root.style.surface === "glass" ? Ink.paperAt(0.74) : Ink.paper
    radius: root.inset ? 7 : 0
    border.width: root.inset ? 1 : 0
    border.color: Ink.line
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
      mode: root.shown("seal") ? root.style.seal || "stamp" : "none"
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
      mode: root.shown("spaces") ? root.style.spaces || "layout" : "none"
      spaces: root.spaces
      barHeight: root.barHeight
      onActivated: function(id) { root.workspaceActivated(id) }
      onStepped: function(delta) { root.workspaceStepped(delta) }
      onOverviewRequested: root.overviewRequested()
    }

    Divider { ruled: root.ruled; visible: titleView.visible && (seal.visible || spacesView.visible) }

    WindowTitle {
      id: titleView
      anchors.verticalCenter: parent.verticalCenter
      mode: root.shown("title") ? root.style.title || "byline" : "none"
      appClass: root.activeWindow ? root.activeWindow.cls : ""
      title: root.activeWindow ? root.activeWindow.title : ""
      home: root.home
      barHeight: root.barHeight
      // Never run under the centre clock or into the right zone.
      maxWidth: Math.max(0, (centreClock.visible ? centreClock.x : right.x) - left.x - x - Type.px(24))
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
      anchors.verticalCenter: parent.verticalCenter
      width: 1
      height: Math.round(parent.height * 0.42)
      color: Ink.alpha(Ink.bone, Ink.light ? 0.16 : 0.13)
    }
  }

  readonly property bool clockRight: style.clockAt === "right"

  // Room the right zone has for what is playing: from the centre clock (or
  // the window title's minimum when the clock is on the right) to the
  // right edge, less everything else in the zone and its dividers.
  readonly property real zoneStart: !centreClock.visible ? width * 0.45 : centreClock.x + centreClock.width + Type.px(24)
  readonly property real fixedRight: status.implicitWidth + (inbox.visible ? inbox.implicitWidth : 0)
    + (rightClock.visible ? rightClock.implicitWidth : 0) + 4 * (Type.px(12) * 2 + 1)
  // Room for the marks and hosted widgets, which never cross the clock.
  readonly property real extrasRoom: Math.max(0, width - Type.px(10) - zoneStart - fixedRight)
  readonly property real mediaRoom: extrasRoom - extras.width - marks.nameWidth
  // What the hosted widgets would take if they all showed (collapsed ones
  // included), for deciding when the tray folds: the tray folds before any
  // widget is dropped.
  readonly property real hostedWidth: {
    var w = 0
    for (var i = 0; i < hostedRow.children.length; i++) {
      var c = hostedRow.children[i]
      if (c.naturalWidth !== undefined) w += c.naturalWidth
    }
    return w
  }

  // Centre: when. Anchored to the exact screen centre, or left empty on
  // purpose when the clock joins the right zone.
  Clock {
    id: centreClock
    anchors.centerIn: parent
    visible: !root.clockRight && root.shown("clock")
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
      // What is playing gives way first when the right zone fills up, and
      // goes when there's no real room left for it.
      maxWidth: Math.min(Type.px(mode === "cell" ? 300 : 260), root.mediaRoom)
      visible: root.media !== null && mode !== "none" && root.mediaRoom >= Type.px(90)
      mode: root.shown("media") ? root.style.media || "underline" : "none"
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
      volume: root.shown("volume") ? root.volume : null
      network: root.shown("network") ? root.network : null
      battery: root.shown("battery") ? root.battery : null
      brightness: root.shown("brightness") ? root.brightness : null
      btStyle: root.style.bluetooth || "device"
      bluetooth: root.style.bluetooth === "off" || !root.shown("bluetooth") ? null : root.bluetooth
      onAction: function(name, how) { root.statusAction(name, how) }
    }

    Divider { ruled: root.ruled; visible: extras.implicitWidth > 0 && (media.visible || status.visible) }

    // The blank the hovered indicator's name opens over (bar/Marks.qml):
    // the zone is anchored right, so it moves what is left of it, never
    // the stamps.
    Item { width: marks.nameWidth; height: root.barHeight; visible: width > 0 }

    // Hanko's own marks, then other widgets from Omarchy's bar layout, in
    // Hanko's ink. One row, so the zone knows how much room they take.
    Item {
      id: extras
      height: root.barHeight
      width: Math.min(extrasRow.implicitWidth, root.extrasRoom)
      implicitWidth: width
      clip: extrasRow.implicitWidth > width

    Row {
      id: extrasRow
      height: root.barHeight

      Marks {
        id: marks
        anchors.verticalCenter: parent.verticalCenter
        indicators: root.shownIndicators
        markStyle: root.style.indicatorStyle || "icon"
        keyboard: root.shown("keyboard") ? root.keyboard : null
        mic: root.shown("mic") ? root.mic : null
        tray: root.shownTray
        barHeight: root.barHeight
        compactTray: marks.fullWidth + root.hostedWidth > root.extrasRoom
        // The zone's spare room, or the real gap before it when that is
        // wider (the room above is reckoned with every divider showing).
        nameRoom: Math.max(0, root.extrasRoom - extras.width, right.x - root.zoneStart + marks.nameWidth)
        onIndicatorAction: function(key, how) { root.indicatorAction(key, how) }
        onKeyboardAction: function(how) { root.keyboardAction(how) }
        onMicAction: function(how) { root.micAction(how) }
        onTrayAction: function(id, how, cell) { root.trayAction(id, how, cell) }
      }

      Row {
        id: hostedRow
        height: root.barHeight
      Repeater {
        model: root.shownHosted
        Row {
          id: hostedCell
          required property var modelData
          required property int index
          readonly property real naturalWidth: slot.implicitWidth > 0 ? slot.implicitWidth + Type.px(12) * 2 + 1 : 0
          height: root.barHeight
          Divider {
            id: slotDivider
            ruled: root.ruled
            visible: slot.implicitWidth > 0 && slot.fits && (hostedCell.index > 0 || marks.visible)
          }
          HostedSlot {
            id: slot
            anchors.verticalCenter: parent.verticalCenter
            entry: hostedCell.modelData
            component: hostedCell.modelData.component
            pluginId: hostedCell.modelData.pluginId || hostedCell.modelData.id
            host: root.host
            barHeight: root.barHeight
            position: root.atBottom ? "bottom" : "top"
            // Measured from the cells before it only, so it can't loop.
            fits: marks.width + hostedCell.x + (Type.px(12) * 2 + 1) + implicitWidth <= root.extrasRoom
          }
        }
      }
      }
    }
    }

    Divider { ruled: root.ruled; visible: inbox.visible && (media.visible || status.visible || extras.implicitWidth > 0) }

    Inbox {
      id: inbox
      visible: root.shown("notif")
      anchors.verticalCenter: parent.verticalCenter
      mode: root.style.notif || "stamps"
      notifications: root.notifications
      dnd: root.dnd
      barHeight: root.barHeight
      onAction: function(how) { root.inboxAction(how) }
    }

    Divider { ruled: root.ruled; visible: rightClock.visible && (media.visible || status.visible || extras.implicitWidth > 0 || inbox.visible) }

    Clock {
      id: rightClock
      anchors.verticalCenter: parent.verticalCenter
      visible: root.clockRight && root.shown("clock")
      mode: root.style.clock || "stacked"
      now: root.now
      timeFormat: root.timeFormat
      barHeight: root.barHeight
      onClicked: root.clockClicked()
    }
  }

  // Edge: the side facing the desktop (hairline, day rule, rod or both),
  // inside the frame when inset.
  Edge {
    shown: root.shown("edge")
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: root.atBottom ? undefined : parent.bottom
    anchors.top: root.atBottom ? parent.top : undefined
    anchors.margins: root.inset ? 1 : 0
    mode: root.style.edge || "rodrule"
    now: root.now
    atBottom: root.atBottom
    inset: root.inset
    onPulled: function(x) { root.edgePulled(x) }
  }
}
