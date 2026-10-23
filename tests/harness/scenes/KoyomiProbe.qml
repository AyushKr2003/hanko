import QtQuick
import qs.Commons as Commons
import "../../../core"
import "../../../core/Style.js" as St
import "../../../core/Skin.js" as Sk
import "../../../bar/sheets"

// Koyomi 暦 under stress (tests/koyomi.py): every hand opened on a day in each
// of the 72 kō and on every month of the year, with as many cities and as
// long a forecast as params give, each one measured: the sheet's height, and
// any part that reaches past the sheet's sides or past its own box (a Text
// wider than itself without elide or wrap). One line per case:
//   PROBE <hand> <pick> <width> <height> <overflows…>
Rectangle {
  id: scene
  readonly property var p: JSON.parse(params)
  width: 1400
  height: 1400
  color: Ink.paper
  property int hand: 0
  property int at: 0
  readonly property var hands: p.hands
  readonly property var picks: p.picks
  Component.onCompleted: {
    Commons.Color.foreground = p.theme ? p.theme.foreground : "#ddd5c7"
    Commons.Color.background = p.theme ? p.theme.background : "#0a0a09"
    Commons.Color.urgent = "#d8452f"
    Motion.forceStill = true
    step.start()
  }
  SheetView {
    id: view
    readonly property var style: St.resolve({ preset: "Hanko", sheetStyles: { time: scene.hands[scene.hand] }, typeSize: scene.p.typeSize || "regular" })
    styles: style.sheetStyles
    skin: Sk.fromStyle(style)
    sheet: "time"
    animate: false
    feed: ({ now: new Date(scene.p.now || "2026-10-06T21:44:00"), zones: scene.p.zones, sky: scene.p.sky, timePick: scene.picks[scene.at],
             calendar: "koyomi", timeFormat: scene.p.timeFormat || "HH:mm", room: scene.p.room || 0 })
  }
  // The almanac itself (the hand's component, which has a leaf), not the
  // card's crop marks and shadow, which sit outside the paper on purpose.
  function content(it) {
    if (!it) return null
    if (it.leaf !== undefined && it.request !== undefined) return it
    for (var i = 0; i < it.children.length; i++) { var c = content(it.children[i]); if (c) return c }
    return null
  }
  function clipped(it) { return clipper(it) !== null }
  // The nearest box that clips this item.
  function clipper(it) {
    for (var q = it.parent; q && q !== view; q = q.parent) if (q.clip) return q
    return null
  }
  function walk(it, out) {
    if (!it || !it.visible || it.opacity === 0) return
    // Writing a clipping box cuts off (a date too long for its slip): the
    // clip hides the overflow, but the words are still lost.
    var cb = it.text !== undefined && it.width > 0 && it.text !== "" ? clipper(it) : null
    if (cb) {
      var p0 = it.mapToItem(cb, 0, 0)
      var th = it.contentHeight !== undefined ? Math.min(it.height, it.contentHeight) || it.contentHeight : it.height
      if (p0.y + th > cb.height + 1.5 || p0.y < -1.5) out.push("cut:Text '" + String(it.text).slice(0, 24) + "'@" + Math.round(p0.y) + "+" + Math.round(th) + ">" + Math.round(cb.height))
    }
    if (it.width > 0 && !clipped(it)) {
      var pt = it.mapToItem(view, 0, 0)
      var name = (it.text !== undefined ? "Text '" + String(it.text).slice(0, 24) + "'" : String(it).split("(")[0])
      if (pt.x < -1.5 || pt.x + it.width > view.width + 1.5) out.push("side:" + name + "@" + Math.round(pt.x) + "+" + Math.round(it.width))
      if (pt.y + it.height > view.height + 1.5) out.push("foot:" + name + "@" + Math.round(pt.y) + "+" + Math.round(it.height))
      if (it.text !== undefined && it.contentWidth !== undefined && it.elide === Text.ElideNone && it.wrapMode === Text.NoWrap
          && it.contentWidth > it.width + 1.5 && it.width > 0 && !(it.rotation)) out.push("text:" + name + " " + Math.round(it.contentWidth) + ">" + Math.round(it.width))
    }
    var kids = it.children
    for (var i = 0; i < kids.length; i++) walk(kids[i], out)
  }
  Timer {
    id: step
    interval: 60
    repeat: true
    onTriggered: {
      var out = []
      var c = content(view)
      if (!c) out.push("no almanac")
      else walk(c, out)
      // Unique, short.
      var seen = {}, u = []
      for (var i = 0; i < out.length; i++) if (!seen[out[i]]) { seen[out[i]] = 1; u.push(out[i]) }
      console.log("PROBE " + scene.hands[scene.hand] + " " + scene.picks[scene.at] + " " + Math.round(view.width) + " " + Math.round(view.height) + " " + u.slice(0, 8).join(" | "))
      if (++scene.at >= scene.picks.length) { scene.at = 0; if (++scene.hand >= scene.hands.length) { stop(); Qt.quit() } }
    }
  }
}
