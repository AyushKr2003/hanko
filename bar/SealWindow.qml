import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../core/Inkan.js" as Inkan
import "../services"

// Inkan's layer (form: inkan; docs/shell-concepts/inkan): one seal in a
// corner of this screen, with nothing else on it. It reserves no space
// (windows run to the screen's edges under it) and takes input only on the
// seal itself (its mask), so the rest of the layer, where the ink blooms
// and the hover reading sets in, never steals a click from a window.
// BarWindow parks the bar while this shows.
PanelWindow {
  id: win

  required property var bar          // the Bar.qml root
  required property var barWindow    // this screen's BarWindow

  readonly property var style: barWindow.shown
  readonly property string screenName: barWindow.screenName
  readonly property string corner: Inkan.cornerOf(style.inkanAt)
  readonly property bool top: corner.indexOf("top") === 0
  readonly property bool left: corner.indexOf("left") > 0
  readonly property bool active: style.form === "inkan" && !bar.barHidden

  readonly property int size: Type.px(Inkan.SIZE)
  readonly property int margin: Type.px(Inkan.MARGIN)
  // Room past the seal for the ink pool, and toward the screen for the
  // reading.
  readonly property int pad: Math.round(size * 0.7)
  readonly property int readingRoom: Type.px(460)

  // The seal's square in this window, and in screen coordinates (for the
  // sheet that prints from it).
  readonly property real sealX: left ? margin : width - margin - size
  readonly property real sealY: top ? margin : height - margin - size

  // What the carving reads, from the live services.
  readonly property int workspace: {
    var list = Hypr.spacesFor(screenName) || []
    for (var i = 0; i < list.length; i++) if (list[i].active) return list[i].id
    return 1
  }
  readonly property var readings: ({
    battery: Status.battery,
    network: Status.network,
    volume: Status.volume,
    notifications: Status.notifications,
    dnd: Status.doNotDisturb,
    indicators: Extras.indicators,
    workspace: win.workspace
  })

  // Dragging the seal: it follows the pointer inside its layer, and on
  // release snaps to the corner nearest where the pointer let go, kept for
  // this monitor (for the whole style when there is only one screen).
  property bool dragging: false
  property point grab: Qt.point(0, 0)
  property point drag: Qt.point(0, 0)
  readonly property int screenW: screen ? screen.width : width
  readonly property int screenH: screen ? screen.height : height
  // The window's own corner on the screen, to turn its points into the screen's.
  readonly property point origin: Qt.point(left ? 0 : screenW - width, top ? 0 : screenH - height)
  property string target: corner
  function dragTo(mx, my) {
    drag = Qt.point(mx - grab.x, my - grab.y)
    target = Inkan.nearest(origin.x + mx, origin.y + my, screenW, screenH)
  }
  function drop() {
    dragging = false
    drag = Qt.point(0, 0)
    if (target !== corner) bar.moveSeal(screenName, target)
  }

  property bool hovered: false

  // The ink-press (docs/shell-concepts/inkan, sheet 04): whenever something
  // prints from this seal, by a click or a key, it sinks for the stamp's
  // 140 ms and ink pools under it (200 ms in, 400 out).
  property bool stamping: false
  readonly property bool printed: bar.inkanPrinted(screenName)
  onPrintedChanged: if (printed && active) press()
  function press() {
    if (Motion.still) return
    stamping = true
    stampDone.restart()
    bloom.restart()
  }
  Timer { id: stampDone; interval: Motion.stamp; onTriggered: win.stamping = false }
  SequentialAnimation {
    id: bloom
    NumberAnimation { target: seal; property: "bloom"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
    NumberAnimation { target: seal; property: "bloom"; to: 0; duration: 400; easing.type: Easing.InCubic }
  }

  screen: barWindow.screen
  visible: active
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: readingRoom + pad + size + margin
  implicitHeight: pad + size + margin

  WlrLayershell.namespace: "hanko-seal"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: win.top
    bottom: !win.top
    left: win.left
    right: !win.left
  }

  mask: Region { item: sealArea }

  InkanReading {
    id: reading
    parts: win.dragging
      ? [{ text: win.target === win.corner ? "stays " + win.corner : "to " + win.target, red: win.target !== win.corner }]
      : Inkan.reading(win.readings, Qt.formatTime(win.bar.now, win.bar.timeFormat))
    y: win.sealY + (win.size - height) / 2
    x: win.left ? win.sealX + win.size + Type.px(14) : win.sealX - Type.px(14) - width
    opacity: (win.hovered || win.dragging) && !win.bar.inkanPrinted(win.screenName) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
      enabled: Motion.live
      NumberAnimation { duration: Motion.fade }
    }
  }

  InkanSeal {
    id: seal
    x: Math.max(0, Math.min(win.width - win.size, win.sealX + win.drag.x))
    y: Math.max(0, Math.min(win.height - win.size, win.sealY + win.drag.y))
    size: win.size
    carving: Inkan.carving(win.style, win.readings)
    hovered: win.hovered
    pressed: sealArea.pressed || win.stamping
  }

  MouseArea {
    id: sealArea
    x: win.sealX
    y: win.sealY
    width: win.size
    height: win.size
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onEntered: win.hovered = true
    onExited: win.hovered = false
    // Points in the window's coordinates (the area sits at the seal).
    onPressed: function(mouse) { if (mouse.button === Qt.LeftButton) win.grab = Qt.point(win.sealX + mouse.x, win.sealY + mouse.y) }
    onPositionChanged: function(mouse) {
      if (!pressed || !(mouse.buttons & Qt.LeftButton)) return
      var dx = win.sealX + mouse.x - win.grab.x, dy = win.sealY + mouse.y - win.grab.y
      if (!win.dragging && Math.abs(dx) + Math.abs(dy) > Type.px(8)) win.dragging = true
      if (win.dragging) win.dragTo(win.sealX + mouse.x, win.sealY + mouse.y)
    }
    onReleased: function(mouse) { if (win.dragging) win.drop() }
    onCanceled: { win.dragging = false; win.drag = Qt.point(0, 0) }
    onClicked: function(mouse) {
      if (win.dragging) return
      if (mouse.button === Qt.RightButton) Hypr.openMenu()
      else if (mouse.button === Qt.MiddleButton) Hypr.openTerminal()
      else win.bar.pressSeal(win.screenName)
    }
    onWheel: function(wheel) {
      var dy = wheel.angleDelta.y || wheel.angleDelta.x
      if (dy) Hypr.stepWorkspace(dy > 0 ? -1 : 1)
    }
  }
}
