import QtQuick
import qs.Commons as Commons
import "../../../core"
import "../../../core/Style.js" as St
import "../../../core/Skin.js" as Sk
import "../../../bar/sheets"

// Koyomi 暦, a month turn frame by frame (tests/harness/turn.py): the Time
// sheet opens on this month in one hand, with motion on, then turns.
Rectangle {
  id: scene
  readonly property var p: JSON.parse(params)
  width: view.width + 40
  height: view.height + 40
  color: Ink.paper
  property int pick: 0
  Component.onCompleted: {
    Commons.Color.foreground = "#ddd5c7"; Commons.Color.background = "#0a0a09"; Commons.Color.urgent = "#d8452f"
    Motion.awake = true
  }
  SheetView {
    id: view
    x: 20; y: 20
    readonly property var style: St.resolve({ preset: "Hanko", sheetStyles: { time: scene.p.hand } })
    styles: style.sheetStyles
    skin: Sk.fromStyle(style)
    sheet: "time"
    animate: false
    feed: ({ now: new Date("2026-10-06T21:44:00"), zones: [], sky: scene.p.sky, timePick: scene.pick, calendar: "koyomi" })
  }
}
