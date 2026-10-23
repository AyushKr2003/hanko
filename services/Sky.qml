pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Koyomi.js" as K
import "../core/Weather.js" as Weather

// The sky for the almanac (Koyomi 暦, docs/koyomi/README.md): the weather
// now and sixteen days ahead, from Open-Meteo, at the place Omarchy's own
// weather panel has (~/.local/state/omarchy/settings/weather.json). A place
// with coordinates is used as it is; one with only a name is found by name
// (Open-Meteo's geocoder); none at all is found from the IP address the way
// Omarchy does (wttr.in). Asked when the Time sheet opens and every half
// hour while it stays open, never while the weather setting is off; the
// last answer is kept in ~/.local/state/hanko/sky.json so a sheet opened
// offline or at boot still has a forecast to draw.
Singleton {
  id: root

  // Set by Bar.qml: the Time sheet is open, and the setting is on.
  property bool wanted: false
  property bool on: true

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  // Fahrenheit where Omarchy's weather panel would use it.
  readonly property bool imperial: K.imperial(Qt.locale().name, place.country || "")

  property var place: ({ name: "", country: "", latitude: null, longitude: null })
  // Open-Meteo's answer as it came, and when.
  property string raw: ""
  property double fetched: 0
  // K.forecast(): { now, days }; null while there is nothing to show.
  readonly property var forecast: on && raw !== "" ? K.forecast(raw, imperial) : null

  readonly property int every: 30 * 60 * 1000

  function refresh() {
    if (!on || !wanted) return
    if (place.latitude === null) { locate(); return }
    if (Date.now() - fetched < every / 2 || skyProc.running) return
    skyProc.command = ["curl", "-fsS", "--max-time", "10", K.url(place.latitude, place.longitude)]
    skyProc.running = true
  }

  function locate() {
    var named = root.named
    if (named.latitude !== null) { root.place = named; refresh(); return }
    if (named.name !== "") {
      if (!geoProc.running) {
        geoProc.command = ["curl", "-fsS", "--max-time", "10", K.geocodeUrl(named.name)]
        geoProc.running = true
      }
    } else if (!areaProc.running) areaProc.running = true
  }

  onWantedChanged: refresh()
  onOnChanged: refresh()

  // The place as weather.json has it (Weather.location()).
  property var named: Weather.location("")
  property FileView placeFile: FileView {
    path: root.stateHome + "/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.named = Weather.location(text()); root.place = { name: "", country: "", latitude: null, longitude: null }; root.fetched = 0; root.refresh() }
    onLoadFailed: { root.named = Weather.location(""); root.refresh() }
  }

  property FileView cache: FileView {
    path: root.stateHome + "/hanko/sky.json"
    printErrors: false
    atomicWrites: true
    onLoaded: {
      var c = null
      try { c = JSON.parse(text()) } catch (e) {}
      if (c && c.raw) { root.raw = c.raw; root.fetched = Number(c.fetched) || 0 }
    }
  }

  property Process geoProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        var g = K.geocoded(text)
        if (g) { root.place = g; root.refresh() }
      }
    }
  }
  property Process areaProc: Process {
    command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]
    stdout: StdioCollector {
      onStreamFinished: {
        var a = Weather.area(text)
        if (a) { root.place = a; root.refresh() }
      }
    }
  }
  property Process skyProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        var f = K.forecast(text, false)
        if (!f.now && !Object.keys(f.days).length) return
        root.raw = text
        root.fetched = Date.now()
        root.cache.setText(JSON.stringify({ fetched: root.fetched, raw: root.raw }) + "\n")
      }
    }
  }

  property Timer _again: Timer {
    interval: root.every
    repeat: true
    running: root.wanted && root.on
    onTriggered: { root.fetched = 0; root.refresh() }
  }
}
