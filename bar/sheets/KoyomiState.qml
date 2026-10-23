import QtQuick
import "../../core"
import "../../core/Koyomi.js" as K
import "../../core/Season.js" as Se
import "../../core/Almanac.js" as Al

// What every hand's almanac (Koyomi 暦, docs/koyomi/README.md) shares: the
// model of the month (core/Koyomi.js), the moves (a day, a week, a month,
// a month of the year, back to today) and the turn: which way the month
// just went and whether its days are still coming in, so each hand can set
// them in its own way. Only a real turn of the month animates; the model
// is rebuilt every minute with the clock, and that sets nothing moving.
QtObject {
  id: root

  property date now: new Date()
  // Days from today the picked day is (Bar.qml timePick).
  property int pick: 0
  // K.forecast() or null (weather off, or nothing fetched yet).
  property var sky: null

  // what: "pick" (arg: days from today)
  signal request(string what, var arg)

  readonly property var k: K.sheet(now, pick, sky, { Se: Se, Al: Al })
  readonly property var leaf: k.leaf
  readonly property var view: k.view
  // The year's dial: today's place in the 72 kō, and the picked day's.
  readonly property real koNow: K.sheet(now, 0, null, { Se: Se, Al: Al }).leaf.ko.no - 1 + 0.5
  readonly property real koPicked: leaf.ko.no - 1 + leaf.ko.through

  // The turn: +1 on to a later month, -1 back; `entering` while the new
  // month's days are being set (each hand staggers its own).
  readonly property int monthKey: view.y * 12 + view.m
  property int dir: 1
  property bool entering: false
  property int _last: -1
  onMonthKeyChanged: {
    if (_last >= 0 && monthKey !== _last) {
      dir = monthKey > _last ? 1 : -1
      entering = Motion.live
      _settle.restart()
    }
    _last = monthKey
  }
  Component.onCompleted: _last = monthKey
  property Timer _settle: Timer { interval: 1100; onTriggered: root.entering = false }

  function go(how) { root.request("pick", K.step(root.now, root.pick, how)) }
  function day(cell) { if (cell) root.request("pick", cell.offset) }
  function month(m) { root.request("pick", K.toMonth(root.now, root.pick, m)) }

  // The wheel turns the month, one notch (120) at a time; a touchpad's
  // small deltas are added up first.
  property real _wheel: 0
  function wheel(delta) {
    _wheel += delta
    if (Math.abs(_wheel) < 120) return
    go(_wheel > 0 ? "month-" : "month+")
    _wheel = 0
  }

  // The keys every hand's almanac takes, beside the cursor's arrows:
  // Page Up/Down or [ ] a month, Shift with them a year, T or Home today.
  function key(event) {
    var shift = (event.modifiers & Qt.ShiftModifier) !== 0
    if (event.key === Qt.Key_PageUp || event.text === "[" || event.text === "{") { go(shift || event.text === "{" ? "year-" : "month-"); return true }
    if (event.key === Qt.Key_PageDown || event.text === "]" || event.text === "}") { go(shift || event.text === "}" ? "year+" : "month+"); return true }
    if (event.key === Qt.Key_T || event.key === Qt.Key_Home) { go("today"); return true }
    return false
  }

  // A few words for the picked day's sky: "Rain 18° / 9°" over "Rain 80%",
  // or for today the weather now: "Fair 14° · feels 13°" over "Wind from
  // the north-east · 11 km/h".
  readonly property string skyLine: {
    var n = leaf.now, s = leaf.sky
    if (n) return n.word + " " + n.temp + (n.feels && n.feels !== n.temp ? " · feels " + n.feels : "")
    if (s) return s.word + " " + s.hi + " / " + s.lo
    return ""
  }
  readonly property string skyNote: {
    var n = leaf.now, s = leaf.sky
    if (n) return "Wind from the " + n.wind.from + " · " + n.speed + " km/h"
    if (s && s.rain >= 0) return "Rain " + s.rain + "%"
    return ""
  }
  readonly property string skyMark: leaf.now ? leaf.now.jp : leaf.sky ? leaf.sky.jp : ""
}
