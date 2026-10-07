pragma Singleton
import QtQuick
import qs.Commons

// Motion 動 (Scroll mockup 05, "Paper moves like paper"): every timing and
// curve Hanko moves with, in one place. No springs, no glow; everything is
// under 320 ms except the now-notch's creep, and the stamp is the only
// overshoot. `still` (the style's motion: still, or Omarchy's reduced
// motion) cuts every transition to its end frame: use ms() for durations.
QtObject {
  id: root

  // The harness renders end frames only.
  property bool forceStill: false
  // Omarchy's own animation switch, off.
  readonly property bool system: Style.reduceMotion === true
  readonly property bool still: forceStill || system || Typeset.current.motion === "still"

  // Behaviours wait until the bar has laid itself out, so nothing slides
  // or creeps in from 0 when Hanko starts.
  property bool awake: false
  readonly property bool live: awake && !still
  property Timer _wake: Timer { interval: 1500; running: true; onTriggered: root.awake = true }

  function ms(v) { return still ? 0 : v }

  // The scroll unrolls (and the rod drops) in 300 ms; rolling up is quicker.
  readonly property int unroll: 300
  readonly property int rollUp: 220
  readonly property var unrollCurve: [0.2, 0.9, 0.25, 1, 1, 1]
  // Ink arrives after the paper: 200 ms, 120 ms late.
  readonly property int ink: 200
  readonly property int inkDelay: 120
  readonly property var inkCurve: [0.4, 0, 0.2, 1, 1, 1]
  // A pan carries on and lands centred on a section.
  readonly property int pan: 260
  readonly property var panCurve: [0.16, 1, 0.3, 1, 1, 1]
  // A new stamp: pressed oversized and tilted, then settles. The only
  // overshoot anywhere.
  readonly property int stamp: 140
  readonly property var stampCurve: [0.3, 1.4, 0.5, 1, 1, 1]
  // A sheet prints top-down from the bar.
  readonly property int sheetPrint: 180
  // An inversion plate slides to the next item, like Ryoku's rail.
  readonly property int slide: 160
  // A value fades through to the next one.
  readonly property int fade: 140
  // The now-notch creeps to the new minute instead of jumping.
  readonly property int creep: 1200
}
