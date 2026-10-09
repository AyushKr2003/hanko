pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Style.js" as S
import "Kata.js" as K

// The live style. Reads ~/.config/hanko/style.json (watched, so the CLI and
// hand edits apply at once), resolves it with Style.js, and writes changes
// back. The file only exists once something differs from the defaults.
//
//   Typeset.current            the resolved style for the default monitor
//   Typeset.styleFor(name)     the style with that monitor's overrides
//   Typeset.set(key, value)    change one setting
//   Typeset.applyPreset(name)  start again from a preset
//   Typeset.draft              the settings window's unsaved document: while
//                              it is set the bar shows it; save() keeps it,
//                              revert() drops it
//   Typeset.kata               the Kata design for the default monitor
//                              (core/Kata.js): { design, classic, <part>, touches }
//   Typeset.kataFor(name)      with that monitor's overrides
//   Typeset.setDesign(name), touch(key, value)
QtObject {
  id: root

  readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hanko"
  readonly property string path: dir + "/style.json"

  readonly property var options: S.OPTIONS
  readonly property var presets: S.PRESETS
  readonly property var presetNames: S.PRESET_NAMES

  // The normalized document: { preset, edits, sealGlyph, motion, typeSize, hidden, monitors }.
  property var doc: S.normalize({})
  property var warnings: []
  // Edits in the settings window print live on the bar but only reach
  // style.json on save().
  property var draft: null
  readonly property var live: draft || doc
  readonly property var current: S.resolve(live)

  // Kata 型: which design draws the bar. Classic (the default) is the
  // Typeset bar above; Shōji is a preset over Kata's parts.
  readonly property var designNames: K.DESIGN_NAMES
  readonly property var kataParts: K.PARTS
  readonly property var kata: K.resolve(live)
  function kataFor(screenName) { return K.resolve(live, String(screenName || "")) }
  function describeDesign(style) { return K.describe(style || kata) }

  // True when position comes from Hanko rather than Omarchy's bar.position.
  readonly property bool ownsPosition: live.edits.position !== undefined

  function styleFor(screenName) {
    return S.resolve(live, String(screenName || ""))
  }

  // The settings window's edits: each returns false when the value is not
  // one the setting takes.
  function draftSet(key, value) {
    var next = S.withSetting(live, key, value)
    if (!next) return false
    draft = next
    return true
  }
  function draftPreset(name) {
    var next = S.withPreset(live, name)
    if (!next) return false
    draft = next
    return true
  }
  function draftMonitor(monitor, key, value) {
    var next = S.withMonitorSetting(live, monitor, key, value)
    if (!next) return false
    draft = next
    return true
  }
  // Back to the preset the draft is on, edits dropped (monitors, the seal
  // glyph, motion and hidden parts kept, as reset() does).
  function draftReset() {
    draft = S.normalize(_keep(live, { preset: live.preset }))
  }
  // Kata's edits, in the draft and saved at once. Each returns false when
  // the value is not one the key takes.
  function draftDesign(name) { return _draftWith(K.withDesign(live, name)) }
  function draftTouch(key, value) { return _draftWith(K.withTouch(live, key, value)) }
  function _draftWith(next) {
    if (!next) return false
    draft = S.normalize(next)
    return true
  }
  function draftClearMonitor(name) {
    var next = S.normalize(live)
    delete next.monitors[name]
    draft = next
  }
  function draftShuffle() { draft = S.shuffled(live, Math.random) }
  // Every hidden part back on the bar.
  function draftShowAll() {
    var next = S.normalize(live)
    next.hidden = []
    draft = next
  }
  function save() {
    if (!draft) return
    var next = draft
    draft = null
    _commit(next)
  }
  function revert() { draft = null }

  // The settings window has no Save: every change it makes is kept at once
  // (keep() after each draft edit) and remembered here, so Undo (Ctrl+Z)
  // can put the one before back. Forgotten when the window closes.
  property var history: []
  // `tag` names a continuous edit (a slider being dragged): repeats of the
  // same tag within 1.5 s are one step of the history, not one per pixel.
  property string _lastTag: ""
  property real _lastAt: 0
  function keep(tag) {
    if (!draft) return
    var next = draft
    draft = null
    if (JSON.stringify(next) === JSON.stringify(doc)) return
    var now = Date.now()
    var merge = !!tag && tag === _lastTag && now - _lastAt < 1500 && history.length > 0
    _lastTag = tag || ""
    _lastAt = now
    if (merge) { _commit(next); return }
    var h = history.slice()
    h.push(doc)
    if (h.length > 50) h.shift()
    history = h
    _commit(next)
  }
  function undo() {
    if (!history.length) return false
    var h = history.slice()
    var previous = h.pop()
    history = h
    draft = null
    _commit(previous)
    return true
  }
  function forget() { history = [] }

  // One setting for one monitor, saved at once (the CLI's --monitor).
  function setFor(monitor, key, value) {
    var next = S.withMonitorSetting(doc, monitor, key, value)
    if (!next) return false
    _commit(next)
    return true
  }

  function set(key, value) {
    var next = S.withSetting(doc, key, value)
    if (!next) return false
    _commit(next)
    return true
  }

  function applyPreset(name) {
    var next = S.withPreset(doc, name)
    if (!next) return false
    _commit(next)
    return true
  }

  function reset() {
    _commit(S.normalize(_keep(doc, {})))
  }

  // What a reset keeps: the seal glyph, motion, type size, overview, hidden
  // parts, monitors, and the Kata design (a reset is about Typeset edits).
  function _keep(from, into) {
    var keys = ["sealGlyph", "motion", "typeSize", "overview", "panelOpacity", "sheetStyles", "hidden", "monitors", "design", "touches"]
    for (var i = 0; i < keys.length; i++) if (from[keys[i]] !== undefined) into[keys[i]] = from[keys[i]]
    return into
  }

  function setDesign(name) { return _commitWith(K.withDesign(doc, name)) }
  function touch(key, value) { return _commitWith(K.withTouch(doc, key, value)) }
  function _commitWith(next) {
    if (!next) return false
    _commit(S.normalize(next))
    return true
  }

  function setSealGlyph(glyph) {
    var next = S.normalize(doc)
    next.sealGlyph = glyph
    _commit(S.normalize(next))
  }

  function shuffle() {
    _commit(S.shuffled(doc, Math.random))
  }

  function serialized() {
    return JSON.stringify(doc, null, 2) + "\n"
  }

  function _commit(next) {
    doc = next
    _pending = serialized()
    saveTimer.restart()
  }

  function _load(text) {
    var parsed = {}
    var w = []
    if (String(text || "").trim() !== "") {
      try {
        parsed = JSON.parse(text)
      } catch (e) {
        w.push("style.json is not valid JSON: " + e.message + "; using defaults until it is fixed")
        parsed = {}
      }
    }
    var next = S.normalize(parsed, w)
    w = w.concat(K.resolve(next).warnings)
    warnings = w
    for (var i = 0; i < w.length; i++) console.warn("hanko: " + w[i])
    if (JSON.stringify(next) !== JSON.stringify(doc)) doc = next
  }

  // What the next save writes; kept apart from doc so a save never races a
  // reload of the same file.
  property string _pending: ""

  // Coalesce bursts (the settings page, a shuffle held down) into one write.
  property Timer saveTimer: Timer {
    interval: 200
    onTriggered: root._mkdir.running = true
  }

  property Process _mkdir: Process {
    command: ["mkdir", "-p", root.dir]
    onExited: root._file.setText(root._pending)
  }

  property FileView _file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    atomicWrites: true
    onFileChanged: reload()
    onLoaded: root._load(text())
    onLoadFailed: root._load("")
  }
}
