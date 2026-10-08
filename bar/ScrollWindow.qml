pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../core/Scroll.js" as Scroll
import "../services"
import "scroll"

// The layer the handscroll unrolls on, one per screen, next to its
// BarWindow (panels: scroll). Built like SheetWindow (Omarchy's
// KeyboardPanel pattern): a full-screen layer whose input mask leaves the
// bar strip to the bar, a brief Exclusive keyboard prime, a click anywhere
// else rolling it up, and clear twins on other screens.
//
// Motion (Scroll, "Paper moves like paper"): the paper unrolls in 300 ms,
// the ink fades in over 200 ms after 120 ms, a pan carries on with its
// speed and lands centred on a section in 260 ms. Omarchy's reduced motion
// (animations off) or motion: still cuts every one to its end frame
// (core/Motion.qml).
PanelWindow {
  id: win

  required property var bar          // the Bar.qml root
  required property var barWindow    // this screen's BarWindow

  readonly property string screenName: screen ? screen.name : ""
  readonly property bool open: bar.scrollOpen && bar.scrollScreen === screenName
  readonly property bool atBottom: bar.position === "bottom"
  readonly property int strip: barWindow.barHeight + barWindow.gap
  property bool primed: false

  // Panning state: while dragging, the track follows the pointer directly;
  // otherwise it eases to the current section.
  property bool dragging: false
  property real dragFrom: 0
  property real trackX: 0
  property double lastStep: 0

  function ms(v) { return Motion.ms(v) }
  function centre() { trackX = Scroll.centred(bar.scrollSection, view.viewWidth, Type.scale) }

  screen: barWindow.screen
  visible: open || closing.running
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "hanko-scroll"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: win.open ? (win.primed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: Region {
    x: 0
    y: 0
    width: win.width
    height: win.height
    Region {
      intersection: Intersection.Subtract
      x: 0
      y: win.atBottom ? win.height - win.strip : 0
      width: win.width
      height: win.strip
    }
  }

  onOpenChanged: {
    primed = false
    if (open) {
      closing.stop()
      dragging = false
      centre()
      view.reveal = 1
      view.ink = 1
      prime.restart()
    } else {
      view.ink = 0
      view.reveal = 0
      closing.restart()
    }
  }
  Connections {
    target: win.bar
    function onScrollSectionChanged() { if (!win.dragging) win.centre() }
  }

  Timer {
    id: prime
    interval: 75
    onTriggered: {
      if (!win.open) return
      win.primed = true
      keys.forceActiveFocus()
    }
  }
  Timer {
    id: closing
    interval: win.ms(320)
  }

  // A click off the paper rolls it up.
  MouseArea {
    anchors.fill: parent
    enabled: win.open
    acceptedButtons: Qt.AllButtons
    onPressed: win.bar.closeScroll()
  }

  FocusScope {
    id: keys
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      var k = event.key
      if (k === Qt.Key_Escape) win.bar.closeScroll()
      else if (k === Qt.Key_H || k === Qt.Key_Left) win.bar.stepScroll(-1)
      else if (k === Qt.Key_L || k === Qt.Key_Right || k === Qt.Key_Tab) win.bar.stepScroll(1)
      else if (k === Qt.Key_Backtab) win.bar.stepScroll(-1)
      else if (k >= Qt.Key_1 && k <= Qt.Key_8) win.bar.scrollTo(k - Qt.Key_1)
      else return
      event.accepted = true
    }

    ScrollView {
      id: view
      paperOpacity: win.barWindow.shown.panelOpacity > 0 ? win.barWindow.shown.panelOpacity / 100 : 1
      readonly property int margin: Math.max(Type.px(16), Math.round(win.width * 0.069))
      readonly property real viewWidth: width - 2 * Type.px(26)

      x: margin
      width: win.width - 2 * margin
      height: Math.min(implicitHeight, win.height - win.strip - Type.px(40))
      y: win.atBottom ? win.height - win.strip - height : win.strip
      atBottom: win.atBottom
      current: win.dragging ? Scroll.nearest(win.trackX, viewWidth, Type.scale) : win.bar.scrollSection
      trackX: win.trackX
      divider: win.barWindow.style.interlude || "seal"
      endleaf: win.barWindow.style.endleaf || "koyomi"
      sides: win.barWindow.style.sides || "curl"
      guides: win.barWindow.style.guides || "both"
      reveal: 0
      ink: 0
      feed: ({
        now: win.bar.now,
        zones: Zones.rows(win.bar.now, win.bar.timeFormat === "HH:mm"),
        timeShift: win.bar.timeShift,
        sound: Sound.reading,
        network: Net.reading,
      bluetooth: Blue.reading,
        power: Power.reading,
      display: Display.reading,
        letters: Status.notifications,
        weather: Weather.reading,
        weatherShown: (win.barWindow.style.hidden || []).indexOf("weather") < 0,
        dnd: Status.doNotDisturb,
        spaces: Hypr.spacesFor(win.screenName),
        leaf: Leaf.reading,
        endShown: (win.barWindow.style.hidden || []).indexOf("endleaf") < 0,
        font: Type.mono,
        version: win.bar.version,
        preset: win.barWindow.style.preset + (win.barWindow.style.edited ? " + edits" : ""),
        switches: {
          awake: !!(Extras.idleProxy && Extras.idleProxy.stayAwake),
          night: !!(Extras.nightProxy && Extras.nightProxy.enabled),
          dnd: Status.doNotDisturb
        },
        sealGlyph: win.barWindow.style.sealGlyph
      })

      Behavior on reveal {
        NumberAnimation {
          duration: win.open ? win.ms(Motion.unroll) : win.ms(Motion.rollUp)
          easing.type: Easing.BezierSpline
          easing.bezierCurve: Motion.unrollCurve
        }
      }
      Behavior on ink {
        SequentialAnimation {
          PauseAnimation { duration: win.open ? win.ms(Motion.inkDelay) : 0 }
          NumberAnimation {
            duration: win.open ? win.ms(Motion.ink) : win.ms(Motion.ink / 2)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.inkCurve
          }
        }
      }

      onRequest: function(section, what, arg) { win.bar.sheetRequest(section, what, arg) }
      onPicked: function(index) { win.bar.scrollTo(index) }
      onDragged: function(dx) {
        if (!win.dragging) { win.dragging = true; win.dragFrom = win.trackX }
        win.trackX = Scroll.clampTrack(win.dragFrom + dx, view.viewWidth, Type.scale)
      }
      onReleased: function(velocity) {
        if (!win.dragging) return
        var land = Scroll.landing(win.trackX, velocity, view.viewWidth, Type.scale)
        win.dragging = false
        win.bar.scrollTo(land)
        win.centre()
      }
      onStepped: function(delta) {
        // One section per wheel gesture, however many events a touchpad sends.
        var t = Date.now()
        if (t - win.lastStep < 260) return
        win.lastStep = t
        win.bar.stepScroll(delta)
      }

      // Swallow clicks on the paper so they don't reach the closer behind.
      MouseArea {
        z: -1
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
      }
    }
  }

  Behavior on trackX {
    enabled: !win.dragging && win.open
    NumberAnimation {
      duration: win.ms(Motion.pan)
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Motion.panCurve
    }
  }

  Variants {
    model: win.open ? Quickshell.screens : []

    delegate: Component {
      PanelWindow {
        id: twin
        required property var modelData
        screen: twin.modelData
        visible: twin.modelData.name !== win.screenName
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "hanko-scroll-dismiss"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onPressed: win.bar.closeScroll()
        }
      }
    }
  }
}
