pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Sheets.js" as Sheets

// One open sheet: the paper (SheetCard) with the right contents in it.
// Pure QtQuick like BarSurface: bar/SheetWindow.qml feeds it live data,
// the harness feeds it fixtures. Each sheet's contents are their own
// component so the handscroll (Phase 7) can lay them out again.
//
// feed: { now, zones, timeShift, sound, network, bluetooth, power, display,
// letters, dnd }:
// plain data for whichever sheet shows.
Item {
  id: root

  property string sheet: ""
  property bool atBottom: false
  property int tearX: 0
  property int tearWidth: 0
  property var feed: ({})
  // Printed (1) or not (0); prints over Motion.sheetPrint (180 ms) when `open` changes.
  property bool open: true
  // Panel opacity (Style.js panelOpacity), 0..1.
  property real paperOpacity: 1
  property bool animate: true
  // How each sheet is drawn (Style.js sheetStyles): ledger | dial | prose.
  property var styles: ({})
  readonly property string hand: styles[sheet] || "ledger"

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
    paperOpacity: root.paperOpacity
    width: root.width
    atBottom: root.atBottom
    tearX: root.tearX
    tearWidth: root.tearWidth
    reveal: root.open ? 1 : 0
    Behavior on reveal {
      enabled: root.animate && !Motion.still
      NumberAnimation { duration: Motion.sheetPrint; easing.type: Easing.OutCubic }
    }

    Loader {
      id: body
      width: card.width
      sourceComponent: (root.hand === "dial"
          ? { time: timeDial, sound: soundDial, network: networkDial, bluetooth: bluetoothDial,
              power: powerDial, display: displayDial, inbox: inboxDial }
          : root.hand === "prose"
          ? { time: timeProse, sound: soundProse, network: networkProse, bluetooth: bluetoothProse,
              power: powerProse, display: displayProse, inbox: inboxProse }
          : { time: timeSheet, sound: soundSheet, network: networkSheet, bluetooth: bluetoothSheet,
              power: powerSheet, display: displaySheet, inbox: inboxSheet })[root.sheet] || null
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

  Component {
    id: networkSheet
    NetworkSheet {
      net: root.feed.network || null
      onRequest: function(what, arg) { root.request("network", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: powerSheet
    PowerSheet {
      power: root.feed.power || null
      onRequest: function(what, arg) { root.request("power", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: inboxSheet
    InboxSheet {
      letters: root.feed.letters || []
      dnd: !!root.feed.dnd
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.request("inbox", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: displaySheet
    DisplaySheet {
      display: root.feed.display || null
      onRequest: function(what, arg) { root.request("display", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: bluetoothSheet
    BluetoothSheet {
      blue: root.feed.bluetooth || null
      onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  // ---- dial
  Component {
    id: timeDial
    TimeDial {
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
    id: soundDial
    SoundDial {
      sound: root.feed.sound || null
      onRequest: function(what, arg) { root.request("sound", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: networkDial
    NetworkDial {
      net: root.feed.network || null
      onRequest: function(what, arg) { root.request("network", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: powerDial
    PowerDial {
      power: root.feed.power || null
      onRequest: function(what, arg) { root.request("power", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: inboxDial
    InboxDial {
      letters: root.feed.letters || []
      dnd: !!root.feed.dnd
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.request("inbox", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: displayDial
    DisplayDial {
      display: root.feed.display || null
      onRequest: function(what, arg) { root.request("display", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: bluetoothDial
    BluetoothDial {
      blue: root.feed.bluetooth || null
      onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  // ---- prose
  Component {
    id: timeProse
    TimeProse {
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
    id: soundProse
    SoundProse {
      sound: root.feed.sound || null
      onRequest: function(what, arg) { root.request("sound", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: networkProse
    NetworkProse {
      net: root.feed.network || null
      onRequest: function(what, arg) { root.request("network", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: powerProse
    PowerProse {
      power: root.feed.power || null
      onRequest: function(what, arg) { root.request("power", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: inboxProse
    InboxProse {
      letters: root.feed.letters || []
      dnd: !!root.feed.dnd
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.request("inbox", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: displayProse
    DisplayProse {
      display: root.feed.display || null
      onRequest: function(what, arg) { root.request("display", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: bluetoothProse
    BluetoothProse {
      blue: root.feed.bluetooth || null
      onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
}
