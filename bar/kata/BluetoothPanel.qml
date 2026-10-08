pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs
import "../parts"

// Bluetooth 藍: the switch, then what is connected as the hero (its name in
// Fraunces, its charge on the ring part when the device reports one), then
// your devices: connected (a click disconnects), known (a click connects)
// and nearby, found while the panel is open (a click pairs). P switches it.
// Requests as BluetoothSheet's: power (bool) | device ({ address, action }).
Column {
  id: root

  property var skin: ({})
  // core/Blue.js sheet() shape, or null before the first reading.
  property var blue: null
  property int maxKnown: 4
  property int maxFound: 4
  signal request(string sheet, string what, var arg)

  readonly property bool present: !blue || blue.present !== false
  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var connected: blue && powered ? blue.connected : []
  readonly property var known: blue && powered ? blue.known.slice(0, maxKnown) : []
  readonly property var found: blue && powered ? blue.found.slice(0, maxFound) : []
  readonly property var first: connected.length ? connected[0] : null
  readonly property int level: first && first.level !== undefined ? first.level : -1

  function rowsOf(list) {
    return list.map(function(d) { return { title: d.name, detail: d.detail, note: d.connected ? "" : d.note, chosen: d.connected } })
  }
  function act(d) { root.request("bluetooth", "device", { address: d.address, action: BlueJs.action(d) }) }

  spacing: Type.px(10)

  Item {
    width: parent.width; height: Type.px(22)
    Text { anchors.verticalCenter: parent.verticalCenter; text: "Bluetooth"; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
    KataSwitch {
      visible: root.present
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      skin: root.skin; on: root.powered
      onToggled: function(on) { root.request("bluetooth", "power", on) }
    }
  }

  // the hero: what is connected, and its charge
  Item {
    width: parent.width
    height: Math.max(heroText.implicitHeight, heroRing.visible ? heroRing.height : 0)
    Column {
      id: heroText
      width: parent.width - (heroRing.visible ? heroRing.width + Type.px(16) : 0)
      spacing: Type.px(4)
      Text {
        width: parent.width; elide: Text.ElideRight
        text: root.blue ? root.blue.title : "Bluetooth"
        color: root.powered ? Ink.ink : Ink.ink3
        font.family: Type.display; font.pixelSize: Type.px(40); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(40), 360, root.skin.soft)
      }
      Text {
        width: parent.width; wrapMode: Text.Wrap
        text: root.blue ? root.blue.blurb : ""
        color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
      }
    }
    Ring {
      id: heroRing
      visible: root.level >= 0
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      skin: root.skin
      value: Math.max(0, root.level)
      size: Type.px(48)
      alert: root.level >= 0 && root.level <= BlueJs.LOW * 100
      tint: Ink.ink
    }
  }

  Divider { visible: root.powered; skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Heading { visible: root.powered; skin: root.skin; text: "Connected"; note: root.connected.length + (root.connected.length === 1 ? " device" : " devices") }
  Text {
    visible: root.powered && root.connected.length === 0
    text: "Nothing connected"
    color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5)
  }
  KataList {
    visible: root.connected.length > 0
    width: parent.width; skin: root.skin
    rows: root.rowsOf(root.connected)
    onPicked: function(i) { root.act(root.connected[i]) }
  }

  Heading { visible: root.known.length > 0; skin: root.skin; text: "Your devices"; note: "click connects" }
  KataList {
    visible: root.known.length > 0
    width: parent.width; skin: root.skin
    rows: root.rowsOf(root.known)
    onPicked: function(i) { root.act(root.known[i]) }
  }

  Heading {
    visible: root.powered
    skin: root.skin
    text: "Nearby"
    note: root.blue && root.blue.scanning ? "looking…" : ""
  }
  Text {
    visible: root.powered && root.found.length === 0
    text: root.blue && root.blue.scanning ? "Looking for devices nearby…" : "Nothing new nearby"
    color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5)
  }
  KataList {
    visible: root.found.length > 0
    width: parent.width; skin: root.skin
    rows: root.found.map(function(d) { return { title: d.name, detail: d.detail, note: "Pair", chosen: false } })
    onPicked: function(i) { root.act(root.found[i]) }
  }

  Keys.onPressed: function(e) { if (e.key === Qt.Key_P && root.present) root.request("bluetooth", "power", !root.powered) }
}
