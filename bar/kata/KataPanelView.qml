pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// One open Kata panel (docs/kata): the frame (the surface part, the
// concave joins of a fold, the sign: a heading, index tabs or a vertical
// name) around one of the five panels, arriving the way the skin says:
//   fold   hangs from the bar's line and unfolds downward
//   slip   comes out from under the bar
//   slide  slides in on its rail; SheetWindow moves the same panel along
//          the bar when another cell is clicked (skin.travels)
// Pure like SheetView, and fed the same `feed`; requests name their sheet
// so Bar.sheetRequest handles them unchanged. Bluetooth and Display have no
// panel of their own here: they open Connections and Power.
Item {
  id: root

  property var skin: ({})
  property string sheet: ""
  property var feed: ({})
  property bool open: true
  property bool atBottom: false
  // Which side of the screen the panel's cell is on, for slide (-1 left, 1 right).
  property int side: 1

  signal request(string sheet, string what, var arg)
  signal closeRequested()
  signal cycle(int delta)
  signal pickSheet(string key)

  readonly property string panel: ({ time: "time", sound: "sound", network: "network", bluetooth: "network", power: "power", display: "power", inbox: "inbox" })[sheet] || ""
  readonly property var signs: ({
    time: ["時", "Time"], sound: ["音", "Sound"], network: ["繋", "Connections"], power: ["電", "Power"], inbox: ["便り", "Letters"]
  })
  readonly property var tabs: [{ key: "time", name: "Time" }, { key: "sound", name: "Sound" }, { key: "network", name: "Network" }, { key: "power", name: "Power" }, { key: "inbox", name: "Letters" }]
  readonly property bool tate: skin.sign === "tategaki"
  readonly property bool hangs: skin.arrive === "fold" || skin.arrive === "slip"
  readonly property int contentW: Type.px(panel === "time" ? ((skin.season || "off") !== "off" ? 640 : 420) : panel === "inbox" ? 420 : 400)
  readonly property int pad: Type.px(20)

  width: contentW + 2 * pad + (tate ? Type.px(52) : 0)
  implicitWidth: width
  implicitHeight: body.implicitHeight + 2 * Type.px(18)
  height: implicitHeight

  readonly property string detail: {
    var f = feed || {}
    if (panel === "sound" && f.sound) {
      for (var i = 0; i < f.sound.outputs.length; i++) if (f.sound.outputs[i].current) return f.sound.outputs[i].label
      return ""
    }
    if (panel === "network" && f.network) return f.network.radio ? "Wi-Fi on" : "Wi-Fi off"
    if (panel === "power" && f.power) return f.power.charging ? "charging" : "on battery"
    if (panel === "inbox") return f.dnd ? "quiet" : ""
    if (panel === "time") return Qt.formatDate(f.now || new Date(), "d MMM yyyy")
    return ""
  }

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

  // slip is clipped at the bar's edge, so it comes out from under it
  Item {
    id: well
    x: -Type.px(12); y: 0
    width: root.width + Type.px(24); height: root.height + Type.px(60)
    clip: root.skin.arrive === "slip"

    Item {
      id: frame
      x: Type.px(12) + (root.skin.arrive === "slide" ? root.side * Type.px(48) * (1 - root.reveal) : 0)
      y: root.skin.arrive === "slip" ? -(root.height + Type.px(40)) * (1 - root.reveal) * (root.atBottom ? -1 : 1)
        : root.skin.arrive === "fold" ? -Type.px(14) * (1 - root.reveal) : 0
      width: root.width; height: root.height
      opacity: root.skin.arrive === "slip" ? 1 : Math.min(1, root.reveal * 2.5)
      transform: Scale {
        origin.y: root.atBottom ? root.height : 0
        yScale: root.skin.arrive === "fold" ? 0.82 + 0.18 * root.reveal : 1
      }

      Surface { anchors.fill: parent; skin: root.skin; hangs: root.hangs }
      Joins { visible: root.skin.arrive === "fold" && root.skin.corner !== "cut" && !root.atBottom; width: root.width }

      Column {
        id: body
        x: root.pad; y: Type.px(18)
        width: root.contentW
        spacing: Type.px(10)
        Sign {
          visible: root.skin.sign === "eyebrow"
          skin: root.skin
          name: root.signs[root.panel] ? root.signs[root.panel][1] : ""
          detail: root.detail
        }
        Loader {
          id: loader
          width: parent.width
          sourceComponent: ({ sound: soundPanel, time: timePanel, network: networkPanel, power: powerPanel, inbox: lettersPanel })[root.panel] || null
          onLoaded: if (root.open) root.focusContents()
        }
      }

      Rectangle { visible: root.tate; x: root.width - Type.px(52); width: 1; height: root.height; color: Ink.kLine }
      Sign {
        visible: root.tate
        x: root.width - Type.px(52); width: Type.px(52); height: root.height
        skin: root.skin
        kanji: root.signs[root.panel] ? root.signs[root.panel][0] : ""
        name: root.signs[root.panel] ? root.signs[root.panel][1] : ""
      }
      Sign {
        visible: root.skin.sign === "tabs" && !root.atBottom
        x: Type.px(14); y: root.height
        skin: root.skin
        tabs: root.tabs
        current: root.panel
        onPicked: function(key) { root.pickSheet(key) }
      }
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
      Keys.onUpPressed: if (sound && sound.master) root.request("sound", "master", Math.min(1, sound.master.level + 0.05))
      Keys.onDownPressed: if (sound && sound.master) root.request("sound", "master", Math.max(0, sound.master.level - 0.05))
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
      display: root.feed.display || null
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
      now: root.feed.now || new Date()
      onRequest: function(s, what, arg) { root.request(s, what, arg) }
      Keys.onEscapePressed: root.closeRequested()
      Keys.onTabPressed: root.cycle(1)
      Keys.onBacktabPressed: root.cycle(-1)
    }
  }
}
