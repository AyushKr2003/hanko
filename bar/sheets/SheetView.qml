pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Sheets.js" as Sheets
import "../../core/Hands.js" as Hands
import "../../core/Time.js" as TimeJs
import "../../core/Status.js" as StatusJs
import "../../core/Blue.js" as BlueJs
import "../../core/Cursor.js" as Cursor
import "../parts"

// One open sheet: the paper (SheetCard) with the right contents in it.
// Pure QtQuick like BarSurface: bar/SheetWindow.qml feeds it live data,
// the harness feeds it fixtures. Each sheet's contents are their own
// component.
//
// feed: { now, zones, timeShift, sound, network, bluetooth, power, display,
// letters, dnd, all }, where all is No. 00's { rows, spaces, window, home,
// media, glyph }:
// plain data for whichever sheet shows.
Item {
  id: root

  property string sheet: ""
  property bool atBottom: false
  property int tearX: 0
  property int tearWidth: 0
  property var feed: ({})
  // Printed (1) or not (0): draws over Motion.sheetPrint (30 + 160 ms) when
  // `open` turns on, sheathes over Motion.noto (240 ms) when it turns off.
  property bool open: true
  // Panel opacity (Style.js panelOpacity), 0..1.
  property real paperOpacity: 1
  property bool animate: true
  // How each sheet is drawn (Style.js sheetStyles): ledger | tanzaku |
  // shogi | soroban | odoshi | kasumi | shoji.
  property var styles: ({})
  // No. 00 (Inkan's sheet of every sheet) is always a ledger.
  readonly property string hand: sheet === "all" ? "ledger" : styles[sheet] || "ledger"
  // Shōji 障子 sheets are a Shōji panel (ShojiPanel), not a printed card:
  // washi in Shōji's skin (core/Skin.js), on a rail a little below the bar
  // (`rail`, so SheetWindow leaves the gap and slides it along), arriving
  // from `side`.
  property var skin: ({})
  property int side: 1
  readonly property bool rail: hand === "shoji"
  // The craft hands (Shōgi, Soroban, Odoshi, Kasumi) draw one model of
  // whichever sheet is open (core/Hands.js).
  // Koyomi 暦 (docs/koyomi/README.md): the Time sheet as the almanac, a
  // month in every hand, unless the calendar setting keeps the week.
  readonly property bool koyomi: sheet === "time" && (feed.calendar || "koyomi") === "koyomi"
  readonly property var handModel: !koyomi && Hands.HANDS.indexOf(hand) >= 0
    ? Hands.model(sheet, sheet === "inbox" ? Object.assign({}, feed, { openLetter: openLetter }) : feed,
                  feed.now || new Date(), { T: TimeJs, St: StatusJs, B: BlueJs }) : null
  // The inbox letter opened to read in full (its stem), in every hand: kept
  // here, since a craft hand is drawn afresh from its model. A hand asks
  // ("open", stem) and ("putAway", letter); the second goes on to Bar.qml.
  property string openLetter: ""
  function handRequest(what, arg) {
    if (sheet === "inbox" && what === "open") { openLetter = String(arg || ""); return }
    if (sheet === "inbox" && what === "putAway") openLetter = ""
    root.request(sheet, what, arg)
  }

  // A sheet asked for something (a value, a device, a page of the ribbon).
  signal request(string sheet, string what, var arg)
  signal closeRequested()
  // Tab / Shift+Tab: move to the next or previous sheet.
  signal cycle(int delta)

  readonly property var info: Sheets.byKey(sheet)
  readonly property int sheetWidth: rail ? panel.width : Type.px(koyomi ? 660 : info ? info.width : 430)

  width: sheetWidth
  implicitWidth: sheetWidth
  implicitHeight: rail ? panel.implicitHeight : card.implicitHeight

  // Hand the keyboard to the contents. Keys they leave alone (the arrows,
  // Enter, Esc, Tab) come up to this view, which moves the cursor.
  function focusContents() {
    if (rail) { panel.focusContents(); return }
    var contents = body.item as Item
    if (contents) contents.forceActiveFocus()
    else root.forceActiveFocus()
  }

  // ------------------------------------------------ Te 手, the cursor
  //
  // Omarchy's panel keys on every sheet, in every hand (bar/KeyCursor.qml,
  // core/Cursor.js): the arrows or h j k l move, Enter or Space act, Esc
  // closes, Tab goes to the next sheet, + and - set a level.
  readonly property alias cursor: keys
  // false: a picture of a sheet (Settings › Sheets), fenced off from the
  // settings window's cursor and without one of its own.
  property bool keyStops: true
  function keyMove(dx, dy) { keys.move(dx, dy) }
  function keyActivate() { keys.activate() }
  function stepLevel(d) { keys.step(d) }
  function placeCursor() { keys.place() }

  onSheetChanged: { keys.reset(); openLetter = "" }

  Keys.onPressed: function(event) {
    var a = Cursor.action(event.key, event.text, (event.modifiers & Qt.ShiftModifier) !== 0)
    if (!a) {
      if (event.text === "+" || event.text === "=") { keys.step(1); event.accepted = true }
      else if (event.text === "-" || event.text === "_") { keys.step(-1); event.accepted = true }
      return
    }
    if (a.kind === "close") root.closeRequested()
    else if (a.kind === "tab") root.cycle(a.dir)
    else if (a.kind === "move") keys.move(a.dx, a.dy)
    else if (a.kind === "activate") keys.activate()
    event.accepted = true
  }

  ShojiPanel {
    id: panel
    visible: root.rail
    skin: root.skin
    side: root.side
    sheet: root.rail ? root.sheet : ""
    open: root.open && root.rail
    feed: root.sheet === "inbox" ? Object.assign({}, root.feed, { openLetter: root.openLetter }) : root.feed
    onRequest: function(sheet, what, arg) { if (sheet === "inbox") root.handRequest(what, arg); else root.request(sheet, what, arg) }
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
    // Opening draws (a held beat, then fast to a dead stop); closing
    // sheathes (slow away, then into the bar's edge). Iai, core/Iai.js.
    Behavior on reveal {
      enabled: root.animate && !Motion.still
      SequentialAnimation {
        PauseAnimation { duration: root.open ? Motion.nukiHold : 0 }
        NumberAnimation {
          duration: root.open ? Motion.nuki : Motion.noto
          easing.type: Easing.BezierSpline
          easing.bezierCurve: root.open ? Motion.nukiCurve : Motion.notoCurve
        }
      }
    }

    Loader {
      id: body
      width: card.width
      sourceComponent: root.rail ? null : root.koyomi
        ? ({ ledger: ledgerKoyomi, tanzaku: tanzakuKoyomi, shogi: shogiKoyomi, soroban: sorobanKoyomi,
             odoshi: odoshiKoyomi, kasumi: kasumiKoyomi })[root.hand] || ledgerKoyomi
        : root.handModel
        ? ({ shogi: shogiHand, soroban: sorobanHand, odoshi: odoshiHand, kasumi: kasumiHand })[root.hand]
        : (root.hand === "tanzaku"
          ? { time: timeTanzaku, sound: soundTanzaku, network: networkTanzaku, bluetooth: bluetoothTanzaku,
              power: powerTanzaku, display: displayTanzaku, inbox: inboxTanzaku }
          : { all: allSheet, time: timeSheet, sound: soundSheet, network: networkSheet, bluetooth: bluetoothSheet,
              power: powerSheet, display: displaySheet, inbox: inboxSheet })[root.sheet] || null
      onLoaded: if (root.open) root.focusContents()
    }
  }

  Component {
    id: allSheet
    AllSheet {
      readonly property var all: root.feed.all || ({})
      now: root.feed.now || new Date()
      timeFormat: root.feed.timeFormat || "HH:mm"
      glyph: all.glyph || "鑑"
      rows: all.rows || []
      spaces: all.spaces || []
      window: all.window || null
      home: all.home || ""
      media: all.media || null
      onRequest: function(what, arg) { root.request("all", what, arg) }
    }
  }

  // ---- Koyomi 暦, the almanac, in each hand
  Component {
    id: ledgerKoyomi
    LedgerKoyomi {
      now: root.feed.now || new Date()
      pick: root.feed.timePick || 0
      sky: root.feed.sky || null
      zones: root.feed.zones || []
      onRequest: function(what, arg) { root.request("time", what, arg) }
    }
  }
  Component { id: tanzakuKoyomi; TanzakuKoyomi { now: root.feed.now || new Date(); pick: root.feed.timePick || 0; sky: root.feed.sky || null; zones: root.feed.zones || []; onRequest: function(what, arg) { root.request("time", what, arg) } } }
  Component { id: shogiKoyomi; ShogiKoyomi { now: root.feed.now || new Date(); pick: root.feed.timePick || 0; sky: root.feed.sky || null; zones: root.feed.zones || []; onRequest: function(what, arg) { root.request("time", what, arg) } } }
  Component { id: sorobanKoyomi; SorobanKoyomi { now: root.feed.now || new Date(); pick: root.feed.timePick || 0; sky: root.feed.sky || null; zones: root.feed.zones || []; onRequest: function(what, arg) { root.request("time", what, arg) } } }
  Component { id: odoshiKoyomi; OdoshiKoyomi { now: root.feed.now || new Date(); pick: root.feed.timePick || 0; sky: root.feed.sky || null; zones: root.feed.zones || []; onRequest: function(what, arg) { root.request("time", what, arg) } } }
  Component { id: kasumiKoyomi; KasumiKoyomi { now: root.feed.now || new Date(); pick: root.feed.timePick || 0; sky: root.feed.sky || null; zones: root.feed.zones || []; onRequest: function(what, arg) { root.request("time", what, arg) } } }

  Component {
    id: timeSheet
    TimeSheet {
      now: root.feed.now || new Date()
      zones: root.feed.zones || []
      shift: root.feed.timeShift || 0
      onRequest: function(what, arg) { root.request("time", what, arg) }
    }
  }

  Component {
    id: soundSheet
    SoundSheet {
      sound: root.feed.sound || null
      onRequest: function(what, arg) { root.request("sound", what, arg) }
    }
  }

  Component {
    id: networkSheet
    NetworkSheet {
      net: root.feed.network || null
      onRequest: function(what, arg) { root.request("network", what, arg) }
    }
  }

  Component {
    id: powerSheet
    PowerSheet {
      power: root.feed.power || null
      onRequest: function(what, arg) { root.request("power", what, arg) }
    }
  }

  Component {
    id: inboxSheet
    InboxSheet {
      letters: root.feed.letters || []
      dnd: !!root.feed.dnd
      now: root.feed.now || new Date()
      openStem: root.openLetter
      onRequest: function(what, arg) { root.handRequest(what, arg) }
    }
  }

  Component {
    id: displaySheet
    DisplaySheet {
      display: root.feed.display || null
      onRequest: function(what, arg) { root.request("display", what, arg) }
    }
  }

  Component {
    id: bluetoothSheet
    BluetoothSheet {
      blue: root.feed.bluetooth || null
      onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
    }
  }

  // ---- tanzaku
  Component {
    id: timeTanzaku
    TimeTanzaku {
      now: root.feed.now || new Date()
      timeFormat: root.feed.timeFormat || "HH:mm"
      zones: root.feed.zones || []
      shift: root.feed.timeShift || 0
      onRequest: function(what, arg) { root.request("time", what, arg) }
    }
  }

  Component {
    id: soundTanzaku
    SoundTanzaku {
      sound: root.feed.sound || null
      onRequest: function(what, arg) { root.request("sound", what, arg) }
    }
  }

  Component {
    id: networkTanzaku
    NetworkTanzaku {
      net: root.feed.network || null
      onRequest: function(what, arg) { root.request("network", what, arg) }
    }
  }

  Component {
    id: powerTanzaku
    PowerTanzaku {
      power: root.feed.power || null
      onRequest: function(what, arg) { root.request("power", what, arg) }
    }
  }

  Component {
    id: inboxTanzaku
    InboxTanzaku {
      letters: root.feed.letters || []
      dnd: !!root.feed.dnd
      now: root.feed.now || new Date()
      openStem: root.openLetter
      onRequest: function(what, arg) { root.handRequest(what, arg) }
    }
  }

  Component {
    id: displayTanzaku
    DisplayTanzaku {
      display: root.feed.display || null
      onRequest: function(what, arg) { root.request("display", what, arg) }
    }
  }

  Component {
    id: bluetoothTanzaku
    BluetoothTanzaku {
      blue: root.feed.bluetooth || null
      onRequest: function(what, arg) { root.request("bluetooth", what, arg) }
    }
  }

  // ---- the craft hands: one component each, for every sheet
  Component {
    id: shogiHand
    ShogiHand {
      model: root.handModel
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.handRequest(what, arg) }
    }
  }

  Component {
    id: sorobanHand
    SorobanHand {
      model: root.handModel
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.handRequest(what, arg) }
    }
  }

  Component {
    id: odoshiHand
    OdoshiHand {
      model: root.handModel
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.handRequest(what, arg) }
    }
  }

  Component {
    id: kasumiHand
    KasumiHand {
      model: root.handModel
      now: root.feed.now || new Date()
      onRequest: function(what, arg) { root.handRequest(what, arg) }
    }
  }

  KeyCursor {
    id: keys
    scope: root.rail ? panel : body.item as Item
    active: root.open && root.keyStops
  }
}
