import QtQuick
import "../../core"
import ".."

// One part of the bar, cropped out of a real bar laid out a screen wide
// with your data (Parts 部品): the part centred, enlarged up to `maxScale`,
// its neighbours fading at the sides. `part` is a BarSurface.partRect name
// (seal, spaces, title, clock, media, notif, edge, or a reading: network,
// bluetooth, volume, brightness, battery). The part is drawn even when it
// is set aside; `empty` says when there is nothing to draw (no backlight,
// no battery, nothing playing).
Item {
  id: root

  property var style: ({})
  property var barData: ({})
  property string part: "seal"
  property real maxScale: 1.8
  readonly property bool empty: measured && region.width <= 0

  // The style with this part shown.
  readonly property var set: {
    var s = Object.assign({}, style)
    s.form = "bar"
    s.hidden = (style.hidden || []).filter(function(h) { return h !== root.part })
    return s
  }

  clip: true
  // Cuts brush strokes too (Shape ignores clip).
  layer.enabled: true

  property bool measured: false
  property rect region: Qt.rect(0, 0, 0, 0)
  function measure() {
    if (part === "edge") {
      var w = width / 1.8
      region = Qt.rect(Math.max(0, bar.width * 0.62 - w / 2), 0, w, bar.height)
    } else {
      var r = bar.partRect(part)
      region = r.width <= 0 ? Qt.rect(0, 0, 0, 0) : Qt.rect(r.x - Type.px(12), 0, r.width + Type.px(24), bar.height)
    }
    measured = true
  }
  readonly property real tick: bar.layoutTick + width + height
  onTickChanged: settle.restart()
  Timer { id: settle; interval: 30; onTriggered: root.measure() }
  Component.onCompleted: settle.restart()

  readonly property real k: region.width <= 0 ? 1
    : Math.min(root.maxScale, width / region.width, (height - Type.px(8)) / Math.max(1, bar.height))

  BarSurface {
    id: bar
    width: Type.px(1920)
    height: implicitHeight
    scale: root.k
    transformOrigin: Item.TopLeft
    x: root.width / 2 - (root.region.x + root.region.width / 2) * root.k
    y: (root.height - height * root.k) / 2
    opacity: root.region.width > 0 ? 1 : 0
    enabled: false
    style: root.set
    now: root.barData.now || new Date()
    spaces: root.barData.spaces || []
    activeWindow: root.barData.activeWindow || null
    home: root.barData.home || ""
    media: root.barData.media || null
    timeFormat: root.barData.timeFormat || "HH:mm"
    volume: root.barData.volume || null
    network: root.barData.network || null
    bluetooth: root.barData.bluetooth || null
    battery: root.barData.battery || null
    brightness: root.barData.brightness || null
    notifications: root.barData.notifications || []
    dnd: !!root.barData.dnd
    indicators: root.barData.indicators || []
  }

  // Everything beside the part fades into the paper: solid for most of
  // the way, clear only at the part's own edge.
  readonly property real side: Math.max(Type.px(14), (width - region.width * k) / 2 + Type.px(10) * k)
  Rectangle {
    z: 5
    width: root.side; height: parent.height
    gradient: Gradient { orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Ink.paper }
      GradientStop { position: 0.55; color: Ink.alpha(Ink.paper, 0.85) }
      GradientStop { position: 1; color: Ink.alpha(Ink.paper, 0) } }
  }
  Rectangle {
    z: 5
    anchors.right: parent.right
    width: root.side; height: parent.height
    gradient: Gradient { orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Ink.alpha(Ink.paper, 0) }
      GradientStop { position: 0.45; color: Ink.alpha(Ink.paper, 0.85) }
      GradientStop { position: 1; color: Ink.paper } }
  }
}
