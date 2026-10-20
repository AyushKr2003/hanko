pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Sheets.js" as Sheets
import "../../core/Hands.js" as Hands
import "../../core/Time.js" as TimeJs
import "../../core/Status.js" as StatusJs
import "../../core/Blue.js" as BlueJs
import "../../core/Cursor.js" as Cursor

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
  // Omarchy's panel keys on every sheet, in every hand (core/Cursor.js):
  // the arrows or h j k l move, Enter or Space act, Esc closes, Tab goes to
  // the next sheet, + and - set a level. A part that does something says
  // so (`keyStop`, with `keyPress()`, and for a level `keyStep`,
  // `keyAdjust(d)` and `keyAxis`); the cursor walks them where they lie on
  // the paper. As in Omarchy it shows on the first key, not for the
  // pointer, and Left/Right on a level set it rather than leave it.
  property bool cursorShown: false
  property Item cursorItem: null
  // Where the cursor was (its centre), to land again when the sheet's
  // parts are made anew under it (a new reading rebuilds the rows).
  property point cursorAt: Qt.point(-1, -1)
  property rect cursorRect: Qt.rect(0, 0, 0, 0)

  function stopItems() {
    var out = []
    function walk(it) {
      if (!it || !it.visible || it.opacity <= 0) return
      if (it.keyStop === true && it.width > 0 && it.height > 0) out.push(it)
      var kids = it.children
      for (var i = 0; i < kids.length; i++) walk(kids[i])
    }
    walk(root.rail ? panel : body.item)
    return out
  }
  function stopsOf(items) {
    return items.map(function(it) {
      var p = it.mapToItem(root, 0, 0)
      return { x: p.x, y: p.y, w: it.width, h: it.height, step: !!it.keyStep, chosen: !!it.keyChosen }
    })
  }
  function setCursor(it) {
    root.cursorItem = it || null
    root.cursorShown = !!it
    root.placeCursor()
  }
  function placeCursor() {
    var it = root.cursorItem
    if (!it) return
    var p = it.mapToItem(root, 0, 0)
    root.cursorRect = Qt.rect(p.x, p.y, it.width, it.height)
    root.cursorAt = Qt.point(p.x + it.width / 2, p.y + it.height / 2)
  }
  function resetCursor() {
    root.cursorShown = false
    root.cursorItem = null
    root.cursorAt = Qt.point(-1, -1)
  }
  function keyMove(dx, dy) {
    var items = root.stopItems()
    if (!items.length) return
    var stops = root.stopsOf(items)
    var from = root.cursorShown ? items.indexOf(root.cursorItem) : -1
    if (from < 0) {
      root.setCursor(items[root.cursorShown && root.cursorAt.x >= 0 ? Cursor.nearest(stops, root.cursorAt) : Cursor.start(stops)])
      return
    }
    var it = root.cursorItem
    if (it.keyStep && typeof it.keyAdjust === "function") {
      var axis = it.keyAxis === "y" ? "y" : "x"
      if (axis === "x" && dx !== 0) { it.keyAdjust(dx); return }
      // A slip is pulled down to hang longer.
      if (axis === "y" && dy !== 0) { it.keyAdjust(dy); return }
    }
    root.setCursor(items[Cursor.move(stops, from, dx, dy)])
  }
  function keyActivate() {
    if (!root.cursorShown || !root.cursorItem) { root.keyMove(0, 0); return }
    if (typeof root.cursorItem.keyPress === "function") root.cursorItem.keyPress()
  }
  function stepLevel(d) {
    var it = root.cursorShown ? root.cursorItem : null
    if (!it || !it["keyStep"]) {
      // No level under the cursor: the sheet's first one.
      var items = root.stopItems()
      it = null
      for (var i = 0; !it && i < items.length; i++) if (items[i].keyStep) it = items[i]
      if (it) root.setCursor(it)
    }
    if (it && typeof it.keyAdjust === "function") it.keyAdjust(d)
  }

  onSheetChanged: resetCursor()
  onOpenChanged: if (!open) resetCursor()
  onCursorItemChanged: {
    // Its row was made anew: land on what stands there now.
    if (!root.cursorItem && root.cursorShown) Qt.callLater(function() {
      if (root.cursorItem || !root.cursorShown) return
      var items = root.stopItems()
      var i = Cursor.nearest(root.stopsOf(items), root.cursorAt)
      if (i >= 0) root.setCursor(items[i])
      else root.resetCursor()
    })
  }
  // Parts move as a sheet lays out (a row comes, a slip swings longer):
  // follow the one under the cursor while it shows.
  Timer {
    interval: 100
    repeat: true
    running: root.cursorShown && root.open
    onTriggered: root.placeCursor()
  }

  Keys.onPressed: function(event) {
    var a = Cursor.action(event.key, event.text, (event.modifiers & Qt.ShiftModifier) !== 0)
    if (!a) {
      if (event.text === "+" || event.text === "=") { root.stepLevel(1); event.accepted = true }
      else if (event.text === "-" || event.text === "_") { root.stepLevel(-1); event.accepted = true }
      return
    }
    if (a.kind === "close") root.closeRequested()
    else if (a.kind === "tab") root.cycle(a.dir)
    else if (a.kind === "move") root.keyMove(a.dx, a.dy)
    else if (a.kind === "activate") root.keyActivate()
    event.accepted = true
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
      sourceComponent: root.rail ? null : root.handModel
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
      onRequest: function(what, arg) { root.request("inbox", what, arg) }
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
      onRequest: function(what, arg) { root.request("inbox", what, arg) }
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
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
    }
  }

  Component {
    id: sorobanHand
    SorobanHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
    }
  }

  Component {
    id: odoshiHand
    OdoshiHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
    }
  }

  Component {
    id: kasumiHand
    KasumiHand {
      model: root.handModel
      onRequest: function(what, arg) { root.request(root.sheet, what, arg) }
    }
  }

  // The cursor: four red corner marks, a printer's register around the part
  // (red is you, now), as Kōsei brackets the part you have open.
  Item {
    id: bracket
    readonly property int out: Type.px(3)
    readonly property int arm: Type.px(7)
    z: 100
    visible: root.cursorShown && root.open && root.cursorRect.width > 0
    x: root.cursorRect.x - out
    y: root.cursorRect.y - out
    width: root.cursorRect.width + 2 * out
    height: root.cursorRect.height + 2 * out
    Behavior on x { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: Motion.live && bracket.visible; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Repeater {
      model: 4
      Item {
        id: corner
        required property int index
        readonly property bool east: index % 2 === 1
        readonly property bool low: index >= 2
        x: east ? bracket.width - bracket.arm : 0
        y: low ? bracket.height - bracket.arm : 0
        width: bracket.arm
        height: bracket.arm
        Rectangle { x: corner.east ? parent.width - width : 0; width: 2; height: parent.height; color: Ink.seal }
        Rectangle { y: corner.low ? parent.height - height : 0; width: parent.width; height: 2; color: Ink.seal }
      }
    }
  }
}
