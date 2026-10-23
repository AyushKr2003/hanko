pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// One open Shōji 障子 panel, the `shoji` sheet hand (SheetView hands a Shōji
// sheet to it): the frame (the washi surface and the sign, a vertical name
// down the right edge) around one of the seven panels. It slides in on its
// rail; SheetWindow moves the same panel along the bar when another cell is
// clicked (skin.travels). Pure like SheetView, and fed the same `feed`;
// requests name their sheet so Bar.sheetRequest handles them unchanged.
Item {
  id: root

  property var skin: ({})
  property string sheet: ""
  property var feed: ({})
  property bool open: true
  // false: a picture (Settings › Sheets), which leaves the keyboard where it is.
  property bool takesKeys: true
  // Which side of the screen the panel's cell is on, for the slide (-1 left, 1 right).
  property int side: 1

  signal request(string sheet, string what, var arg)
  signal closeRequested()
  signal cycle(int delta)

  readonly property string panel: ({ time: "time", sound: "sound", network: "network", bluetooth: "bluetooth", power: "power", display: "display", inbox: "inbox" })[sheet] || ""
  readonly property var signs: ({
    time: ["時", "Time"], sound: ["音", "Sound"], network: ["繋", "Network"], bluetooth: ["藍", "Bluetooth"], power: ["電", "Power"], display: ["明", "Display"], inbox: ["便り", "Letters"]
  })
  readonly property int signW: Type.px(52)
  // Koyomi 暦: the Time panel as the almanac (style `calendar`), or the week.
  readonly property bool koyomi: panel === "time" && (feed.calendar || "koyomi") === "koyomi"
  readonly property int contentW: Type.px(koyomi ? 660 : panel === "time" ? ((skin.season || "off") !== "off" ? 640 : 420) : panel === "inbox" ? 420 : 400)
  readonly property int pad: Type.px(20)

  width: contentW + 2 * pad + signW
  implicitWidth: width
  implicitHeight: body.implicitHeight + 2 * Type.px(18)
  height: implicitHeight

  function focusContents() {
    var c = loader.item as Item
    if (c) c.forceActiveFocus()
    else root.forceActiveFocus()
  }

  // ── arrival ─────────────────────────────────────────────────────────
  property real reveal: open ? 1 : 0
  Behavior on reveal {
    enabled: !Motion.still
    NumberAnimation {
      duration: root.open ? (root.skin.open || 240) : (root.skin.leave || 140)
      easing.type: Easing.BezierSpline
      easing.bezierCurve: root.open ? (root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1]) : (root.skin.leaveCurve || [0.5, 0, 0.75, 0, 1, 1])
    }
  }

  Item {
    id: frame
    x: root.side * Type.px(48) * (1 - root.reveal)
    width: root.width; height: root.height
    opacity: Math.min(1, root.reveal * 2.5)

    Surface { anchors.fill: parent; skin: root.skin }

    Column {
      id: body
      x: root.pad; y: Type.px(18)
      width: root.contentW
      spacing: Type.px(10)
      Loader {
        id: loader
        width: parent.width
        sourceComponent: ({ sound: soundPanel, time: root.koyomi ? timeKoyomi : timePanel, network: networkPanel, bluetooth: bluetoothPanel, power: powerPanel, display: displayPanel, inbox: lettersPanel })[root.panel] || null
        onLoaded: if (root.open && root.takesKeys) root.focusContents()
      }
    }

    Rectangle { x: root.width - root.signW; width: 1; height: root.height; color: Ink.kLine }
    Sign {
      x: root.width - root.signW; width: root.signW; height: root.height
      skin: root.skin
      kanji: root.signs[root.panel] ? root.signs[root.panel][0] : ""
      name: root.signs[root.panel] ? root.signs[root.panel][1] : ""
    }
  }

  // Swallow clicks on the paper so they don't reach the closer behind.
  MouseArea { z: -1; anchors.fill: parent; acceptedButtons: Qt.AllButtons }

  Keys.onEscapePressed: root.closeRequested()
  Keys.onTabPressed: root.cycle(1)
  Keys.onBacktabPressed: root.cycle(-1)

  Component {
    id: soundPanel
    SoundPanel {
      skin: root.skin
      sound: root.feed.sound || null
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: timeKoyomi
    ShojiKoyomi {
      skin: root.skin
      now: root.feed.now || new Date()
      pick: root.feed.timePick || 0
      // The panel's own padding comes off the room.
      room: root.feed.room ? root.feed.room - 2 * Type.px(18) : 0
      sky: root.feed.sky || null
      zones: root.feed.zones || []
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: timePanel
    TimePanel {
      skin: root.skin
      now: root.feed.now || new Date()
      zones: root.feed.zones || []
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: networkPanel
    NetworkPanel {
      skin: root.skin
      net: root.feed.network || null
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: bluetoothPanel
    BluetoothPanel {
      skin: root.skin
      blue: root.feed.bluetooth || null
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: powerPanel
    PowerPanel {
      skin: root.skin
      power: root.feed.power || null
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: lettersPanel
    LettersPanel {
      skin: root.skin
      letters: root.feed.letters || []
      dnd: !!root.feed.dnd
      openStem: root.feed.openLetter || ""
      now: root.feed.now || new Date()
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
  Component {
    id: displayPanel
    DisplayPanel {
      skin: root.skin
      display: root.feed.display || null
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
}
