pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Sheets.js" as Sheets

// One open sheet: the paper (SheetCard) with the right contents in it.
// Pure QtQuick like BarSurface: bar/SheetWindow.qml feeds it live data,
// the harness feeds it fixtures. Each sheet's contents are their own
// component so the handscroll (Phase 7) can lay them out again.
//
// feed: { now, zones, timeShift, sound, ... } plain data for whichever
// sheet shows.
Item {
  id: root

  property string sheet: ""
  property bool atBottom: false
  property int tearX: 0
  property int tearWidth: 0
  property var feed: ({})
  // Printed (1) or not (0); animates over 180 ms when `open` changes.
  property bool open: true
  property bool animate: true

  // A sheet asked for something (a value, a device, a page of the ribbon).
  signal request(string sheet, string what, var arg)
  signal closeRequested()
  // Tab / Shift+Tab: move to the next or previous sheet.
  signal cycle(int delta)

  readonly property var info: Sheets.byKey(sheet)
  readonly property int sheetWidth: Type.px(info ? info.width : 430)

  width: sheetWidth
  implicitWidth: sheetWidth
  implicitHeight: card.implicitHeight

  // Hand the keyboard to the contents (arrows act inside a sheet).
  function focusContents() {
    var contents = body.item as Item
    if (contents) contents.forceActiveFocus()
    else root.forceActiveFocus()
  }

  SheetCard {
    id: card
    width: root.width
    atBottom: root.atBottom
    tearX: root.tearX
    tearWidth: root.tearWidth
    reveal: root.open ? 1 : 0
    Behavior on reveal {
      enabled: root.animate
      NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Loader {
      id: body
      width: card.width
      sourceComponent: ({ time: timeSheet, sound: soundSheet })[root.sheet] || null
      onLoaded: if (root.open) root.focusContents()
    }
  }

  Component {
    id: timeSheet
    TimeSheet {
      now: root.feed.now || new Date()
      zones: root.feed.zones || []
      shift: root.feed.timeShift || 0
      onRequest: function(what, arg) { root.request("time", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: soundSheet
    SoundSheet {
      sound: root.feed.sound || null
      onRequest: function(what, arg) { root.request("sound", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
}
