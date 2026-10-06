pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Weather.js" as WeatherJs

// Weather 天 for the leaf left of 01 // TIME on the handscroll. The same
// place and units as Omarchy's own weather panel (core/Weather.js says
// how), fetched from Open-Meteo while the scroll is out and at most every
// fifteen minutes; the last answer stays on the paper while a new one is
// on its way or when the network is down.
Singleton {
  id: root

  // Set by Bar.qml while the scroll is out.
  property bool wanted: false
  // Set by Bar.qml: shell.json's bar subtree, for the omarchy.weather
  // entry's `unit` and `refreshMinutes`.
  property var barConfig: ({})

  readonly property var entry: {
    var layout = barConfig && barConfig.layout ? barConfig.layout : {}
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var list = Array.isArray(layout[sections[s]]) ? layout[sections[s]] : []
      for (var i = 0; i < list.length; i++) if (list[i] && list[i].id === "omarchy.weather") return list[i]
    }
    return ({})
  }
  readonly property int refreshMinutes: Math.max(5, parseInt(entry.refreshMinutes, 10) || 15)

  // Where: weather.json, else the detected area.
  property var place: ({ name: "", latitude: null, longitude: null })
  property var detected: null
  readonly property bool pinned: place.latitude !== null && place.longitude !== null
  readonly property var target: pinned ? place : detected
  readonly property bool useImperial: WeatherJs.imperial(entry.unit || "", Qt.locale().name, detected ? detected.country : "")

  // The last Open-Meteo answer, and when it came.
  property string raw: ""
  property real fetchedAt: 0
  property date now: new Date()

  // core/Weather.js leaf() shape, or null before the first answer.
  readonly property var reading: raw ? WeatherJs.leaf(raw, place.name || (detected ? detected.name : ""), useImperial, now) : null

  function refresh() {
    root.now = new Date()
    if (!root.pinned && !root.detected) { if (!areaProc.running) areaProc.running = true; return }
    if (Date.now() - root.fetchedAt < root.refreshMinutes * 60000 && root.raw) return
    if (forecastProc.running || !root.target) return
    forecastProc.command = ["curl", "-fsS", "--max-time", "6", WeatherJs.url(root.target.latitude, root.target.longitude)]
    forecastProc.running = true
  }

  onWantedChanged: if (wanted) refresh()
  onTargetChanged: { fetchedAt = 0; if (wanted) refresh() }

  property FileView placeFile: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.place = WeatherJs.location(text())
    onLoadFailed: root.place = WeatherJs.location("")
  }

  // wttr.in names the area the IP address is in, as Omarchy's panel does
  // when no place is set.
  property Process areaProc: Process {
    command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]
    stdout: StdioCollector {
      onStreamFinished: {
        var a = WeatherJs.area(text)
        if (a) { root.detected = a; root.refresh() }
      }
    }
  }

  property Process forecastProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        if (WeatherJs.leaf(text, "", false, new Date()) === null) return
        root.raw = text
        root.fetchedAt = Date.now()
      }
    }
  }

  // While the scroll is out: keep the past part of the day's curve moving,
  // and fetch again when the answer is old.
  property Timer _tick: Timer {
    interval: 60000
    repeat: true
    running: root.wanted
    onTriggered: root.refresh()
  }
}
