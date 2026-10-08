pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Title.js" as Title
import "../core/Season.js" as Season
import "parts"

// The bar a Kata design draws (docs/kata): seal · desks · window | time
// (and the season) | what is playing · Wi-Fi · volume · battery, all from
// parts dressed by `skin` (core/Skin.js). Pure like BarSurface: the same
// data in, the same signals out, and the same anchorFor / cellAt /
// rightCells, so BarWindow can swap the two and the sheets and the scroll
// still open under the right cell.
Item {
  id: root

  property var skin: ({})
  property var style: ({})          // the Typeset style: height, sealGlyph, hidden
  property date now: new Date()
  property var spaces: []
  property var activeWindow: null
  property string home: ""
  property var media: null
  property string timeFormat: "HH:mm"
  property var volume: null
  property var network: null
  // core/Blue.js cell(): { name, enabled, connected, level, devices, needsYou }; null without an adapter.
  property var bluetooth: null
  property var battery: null
  property var notifications: []
  property bool dnd: false
  // The harness can point at a cell: seal | clock | network | volume | battery.
  property string hoverCell: ""

  signal sealClicked(int button)
  signal workspaceActivated(int id)
  signal workspaceStepped(int delta)
  signal overviewRequested()
  signal mediaAction(string name)
  signal clockClicked()
  signal statusAction(string name, string how)
  signal inboxAction(string how)

  function shown(part) { return !style.hidden || style.hidden.indexOf(part) < 0 }

  readonly property int barHeight: Type.px(style.height || 40)
  readonly property int unread: notifications ? notifications.length : 0
  readonly property string surfaceKind: skin.surface || "paper"
  readonly property var kanji: ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

  implicitHeight: barHeight

  // ── the cells, for sheets and Omarchy's hotkeys ──────────────────────
  readonly property var rightCells: {
    var out = []
    if (netCell.visible) out.push("network")
    if (btCell.visible) out.push("bluetooth")
    if (volCell.visible) out.push("volume")
    if (batCell.visible) out.push("battery")
    if (sealCell.visible) out.push("notif")
    return out
  }
  function cellItem(cell) {
    return cell === "clock" ? clockCell : cell === "notif" ? sealCell
      : cell === "network" ? netCell : cell === "bluetooth" ? btCell : cell === "volume" ? volCell : cell === "battery" ? batCell : null
  }
  function anchorFor(cell) {
    var item = cellItem(cell)
    if (!item || !item.visible) return null
    var p = item.mapToItem(root, 0, 0)
    return { x: Math.round(p.x), width: Math.round(item.width) }
  }
  function cellAt(x) {
    var cells = rightCells.concat(["clock"])
    for (var i = 0; i < cells.length; i++) {
      var a = anchorFor(cells[i])
      if (a && x >= a.x && x < a.x + a.width) return cells[i]
    }
    return ""
  }

  // ── the pointer: what you are on, or the harness's hoverCell ─────────
  property var hovered: null
  readonly property var pointed: hovered || cellItem(hoverCell)
  readonly property var cellNames: ({ notif: "Letters", clock: "Calendar", network: root.network ? root.network.name : "Network", bluetooth: "Bluetooth", volume: "Sound", battery: "Battery" })

  // ── the bar's own paper ──────────────────────────────────────────────
  Rectangle { visible: root.surfaceKind === "card"; y: root.height; width: root.width; height: 1; color: Ink.shade }
  Rectangle { visible: root.surfaceKind === "card"; y: root.height + 1; width: root.width; height: 2; color: Ink.shade2 }
  Rectangle {
    anchors.fill: parent
    color: Ink.paper
    Fibres {
      anchors.fill: parent
      kind: root.surfaceKind === "card" ? "grain" : "washi"
      level: root.surfaceKind === "paper" ? 0 : Math.max(1, root.skin.grain || 0)
    }
  }
  Rectangle { y: root.height - 1; width: root.width; height: 1; color: root.surfaceKind === "card" ? Ink.edge : Ink.kLine }

  component Cell: Item {
    id: cell
    property string name: ""
    height: root.barHeight
    HoverHandler { onHoveredChanged: root.hovered = hovered ? cell : (root.hovered === cell ? null : root.hovered) }
  }
  component Label: Text {
    color: Ink.ink2
    font.family: Type.text
    font.pixelSize: Type.px(13)
    font.weight: Font.Medium
    font.variableAxes: Type.valueAxes
    verticalAlignment: Text.AlignVCenter
  }

  // ── left: the seal, the desks, the window ────────────────────────────
  Row {
    id: left
    x: Type.px(10)
    height: root.barHeight

    Cell {
      id: sealCell
      name: "notif"
      visible: root.shown("seal")
      width: sealRow.implicitWidth + Type.px(18)
      Row {
        id: sealRow
        anchors.centerIn: parent
        spacing: Type.px(6)
        KataSeal {
          anchors.verticalCenter: parent.verticalCenter
          skin: root.skin
          glyph: root.style.sealGlyph || "鑑"
          on: root.unread > 0 && !root.dnd
          size: Type.px(24)
        }
        Text {
          visible: root.unread > 0 && !root.dnd
          anchors.verticalCenter: parent.verticalCenter
          text: String(root.unread)
          color: Ink.seal
          font.family: Type.display; font.pixelSize: Type.px(16); font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(16), 400, root.skin.soft)
        }
      }
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        // The seal is Letters in every design; right-click keeps the Omarchy menu.
        onClicked: function(mouse) {
          if (mouse.button === Qt.LeftButton) root.inboxAction("click")
          else if (mouse.button === Qt.MiddleButton) root.inboxAction("middle")
          else root.sealClicked(Qt.LeftButton)
        }
      }
    }

    Item {
      id: desks
      visible: root.shown("spaces")
      width: deskRow.implicitWidth
      height: root.barHeight
      readonly property var list: (root.spaces || []).filter(function(s) { return s.id > 0 && s.id <= 10 })
      property Item current: null

      // the current desk's mark: an ink plate, or a brush mark under it (wash)
      Rectangle {
        visible: root.skin.select !== "wash" && desks.current !== null
        x: desks.current ? desks.current.x : 0
        y: (root.barHeight - height) / 2
        width: Type.px(26); height: Type.px(24)
        radius: root.skin.radiusChip || 0
        color: Ink.ink
        Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(root.skin.open || 200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] } }
      }
      PointerMark {
        visible: root.skin.select === "wash"
        anchors.fill: parent
        skin: ({ pointer: "brush", open: root.skin.open, openCurve: root.skin.openCurve })
        target: desks.current ? Qt.rect(desks.current.x, 0, desks.current.width, root.barHeight) : Qt.rect(0, 0, 0, 0)
        lineY: root.barHeight + Type.px(5)
      }

      Row {
        id: deskRow
        height: root.barHeight
        Repeater {
          model: desks.list
          Item {
            id: desk
            required property var modelData
            readonly property bool on: modelData.active
            width: Type.px(26); height: root.barHeight
            onOnChanged: if (on) desks.current = desk
            Component.onCompleted: if (on) desks.current = desk
            Text {
              anchors.centerIn: parent
              text: root.skin.kanjiNumerals ? root.kanji[desk.modelData.id] || String(desk.modelData.id) : String(desk.modelData.id)
              color: desk.on ? (root.skin.select === "wash" ? Ink.ink : Ink.paper) : desk.modelData.count > 0 ? Ink.ink2 : Ink.ink3
              font.family: root.skin.kanjiNumerals ? Type.jp : Type.text
              font.pixelSize: Type.px(13)
              font.weight: desk.on ? Font.DemiBold : Font.Normal
            }
            Rectangle {
              visible: !desk.on && desk.modelData.count > 0 && !desk.modelData.urgent
              anchors.horizontalCenter: parent.horizontalCenter
              y: root.barHeight / 2 + Type.px(9)
              width: 3; height: 3; radius: 1.5
              color: Ink.ink3
            }
            UnreadMark {
              visible: desk.modelData.urgent
              anchors.centerIn: parent
              width: Type.px(26); height: Type.px(24)
              skin: root.skin
              small: true
            }
            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) root.overviewRequested()
                else root.workspaceActivated(desk.modelData.id)
              }
            }
          }
        }
      }
      WheelHandler { onWheel: function(event) { root.workspaceStepped(event.angleDelta.y > 0 ? -1 : 1) } }
    }

    // 間: one interval on purpose
    Item { width: Type.px(22); height: 1 }

    Row {
      id: titleRow
      visible: root.shown("title") && root.activeWindow !== null
      height: root.barHeight
      spacing: Type.px(9)
      readonly property var parts: root.activeWindow ? Title.describe(root.activeWindow.cls, root.activeWindow.title) : null
      readonly property real room: Math.max(0, clockCell.x - left.x - x - Type.px(28))
      clip: true
      width: Math.min(implicitWidth, room)
      Label { text: titleRow.parts ? titleRow.parts.app : ""; color: Ink.ink; height: root.barHeight }
      Label {
        text: titleRow.parts ? (titleRow.parts.leaf || titleRow.parts.head) : ""
        color: Ink.ink3
        font.weight: Font.Normal
        font.italic: root.surfaceKind === "card"
        height: root.barHeight
      }
    }
  }

  // ── centre: the time, the date, the season ──────────────────────────
  Cell {
    id: clockCell
    name: "clock"
    visible: root.shown("clock")
    anchors.horizontalCenter: parent.horizontalCenter
    width: clockRow.implicitWidth + Type.px(18)
    readonly property string season: Season.label(root.now, root.skin.season)
    Row {
      id: clockRow
      anchors.centerIn: parent
      spacing: Type.px(10)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: Qt.formatTime(root.now, root.timeFormat)
        color: Ink.ink
        font.family: Type.display; font.pixelSize: Type.px(20); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(20), 400, root.skin.soft)
        font.features: { "tnum": 1, "lnum": 1 }
      }
      Label { text: Qt.formatDate(root.now, "ddd d MMM"); color: Ink.ink3; font.weight: Font.Normal; height: root.barHeight }
      Rectangle { visible: clockCell.season !== ""; anchors.verticalCenter: parent.verticalCenter; width: 1; height: Type.px(14); color: Ink.kLine }
      Label {
        visible: clockCell.season !== ""
        text: clockCell.season
        color: Ink.ink2
        font.family: root.skin.season === "kanji" ? Type.jp : Type.text
        font.letterSpacing: root.skin.season === "kanji" ? Type.px(1) : 0
        height: root.barHeight
      }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clockClicked() }
  }

  // ── right: what is playing, Wi-Fi, volume, battery ─────────────────
  Row {
    id: right
    anchors.right: parent.right
    anchors.rightMargin: Type.px(8)
    height: root.barHeight

    Item {
      id: mediaCell
      readonly property bool playing: root.media !== null && root.shown("media")
      // what is left between the clock and the status cells
      readonly property real others: (netCell.visible ? netCell.width : 0) + (volCell.visible ? volCell.width : 0) + (batCell.visible ? batCell.width : 0)
      readonly property real room: Math.max(0, root.width - Type.px(8) - others - Type.px(7) - (clockCell.x + clockCell.width) - Type.px(40))
      visible: playing && room >= Type.px(90)
      width: visible ? Math.min(mediaRow.implicitWidth + Type.px(18), Type.px(280), room) : 0
      height: root.barHeight
      clip: true
      Row {
        id: mediaRow
        x: Type.px(9)
        height: root.barHeight
        spacing: Type.px(9)
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2
          Repeater {
            model: [5, 11, 7]
            Rectangle { required property int modelData; anchors.bottom: parent.bottom; width: 2; height: Type.px(modelData); color: Ink.ink2; opacity: root.media && root.media.playing ? 1 : 0.4 }
          }
        }
        Label { text: root.media ? root.media.title : ""; color: Ink.ink; height: root.barHeight }
        Label { text: root.media ? root.media.artist : ""; color: Ink.ink3; font.weight: Font.Normal; height: root.barHeight }
      }
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(mouse) { root.mediaAction(mouse.button === Qt.RightButton ? "next" : mouse.button === Qt.MiddleButton ? "previous" : "playPause") }
      }
    }
    Rectangle { visible: mediaCell.visible; anchors.verticalCenter: parent.verticalCenter; width: root.skin.divider === "score" ? 2 : 1; height: Type.px(14); color: root.skin.divider === "score" ? Ink.scoreDark : Ink.kLine }
    Item { visible: mediaCell.visible; width: Type.px(6); height: 1 }

    // Wi-Fi: the icon; its name comes out when you reach for it
    Cell {
      id: netCell
      name: "network"
      visible: root.network !== null && root.shown("network")
      readonly property bool reach: root.pointed === netCell
      width: netRow.implicitWidth + Type.px(18)
      Row {
        id: netRow
        anchors.centerIn: parent
        spacing: Type.px(7)
        Icon {
          anchors.verticalCenter: parent.verticalCenter
          name: root.network && root.network.off ? "offline" : "wifi"
          level: root.network ? Math.max(1, Math.min(3, root.network.bars - (root.network.bars > 3 ? 1 : 0))) : 0
          color: root.network && root.network.off ? Ink.seal : (netCell.reach ? Ink.ink : Ink.ink2)
          size: Type.px(16)
        }
        Label { visible: netCell.reach; text: root.network ? root.network.name : ""; color: Ink.ink3; font.weight: Font.Normal; height: root.barHeight }
      }
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(mouse) { root.statusAction("network", mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "click") }
      }
    }

    // Bluetooth: the rune, faint when off; the connected device's charge
    // beside it, and its name when you reach for it
    Cell {
      id: btCell
      name: "bluetooth"
      visible: root.bluetooth !== null && root.shown("bluetooth") && root.style.bluetooth !== "off"
      readonly property bool reach: root.pointed === btCell
      readonly property bool on: !!(root.bluetooth && root.bluetooth.enabled)
      readonly property bool alert: !!(root.bluetooth && root.bluetooth.needsYou)
      readonly property bool linked: !!(root.bluetooth && root.bluetooth.connected > 0)
      width: btRow.implicitWidth + Type.px(18)
      Row {
        id: btRow
        anchors.centerIn: parent
        spacing: Type.px(6)
        Icon {
          anchors.verticalCenter: parent.verticalCenter
          name: btCell.on ? "bluetooth" : "bluetoothOff"
          color: btCell.alert ? Ink.seal : btCell.reach || btCell.linked ? Ink.ink : Ink.ink3
          size: Type.px(16)
        }
        Label {
          visible: btCell.linked && root.bluetooth.level >= 0
          text: btCell.linked ? String(Math.round(root.bluetooth.level * 100)) : ""
          color: btCell.alert ? Ink.seal : (btCell.reach ? Ink.ink : Ink.ink2)
          height: root.barHeight; font.features: { "tnum": 1 }
        }
        Label { visible: btCell.reach; text: root.bluetooth ? root.bluetooth.name : ""; color: Ink.ink3; font.weight: Font.Normal; height: root.barHeight }
      }
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(mouse) { root.statusAction("bluetooth", mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "click") }
      }
    }

    // volume: an icon and a figure you can scroll
    Cell {
      id: volCell
      name: "volume"
      visible: root.volume !== null && root.shown("volume")
      readonly property bool alert: root.volume && root.volume.muted
      width: volRow.implicitWidth + Type.px(18)
      Row {
        id: volRow
        anchors.centerIn: parent
        spacing: Type.px(7)
        Icon {
          anchors.verticalCenter: parent.verticalCenter
          name: volCell.alert ? "muted" : "volume"
          color: volCell.alert ? Ink.seal : (root.pointed === volCell ? Ink.ink : Ink.ink2)
          size: Type.px(16)
        }
        Label { text: root.volume ? String(root.volume.percent) : ""; color: volCell.alert ? Ink.seal : (root.pointed === volCell ? Ink.ink : Ink.ink2); height: root.barHeight; font.features: { "tnum": 1 } }
      }
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(mouse) { root.statusAction("volume", mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "click") }
        onWheel: function(wheel) { root.statusAction("volume", wheel.angleDelta.y > 0 ? "up" : "down") }
      }
    }

    // battery: the ring part (a glyph, or an ensō that closes as it fills)
    Cell {
      id: batCell
      name: "battery"
      visible: root.battery !== null && root.shown("battery")
      readonly property bool alert: root.battery && root.battery.needsYou
      width: batRow.implicitWidth + Type.px(18)
      Row {
        id: batRow
        anchors.centerIn: parent
        spacing: Type.px(7)
        Ring {
          anchors.verticalCenter: parent.verticalCenter
          skin: root.skin
          value: root.battery ? root.battery.percent : 0
          size: Type.px(17)
          alert: batCell.alert
          tint: root.pointed === batCell ? Ink.ink : Ink.ink2
        }
        Label { text: root.battery ? String(root.battery.percent) : ""; color: batCell.alert ? Ink.seal : (root.pointed === batCell ? Ink.ink : Ink.ink2); height: root.barHeight; font.features: { "tnum": 1 } }
        Icon { visible: root.battery && root.battery.charging; anchors.verticalCenter: parent.verticalCenter; name: "bolt"; color: Ink.ink2; size: Type.px(14) }
      }
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(mouse) { root.statusAction("battery", mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "click") }
      }
    }
  }

  // ── the pointer mark, over everything ────────────────────────────────
  PointerMark {
    anchors.fill: parent
    z: 10
    skin: root.skin
    target: {
      var it = root.pointed
      if (!it || !it.visible) return Qt.rect(0, 0, 0, 0)
      // mapToItem is not a binding dependency: read the positions it uses
      // so the mark follows the layout (the rows place their cells late).
      var deps = it.x + it.width + left.x + right.x + right.width + clockCell.x + root.width
      var p = it.mapToItem(root, deps * 0, 0)
      return Qt.rect(p.x, 0, it.width, root.barHeight)
    }
    lineY: root.barHeight
    label: root.pointed && root.pointed.name ? root.cellNames[root.pointed.name] || "" : ""
  }
}
