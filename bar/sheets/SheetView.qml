pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Sheets.js" as Sheets
import "../../core/Hands.js" as Hands
import "../../core/Time.js" as TimeJs
import "../../core/Status.js" as StatusJs
import "../../core/Blue.js" as BlueJs

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
  // How each sheet is drawn (Style.js sheetStyles): ledger | tanzaku |
  // shogi | soroban | odoshi | kasumi | shoji.
  property var styles: ({})
  readonly property string hand: styles[sheet] || "ledger"
  // Shōji 障子 sheets are a Shōji panel (ShojiPanel), not a printed card:
  // washi in Shōji's skin (core/Skin.js), on a rail a little below the bar
  // (`rail`, so SheetWindow leaves the gap and slides it along), arriving
  // from `side`.
  property var skin: ({})
  property int side: 1
  readonly property bool rail: hand === "shoji"
  // The craft hands (Shōgi, Soroban, Odoshi, Kasumi) draw one model of
  // whichever sheet is open (core/Hands.js).
  readonly property var handModel: Hands.HANDS.indexOf(hand) >= 0
    ? Hands.model(sheet, feed, feed.now || new Date(), { T: TimeJs, St: StatusJs, B: BlueJs }) : null

  // A sheet asked for something (a value, a device, a page of the ribbon).
  signal request(string sheet, string what, var arg)
  signal closeRequested()
  // Tab / Shift+Tab: move to the next or previous sheet.
  signal cycle(int delta)

  readonly property var info: Sheets.byKey(sheet)
  readonly property int sheetWidth: rail ? panel.width : Type.px(info ? info.width : 430)

  width: sheetWidth
  implicitWidth: sheetWidth
  implicitHeight: rail ? panel.implicitHeight : card.implicitHeight

  // Hand the keyboard to the contents (arrows act inside a sheet).
  function focusContents() {
    if (rail) { panel.focusContents(); return }
    var contents = body.item as Item
    if (contents) contents.forceActiveFocus()
    else root.forceActiveFocus()
  }

  ShojiPanel {
    id: panel
    visible: root.rail
    skin: root.skin
    side: root.side
    sheet: root.rail ? root.sheet : ""
    open: root.open && root.rail
    feed: root.feed
    onRequest: function(sheet, what, arg) { root.request(sheet, what, arg) }
    onCloseRequested: root.closeRequested()
    onCycle: function(delta) { root.cycle(delta) }
  }

  SheetCard {
    id: card
    visible: !root.rail
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
      sourceComponent: root.rail ? null : root.handModel
        ? ({ shogi: shogiHand, soroban: sorobanHand, odoshi: odoshiHand, kasumi: kasumiHand })[root.hand]
        : (root.hand === "tanzaku"
          ? { time: timeTanzaku, sound: soundTanzaku, network: networkTanzaku, bluetooth: bluetoothTanzaku,
              power: powerTanzaku, display: displayTanzaku, inbox: inboxTanzaku }
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

  // ---- tanzaku
  Component {
    id: timeTanzaku
    TimeTanzaku {
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
    id: soundTanzaku
    SoundTanzaku {
      sound: root.feed.sound || null
      onRequest: function(what, arg) { root.request("sound", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: networkTanzaku
    NetworkTanzaku {
      net: root.feed.network || null
      onRequest: function(what, arg) { root.request("network", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: powerTanzaku
    PowerTanzaku {
      power: root.feed.power || null
      onRequest: function(what, arg) { root.request("power", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: inboxTanzaku
    InboxTanzaku {
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
    id: displayTanzaku
    DisplayTanzaku {
      display: root.feed.display || null
      onRequest: function(what, arg) { root.request("display", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: bluetoothTanzaku
    BluetoothTanzaku {
      blue: root.feed.bluetooth || null
      onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  // ---- the craft hands: one component each, for every sheet
  Component {
    id: shogiHand
    ShogiHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: sorobanHand
    SorobanHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: odoshiHand
    OdoshiHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }

  Component {
    id: kasumiHand
    KasumiHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
}
