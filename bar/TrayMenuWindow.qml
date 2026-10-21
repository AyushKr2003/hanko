pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import "../core"
import "../core/Extras.js" as X

// A tray app's menu, printed by Hanko under its icon: a slip of paper with
// the app's name as a tracked eyebrow and hairline rows, hover marked with
// the ink bar sheets use. Submenus open in place, with a back row naming
// where you are. It reads the menu through QsMenuOpener because
// item.display() asks Qt for a platform menu, which Quickshell refuses
// outside QApplication mode (omarchy-shell's), so right-click did nothing.
// A click anywhere else, or Esc, closes it. Keys as on Omarchy's panels:
// Up/Down (or j/k) walk the rows, Enter, Space or Right open one, Left
// goes back out of a submenu.
PopupWindow {
  id: win

  required property var barWindow

  // The tray item whose menu is open, and the cell it hangs from.
  property var item: null
  property Item cell: null
  property bool open: false
  // The submenus entered, deepest last: { opener, title }.
  property var stack: []
  // When a click elsewhere last closed it, and on which item: a right-click
  // on the same icon is that click, and should leave it closed.
  property real clearedAt: 0
  property var clearedItem: null
  // The row the keyboard is on (-1: none yet; it shows on the first key).
  property int cursor: -1

  readonly property bool atBottom: barWindow.atBottom
  readonly property var rows: stack.length > 0 ? stack[stack.length - 1].opener.children : rootOpener.children
  readonly property string appName: item ? String(item.tooltipTitle || item.title || item.id || "") : ""

  function toggle(trayItem, trayCell) {
    if (open && item === trayItem) { close(); return }
    if (trayItem === clearedItem && Date.now() - clearedAt < 300) return
    reset()
    item = trayItem
    cell = trayCell
    open = true
  }
  function close() { open = false; grab.active = false }
  function reset() {
    // Deepest first: a submenu's entry belongs to its parent's children.
    var openers = stack
    stack = []
    for (var i = openers.length - 1; i >= 0; i--) openers[i].opener.destroy()
  }
  function enter(entry) {
    var opener = openerComponent.createObject(win, { menu: entry })
    if (!opener) return
    stack = stack.concat([{ opener: opener, title: X.menuText(entry.text) }])
  }
  function back() {
    if (stack.length === 0) { close(); return }
    var top = stack[stack.length - 1]
    stack = stack.slice(0, -1)
    top.opener.destroy()
  }
  // The next row a key can land on, from `from` in direction d.
  function stepCursor(d) {
    var n = rowRepeater.count
    for (var i = win.cursor < 0 ? (d > 0 ? 0 : n - 1) : win.cursor + d; i >= 0 && i < n; i += d) {
      var r = rowRepeater.itemAt(i)
      var e = win.rows[i]
      if (r && r.visible && e && !e.isSeparator && e.enabled) { win.cursor = i; return }
    }
  }
  function pickCursor(sub) {
    var e = win.cursor >= 0 ? win.rows[win.cursor] : null
    if (!e) { stepCursor(1); return }
    if (sub && !e.hasChildren) return
    pick(e)
  }
  onRowsChanged: cursor = -1
  function pick(entry) {
    if (entry.hasChildren) { enter(entry); return }
    entry.triggered()
    close()
  }

  QsMenuOpener {
    id: rootOpener
    menu: win.open && win.item ? win.item.menu : null
  }
  Component { id: openerComponent; QsMenuOpener {} }

  // An icon that leaves the tray takes its menu with it.
  onItemChanged: if (!item) close()
  onCellChanged: if (!cell) close()
  onOpenChanged: {
    if (open) grabLater.restart()
    // Later: a pick closes it from inside a row the reset would destroy.
    else Qt.callLater(reset)
  }

  anchor.item: cell
  anchor.edges: atBottom ? Edges.Top : Edges.Bottom
  anchor.gravity: atBottom ? Edges.Top : Edges.Bottom
  anchor.rect.x: 0
  anchor.rect.y: atBottom ? -Type.px(4) : Type.px(4)
  anchor.rect.width: cell ? cell.width : 1
  anchor.rect.height: cell ? cell.height : 1
  anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip

  visible: open && !!cell
  color: "transparent"
  implicitWidth: slip.width
  implicitHeight: slip.height

  HyprlandFocusGrab {
    id: grab
    windows: [win]
    active: false
    onCleared: {
      if (!win.open) return
      win.clearedItem = win.item
      win.clearedAt = Date.now()
      win.close()
    }
  }
  // The grab lands a moment after the popup maps, as the overview's does.
  Timer {
    id: grabLater
    interval: 120
    onTriggered: grab.active = win.open
  }

  Rectangle {
    id: slip
    width: list.width + Type.px(8)
    height: list.height + Type.px(8)
    color: Ink.paper
    radius: 2
    border.width: 1
    border.color: Ink.line
    opacity: win.visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Motion.ms(120); easing.type: Easing.OutCubic } }

    focus: true
    Keys.onPressed: function(event) {
      var t = event.text
      if (event.key === Qt.Key_Escape) win.back()
      else if (event.key === Qt.Key_Down || t === "j") win.stepCursor(1)
      else if (event.key === Qt.Key_Up || t === "k") win.stepCursor(-1)
      else if (event.key === Qt.Key_Left || t === "h") { if (win.stack.length > 0) win.back() }
      else if (event.key === Qt.Key_Right || t === "l") win.pickCursor(true)
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) win.pickCursor(false)
      else return
      event.accepted = true
    }

    Column {
      id: list
      x: Type.px(4)
      y: Type.px(4)
      // Column measures its children's widths, which are its own, so the
      // rows' natural widths are read here instead.
      readonly property real natural: {
        var w = head.implicitWidth
        for (var i = 0; i < rowRepeater.count; i++) {
          var r = rowRepeater.itemAt(i)
          if (r && r.visible) w = Math.max(w, r.implicitWidth)
        }
        return w
      }
      width: Math.min(Type.px(320), Math.max(Type.px(180), natural))

      // The eyebrow: the app's name, or the way back out of a submenu.
      Item {
        id: head
        width: list.width
        implicitWidth: headText.implicitWidth + Type.px(20)
        height: Type.px(26)
        readonly property bool inSub: win.stack.length > 0

        Rectangle {
          anchors.fill: parent
          radius: 2
          color: head.inSub && headMouse.containsMouse ? Ink.alpha(Ink.bone, 0.06) : "transparent"
        }
        Text {
          id: headText
          anchors.left: parent.left
          anchors.leftMargin: Type.px(10)
          anchors.right: parent.right
          anchors.rightMargin: Type.px(10)
          anchors.verticalCenter: parent.verticalCenter
          text: (head.inSub ? "‹  " + win.stack[win.stack.length - 1].title : win.appName).toUpperCase()
          elide: Text.ElideRight
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.label
          font.letterSpacing: Type.trackLabel
        }
        MouseArea {
          id: headMouse
          anchors.fill: parent
          enabled: head.inSub
          hoverEnabled: true
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: win.back()
        }
      }
      Rectangle {
        x: Type.px(10)
        width: list.width - Type.px(20)
        height: 1
        color: Ink.lineSoft
      }

      Repeater {
        id: rowRepeater
        model: win.rows

        Item {
          id: row
          required property var modelData
          required property int index
          readonly property var entry: modelData
          readonly property bool separator: entry.isSeparator
          // A leading separator or a first row that only repeats the app's
          // name, as some apps send, says nothing under the eyebrow.
          readonly property bool redundant: win.stack.length === 0 && index <= 1
            && (separator || (index === 0 && entry.hasChildren && X.menuText(entry.text).toLowerCase() === win.appName.toLowerCase()))
          readonly property bool hot: win.cursor === index && entry.enabled && !separator
          readonly property bool checkable: entry.buttonType !== QsMenuButtonType.None
          readonly property string mark: !checkable ? ""
            : entry.buttonType === QsMenuButtonType.RadioButton ? (entry.checkState === Qt.Checked ? "●" : "○")
            : (entry.checkState === Qt.Checked ? "✓" : "")

          visible: !redundant
          width: list.width
          implicitWidth: label.implicitWidth + Type.px(66)
          height: redundant ? 0 : separator ? Type.px(9) : Type.px(28)

          Rectangle {
            visible: row.separator
            x: Type.px(10)
            width: parent.width - Type.px(20)
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: Ink.lineSoft
          }

          Rectangle {
            visible: !row.separator
            anchors.fill: parent
            radius: 2
            color: row.hot ? Ink.alpha(Ink.bone, 0.06) : "transparent"
          }
          // The ink bar sheets show at a row you can pick.
          Rectangle {
            visible: !row.separator
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: row.hot ? parent.height - Type.px(12) : 0
            color: Ink.ink
            Behavior on height { enabled: !Motion.still; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
          }

          // The gutter: a check or radio mark, else the entry's own icon:
          // symbolic ones inked, others in grey, since inking a drawn
          // checkbox (udiskie's) would fill it in.
          Item {
            visible: !row.separator
            x: Type.px(10)
            width: Type.px(16)
            height: parent.height
            Text {
              anchors.centerIn: parent
              text: row.mark
              color: Ink.ink
              font.family: Type.text
              font.pixelSize: Type.note
            }
            Image {
              id: entryIcon
              visible: false
              anchors.centerIn: parent
              width: Type.px(14)
              height: width
              sourceSize: Qt.size(width * 2, height * 2)
              source: row.separator || row.checkable ? "" : String(row.entry.icon || "")
              fillMode: Image.PreserveAspectFit
            }
            MultiEffect {
              readonly property bool symbolic: String(entryIcon.source).split("?")[0].slice(-9) === "-symbolic"
              visible: entryIcon.status === Image.Ready
              anchors.fill: entryIcon
              source: entryIcon
              opacity: row.entry.enabled ? 1 : 0.45
              colorization: symbolic ? 1 : 0
              colorizationColor: Ink.inkDim
              brightness: symbolic ? 0.25 : 0
              saturation: symbolic ? 0 : -1
            }
          }

          Text {
            id: label
            visible: !row.separator
            anchors.left: parent.left
            anchors.leftMargin: Type.px(32)
            anchors.right: parent.right
            anchors.rightMargin: Type.px(28)
            anchors.verticalCenter: parent.verticalCenter
            text: X.menuText(row.entry.text)
            elide: Text.ElideRight
            color: row.entry.enabled ? Ink.ink : Ink.inkFaint
            font.family: Type.text
            font.pixelSize: Type.note
          }
          Text {
            visible: !row.separator && row.entry.hasChildren
            anchors.right: parent.right
            anchors.rightMargin: Type.px(10)
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.value
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: !row.separator && row.entry.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            // One cursor for the keys and the pointer, as Omarchy's menus
            // keep it: hovering a row moves it there.
            onPositionChanged: win.cursor = row.index
            onClicked: win.pick(row.entry)
          }
        }
      }
    }
  }
}
